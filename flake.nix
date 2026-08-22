{
  description = "A framework to simplify multihost, modulized nix configs";
  outputs = { ... }: {
    lib.mkConfiguration = import ./main.nix;
  };
}