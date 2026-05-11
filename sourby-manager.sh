#!/bin/bash

# Sourby Manager - Installation and Uninstallation with Backup/Restore
# Full automation for Sourby installation, backup, and uninstallation
# Usage: curl -fsSL https://raw.githubusercontent.com/YanIanZ/pteroject/main/sourby-manager.sh | bash
# Or: ./sourby-manager.sh

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
DOWNLOAD_DIR="${DOWNLOAD_DIR:-/tmp/sourby-manager}"
PTERODACTYL_PATH="${PTERODACTYL_PATH:-/var/www/pterodactyl}"
BACKUP_BASE_DIR="/var/backups/sourby"
LATEST_BACKUP="${BACKUP_BASE_DIR}/latest"

# Sourby files to backup/restore
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
    echo -e "${GREEN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║           Sourby Manager v1.0              ║${NC}"
    echo -e "${GREEN}║  Installation & Uninstallation with        ║${NC}"
    echo -e "${GREEN}║  Backup & Restore                          ║${NC}"
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

# Create backup directory
create_backup_dir() {
    mkdir -p "$BACKUP_BASE_DIR"
    log_success "Backup directory ready: $BACKUP_BASE_DIR"
}

# Backup Pterodactyl files
backup_files() {
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

    # Update latest symlink
    rm -f "$LATEST_BACKUP"
    ln -s "$backup_path" "$LATEST_BACKUP"

    log_success "Backup complete: $backup_path"
    echo ""
}

