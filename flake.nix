{
  description = "A framework to simplify multihost, modularized nixos/HM configs";
  outputs = { ... }: {
    lib.mkConfigurations = import ./main.nix;
  };
}
