<div align="center">
  <h1>Abstractix</h1>
  <h3>A tiny, opinionated framework, adding abstraction to a nixos/HM multihost, modularized configuration</h3>
</div>

## Usage:

### In your flake.nix:
```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    abstractix.url = "github:WinterMaximus/abstractix";
    # Etc
  };

  outputs = inputs @ {
    nixpkgs,
    home-manager,
    abstractix,
    ...
  }:
    abstractix.lib.mkConfigurations {
      inherit inputs nixpkgs home-manager;
      hostsDir = ./hosts;
      sysModsDir = ./modules/system;
      hmModsDir = ./modules/home;
    };
}
```
### Create modules as simple nix functions:
*module.nix*
```nix
{...}: { # Any args you need
  # Config here
}
```
### Create hosts that get automatically added to you flake:
*hosts/laptop/config.nix*
```nix
{
  system = "x86_64-linux";
  modules = {
    system = {
      foo.enable = true; # Enables foo.nix in your sysMods dir
    };
    home = {
      bar.enable = true; # Enables bar.nix in your hmMods dir
    };
  };
  config = {
    imports = [./hardware.nix]; # And anything else you want to manually import, within the hosts/laptop dir
    system.stateVersion = "25.11";
    networking.hostName = "wsl";
  };
  home = {
    username = "user";
    home.stateVersion = "25.11";
  };
}
```