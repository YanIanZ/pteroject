#!/bin/bash

# Sourby Installation Script
# Installs Sourby (rebranded Pterodactyl with integrated addons) to an existing Pterodactyl Panel installation

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Default Pterodactyl path
PTERODACTYL_PATH="${PTERODACTYL_PATH:-/var/www/pterodactyl}"

echo -e "${GREEN}=== Sourby Installation Script ===${NC}"
echo ""

# Check if Pterodactyl path exists
if [ ! -d "$PTERODACTYL_PATH" ]; then
    echo -e "${RED}Error: Pterodactyl installation not found at $PTERODACTYL_PATH${NC}"
    echo "Set PTERODACTYL_PATH environment variable to the correct path and try again."
    echo "Example: PTERODACTYL_PATH=/var/www/panel ./install.sh"
    exit 1
fi

echo -e "${YELLOW}Pterodactyl Path: $PTERODACTYL_PATH${NC}"
echo ""

# Get current script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo -e "${YELLOW}Step 1: Copying addon files to Pterodactyl installation...${NC}"

# Copy Unix Theme v2
if [ -d "$SCRIPT_DIR/Unix Theme v2/pterodactyl" ]; then
    echo "Copying Unix Theme v2..."
    cp -r "$SCRIPT_DIR/Unix Theme v2/pterodactyl"/* "$PTERODACTYL_PATH/"
    echo -e "${GREEN}✓ Unix Theme v2 copied${NC}"
else
    echo -e "${RED}✗ Unix Theme v2 not found${NC}"
fi

# Copy Billing System
if [ -d "$SCRIPT_DIR/billing-system-v1x-v143/PanelFiles" ]; then
    echo "Copying Billing System..."
    cp -r "$SCRIPT_DIR/billing-system-v1x-v143/PanelFiles"/* "$PTERODACTYL_PATH/"
    echo -e "${GREEN}✓ Billing System copied${NC}"
else
    echo -e "${RED}✗ Billing System not found${NC}"
fi

# Copy Player List addon
if [ -d "$SCRIPT_DIR/Player List & Counter 1.0/PanelFiles" ]; then
    echo "Copying Player List addon..."
    cp -r "$SCRIPT_DIR/Player List & Counter 1.0/PanelFiles"/* "$PTERODACTYL_PATH/"
    echo -e "${GREEN}✓ Player List addon copied${NC}"
else
    echo -e "${RED}✗ Player List addon not found${NC}"
fi

# Copy Custom Server Sort
if [ -d "$SCRIPT_DIR/custom-server-sort-v103" ]; then
    echo "Copying Custom Server Sort..."
    find "$SCRIPT_DIR/custom-server-sort-v103" -type f ! -name "PanelEdit.txt" ! -name "README.md" -exec bash -c 'rel="${1#'"$SCRIPT_DIR/custom-server-sort-v103/"'}"; mkdir -p "$PTERODACTYL_PATH/${rel%/*}"; cp "$1" "$PTERODACTYL_PATH/$rel"' _ {} \;
    echo -e "${GREEN}✓ Custom Server Sort copied${NC}"
else
    echo -e "${RED}✗ Custom Server Sort not found${NC}"
fi

echo ""
echo -e "${YELLOW}Step 2: Registering Sourby Theme Service Provider...${NC}"
echo "Edit $PTERODACTYL_PATH/bootstrap/app.php and add to withProviders():"
echo ""
echo "    Pterodactyl\Providers\SourbyThemeServiceProvider::class,"
echo ""
echo -e "${YELLOW}Or edit $PTERODACTYL_PATH/config/app.php providers array:${NC}"
echo "    'providers' => ["
echo "        ..."
echo "        Pterodactyl\Providers\SourbyThemeServiceProvider::class,"
echo "    ]"
echo ""
read -p "Press Enter after registering the service provider... " -t 30 || true

echo ""
echo -e "${YELLOW}Step 3: Running migrations...${NC}"
cd "$PTERODACTYL_PATH"
php artisan migrate --force
echo -e "${GREEN}✓ Migrations completed${NC}"

echo ""
echo -e "${YELLOW}Step 4: Building frontend...${NC}"
cd "$PTERODACTYL_PATH"
if [ -f "package.json" ]; then
    yarn install
    yarn run build:production
    echo -e "${GREEN}✓ Frontend built${NC}"
else
    echo -e "${RED}✗ package.json not found${NC}"
fi

echo ""
echo -e "${YELLOW}Step 5: Clearing caches...${NC}"
cd "$PTERODACTYL_PATH"
php artisan route:clear
php artisan config:clear
php artisan view:clear
php artisan cache:clear
echo -e "${GREEN}✓ Caches cleared${NC}"

echo ""
echo -e "${GREEN}=== Installation Complete ===${NC}"
echo ""
echo "Sourby has been successfully installed!"
echo ""
echo "Next steps:"
echo "1. Configure environment variables in .env:"
echo "   - APP_NAME=Sourby"
echo "   - THEME=sourby-unix"
echo "   - SOURBY_BILLING_ENABLED=true"
echo "   - SOURBY_PLAYER_LIST_ENABLED=true"
echo "   - SOURBY_CUSTOM_SORT_ENABLED=true"
echo ""
echo "2. Access admin panel at: https://your-domain/admin"
echo ""
echo "3. Configure addons:"
echo "   - Sourby Theme: /admin/sourby"
echo "   - Shop Settings: /admin/shop/settings"
echo "   - Player Counter: /admin/players"
echo ""
echo "For more information, see SOURBY_INTEGRATION.md"
