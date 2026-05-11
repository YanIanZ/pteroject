#!/bin/bash

######################################################################################
# Sourby Installer Library - Shared functionality for install.sh
######################################################################################

set -e

# Configuration
PTERODACTYL_PATH="${PTERODACTYL_PATH:-/var/www/pterodactyl}"
BACKUP_BASE_DIR="/var/backups/sourby"
GITHUB_REPO="YanIanZ/pteroject"
GITHUB_BRANCH="${GITHUB_SOURCE:-main}"
DOWNLOAD_DIR="/tmp/sourby-installer"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# ============================================================================
# OUTPUT FUNCTIONS
# ============================================================================

output() {
    echo -e "$1"
}

error() {
    echo -e "${RED}✗${NC} $1" >&2
}

success() {
    echo -e "${GREEN}✓${NC} $1"
}

info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

welcome() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║     Sourby Unified Installer v1.0.0        ║${NC}"
    echo -e "${GREEN}║  Pterodactyl Panel Addons & Theme Suite     ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "Sourby Unified Installer - Installation, Updates & Management"
    echo ""
    echo -e "  ◆ Install Sourby addons & theme onto an existing Pterodactyl panel"
    echo -e "  ◆ Automatic backup before every operation"
    echo -e "  ◆ Supports interactive (./install.sh) and piped (curl | bash) modes"
    echo ""
    echo -e "${CYAN}────────────────────────────────────────────${NC}"
}

divider() {
    echo -e "${CYAN}────────────────────────────────────────────${NC}"
}

# ============================================================================
# VALIDATION FUNCTIONS
# ============================================================================

check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root (use sudo)"
        exit 1
    fi
}

check_dependencies() {
    info "Checking dependencies..."

    for cmd in curl unzip php composer git yarn; do
        if ! command -v "$cmd" &> /dev/null; then
            error "$cmd not found. Please install it and try again."
            exit 1
        fi
        success "$cmd found"
    done
    output ""
}

validate_pterodactyl() {
    info "Validating Pterodactyl installation..."

    if [ ! -d "$PTERODACTYL_PATH" ]; then
        error "Pterodactyl not found at $PTERODACTYL_PATH"
        echo "Set PTERODACTYL_PATH and try again: PTERODACTYL_PATH=/path sudo $0"
        exit 1
    fi

    if [ ! -f "$PTERODACTYL_PATH/artisan" ]; then
        error "Pterodactyl artisan not found. Invalid path?"
        exit 1
    fi

    success "Pterodactyl found at $PTERODACTYL_PATH"
    output ""
}

# ============================================================================
# BACKUP & RESTORE
# ============================================================================

ensure_backup_dir() {
    mkdir -p "$BACKUP_BASE_DIR"
}

create_backup() {
    local backup_path="$BACKUP_BASE_DIR/sourby-backup-$(date +%Y%m%d-%H%M%S)"

    info "Creating backup at $backup_path..."
    mkdir -p "$backup_path"

    local files=(
        "app/Providers/SourbyThemeServiceProvider.php"
        "app/Http/ViewComposers/SourbyThemeComposer.php"
        "app/Models/SourbySetting.php"
        "config/sourby.php"
        "routes/sourby.php"
        "resources/views/partials/sourby"
        "public/themes/sourby"
        ".env"
    )

    for file in "${files[@]}"; do
        local src="$PTERODACTYL_PATH/$file"
        local dst="$backup_path/$file"

        if [ -e "$src" ]; then
            mkdir -p "$(dirname "$dst")"
            cp -r "$src" "$dst"
            success "Backed up $file"
        fi
    done

    rm -f "$BACKUP_BASE_DIR/latest"
    ln -s "$backup_path" "$BACKUP_BASE_DIR/latest"

    success "Backup complete: $backup_path"
    output ""
}

list_backups() {
    output ""
    info "Sourby backups:"

    if [ ! -d "$BACKUP_BASE_DIR" ]; then
        warning "No backups found"
        return
    fi

    if [ -z "$(ls -A $BACKUP_BASE_DIR)" ]; then
        warning "No backups found"
        return
    fi

    ls -lh "$BACKUP_BASE_DIR" | grep -v "^total" | grep -v "^d.*latest" | awk '{print "  " $9 " (" $5 ")"}'
    output ""
}

