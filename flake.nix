{
  description = "A framework to simplify multihost, modulized nix configs";
  outputs = { ... }: {
    lib.mkConfigurations = import ./main.nix;
  };
}
