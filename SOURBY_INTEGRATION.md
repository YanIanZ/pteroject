# Sourby Integration Guide

## Version Compatibility

| Component | Version | PHP | Laravel | Node.js |
|-----------|---------|-----|---------|---------|
| Sourby Unix Theme | 2.2.0 | 8.2+ | 11.x | 20.x+ |
| Billing System | 1.x-1.4.3 | 8.2+ | 11.x | 20.x+ |
| Player List | 1.0 | 8.2+ | 11.x | 20.x+ |
| Custom Server Sort | 1.0.3 | 8.2+ | 11.x | 20.x+ |

## System Architecture

### Core Components Integration

```
Pterodactyl Panel (Laravel 11)
├── Sourby Unix Theme (Frontend Layer)
│   ├── Views & Blade Templates
│   ├── CSS/SCSS Assets
│   └── JS Components
├── Billing System (Financial Module)
│   ├── PayPal Integration
│   ├── Stripe Integration
│   └── Balance Management
├── Player List (Server Monitoring)
│   ├── Real-time Data Display
│   └── Server Status
└── Custom Server Sort (User Preferences)
    ├── Drag-and-Drop UI
    └── Persistence Layer
```

## Database Schema Integration

### New Tables Created

#### `sourby_billing_accounts`
```sql
CREATE TABLE sourby_billing_accounts (
    id BIGINT UNSIGNED PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    balance DECIMAL(10, 2) DEFAULT 0,
    currency VARCHAR(3) DEFAULT 'USD',
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
```

#### `sourby_billing_transactions`
```sql
CREATE TABLE sourby_billing_transactions (
    id BIGINT UNSIGNED PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    account_id BIGINT UNSIGNED NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    type ENUM('credit', 'debit', 'refund'),
    gateway VARCHAR(50),
    reference_id VARCHAR(255),
    status ENUM('pending', 'completed', 'failed', 'cancelled'),
    created_at TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (account_id) REFERENCES sourby_billing_accounts(id)
);
```

#### `sourby_player_list_cache`
```sql
CREATE TABLE sourby_player_list_cache (
    id BIGINT UNSIGNED PRIMARY KEY,
    server_id BIGINT UNSIGNED NOT NULL,
    players JSON,
    player_count INT DEFAULT 0,
    updated_at TIMESTAMP,
    FOREIGN KEY (server_id) REFERENCES servers(id) ON DELETE CASCADE
);
```

#### `sourby_server_sort_order`
```sql
CREATE TABLE sourby_server_sort_order (
    id BIGINT UNSIGNED PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    server_id BIGINT UNSIGNED NOT NULL,
    sort_position INT DEFAULT 0,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (server_id) REFERENCES servers(id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_server (user_id, server_id)
);
```

## CSS Integration Points

### Theme Integration Files

**Location:** `resources/css/pterodactyl/sourby/`

- `theme.css` - Main theme stylesheet
- `variables.css` - CSS custom properties for theming
- `components.css` - Component-specific styles
- `responsive.css` - Mobile/responsive adjustments
- `dark-mode.css` - Dark theme override

### Tailwind CSS Configuration

Update `tailwind.config.js`:

```javascript
module.exports = {
  theme: {
    extend: {
      colors: {
        sourby: {
          primary: '#6c5ce7',
          secondary: '#a29bfe',
          dark: '#2d3436',
          light: '#f5f6fa',
        }
      },
      fontFamily: {
        sourby: ['Inter', 'sans-serif'],
      },
    },
  },
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/typography'),
  ],
};
```

## Blade Template Integration

### Theme Layout Files

**Location:** `resources/views/layouts/sourby/`

- `app.blade.php` - Main application layout
- `auth.blade.php` - Authentication layout
- `dashboard.blade.php` - Dashboard layout with sidebar
- `minimal.blade.php` - Minimal layout for modals

### Component Integration

**Location:** `resources/views/components/sourby/`

