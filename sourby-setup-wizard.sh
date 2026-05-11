#!/bin/bash

# Sourby Setup Wizard - Complete interactive setup with addon/theme selection
# Full automation: backup, install, PayPal setup, theme config, addon setup
# Usage: curl -fsSL https://raw.githubusercontent.com/YanIanZ/pteroject/main/sourby-setup-wizard.sh | bash
# Or: ./sourby-setup-wizard.sh

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
GITHUB_REPO="YanIanZ/pteroject"
GITHUB_BRANCH="main"
DOWNLOAD_DIR="${DOWNLOAD_DIR:-/tmp/sourby-setup}"
PTERODACTYL_PATH="${PTERODACTYL_PATH:-/var/www/pterodactyl}"
BACKUP_BASE_DIR="/var/backups/sourby"
LATEST_BACKUP="${BACKUP_BASE_DIR}/latest"

# Features to install (default all false, user selects)
INSTALL_UNIX_THEME=false
INSTALL_BILLING=false
INSTALL_PLAYER_LIST=false
INSTALL_CUSTOM_SORT=false

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

# Helper functions
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
    echo -e "${GREEN}║      Sourby Setup Wizard v1.0              ║${NC}"
    echo -e "${GREEN}║  Complete Interactive Configuration        ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════╝${NC}"
    echo ""
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

# Check dependencies
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

# Validate Pterodactyl installation
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

# Interactive addon selection
select_addons() {
    print_header
    echo "Step 1: Select Components to Install"
    echo ""
    echo "Which Sourby components do you want to install?"
    echo ""

    read -p "  Install Unix Theme v2 (modern dark theme)? (y/n): " -n 1 -r
    echo ""
    [[ $REPLY =~ ^[Yy]$ ]] && INSTALL_UNIX_THEME=true

    read -p "  Install Billing System (PayPal/Stripe)? (y/n): " -n 1 -r
    echo ""
    [[ $REPLY =~ ^[Yy]$ ]] && INSTALL_BILLING=true

    read -p "  Install Player List (real-time counter)? (y/n): " -n 1 -r
    echo ""
    [[ $REPLY =~ ^[Yy]$ ]] && INSTALL_PLAYER_LIST=true

    read -p "  Install Custom Server Sort (drag-drop)? (y/n): " -n 1 -r
    echo ""
    [[ $REPLY =~ ^[Yy]$ ]] && INSTALL_CUSTOM_SORT=true

    echo ""
    log_success "Components selected"
    echo ""
}

# Theme configuration
configure_theme() {
    if [ "$INSTALL_UNIX_THEME" = false ]; then
        return
    fi

    print_header
    echo "Step 2: Theme Configuration"
    echo ""

    read -p "App name (default: Sourby): " -r input
    APP_NAME="${input:-Sourby}"

    echo ""
    log_info "Optional theme customization (leave blank to skip):"
    echo ""

    read -p "Background image URL: " -r SOURBY_BACKGROUND
    read -p "Logo image URL: " -r SOURBY_LOGO
    read -p "Favicon image URL: " -r SOURBY_FAVICON

    echo ""
    log_success "Theme configured"
    echo ""
}

# PayPal setup
configure_paypal() {
    if [ "$INSTALL_BILLING" = false ]; then
        return
    fi

    print_header
    echo "Step 3: PayPal Setup"
    echo ""

    read -p "PayPal mode (sandbox/live, default: sandbox): " -r input
    PAYPAL_MODE="${input:-sandbox}"

    echo ""
    read -p "PayPal Client ID: " -r PAYPAL_CLIENT_ID
    if [ -z "$PAYPAL_CLIENT_ID" ]; then
        log_warning "PayPal Client ID not provided. Billing will not work."
    fi

    echo ""
    read -p "PayPal Client Secret: " -r PAYPAL_CLIENT_SECRET
    if [ -z "$PAYPAL_CLIENT_SECRET" ]; then
        log_warning "PayPal Secret not provided. Billing will not work."
    fi

    echo ""
    read -p "Stripe API Key (optional): " -r STRIPE_KEY
    read -p "Stripe Secret Key (optional): " -r STRIPE_SECRET

    echo ""
    log_success "PayPal configured"
    echo ""
}

