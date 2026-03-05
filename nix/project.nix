{ CHaP, indexState, pkgs, ... }:

let
  indexTool = { index-state = indexState; };
  shell = { pkgs, ... }: {
    tools = {
      cabal = indexTool;
      cabal-fmt = indexTool;
      fourmolu = indexTool;
      hlint = indexTool;
    };
    buildInputs = [
      pkgs.just
      pkgs.nixfmt-classic
    ];
    shellHook = ''
      echo "Entering cardano-mpfs-cage dev shell"
    '';
  };

  mkProject = ctx@{ lib, pkgs, ... }: {
    name = "cardano-mpfs-cage";
    src = ./..;
    compiler-nix-name = "ghc984";
    index-state = indexState;
    shell = shell { inherit pkgs; };
    inputMap = { "https://chap.intersectmbo.org/" = CHaP; };
  };

  project = pkgs.haskell-nix.cabalProject' mkProject;

in {
  devShells.default = project.shell;
  inherit project;
  packages.cage-lib =
    project.hsPkgs.cardano-mpfs-cage.components.library;
  packages.cage-tests =
    project.hsPkgs.cardano-mpfs-cage.components.tests.cage-tests;
  packages.cage-test-vectors =
    project.hsPkgs.cardano-mpfs-cage.components.exes.cage-test-vectors;
}
