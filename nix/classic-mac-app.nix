let
  harnessRoot = ../.;

  mkClassicMacDerivation =
    {
      pkgs,
      retro68,
      source,
      applicationName,
      architecture,
      interfaceMode ? "multiversal",
      suffix ? "",
      cmakeFlags ? [ ],
      extraNativeBuildInputs ? [ ],
    }:
    let
      retroPkgs = retro68.legacyPackages.pkgsCross.${architecture};
      baseStdenv =
        if interfaceMode == "multiversal" then
          retroPkgs.stdenv
        else if interfaceMode == "universal" then
          retroPkgs.stdenvUniversal
        else if interfaceMode == "universal-only" then
          retroPkgs.stdenvUniversal.override {
            cc = retroPkgs.stdenvUniversal.cc.override {
              extraPackages = with retroPkgs.retro68; [
                universal
                libretro
                setup_hook
              ];
            };
          }
        else
          throw "Unknown classic Mac interface mode: ${interfaceMode}";
    in
    baseStdenv.mkDerivation {
      name = applicationName + suffix;
      src = source;
      cmakeFlags = cmakeFlags ++ [ "-DCLASSIC_MAC_HARNESS_DIR=${harnessRoot}" ];

      nativeBuildInputs = [
        pkgs.cmake
        pkgs.ninja
        retro68.packages.tools
      ]
      ++ extraNativeBuildInputs;

      FULL_COMPILER_PATH = "${baseStdenv.cc}/bin/${retroPkgs.targetPlatform.config}-g++";
    };

  mkClassicMacApp =
    {
      pkgs,
      retro68,
      source,
      applicationName,
      applicationCreator,
      interfaceMode ? "multiversal",
      cmakeFlags ? [ ],
      variants ? { },
    }:
    let
      inherit (pkgs) lib;
      build =
        architecture: extra:
        mkClassicMacDerivation ({
          inherit
            pkgs
            retro68
            source
            applicationName
            architecture
            ;
          interfaceMode = extra.interfaceMode or interfaceMode;
          cmakeFlags = cmakeFlags ++ (extra.cmakeFlags or [ ]);
          suffix = extra.suffix or "";
          extraNativeBuildInputs = extra.extraNativeBuildInputs or [ ];
        });
      basePackages = {
        m68k = build "m68k" { };
        powerpc = build "powerpc" { };
        retro68-tools = retro68.packages.tools;
      };
      variantPackages = lib.mapAttrs (
        _: variant: build (variant.architecture or "powerpc") variant
      ) variants;
      fatPackage = pkgs.runCommand "${applicationName}-fat" { } ''
        mkdir -p $out
        ${retro68.packages.tools}/bin/Rez -o $out/${applicationName}.bin \
          --copy ${basePackages.m68k}/${applicationName}.bin \
          --copy ${basePackages.powerpc}/${applicationName}.bin \
          --data ${basePackages.powerpc}/${applicationName}.bin \
          --type 'APPL' --creator '${applicationCreator}'
      '';
      packages =
        basePackages
        // variantPackages
        // {
          fat = fatPackage;
          default = fatPackage;
        };
    in
    {
      inherit packages;
    };
in
{
  inherit mkClassicMacApp mkClassicMacDerivation;
}