# Download Sourby from GitHub
download_sourby() {
    log_info "Downloading Sourby from GitHub..."
    mkdir -p "$DOWNLOAD_DIR"
    cd "$DOWNLOAD_DIR"

    local download_url="https://github.com/$GITHUB_REPO/archive/refs/heads/$GITHUB_BRANCH.zip"
    log_info "Repository: $GITHUB_REPO ($GITHUB_BRANCH)"
    log_info "Downloading: $download_url"

    if curl -fsSL "$download_url" -o sourby.zip; then
        log_success "Downloaded"
    else
        log_error "Download failed"
        exit 1
    fi

    # Extract
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

# Install all addons
install_addons() {
    log_info "Installing Sourby addons..."

    # Unix Theme v2
    if [ -d "$EXTRACTED_DIR/Unix Theme v2/pterodactyl" ]; then
        log_info "Installing Unix Theme v2..."
        cp -r "$EXTRACTED_DIR/Unix Theme v2/pterodactyl"/* "$PTERODACTYL_PATH/"
        log_success "Unix Theme v2 installed"
    fi

    # Billing System
    if [ -d "$EXTRACTED_DIR/billing-system-v1x-v143/PanelFiles" ]; then
        log_info "Installing Billing System..."
        cp -r "$EXTRACTED_DIR/billing-system-v1x-v143/PanelFiles"/* "$PTERODACTYL_PATH/"
        log_success "Billing System installed"
    fi

    # Player List
    if [ -d "$EXTRACTED_DIR/Player List & Counter 1.0/PanelFiles" ]; then
        log_info "Installing Player List addon..."
        cp -r "$EXTRACTED_DIR/Player List & Counter 1.0/PanelFiles"/* "$PTERODACTYL_PATH/"
        log_success "Player List addon installed"
    fi

    # Custom Server Sort
    if [ -d "$EXTRACTED_DIR/custom-server-sort-v103" ]; then
        log_info "Installing Custom Server Sort..."
        find "$EXTRACTED_DIR/custom-server-sort-v103" -type f ! -name "PanelEdit.txt" ! -name "README.md" -exec bash -c 'rel="${1#'"$EXTRACTED_DIR/custom-server-sort-v103/"'}"; mkdir -p "$PTERODACTYL_PATH/${rel%/*}"; cp "$1" "$PTERODACTYL_PATH/$rel"' _ {} \;
        log_success "Custom Server Sort installed"
    fi

    echo ""
}

# Ask to install dependencies
ask_install_dependencies() {
    echo ""
    log_info "Required dependencies:"
    echo "  - paypal/checkout-sdk (PayPal payments)"
    echo "  - stripe/stripe-php (Stripe payments)"
    echo "  - sortablejs (drag-drop server sort)"
    echo ""

    if [ "$RUNNING_PIPED" = true ]; then
        # In piped mode, install automatically
        return 0
    fi

    read -p "Install dependencies? (y/n): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_warning "Skipping dependency installation"
        log_warning "You must install manually:"
        echo "  cd $PTERODACTYL_PATH"
        echo "  composer require paypal/checkout-sdk stripe/stripe-php"
        echo "  yarn add sortablejs"
        return 1
    fi
    return 0
}

# Install dependencies
install_dependencies() {
    log_info "Installing PHP and Node.js dependencies..."
    cd "$PTERODACTYL_PATH"

    log_info "Installing Composer packages..."
    if composer require --no-interaction paypal/checkout-sdk stripe/stripe-php &> /dev/null; then
        log_success "PHP dependencies installed (paypal/checkout-sdk, stripe/stripe-php)"
    else
        log_error "Failed to install PHP dependencies"
        exit 1
    fi

    log_info "Installing Node.js packages..."
    if yarn add sortablejs &> /dev/null; then
        log_success "Node.js dependencies installed (sortablejs)"
    else
        log_error "Failed to install Node.js dependencies"
        exit 1
    fi

    echo ""
}

# Register service provider (manual step)
register_provider() {
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
        log_warning "Complete manual registration, then continue with remaining setup:"
        echo ""
        echo "  cd $PTERODACTYL_PATH"
        echo "  php artisan migrate"
        echo "  yarn install && yarn run build:production"
        echo "  php artisan cache:clear"
        echo ""
        log_warning "Run these commands to complete the installation"
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

# Uninstall Sourby
uninstall_sourby() {
    log_warning "Uninstalling Sourby and restoring from backup..."
    echo ""

    if [ ! -L "$LATEST_BACKUP" ]; then
        log_error "No backup found. Cannot uninstall safely."
        exit 1
    fi

    local backup_path=$(readlink "$LATEST_BACKUP")
    log_info "Restoring from: $backup_path"
    echo ""

    # Remove Sourby files
    log_info "Removing Sourby files..."
    for file in "${SOURBY_FILES[@]}"; do
        local target="$PTERODACTYL_PATH/$file"
        if [ -e "$target" ]; then
            rm -rf "$target"
            log_success "Removed $file"
        fi
    done
    echo ""

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
    echo ""

    # Clear caches
    clear_caches

    log_success "Uninstallation complete"
    echo ""
    log_info "Verify that your Pterodactyl panel works correctly."
    log_info "Check /admin panel to confirm."
}

# Show menu
show_menu() {
    echo ""
    echo -e "${BLUE}What would you like to do?${NC}"
    echo ""
    echo "  1) Install Sourby (full installation with backup)"
    echo "  2) Uninstall Sourby (restore from latest backup)"
    echo "  3) List backup history"
    echo "  4) Exit"
    echo ""
    read -p "Select option (1-4): " choice

    case $choice in
        1) return 0 ;;
        2) return 1 ;;
        3) show_backups; show_menu; show_menu ;;
        4) exit 0 ;;
        *) log_error "Invalid option"; show_menu; show_menu ;;
    esac
}

# Show backup history
show_backups() {
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

# Main installation flow
install_sourby() {
    print_header
    check_root
    check_dependencies
    validate_pterodactyl
    create_backup_dir
    backup_files
    download_sourby
    install_addons
    ask_install_dependencies && install_dependencies
    register_provider
    run_migrations
    build_frontend
    clear_caches

    echo -e "${GREEN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║    Sourby Installation Complete! ✓         ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════╝${NC}"
    echo ""

    echo "Next steps:"
    echo ""
    echo "1. Update .env file:"
    echo "   APP_NAME=Sourby"
    echo "   THEME=sourby-unix"
    echo "   SOURBY_BILLING_ENABLED=true"
    echo "   SOURBY_PLAYER_LIST_ENABLED=true"
    echo "   SOURBY_CUSTOM_SORT_ENABLED=true"
    echo ""
    echo "2. Access admin panel:"
    echo "   https://your-domain/admin"
    echo ""
    echo "3. Configure addons:"
    echo "   - Theme: /admin/sourby"
    echo "   - Shop: /admin/shop/settings"
    echo "   - Players: /admin/players"
    echo ""
    echo "Backup location: $LATEST_BACKUP"
    echo ""

    # Cleanup
    rm -rf "$DOWNLOAD_DIR"
}

# Main
if [ "$RUNNING_PIPED" = true ]; then
    # Piped mode - just install
    install_sourby
else
    # Interactive mode
    print_header
    check_root
    check_dependencies
    validate_pterodactyl
    create_backup_dir

    show_menu
    if [ $? -eq 0 ]; then
        install_sourby
    else
        uninstall_sourby
    fi
fi

exit 0
