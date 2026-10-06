{
  description = "nivis-aws-amplify-site — GitHub-connected AWS Amplify Hosting site (app + branch + domain + service role) as a nivis module";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      # The nivis module:
      # { nivis, namePrefix ? "", cfg } -> { resources, dataSources, outputs }.
      nivisModules.default = import ./module.nix;

      checks = forAllSystems (pkgs: {
        eval = pkgs.runCommand "nivis-aws-amplify-site-eval" { } (
          let
            result = import ./check/eval.nix { lib = nixpkgs.lib; };
          in
          ''
            echo ${nixpkgs.lib.escapeShellArg result} > $out
          ''
        );

        format = pkgs.runCommand "nivis-aws-amplify-site-format" { nativeBuildInputs = [ pkgs.nixfmt ]; } ''
          nixfmt --check ${./flake.nix} ${./module.nix} ${./check/eval.nix}
          touch $out
        '';
      });

      formatter = forAllSystems (pkgs: pkgs.nixfmt);

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = [
            pkgs.nixfmt
            pkgs.awscli2
          ];
        };
      });
    };
}
