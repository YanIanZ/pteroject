#!/bin/bash

# Sourby Unified Installer - Complete Installation, Configuration & Management
# Combines setup wizard, backup/restore, and install/uninstall in one script
# Usage: curl -fsSL https://raw.githubusercontent.com/YanIanZ/pteroject/main/sourby-installer.sh | bash
# Or: ./sourby-installer.sh

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
GITHUB_REPO="YanIanZ/pteroject"
GITHUB_BRANCH="main"
DOWNLOAD_DIR="${DOWNLOAD_DIR:-/tmp/sourby-installer}"
PTERODACTYL_PATH="${PTERODACTYL_PATH:-/var/www/pterodactyl}"
BACKUP_BASE_DIR="/var/backups/sourby"
LATEST_BACKUP="${BACKUP_BASE_DIR}/latest"

# Installation options (default all true, user can select)
INSTALL_UNIX_THEME=true
INSTALL_BILLING=true
INSTALL_PLAYER_LIST=true
INSTALL_CUSTOM_SORT=true
INSTALL_DEPS=true

# Configuration variables
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

# Detect if running via curl pipe
RUNNING_PIPED=false
if [ -t 0 ]; then
    RUNNING_PIPED=false
else
    RUNNING_PIPED=true
fi

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

print_header() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║        Sourby Unified Installer v1.0       ║${NC}"
    echo -e "${GREEN}║  Installation • Configuration • Management  ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════╝${NC}"
    echo ""
}

