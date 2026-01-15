{
  description = "A system-wide git hook configuration for easy, consitant, and personalized configuration.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        ocamlPackages = pkgs.ocaml-ng.ocamlPackages;

        gghCommit =
          if self ? shortRev && self.shortRev != null
          then self.shortRev
          else if self ? dirtyShortRev && self.dirtyShortRev != null
          then self.dirtyShortRev
          else "unknown-commit";

        duneProject = builtins.readFile ./dune-project;
        # Match the line (version <version>) and capture the middle part
        versionMatch = builtins.match ".*\\(version ([^)]+)\\).*" duneProject;
        projectVersion = if versionMatch != null then builtins.head versionMatch else "0.0.0+git-${gghCommit}";
      in
        {
          packages.default = ocamlPackages.buildDunePackage {
            pname = "ggh";
            version = projectVersion;
            src = self;

            nativeBuildInputs = [];
            
            buildInputs = [
              ocamlPackages.dolog
            ];

            preBuild = ''
            export GGH_COMMIT="${gghCommit}"
            echo "nix build: GGH_COMMIT set to '$GGH_COMMIT'"
          '';
            
          };

          apps.default = flake-utils.lib.mkApp {
            drv = self.packages.${system}.default;
          };

          devShells.default = pkgs.mkShell {
            buildInputs = [
              pkgs.ocaml
              pkgs.dune_3
              pkgs.ocamlformat

              ocamlPackages.ocaml
              ocamlPackages.findlib
              ocamlPackages.ocaml-lsp
              ocamlPackages.utop
              ocamlPackages.alcotest

              ocamlPackages.dolog

            ];
          };
        });
}
