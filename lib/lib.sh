#!/bin/bash

#==============================================================================
# Sourby Installer - Shared Library
#==============================================================================

export GITHUB_SOURCE="main"
export SCRIPT_VERSION="v1.0.0"
export GITHUB_BASE_URL="https://raw.githubusercontent.com/YanIanZ/pteroject"

# Global configuration
GITHUB_REPO="YanIanZ/pteroject"
GITHUB_BRANCH="main"
DOWNLOAD_DIR="${DOWNLOAD_DIR:-/tmp/sourby-installer}"
PTERODACTYL_PATH="${PTERODACTYL_PATH:-/var/www/pterodactyl}"
BACKUP_BASE_DIR="/var/backups/sourby"
LATEST_BACKUP="${BACKUP_BASE_DIR}/latest"
LOG_PATH="/var/log/sourby-installer.log"

# Component selection (set by UI)
INSTALL_UNIX_THEME=false
INSTALL_BILLING=false
INSTALL_PLAYER_LIST=false
INSTALL_CUSTOM_SORT=false

# Configuration values
APP_NAME="Sourby"
THEME_NAME="sourby-unix"
PAYPAL_MODE="sandbox"
PAYPAL_CLIENT_ID=""
PAYPAL_CLIENT_SECRET=""
STRIPE_KEY=""
STRIPE_SECRET=""
SOURBY_BACKGROUND=""
SOURBY_LOGO=""
SOURBY_FAVICON=""

# Sourby managed files for backup/restore
SOURBY_FILES=(
    "app/Providers/SourbyThemeServiceProvider.php"
    "app/Http/ViewComposers/SourbyThemeComposer.php"
    "app/Models/SourbySetting.php"
    "config/sourby.php"
    "routes/sourby.php"
    "resources/views/partials/sourby"
    "public/themes/sourby"
)

# Detect if running via curl pipe
if [ -t 0 ]; then
    RUNNING_PIPED=false
else
    RUNNING_PIPED=true
fi

#==============================================================================
# COLOR DEFINITIONS
#==============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

#==============================================================================
# LOGGING HELPERS
#==============================================================================
output() { echo -e "$*"; }

log_info()    { output "${BLUE}ℹ${NC} $*"; }
log_success() { output "${GREEN}✓${NC} $*"; }
log_warning() { output "${YELLOW}⚠${NC} $*"; }
log_error()   { output "${RED}✗${NC} $*"; }

#==============================================================================
# HEADERS & DIVIDERS
#==============================================================================
print_banner() {
    clear 2>/dev/null || true
    output "${GREEN}╔════════════════════════════════════════════╗${NC}"
    output "${GREEN}║       Sourby Unified Installer ${SCRIPT_VERSION}          ║${NC}"
    output "${GREEN}║  Pterodactyl Panel Addons & Theme Suite     ║${NC}"
    output "${GREEN}╚════════════════════════════════════════════╝${NC}"
    output ""
}

print_divider() {
    output "${CYAN}────────────────────────────────────────────${NC}"
}

#==============================================================================
# VALIDATION CHECKS
#==============================================================================
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

check_dependencies() {
    local missing=()

    for cmd in curl unzip php; do
        if ! command -v "$cmd" &>/dev/null; then
            missing+=("$cmd")
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        log_error "Missing required dependencies: ${missing[*]}"
        log_warning "Install them and try again."
        exit 1
    fi
}

validate_pterodactyl() {
    if [ ! -d "$PTERODACTYL_PATH" ]; then
        log_error "Pterodactyl not found at $PTERODACTYL_PATH"
        output "  Set PTERODACTYL_PATH environment variable:"
        output "  PTERODACTYL_PATH=/custom/path $0"
        exit 1
    fi

    if [ ! -f "$PTERODACTYL_PATH/artisan" ]; then
        log_error "Pterodactyl artisan not found at $PTERODACTYL_PATH"
        exit 1
    fi

    log_success "Pterodactyl found: $PTERODACTYL_PATH"
}

ensure_backup_dir() {
    mkdir -p "$BACKUP_BASE_DIR"
    mkdir -p "$(dirname "$LOG_PATH")"
}