print_divider() {
    echo -e "${CYAN}────────────────────────────────────────────${NC}"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

check_dependencies() {
    log_info "Checking dependencies..."

    for cmd in curl unzip php composer git yarn; do
        if ! command -v $cmd &> /dev/null; then
            log_error "$cmd not found. Please install it and try again."
            exit 1
        fi
        log_success "$cmd found"
    done
    echo ""
}

validate_pterodactyl() {
    log_info "Validating Pterodactyl installation..."

    if [ ! -d "$PTERODACTYL_PATH" ]; then
        log_error "Pterodactyl not found at $PTERODACTYL_PATH"
        echo "Set PTERODACTYL_PATH environment variable and try again:"
        echo "  PTERODACTYL_PATH=/custom/path sudo $0"
        exit 1
    fi

    if [ ! -f "$PTERODACTYL_PATH/artisan" ]; then
        log_error "Pterodactyl artisan not found. Invalid path?"
        exit 1
    fi

    log_success "Pterodactyl found at $PTERODACTYL_PATH"
    echo ""
}

create_backup_dir() {
    mkdir -p "$BACKUP_BASE_DIR"
    log_success "Backup directory ready: $BACKUP_BASE_DIR"
}

# ============================================================================
# BACKUP & RESTORE
# ============================================================================

backup_files() {
    local backup_path="$BACKUP_BASE_DIR/sourby-backup-$(date +%Y%m%d-%H%M%S)"

    log_info "Creating backup at $backup_path..."
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
            log_success "Backed up $file"
        fi
    done

    rm -f "$LATEST_BACKUP"
    ln -s "$backup_path" "$LATEST_BACKUP"

    log_success "Backup complete: $backup_path"
    echo ""
}

list_backups() {
    echo ""
    log_info "Sourby backups:"

    if [ ! -d "$BACKUP_BASE_DIR" ]; then
        log_warning "No backups found"
        return
    fi

    if [ "$(ls -A $BACKUP_BASE_DIR)" ]; then
        ls -lh "$BACKUP_BASE_DIR" | grep -v "^total" | grep -v "^d.*latest" | awk '{print "  " $9 " (" $5 ")"}'
    else
        log_warning "No backups found"
    fi
    echo ""
}

restore_from_backup() {
    if [ ! -L "$LATEST_BACKUP" ]; then
        log_error "No backup found. Cannot restore."
        exit 1
    fi

    local backup_path=$(readlink "$LATEST_BACKUP")
    log_info "Restoring from: $backup_path"
    echo ""

    # Remove Sourby files
    log_info "Removing Sourby files..."
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
            log_success "Removed $file"
        fi
    done
    echo ""

    # Restore from backup
    log_info "Restoring from backup..."
    for file in "${files[@]}"; do
        local src="$backup_path/$file"
        local dst="$PTERODACTYL_PATH/$file"

        if [ -e "$src" ]; then
            mkdir -p "$(dirname "$dst")"
            cp -r "$src" "$dst"
            log_success "Restored $file"
        fi
    done
    echo ""

    clear_caches

    log_success "Restoration complete"
    echo ""
}

# ============================================================================
# DOWNLOAD & EXTRACT
# ============================================================================

download_sourby() {
    log_info "Downloading Sourby from GitHub..."
    mkdir -p "$DOWNLOAD_DIR"
    cd "$DOWNLOAD_DIR"

    local download_url="https://github.com/$GITHUB_REPO/archive/refs/heads/$GITHUB_BRANCH.zip"
    log_info "Repository: $GITHUB_REPO ($GITHUB_BRANCH)"

    if curl -fsSL "$download_url" -o sourby.zip; then
        log_success "Downloaded"
    else
        log_error "Download failed"
        exit 1
    fi

    log_info "Extracting..."
    unzip -oq sourby.zip
    EXTRACTED_DIR="pteroject-${GITHUB_BRANCH}"
    if [ ! -d "$EXTRACTED_DIR" ]; then
        log_error "Extraction failed"
        exit 1
    fi
    log_success "Extracted"
    echo ""
}

# ============================================================================
# INSTALLATION
# ============================================================================

install_addons() {
    log_info "Installing selected components..."
    echo ""

    if [ "$INSTALL_UNIX_THEME" = true ]; then
        if [ -d "$EXTRACTED_DIR/Unix Theme v2/pterodactyl" ]; then
            log_info "Installing Unix Theme v2..."
            cp -r "$EXTRACTED_DIR/Unix Theme v2/pterodactyl"/* "$PTERODACTYL_PATH/"
            log_success "Unix Theme v2 installed"
        fi
    fi

    if [ "$INSTALL_BILLING" = true ]; then
        if [ -d "$EXTRACTED_DIR/billing-system-v1x-v143/PanelFiles" ]; then
            log_info "Installing Billing System..."
            cp -r "$EXTRACTED_DIR/billing-system-v1x-v143/PanelFiles"/* "$PTERODACTYL_PATH/"
            log_success "Billing System installed"
        fi
    fi

    if [ "$INSTALL_PLAYER_LIST" = true ]; then
        if [ -d "$EXTRACTED_DIR/Player List & Counter 1.0/PanelFiles" ]; then
            log_info "Installing Player List addon..."
            cp -r "$EXTRACTED_DIR/Player List & Counter 1.0/PanelFiles"/* "$PTERODACTYL_PATH/"
            log_success "Player List addon installed"
        fi
    fi

    if [ "$INSTALL_CUSTOM_SORT" = true ]; then
        if [ -d "$EXTRACTED_DIR/custom-server-sort-v103" ]; then
            log_info "Installing Custom Server Sort..."
            find "$EXTRACTED_DIR/custom-server-sort-v103" -type f ! -name "PanelEdit.txt" ! -name "README.md" -exec bash -c 'rel="${1#'"$EXTRACTED_DIR/custom-server-sort-v103/"'}"; mkdir -p "$PTERODACTYL_PATH/${rel%/*}"; cp "$1" "$PTERODACTYL_PATH/$rel"' _ {} \;
            log_success "Custom Server Sort installed"
        fi
    fi

    echo ""
}

install_dependencies() {
    log_info "Installing PHP and Node.js dependencies..."
    cd "$PTERODACTYL_PATH"

    log_info "Installing Composer packages..."
    if composer require --no-interaction paypal/checkout-sdk stripe/stripe-php; then
        log_success "PHP dependencies installed"
    else
        log_error "Failed to install PHP dependencies"
        log_info "Try manually: composer require paypal/checkout-sdk stripe/stripe-php"
        exit 1
    fi

    log_info "Installing Node.js packages..."
    if yarn add sortablejs; then
        log_success "Node.js dependencies installed"
    else
        log_error "Failed to install Node.js dependencies"
        log_info "Try manually: yarn add sortablejs"
        exit 1
    fi

    echo ""
}

update_env() {
    log_info "Updating .env configuration..."

    local env_file="$PTERODACTYL_PATH/.env"

    # Backup .env
    if [ -f "$env_file" ]; then
        cp "$env_file" "$env_file.bak"
    fi

    # Update or add APP_NAME
    if grep -q "^APP_NAME=" "$env_file" 2>/dev/null; then
        sed -i "s|^APP_NAME=.*|APP_NAME=\"$APP_NAME\"|" "$env_file"
    else
        echo "APP_NAME=\"$APP_NAME\"" >> "$env_file"
    fi

    # Update or add THEME
    if grep -q "^THEME=" "$env_file" 2>/dev/null; then
        sed -i "s|^THEME=.*|THEME=$THEME_NAME|" "$env_file"
    else
        echo "THEME=$THEME_NAME" >> "$env_file"
    fi

    # PayPal configuration
    if [ "$INSTALL_BILLING" = true ] && [ -n "$PAYPAL_CLIENT_ID" ]; then
        grep -q "^PAYPAL_MODE=" "$env_file" 2>/dev/null && sed -i "s|^PAYPAL_MODE=.*|PAYPAL_MODE=$PAYPAL_MODE|" "$env_file" || echo "PAYPAL_MODE=$PAYPAL_MODE" >> "$env_file"
        grep -q "^PAYPAL_CLIENT_ID=" "$env_file" 2>/dev/null && sed -i "s|^PAYPAL_CLIENT_ID=.*|PAYPAL_CLIENT_ID=$PAYPAL_CLIENT_ID|" "$env_file" || echo "PAYPAL_CLIENT_ID=$PAYPAL_CLIENT_ID" >> "$env_file"
        grep -q "^PAYPAL_CLIENT_SECRET=" "$env_file" 2>/dev/null && sed -i "s|^PAYPAL_CLIENT_SECRET=.*|PAYPAL_CLIENT_SECRET=$PAYPAL_CLIENT_SECRET|" "$env_file" || echo "PAYPAL_CLIENT_SECRET=$PAYPAL_CLIENT_SECRET" >> "$env_file"
    fi

    if [ -n "$STRIPE_KEY" ]; then
        grep -q "^STRIPE_PUBLIC_KEY=" "$env_file" 2>/dev/null && sed -i "s|^STRIPE_PUBLIC_KEY=.*|STRIPE_PUBLIC_KEY=$STRIPE_KEY|" "$env_file" || echo "STRIPE_PUBLIC_KEY=$STRIPE_KEY" >> "$env_file"
    fi

    if [ -n "$STRIPE_SECRET" ]; then
        grep -q "^STRIPE_SECRET_KEY=" "$env_file" 2>/dev/null && sed -i "s|^STRIPE_SECRET_KEY=.*|STRIPE_SECRET_KEY=$STRIPE_SECRET|" "$env_file" || echo "STRIPE_SECRET_KEY=$STRIPE_SECRET" >> "$env_file"
    fi

    # Theme customization
    if [ "$INSTALL_UNIX_THEME" = true ]; then
        [ -n "$SOURBY_BACKGROUND" ] && (grep -q "^SOURBY_BACKGROUND=" "$env_file" 2>/dev/null && sed -i "s|^SOURBY_BACKGROUND=.*|SOURBY_BACKGROUND=$SOURBY_BACKGROUND|" "$env_file" || echo "SOURBY_BACKGROUND=$SOURBY_BACKGROUND" >> "$env_file")
        [ -n "$SOURBY_LOGO" ] && (grep -q "^SOURBY_LOGO=" "$env_file" 2>/dev/null && sed -i "s|^SOURBY_LOGO=.*|SOURBY_LOGO=$SOURBY_LOGO|" "$env_file" || echo "SOURBY_LOGO=$SOURBY_LOGO" >> "$env_file")
        [ -n "$SOURBY_FAVICON" ] && (grep -q "^SOURBY_FAVICON=" "$env_file" 2>/dev/null && sed -i "s|^SOURBY_FAVICON=.*|SOURBY_FAVICON=$SOURBY_FAVICON|" "$env_file" || echo "SOURBY_FAVICON=$SOURBY_FAVICON" >> "$env_file")
    fi

    # Addon feature flags
    grep -q "^SOURBY_BILLING_ENABLED=" "$env_file" 2>/dev/null && sed -i "s|^SOURBY_BILLING_ENABLED=.*|SOURBY_BILLING_ENABLED=$([ "$INSTALL_BILLING" = true ] && echo 'true' || echo 'false')|" "$env_file" || echo "SOURBY_BILLING_ENABLED=$([ "$INSTALL_BILLING" = true ] && echo 'true' || echo 'false')" >> "$env_file"
    grep -q "^SOURBY_PLAYER_LIST_ENABLED=" "$env_file" 2>/dev/null && sed -i "s|^SOURBY_PLAYER_LIST_ENABLED=.*|SOURBY_PLAYER_LIST_ENABLED=$([ "$INSTALL_PLAYER_LIST" = true ] && echo 'true' || echo 'false')|" "$env_file" || echo "SOURBY_PLAYER_LIST_ENABLED=$([ "$INSTALL_PLAYER_LIST" = true ] && echo 'true' || echo 'false')" >> "$env_file"
    grep -q "^SOURBY_CUSTOM_SORT_ENABLED=" "$env_file" 2>/dev/null && sed -i "s|^SOURBY_CUSTOM_SORT_ENABLED=.*|SOURBY_CUSTOM_SORT_ENABLED=$([ "$INSTALL_CUSTOM_SORT" = true ] && echo 'true' || echo 'false')|" "$env_file" || echo "SOURBY_CUSTOM_SORT_ENABLED=$([ "$INSTALL_CUSTOM_SORT" = true ] && echo 'true' || echo 'false')" >> "$env_file"

    log_success ".env updated"
    echo ""
}

register_provider() {
    if [ "$INSTALL_UNIX_THEME" = false ]; then
        return
    fi

    echo -e "${YELLOW}Manual Step Required${NC}"
    echo ""
    echo "Register the Sourby service provider in Pterodactyl installation."
    echo ""
    echo "Edit ${CYAN}bootstrap/app.php${NC}:"
    echo "  Add to withProviders():"
    echo "    ${CYAN}Pterodactyl\\Providers\\SourbyThemeServiceProvider::class,${NC}"
    echo ""
    echo "Or edit ${CYAN}config/app.php${NC}:"
    echo "  Add to 'providers' array:"
    echo "    ${CYAN}Pterodactyl\\Providers\\SourbyThemeServiceProvider::class,${NC}"
    echo ""

    if [ "$RUNNING_PIPED" = false ]; then
        read -p "Press Enter after registering... " -t 30 || true
    else
        log_warning "Complete registration first, then run migrations."
        exit 0
    fi

    echo ""
}

run_migrations() {
    log_info "Running migrations..."
    cd "$PTERODACTYL_PATH"

    if php artisan migrate --force &> /dev/null; then
        log_success "Migrations completed"
    else
        log_error "Migrations failed"
        exit 1
    fi

    echo ""
}

build_frontend() {
    log_info "Building frontend assets..."
    cd "$PTERODACTYL_PATH"

    if [ -f "package.json" ]; then
        if yarn install &> /dev/null && yarn run build:production &> /dev/null; then
            log_success "Frontend built"
        else
            log_error "Frontend build failed"
            exit 1
        fi
    else
        log_warning "package.json not found, skipping frontend build"
    fi

    echo ""
}

clear_caches() {
    log_info "Clearing caches..."
    cd "$PTERODACTYL_PATH"

    php artisan route:clear &> /dev/null
    php artisan config:clear &> /dev/null
    php artisan view:clear &> /dev/null
    php artisan cache:clear &> /dev/null

    log_success "Caches cleared"
    echo ""
}

# ============================================================================
# INTERACTIVE MENUS
# ============================================================================

menu_main() {
    print_header
    check_root
    check_dependencies
    validate_pterodactyl
    create_backup_dir

    echo "What would you like to do?"
    echo ""
    echo "  1) Install Sourby (with setup)"
    echo "  2) Uninstall Sourby (restore from backup)"
    echo "  3) Reconfigure existing Sourby"
    echo "  4) View backup history"
    echo "  5) Exit"
    echo ""
    read -p "Select option (1-5): " choice

    case $choice in
        1) menu_install ;;
        2) uninstall_sourby ;;
        3) menu_reconfigure ;;
        4) list_backups; menu_main ;;
        5) exit 0 ;;
        *) log_error "Invalid option"; menu_main ;;
    esac
}

menu_install() {
    print_header
    echo "Step 1: Select Components"
    echo ""

    # Reset to defaults
    INSTALL_UNIX_THEME=true
    INSTALL_BILLING=true
    INSTALL_PLAYER_LIST=true
    INSTALL_CUSTOM_SORT=true

    read -p "  Install Unix Theme v2? (Y/n): " -n 1 -r
    echo ""
    [[ $REPLY =~ ^[Nn]$ ]] && INSTALL_UNIX_THEME=false

    read -p "  Install Billing System? (Y/n): " -n 1 -r
    echo ""
    [[ $REPLY =~ ^[Nn]$ ]] && INSTALL_BILLING=false

    read -p "  Install Player List? (Y/n): " -n 1 -r
    echo ""
    [[ $REPLY =~ ^[Nn]$ ]] && INSTALL_PLAYER_LIST=false

    read -p "  Install Custom Server Sort? (Y/n): " -n 1 -r
    echo ""
    [[ $REPLY =~ ^[Nn]$ ]] && INSTALL_CUSTOM_SORT=false

    menu_configure
}

menu_configure() {
    print_header
    echo "Step 2: Configuration"
    echo ""

    if [ "$INSTALL_UNIX_THEME" = true ]; then
        read -p "App name (default: Sourby): " -r input
        APP_NAME="${input:-Sourby}"

        echo ""
        log_info "Optional customization (leave blank to skip):"
        read -p "Background image URL: " -r SOURBY_BACKGROUND
        read -p "Logo image URL: " -r SOURBY_LOGO
        read -p "Favicon image URL: " -r SOURBY_FAVICON
    fi

    if [ "$INSTALL_BILLING" = true ]; then
        echo ""
        read -p "PayPal mode (sandbox/live, default: sandbox): " -r input
        PAYPAL_MODE="${input:-sandbox}"

        read -p "PayPal Client ID: " -r PAYPAL_CLIENT_ID
        read -p "PayPal Client Secret: " -r PAYPAL_CLIENT_SECRET
        read -p "Stripe API Key (optional): " -r STRIPE_KEY
        read -p "Stripe Secret Key (optional): " -r STRIPE_SECRET
    fi

    echo ""
    read -p "Install dependencies? (Y/n): " -n 1 -r
    echo ""
    [[ $REPLY =~ ^[Nn]$ ]] && INSTALL_DEPS=false

    menu_summary
}

menu_summary() {
    print_header
    echo "Installation Summary"
    echo ""
    echo "Components:"
    [ "$INSTALL_UNIX_THEME" = true ] && echo "  ✓ Unix Theme v2"
    [ "$INSTALL_BILLING" = true ] && echo "  ✓ Billing System"
    [ "$INSTALL_PLAYER_LIST" = true ] && echo "  ✓ Player List"
    [ "$INSTALL_CUSTOM_SORT" = true ] && echo "  ✓ Custom Server Sort"
    echo ""
    echo "Configuration:"
    [ "$INSTALL_UNIX_THEME" = true ] && echo "  Theme: $THEME_NAME (App: $APP_NAME)"
    [ "$INSTALL_BILLING" = true ] && echo "  PayPal: $PAYPAL_MODE"
    [ "$INSTALL_DEPS" = true ] && echo "  Dependencies: auto-install"
    echo ""

    print_divider
    echo ""
    read -p "Proceed with installation? (y/n): " -n 1 -r
    echo ""
    [[ ! $REPLY =~ ^[Yy]$ ]] && menu_main

    echo ""
    perform_install
}

menu_reconfigure() {
    print_header
    echo "Reconfigure Existing Sourby"
    echo ""

    menu_configure

    log_info "Updating configuration..."
    update_env
    clear_caches

    log_success "Sourby reconfigured!"
    echo ""
    menu_main
}

# ============================================================================
# INSTALLATION FLOW
# ============================================================================

perform_install() {
    backup_files
    download_sourby
    install_addons
    [ "$INSTALL_DEPS" = true ] && install_dependencies
    update_env
    register_provider
    run_migrations
    build_frontend
    clear_caches

    print_header
    echo -e "${GREEN}Installation Complete! ✓${NC}"
    echo ""
    echo "Next steps:"
    echo ""
    echo "  1. Access admin panel:"
    echo "     ${CYAN}https://your-domain/admin${NC}"
    echo ""
    echo "  2. Verify Sourby theme is active"
    echo ""
    [ "$INSTALL_BILLING" = true ] && echo "  3. Configure PayPal in:"
    [ "$INSTALL_BILLING" = true ] && echo "     ${CYAN}/admin/shop/settings${NC}"
    echo ""
    [ "$INSTALL_PLAYER_LIST" = true ] && echo "  4. Player counter in:"
    [ "$INSTALL_PLAYER_LIST" = true ] && echo "     ${CYAN}/admin/players${NC}"
    echo ""
    echo "Backup: $LATEST_BACKUP"
    echo ""

    rm -rf "$DOWNLOAD_DIR"
}

uninstall_sourby() {
    print_header
    echo "Uninstall Sourby"
    echo ""
    log_warning "This will restore from the latest backup."
    echo ""
    read -p "Are you sure? (y/n): " -n 1 -r
    echo ""
    [[ ! $REPLY =~ ^[Yy]$ ]] && menu_main

    echo ""
    restore_from_backup

    log_success "Sourby uninstalled!"
    echo ""
    menu_main
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    if [ "$RUNNING_PIPED" = true ]; then
        # Piped mode - full auto-install with setup prompts
        print_header
        check_root
        check_dependencies
        validate_pterodactyl
        create_backup_dir
        backup_files
        download_sourby
        install_addons
        install_dependencies
        update_env
        register_provider
        run_migrations
        build_frontend
        clear_caches

        echo -e "${GREEN}╔════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║    Installation Complete! ✓               ║${NC}"
        echo -e "${GREEN}╚════════════════════════════════════════════╝${NC}"
        echo ""
        echo "Access admin: https://your-domain/admin"
        echo "Backup: $LATEST_BACKUP"
        echo ""

        rm -rf "$DOWNLOAD_DIR"
    else
        # Interactive mode - show menu
        menu_main
    fi
}

main
exit 0
