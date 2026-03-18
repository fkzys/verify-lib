# verify-lib

[![CI](https://github.com/rpPH4kQocMjkm2Ve/verify-lib/actions/workflows/ci.yml/badge.svg)](https://github.com/rpPH4kQocMjkm2Ve/verify-lib/actions/workflows/ci.yml)
![License](https://img.shields.io/github/license/rpPH4kQocMjkm2Ve/verify-lib)

Validates shell library files before sourcing. Compiled binary — breaks
the bootstrap problem of verifying a shell library from shell.

## Install

### With gitpkg

```sh
gitpkg install verify-lib
```

### AUR

```sh
yay -S verify-lib
```

### Manually

```sh
make build
sudo make install
```

## Usage

```sh
verify-lib <file> [prefix]
```

Returns `0` and prints the resolved canonical path to stdout on success.
Returns `1` with diagnostics to stderr on failure.

Default prefix is `/usr/lib/` when omitted.

### Examples

```sh
verify-lib /usr/lib/gitpkg/common.sh /usr/lib/gitpkg/
verify-lib /usr/lib/atomic/common.sh /usr/lib/atomic/
verify-lib /usr/lib/foo/bar.sh
```

### In scripts

```sh
_src() { local p; p=$(verify-lib "$1" "$2") && source "$p" || exit 1; }
_src /usr/lib/gitpkg/common.sh /usr/lib/gitpkg/
```

## Checks

The binary runs every check in sequence. The first failure stops
execution and returns `1`.

| # | Check | Rejects | Threat |
|---|-------|---------|--------|
| 1 | `realpath()` resolution | Dangling or escaping symlinks | Symlink escape outside trusted tree |
| 2 | Path prefix match | Paths outside expected directory | Sourcing untrusted locations |
| 3 | Regular file test (`S_ISREG`) | Directories, devices, fifos, sockets | Device/fifo/socket substitution |
| 4 | Ownership `0:0` | Files owned by non-root | Unprivileged file replacement |
| 5 | No group/other write (`g-w`, `o-w`) | Writable by non-root | Unauthorized modification |
| 6 | Writable mount in user namespace | `uid=0` faked via `--map-root-user` on rw mount | User namespace privilege spoofing |
| 7 | Directory chain ownership up to prefix | Non-root owned parent directories | Parent directory hijack |
| 8 | Group-write on non-root gid dirs | Directories writable by local group | Group member planting files |
| 9 | World-writable dirs without sticky bit | `/tmp`-style directories in the chain | Race condition file swap |

### User namespace handling

Inside a non-init user namespace (detected via `/proc/self/uid_map`),
real root's files appear owned by the kernel overflow UID (typically
`65534`). The binary tolerates this **only** when the path resides on a
read-only mount — a writable mount would let the fake namespace root
create files indistinguishable from real root's.

## Dependencies

- `gcc`, `make`

## License

AGPL-3.0-or-later
