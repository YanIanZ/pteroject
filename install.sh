#!/bin/bash

set -e

######################################################################################
#                                                                                    #
# Project 'pteroject' - Sourby Unified Installer                                     #
#                                                                                    #
# Copyright (C) 2025 - 2026, YanIanZ                                                 #
#                                                                                    #
#   This program is free software: you can redistribute it and/or modify             #
#   it under the terms of the GNU General Public License as published by             #
#   the Free Software Foundation, either version 3 of the License, or                #
#   (at your option) any later version.                                              #
#                                                                                    #
#   This program is distributed in the hope that it will be useful,                  #
#   but WITHOUT ANY WARRANTY; without even the implied warranty of                   #
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the                    #
#   GNU General Public License for more details.                                     #
#                                                                                    #
#   You should have received a copy of the GNU General Public License                #
#   along with this program.  If not, see <https://www.gnu.org/licenses/>.           #
#                                                                                    #
# https://github.com/YanIanZ/pteroject/blob/main/LICENSE                             #
#                                                                                    #
######################################################################################

export GITHUB_SOURCE="main"
export SCRIPT_RELEASE="v1.0.0"
export GITHUB_BASE_URL="https://raw.githubusercontent.com/YanIanZ/pteroject"

LOG_PATH="/var/log/sourby-installer.log"

# Source the library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/lib/lib.sh" ]; then
    # Local mode - source from script directory
    # shellcheck source=lib/lib.sh
    source "$SCRIPT_DIR/lib/lib.sh"
else
    # Remote mode - download lib.sh
    echo "* Downloading library..."
    rm -f /tmp/sourby-lib.sh
    if curl -sSL -o /tmp/sourby-lib.sh "$GITHUB_BASE_URL/$GITHUB_SOURCE/lib/lib.sh" 2>/dev/null; then
        if head -1 /tmp/sourby-lib.sh | grep -q '#!/bin/bash'; then
            # shellcheck source=/dev/null
            source /tmp/sourby-lib.sh
        else
            echo "* ERROR: Failed to download library. Check your internet connection."
            rm -f /tmp/sourby-lib.sh
            exit 1
        fi
    else
        echo "* ERROR: Failed to download library. Check your internet connection."
        exit 1
    fi
fi

#==============================================================================
# MAIN DISPATCHER
#==============================================================================
execute() {
    echo -e "\n\n* sourby-installer $(date) \n\n" >> "$LOG_PATH"

    # Try to update lib from remote (if available)
    update_lib_source 2>/dev/null || true

    # Direct commands (no UI needed)
    if [[ "$1" == "backup" ]] || [[ "$1" == "restore" ]]; then
        run_ui "$1" 2>&1 | tee -a "$LOG_PATH"
        return
    fi

    # Full UI flows
    run_ui "$1" 2>&1 | tee -a "$LOG_PATH"

    # Chained execution
    if [[ -n $2 ]]; then
        echo -e -n "* Operation '$1' completed. Proceed to '$2'? (y/N): "
        read -r CONFIRM </dev/tty
        if [[ "$CONFIRM" =~ [Yy] ]]; then
            execute "$2"
        else
            output "Operation '$2' cancelled."
            exit 0
        fi
    fi
}

#==============================================================================
# MAIN ENTRY POINT
#==============================================================================
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
    read -r action </dev/tty

    max_idx=$((${#actions[@]} - 1))

    if [ -z "$action" ]; then
        output "Input is required"
        continue
    fi

    # Validate: digits-only and within range
    valid=0
    case "$action" in
        ''|*[!0-9]* ) ;;  # empty or contains non-digit
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
    execute "$selected"
done

# Cleanup
rm -f /tmp/sourby-lib.sh

exit 0
