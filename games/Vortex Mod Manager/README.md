# Vortex Proton Installer for Linux

A simple installer that sets up **Nexus Mods Vortex** as a desktop application on Linux, running Vortex through Steam's Proton compatibility layer.

It supports native Steam and Flatpak Steam installations, including multiple Steam library folders and drives.

## Features

- Detects native Steam and Flatpak Steam installations.
- Supports multiple Steam library folders and drives.
- Automatically searches for Vortex and detects its Steam compatibility-data AppID.
- Allows you to enter the Vortex executable or compatibility-data path manually.
- Detects installed Proton versions and prefers **GE-Proton** as the default when available.
- Creates a Vortex launcher and desktop application entry.
- Registers the `nxm://` protocol so Nexus Mods **Mod Manager Download** links can open Vortex.
- Applies X11 and DPI-related environment settings intended to help with mouse-click alignment.

## Requirements

Before running the installer, make sure you have:

- Linux with Bash and the standard command-line utilities used by the script.
- Steam installed, either natively or as a Flatpak.
- **Vortex added to Steam as a Non-Steam Game.** This installer does not install Vortex itself.
- At least one Proton version installed. **GE-Proton is recommended**; install it through Steam or your usual GE-Proton installation method before running the installer if you want to use it.
- Vortex launched from Steam at least once with Proton enabled, so Steam creates its compatibility prefix.

## Installation and usage

1. Install Vortex separately if you have not already.
2. Open Steam and choose **Games → Add a Non-Steam Game to My Library**. Add the Vortex installer or Vortex executable as appropriate for your existing setup.
3. Open Vortex's Steam properties and enable **Force the use of a specific Steam Play compatibility tool**. Select **GE-Proton** if installed, or another installed Proton version.
4. Launch Vortex from Steam at least once, then close it. This allows Steam to create the Proton compatibility prefix the installer needs to find.
5. Download or clone this repository and open a terminal in the folder containing `install-vortex-proton.sh`.
6. Make the script executable:

   ```bash
   chmod +x install-vortex-proton.sh
   ```

7. Run the installer:

   ```bash
   ./install-vortex-proton.sh
   ```

8. Follow the prompts to select the Steam installation, confirm or enter the Vortex path, and choose an installed Proton version. GE-Proton is selected as the default when the script detects it.

When the installer finishes, you should be able to launch **Vortex** from your application menu and use Nexus Mods **Mod Manager Download** buttons.

## Manual path options

If automatic detection does not find Vortex, the script lets you enter either:

- The full path to `Vortex.exe`, or
- The `compatdata/<APPID>` directory for Vortex's Steam prefix.

If the AppID cannot be determined from the executable path, the installer asks you to enter it.

## Troubleshooting

### Vortex is not detected

- Confirm Vortex has been added to Steam as a Non-Steam Game.
- Launch Vortex from Steam at least once with Proton enabled.
- Make sure you selected the Steam installation that contains Vortex.
- If Vortex is installed in a library on another drive, confirm that library is registered in Steam.
- Use the manual path prompt to provide the `Vortex.exe` path or its `compatdata/<APPID>` directory.

### No Proton versions are listed

Install a Proton version through Steam. If you want to use GE-Proton, make sure it is installed in a Steam library or `compatibilitytools.d` location the script searches.

### Nexus Mods links do not open Vortex

The installer registers the `nxm://` protocol handler for your user account. If links still do not open Vortex, check your desktop environment's default application for the `x-scheme-handler/nxm` protocol and confirm the launcher exists at:

```text
~/.local/bin/vortex-proton
```

You can also check the desktop entry at:

```text
~/.local/share/applications/vortex.desktop
```

### Mouse clicks are misaligned

The launcher sets X11 and DPI-related environment variables intended to help with click alignment. On Wayland, it forces several application backends to X11; behavior can vary by desktop environment and system configuration.

## Files created

The installer creates or updates these user-level files:

- `~/.local/bin/vortex-proton` — Vortex launcher.
- `~/.local/share/applications/vortex.desktop` — desktop application entry.
- `~/.config/mimeapps.list` — default handler registration for `nxm://` links.

## Notes

- This script configures an existing Vortex installation; it does not install Vortex itself.
- It does not install Proton or GE-Proton.
- Review the script before running it so you understand the changes it makes to your user configuration.
- Results may vary with Steam layouts, Proton versions, desktop environments, and Vortex updates.

## Contributing and feedback

Bug reports, suggestions, and contributions are welcome. If something does not work on your setup, include your Linux distribution, whether you use native or Flatpak Steam, the Proton version selected, and relevant terminal output.
