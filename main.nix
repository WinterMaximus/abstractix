{
  inputs,
  nixpkgs,
  home-manager,
  hostsDir,
  sysModsDir,
  hmModsDir,
}: let
  lib = nixpkgs.lib;

  discoverNixFiles = dir:
  # Find all .nix files recursively in a directory & subdirectories
    lib.concatMap
    (
      name: let
        path = dir + "/${name}";
        type = (builtins.readDir dir).${name};
      in
        if type == "directory"
        then discoverNixFiles path
        else if type == "regular" && lib.hasSuffix ".nix" name
        then [path]
        else []
    )
    (builtins.attrNames (builtins.readDir dir));

  moduleName = file: lib.removeSuffix ".nix" (baseNameOf file); # Remove .nix for module names

  systemModuleFiles = discoverNixFiles sysModsDir;
  homeModuleFiles = discoverNixFiles hmModsDir;

  hostEntries = let
    # Find hosts
    hostNames =
      builtins.attrNames
      (lib.filterAttrs
        (_name: type: type == "directory")
        (builtins.readDir hostsDir));
    toEntry = name: let
      file = hostsDir + "/${name}/config.nix";
    in
      if builtins.pathExists file
      then {inherit name file;}
      else throw "${toString hostsDir}/${name}/config.nix does not exist";
  in
    map toEntry hostNames;

  enabledModuleNames = kind: host: let
    # Find enabled modules
    requested = host.modules.${kind} or {};
    enabled =
      lib.filterAttrs
      (_name: value: builtins.isAttrs value && (value.enable or false))
      requested;
  in
    builtins.attrNames enabled;

  selectModules = kind: available: host: let
    # Match "requested" modules with actual files
    availableByName =
      lib.listToAttrs
      (map (file: {
          name = moduleName file;
          value = file;
        })
        available);
    requested = enabledModuleNames kind host;
    unknown =
      builtins.filter
      (name: !(builtins.hasAttr name availableByName))
      requested;
  in
    if unknown != []
    then throw "Unknown ${kind} module(s): ${lib.concatStringsSep ", " unknown}"
    else map (name: availableByName.${name}) requested;

  mkHost = hostFile: let
    # Build the actual nixos system
    host = import hostFile;
    systemModules = selectModules "system" systemModuleFiles host;
    homeModules = selectModules "home" homeModuleFiles host;
    hostConfig = host.config or {};
    hostHome = host.home or {};
    username = hostHome.username or (throw "${toString hostFile}: home.username must be set");
    system = host.system or (throw "${toString hostFile}: system must be set");
  in
    lib.nixosSystem {
      inherit system;
      specialArgs = {inherit inputs;};
      modules =
        systemModules
        ++ [
          hostConfig
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = {inherit inputs;};
              users.${username} =
                {
                  imports = homeModules;
                }
                // (removeAttrs hostHome ["username"]);
            };
          }
        ];
    };
in {
  nixosConfigurations =
    lib.listToAttrs
    (map
      (host: {
        name = host.name;
        value = mkHost host.file;
      })
      hostEntries);
}
