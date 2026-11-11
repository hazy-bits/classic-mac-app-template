# Harness API 0.1

Version 0.1 formalizes the contracts used by both HelloClassic and Linewren. Minor
0.1 releases may add optional fields and function arguments; existing fields,
outputs, and C functions will retain their meaning. A breaking change will use
a new configuration schema and a new API version.

## Flake library

The flake exports `lib.version`, `lib.mkClassicMacApp`, and
`lib.mkClassicMacDerivation`.

`mkClassicMacApp` accepts:

- `pkgs` and the per-system Retro68 flake input;
- the application source, name, and four-character creator code;
- `interfaceMode`: `multiversal`, `universal`, or `universal-only`;
- common CMake flags;
- named build variants with an architecture, suffix, flags, optional native
  build inputs, and an optional override for `interfaceMode`.

It returns `packages` containing `m68k`, `powerpc`, `fat`, `default`,
`retro68-tools`, and every named variant. Every CMake build receives
`CLASSIC_MAC_HARNESS_DIR`, which points to this repository and makes the guest
library available without copying it into the application.

An application flake can use `harness.lib.mkClassicMacApp` with a pinned
input for this repository. Pass the application's own source and its
per-system Retro68 input. To use the same Retro68 revision as the harness,
set the application input's `follows` to `harness/Retro68`. The application
flake can expose the builder's `packages` result under `perSystem`.

```nix
packages = (inputs.harness.lib.mkClassicMacApp {
  inherit pkgs;
  retro68 = inputs'.Retro68;
  source = ./.;
  applicationName = "MyApplication";
  applicationCreator = "MyAp";
  variants.powerpc-smoke.cmakeFlags = [ "-DCLASSIC_SMOKE_TEST=ON" ];
}).packages;
```

## Project configuration

The `classic` command reads `classic-project.json` from the current directory,
or from `--project-root`. Schema 1 requires:

```json
{
  "schemaVersion": 1,
  "application": "HelloClassic",
  "runTarget": "powerpc",
  "testTarget": "powerpc-smoke",
  "testTimeoutSeconds": 30
}
```

The application is the MacBinary base name. Targets are flake package names.
The guest can be supplied positionally or through `CLASSIC_MAC_GUEST`; an
optional UTM VM name can be supplied with `--vm` or `CLASSIC_MAC_VM`.

The runner uses Retro68's TCP LaunchAPPL transport. To use it from another
application, run the harness flake's `classic` command from that application's
checkout or pass `--project-root` before the subcommand.

## Guest test library

Add the library only to smoke builds:

```cmake
add_subdirectory("${CLASSIC_MAC_HARNESS_DIR}/guest"
                 "${CMAKE_CURRENT_BINARY_DIR}/classic-test")
target_link_libraries(MyApplication PRIVATE classic-test)
```

An application writes one TAP plan and one result per assertion:

```c
ClassicTestReport report;
if(!ClassicTestBegin(&report, 1))
    return 1;
ClassicTestResult(&report, window != NULL, "created a window",
                  "NewWindow returned NULL");
return ClassicTestEnd(&report);
```

`ClassicTestEnd` fails if an assertion failed, the completed count differs from
the plan, the report could not be written, or closing it failed.
