#!/bin/bash

######################################################################################
# Sourby Installer Library - Shared functionality for install.sh
######################################################################################

# Configuration
PTERODACTYL_PATH="${PTERODACTYL_PATH:-/var/www/pterodactyl}"
PANEL_URL="${PANEL_URL:-}"
APPLICATION_API_KEY="${APPLICATION_API_KEY:-}"
BACKUP_BASE_DIR="/var/backups/sourby"
GITHUB_REPO="YanIanZ/pteroject"
GITHUB_BRANCH="${GITHUB_SOURCE:-main}"
DOWNLOAD_DIR="/tmp/sourby-installer"

# Payment config (set during wizard)
PAYPAL_CLIENT_ID=""
PAYPAL_CLIENT_SECRET=""
PAYPAL_MODE="sandbox"
STRIPE_KEY=""
STRIPE_SECRET=""

# Detected flags
INSTALL_THEME=1
INSTALL_BILLING=1
INSTALL_PLAYERS=1
INSTALL_SORT=1

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
    echo -e "  ◆ Interactive mode:  ${CYAN}bash <(curl -s https://raw.githubusercontent.com/YanIanZ/pteroject/main/install.sh)${NC}"
    echo ""
    echo -e "${CYAN}────────────────────────────────────────────${NC}"
}

divider() {
    echo -e "${CYAN}────────────────────────────────────────────${NC}"
}

# ============================================================================
# INTERACTIVE INPUT (always reads from /dev/tty)
# ============================================================================

prompt() {
    # prompt "label" "default"
    local label="$1"
    local default="$2"

    if [ -n "$default" ]; then
        echo -n "* $label [$default]: " >/dev/tty
    else
        echo -n "* $label: " >/dev/tty
    fi
}

read_input() {
    local var_name="$1"
    local fallback="${2:-}"
    local value

    read -r value </dev/tty
    if [ -z "$value" ] && [ -n "$fallback" ]; then
        value="$fallback"
    fi

    # Write back to the named variable
    printf -v "$var_name" '%s' "$value"
}

read_yn() {
    # Returns 0 for yes, 1 for no
    local label="$1"
    local default_y="${2:-1}"  # 1 = default yes

    if [ "$default_y" -eq 1 ]; then
        echo -n "* $label (Y/n): " >/dev/tty
    else
        echo -n "* $label (y/N): " >/dev/tty
    fi

    read -r reply </dev/tty

    if [ "$default_y" -eq 1 ]; then
        [[ ! $reply =~ ^[Nn]$ ]]
    else
        [[ $reply =~ ^[Yy]$ ]]
    fi
}

# ============================================================================
# CONFIGURATION WIZARD (Pterodactyl API setup)
# ============================================================================

configure_panel() {
    output ""
    divider
    output ""
    echo -e "  ${CYAN}Pterodactyl Panel Configuration${NC}"
    output ""

    prompt "Panel URL (e.g. https://panel.yourdomain.com)" "$PANEL_URL"
    read_input PANEL_URL "$PANEL_URL"

    prompt "Application API Key (create at Admin → Application API)" "$APPLICATION_API_KEY"
    read_input APPLICATION_API_KEY "$APPLICATION_API_KEY"

    if [ -z "$PANEL_URL" ]; then
        warning "Panel URL not provided. You can set it later in .env"
    else
        success "Panel URL: $PANEL_URL"
    fi

    if [ -n "$APPLICATION_API_KEY" ]; then
        success "API Key configured"
    else
        warning "API Key not provided. Some features may not work."
    fi

    output ""
}

# ============================================================================
# COMPONENT SELECTION
# ============================================================================

configure_components() {
    output ""
    divider
    output ""
    echo -e "  ${CYAN}Addon Selection${NC}"
    output ""

    if ! read_yn "Install Unix Theme v2 (modern dark theme)?" 1; then
        INSTALL_THEME=0
    fi

    if ! read_yn "Install Billing System (PayPal/Stripe)?" 1; then
        INSTALL_BILLING=0
    fi

    if ! read_yn "Install Player List (real-time counter)?" 1; then
        INSTALL_PLAYERS=0
    fi

    if ! read_yn "Install Custom Server Sort (drag-drop)?" 1; then
        INSTALL_SORT=0
    fi

    output ""
    info "Selected:"
    [ "$INSTALL_THEME" -eq 1 ] && output "  ${GREEN}✓${NC} Unix Theme v2"
    [ "$INSTALL_BILLING" -eq 1 ] && output "  ${GREEN}✓${NC} Billing System"
    [ "$INSTALL_PLAYERS" -eq 1 ] && output "  ${GREEN}✓${NC} Player List"
    [ "$INSTALL_SORT" -eq 1 ] && output "  ${GREEN}✓${NC} Custom Server Sort"
    output ""
}

build_component_string() {
    local s=""
    [ "$INSTALL_THEME" -eq 1 ] && s="$s theme"
    [ "$INSTALL_BILLING" -eq 1 ] && s="$s billing"
    [ "$INSTALL_PLAYERS" -eq 1 ] && s="$s players"
    [ "$INSTALL_SORT" -eq 1 ] && s="$s sort"
    echo "${s# }"
}

