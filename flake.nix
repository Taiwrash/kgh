{
  description = "KGH - Kubernetes GitOps Homelab Controller";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        kghBase = pkgs.buildGoModule {
          pname = "kgh";
          version = "0.1.0";
          src = ./.;

          # This hash will need to be updated after the first failed build
          vendorHash = "sha256-zOZFqQfCv03RTK2bWCLfoTvDhMXUrcOBosfcXbkibGg=";

          subPackages = [ "cmd/kgh" ];

          meta = with pkgs.lib; {
            description = "Kubernetes GitOps Homelab Controller";
            homepage = "https://github.com/Taiwrash/kgh";
            license = licenses.mit;
            maintainers = with maintainers; [ ];
          };
        };

        kgh = kghBase.overrideAttrs (old: {
          env = (old.env or {}) // { CGO_ENABLED = 0; };
        });
      in
      {
        packages.default = kgh;

        packages.dockerImage = pkgs.dockerTools.buildLayeredImage {
          name = "taiwrash/kgh";
          tag = "latest";
          contents = [ kgh pkgs.cacert ];
          config = {
            Cmd = [ "/bin/kgh" ];
            ExposedPorts = {
              "8080/tcp" = {};
            };
          };
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            go
            gopls
            gotools
            go-tools
          ];
        };
      }
    );
}
