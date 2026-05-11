# Sourby Quick Start

Get Sourby installed in 5 minutes.

## Prerequisites

- Pterodactyl Panel v1.12.0+
- SSH access to server
- `sudo` privileges

## Installation

### 1. Clone Sourby

```bash
cd /tmp
git clone https://github.com/YanIanZ/pteroject.git sourby
cd sourby
```

### 2. Run Installer

```bash
# If Pterodactyl is at /var/www/pterodactyl (default)
sudo ./install.sh

# If Pterodactyl is elsewhere
sudo PTERODACTYL_PATH=/path/to/panel ./install.sh
```

### 3. Register Service Provider

When prompted, edit your Pterodactyl `bootstrap/app.php`:

```php
->withProviders([
    // ... existing
    Pterodactyl\Providers\SourbyThemeServiceProvider::class,
])
```

Then return to terminal and press Enter.

### 4. Done!

Visit admin panel: `https://your-domain/admin`

You should see:
- Dark Sourby theme
- "Sourby Theme" link in sidebar
- "Shop Management" section
- "Player Counter" settings

## Configuration (Optional)

Edit `.env` in Pterodactyl root:

```env
APP_NAME="Sourby"
THEME=sourby-unix
SOURBY_BILLING_ENABLED=true
SOURBY_PLAYER_LIST_ENABLED=true
SOURBY_CUSTOM_SORT_ENABLED=true
```

### Configure Payments (Optional)

Admin Panel → Sourby Shop Management → Settings

Add PayPal Client ID/Secret and Stripe keys.

## Features

### Billing System
- PayPal & Stripe integration
- Player balance management
- Payment history tracking

### Player List
- Real-time player counter
- Player list display on console
- Quick player status check

### Custom Server Sort
- Drag-and-drop server reordering
- localStorage persistence
- Per-user sort order

### Modern Admin Panel
- Dark theme with accents
- Improved navigation
- Shop and theme management

## Troubleshooting

### Dark theme not showing?
```bash
cd /var/www/pterodactyl
php artisan cache:clear
yarn run build:production
```

### Routes not working?
Verify service provider is registered:
```bash
grep -n "SourbyThemeServiceProvider" config/app.php bootstrap/app.php
```

### Still broken?
See INSTALL.md "Troubleshooting" section.

## Next Steps

1. **Customize:** Sourby Theme → Theme Settings
2. **Monetize:** Add PayPal/Stripe keys in Shop
3. **Document:** See SOURBY_INTEGRATION.md for full architecture

## Need Help?

- **Issues:** https://github.com/YanIanZ/pteroject/issues
- **Docs:** INSTALL.md, SOURBY_INTEGRATION.md, README.md