restore_from_backup() {
    local backup_path="$BACKUP_BASE_DIR/latest"

    if [ ! -L "$backup_path" ]; then
        error "No backup found. Cannot restore."
        exit 1
    fi

    backup_path=$(readlink "$backup_path")
    info "Restoring from: $backup_path"
    output ""

    info "Removing Sourby files..."
    local files=(
        "app/Providers/SourbyThemeServiceProvider.php"
        "app/Http/ViewComposers/SourbyThemeComposer.php"
        "app/Models/SourbySetting.php"
        "config/sourby.php"
        "routes/sourby.php"
        "resources/views/partials/sourby"
        "public/themes/sourby"
    )

    for file in "${files[@]}"; do
        local target="$PTERODACTYL_PATH/$file"
        if [ -e "$target" ]; then
            rm -rf "$target"
            success "Removed $file"
        fi
    done
    output ""

    info "Restoring from backup..."
    for file in "${files[@]}"; do
        local src="$backup_path/$file"
        local dst="$PTERODACTYL_PATH/$file"

        if [ -e "$src" ]; then
            mkdir -p "$(dirname "$dst")"
            cp -r "$src" "$dst"
            success "Restored $file"
        fi
    done
    output ""

    clear_caches

    success "Restoration complete"
    output ""
}

# ============================================================================
# DOWNLOAD & EXTRACT
# ============================================================================

download_sourby() {
    info "Downloading Sourby from GitHub..."
    mkdir -p "$DOWNLOAD_DIR"
    cd "$DOWNLOAD_DIR"

    local download_url="https://github.com/$GITHUB_REPO/archive/refs/heads/$GITHUB_BRANCH.zip"
    info "Repository: $GITHUB_REPO ($GITHUB_BRANCH)"

    if ! curl -fsSL "$download_url" -o sourby.zip; then
        error "Download failed"
        exit 1
    fi

    success "Downloaded"

    info "Extracting..."
    unzip -oq sourby.zip
    EXTRACTED_DIR="pteroject-${GITHUB_BRANCH}"
    if [ ! -d "$EXTRACTED_DIR" ]; then
        error "Extraction failed"
        exit 1
    fi
    success "Extracted"
    output ""
}

# ============================================================================
# INSTALLATION
# ============================================================================

