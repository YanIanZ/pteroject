#!/bin/bash
# Sourby Curl Installer - One-liner download & install
# Usage: bash <(curl -s https://raw.githubusercontent.com/YanIanZ/pteroject/main/curl-install.sh)

set -e

export GITHUB_SOURCE="main"
export GITHUB_BASE_URL="https://raw.githubusercontent.com/YanIanZ/pteroject"

LOG_PATH="/var/log/sourby-installer.log"

# Download and source library (force fresh, no cache)
echo "* Downloading Sourby installer..."
rm -f /tmp/sourby-lib.sh
if ! curl -sSL --no-cache -o /tmp/sourby-lib.sh "$GITHUB_BASE_URL/$GITHUB_SOURCE/lib/lib.sh?t=$(date +%s)" 2>/dev/null; then
    echo "ERROR: Failed to download library"
    exit 1
fi

if ! head -1 /tmp/sourby-lib.sh | grep -q '#!/bin/bash'; then
    echo "ERROR: Invalid library file"
    rm -f /tmp/sourby-lib.sh
    exit 1
fi

# Source library
source /tmp/sourby-lib.sh

# Download install.sh dispatcher
if ! curl -sSL -o /tmp/sourby-install.sh "$GITHUB_BASE_URL/$GITHUB_SOURCE/install.sh" 2>/dev/null; then
    echo "ERROR: Failed to download installer"
    rm -f /tmp/sourby-lib.sh
    exit 1
fi

# Execute main menu loop
echo -e "\n\n* sourby-installer $(date) \n\n" >> "$LOG_PATH"

welcome ""

done=false
while [ "$done" == false ]; do
    options=(
        "Install Sourby (all addons + theme)"
        "Select components to install"
        "Update Sourby from GitHub"
        "Uninstall Sourby (restore backup)"
        "Create backup"
        "Restore from backup"
        "View backup history"
        "Exit"
    )

    actions=(
        "install"
        "select"
        "update"
        "uninstall"
        "backup"
        "restore"
        "backup-history"
        "exit"
    )

    output "What would you like to do?"
    output ""

    for i in "${!options[@]}"; do
        output "  [${i}]  ${options[$i]}"
    done

    output ""
    echo -n "* Input 0-$((${#actions[@]} - 1)): "
    read -r action || true

    max_idx=$((${#actions[@]} - 1))

    if [ -z "$action" ]; then
        output "Input is required"
        continue
    fi

    # Validate: digits-only and within range
    valid=0
    case "$action" in
        ''|*[!0-9]* ) ;;
        * ) [ "$action" -le "$max_idx" ] 2>/dev/null && valid=1 ;;
    esac

    if [ "$valid" -eq 0 ]; then
        output "Invalid option. Please enter 0-$max_idx."
        continue
    fi

    selected="${actions[$action]}"

    if [ "$selected" = "backup-history" ]; then
        ensure_backup_dir
        list_backups
        continue
    fi

    if [ "$selected" = "exit" ]; then
        output "Goodbye!"
        exit 0
    fi

    done=true

    # Execute action
    echo -e "\n\n* Operation: $selected $(date) \n\n" >> "$LOG_PATH"
    run_ui "$selected" 2>&1 | tee -a "$LOG_PATH"

    # Chained execution
    if [[ -n $2 ]]; then
        echo -e -n "* Operation '$selected' completed. Return to menu? (y/N): "
        read -r CONFIRM || true
        if [[ ! "$CONFIRM" =~ [Yy] ]]; then
            exit 0
        fi
        done=false
    fi
done

# Cleanup
rm -f /tmp/sourby-lib.sh /tmp/sourby-install.sh

exit 0
