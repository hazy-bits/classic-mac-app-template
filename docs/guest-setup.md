# Guest setup

The fastest local loop keeps the guest booted between builds. The host sends a
MacBinary application directly to Retro68's LaunchAPPLServer, which preserves
the data and resource forks, launches it, and returns the guest's `out` file.

## Mac OS 9 in UTM

1. Create a Power Macintosh G4 guest and install Mac OS 9 from media and a ROM
   that you are entitled to use.
2. Use UTM Shared Network mode. In the guest TCP/IP control panel, select
   Ethernet and DHCP Server. Record the guest IPv4 address.
3. Copy the PowerPC `LaunchAPPLServer` application from a Retro68 build onto the
   guest disk using a resource-fork-preserving format such as MacBinary or HFS.
4. Open LaunchAPPLServer and select **OpenTransport TCP** in its Connection menu.
5. On the host, run `python3 scripts/classic.py doctor GUEST_IP`.

LaunchAPPLServer listens on unauthenticated TCP port 1984. Do not expose that
port outside a private host/guest network.

## PowerPC Mac OS X and other targets

Use a PowerPC Mac OS X guest that can run LaunchAPPLServer and select
`--target powerpc-osx-smoke` for the Carbon smoke test.

The reusable build layer also produces a 68K application. Retro68 supports
additional LaunchAPPL methods including Mini vMac, shared folders, serial links,
Executor and real machines. The initial host runner intentionally implements
the TCP transport used by the warm PowerPC/UTM loop; its deployment boundary is
small enough to add other LaunchAPPL methods without changing the application
or guest test protocol.