#==============================================================================
# BACKUP & RESTORE
#==============================================================================
create_backup() {
    local backup_path="$BACKUP_BASE_DIR/sourby-backup-$(date +%Y%m%d-%H%M%S)"

    log_info "Creating backup at $backup_path..."
    mkdir -p "$backup_path"

    for file in "${SOURBY_FILES[@]}"; do
        local src="$PTERODACTYL_PATH/$file"
        local dst="$backup_path/$file"
        if [ -e "$src" ]; then
            mkdir -p "$(dirname "$dst")"
            cp -r "$src" "$dst"
            log_success "Backed up $file"
        fi
    done

    # Also backup .env if it exists and isn't already backed up
    if [ -f "$PTERODACTYL_PATH/.env" ]; then
        cp "$PTERODACTYL_PATH/.env" "$backup_path/env.bak"
    fi

    rm -f "$LATEST_BACKUP"
    ln -s "$backup_path" "$LATEST_BACKUP"
    log_success "Backup complete: $backup_path"
    output ""
    return 0
}

list_backups() {
    output ""
    log_info "Backup history:"

    if [ ! -d "$BACKUP_BASE_DIR" ] || [ -z "$(ls -A "$BACKUP_BASE_DIR" 2>/dev/null)" ]; then
        log_warning "No backups found."
        return
    fi

    ls -1t "$BACKUP_BASE_DIR" | grep -v "^latest$" | while read -r entry; do
        if [ -d "$BACKUP_BASE_DIR/$entry" ]; then
            local count=$(find "$BACKUP_BASE_DIR/$entry" -type f 2>/dev/null | wc -l | tr -d ' ')
            output "  ${CYAN}$entry${NC}  (${count} files)"
        fi
    done
    output ""

    if [ -L "$LATEST_BACKUP" ]; then
        local latest=$(readlink "$LATEST_BACKUP")
        log_info "Latest backup: $(basename "$latest")"
    fi
    output ""
}

restore_from_backup() {
    if [ ! -L "$LATEST_BACKUP" ]; then
        log_error "No backup found. Cannot restore."
        exit 1
    fi

    local backup_path
    backup_path=$(readlink "$LATEST_BACKUP")

    log_warning "Restoring from: $(basename "$backup_path")"
    output ""

    # Remove current Sourby files
    log_info "Removing current Sourby files..."
    for file in "${SOURBY_FILES[@]}"; do
        local target="$PTERODACTYL_PATH/$file"
        if [ -e "$target" ]; then
            rm -rf "$target"
            log_success "Removed $file"
        fi
    done
    output ""

    # Restore from backup
    log_info "Restoring from backup..."
    for file in "${SOURBY_FILES[@]}"; do
        local src="$backup_path/$file"
        local dst="$PTERODACTYL_PATH/$file"
        if [ -e "$src" ]; then
            mkdir -p "$(dirname "$dst")"
            cp -r "$src" "$dst"
            log_success "Restored $file"
        fi
    done

    # Restore .env if backed up
    if [ -f "$backup_path/env.bak" ]; then
        cp "$backup_path/env.bak" "$PTERODACTYL_PATH/.env"
        log_success "Restored .env"
    fi

    output ""
    clear_caches
    log_success "Restoration complete."
    output ""
    return 0
}

#==============================================================================
# DOWNLOAD
#==============================================================================
download_sourby() {
    log_info "Downloading Sourby from GitHub..."
    mkdir -p "$DOWNLOAD_DIR"
    cd "$DOWNLOAD_DIR" || exit 1

    local download_url="https://github.com/$GITHUB_REPO/archive/refs/heads/$GITHUB_BRANCH.zip"
    log_info "Repository: $GITHUB_REPO ($GITHUB_BRANCH)"

    if ! curl -fsSL "$download_url" -o sourby.zip; then
        log_error "Download failed. Check your internet connection."
        exit 1
    fi

    log_info "Extracting..."
    unzip -oq sourby.zip
    EXTRACTED_DIR="pteroject-${GITHUB_BRANCH}"

    if [ ! -d "$EXTRACTED_DIR" ]; then
        log_error "Extraction failed."
        exit 1
    fi

    log_success "Downloaded and extracted."
    output ""
}

