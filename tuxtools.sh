#!/bin/bash
# Tuxtools Ultimate Installer
# Version 4.0 - Fully Automated, Modular, and Functional
# Author: Project AetherWare

TU_DIR="$HOME/.tuxtools"
BIN_DIR="$TU_DIR/commands"
INSTALL_BIN="/usr/local/bin"
SCRIPT_URL="https://raw.githubusercontent.com/ProjectAetherWare/tuxtools/main/tuxtools.sh"
LOG_FILE="$TU_DIR/tuxtools.log"

mkdir -p "$BIN_DIR"
touch "$LOG_FILE"

# -------------------------------
# Helper Functions
# -------------------------------
log() {
    echo -e "\e[33m[$(date '+%F %T')]\e[0m $*"
    echo "[$(date '+%F %T')] $*" >> "$LOG_FILE"
}

confirm() {
    read -p "$1 (y/N): " response
    [[ "$response" =~ ^[Yy]$ ]]
}

install_dep() {
    if ! command -v "$1" >/dev/null; then
        log "Installing dependency: $1"
        sudo apt install -y "$1"
    fi
}

create_command() {
    local cmd="$1"
    local body="$2"
    local file="$BIN_DIR/$cmd"

    cat > "$file" <<EOL
#!/bin/bash
$body
EOL

    chmod +x "$file"
    ln -sf "$file" "$INSTALL_BIN/$cmd"
}

# -------------------------------
# Core Commands
# -------------------------------

# repairall
create_command "repairall" '
log "Starting full system repair..."
if confirm "This will update, autoremove, autoclean, and reboot. Continue?"; then
    sudo apt update && sudo apt upgrade -y
    sudo apt autoremove -y
    sudo apt autoclean -y
    log "System repair complete. Rebooting..."
    sudo reboot
fi
'

# optimizeall
create_command "optimizeall" '
log "Optimizing system..."
cleanup
sudo sysctl -w vm.swappiness=10
log "Optimization done. Rebooting..."
sudo reboot
'

# cleanup
create_command "cleanup" '
log "Cleaning temp files and logs..."
rm -rf /tmp/* ~/.cache/*
sudo journalctl --vacuum-time=2weeks
log "Cleanup complete."
'

# sysinfo
create_command "sysinfo" '
log "Displaying system info..."
echo -e "\e[36mSystem:\e[0m"; uname -a
echo -e "\e[36mOS Info:\e[0m"; lsb_release -a 2>/dev/null
echo -e "\e[36mMemory:\e[0m"; free -h
echo -e "\e[36mDisk Usage:\e[0m"; df -h
echo -e "\e[36mCPU Info:\e[0m"; lscpu
'

# updateapps
create_command "updateapps" '
log "Updating all applications..."
sudo apt update && sudo apt upgrade -y
command -v snap >/dev/null && sudo snap refresh
command -v flatpak >/dev/null && flatpak update -y
log "All apps updated."
'

# clearcache
create_command "clearcache" '
log "Clearing system/user caches..."
sudo apt clean
rm -rf ~/.cache/*
log "Caches cleared."
'

# flushdns
create_command "flushdns" '
log "Flushing DNS cache..."
sudo systemd-resolve --flush-caches 2>/dev/null || sudo resolvectl flush-caches 2>/dev/null
log "DNS cache cleared."
'

# fixperms
create_command "fixperms" '
log "Fixing home folder permissions..."
sudo chown -R $USER:$USER $HOME
log "Permissions fixed."
'

# speedtest
create_command "speedtest" '
install_dep speedtest-cli
log "Running internet speed test..."
speedtest-cli
'

# findbig
create_command "findbig" '
log "Finding top 10 largest files in home..."
find $HOME -type f -exec du -h {} + | sort -rh | head -n 10
'

# rebootnow
create_command "rebootnow" '
if confirm "Are you sure you want to reboot now?"; then
    log "Rebooting..."
    sudo reboot
fi
'

# shutdownnow
create_command "shutdownnow" '
if confirm "Are you sure you want to shutdown now?"; then
    log "Shutting down..."
    sudo shutdown now
fi
'

# sysupdate
create_command "sysupdate" '
log "Performing safe system update..."
sudo apt update && sudo apt upgrade -y
sudo apt autoremove -y
sudo apt autoclean -y
log "System update complete."
'

# temps
create_command "temps" '
install_dep lm-sensors
log "Displaying CPU/GPU temperatures..."
sensors
'

# gaming-mode
create_command "gaming-mode" '
log "Activating gaming mode..."
sudo sysctl -w vm.swappiness=10
sudo systemctl disable bluetooth.service --now 2>/dev/null
log "Gaming mode enabled."
'

# fps-boost
create_command "fps-boost" '
export __GL_SYNC_TO_VBLANK=0
log "VSync disabled for max FPS."
'

# alias-add
create_command "alias-add" '
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: alias-add <name> <command>"
    exit 1
fi
echo "alias $1=\"$2\"" >> ~/.bash_aliases
source ~/.bash_aliases
log "Alias $1 added."
'

# log-run
create_command "log-run" "
cat $LOG_FILE
"

# update-tuxtools
create_command "update-tuxtools" '
log "Updating Tuxtools..."
cd "$TU_DIR"
wget -O tuxtools.sh "$SCRIPT_URL"
chmod +x tuxtools.sh
log "Tuxtools updated."
'

# reinstall-tuxtools
create_command "reinstall-tuxtools" '
log "Reinstalling Tuxtools..."
rm -rf "$TU_DIR"
bash <(curl -s "$SCRIPT_URL")
'

# -------------------------------
# New Enhanced Commands
# -------------------------------
create_command "diskcheck" 'log "Checking disk usage..."; df -h'
create_command "memcheck" 'log "Checking memory usage..."; free -h'
create_command "netinfo" 'log "Displaying network info..."; ip a; echo; route -n'
create_command "processes" 'log "Top CPU processes:"; ps aux --sort=-%cpu | head -n 10'
create_command "tempclean" 'log "Removing temp logs..."; rm -rf /tmp/*; log "Temp cleanup done."'
create_command "backup-home" 'log "Backing up home directory..."; tar -czvf $HOME/home_backup_$(date +%F).tar.gz $HOME; log "Backup complete."'

# -------------------------------
# Tuxtools Menu
# -------------------------------
TU_MENU="$BIN_DIR/tuxtools"
cat > "$TU_MENU" <<'EOL'
#!/bin/bash
LOG_FILE="$HOME/.tuxtools/tuxtools.log"
echo -e "\e[1;33m==============================="
echo "         Tuxtools Menu          "
echo -e "===============================\e[0m"
for cmd in $(ls $HOME/.tuxtools/commands | grep -v tuxtools); do
    echo -e "\e[1;36m$cmd\e[0m"
done
echo -e "\e[1;33m===============================\e[0m"
EOL
chmod +x "$TU_MENU"
ln -sf "$TU_MENU" "$INSTALL_BIN/tuxtools"

log "✅ Tuxtools installation complete! Run 'tuxtools' to see the menu. All commands now work globally."