# Create backup directory
create_backup_dir() {
    mkdir -p "$BACKUP_BASE_DIR"
    log_success "Backup directory ready: $BACKUP_BASE_DIR"
}

# Backup existing files
backup_files() {
    local backup_path="$BACKUP_BASE_DIR/sourby-backup-$(date +%Y%m%d-%H%M%S)"

    log_info "Creating backup at $backup_path..."
    mkdir -p "$backup_path"

    # Backup files that might be overwritten
    for file in "app/Providers/SourbyThemeServiceProvider.php" "config/sourby.php" "routes/sourby.php" ".env"; do
        local src="$PTERODACTYL_PATH/$file"
        local dst="$backup_path/$file"

        if [ -e "$src" ]; then
            mkdir -p "$(dirname "$dst")"
            cp -r "$src" "$dst"
            log_success "Backed up $file"
        fi
    done

    # Update latest symlink
    rm -f "$LATEST_BACKUP"
    ln -s "$backup_path" "$LATEST_BACKUP"

    log_success "Backup complete: $backup_path"
    echo ""
}

# Download Sourby
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
    unzip -q sourby.zip
    EXTRACTED_DIR="pteroject-${GITHUB_BRANCH}"
    if [ ! -d "$EXTRACTED_DIR" ]; then
        log_error "Extraction failed"
        exit 1
    fi
    log_success "Extracted"
    echo ""
}

# Install selected addons
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

# Install dependencies
install_dependencies() {
    log_info "Installing dependencies..."
    cd "$PTERODACTYL_PATH"

    if composer require --no-interaction paypal/checkout-sdk stripe/stripe-php &> /dev/null; then
        log_success "PHP dependencies installed"
    else
        log_error "Failed to install PHP dependencies"
        exit 1
    fi

    if yarn add sortablejs &> /dev/null; then
        log_success "Node.js dependencies installed"
    else
        log_error "Failed to install Node.js dependencies"
        exit 1
    fi

    echo ""
}