- `navbar.blade.php` - Top navigation bar
- `sidebar.blade.php` - Left sidebar navigation
- `server-card.blade.php` - Server listing card
- `player-list.blade.php` - Player count/list display
- `billing-card.blade.php` - User balance display

### Service Provider Registration

**File:** `app/Providers/SourbyThemeServiceProvider.php`

```php
<?php

namespace Pterodactyl\Providers;

use Illuminate\Support\ServiceProvider;
use Illuminate\View\Compilers\BladeCompiler;

class SourbyThemeServiceProvider extends ServiceProvider
{
    public function boot(): void
    {
        // Register view paths
        $this->loadViewsFrom(
            base_path('resources/views/sourby'),
            'sourby'
        );

        // Register component namespace
        $this->callAfterResolving(BladeCompiler::class, function (BladeCompiler $blade) {
            $blade->component('sourby::components.*', 'sourby');
        });

        // Publish assets
        $this->publishes([
            base_path('resources/css/sourby') => public_path('css/sourby'),
            base_path('resources/js/sourby') => public_path('js/sourby'),
        ], 'sourby-assets');
    }
}
```

## Configuration System

### Environment Variables

```env
# Sourby Theme Configuration
SOURBY_THEME=unix-v2
SOURBY_THEME_VARIANT=dark
SOURBY_BILLING_ENABLED=true
SOURBY_PLAYER_LIST_ENABLED=true
SOURBY_CUSTOM_SORT_ENABLED=true

# Billing Gateway Configuration
SOURBY_BILLING_DEFAULT_GATEWAY=paypal
PAYPAL_CLIENT_ID=your_client_id
PAYPAL_CLIENT_SECRET=your_secret
STRIPE_PUBLIC_KEY=your_public_key
STRIPE_SECRET_KEY=your_secret_key

# Player List Configuration
SOURBY_PLAYER_CACHE_TTL=300
SOURBY_PLAYER_LIST_LIMIT=50
```

### Configuration File

**File:** `config/sourby.php`

```php
<?php

return [
    'theme' => [
        'name' => env('SOURBY_THEME', 'unix-v2'),
        'variant' => env('SOURBY_THEME_VARIANT', 'dark'),
        'custom_colors' => [
            'primary' => '#6c5ce7',
            'secondary' => '#a29bfe',
        ],
    ],

    'features' => [
        'billing' => env('SOURBY_BILLING_ENABLED', true),
        'player_list' => env('SOURBY_PLAYER_LIST_ENABLED', true),
        'custom_sort' => env('SOURBY_CUSTOM_SORT_ENABLED', true),
    ],

    'billing' => [
        'default_gateway' => env('SOURBY_BILLING_DEFAULT_GATEWAY', 'paypal'),
        'currencies' => ['USD', 'EUR', 'GBP'],
    ],

    'player_list' => [
        'cache_ttl' => env('SOURBY_PLAYER_CACHE_TTL', 300),
        'limit' => env('SOURBY_PLAYER_LIST_LIMIT', 50),
    ],
];
```

## Integration Testing

### Unit Tests

**File:** `tests/Unit/Sourby/BillingSystemTest.php`

```php
<?php

namespace Tests\Unit\Sourby;

use Tests\TestCase;
use Pterodactyl\Models\User;
use App\Models\SourbyBillingAccount;

class BillingSystemTest extends TestCase
{
    public function test_billing_account_creation()
    {
        $user = User::factory()->create();
        $account = SourbyBillingAccount::create([
            'user_id' => $user->id,
            'balance' => 0,
            'currency' => 'USD',
        ]);

        $this->assertDatabaseHas('sourby_billing_accounts', [
            'user_id' => $user->id,
            'balance' => 0,
        ]);
    }

    public function test_balance_transaction()
    {
        $account = SourbyBillingAccount::factory()->create(['balance' => 100]);
        $account->debit(25);

        $this->assertEquals(75, $account->fresh()->balance);
    }
}
```

### Integration Tests

