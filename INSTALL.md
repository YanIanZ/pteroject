# Sourby Installation Guide

This guide covers installing Sourby (enhanced Pterodactyl with integrated addons) to an existing Pterodactyl Panel v1.12.0+ installation.

## Prerequisites

- Pterodactyl Panel v1.12.0 or higher
- PHP 8.2+
- Laravel 11
- MySQL/MariaDB
- Node.js 16+
- Yarn
- SSH/command-line access to server
- `sudo` access or direct file access

## Automated Installation (Recommended)

### Step 1: Clone or Download Sourby

```bash
git clone https://github.com/YanIanZ/pteroject.git /tmp/sourby
cd /tmp/sourby
```

Or download as ZIP and extract.

### Step 2: Run Installation Script

```bash
# Set Pterodactyl path (if not /var/www/pterodactyl)
export PTERODACTYL_PATH=/path/to/pterodactyl

# Run installer
./install.sh
```

The script will:
1. Copy all addon files to Pterodactyl installation
2. Guide you through registering the service provider
3. Run database migrations
4. Build frontend assets
5. Clear caches

### Step 3: Register Service Provider (Manual Step)

During installation, the script will ask you to register the Sourby service provider.

Edit `bootstrap/app.php`:

```php
return Application::configure(basePath: dirname(__DIR__))
    ->withProviders([
        // ... existing providers
        Pterodactyl\Providers\SourbyThemeServiceProvider::class,
    ])
    // ... rest of config
```

Or edit `config/app.php` in the providers array:

```php
'providers' => [
    // ... existing providers
    Pterodactyl\Providers\SourbyThemeServiceProvider::class,
],
```

### Step 4: Complete Installation

After registering the provider, return to the terminal and press Enter to continue the automated installer, which will run migrations and build frontend assets.

## Manual Installation

If the automated script doesn't work, follow these steps manually:

### 1. Copy Files

```bash
PTERODACTYL=/var/www/pterodactyl  # Adjust path if needed

# Copy Unix Theme
cp -r "Unix Theme v2/pterodactyl"/* $PTERODACTYL/

# Copy Billing System
cp -r "billing-system-v1x-v143/PanelFiles"/* $PTERODACTYL/

# Copy Player List addon
cp -r "Player List & Counter 1.0/PanelFiles"/* $PTERODACTYL/

# Copy Custom Server Sort
cp -r "custom-server-sort-v103"/* $PTERODACTYL/
```

### 2. Install Dependencies

```bash
cd $PTERODACTYL
composer require paypal/checkout-sdk stripe/stripe-php
yarn add sortablejs
```

### 3. Register Service Provider

Edit `$PTERODACTYL/bootstrap/app.php` or `$PTERODACTYL/config/app.php` and add:

```php
Pterodactyl\Providers\SourbyThemeServiceProvider::class,
```

### 4. Run Migrations

```bash
cd $PTERODACTYL
php artisan migrate
```

### 5. Configure Environment

Edit `.env` file:

```env
APP_NAME="Sourby"
THEME=sourby-unix

# Addon configuration
SOURBY_BILLING_ENABLED=true
SOURBY_PLAYER_LIST_ENABLED=true
SOURBY_CUSTOM_SORT_ENABLED=true
```

### 6. Build Frontend

```bash
cd $PTERODACTYL
yarn install
yarn run build:production
```

### 7. Clear Caches

```bash
cd $PTERODACTYL
php artisan route:clear
php artisan config:clear
php artisan view:clear
php artisan cache:clear
```

## Configuration

### Environment Variables

Add to `.env`:

```env
# Required
APP_NAME="Sourby"
THEME=sourby-unix

# Optional - Enable/disable addons
SOURBY_BILLING_ENABLED=true
SOURBY_PLAYER_LIST_ENABLED=true
SOURBY_CUSTOM_SORT_ENABLED=true

# Optional - Theme customization
SOURBY_BACKGROUND=https://example.com/bg.png
SOURBY_LOGO=https://example.com/logo.png
SOURBY_FAVICON=https://example.com/favicon.png
```

### Admin Panel Access

After installation, access admin features at:

- **Main Admin Panel:** `https://your-domain/admin`
- **Sourby Theme Settings:** `https://your-domain/admin/sourby`
- **Shop Management:** `https://your-domain/admin/shop`
- **Player Counter Settings:** `https://your-domain/admin/players`