# Update .env file
update_env() {
    log_info "Updating .env configuration..."

    local env_file="$PTERODACTYL_PATH/.env"

    # Backup .env
    cp "$env_file" "$env_file.bak"

    # Update or add APP_NAME
    if grep -q "^APP_NAME=" "$env_file"; then
        sed -i "s|^APP_NAME=.*|APP_NAME=\"$APP_NAME\"|" "$env_file"
    else
        echo "APP_NAME=\"$APP_NAME\"" >> "$env_file"
    fi

    # Update or add THEME
    if grep -q "^THEME=" "$env_file"; then
        sed -i "s|^THEME=.*|THEME=$THEME_NAME|" "$env_file"
    else
        echo "THEME=$THEME_NAME" >> "$env_file"
    fi

    # PayPal configuration
    if [ "$INSTALL_BILLING" = true ]; then
        if grep -q "^PAYPAL_MODE=" "$env_file"; then
            sed -i "s|^PAYPAL_MODE=.*|PAYPAL_MODE=$PAYPAL_MODE|" "$env_file"
        else
            echo "PAYPAL_MODE=$PAYPAL_MODE" >> "$env_file"
        fi

        if [ -n "$PAYPAL_CLIENT_ID" ]; then
            if grep -q "^PAYPAL_CLIENT_ID=" "$env_file"; then
                sed -i "s|^PAYPAL_CLIENT_ID=.*|PAYPAL_CLIENT_ID=$PAYPAL_CLIENT_ID|" "$env_file"
            else
                echo "PAYPAL_CLIENT_ID=$PAYPAL_CLIENT_ID" >> "$env_file"
            fi
        fi

        if [ -n "$PAYPAL_CLIENT_SECRET" ]; then
            if grep -q "^PAYPAL_CLIENT_SECRET=" "$env_file"; then
                sed -i "s|^PAYPAL_CLIENT_SECRET=.*|PAYPAL_CLIENT_SECRET=$PAYPAL_CLIENT_SECRET|" "$env_file"
            else
                echo "PAYPAL_CLIENT_SECRET=$PAYPAL_CLIENT_SECRET" >> "$env_file"
            fi
        fi

        if [ -n "$STRIPE_KEY" ]; then
            if grep -q "^STRIPE_PUBLIC_KEY=" "$env_file"; then
                sed -i "s|^STRIPE_PUBLIC_KEY=.*|STRIPE_PUBLIC_KEY=$STRIPE_KEY|" "$env_file"
            else
                echo "STRIPE_PUBLIC_KEY=$STRIPE_KEY" >> "$env_file"
            fi
        fi

        if [ -n "$STRIPE_SECRET" ]; then
            if grep -q "^STRIPE_SECRET_KEY=" "$env_file"; then
                sed -i "s|^STRIPE_SECRET_KEY=.*|STRIPE_SECRET_KEY=$STRIPE_SECRET|" "$env_file"
            else
                echo "STRIPE_SECRET_KEY=$STRIPE_SECRET" >> "$env_file"
            fi
        fi
    fi

    # Theme customization
    if [ "$INSTALL_UNIX_THEME" = true ]; then
        if [ -n "$SOURBY_BACKGROUND" ]; then
            if grep -q "^SOURBY_BACKGROUND=" "$env_file"; then
                sed -i "s|^SOURBY_BACKGROUND=.*|SOURBY_BACKGROUND=$SOURBY_BACKGROUND|" "$env_file"
            else
                echo "SOURBY_BACKGROUND=$SOURBY_BACKGROUND" >> "$env_file"
            fi
        fi

        if [ -n "$SOURBY_LOGO" ]; then
            if grep -q "^SOURBY_LOGO=" "$env_file"; then
                sed -i "s|^SOURBY_LOGO=.*|SOURBY_LOGO=$SOURBY_LOGO|" "$env_file"
            else
                echo "SOURBY_LOGO=$SOURBY_LOGO" >> "$env_file"
            fi
        fi

        if [ -n "$SOURBY_FAVICON" ]; then
            if grep -q "^SOURBY_FAVICON=" "$env_file"; then
                sed -i "s|^SOURBY_FAVICON=.*|SOURBY_FAVICON=$SOURBY_FAVICON|" "$env_file"
            else
                echo "SOURBY_FAVICON=$SOURBY_FAVICON" >> "$env_file"
            fi
        fi
    fi

    # Addon feature flags
    if grep -q "^SOURBY_BILLING_ENABLED=" "$env_file"; then
        sed -i "s|^SOURBY_BILLING_ENABLED=.*|SOURBY_BILLING_ENABLED=$([ "$INSTALL_BILLING" = true ] && echo 'true' || echo 'false')|" "$env_file"
    else
        echo "SOURBY_BILLING_ENABLED=$([ "$INSTALL_BILLING" = true ] && echo 'true' || echo 'false')" >> "$env_file"
    fi

    if grep -q "^SOURBY_PLAYER_LIST_ENABLED=" "$env_file"; then
        sed -i "s|^SOURBY_PLAYER_LIST_ENABLED=.*|SOURBY_PLAYER_LIST_ENABLED=$([ "$INSTALL_PLAYER_LIST" = true ] && echo 'true' || echo 'false')|" "$env_file"
    else
        echo "SOURBY_PLAYER_LIST_ENABLED=$([ "$INSTALL_PLAYER_LIST" = true ] && echo 'true' || echo 'false')" >> "$env_file"
    fi

    if grep -q "^SOURBY_CUSTOM_SORT_ENABLED=" "$env_file"; then
        sed -i "s|^SOURBY_CUSTOM_SORT_ENABLED=.*|SOURBY_CUSTOM_SORT_ENABLED=$([ "$INSTALL_CUSTOM_SORT" = true ] && echo 'true' || echo 'false')|" "$env_file"
    else
        echo "SOURBY_CUSTOM_SORT_ENABLED=$([ "$INSTALL_CUSTOM_SORT" = true ] && echo 'true' || echo 'false')" >> "$env_file"
    fi

    log_success ".env updated with configuration"
    echo ""
}

