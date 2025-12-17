#!/bin/bash
# Tuxtools Full Installer with all commands implemented

TU_DIR="$HOME/.tuxtools"
BIN_DIR="$HOME/.local/bin"
COMMANDS_DIR="$TU_DIR/commands"
CMDS_DIR="$TU_DIR/cmds"
LOGS_DIR="$TU_DIR/logs"

mkdir -p "$COMMANDS_DIR" "$CMDS_DIR" "$LOGS_DIR" "$BIN_DIR"

echo "Tuxtools: folder structure created."

# Logging function
log_run() {
    echo "$(date '+%F %T') | $1" >> "$LOGS_DIR/tuxtools.log"
}

# --- Create all command files ---
# repairall
cat > "$CMDS_DIR/repairall.cmd" <<'EOF'
#!/bin/bash
read -p "This will update, repair, and reboot your system. Continue? [y/N]: " choice
[[ $choice != y && $choice != Y ]] && exit
sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y
sync; sudo sysctl -w vm.drop_caches=3
sudo reboot
EOF

# optimizeall
cat > "$CMDS_DIR/optimizeall.cmd" <<'EOF'
#!/bin/bash
read -p "Optimize performance, clean caches, and reboot? [y/N]: " choice
[[ $choice != y && $choice != Y ]] && exit
sudo apt clean && sudo apt autoremove -y
rm -rf /tmp/*
sync; sudo sysctl -w vm.drop_caches=3
sudo reboot
EOF

# cleanup
cat > "$CMDS_DIR/cleanup.cmd" <<'EOF'
#!/bin/bash
read -p "Delete temp files and logs? [y/N]: " choice
[[ $choice != y && $choice != Y ]] && exit
sudo find /var/log -type f -name "*.log" -delete
rm -rf /tmp/*
echo "Cleanup complete!"
EOF

# sysinfo
cat > "$CMDS_DIR/sysinfo.cmd" <<'EOF'
#!/bin/bash
echo "Hostname: $(hostname)"
echo "Kernel: $(uname -r)"
echo "CPU: $(lscpu | grep 'Model name' | cut -d: -f2)"
echo "RAM usage:"
free -h
echo "Disk usage:"
df -h
EOF

# sysupdate
cat > "$CMDS_DIR/sysupdate.cmd" <<'EOF'
#!/bin/bash
read -p "Update & repair system safely? [y/N]: " choice
[[ $choice != y && $choice != Y ]] && exit
sudo apt update && sudo apt upgrade -y
sudo apt autoremove -y
sudo apt --fix-broken install -y
EOF

# updateapps
cat > "$CMDS_DIR/updateapps.cmd" <<'EOF'
#!/bin/bash
sudo apt update && sudo apt upgrade -y
sudo snap refresh
flatpak update -y
EOF

# clearcache
cat > "$CMDS_DIR/clearcache.cmd" <<'EOF'
#!/bin/bash
sudo apt clean
rm -rf ~/.cache/*
sudo rm -rf /var/cache/apt/*
EOF

# flushdns
cat > "$CMDS_DIR/flushdns.cmd" <<'EOF'
#!/bin/bash
sudo systemd-resolve --flush-caches
echo "DNS cache flushed"
EOF

# fixperms
cat > "$CMDS_DIR/fixperms.cmd" <<'EOF'
#!/bin/bash
read -p "Fix home folder permissions? [y/N]: " choice
[[ $choice != y && $choice != Y ]] && exit
sudo chown -R $USER:$USER $HOME
echo "Permissions fixed"
EOF

# speedtest
cat > "$CMDS_DIR/speedtest.cmd" <<'EOF'
#!/bin/bash
if ! command -v speedtest-cli >/dev/null 2>&1; then
    sudo apt install -y speedtest-cli
fi
speedtest-cli
EOF

# findbig
cat > "$CMDS_DIR/findbig.cmd" <<'EOF'
#!/bin/bash
echo "Top 10 largest files in home:"
find $HOME -type f -exec du -h {} + | sort -rh | head -n 10
EOF

# rebootnow
cat > "$CMDS_DIR/rebootnow.cmd" <<'EOF'
#!/bin/bash
read -p "Reboot immediately? [y/N]: " choice
[[ $choice != y && $choice != Y ]] && exit
sudo reboot
EOF

# shutdownnow
cat > "$CMDS_DIR/shutdownnow.cmd" <<'EOF'
#!/bin/bash
read -p "Shutdown immediately? [y/N]: " choice
[[ $choice != y && $choice != Y ]] && exit
sudo shutdown now
EOF

# temps
cat > "$CMDS_DIR/temps.cmd" <<'EOF'
#!/bin/bash
if command -v sensors >/dev/null 2>&1; then
    sensors
else
    sudo apt install -y lm-sensors
    sudo sensors-detect --auto
    sensors
fi
EOF

# gaming-mode
cat > "$CMDS_DIR/gaming-mode.cmd" <<'EOF'
#!/bin/bash
echo "Disabling unnecessary services for gaming..."
sudo systemctl stop bluetooth.service
sudo systemctl stop cups.service
sudo systemctl stop apache2.service
sync; sudo sysctl -w vm.drop_caches=3
echo "Gaming mode applied"
EOF

# fps-boost
cat > "$CMDS_DIR/fps-boost.cmd" <<'EOF'
#!/bin/bash
export __GL_SYNC_TO_VBLANK=0
echo "VSync disabled for maximum FPS"
EOF

# alias-add
cat > "$CMDS_DIR/alias-add.cmd" <<'EOF'
#!/bin/bash
read -p "Enter alias name: " name
read -p "Enter command: " cmd
echo "alias $name='$cmd'" >> ~/.bashrc
source ~/.bashrc
echo "Alias $name added!"
EOF

# log-run
cat > "$CMDS_DIR/log-run.cmd" <<'EOF'
#!/bin/bash
tail -n 50 ~/.tuxtools/logs/tuxtools.log
EOF

# update-tuxtools
cat > "$CMDS_DIR/update-tuxtools.cmd" <<'EOF'
#!/bin/bash
echo "To update tuxtools, run the installer script again."
EOF

# Make all command stubs
for cmdfile in "$CMDS_DIR"/*.cmd; do
    cmdname=$(basename "$cmdfile" .cmd)
    cat > "$COMMANDS_DIR/$cmdname" <<EOF
#!/bin/bash
TU_DIR="\$HOME/.tuxtools"
CMDS_DIR="\$TU_DIR/cmds"
LOGS_DIR="\$TU_DIR/logs"
if [[ -f "\$CMDS_DIR/$cmdname.cmd" ]]; then
    bash "\$CMDS_DIR/$cmdname.cmd"
    echo "\$(date '+%F %T') | $cmdname executed" >> "\$LOGS_DIR/tuxtools.log"
else
    echo "Command file not found!"
fi
EOF
    chmod +x "$COMMANDS_DIR/$cmdname"
done

# --- Launcher ---
cat > "$BIN_DIR/tuxtools" <<'EOF'
#!/bin/bash
TU_DIR="$HOME/.tuxtools"
COMMANDS_DIR="$TU_DIR/commands"

show_menu() {
    echo -e "\e[1;34m=== TUXTOOLS MENU ===\e[0m"
    echo -e "\e[1;33mSystem & Performance\e[0m"
    echo "repairall, optimizeall, cleanup, sysinfo, sysupdate"
    echo -e "\n\e[1;33mPackage & Cache Management\e[0m"
    echo "updateapps, clearcache, flushdns, fixperms"
    echo -e "\n\e[1;33mDisk & Storage\e[0m"
    echo "findbig"
    echo -e "\n\e[1;33mNetwork\e[0m"
    echo "speedtest"
    echo -e "\n\e[1;33mReboot & Power\e[0m"
    echo "rebootnow, shutdownnow"
    echo -e "\n\e[1;33mMonitoring / Info\e[0m"
    echo "temps"
    echo -e "\n\e[1;33mGaming / Optimization\e[0m"
    echo "gaming-mode, fps-boost"
    echo -e "\n\e[1;33mExtras / Utilities\e[0m"
    echo "alias-add, log-run, update-tuxtools"
    echo -e "\nType a command to run it, or 'exit' to quit."
}

if [[ "$1" == "-options" ]]; then
    echo "1) List commands"
    echo "2) Delete Tuxtools"
    read -p "Choose: " choice
    case "$choice" in
        1) ls "$COMMANDS_DIR" ;;
        2) rm -rf "$TU_DIR"; echo "Tuxtools removed"; exit ;;
    esac
    exit
fi

while true; do
    show_menu
    read -p "Tuxtools> " cmd
    [[ "$cmd" == "exit" ]] && break
    if [[ -x "$COMMANDS_DIR/$cmd" ]]; then
        "$COMMANDS_DIR/$cmd"
    else
        echo "Command not found"
    fi
done
EOF

chmod +x "$BIN_DIR/tuxtools"

# Add to PATH if missing
if ! echo "$PATH" | grep -q "$BIN_DIR"; then
    echo "export PATH=\"$BIN_DIR:\$PATH\"" >> "$HOME/.bashrc"
    echo "Added $BIN_DIR to PATH. Run 'source ~/.bashrc' or restart terminal."
fi

echo "Tuxtools installed fully!"
echo "Run 'tuxtools' for menu, or run commands directly in terminal."
