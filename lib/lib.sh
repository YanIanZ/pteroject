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

    if ! read_yn "Install Sourby Theme (modern dark theme)?" 1; then
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
    [ "$INSTALL_THEME" -eq 1 ] && output "  ${GREEN}✓${NC} Sourby Theme"
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
# VALIDATION & DEPENDENCY AUTO-INSTALL
# ============================================================================

check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root (use sudo)"
        exit 1
    fi
}

detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS="$ID"
    elif [ -f /etc/debian_version ]; then
        OS="debian"
    elif [ -f /etc/redhat-release ]; then
        OS="rhel"
    else
        OS="unknown"
    fi
}

install_pkg() {
    case "$OS" in
        ubuntu|debian) apt-get install -y -qq "$@" 2>/dev/null ;;
        rhel|centos|fedora|rocky|almalinux)
            if command -v dnf &>/dev/null; then dnf install -y -q "$@"
            else yum install -y -q "$@"; fi ;;
        *) return 1 ;;
    esac
}

check_dependencies() {
    info "Checking dependencies..."
    detect_os

    local missing=()
    local need_node_update=false
    local need_php_ext=false

    # curl
    if ! command -v curl &>/dev/null; then
        missing+=("curl")
    fi

    # unzip
    if ! command -v unzip &>/dev/null; then
        missing+=("unzip")
    fi

    # git
    if ! command -v git &>/dev/null; then
        missing+=("git")
    fi

    # rsync (used to overlay panel base + theme without clobbering user data)
    if ! command -v rsync &>/dev/null; then
        missing+=("rsync")
    fi

    # System packages
    if [ ${#missing[@]} -gt 0 ]; then
        output ""
        warning "Missing: ${missing[*]}"
        if [ "$OS" != "unknown" ] && read_yn "Install them automatically?" 1; then
            install_pkg "${missing[@]}" && success "System packages installed" || {
                error "Failed to install: ${missing[*]}"
                exit 1
            }
        else
            error "Install missing packages and try again: ${missing[*]}"
            exit 1
        fi
    fi

    # PHP + extensions
    if ! command -v php &>/dev/null; then
        output ""
        warning "PHP not found."
        if [ "$OS" != "unknown" ] && read_yn "Install PHP 8.2 and required extensions?" 1; then
            case "$OS" in
                ubuntu|debian)
                    add-apt-repository -y ppa:ondrej/php 2>/dev/null || true
                    apt-get update -qq 2>/dev/null
                    install_pkg php8.2 php8.2-cli php8.2-common php8.2-mysql php8.2-gd php8.2-mbstring php8.2-bcmath php8.2-xml php8.2-curl php8.2-zip
                    ;;
                rhel|centos|fedora|rocky|almalinux)
                    install_pkg php82 php82-cli php82-common php82-mysqlnd php82-gd php82-mbstring php82-bcmath php82-xml php82-curl php82-zip
                    ;;
                *) error "Cannot auto-install PHP on $OS. Install manually."; exit 1 ;;
            esac
        else
            error "PHP is required. Install and try again."
            exit 1
        fi
    fi
    success "php $(php -v 2>/dev/null | head -1 | awk '{print $2}')"

    # Node.js
    if command -v node &>/dev/null; then
        local node_ver=$(node -v 2>/dev/null | sed 's/v//' | cut -d. -f1)
        if [ "$node_ver" -lt 22 ] 2>/dev/null; then
            output ""
            warning "Node.js $(node -v) is too old (>=22 required)."
            if read_yn "Install Node.js 22 via NodeSource?" 1; then
                curl -fsSL https://deb.nodesource.com/setup_22.x | bash - 2>/dev/null
                install_pkg nodejs
                success "Node.js $(node -v) installed"
            fi
        else
            success "node $(node -v)"
        fi
    else
        output ""
        warning "Node.js not found."
        if read_yn "Install Node.js 22 via NodeSource?" 1; then
            curl -fsSL https://deb.nodesource.com/setup_22.x | bash - 2>/dev/null
            install_pkg nodejs
            success "Node.js $(node -v) installed"
        else
            error "Node.js >=22 is required."
            exit 1
        fi
    fi

    # Yarn
    if ! command -v yarn &>/dev/null; then
        output ""
        warning "Yarn not found."
        if read_yn "Install Yarn via npm?" 1; then
            npm install -g yarn 2>/dev/null && success "yarn installed" || {
                warning "npm install failed, trying corepack..."
                corepack enable 2>/dev/null && corepack prepare yarn@stable --activate 2>/dev/null && success "yarn installed via corepack" || {
                    error "Failed to install Yarn. Install manually: npm install -g yarn"
                    exit 1
                }
            }
        else
            error "Yarn is required."
            exit 1
        fi
    else
        success "yarn $(yarn -v)"
    fi

    # Composer
    if ! command -v composer &>/dev/null; then
        output ""
        warning "Composer not found."
        if read_yn "Install Composer?" 1; then
            curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer 2>/dev/null
            success "composer $(composer --version 2>/dev/null | head -1 | awk '{print $3}')"
        else
            error "Composer is required."
            exit 1
        fi
    else
        success "composer $(composer --version 2>/dev/null | head -1 | awk '{print $3}')"
    fi

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
    rm -rf "$DOWNLOAD_DIR"
    mkdir -p "$DOWNLOAD_DIR"
    cd "$DOWNLOAD_DIR"

    local download_url="https://github.com/$GITHUB_REPO/archive/refs/heads/$GITHUB_BRANCH.zip"
    info "Repository: $GITHUB_REPO ($GITHUB_BRANCH)"

    if ! curl -fL --progress-bar "$download_url" -o sourby.zip; then
        error "Download failed"
        exit 1
    fi

    local zip_size
    zip_size=$(du -h sourby.zip 2>/dev/null | awk '{print $1}')
    success "Downloaded ($zip_size)"

    info "Extracting..."
    unzip -oq sourby.zip
    EXTRACTED_DIR="$DOWNLOAD_DIR/pteroject-${GITHUB_BRANCH}"
    if [ ! -d "$EXTRACTED_DIR" ]; then
        error "Extraction failed — expected $EXTRACTED_DIR"
        exit 1
    fi
    success "Extracted"
    output ""
}