# ============================================================================
# PAYMENT GATEWAY CONFIGURATION
# ============================================================================

configure_payments() {
    output ""
    divider
    output ""
    output "  ${CYAN}Payment Gateway Setup${NC}"
    output ""

    # PayPal
    echo -n "* PayPal mode (sandbox/live) [sandbox]: " >/dev/tty
    read_input PAYPAL_MODE "sandbox"

    echo -n "* PayPal Client ID: " >/dev/tty
    read_input PAYPAL_CLIENT_ID ""

    echo -n "* PayPal Client Secret: " >/dev/tty
    read_input PAYPAL_CLIENT_SECRET ""

    output ""

    # Stripe (optional)
    if read_yn "Configure Stripe as well?" 1; then
        echo -n "* Stripe Publishable Key: " >/dev/tty
        read_input STRIPE_KEY ""

        echo -n "* Stripe Secret Key: " >/dev/tty
        read_input STRIPE_SECRET ""

        if [ -n "$STRIPE_KEY" ] && [ -n "$STRIPE_SECRET" ]; then
            success "Stripe configured"
        fi
    fi

    if [ -n "$PAYPAL_CLIENT_ID" ] && [ -n "$PAYPAL_CLIENT_SECRET" ]; then
        success "PayPal configured ($PAYPAL_MODE)"
    elif [ -n "$STRIPE_KEY" ]; then
        success "Stripe only mode"
    else
        warning "No payment credentials provided. Billing will need manual .env setup."
    fi

    output ""
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

    if [ "$INSTALL_BILLING" -eq 1 ]; then
        output ""
        info "Installing payment SDKs (PayPal/Stripe)..."
        composer require paypal/checkout-sdk stripe/stripe-php --no-interaction 2>&1 | tail -1 || \
            warning "Payment SDKs install failed — install manually: composer require paypal/checkout-sdk stripe/stripe-php"
        success "Payment SDKs installed"
    fi

    output ""
}

update_env() {
    info "Updating .env configuration..."

    local env_file="$PTERODACTYL_PATH/.env"

    if [ -f "$env_file" ]; then
        cp "$env_file" "$env_file.bak"
    else
        warning ".env not found, creating from .env.example"
        if [ -f "$PTERODACTYL_PATH/.env.example" ]; then
            cp "$PTERODACTYL_PATH/.env.example" "$env_file"
        fi
    fi

    # App & theme
    set_env "APP_NAME" "\"Sourby\""
    set_env "THEME" "sourby-unix"

    # Panel configuration
    [ -n "$PANEL_URL" ] && set_env "APP_URL" "$PANEL_URL"
    [ -n "$APPLICATION_API_KEY" ] && set_env "SOURBY_API_KEY" "$APPLICATION_API_KEY"

    # Feature flags
    set_env "SOURBY_BILLING_ENABLED" "$([ "$INSTALL_BILLING" -eq 1 ] && echo 'true' || echo 'false')"
    set_env "SOURBY_PLAYER_LIST_ENABLED" "$([ "$INSTALL_PLAYERS" -eq 1 ] && echo 'true' || echo 'false')"
    set_env "SOURBY_CUSTOM_SORT_ENABLED" "$([ "$INSTALL_SORT" -eq 1 ] && echo 'true' || echo 'false')"

    # PayPal
    [ -n "$PAYPAL_MODE" ] && set_env "PAYPAL_MODE" "$PAYPAL_MODE"
    [ -n "$PAYPAL_CLIENT_ID" ] && set_env "PAYPAL_CLIENT_ID" "$PAYPAL_CLIENT_ID"
    [ -n "$PAYPAL_CLIENT_SECRET" ] && set_env "PAYPAL_CLIENT_SECRET" "$PAYPAL_CLIENT_SECRET"

    # Stripe
    [ -n "$STRIPE_KEY" ] && set_env "STRIPE_KEY" "$STRIPE_KEY"
    [ -n "$STRIPE_SECRET" ] && set_env "STRIPE_SECRET" "$STRIPE_SECRET"

    success ".env updated"
    output ""
}

set_env() {
    local key="$1"
    local value="$2"
    local env_file="$PTERODACTYL_PATH/.env"

    if grep -q "^${key}=" "$env_file" 2>/dev/null; then
        sed -i "s|^${key}=.*|${key}=${value}|" "$env_file"
    else
        echo "${key}=${value}" >> "$env_file"
    fi
}

