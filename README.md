# Sourby - Enhanced Pterodactyl Panel

Sourby is a rebranded and enhanced version of the Pterodactyl Game Server Panel with integrated addons and modern UI/UX.

## Features

- **Sourby Unix Theme v2.2.0** - Modern dark theme with customizable settings
- **Sourby Billing System** - PayPal and Stripe integration for balance management
- **Sourby Player List** - Real-time player counter and list display
- **Sourby Custom Server Sort** - Drag-and-drop server reordering with persistence

## Installation

### Prerequisites
- Pterodactyl Panel v1.12.0+
- PHP 8.2+
- Laravel 11
- MySQL/MariaDB
- Node.js 16+ & Yarn
- Composer
- curl, unzip, git

### Recommended: Full Setup Wizard (Complete Configuration)

**Interactive setup with selective addon/theme installation and automatic PayPal/theme configuration:**

```bash
curl -fsSL https://raw.githubusercontent.com/YanIanZ/pteroject/main/sourby-setup-wizard.sh | sudo bash
```

Or locally:
```bash
sudo ./sourby-setup-wizard.sh
```

Features:
- ✓ Choose which addons to install (Unix Theme, Billing, Player List, Custom Sort)
- ✓ Automatic theme configuration (name, logo, favicon)
- ✓ Complete PayPal setup automation (Client ID, Secret, Stripe keys)
- ✓ Automatic .env configuration with all settings
- ✓ Full dependency installation with user prompt
- ✓ Automatic backup before installation
- ✓ Production-ready with error handling

### Alternative: Quick Manager (Install/Uninstall Only)

For faster installation without interactive setup:

```bash
curl -fsSL https://raw.githubusercontent.com/YanIanZ/pteroject/main/sourby-manager.sh | sudo bash
```

Features:
- ✓ Full automation with all dependencies
- ✓ Automatic backup before installation
- ✓ Interactive menu (install/uninstall/backup history)
- ✓ One-command uninstall with automatic restore

### Manual Installation (Alternative)

1. Copy addon files to your Pterodactyl installation:
```bash
cp -r Unix\ Theme\ v2/pterodactyl/* /var/www/pterodactyl/
cp -r billing-system-v1x-v143/PanelFiles/* /var/www/pterodactyl/
cp -r Player\ List\ \&\ Counter\ 1.0/PanelFiles/* /var/www/pterodactyl/
cp -r custom-server-sort-v103/* /var/www/pterodactyl/
```

2. Register service providers in `bootstrap/app.php` or `config/app.php`:
```php
Pterodactyl\Providers\SourbyThemeServiceProvider::class,
```

3. Run migrations:
```bash
php artisan migrate
```

4. Build frontend:
```bash
yarn install
yarn run build:production
```

5. Clear caches:
```bash
php artisan cache:clear
php artisan view:clear
```

## Configuration

Create a `.env` file based on `.env.example`:

```env
APP_NAME="Sourby"
THEME=sourby-unix
SOURBY_BILLING_ENABLED=true
SOURBY_PLAYER_LIST_ENABLED=true
SOURBY_CUSTOM_SORT_ENABLED=true
```

## Installation Scripts

- `sourby-manager.sh` - Comprehensive manager with install/uninstall and backup/restore (RECOMMENDED)
- `install-sourby.sh` - Standalone installation script (curl-downloadable)
- `install.sh` - Local installation script
- `INSTALL.md` - Detailed installation guide with manual steps
- `QUICKSTART.md` - 5-minute quick start guide

## Documentation

- [Installation Guide](./INSTALL.md)
- [Quick Start](./QUICKSTART.md)
- [Unix Theme PanelEdit](./Unix\ Theme\ v2/PanelEdit.txt)
- [Billing System Setup](./billing-system-v1x-v143/PanelEdit.txt)
- [Player List Installation](./Player\ List\ \&\ Counter\ 1.0/PanelEdit.txt)
- [Custom Sort Setup](./custom-server-sort-v103/PanelEdit.txt)
- [Integration Guide](./SOURBY_INTEGRATION.md)

## Support

For issues and feature requests, visit [GitHub Issues](https://github.com/YanIanZ/pteroject/issues).

## License

See LICENSE file in respective addon directories.