**File:** `tests/Feature/Sourby/BillingIntegrationTest.php`

```php
<?php

namespace Tests\Feature\Sourby;

use Tests\TestCase;
use Pterodactyl\Models\User;

class BillingIntegrationTest extends TestCase
{
    public function test_user_can_view_billing_dashboard()
    {
        $user = User::factory()->create();
        $response = $this->actingAs($user)->get('/account/billing');

        $response->assertStatus(200);
        $response->assertViewIs('sourby.billing.dashboard');
    }

    public function test_paypal_webhook_processing()
    {
        $payload = [
            'event_type' => 'PAYMENT.CAPTURE.COMPLETED',
            'resource' => ['amount' => ['value' => '50.00']],
        ];

        $response = $this->post('/webhooks/paypal', $payload, [
            'X-PayPal-Transmission-Sig' => 'test_signature',
        ]);

        $response->assertStatus(200);
    }
}
```

## Troubleshooting

### Common Issues

#### Theme Not Loading
- Check that `SOURBY_THEME` is set in `.env`
- Verify CSS files are published: `php artisan vendor:publish --tag=sourby-assets`
- Clear view cache: `php artisan view:clear`
- Check browser console for CSS loading errors

#### Billing Gateway Errors
- Verify API credentials in `.env` are correct
- Check webhook endpoints are accessible
- Review transaction logs in `storage/logs/sourby-billing.log`
- Test gateway connectivity: `php artisan sourby:test-billing-gateway`

#### Player List Not Updating
- Check cache is enabled: `php artisan config:cache`
- Verify Wings API connectivity
- Monitor cache hit rate: `php artisan sourby:cache-stats`
- Review player list logs: `storage/logs/sourby-player-list.log`

#### Custom Sort Persistence Issues
- Clear user session cache: `php artisan cache:clear`
- Verify database connectivity to `sourby_server_sort_order` table
- Check user permissions in `user_permissions` table
- Review sort order logs: `storage/logs/sourby-custom-sort.log`

### Debugging Commands

```bash
# Test all Sourby components
php artisan sourby:health-check

# Generate test data
php artisan sourby:seed-test-data

# View component status
php artisan sourby:component-status

# Clear all Sourby caches
php artisan sourby:clear-caches

# Export integration report
php artisan sourby:export-report
```

## Performance Optimization

### Caching Strategy

- Player list data cached for 5 minutes (configurable)
- Theme assets cached indefinitely (invalidated on updates)
- Billing transaction cache: 1 hour
- Server sort order: User session cache

### Database Optimization

- Add indexes on foreign keys:
```sql
CREATE INDEX idx_billing_transactions_user ON sourby_billing_transactions(user_id);
CREATE INDEX idx_player_cache_server ON sourby_player_list_cache(server_id);
CREATE INDEX idx_sort_order_user ON sourby_server_sort_order(user_id);
```

- Archive old transactions monthly:
```bash
php artisan sourby:archive-transactions --months=6
```

## Migration Guide from Pterodactyl

### Step-by-Step Migration

1. **Backup existing installation**
   ```bash
   tar -czf pterodactyl-backup.tar.gz /var/www/pterodactyl
   mysqldump -u root -p pterodactyl > pterodactyl-backup.sql
   ```

2. **Install Sourby components**
   - Follow installation steps in main README.md

3. **Run migrations**
   ```bash
   php artisan migrate --path=database/migrations/sourby
   ```

4. **Seed initial data** (optional)
   ```bash
   php artisan db:seed --class=SourbySeeder
   ```

5. **Test all components**
   ```bash
   php artisan sourby:health-check
   ```

## Support & Documentation

- **GitHub Repository:** https://github.com/YanIanZ/pteroject
- **Issue Tracker:** https://github.com/YanIanZ/pteroject/issues
- **Discussions:** https://github.com/YanIanZ/pteroject/discussions

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

See LICENSE files in respective addon directories. Sourby maintains compatibility with Pterodactyl's licensing model.
