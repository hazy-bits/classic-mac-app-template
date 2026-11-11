{
  description = "Build and test a Macintosh Toolbox application with Retro68";

  inputs = {
    Retro68.url = "github:autc04/Retro68";
    nixpkgs.follows = "Retro68/nixpkgs";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    let
      classicMacApp = import ./nix/classic-mac-app.nix;
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];

      flake.lib = {
        version = "0.1.0";
        inherit (classicMacApp) mkClassicMacApp mkClassicMacDerivation;
      };

      perSystem =
        { inputs', pkgs, ... }:
        let
          runner = pkgs.writeShellApplication {
            name = "classic";
            text = ''
              exec ${pkgs.python3}/bin/python3 ${./scripts/classic.py} "$@"
            '';
          };
          carbon = {
            architecture = "carbon";
            interfaceMode = "universal-only";
            suffix = "-osx";
          };
          app = classicMacApp.mkClassicMacApp {
            inherit pkgs;
            retro68 = inputs'.Retro68;
            source = ./.;
            applicationName = "HelloClassic";
            applicationCreator = "HeLo";
            variants = {
              powerpc-osx = carbon;
              powerpc-osx-smoke = carbon // {
                suffix = "-osx-smoke";
                cmakeFlags = [ "-DCLASSIC_SMOKE_TEST=ON" ];
              };
              powerpc-smoke = {
                architecture = "powerpc";
                suffix = "-smoke";
                cmakeFlags = [ "-DCLASSIC_SMOKE_TEST=ON" ];
              };
            };
          };
        in
        {
          packages = app.packages // {
            classic-runner = runner;
          };
          apps.classic = {
            type = "app";
            program = "${runner}/bin/classic";
          };
          checks.runner =
            pkgs.runCommand "classic-runner-tests"
              {
                nativeBuildInputs = [ pkgs.python3 ];
              }
              ''
                cd ${./.}
                python3 -m unittest discover -s tests
                touch $out
              '';
          devShells.default = app.packages.powerpc;
          formatter = pkgs.nixfmt-rfc-style;
        };
    };
}
