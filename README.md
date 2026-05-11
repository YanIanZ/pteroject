# Sourby - Enhanced Pterodactyl Panel

Sourby is a rebranded and enhanced version of the Pterodactyl Game Server Panel with integrated addons and modern UI/UX.

## Features

- **Sourby Unix Theme v2.2.0** - Modern dark theme with customizable settings
- **Sourby Billing System** - PayPal and Stripe integration for balance management
- **Sourby Player List** - Real-time player counter and list display
- **Sourby Custom Server Sort** - Drag-and-drop server reordering with persistence

## Installation

### Prerequisites
- PHP 8.2+
- Laravel 11
- MySQL/MariaDB
- Node.js & Yarn
- Go 1.24+ (for Wings)

### Quick Start

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

## Documentation

- [Unix Theme PanelEdit](./Unix\ Theme\ v2/PanelEdit.txt)
- [Billing System Setup](./billing-system-v1x-v143/PanelEdit.txt)
- [Player List Installation](./Player\ List\ \&\ Counter\ 1.0/PanelEdit.txt)
- [Custom Sort Setup](./custom-server-sort-v103/PanelEdit.txt)
- [Integration Guide](./SOURBY_INTEGRATION.md)

## Support

For issues and feature requests, visit [GitHub Issues](https://github.com/YanIanZ/pteroject/issues).

## License

See LICENSE file in respective addon directories.
