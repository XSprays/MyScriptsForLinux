#!/bin/bash

# ============================================================
#  Vortex Mod Manager (Proton) Setup Script
#  Supports:
#    - Native Steam
#    - Flatpak Steam
#    - Multiple Steam library folders / drives
# ============================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

echo
echo "=============================================="
echo "  Vortex (Proton) Installer for Linux"
echo "  Native + Flatpak + Multi-drive support"
echo "=============================================="
echo

# ------------------------------------------------------------
# 1. Detect Steam installations
# ------------------------------------------------------------
declare -A STEAM_CANDIDATES=(
    ["Native"]="$HOME/.steam/steam"
    ["Native (alt)"]="$HOME/.local/share/Steam"
    ["Flatpak"]="$HOME/.var/app/com.valvesoftware.Steam/data/Steam"
)

STEAM_ROOT=""
STEAM_TYPE=""
FOUND_STEAMS=()
FOUND_PATHS=()

echo "Searching for Steam installations..."
for type in "Native" "Native (alt)" "Flatpak"; do
    path="${STEAM_CANDIDATES[$type]}"
    if [[ -d "$path/steamapps" ]]; then
        echo "  Found: $type → $path"
        FOUND_STEAMS+=("$type")
        FOUND_PATHS+=("$path")
    fi
done

