#!/bin/bash
# Tuxtools Full Installer & Command Manager
# Author: Project AetherWare
# Version: 2.0.0
# Installs Tuxtools and all commands as executable utilities

TU_DIR="$HOME/.tuxtools"
BIN_DIR="$TU_DIR/commands"
INSTALL_BIN="/usr/local/bin"
SCRIPT_URL="https://raw.githubusercontent.com/ProjectAetherWare/tuxtools/main/tuxtools.sh"
LOG_FILE="$TU_DIR/tuxtools.log"

mkdir -p "$BIN_DIR"
touch "$LOG_FILE"

echo "Installing Tuxtools..."

# ============================
# Core Command Definitions
# ============================

# Function to create individual command scripts
create_command() {
    local cmd_name="$1"
    local cmd_body="$2"
    local cmd_file="$BIN_DIR/$cmd_name"

    cat > "$cmd_file" <<EOL
#!/bin/bash
# Tuxtools command: $cmd_name
$cmd_body
EOL
    chmod +x "$cmd_file"
    ln -sf "$cmd_file" "$INSTALL_BIN/$cmd_name"
}

# ----------------------------
# Core Commands
# ----------------------------
create_command "repairall" 'echo "Running repairall..."; sudo apt update && sudo apt upgrade -y; sudo apt autoremove -y; sudo reboot'
create_command "optimizeall" 'echo "Optimizing system..."; cleanup; sudo sysctl -w vm.swappiness=10; echo "Optimization done."; sudo reboot'
create_command "cleanup" 'echo "Cleaning temp files and logs..."; rm -rf /tmp/* ~/.cache/*; sudo journalctl --vacuum-time=2weeks; echo "Cleanup complete."'
create_command "sysinfo" 'echo "System Info:"; uname -a; lsb_release -a 2>/dev/null; free -h; df -h; lscpu'
create_command "updateapps" 'sudo apt update && sudo apt upgrade -y; if command -v snap >/dev/null; then sudo snap refresh; fi; if command -v flatpak >/dev/null; then flatpak update -y; fi; echo "Apps updated."'
create_command "clearcache" 'sudo apt clean; rm -rf ~/.cache/*; echo "Caches cleared."'
create_command "flushdns" 'sudo systemd-resolve --flush-caches 2>/dev/null || sudo resolvectl flush-caches 2>/dev/null; echo "DNS flushed."'
create_command "fixperms" 'sudo chown -R $USER:$USER $HOME; echo "Permissions fixed."'
create_command "speedtest" 'if ! command -v speedtest-cli >/dev/null; then sudo apt install speedtest-cli -y; fi; speedtest-cli'
create_command "findbig" 'echo "Top 10 largest files in home:"; find $HOME -type f -exec du -h {} + | sort -rh | head -n 10'
create_command "rebootnow" 'sudo reboot'
create_command "shutdownnow" 'sudo shutdown now'
create_command "sysupdate" 'sudo apt update && sudo apt upgrade -y; sudo apt autoremove -y; sudo apt autoclean -y; echo "System updated."'
create_command "temps" 'if command -v sensors >/dev/null; then sensors; else echo "Install lm-sensors to see temperatures."; fi'
create_command "gaming-mode" 'sudo sysctl -w vm.swappiness=10; sudo systemctl disable bluetooth.service --now 2>/dev/null; echo "Gaming mode applied."'
create_command "fps-boost" 'export __GL_SYNC_TO_VBLANK=0; echo "VSync disabled for FPS boost."'
create_command "alias-add" 'if [ -z "$1" ] || [ -z "$2" ]; then echo "Usage: alias-add <name> <command>"; exit 1; fi; echo "alias $1=\"$2\"" >> ~/.bash_aliases; source ~/.bash_aliases; echo "Alias $1 added."'
create_command "log-run" 'cat "$LOG_FILE"'
create_command "update-tuxtools" 'cd "$TU_DIR"; wget -O tuxtools.sh "$SCRIPT_URL"; chmod +x tuxtools.sh; echo "Tuxtools updated."'
create_command "reinstall-tuxtools" 'rm -rf "$TU_DIR"; bash <(curl -s "$SCRIPT_URL")'

# ----------------------------
# New Enhanced Commands
# ----------------------------
create_command "diskcheck" 'echo "Checking disk usage..."; df -h; echo "Disk check complete."'
create_command "memcheck" 'echo "Memory usage:"; free -h'
create_command "netinfo" 'echo "Network Info:"; ip a; echo "Routing table:"; route -n'
create_command "processes" 'echo "Top CPU processes:"; ps aux --sort=-%cpu | head -n 10'
create_command "tempclean" 'echo "Removing temp logs..."; rm -rf /tmp/*; echo "Temp cleanup complete."'
create_command "backup-home" 'echo "Backing up home directory..."; tar -czvf $HOME/home_backup_$(date +%F).tar.gz $HOME; echo "Backup complete."'

# ============================
# Tuxtools Menu
# ============================
TU_MENU="$BIN_DIR/tuxtools"
cat > "$TU_MENU" <<'EOL'
#!/bin/bash
# Tuxtools Main Menu

LOG_FILE="$HOME/.tuxtools/tuxtools.log"

echo "==========================="
echo "      Tuxtools Menu         "
echo "==========================="
echo "repairall      - Full system repair, update, and reboot"
echo "optimizeall    - Performance optimizer + cleanup + reboot"
echo "cleanup        - Fast cleanup of temp files and logs"
echo "sysinfo        - Show system, CPU, memory info"
echo "sysupdate      - Safe system update and repair"
echo "updateapps     - Update APT, Snap, Flatpak apps"
echo "clearcache     - Clear system/user caches"
echo "flushdns       - Flush DNS cache"
echo "fixperms       - Fix home folder permissions"
echo "speedtest      - Check internet speed"
echo "findbig        - Find top 10 largest files in home"
echo "rebootnow      - Reboot system"
echo "shutdownnow    - Shutdown system"
echo "temps          - Show CPU/GPU temps"
echo "gaming-mode    - Optimize system for gaming"
echo "fps-boost      - Boost FPS"
echo "alias-add      - Add terminal alias"
echo "log-run        - Show command log"
echo "update-tuxtools- Update Tuxtools"
echo "reinstall-tuxtools - Reinstall Tuxtools"
echo "diskcheck      - Check disk usage"
echo "memcheck       - Check memory usage"
echo "netinfo        - Show network info"
echo "processes      - Top CPU processes"
echo "tempclean      - Cleanup temp logs"
echo "backup-home    - Backup home directory"

echo "==========================="
EOL

chmod +x "$TU_MENU"
ln -sf "$TU_MENU" "$INSTALL_BIN/tuxtools"

echo "Installation complete!"
echo "All commands are now available globally. Run 'tuxtools' to see the menu."