# Register service provider (manual step)
register_provider() {
    if [ "$INSTALL_UNIX_THEME" = false ]; then
        return
    fi

    echo -e "${YELLOW}Manual Step Required${NC}"
    echo ""
    echo "Register the Sourby service provider in your Pterodactyl installation."
    echo ""
    echo "Option 1 - Edit bootstrap/app.php:"
    echo "  Add to withProviders():"
    echo "    Pterodactyl\Providers\SourbyThemeServiceProvider::class,"
    echo ""
    echo "Option 2 - Edit config/app.php:"
    echo "  Add to 'providers' array:"
    echo "    Pterodactyl\Providers\SourbyThemeServiceProvider::class,"
    echo ""

    if [ "$RUNNING_PIPED" = false ]; then
        read -p "Press Enter after registering the provider... " -t 30 || true
    else
        log_warning "Complete manual registration first, then continue."
        exit 0
    fi

    echo ""
}

# Run migrations
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

# Build frontend
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

# Clear caches
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

# Show summary
show_summary() {
    print_header
    echo "Installation Summary"
    echo ""
    echo "Components installed:"
    [ "$INSTALL_UNIX_THEME" = true ] && echo "  ✓ Unix Theme v2"
    [ "$INSTALL_BILLING" = true ] && echo "  ✓ Billing System (PayPal/Stripe)"
    [ "$INSTALL_PLAYER_LIST" = true ] && echo "  ✓ Player List"
    [ "$INSTALL_CUSTOM_SORT" = true ] && echo "  ✓ Custom Server Sort"
    echo ""
    echo "Configuration:"
    echo "  App Name: $APP_NAME"
    [ "$INSTALL_UNIX_THEME" = true ] && echo "  Theme: $THEME_NAME"
    [ "$INSTALL_BILLING" = true ] && echo "  PayPal Mode: $PAYPAL_MODE"
    echo ""
    echo "Backup location: $LATEST_BACKUP"
    echo "Log file: /var/log/sourby-setup.log"
    echo ""
}

# Main installation flow
main() {
    print_header
    check_root
    check_dependencies
    validate_pterodactyl
    create_backup_dir

    # Only show interactive prompts if not piped
    if [ "$RUNNING_PIPED" = false ]; then
        select_addons
        configure_theme
        configure_paypal
    else
        # In piped mode, install everything
        INSTALL_UNIX_THEME=true
        INSTALL_BILLING=true
        INSTALL_PLAYER_LIST=true
        INSTALL_CUSTOM_SORT=true
    fi

    backup_files
    download_sourby
    install_addons

    # Ask about dependencies
    echo ""
    log_info "Required dependencies:"
    echo "  - paypal/checkout-sdk (PayPal payments)"
    echo "  - stripe/stripe-php (Stripe payments)"
    echo "  - sortablejs (drag-drop server sort)"
    echo ""

    if [ "$RUNNING_PIPED" = false ]; then
        read -p "Install dependencies? (y/n): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            install_dependencies
        else
            log_warning "Skipping dependency installation"
            log_warning "You must install manually:"
            echo "  cd $PTERODACTYL_PATH"
            echo "  composer require paypal/checkout-sdk stripe/stripe-php"
            echo "  yarn add sortablejs"
        fi
    else
        install_dependencies
    fi

    update_env
    register_provider
    run_migrations
    build_frontend
    clear_caches

    echo -e "${GREEN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║    Sourby Setup Complete! ✓               ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════╝${NC}"
    echo ""

    show_summary

    echo "Next steps:"
    echo ""
    echo "1. Access admin panel:"
    echo "   https://your-domain/admin"
    echo ""
    echo "2. Verify Sourby theme is active"
    echo ""
    echo "3. Configure addons (if installed):"
    [ "$INSTALL_BILLING" = true ] && echo "   - Shop Settings: /admin/shop/settings"
    [ "$INSTALL_PLAYER_LIST" = true ] && echo "   - Player Counter: /admin/players"
    echo ""
    echo "4. Test payments (if billing installed)"
    echo ""

    # Cleanup
    rm -rf "$DOWNLOAD_DIR"
}

# Run main
main
exit 0
