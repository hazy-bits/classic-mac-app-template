# Classic Mac App Template

Build a Macintosh Toolbox application in C with Retro68. This template starts
with a small Hello Window app and gives it repeatable builds for 68K and
PowerPC, plus a host command that can run and smoke-test it inside a Mac guest.

This is the template and test harness we started with when building
[Linewren](https://github.com/hazy-bits/linewren), a distraction-free Markdown
editor for Mac OS 9 and PowerPC Mac OS X. Linewren shows how far that starting
point can go. The template keeps the pieces another app can reuse.

Thanks to [Wolfgang Thaller and the Retro68 contributors](https://github.com/autc04/Retro68)
for the cross-compiler, Toolbox interfaces, resource and packaging tools, and
LaunchAPPL. Those tools let us build and exercise old Mac software from a
modern machine. This project supplies an example app, Nix build helpers, and a
small test harness around them.

## Build the example

Install Nix with flakes enabled. Configure the Retro68 cache in
`nix.conf` so Nix can download the pinned toolchain.

```ini
extra-substituters = https://autc04.cachix.org
extra-trusted-public-keys = autc04.cachix.org-1:MyPhhbTlMACU1jhpdXlPlU4R4gyDEeNbuVYi/dU/2iU=
```

On macOS with Determinate Nix, `./scripts/configure-nix-cache.sh` can add
these settings to the daemon configuration. Other installations can add
them through their normal Nix configuration.

```sh
nix build
```

| Nix target | Output in `result/` |
| --- | --- |
| Default or `.#fat` | `HelloClassic.bin` for 68K and PowerPC Classic Mac OS |
| `.#m68k` or `.#powerpc` | `HelloClassic.bin` for one Classic architecture |
| `.#powerpc-osx` | Carbon CFM `HelloClassic.bin` and HFS `HelloClassic.img` for PowerPC Mac OS X |

For Carbon interface and packaging details, see the
[PowerPC Mac OS X notes](docs/powerpc-osx.md).

## Run the tests

```sh
python3 -m unittest discover -s tests
nix flake check
```

For a guest smoke test, follow the [guest setup](docs/guest-setup.md), then
substitute your guest address in these commands.

```sh
export CLASSIC_MAC_GUEST=192.168.64.2
nix run .#classic -- doctor
nix run .#classic -- run
nix run .#classic -- test
```

The smoke build creates the application window, checks it inside the guest,
and sends a TAP report back to the host. A failed assertion, missing report,
connection failure, or timeout makes the command fail. The optional
`--vm "Mac OS 9"` argument lets the runner start a named UTM guest on macOS.

## Start your own app

Use this repository as a starting point. Replace the code and resources in
`src/`, update the CMake target and creator code, and keep the name in
`classic-project.json` and `flake.nix` aligned with the built application.
Use named variants for smoke builds and platform-specific flags.

An existing project can import the Nix builders, run the host command against
its own project configuration, and link the guest test library into its smoke
build. The [harness API](docs/harness-api.md) shows those integration points.

## Development

This project was developed with substantial help from large language models.

## License

The template and harness use the [MIT License](LICENSE). Retro68 and the
system interfaces use their own licenses. The repository contains source
and build definitions. Supply any guest system, ROM, and Apple interface
files required by your setup through their respective distribution channels.
