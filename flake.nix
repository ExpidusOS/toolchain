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
          pkgs = (import nixpkgs {inherit system;}).appendOverlays [
            (final: prev: {
              coreutils = prev.coreutils.overrideAttrs (f: p: {
                doCheck = p.doCheck && !prev.hostPlatform.isAarch64;
              });

              coreutils-full = prev.coreutils-full.overrideAttrs (f: p: {
                doCheck = p.doCheck && !prev.hostPlatform.isAarch64;
              });

              findutils = prev.findutils.overrideAttrs (f: p: {
                doCheck = p.doCheck && !prev.hostPlatform.isAarch64;
              });

              diffutils = prev.diffutils.overrideAttrs (f: p: {
                doCheck = p.doCheck && !prev.hostPlatform.isAarch64;
              });
            })
            zig.overlays.default
          ];
        in {
          packages.default = pkgs.symlinkJoin {
            name = "expidus-toolchain-${self.shortRev or "dirty"}";

            paths = with pkgs; let
              expandSingleDep = dep: if lib.isDerivation dep then
                ([ dep ] ++ builtins.map (output: dep.${output}) dep.outputs)
              else [];

              expandDeps = deps: lib.flatten (builtins.map expandSingleDep deps);
            in expandDeps ([
              pkgs.zig
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

          legacyPackages = pkgs;
        });
}
