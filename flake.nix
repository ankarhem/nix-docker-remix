{
  description = "A Nix-flake-based Node.js development environment";

  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1.*.tar.gz";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }: let
  in
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          (final: prev: {
            nodejs = prev.nodejs_20;
          })
        ];
      };
    in {
      packages = rec {
        remix = pkgs.buildNpmPackage rec {
          name = "nix-docker-remix";
          version = "0.1.0";
          src = ./.;

          # To retrieve the hash of the dependencies, run:
          # nix run nixpkgs#prefetch-npm-deps package-lock.json
          npmDepsHash = "sha256-anUhDYX5ppp1nd6Ye+exr7X0bRF9ktpkN0VfgH0LZTk=";
          # The prepack script runs the build script, which we'd rather do in the build phase.
          npmPackFlags = ["--ignore-scripts"];
          buildInputs = with pkgs; [nodejs];
          # How the output of the build phase
          installPhase = ''
            mkdir $out
            npm run build
            cp -r build/ $out
          '';
        };

        docker = pkgs.dockerTools.buildLayeredImage {
          name = "ghcr.io/ankarhem/nix-docker-remix";
          tag = "latest";
          contents = with pkgs; [nodejs];
          config.Cmd = "npx remix-serve ${remix}/build/server/index.js";
        };
      };
      devShells.default = pkgs.mkShell {
        nativeBuildInputs = with pkgs; [nodejs flyctl];
      };
    });
}