### Database Tables

Sourby creates these new tables:

- `sourby_settings` - Theme configuration
- `payments` - Payment transaction history
- `games` - Shop game products
- `game_category` - Shop categories
- `player_counter` - Player count tracking

## Verification

### Check Installation

```bash
# Verify files copied
test -f "$PTERODACTYL/app/Providers/SourbyThemeServiceProvider.php" && echo "✓ Service Provider found" || echo "✗ Missing"

# Verify config
test -f "$PTERODACTYL/config/sourby.php" && echo "✓ Config found" || echo "✗ Missing"

# Verify routes
test -f "$PTERODACTYL/routes/sourby.php" && echo "✓ Routes found" || echo "✗ Missing"

# Verify CSS
test -f "$PTERODACTYL/public/themes/sourby/css/admin-modern.css" && echo "✓ CSS found" || echo "✗ Missing"
```

### Test Theme

1. Navigate to admin panel: `https://your-domain/admin`
2. Look for "Sourby Theme" link in sidebar
3. Check that dark theme is applied
4. Verify addon sections appear (Billing, Player List, Custom Sort)

## Troubleshooting

### Service Provider Not Registered

**Error:** `Class 'Pterodactyl\Providers\SourbyThemeServiceProvider' not found`

**Solution:**
1. Verify file exists: `app/Providers/SourbyThemeServiceProvider.php`
2. Check provider is registered in `bootstrap/app.php` or `config/app.php`
3. Run: `php artisan optimize:clear`

### Routes Not Found

**Error:** `No routes found for /admin/sourby`

**Solution:**
1. Verify `routes/sourby.php` exists
2. Check service provider boot() loads routes
3. Run: `php artisan route:clear`

### CSS Not Loading

**Error:** Admin panel appears unstyled or broken

**Solution:**
1. Verify CSS files exist in `public/themes/sourby/css/`
2. Run: `php artisan view:clear`
3. Rebuild frontend: `yarn run build:production`
4. Check browser cache (Ctrl+Shift+Delete)

### Database Migration Failed

**Error:** `SQLSTATE[HY000]: General error: 1030 Got error...`

**Solution:**
1. Ensure MySQL is running: `systemctl status mysql`
2. Check disk space: `df -h`
3. Verify database permissions: `SHOW GRANTS FOR 'panel'@'localhost';`
4. Run migrations with verbose output: `php artisan migrate --verbose`

### Missing Tables

**Error:** `SQLSTATE[42S02]: Table 'sourby_settings' doesn't exist`

**Solution:**
1. Run migrations: `php artisan migrate`
2. Create missing table manually:
   ```sql
   CREATE TABLE sourby_settings (
     id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
     name VARCHAR(255) UNIQUE,
     value TEXT,
     created_at TIMESTAMP,
     updated_at TIMESTAMP
   );
   ```

## Uninstallation

To remove Sourby and revert to default Pterodactyl:

```bash
# Remove service provider from bootstrap/app.php or config/app.php

# Delete Sourby-specific files
rm -rf app/Providers/SourbyThemeServiceProvider.php
rm -rf app/Http/ViewComposers/SourbyThemeComposer.php
rm -rf app/Models/SourbySetting.php
rm -rf config/sourby.php
rm -rf routes/sourby.php
rm -rf resources/views/partials/sourby
rm -rf public/themes/sourby

# Clear caches
php artisan route:clear
php artisan cache:clear
php artisan view:clear

# Verify default theme works
# Navigate to /admin - should show default Pterodactyl panel
```

## Support

For issues and questions:

- **GitHub Issues:** https://github.com/YanIanZ/pteroject/issues
- **Integration Guide:** See `SOURBY_INTEGRATION.md`
- **Addon Docs:** See individual PanelEdit.txt files

## Next Steps

After successful installation:

1. **Configure Billing:** Add PayPal/Stripe keys in Shop Settings
2. **Customize Theme:** Edit colors/logo in Sourby Theme settings
3. **Enable Addons:** Toggle addons in `.env` as needed
4. **Test Features:** 
   - Buy balance in shop
   - View player count on server console
   - Drag-and-drop servers to reorder
5. **Review Logs:** Check `storage/logs/laravel.log` for any errors

Enjoy using Sourby!
