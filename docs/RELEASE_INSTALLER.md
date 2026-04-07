# Release + Installer Notes (wamcp)

This document defines a simple public distribution convention for `wamcp`.

## Installer entrypoint

Host `install.sh` at a stable URL so users can run:

```bash
curl -fsSL <install_url> | bash
```

Supported installer flags:

```bash
curl -fsSL <install_url> | bash -s -- --ref <tag-or-commit>
curl -fsSL <install_url> | bash -s -- --uninstall
curl -fsSL <install_url> | bash -s -- --uninstall --purge
```

## Source layout on user machines

Installer uses:

- `~/.wamcp-src/<ref>`: git checkout of this repo at `<ref>`
- `~/.wamcp-src/current`: symlink to selected checkout
- `~/.local/bin/wamcp`: symlink to `~/.wamcp-src/current/scripts/wamcp`

`wamcp` supports global use via `WAMCP_ROOT` (defaults to repo root next to the script).

## Recommended release strategy (GitHub)

For stable installs, publish releases (tags) and tell users to pin versions:

```bash
curl -fsSL <install_url> | bash -s -- --ref vX.Y.Z
```

If you want faster installs and no `git` requirement, add a tarball approach:

- Release asset: `wamcp-vX.Y.Z.tar.gz`
- Contents: `scripts/wamcp`, `whatsapp-bridge/`, `whatsapp-mcp-server/`, `docs/`
- Installer downloads the asset into `~/.wamcp-src/vX.Y.Z` and sets `current` symlink.