# ============================================================================
# INSTALLATION
# ============================================================================

install_panel_base() {
    local panel_src="$DOWNLOAD_DIR/panel-upstream"
    local panel_tar="$DOWNLOAD_DIR/panel.tar.gz"
    # Pterodactyl's GitHub "releases/latest" currently resolves to v1.12.2 (canary,
    # Laravel 11, PHP 8.2). The theme + addons in this repo target the long-lived
    # stable line (v1.11.x, Laravel 10), so pin to v1.11.11 by default. Override
    # via PANEL_RELEASE_URL for any other release.
    local panel_url="${PANEL_RELEASE_URL:-https://github.com/pterodactyl/panel/releases/download/v1.11.11/panel.tar.gz}"

    info "Downloading latest Pterodactyl panel release tarball..."
    info "URL: $panel_url"

    rm -rf "$panel_src" "$panel_tar"
    mkdir -p "$panel_src"

    # curl -# shows a progress bar; -L follows GitHub redirects; --fail = non-zero on HTTP error
    if ! curl -fL --progress-bar -o "$panel_tar" "$panel_url"; then
        error "Failed to download panel tarball from $panel_url"
        exit 1
    fi

    local tar_size
    tar_size=$(du -h "$panel_tar" 2>/dev/null | awk '{print $1}')
    success "Downloaded ($tar_size)"

    info "Extracting panel.tar.gz..."
    # Show file count progress via pv if available, else plain tar
    if command -v pv >/dev/null 2>&1; then
        pv "$panel_tar" | tar -xz -C "$panel_src" || { error "Extraction failed"; exit 1; }
    else
        tar -xzf "$panel_tar" -C "$panel_src" || { error "Extraction failed"; exit 1; }
    fi
    success "Extracted"

    info "Syncing panel base into $PTERODACTYL_PATH (preserving .env, storage, user data)..."

    # Progress: rsync --info=progress2 shows percent. Fall back to plain rsync on old versions.
    local rsync_progress_flag=""
    if rsync --info=progress2 --version >/dev/null 2>&1 && rsync --help 2>&1 | grep -q "info=progress2"; then
        rsync_progress_flag="--info=progress2"
    fi

    rsync -a $rsync_progress_flag \
        --exclude='.env' \
        --exclude='.env.*' \
        --exclude='.git' \
        --exclude='.github' \
        --exclude='storage/logs/' \
        --exclude='storage/framework/cache/' \
        --exclude='storage/framework/sessions/' \
        --exclude='storage/framework/views/' \
        --exclude='storage/app/' \
        --exclude='bootstrap/cache/' \
        --exclude='node_modules/' \
        --exclude='vendor/' \
        --exclude='public/build/' \
        --exclude='public/hot' \
        "$panel_src/" "$PTERODACTYL_PATH/" || { error "Panel base sync failed"; exit 1; }

    success "Panel base synced from latest release"
    output ""

    # vendor/ was excluded, so it may not match the new composer.json/lock that
    # just landed. Refresh it now — otherwise Schema::hasTable, getTables() and
    # other Laravel APIs may not match (e.g. Laravel 11 vendor vs Laravel 10 code).
    info "Refreshing Composer dependencies to match new panel base..."
    cd "$PTERODACTYL_PATH"
    if command -v composer >/dev/null 2>&1; then
        composer install --no-dev --optimize-autoloader --no-interaction 2>&1 | tail -3 || {
            error "composer install failed"
            warning "Run manually: cd $PTERODACTYL_PATH && composer install --no-dev"
            exit 1
        }
        success "Composer dependencies refreshed"
    else
        warning "composer not found — vendor/ may be out of sync with new panel code"
    fi
    output ""
}