if [[ ${#FOUND_STEAMS[@]} -eq 0 ]]; then
    error "No Steam installation found (native or Flatpak)."
fi

if [[ ${#FOUND_STEAMS[@]} -gt 1 ]]; then
    echo
    echo "Multiple Steam installations detected:"
    for i in "${!FOUND_STEAMS[@]}"; do
        echo "  [$((i+1))] ${FOUND_STEAMS[$i]} → ${FOUND_PATHS[$i]}"
    done
    echo
    read -rp "Select which Steam to use [1]: " choice
    choice=${choice:-1}
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#FOUND_STEAMS[@]} )); then
        error "Invalid selection."
    fi
    STEAM_TYPE="${FOUND_STEAMS[$((choice-1))]}"
    STEAM_ROOT="${FOUND_PATHS[$((choice-1))]}"
else
    STEAM_TYPE="${FOUND_STEAMS[0]}"
    STEAM_ROOT="${FOUND_PATHS[0]}"
fi

success "Using $STEAM_TYPE Steam"
echo "   Path: $STEAM_ROOT"
echo

# ------------------------------------------------------------
# 2. Find all Steam library folders (multi-drive support)
# ------------------------------------------------------------
info "Scanning for Steam library folders (multi-drive)..."

LIBRARY_FOLDERS=("$STEAM_ROOT/steamapps")

# Parse libraryfolders.vdf
VDF_FILE="$STEAM_ROOT/steamapps/libraryfolders.vdf"
if [[ -f "$VDF_FILE" ]]; then
    while IFS= read -r line; do
        if [[ "$line" =~ \"path\"[[:space:]]+\"([^\"]+)\" ]]; then
            lib_path="${BASH_REMATCH[1]}"
            # Expand ~ and make absolute
            lib_path="${lib_path/#\~/$HOME}"
            if [[ -d "$lib_path/steamapps" ]]; then
                LIBRARY_FOLDERS+=("$lib_path/steamapps")
            fi
        fi
    done < "$VDF_FILE"
fi

# Remove duplicates
mapfile -t LIBRARY_FOLDERS < <(printf "%s\n" "${LIBRARY_FOLDERS[@]}" | sort -u)

echo "Library folders found:"
for lib in "${LIBRARY_FOLDERS[@]}"; do
    echo "  • $lib"
done
echo

# ------------------------------------------------------------
# 3. Search for Vortex across all libraries
# ------------------------------------------------------------
info "Searching for Vortex across all library folders..."

VORTEX_APPID=""
VORTEX_EXE=""
VORTEX_COMPATDATA=""

for lib in "${LIBRARY_FOLDERS[@]}"; do
    compat="$lib/compatdata"
    [[ -d "$compat" ]] || continue

    while IFS= read -r -d '' dir; do
        for candidate in \
            "$dir/pfx/drive_c/Program Files/Vortex/Vortex.exe" \
            "$dir/pfx/drive_c/Program Files (x86)/Vortex/Vortex.exe"
        do
            if [[ -f "$candidate" ]]; then
                VORTEX_APPID=$(basename "$dir")
                VORTEX_EXE="$candidate"
                VORTEX_COMPATDATA="$dir"
                break 3
            fi
        done
    done < <(find "$compat" -maxdepth 1 -type d -print0 2>/dev/null)
done

if [[ -n "$VORTEX_APPID" ]]; then
    success "Auto-detected Vortex"
    echo "   AppID        : $VORTEX_APPID"
    echo "   Executable   : $VORTEX_EXE"
    echo "   Compatdata   : $VORTEX_COMPATDATA"
else
    warn "Could not auto-detect Vortex."
fi

echo
echo "You can also manually specify the path."
echo "Examples:"
echo "  - Full path to Vortex.exe"
echo "  - Path to the compatdata/APPID folder"
echo

read -rp "Enter path manually (leave empty to use auto-detected): " MANUAL_PATH

if [[ -n "$MANUAL_PATH" ]]; then
    MANUAL_PATH="${MANUAL_PATH/#\~/$HOME}"
    MANUAL_PATH=$(realpath -m "$MANUAL_PATH" 2>/dev/null || echo "$MANUAL_PATH")

    if [[ -f "$MANUAL_PATH" && "$MANUAL_PATH" == *Vortex.exe ]]; then
        VORTEX_EXE="$MANUAL_PATH"
        if [[ "$MANUAL_PATH" =~ compatdata/([0-9]+)/ ]]; then
            VORTEX_APPID="${BASH_REMATCH[1]}"
            VORTEX_COMPATDATA=$(dirname "$(dirname "$(dirname "$(dirname "$MANUAL_PATH")")")")
        else
            read -rp "Could not detect AppID. Enter the AppID: " VORTEX_APPID
            [[ -z "$VORTEX_APPID" ]] && error "AppID is required."
            VORTEX_COMPATDATA=""
        fi
    elif [[ -d "$MANUAL_PATH" ]]; then
        if [[ -f "$MANUAL_PATH/pfx/drive_c/Program Files/Vortex/Vortex.exe" ]]; then
            VORTEX_EXE="$MANUAL_PATH/pfx/drive_c/Program Files/Vortex/Vortex.exe"
            VORTEX_APPID=$(basename "$MANUAL_PATH")
            VORTEX_COMPATDATA="$MANUAL_PATH"
        elif [[ -f "$MANUAL_PATH/pfx/drive_c/Program Files (x86)/Vortex/Vortex.exe" ]]; then
            VORTEX_EXE="$MANUAL_PATH/pfx/drive_c/Program Files (x86)/Vortex/Vortex.exe"
            VORTEX_APPID=$(basename "$MANUAL_PATH")
            VORTEX_COMPATDATA="$MANUAL_PATH"
        else
            error "Directory does not contain Vortex.exe."
        fi
    else
        error "Invalid path."
    fi

    success "Using manually specified Vortex"
    echo "   AppID        : $VORTEX_APPID"
    echo "   Executable   : $VORTEX_EXE"
fi

if [[ -z "$VORTEX_APPID" || -z "$VORTEX_EXE" ]]; then
    error "No valid Vortex installation found."
fi

# If we still don't have the exact compatdata path, try to reconstruct it
if [[ -z "$VORTEX_COMPATDATA" ]]; then
    for lib in "${LIBRARY_FOLDERS[@]}"; do
        if [[ -d "$lib/compatdata/$VORTEX_APPID" ]]; then
            VORTEX_COMPATDATA="$lib/compatdata/$VORTEX_APPID"
            break
        fi
    done
fi

if [[ -z "$VORTEX_COMPATDATA" ]]; then
    # Fallback
    VORTEX_COMPATDATA="$STEAM_ROOT/steamapps/compatdata/$VORTEX_APPID"
fi

echo

# ------------------------------------------------------------
# 4. Detect Proton versions
# ------------------------------------------------------------
info "Detecting installed Proton versions..."

declare -a PROTON_LIST=()
declare -a PROTON_PATHS=()

search_paths=(
    "$STEAM_ROOT/steamapps/common"
    "$STEAM_ROOT/compatibilitytools.d"
    "$HOME/.local/share/Steam/compatibilitytools.d"
    "$HOME/.steam/steam/compatibilitytools.d"
    "$HOME/.var/app/com.valvesoftware.Steam/data/Steam/compatibilitytools.d"
)

# Also search in every library folder
for lib in "${LIBRARY_FOLDERS[@]}"; do
    search_paths+=("$lib/common")
done

for base in "${search_paths[@]}"; do
    [[ -d "$base" ]] || continue
    while IFS= read -r -d '' proton; do
        name=$(basename "$(dirname "$proton")")
        if [[ ! " ${PROTON_LIST[*]} " =~ " ${name} " ]]; then
            PROTON_LIST+=("$name")
            PROTON_PATHS+=("$proton")
        fi
    done < <(find "$base" -name "proton" -type f -print0 2>/dev/null)
done

if [[ ${#PROTON_LIST[@]} -eq 0 ]]; then
    error "No Proton installations found."
fi

echo
echo "Available Proton versions:"
for i in "${!PROTON_LIST[@]}"; do
    echo "  [$((i+1))] ${PROTON_LIST[$i]}"
done
echo

DEFAULT_INDEX=0
for i in "${!PROTON_LIST[@]}"; do
    if [[ "${PROTON_LIST[$i]}" == GE-Proton* ]]; then
        DEFAULT_INDEX=$i
        break
    fi
done

read -rp "Select Proton version [default: $((DEFAULT_INDEX+1)) - ${PROTON_LIST[$DEFAULT_INDEX]}]: " choice
choice=${choice:-$((DEFAULT_INDEX+1))}

if ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#PROTON_LIST[@]} )); then
    error "Invalid selection."
fi

SELECTED_PROTON_NAME="${PROTON_LIST[$((choice-1))]}"
SELECTED_PROTON_PATH="${PROTON_PATHS[$((choice-1))]}"

success "Selected: $SELECTED_PROTON_NAME"
echo "   Path: $SELECTED_PROTON_PATH"
echo

# ------------------------------------------------------------
# 5. Create launcher
# ------------------------------------------------------------
info "Creating launcher script..."

mkdir -p "$HOME/.local/bin"
LAUNCHER="$HOME/.local/bin/vortex-proton"

cat > "$LAUNCHER" << EOF
#!/bin/bash
# Auto-generated by install-vortex-proton.sh
# Steam type : $STEAM_TYPE
# AppID      : $VORTEX_APPID

export STEAM_COMPAT_DATA_PATH="$VORTEX_COMPATDATA"
export STEAM_COMPAT_CLIENT_INSTALL_PATH="$STEAM_ROOT"

# Force X11 + DPI fixes (helps with click alignment)
export GDK_BACKEND=x11
export QT_QPA_PLATFORM=xcb
export SDL_VIDEODRIVER=x11
export GDK_SCALE=1
export GDK_DPI_SCALE=1
export QT_SCALE_FACTOR=1
export QT_AUTO_SCREEN_SCALE_FACTOR=0

PROTON="$SELECTED_PROTON_PATH"
VORTEX_EXE="$VORTEX_EXE"

if [[ ! -x "\$PROTON" ]]; then
    notify-send "Vortex" "Proton not found: \$PROTON" 2>/dev/null || true
    echo "Proton not found: \$PROTON"
    exit 1
fi

if [[ "\$1" == nxm://* ]]; then
    exec "\$PROTON" run "\$VORTEX_EXE" -d "\$1"
else
    exec "\$PROTON" run "\$VORTEX_EXE" "\$@"
fi
EOF

chmod +x "$LAUNCHER"
success "Launcher created: $LAUNCHER"

# ------------------------------------------------------------
# 6. Desktop entry
# ------------------------------------------------------------
info "Creating desktop entry..."

DESKTOP_FILE="$HOME/.local/share/applications/vortex.desktop"
mkdir -p "$HOME/.local/share/applications"

cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Name=Vortex
Comment=Nexus Mods Vortex Mod Manager (Proton)
Exec=$LAUNCHER %u
Icon=steam
Terminal=false
Type=Application
Categories=Game;Utility;
MimeType=x-scheme-handler/nxm;
StartupNotify=true
EOF

chmod +x "$DESKTOP_FILE"
update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
success "Desktop entry created"

# ------------------------------------------------------------
# 7. NXM handler
# ------------------------------------------------------------
info "Registering nxm:// protocol handler..."

mkdir -p "$HOME/.config"
MIMEAPPS="$HOME/.config/mimeapps.list"
touch "$MIMEAPPS"

sed -i '/x-scheme-handler\/nxm/d' "$MIMEAPPS" 2>/dev/null || true

if ! grep -q "^\[Default Applications\]" "$MIMEAPPS"; then
    echo "[Default Applications]" >> "$MIMEAPPS"
fi

echo "x-scheme-handler/nxm=vortex.desktop" >> "$MIMEAPPS"
xdg-mime default vortex.desktop x-scheme-handler/nxm 2>/dev/null || true

success "NXM protocol handler registered"

# ------------------------------------------------------------
# 8. Summary
# ------------------------------------------------------------
echo
echo "=============================================="
echo "  Installation complete!"
echo "=============================================="
echo
echo "Summary:"
echo "  Steam type     : $STEAM_TYPE"
echo "  AppID          : $VORTEX_APPID"
echo "  Compatdata     : $VORTEX_COMPATDATA"
echo "  Proton         : $SELECTED_PROTON_NAME"
echo "  Launcher       : $LAUNCHER"
echo "  Desktop entry  : $DESKTOP_FILE"
echo
echo "You can now:"
echo "  • Launch Vortex from the application menu"
echo "  • Use 'Mod Manager Download' buttons on Nexus Mods"
echo
