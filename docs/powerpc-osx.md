# PowerPC Mac OS X

The `powerpc-osx` and `powerpc-osx-smoke` variants use Retro68's Carbon CFM
target and select `interfaceMode = "universal-only"` for those builds.
Retro68 supplies CarbonLib. See the [Retro68 build documentation](https://github.com/autc04/Retro68)
for how it obtains or accepts Apple Universal Interfaces.

Use Carbon-compatible Toolbox accessors such as `GetWindowPortBounds`
and `SetPortWindowPort`. Guard Classic initialization calls and direct
QuickDraw structure access. The HelloClassic source shows both paths.

```sh
nix build .#powerpc-osx
hdiutil convert result/HelloClassic.img -format UDRO -o HelloClassic.dmg
```

MacBinary and the HFS image preserve the application resource fork. The
`hdiutil` step is optional and runs on a macOS build host.

Use a compatible PowerPC Mac OS X guest with LaunchAPPLServer to run the
Carbon smoke build.

```sh
nix run .#classic -- test --target powerpc-osx-smoke
```

During Linewren's testing on Tiger, growing an editor buffer crashed in the
Carbon CFM runtime's `realloc`, which accessed a Classic low-memory address.
Linewren uses a Carbon-specific allocation workaround. The HelloClassic
smoke test exercises window creation. Test allocation and other app-specific
behavior on the Mac OS X versions you intend to support.