#==============================================================================
# INSTALL ADDONS
#==============================================================================
install_addons() {
    log_info "Installing Sourby components..."
    output ""

    # Unix Theme v2
    if [ -d "$EXTRACTED_DIR/Unix Theme v2/pterodactyl" ]; then
        log_info "Installing Unix Theme v2..."
        cp -r "$EXTRACTED_DIR/Unix Theme v2/pterodactyl"/* "$PTERODACTYL_PATH/"
        log_success "Unix Theme v2"
    else
        log_warning "Unix Theme v2 not found in download"
    fi

    # Billing System
    if [ -d "$EXTRACTED_DIR/billing-system-v1x-v143/PanelFiles" ]; then
        log_info "Installing Billing System..."
        cp -r "$EXTRACTED_DIR/billing-system-v1x-v143/PanelFiles"/* "$PTERODACTYL_PATH/"
        log_success "Billing System"
    else
        log_warning "Billing System not found in download"
    fi

    # Player List
    if [ -d "$EXTRACTED_DIR/Player List & Counter 1.0/PanelFiles" ]; then
        log_info "Installing Player List addon..."
        cp -r "$EXTRACTED_DIR/Player List & Counter 1.0/PanelFiles"/* "$PTERODACTYL_PATH/"
        log_success "Player List addon"
    else
        log_warning "Player List addon not found in download"
    fi

    # Custom Server Sort
    if [ -d "$EXTRACTED_DIR/custom-server-sort-v103" ]; then
        log_info "Installing Custom Server Sort..."
        find "$EXTRACTED_DIR/custom-server-sort-v103" \
            -type f ! -name "PanelEdit.txt" ! -name "README.md" \
            -exec bash -c '
                rel="${1#'$EXTRACTED_DIR/custom-server-sort-v103/'}"
                mkdir -p "$PTERODACTYL_PATH/${rel%/*}"
                cp "$1" "$PTERODACTYL_PATH/$rel"
            ' _ {} \;
        log_success "Custom Server Sort"
    else
        log_warning "Custom Server Sort not found in download"
    fi

    output ""
}

#==============================================================================
# DEPENDENCIES
#==============================================================================
install_dependencies() {
    log_info "Installing PHP and Node.js dependencies..."
    cd "$PTERODACTYL_PATH" || exit 1

    # Composer dependencies
    if command -v composer &>/dev/null; then
        log_info "Installing Composer packages..."
        composer require --no-interaction paypal/checkout-sdk stripe/stripe-php &>/dev/null && \
            log_success "PHP SDKs: paypal/checkout-sdk, stripe/stripe-php" || \
            log_warning "Composer install failed - install manually: composer require paypal/checkout-sdk stripe/stripe-php"
    fi

    # Node.js dependencies
    if command -v yarn &>/dev/null; then
        log_info "Installing Node.js packages..."
        yarn add sortablejs &>/dev/null && \
            log_success "sortablejs" || \
            log_warning "yarn add failed - install manually: yarn add sortablejs"
    fi

    output ""
}

#==============================================================================
# ENV CONFIGURATION
#==============================================================================
update_env() {
    log_info "Updating .env configuration..."
    local env_file="$PTERODACTYL_PATH/.env"

    if [ ! -f "$env_file" ]; then
        log_warning ".env not found. Skipping configuration."
        return
    fi

    # Always backup .env before modifying
    cp "$env_file" "$env_file.bak.$(date +%Y%m%d%H%M%S)"

    set_env() { grep -q "^$1=" "$env_file" && sed -i "s|^$1=.*|$1=$2|" "$env_file" || echo "$1=$2" >> "$env_file"; }

    set_env "APP_NAME" "\"$APP_NAME\""
    set_env "THEME" "$THEME_NAME"

    # Payment config
    if [ -n "$PAYPAL_CLIENT_ID" ]; then
        set_env "PAYPAL_MODE" "$PAYPAL_MODE"
        set_env "PAYPAL_CLIENT_ID" "$PAYPAL_CLIENT_ID"
        set_env "PAYPAL_CLIENT_SECRET" "$PAYPAL_CLIENT_SECRET"
    fi

    [ -n "$STRIPE_KEY" ] && set_env "STRIPE_PUBLIC_KEY" "$STRIPE_KEY"
    [ -n "$STRIPE_SECRET" ] && set_env "STRIPE_SECRET_KEY" "$STRIPE_SECRET"

    # Theme customization
    [ -n "$SOURBY_BACKGROUND" ] && set_env "SOURBY_BACKGROUND" "$SOURBY_BACKGROUND"
    [ -n "$SOURBY_LOGO" ] && set_env "SOURBY_LOGO" "$SOURBY_LOGO"
    [ -n "$SOURBY_FAVICON" ] && set_env "SOURBY_FAVICON" "$SOURBY_FAVICON"

    log_success ".env updated"
    output ""
}

#==============================================================================
# LARAVEL COMMANDS
#==============================================================================
run_migrations() {
    log_info "Running database migrations..."
    cd "$PTERODACTYL_PATH" || exit 1

    if php artisan migrate --force &>/dev/null; then
        log_success "Migrations complete"
    else
        log_error "Migration failed"
        exit 1
    fi
    output ""
}

build_frontend() {
    log_info "Building frontend assets..."
    cd "$PTERODACTYL_PATH" || exit 1

    if [ -f "package.json" ]; then
        if yarn install &>/dev/null && yarn run build:production &>/dev/null; then
            log_success "Frontend built"
        else
            log_error "Frontend build failed"
            exit 1
        fi
    else
        log_warning "package.json not found, skipping frontend build"
    fi
    output ""
}

clear_caches() {
    log_info "Clearing caches..."
    cd "$PTERODACTYL_PATH" || exit 1

    php artisan route:clear &>/dev/null || true
    php artisan config:clear &>/dev/null || true
    php artisan view:clear &>/dev/null || true
    php artisan cache:clear &>/dev/null || true

    log_success "Caches cleared"
    output ""
}

#==============================================================================
# SERVICE PROVIDER REGISTRATION (Manual Step)
#==============================================================================
prompt_provider_registration() {
    output "${YELLOW}────────────────────────────────────────────${NC}"
    log_warning "Manual Step: Register the Service Provider"
    output ""
    output "Add to ${CYAN}$PTERODACTYL_PATH/bootstrap/app.php${NC} in withProviders():"
    output ""
    output "    ${CYAN}Pterodactyl\\Providers\\SourbyThemeServiceProvider::class,${NC}"
    output ""

    if [ "$RUNNING_PIPED" = false ]; then
        echo -n "* Press Enter after registering the service provider... "
        read -r
        output ""
    else
        log_warning "Complete registration, then run migrations manually:"
        output "  cd $PTERODACTYL_PATH"
        output "  php artisan migrate"
        output "  yarn install && yarn run build:production"
        output "  php artisan cache:clear"
        output ""
    fi
    print_divider
}

#==============================================================================
# INTERACTIVE UI
#==============================================================================
run_ui() {
    local action="$1"

    case "$action" in
        install)
            run_install_full
            ;;
        select)
            run_install_select
            ;;
        update)
            run_update
            ;;
        uninstall)
            run_uninstall
            ;;
        backup)
            check_root
            ensure_backup_dir
            create_backup
            ;;
        restore)
            check_root
            validate_pterodactyl
            run_restore
            ;;
        *)
            log_error "Unknown action: $action"
            exit 1
            ;;
    esac
}

run_install_full() {
    print_banner
    check_root
    check_dependencies
    validate_pterodactyl
    ensure_backup_dir

    # Create backup first
    log_info "Creating pre-installation backup..."
    create_backup

    # Download and install
    download_sourby
    install_addons
    install_dependencies
    update_env
    prompt_provider_registration
    run_migrations
    build_frontend
    clear_caches

    # Cleanup
    rm -rf "$DOWNLOAD_DIR"

    print_banner
    output "${GREEN}✓ Installation Complete!${NC}"
    output ""
    print_next_steps
}

run_install_select() {
    print_banner
    check_root
    check_dependencies
    validate_pterodactyl
    ensure_backup_dir

    output "Step 1: Choose Components to Install"
    output ""

    read -p "  Install Unix Theme v2? (Y/n): " -n 1 -r
    output ""
    [[ $REPLY =~ ^[Yy]$ || -z $REPLY ]] && INSTALL_UNIX_THEME=true

    read -p "  Install Billing System (PayPal/Stripe)? (Y/n): " -n 1 -r
    output ""
    [[ $REPLY =~ ^[Yy]$ || -z $REPLY ]] && INSTALL_BILLING=true

    read -p "  Install Player List (real-time counter)? (Y/n): " -n 1 -r
    output ""
    [[ $REPLY =~ ^[Yy]$ || -z $REPLY ]] && INSTALL_PLAYER_LIST=true

    read -p "  Install Custom Server Sort (drag-drop)? (Y/n): " -n 1 -r
    output ""
    [[ $REPLY =~ ^[Yy]$ || -z $REPLY ]] && INSTALL_CUSTOM_SORT=true

    output ""

    # Theme configuration
    if [ "$INSTALL_UNIX_THEME" = true ]; then
        output "Step 2: Theme Configuration"
        output ""
        read -p "  App name (default: Sourby): " -r input
        APP_NAME="${input:-Sourby}"

        output "  Optional theme customization (leave blank to skip):"
        read -p "  Background image URL: " -r SOURBY_BACKGROUND
        read -p "  Logo image URL: " -r SOURBY_LOGO
        read -p "  Favicon image URL: " -r SOURBY_FAVICON
        output ""
    fi

    # Payment configuration
    if [ "$INSTALL_BILLING" = true ]; then
        output "Step 3: Payment Configuration"
        output ""
        read -p "  PayPal mode (sandbox/live, default: sandbox): " -r input
        PAYPAL_MODE="${input:-sandbox}"
        read -p "  PayPal Client ID: " -r PAYPAL_CLIENT_ID
        read -p "  PayPal Client Secret: " -r PAYPAL_CLIENT_SECRET
        read -p "  Stripe Public Key (optional): " -r STRIPE_KEY
        read -p "  Stripe Secret Key (optional): " -r STRIPE_SECRET
        output ""
    fi

    # Summary
    print_banner
    output "Installation Summary:"
    output ""
    [ "$INSTALL_UNIX_THEME" = true ] && output "  ${GREEN}✓${NC} Unix Theme v2 (${APP_NAME})"
    [ "$INSTALL_BILLING" = true ] && output "  ${GREEN}✓${NC} Billing System (PayPal: $PAYPAL_MODE)"
    [ "$INSTALL_PLAYER_LIST" = true ] && output "  ${GREEN}✓${NC} Player List addon"
    [ "$INSTALL_CUSTOM_SORT" = true ] && output "  ${GREEN}✓${NC} Custom Server Sort"
    output ""

    print_divider

    read -p "Proceed with installation? (y/N): " -n 1 -r
    output ""
    [[ ! $REPLY =~ ^[Yy]$ ]] && output "Installation cancelled." && exit 0

    output ""
    create_backup
    download_sourby

    # Install only selected addons
    log_info "Installing selected components..."
    output ""

    if [ "$INSTALL_UNIX_THEME" = true ]; then
        if [ -d "$EXTRACTED_DIR/Unix Theme v2/pterodactyl" ]; then
            log_info "Installing Unix Theme v2..."
            cp -r "$EXTRACTED_DIR/Unix Theme v2/pterodactyl"/* "$PTERODACTYL_PATH/"
            log_success "Unix Theme v2"
        fi
    fi

    if [ "$INSTALL_BILLING" = true ]; then
        if [ -d "$EXTRACTED_DIR/billing-system-v1x-v143/PanelFiles" ]; then
            log_info "Installing Billing System..."
            cp -r "$EXTRACTED_DIR/billing-system-v1x-v143/PanelFiles"/* "$PTERODACTYL_PATH/"
            log_success "Billing System"
        fi
    fi

    if [ "$INSTALL_PLAYER_LIST" = true ]; then
        if [ -d "$EXTRACTED_DIR/Player List & Counter 1.0/PanelFiles" ]; then
            log_info "Installing Player List..."
            cp -r "$EXTRACTED_DIR/Player List & Counter 1.0/PanelFiles"/* "$PTERODACTYL_PATH/"
            log_success "Player List"
        fi
    fi

    if [ "$INSTALL_CUSTOM_SORT" = true ]; then
        if [ -d "$EXTRACTED_DIR/custom-server-sort-v103" ]; then
            log_info "Installing Custom Server Sort..."
            find "$EXTRACTED_DIR/custom-server-sort-v103" \
                -type f ! -name "PanelEdit.txt" ! -name "README.md" \
                -exec bash -c '
                    rel="${1#'$EXTRACTED_DIR/custom-server-sort-v103/'}"
                    mkdir -p "$PTERODACTYL_PATH/${rel%/*}"
                    cp "$1" "$PTERODACTYL_PATH/$rel"
                ' _ {} \;
            log_success "Custom Server Sort"
        fi
    fi

    output ""

    # Install deps
    read -p "Install dependencies (composer + yarn)? (Y/n): " -n 1 -r
    output ""
    [[ $REPLY =~ ^[Yy]$ || -z $REPLY ]] && install_dependencies

    update_env
    prompt_provider_registration
    run_migrations
    build_frontend
    clear_caches

    rm -rf "$DOWNLOAD_DIR"

    print_banner
    output "${GREEN}✓ Installation Complete!${NC}"
    output ""
    print_next_steps
}

run_update() {
    print_banner
    check_root
    check_dependencies
    validate_pterodactyl
    ensure_backup_dir

    log_info "Updating Sourby from GitHub..."
    create_backup
    download_sourby
    install_addons
    install_dependencies
    update_env
    build_frontend
    clear_caches

    rm -rf "$DOWNLOAD_DIR"

    print_banner
    output "${GREEN}✓ Update Complete!${NC}"
    output ""
    log_info "Clear your browser cache (Ctrl+Shift+R) to see changes."
    output ""
}

run_uninstall() {
    print_banner
    check_root
    validate_pterodactyl

    log_warning "This will restore Sourby files from the latest backup."
    output ""

    read -p "Are you sure you want to uninstall? (y/N): " -n 1 -r
    output ""
    [[ ! $REPLY =~ ^[Yy]$ ]] && output "Uninstall cancelled." && exit 0

    output ""
    restore_from_backup

    print_banner
    output "${GREEN}✓ Uninstall Complete!${NC}"
    output ""
    log_info "Your Pterodactyl panel has been restored from backup."
    log_info "Verify functionality at your admin panel."
    output ""
}

run_restore() {
    ensure_backup_dir
    list_backups

    if [ ! -L "$LATEST_BACKUP" ]; then
        log_error "No backup available to restore from."
        exit 1
    fi

    read -p "Restore from latest backup? (y/N): " -n 1 -r
    output ""
    [[ ! $REPLY =~ ^[Yy]$ ]] && output "Restore cancelled." && exit 0

    output ""
    restore_from_backup
}

#==============================================================================
# NEXT STEPS
#==============================================================================
print_next_steps() {
    output "Next steps:"
    output ""
    output "  1. Access admin panel: ${CYAN}https://your-domain/admin${NC}"
    output ""
    output "  2. Verify Sourby theme is active"
    output ""
    output "  3. Manage addons:"
    output "     ${CYAN}- Theme Settings:${NC}  /admin/sourby"
    output "     ${CYAN}- Shop Settings:${NC}  /admin/shop/settings"
    output "     ${CYAN}- Player Counter:${NC} /admin/players"
    output ""
    output "  4. Backup location: ${CYAN}$LATEST_BACKUP${NC}"
    output ""
    output "  Documentation: ${CYAN}SOURBY_INTEGRATION.md${NC}"
    output ""
}

#==============================================================================
# WELCOME
#==============================================================================
welcome() {
    print_banner
    output "Sourby Unified Installer - Installation, Updates & Management"
    output ""
    output "  ${GREEN}◆${NC} Install Sourby addons & theme onto an existing Pterodactyl panel"
    output "  ${GREEN}◆${NC} Automatic backup before every operation"
    output "  ${GREEN}◆${NC} Supports interactive (./install.sh) and piped (curl | bash) modes"
    output ""
    print_divider
}

#==============================================================================
# SELF-UPDATE LIB (download latest lib.sh)
#==============================================================================
update_lib_source() {
    local remote_lib="$GITHUB_BASE_URL/$GITHUB_SOURCE/lib/lib.sh?t=$(date +%s)"

    if curl -sSL -o /tmp/sourby-lib.sh "$remote_lib" 2>/dev/null && \
       head -1 /tmp/sourby-lib.sh | grep -q '#!/bin/bash'; then
        # shellcheck source=/dev/null
        source /tmp/sourby-lib.sh
    fi
}
