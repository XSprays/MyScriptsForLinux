# Vortex Proton Installer for Linux

A simple and robust script that sets up **Nexus Mods Vortex** (running under Proton) as a proper desktop application on Linux.

It supports:

- Native Steam
- Flatpak Steam
- Multiple Steam library folders / drives
- Automatic detection of Vortex + AppID
- Manual path override
- Proton version selection (prefers GE-Proton)
- X11 + DPI fixes (fixes click misalignment)
- `nxm://` protocol handler (so "Mod Manager Download" buttons work)

---

## Features

| Feature | Supported |
|---------|-----------|
| Native Steam | Yes |
| Flatpak Steam | Yes |
| Multiple Steam library drives | Yes |
| Auto-detect Vortex AppID | Yes |
| Manual path input | Yes |
| Proton selection | Yes (prefers GE-Proton) |
| Desktop entry | Yes |
| NXM protocol handler | Yes |
| Click offset / DPI fix | Yes |
| Force X11 | Yes |

---

## Requirements

- Steam (native or Flatpak)
- Vortex already added as a **Non-Steam Game** and run at least once
- At least one Proton version installed (GE-Proton recommended)

---

## Usage

```bash
chmod +x install-vortex-proton.sh
./install-vortex-proton.sh