register_provider() {
    info "Registering Sourby service provider..."

    local bootstrap_file="$PTERODACTYL_PATH/bootstrap/app.php"
    local config_file="$PTERODACTYL_PATH/config/app.php"
    local provider_class="Pterodactyl\Providers\SourbyThemeServiceProvider::class"

    if [ -f "$bootstrap_file" ]; then
        if ! grep -q "SourbyThemeServiceProvider" "$bootstrap_file"; then
            info "Auto-registering in bootstrap/app.php..."
            sed -i "/->withProviders(\[/a\        $provider_class," "$bootstrap_file" 2>/dev/null || true
            success "Service provider registered in bootstrap/app.php"
        else
            success "Service provider already registered"
        fi
        output ""
        return 0
    fi

    if [ -f "$config_file" ]; then
        if ! grep -q "SourbyThemeServiceProvider" "$config_file"; then
            info "Auto-registering in config/app.php..."
            sed -i "/'providers' => \[/a\        $provider_class," "$config_file" 2>/dev/null || true
            success "Service provider registered in config/app.php"
        else
            success "Service provider already registered"
        fi
        output ""
        return 0
    fi

    error "Could not find bootstrap/app.php or config/app.php"
    error "Please manually add to your Pterodactyl config:"
    echo "  $provider_class"
    output ""
    return 1
}

run_migrations() {
    info "Running migrations..."
    cd "$PTERODACTYL_PATH"

    php artisan migrate --force || { error "Migrations failed"; exit 1; }
    success "Migrations completed"
    output ""
}

build_frontend() {
    info "Building frontend assets (this may take a few minutes)..."
    cd "$PTERODACTYL_PATH"

    if [ ! -f "package.json" ]; then
        warning "package.json not found, skipping frontend build"
        output ""
        return
    fi

    # Check Node version
    local node_ver=$(node -v 2>/dev/null | sed 's/v//' | cut -d. -f1)
    if [ "$node_ver" -lt 22 ] 2>/dev/null; then
        warning "Node.js $(node -v) is older than required (>=22). Using --ignore-engines..."
        export YARN_IGNORE_ENGINES=true
        yarn install || { error "yarn install failed — upgrade Node to >=22"; exit 1; }
    else
        yarn install || { error "yarn install failed"; exit 1; }
    fi
    YARN_IGNORE_ENGINES=true yarn run build:production || { error "Frontend build failed"; exit 1; }

    success "Frontend built"
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
            # Interactive configuration (like Pterodactyl installer)
            configure_panel
            configure_components
            [ "$INSTALL_BILLING" -eq 1 ] && configure_payments
            divider

            create_backup
            download_sourby
            install_addons "$(build_component_string)"
            install_dependencies
            update_env
            register_provider || return
            run_migrations
            build_frontend
            clear_caches

            output ""
            echo -e "${GREEN}╔════════════════════════════════════════════╗${NC}"
            echo -e "${GREEN}║    Installation Complete! ✓               ║${NC}"
            echo -e "${GREEN}╚════════════════════════════════════════════╝${NC}"
            output ""
            verify_install
            show_completion_summary
            ;;

        select)
            configure_components
            divider

            create_backup
            download_sourby
            install_addons "$(build_component_string)"
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

            if read_yn "Are you sure?" 0; then
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

            if read_yn "Are you sure?" 0; then
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

show_completion_summary() {
    output "Next steps:"
    output ""
    output "  1. Access admin panel: ${CYAN}https://your-domain/admin${NC}"
    output ""
    output "  2. Verify Sourby theme is active"
    output ""
    output "  3. Manage addons:"
    [ "$INSTALL_BILLING" -eq 1 ] && output "     ${CYAN}Shop Settings:${NC}  /admin/shop/settings"
    [ "$INSTALL_PLAYERS" -eq 1 ] && output "     ${CYAN}Player Counter:${NC} /admin/players"
    output ""
    output "  Backup location: ${CYAN}$BACKUP_BASE_DIR/latest${NC}"
    output ""
    output "  Docs: ${CYAN}SOURBY_INTEGRATION.md${NC}"
    output ""
}

# Verify installation
verify_install() {
    local ok=1

    output ""
    divider
    info "Verifying installation..."

    if [ -f "$PTERODACTYL_PATH/config/sourby.php" ]; then
        success "config/sourby.php"
    else
        error "config/sourby.php — config not copied"
        ok=0
    fi

    if [ -d "$PTERODACTYL_PATH/public/themes/sourby" ]; then
        success "public/themes/sourby (theme assets)"
    else
        error "public/themes/sourby — theme assets missing"
        ok=0
    fi

    if [ -f "$PTERODACTYL_PATH/routes/sourby.php" ]; then
        success "routes/sourby.php"
    else
        error "routes/sourby.php — routes not copied"
        ok=0
    fi

    if [ -f "$PTERODACTYL_PATH/app/Models/SourbySetting.php" ]; then
        success "app/Models/SourbySetting.php"
    else
        error "app/Models/SourbySetting.php — model not copied"
        ok=0
    fi

    if [ "$ok" -eq 0 ]; then
        warning "Some files are missing. Check that PTERODACTYL_PATH is correct: $PTERODACTYL_PATH"
    else
        success "All Sourby files verified"
    fi
    divider
    output ""
}

export -f output error success info warning welcome divider
export -f prompt read_input read_yn
export -f configure_panel configure_components build_component_string configure_payments
export -f check_root check_dependencies validate_pterodactyl
export -f ensure_backup_dir create_backup list_backups restore_from_backup
export -f download_sourby install_addons install_dependencies
export -f update_env set_env register_provider run_migrations build_frontend clear_caches
export -f update_lib_source run_ui show_completion_summary verify_install
