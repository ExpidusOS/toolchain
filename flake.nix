{
  description = "ExpidusOS development toolchain.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    flake-utils.url = "github:numtide/flake-utils";

    zig = {
      url = "github:ExpidusOS/zig/expidus";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Used for shell.nix
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    zig,
    flake-utils,
    ...
  }@inputs:
    flake-utils.lib.eachSystem flake-utils.lib.allSystems (
      system:
        let
          pkgs = import nixpkgs {inherit system;};
        in {
          packages.default = pkgs.symlinkJoin {
            name = "expidus-toolchain-${self.shortRev or "dirty"}";

            paths = with pkgs; let
              expandSingleDep = dep: if lib.isDerivation dep then
                ([ dep ] ++ builtins.map (output: dep.${output}) dep.outputs)
              else [];

              expandDeps = deps: lib.flatten (builtins.map expandSingleDep deps);
            in expandDeps ([
              inputs.zig.packages.${system}.default
              python3
              meson
              cmake
              ninja
              gnumake
              flex
              bison
              autoconf
              libtool
            ] ++ (with llvmPackages_17; [
              llvm
              lld
            ]));

            postBuild = ''
              source ${pkgs.makeWrapper}/nix-support/setup-hook
              wrapProgram $out/bin/zig --set ZIG_SYSROOT $out
            '';
          };
        });
}
