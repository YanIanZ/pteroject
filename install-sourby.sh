#!/bin/bash

# Sourby Installation Bootstrap Script
# Download and install Sourby from GitHub in one command
# Usage: curl -fsSL https://raw.githubusercontent.com/YanIanZ/pteroject/main/install-sourby.sh | bash

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
DOWNLOAD_DIR="${DOWNLOAD_DIR:-/tmp/sourby-install}"
PTERODACTYL_PATH="${PTERODACTYL_PATH:-/var/www/pterodactyl}"

# Detect if running via curl pipe
RUNNING_PIPED=false
if [ -t 0 ]; then
    RUNNING_PIPED=false
else
    RUNNING_PIPED=true
fi

echo -e "${GREEN}╔════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     Sourby Installation Bootstrap         ║${NC}"
echo -e "${GREEN}║  Enhanced Pterodactyl with Integrated     ║${NC}"
echo -e "${GREEN}║  Addons & Modern UI                       ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════╝${NC}"
echo ""

# Check if root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Error: This script must be run as root (use sudo)${NC}"
   exit 1
fi

# Check dependencies
echo -e "${YELLOW}Checking dependencies...${NC}"

for cmd in curl unzip php; do
    if ! command -v $cmd &> /dev/null; then
        echo -e "${RED}✗ $cmd not found. Please install it and try again.${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ $cmd${NC}"
done

echo ""

# Validate Pterodactyl path
echo -e "${YELLOW}Validating Pterodactyl installation...${NC}"
if [ ! -d "$PTERODACTYL_PATH" ]; then
    echo -e "${RED}Error: Pterodactyl not found at $PTERODACTYL_PATH${NC}"
    echo "Set PTERODACTYL_PATH environment variable and try again:"
    echo "  PTERODACTYL_PATH=/custom/path curl -fsSL ... | bash"
    exit 1
fi

if [ ! -f "$PTERODACTYL_PATH/artisan" ]; then
    echo -e "${RED}Error: Pterodactyl artisan not found. Invalid path?${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Pterodactyl found at $PTERODACTYL_PATH${NC}"
echo ""

# Download Sourby
echo -e "${YELLOW}Downloading Sourby from GitHub...${NC}"
mkdir -p "$DOWNLOAD_DIR"
cd "$DOWNLOAD_DIR"

echo "Repository: $GITHUB_REPO ($GITHUB_BRANCH)"

# Download as ZIP
DOWNLOAD_URL="https://github.com/$GITHUB_REPO/archive/refs/heads/$GITHUB_BRANCH.zip"
echo "Downloading: $DOWNLOAD_URL"

if curl -fsSL "$DOWNLOAD_URL" -o sourby.zip; then
    echo -e "${GREEN}✓ Downloaded${NC}"
else
    echo -e "${RED}✗ Download failed${NC}"
    exit 1
fi

# Extract
echo "Extracting..."
unzip -oq sourby.zip
EXTRACTED_DIR="pteroject-${GITHUB_BRANCH}"
if [ ! -d "$EXTRACTED_DIR" ]; then
    echo -e "${RED}✗ Extraction failed${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Extracted${NC}"

echo ""
echo -e "${YELLOW}Installing Sourby addons...${NC}"

# Copy Unix Theme
if [ -d "$EXTRACTED_DIR/Unix Theme v2/pterodactyl" ]; then
    echo "Installing Unix Theme v2..."
    cp -r "$EXTRACTED_DIR/Unix Theme v2/pterodactyl"/* "$PTERODACTYL_PATH/"
    echo -e "${GREEN}✓ Unix Theme v2${NC}"
fi

# Copy Billing System
if [ -d "$EXTRACTED_DIR/billing-system-v1x-v143/PanelFiles" ]; then
    echo "Installing Billing System..."
    cp -r "$EXTRACTED_DIR/billing-system-v1x-v143/PanelFiles"/* "$PTERODACTYL_PATH/"
    echo -e "${GREEN}✓ Billing System${NC}"
fi

# Copy Player List
if [ -d "$EXTRACTED_DIR/Player List & Counter 1.0/PanelFiles" ]; then
    echo "Installing Player List addon..."
    cp -r "$EXTRACTED_DIR/Player List & Counter 1.0/PanelFiles"/* "$PTERODACTYL_PATH/"
    echo -e "${GREEN}✓ Player List${NC}"
fi

# Copy Custom Sort
if [ -d "$EXTRACTED_DIR/custom-server-sort-v103" ]; then
    echo "Installing Custom Server Sort..."
    find "$EXTRACTED_DIR/custom-server-sort-v103" -type f ! -name "PanelEdit.txt" ! -name "README.md" -exec bash -c 'rel="${1#'"$EXTRACTED_DIR/custom-server-sort-v103/"'}"; mkdir -p "$PTERODACTYL_PATH/${rel%/*}"; cp "$1" "$PTERODACTYL_PATH/$rel"' _ {} \;
    echo -e "${GREEN}✓ Custom Server Sort${NC}"
fi

echo ""
echo -e "${YELLOW}Installing Dependencies...${NC}"
cd "$PTERODACTYL_PATH"
composer require paypal/checkout-sdk stripe/stripe-php
yarn add sortablejs
echo -e "${GREEN}✓ Dependencies installed${NC}"

echo ""
echo -e "${YELLOW}Registering Sourby Theme Service Provider...${NC}"
echo ""
echo "You must manually register the service provider."
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
    echo -e "${YELLOW}(Automatic registration not yet available in piped mode)${NC}"
    echo "Complete the manual steps above, then run:"
    echo "  cd $PTERODACTYL_PATH"
    echo "  php artisan migrate"
    echo "  yarn install && yarn run build:production"
    echo "  php artisan cache:clear"
    exit 0
fi

echo ""
echo -e "${YELLOW}Installing Node.js dependencies...${NC}"
cd "$PTERODACTYL_PATH"
yarn add sortablejs
echo -e "${GREEN}✓ Dependencies installed${NC}"

echo ""
echo -e "${YELLOW}Payment SDKs (PayPal/Stripe) are optional.${NC}"
echo "Install manually if needed:"
echo "  composer require stripe/stripe-php"
echo ""

echo -e "${YELLOW}Running migrations...${NC}"
cd "$PTERODACTYL_PATH"
php artisan migrate --force

echo ""
echo -e "${YELLOW}Building frontend...${NC}"
if [ -f "package.json" ]; then
    yarn install > /dev/null 2>&1
    yarn run build:production > /dev/null 2>&1
    echo -e "${GREEN}✓ Frontend built${NC}"
fi

echo ""
echo -e "${YELLOW}Clearing caches...${NC}"
php artisan route:clear
php artisan config:clear
php artisan view:clear
php artisan cache:clear
echo -e "${GREEN}✓ Caches cleared${NC}"

echo ""
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
echo "Docs: https://github.com/YanIanZ/pteroject"
echo ""

# Cleanup
rm -rf "$DOWNLOAD_DIR"

exit 0
