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

        gghVersion =
          if self.sourceInfo ? tag && self.sourceInfo.tag != null
          then self.sourceInfo.tag
          else "unknown-tag";

        gghCommit =
          if self ? shortRev && self.shortRev != null
          then self.shortRev
          else if self ? dirtyShortRev && self.dirtyShortRev != null
          then self.dirtyShortRev
          else "unknown-commit";

        projectVersion =
          if gghVersion != "unknown-tag"
          then gghVersion
          else "0.0.0-git-${if gghCommit != "unknown-commit" then gghCommit else "dev"}";

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
            export GGH_VERSION="${gghVersion}"
            export GGH_COMMIT="${gghCommit}"

            echo "nix build: GGH_VERSION set to '$GGH_VERSION'"
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