install_addons() {
    local components="$1"

    if [ ! -d "$EXTRACTED_DIR" ]; then
        error "Extracted directory not found: $EXTRACTED_DIR"
        warning "Download may have failed. Check your internet connection."
        exit 1
    fi

    # Optionally sync panel base first so theme/addons overlay clean latest panel
    if [ "${SYNC_PANEL_BASE:-1}" -eq 1 ]; then
        if read_yn "Sync latest Pterodactyl panel base before installing addons? (recommended for broken/missing CSS)" 1; then
            install_panel_base
        else
            info "Skipping panel base sync — overlaying on existing panel"
        fi
    fi

    info "Installing selected components (from $EXTRACTED_DIR)..."
    output ""

    # Debug: show what was extracted
    info "Extracted contents:"
    ls -d "$EXTRACTED_DIR"/*/ 2>/dev/null | while read -r d; do
        output "  $(basename "$d")/"
    done
    output ""
    local installed=0

    if [[ "$components" == *"theme"* ]]; then
        local theme_dir="$EXTRACTED_DIR/Sourby Theme/pterodactyl"
        if [ -d "$theme_dir" ]; then
            info "Installing Sourby Theme..."
            # Copy theme files excluding core panel overrides
            # Theme uses ViewComposers + partial includes, not file replacement
            rsync -a \
                --exclude='app/Http/Controllers/Auth/LoginController.php' \
                --exclude='app/Http/Controllers/Admin/BaseController.php' \
                --exclude='app/Http/Controllers/Base/IndexController.php' \
                --exclude='resources/views/layouts/admin.blade.php' \
                --exclude='resources/views/templates/wrapper.blade.php' \
                --exclude='resources/views/templates/auth/core.blade.php' \
                --exclude='resources/views/templates/base/core.blade.php' \
                --exclude='resources/views/vendor/' \
                "$theme_dir/" "$PTERODACTYL_PATH/" 2>/dev/null || \
                cp -r "$theme_dir"/* "$PTERODACTYL_PATH/"
            success "Sourby Theme installed"
            installed=1
        else
            warning "Sourby Theme not found at $theme_dir"
        fi
    fi

    if [[ "$components" == *"billing"* ]]; then
        local billing_dir="$EXTRACTED_DIR/billing-system-v1x-v143/PanelFiles"
        if [ -d "$billing_dir" ]; then
            info "Installing Billing System..."
            cp -r "$billing_dir"/* "$PTERODACTYL_PATH/"
            success "Billing System installed"
            installed=1
        else
            warning "Billing System not found at $billing_dir"
        fi
    fi

    if [[ "$components" == *"players"* ]]; then
        local players_dir="$EXTRACTED_DIR/Player List & Counter 1.0/PanelFiles"
        if [ -d "$players_dir" ]; then
            info "Installing Player List addon..."
            cp -r "$players_dir"/* "$PTERODACTYL_PATH/"
            success "Player List addon installed"
            installed=1
        else
            warning "Player List not found at $players_dir"
        fi
    fi

    if [[ "$components" == *"sort"* ]]; then
        local sort_dir="$EXTRACTED_DIR/custom-server-sort-v103"
        if [ -d "$sort_dir" ]; then
            info "Installing Custom Server Sort..."
            find "$sort_dir" -type f ! -name "PanelEdit.txt" ! -name "README.md" -exec bash -c 'rel="${1#'"$sort_dir"'/}"; mkdir -p "$PTERODACTYL_PATH/${rel%/*}"; cp "$1" "$PTERODACTYL_PATH/$rel"' _ {} \;
            success "Custom Server Sort installed"
            installed=1
        else
            warning "Custom Server Sort not found at $sort_dir"
        fi
    fi

    if [ "$installed" -eq 0 ]; then
        error "No addon directories found in the downloaded package."
        error "Extracted contents at $EXTRACTED_DIR:"
        ls -la "$EXTRACTED_DIR" 2>/dev/null || warning "(directory empty or missing)"
        exit 1
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

        info "Installing @stripe/stripe-js JS package..."
        yarn add @stripe/stripe-js 2>&1 | tail -1 || \
            warning "Failed to add @stripe/stripe-js — install manually: yarn add @stripe/stripe-js"
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
    local provider_class="Pterodactyl\\\\Providers\\\\SourbyThemeServiceProvider::class"

    # Detect Laravel version: Laravel 11 uses Application::configure()->withProviders([...])
    # Laravel 10 (Pterodactyl LTS v1.11.x) uses config/app.php 'providers' array
    local is_laravel11=0
    if [ -f "$bootstrap_file" ] && grep -q "withProviders\|Application::configure" "$bootstrap_file"; then
        is_laravel11=1
    fi

    # Also ensure Unix provider isn't already registered (would cause double admin.index route)
    local unix_registered=0
    if [ -f "$config_file" ] && grep -q "UnixThemeServiceProvider" "$config_file"; then
        unix_registered=1
    fi
    if [ -f "$bootstrap_file" ] && grep -q "UnixThemeServiceProvider" "$bootstrap_file"; then
        unix_registered=1
    fi
    if [ "$unix_registered" -eq 1 ]; then
        warning "UnixThemeServiceProvider already registered — removing to avoid route conflicts with Sourby"
        [ -f "$config_file" ] && sed -i '/UnixThemeServiceProvider/d' "$config_file"
        [ -f "$bootstrap_file" ] && sed -i '/UnixThemeServiceProvider/d' "$bootstrap_file"
    fi

    if [ "$is_laravel11" -eq 1 ]; then
        if ! grep -q "SourbyThemeServiceProvider" "$bootstrap_file"; then
            info "Laravel 11 detected — registering in bootstrap/app.php..."
            sed -i "/->withProviders(\[/a\\        $provider_class," "$bootstrap_file"
            if grep -q "SourbyThemeServiceProvider" "$bootstrap_file"; then
                success "Service provider registered in bootstrap/app.php"
            else
                error "Failed to inject provider — bootstrap/app.php may not have withProviders([ block"
                error "Add manually: $provider_class"
                return 1
            fi
        else
            success "Service provider already registered (bootstrap/app.php)"
        fi
        output ""
        return 0
    fi

    if [ -f "$config_file" ]; then
        if ! grep -q "SourbyThemeServiceProvider" "$config_file"; then
            info "Laravel 10 (Pterodactyl LTS) detected — registering in config/app.php..."
            # Match the application providers section (RouteServiceProvider is the last app provider in stock Pterodactyl)
            if grep -q "RouteServiceProvider::class" "$config_file"; then
                sed -i "/RouteServiceProvider::class,/a\\        $provider_class," "$config_file"
            else
                sed -i "/'providers' => ServiceProvider::defaultProviders/a\\        $provider_class," "$config_file" 2>/dev/null || \
                sed -i "/'providers' => \[/a\\        $provider_class," "$config_file"
            fi
            if grep -q "SourbyThemeServiceProvider" "$config_file"; then
                success "Service provider registered in config/app.php"
            else
                error "Failed to inject provider into config/app.php"
                error "Add manually inside 'providers' => [ ... ] array: $provider_class"
                return 1
            fi
        else
            success "Service provider already registered (config/app.php)"
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

################################################################################
# patch_addon_routes — auto-insert route blocks documented in each PanelEdit.txt
# Uses BEGIN/END marker comments so re-runs are idempotent (no duplicate routes).
################################################################################

_marker_present() {
    # _marker_present <file> <marker>
    grep -Fq "$2" "$1" 2>/dev/null
}

_append_block_if_missing() {
    # _append_block_if_missing <file> <marker> <heredoc-block>
    local file="$1"
    local marker="$2"
    local block="$3"
    if [ ! -f "$file" ]; then
        warning "Cannot patch — $file missing"
        return 1
    fi
    if _marker_present "$file" "$marker"; then
        return 0
    fi
    {
        echo ""
        echo "// >>> $marker (managed by sourby-installer — do not edit)"
        echo "$block"
        echo "// <<< $marker"
    } >> "$file"
}

_insert_after_pattern() {
    # _insert_after_pattern <file> <pattern> <marker> <block>
    local file="$1" pat="$2" marker="$3" block="$4"
    if [ ! -f "$file" ]; then
        warning "Cannot patch — $file missing"
        return 1
    fi
    if _marker_present "$file" "$marker"; then
        return 0
    fi
    if ! grep -q "$pat" "$file"; then
        warning "Pattern not found in $file: $pat — skipping insertion"
        return 1
    fi
    # Build a temp marker block, then sed-insert after first match
    local tmpblock
    tmpblock=$(mktemp)
    {
        echo "// >>> $marker (managed by sourby-installer)"
        echo "$block"
        echo "// <<< $marker"
    } > "$tmpblock"
    # Use awk for safe multi-line insertion
    awk -v pat="$pat" -v blockfile="$tmpblock" '
        BEGIN { while ((getline line < blockfile) > 0) blk = blk line "\n" }
        { print; if (!done && index($0, pat) > 0) { printf "%s", blk; done=1 } }
    ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
    rm -f "$tmpblock"
}

patch_addon_routes() {
    local routes_admin="$PTERODACTYL_PATH/routes/admin.php"
    local routes_api_client="$PTERODACTYL_PATH/routes/api-client.php"
    local wrapper="$PTERODACTYL_PATH/resources/views/templates/wrapper.blade.php"
    local admin_blade="$PTERODACTYL_PATH/resources/views/layouts/admin.blade.php"

    info "Patching addon routes & sidebar..."

    # ----- Billing -----
    if [ "$INSTALL_BILLING" -eq 1 ]; then
        _append_block_if_missing "$routes_admin" "SOURBY:BILLING:ADMIN" \
'/*
| Sourby Billing - Shop admin routes (Endpoint: /admin/shop)
*/
Route::group(["prefix" => "shop"], function () {
    Route::group(["prefix" => "settings"], function () {
        Route::get("/payments", [Admin\Shop\SettingsController::class, "payments"])->name("admin.shop.settings.payments");
        Route::get("/servers", [Admin\Shop\SettingsController::class, "servers"])->name("admin.shop.settings.servers");
        Route::get("/tos", [Admin\Shop\SettingsController::class, "tos"])->name("admin.shop.settings.tos");
        Route::get("/invoice", [Admin\Shop\SettingsController::class, "invoice"])->name("admin.shop.settings.invoice");
        Route::post("/payments", [Admin\Shop\SettingsController::class, "savePayments"]);
        Route::post("/settings", [Admin\Shop\SettingsController::class, "saveSettings"])->name("admin.shop.settings");
        Route::post("/servers", [Admin\Shop\SettingsController::class, "saveServerSettings"]);
        Route::post("/tos", [Admin\Shop\SettingsController::class, "saveTos"]);
        Route::post("/invoice", [Admin\Shop\SettingsController::class, "saveInvoice"]);
    });
    Route::group(["prefix" => "payments"], function () {
        Route::get("/", [Admin\Shop\PaymentsController::class, "index"])->name("admin.shop.payments");
        Route::get("/invoice/{id}", [Admin\Shop\PaymentsController::class, "viewInvoice"])->name("admin.shop.payments.invoice");
    });
    Route::group(["prefix" => "categories"], function () {
        Route::get("/", [Admin\Shop\CategoriesController::class, "index"])->name("admin.shop.categories");
        Route::get("/games", [Admin\Shop\GamesController::class, "index"])->name("admin.shop.categories.games.categories");
        Route::post("/create", [Admin\Shop\CategoriesController::class, "create"])->name("admin.shop.categories.create");
        Route::delete("/delete", [Admin\Shop\CategoriesController::class, "delete"])->name("admin.shop.categories.delete");
        Route::group(["prefix" => "{id}"], function () {
            Route::get("/edit", [Admin\Shop\CategoriesController::class, "edit"])->name("admin.shop.categories.edit");
            Route::post("/edit", [Admin\Shop\CategoriesController::class, "update"]);
            Route::group(["prefix" => "games"], function () {
                Route::get("/", [Admin\Shop\GamesController::class, "games"])->name("admin.shop.categories.games");
                Route::get("/create", [Admin\Shop\GamesController::class, "create"])->name("admin.shop.categories.games.create");
                Route::get("/{gameId}/edit", [Admin\Shop\GamesController::class, "edit"])->name("admin.shop.categories.games.edit");
                Route::post("/create", [Admin\Shop\GamesController::class, "store"]);
                Route::post("/{gameId}/edit", [Admin\Shop\GamesController::class, "update"]);
                Route::post("/{gameId}/move", [Admin\Shop\GamesController::class, "move"])->name("admin.shop.categories.games.move");
                Route::delete("/delete", [Admin\Shop\GamesController::class, "delete"])->name("admin.shop.categories.games.delete");
            });
        });
    });
});' && success "billing admin routes patched"

        _append_block_if_missing "$routes_api_client" "SOURBY:BILLING:API" \
'Route::get("/personal", [Client\PersonalSettingsController::class, "index"]);
Route::post("/personal", [Client\PersonalSettingsController::class, "savePersonalSettings"]);

Route::group(["prefix" => "/shop"], function () {
    Route::get("/categories", [Client\Shop\ShopController::class, "categories"]);
    Route::get("/categories/{category}", [Client\Shop\ShopController::class, "games"]);
    Route::get("/payment/invoice/{id}", [Client\Shop\PaymentController::class, "viewInvoice"]);
    Route::post("/order", [Client\Shop\ShopController::class, "order"]);
    Route::post("/payment", [Client\Shop\PaymentController::class, "getDetails"]);
    Route::post("/payment/paypal", [Client\Shop\PaymentController::class, "paypal"]);
    Route::post("/payment/stripe", [Client\Shop\PaymentController::class, "stripe"]);
});' && success "billing api-client routes patched"
    fi

    # ----- Player List -----
    if [ "$INSTALL_PLAYERS" -eq 1 ]; then
        _append_block_if_missing "$routes_admin" "SOURBY:PLAYERS:ADMIN" \
'use Pterodactyl\Http\Controllers\Admin\PlayerCounterController;
Route::group(["prefix" => "players"], function () {
    Route::get("/", [PlayerCounterController::class, "index"])->name("admin.sourby.players");
    Route::post("/create", [PlayerCounterController::class, "create"])->name("admin.sourby.players.create");
    Route::post("/update", [PlayerCounterController::class, "update"])->name("admin.sourby.players.update");
    Route::delete("/delete", [PlayerCounterController::class, "delete"])->name("admin.sourby.players.delete");
});' && success "player list admin routes patched"

        _append_block_if_missing "$routes_api_client" "SOURBY:PLAYERS:API" \
'use Pterodactyl\Http\Controllers\Api\Client\Servers\PlayersController;
Route::get("/players", [PlayersController::class, "index"]);' && success "player list api-client routes patched"
    fi

    # ----- Custom Sort: wrapper.blade.php JS tag -----
    if [ "$INSTALL_SORT" -eq 1 ] && [ -f "$wrapper" ]; then
        if ! grep -q "customserversort.js" "$wrapper"; then
            local sort_tag='        <script src="/themes/sourby/js/customserversort.js"></script>'
            if grep -q "asset->js('main.js')" "$wrapper"; then
                awk -v ins="$sort_tag" '
                    { print; if (!done && index($0, "asset->js(\047main.js\047)") > 0) { print ins; done=1 } }
                ' "$wrapper" > "$wrapper.tmp" && mv "$wrapper.tmp" "$wrapper"
            else
                awk -v ins="$sort_tag" '
                    { if (!done && index($0, "</body>") > 0) { print ins; done=1 } print }
                ' "$wrapper" > "$wrapper.tmp" && mv "$wrapper.tmp" "$wrapper"
            fi
            success "custom sort script tag inserted into wrapper.blade.php"
        fi
    fi

    # ----- Sidebar menu (admin.blade.php) — Shop + Player Counter links -----
    if [ -f "$admin_blade" ]; then
        if [ "$INSTALL_BILLING" -eq 1 ] && ! grep -q "SOURBY:SIDEBAR:SHOP" "$admin_blade"; then
            local sidebar_shop_file
            sidebar_shop_file=$(mktemp)
            cat > "$sidebar_shop_file" <<'SIDEBAR_SHOP_EOF'
        {{-- SOURBY:SIDEBAR:SHOP --}}
        <li class="header">SHOP MANAGEMENT</li>
        <li class="{{ ! starts_with(Route::currentRouteName(), 'admin.shop.settings') ?: 'active' }}"><a href="{{ route('admin.shop.settings.payments') }}"><i class="fa fa-cog"></i> <span>Settings</span></a></li>
        <li class="{{ ! starts_with(Route::currentRouteName(), 'admin.shop.categories') || starts_with(Route::currentRouteName(), 'admin.shop.categories.games') ?: 'active' }}"><a href="{{ route('admin.shop.categories') }}"><i class="fa fa-list"></i> <span>Categories</span></a></li>
        <li class="{{ ! starts_with(Route::currentRouteName(), 'admin.shop.categories.games') ?: 'active' }}"><a href="{{ route('admin.shop.categories.games.categories') }}"><i class="fa fa-play"></i> <span>Games</span></a></li>
        <li class="{{ ! starts_with(Route::currentRouteName(), 'admin.shop.payments') ?: 'active' }}"><a href="{{ route('admin.shop.payments') }}"><i class="fa fa-money"></i> <span>Payments</span></a></li>
SIDEBAR_SHOP_EOF
            if grep -q "SERVICE MANAGEMENT" "$admin_blade"; then
                awk -v insfile="$sidebar_shop_file" '
                    BEGIN { while ((getline line < insfile) > 0) blk = blk line "\n" }
                    { if (!done && index($0, "SERVICE MANAGEMENT") > 0) { printf "%s", blk; done=1 } print }
                ' "$admin_blade" > "$admin_blade.tmp" && mv "$admin_blade.tmp" "$admin_blade"
                success "sidebar SHOP MANAGEMENT block inserted"
            fi
            rm -f "$sidebar_shop_file"
        fi
        if [ "$INSTALL_PLAYERS" -eq 1 ] && ! grep -q "SOURBY:SIDEBAR:PLAYERS" "$admin_blade"; then
            local sidebar_players_file
            sidebar_players_file=$(mktemp)
            cat > "$sidebar_players_file" <<'SIDEBAR_PLAYERS_EOF'
        {{-- SOURBY:SIDEBAR:PLAYERS --}}
        <li class="{{ ! starts_with(Route::currentRouteName(), 'admin.sourby.players') ?: 'active' }}"><a href="{{ route('admin.sourby.players') }}"><i class="fa fa-user"></i> <span>Player Counter</span></a></li>
SIDEBAR_PLAYERS_EOF
            if grep -q "SERVICE MANAGEMENT" "$admin_blade"; then
                awk -v insfile="$sidebar_players_file" '
                    BEGIN { while ((getline line < insfile) > 0) blk = blk line "\n" }
                    { if (!done && index($0, "SERVICE MANAGEMENT") > 0) { printf "%s", blk; done=1 } print }
                ' "$admin_blade" > "$admin_blade.tmp" && mv "$admin_blade.tmp" "$admin_blade"
                success "sidebar Player Counter link inserted"
            fi
            rm -f "$sidebar_players_file"
        fi
    fi

    # ----- composer deps for billing -----
    if [ "$INSTALL_BILLING" -eq 1 ]; then
        info "Installing billing composer deps (laraveldaily/laravel-invoices, paypal/rest-api-sdk-php)..."
        cd "$PTERODACTYL_PATH"
        # -W = update with dependencies (resolves Pterodactyl's pin conflicts)
        # --ignore-platform-req=php = skip PHP version check (Pterodactyl may pin different)
        composer require laraveldaily/laravel-invoices:^3.0 -W --no-interaction 2>&1 | tail -3 || \
            warning "laravel-invoices install failed — try: composer require laraveldaily/laravel-invoices:^3.0 -W --ignore-platform-reqs"
        composer require paypal/rest-api-sdk-php:* --no-interaction 2>&1 | tail -3 || \
            warning "paypal-sdk install failed — try: composer require paypal/rest-api-sdk-php"
        mkdir -p "$PTERODACTYL_PATH/storage/app/invoices"
    fi

    # ----- composer dep for player list (gameq) -----
    if [ "$INSTALL_PLAYERS" -eq 1 ]; then
        info "Installing player counter composer dep (austinb/gameq)..."
        cd "$PTERODACTYL_PATH"
        # austinb/gameq has both 3.x (PHP 7.x) and dev-master (PHP 8). Try 3.x first, fall back to dev-master
        composer require "austinb/gameq:^3.1" -W --no-interaction 2>&1 | tail -3 || \
            composer require "austinb/gameq:dev-master" -W --no-interaction 2>&1 | tail -3 || \
            warning "gameq install failed — install manually: composer require austinb/gameq -W"
    fi

    output ""
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
    # Node 17+ + OpenSSL 3 breaks webpack 4 (ERR_OSSL_EVP_UNSUPPORTED).
    # Pterodactyl v1.11.x uses webpack 4 — force legacy OpenSSL provider.
    export NODE_OPTIONS="--openssl-legacy-provider ${NODE_OPTIONS:-}"
    YARN_IGNORE_ENGINES=true yarn run build:production || { error "Frontend build failed"; exit 1; }

    # Verify build artifacts exist
    if [ ! -d "$PTERODACTYL_PATH/public/assets" ] && [ ! -d "$PTERODACTYL_PATH/public/build" ]; then
        error "Build produced no assets in public/assets or public/build"
        exit 1
    fi

    # Fix ownership (nginx/php-fpm runs as www-data on Debian/Ubuntu)
    local web_user="www-data"
    id -u "$web_user" >/dev/null 2>&1 || web_user="nginx"
    id -u "$web_user" >/dev/null 2>&1 && chown -R "$web_user:$web_user" "$PTERODACTYL_PATH" || warning "Could not chown — set manually"

    success "Frontend built and permissions fixed"
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
            patch_addon_routes
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
            patch_addon_routes
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
            patch_addon_routes
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

    if [ -f "$PTERODACTYL_PATH/public/themes/sourby/css/core.css" ]; then
        success "themes/sourby/css/core.css"
    else
        error "themes/sourby/css/core.css missing — CSS won't load in browser"
        ok=0
    fi

    if [ -d "$PTERODACTYL_PATH/public/assets" ] || [ -d "$PTERODACTYL_PATH/public/build" ]; then
        success "frontend build output present"
    else
        error "no public/assets or public/build — yarn build:production likely failed"
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
export -f check_root check_dependencies validate_pterodactyl detect_os install_pkg
export -f ensure_backup_dir create_backup list_backups restore_from_backup
export -f download_sourby install_addons install_dependencies
export -f update_env set_env register_provider patch_addon_routes run_migrations build_frontend clear_caches
export -f update_lib_source run_ui show_completion_summary verify_install