install_addons() {
    local components="$1"

    info "Installing selected components..."
    output ""

    if [[ "$components" == *"theme"* ]]; then
        if [ -d "$EXTRACTED_DIR/Unix Theme v2/pterodactyl" ]; then
            info "Installing Unix Theme v2..."
            cp -r "$EXTRACTED_DIR/Unix Theme v2/pterodactyl"/* "$PTERODACTYL_PATH/"
            success "Unix Theme v2 installed"
        fi
    fi

    if [[ "$components" == *"billing"* ]]; then
        if [ -d "$EXTRACTED_DIR/billing-system-v1x-v143/PanelFiles" ]; then
            info "Installing Billing System..."
            cp -r "$EXTRACTED_DIR/billing-system-v1x-v143/PanelFiles"/* "$PTERODACTYL_PATH/"
            success "Billing System installed"
        fi
    fi

    if [[ "$components" == *"players"* ]]; then
        if [ -d "$EXTRACTED_DIR/Player List & Counter 1.0/PanelFiles" ]; then
            info "Installing Player List addon..."
            cp -r "$EXTRACTED_DIR/Player List & Counter 1.0/PanelFiles"/* "$PTERODACTYL_PATH/"
            success "Player List addon installed"
        fi
    fi

    if [[ "$components" == *"sort"* ]]; then
        if [ -d "$EXTRACTED_DIR/custom-server-sort-v103" ]; then
            info "Installing Custom Server Sort..."
            find "$EXTRACTED_DIR/custom-server-sort-v103" -type f ! -name "PanelEdit.txt" ! -name "README.md" -exec bash -c 'rel="${1#'"$EXTRACTED_DIR/custom-server-sort-v103/"'}"; mkdir -p "$PTERODACTYL_PATH/${rel%/*}"; cp "$1" "$PTERODACTYL_PATH/$rel"' _ {} \;
            success "Custom Server Sort installed"
        fi
    fi

    output ""
}

install_dependencies() {
    info "Installing dependencies..."
    cd "$PTERODACTYL_PATH"

    info "Installing sortablejs for drag-drop..."
    if yarn add sortablejs 2>&1 | grep -q "success"; then
        success "sortablejs installed"
    else
        warning "Failed to install sortablejs, continuing..."
    fi

    output ""
    info "Optional: Install Stripe SDK for payments"
    echo "  composer require stripe/stripe-php"
    output ""
}

update_env() {
    info "Updating .env configuration..."

    local env_file="$PTERODACTYL_PATH/.env"

    if [ -f "$env_file" ]; then
        cp "$env_file" "$env_file.bak"
    fi

    grep -q "^APP_NAME=" "$env_file" 2>/dev/null && \
        sed -i "s|^APP_NAME=.*|APP_NAME=\"Sourby\"|" "$env_file" || \
        echo "APP_NAME=\"Sourby\"" >> "$env_file"

    grep -q "^THEME=" "$env_file" 2>/dev/null && \
        sed -i "s|^THEME=.*|THEME=sourby-unix|" "$env_file" || \
        echo "THEME=sourby-unix" >> "$env_file"

    grep -q "^SOURBY_BILLING_ENABLED=" "$env_file" 2>/dev/null && \
        sed -i "s|^SOURBY_BILLING_ENABLED=.*|SOURBY_BILLING_ENABLED=true|" "$env_file" || \
        echo "SOURBY_BILLING_ENABLED=true" >> "$env_file"

    grep -q "^SOURBY_PLAYER_LIST_ENABLED=" "$env_file" 2>/dev/null && \
        sed -i "s|^SOURBY_PLAYER_LIST_ENABLED=.*|SOURBY_PLAYER_LIST_ENABLED=true|" "$env_file" || \
        echo "SOURBY_PLAYER_LIST_ENABLED=true" >> "$env_file"

    grep -q "^SOURBY_CUSTOM_SORT_ENABLED=" "$env_file" 2>/dev/null && \
        sed -i "s|^SOURBY_CUSTOM_SORT_ENABLED=.*|SOURBY_CUSTOM_SORT_ENABLED=true|" "$env_file" || \
        echo "SOURBY_CUSTOM_SORT_ENABLED=true" >> "$env_file"

    success ".env updated"
    output ""
}

register_provider() {
    echo -e "${YELLOW}Manual Step Required${NC}"
    output ""
    output "Register the Sourby service provider in your Pterodactyl installation."
    output ""
    output "Edit bootstrap/app.php:"
    output "  Add to withProviders():"
    output "    Pterodactyl\\Providers\\SourbyThemeServiceProvider::class,"
    output ""
    output "Or edit config/app.php:"
    output "  Add to 'providers' array:"
    output "    Pterodactyl\\Providers\\SourbyThemeServiceProvider::class,"
    output ""

    if [ -t 0 ]; then
        read -p "Press Enter after registering... " -t 30 || true
    else
        warning "Complete registration first, then run migrations."
        return 1
    fi

    output ""
    return 0
}

run_migrations() {
    info "Running migrations..."
    cd "$PTERODACTYL_PATH"

    if php artisan migrate --force &> /dev/null; then
        success "Migrations completed"
    else
        warning "Migrations may have failed, check logs"
    fi

    output ""
}

build_frontend() {
    info "Building frontend assets..."
    cd "$PTERODACTYL_PATH"

    if [ -f "package.json" ]; then
        if yarn install &> /dev/null && yarn run build:production &> /dev/null; then
            success "Frontend built"
        else
            warning "Frontend build may have failed, check logs"
        fi
    else
        warning "package.json not found, skipping frontend build"
    fi

    output ""
}

clear_caches() {
    info "Clearing caches..."
    cd "$PTERODACTYL_PATH"

    php artisan route:clear &> /dev/null || true
    php artisan config:clear &> /dev/null || true
    php artisan view:clear &> /dev/null || true
    php artisan cache:clear &> /dev/null || true

    success "Caches cleared"
    output ""
}

# ============================================================================
# UPDATE FUNCTIONS
# ============================================================================

update_lib_source() {
    if [ -z "$GITHUB_BASE_URL" ]; then
        return
    fi

    local tmp_lib="/tmp/sourby-lib-update.sh"
    if curl -sSL -o "$tmp_lib" "$GITHUB_BASE_URL/$GITHUB_SOURCE/lib/lib.sh" 2>/dev/null; then
        if head -1 "$tmp_lib" | grep -q '#!/bin/bash'; then
            source "$tmp_lib"
            rm -f "$tmp_lib"
        fi
    fi
}

# ============================================================================
# UI FLOWS
# ============================================================================

run_ui() {
    local action="$1"

    check_root
    check_dependencies
    validate_pterodactyl
    ensure_backup_dir

    case "$action" in
        install)
            create_backup
            download_sourby
            install_addons "theme billing players sort"
            install_dependencies
            update_env
            register_provider || return
            run_migrations
            build_frontend
            clear_caches

            output ""
            output -e "${GREEN}╔════════════════════════════════════════════╗${NC}"
            output -e "${GREEN}║    Installation Complete! ✓               ║${NC}"
            output -e "${GREEN}╚════════════════════════════════════════════╝${NC}"
            output ""
            output "Access admin: https://your-domain/admin"
            output "Backup: $BACKUP_BASE_DIR/latest"
            output ""
            ;;

        select)
            output ""
            output "Select components to install:"
            output ""

            read -p "  Install Unix Theme? (Y/n): " -n 1 -r; echo ""
            local theme=$([[ $REPLY =~ ^[Nn]$ ]] && echo "" || echo "theme")

            read -p "  Install Billing System? (Y/n): " -n 1 -r; echo ""
            local billing=$([[ $REPLY =~ ^[Nn]$ ]] && echo "" || echo "billing")

            read -p "  Install Player List? (Y/n): " -n 1 -r; echo ""
            local players=$([[ $REPLY =~ ^[Nn]$ ]] && echo "" || echo "players")

            read -p "  Install Custom Server Sort? (Y/n): " -n 1 -r; echo ""
            local sort=$([[ $REPLY =~ ^[Nn]$ ]] && echo "" || echo "sort")

            output ""
            create_backup
            download_sourby
            install_addons "$theme $billing $players $sort"
            install_dependencies
            update_env
            register_provider || return
            run_migrations
            build_frontend
            clear_caches

            output ""
            success "Installation complete"
            output ""
            ;;

        update)
            create_backup
            download_sourby
            install_addons "theme billing players sort"
            build_frontend
            clear_caches

            success "Update complete"
            output ""
            ;;

        uninstall)
            output ""
            warning "This will restore from the latest backup."
            output ""
            read -p "Are you sure? (y/n): " -n 1 -r; echo ""

            if [[ $REPLY =~ ^[Yy]$ ]]; then
                restore_from_backup
                success "Sourby uninstalled"
            else
                output "Uninstall cancelled"
            fi
            output ""
            ;;

        backup)
            create_backup
            success "Backup created"
            output ""
            ;;

        restore)
            output ""
            warning "This will restore from the latest backup."
            read -p "Are you sure? (y/n): " -n 1 -r; echo ""

            if [[ $REPLY =~ ^[Yy]$ ]]; then
                restore_from_backup
                success "Restored from backup"
            else
                output "Restore cancelled"
            fi
            output ""
            ;;

        *)
            error "Unknown action: $action"
            exit 1
            ;;
    esac

    rm -rf "$DOWNLOAD_DIR"
}

export -f output error success info warning welcome divider
export -f check_root check_dependencies validate_pterodactyl
export -f ensure_backup_dir create_backup list_backups restore_from_backup
export -f download_sourby install_addons install_dependencies
export -f update_env register_provider run_migrations build_frontend clear_caches
export -f update_lib_source run_ui
