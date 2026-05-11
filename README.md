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
- curl, unzip

### Quick Install (Recommended)

```bash
bash <(curl -s https://raw.githubusercontent.com/YanIanZ/pteroject/main/install.sh)
```

Or clone and run locally:
```bash
git clone https://github.com/YanIanZ/pteroject.git
cd pteroject
sudo ./install.sh
```

### Interactive Menu

```
  [0]  Install Sourby (all addons + theme)
  [1]  Select components to install
  [2]  Update Sourby from GitHub
  [3]  Uninstall Sourby (restore backup)
  [4]  Create backup
  [5]  Restore from backup
  [6]  View backup history
  [7]  Exit
```

### Features
- Interactive numbered menu (always reads from terminal — works with `bash <(curl ...)`)
- Panel configuration wizard (API key, panel URL)
- Component selection (choose Unix Theme, Billing, Player List, Custom Sort)
- Auto-downloads `lib/lib.sh` when running remotely
- Automatic backup before every install/update
- One-command restore from backup
- Dependency installation with user prompt
- PayPal/Stripe configuration wizard
- Theme customization (app name, logo, favicon, background)
- One-command restore from backup
- Dependency installation with user prompt
- Piped mode support: `curl ... | sudo bash` auto-installs everything

### Script Structure

```
install.sh         Main entry point (menu + dispatcher)
lib/
  lib.sh           Shared library (logging, checks, install, backup, config)
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

- `install.sh` - Unified installer with interactive menu (curl-pipeable)
- `lib/lib.sh` - Shared library (logging, validation, backup, install, config)

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
