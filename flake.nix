{
  description = "otosky Nix Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    nixpkgs,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      devShells.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          makejinja
          python313
          cilium-cli
          cloudflared
          fluxcd
          talhelper
          cue

          sops
          ssh-to-age
          gnupg
          age
          jq
          yq-go
          kubectl
          kubernetes-helm
          helmfile

          just
          gum
          kustomize
          talosctl
          kubeconform
        ];
      };
    });
}
