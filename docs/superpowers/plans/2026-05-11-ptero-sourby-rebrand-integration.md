# Pterodactyl → Sourby Rebrand & Unix Theme Integration

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebrand Pterodactyl addons to "sourby", integrate Unix theme with all addons, modernize admin UI/UX, and push to GitHub.

**Architecture:** 
- Phase 1: Git initialization and remote setup
- Phase 2: Namespace/config rebranding across 4 addons (Unix Theme, Billing, Player List, Custom Sort)
- Phase 3: Unix theme integration with addon styles (billing, player list, custom sort UI consistency)
- Phase 4: Admin UI/UX updates (theme styles, shop management, Unix settings pages)
- Phase 5: Final verification, commit, and push to GitHub

**Tech Stack:** PHP 8.2+, Laravel 11, React/TypeScript, Blade, SortableJS

---

## Phase 1: Git Setup

### Task 1: Initialize git repo and configure remote

**Files:**
- Create: `.gitignore`
- Create: `.env.example`

- [ ] **Step 1: Initialize git repository**

```bash
cd /Users/rheninxy/Documents/Ptero
git init
```

Expected: "Initialized empty Git repository"

- [ ] **Step 2: Create .gitignore**

```bash
cat > .gitignore <<'EOF'
# Panel
panel/node_modules/
panel/vendor/
panel/.env
panel/bootstrap/cache/
panel/storage/
panel/tests/_output/

# Wings
wings/bin/
wings/vendor/

# IDE
.vscode/
.idea/
*.swp
*.swo
*.DS_Store

# Addons
**/node_modules/
**/vendor/
**/.env
**/storage/
**/cache/

# Build artifacts
dist/
build/
*.min.js
*.min.css
EOF
```

- [ ] **Step 3: Create .env.example**

```bash
cat > .env.example <<'EOF'
APP_NAME="Sourby"
APP_ENV=local
APP_DEBUG=true
APP_URL=http://localhost
THEME=sourby-unix

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=sourby_panel
DB_USERNAME=sourby
DB_PASSWORD=secret

MAIL_MAILER=log
MAIL_FROM_ADDRESS=admin@sourby.local

# Addons
SOURBY_BILLING_ENABLED=true
SOURBY_PLAYER_LIST_ENABLED=true
SOURBY_CUSTOM_SORT_ENABLED=true
EOF
```

- [ ] **Step 4: Configure GitHub remote**

```bash
git remote add origin https://github.com/YanIanZ/pteroject.git
```

- [ ] **Step 5: Create initial commit**

```bash
git add .gitignore .env.example
git commit -m "chore: initialize git repo with environment templates"
```

---

## Phase 2: Namespace & Config Rebranding

### Task 2: Rebrand Unix Theme (PHP namespaces + config)

**Files:**
- Modify: `Unix Theme v2/pterodactyl/app/Providers/UnixThemeServiceProvider.php`
- Modify: `Unix Theme v2/pterodactyl/config/unix.php`
- Create: `Unix Theme v2/pterodactyl/app/Providers/SourbyThemeServiceProvider.php`

- [ ] **Step 1: Create new Sourby service provider**

In `Unix Theme v2/pterodactyl/app/Providers/SourbyThemeServiceProvider.php`:

```php
<?php

namespace Pterodactyl\Providers;

use Illuminate\Support\Facades\Route;
use Illuminate\Support\ServiceProvider;
use Pterodactyl\Http\ViewComposers\SourbyThemeComposer;

class SourbyThemeServiceProvider extends ServiceProvider
{
    public function boot(): void
    {
        Route::middleware(['web', 'auth.session', 'csrf'])->prefix('/admin')
            ->group(base_path('routes/sourby.php'));

        view()->composer('*', SourbyThemeComposer::class);
    }

    public function register(): void
    {
        $this->mergeConfigFrom(__DIR__ . '/../../config/sourby.php', 'sourby');
    }
}
```

- [ ] **Step 2: Create Sourby theme composer**

In `Unix Theme v2/pterodactyl/app/Http/ViewComposers/SourbyThemeComposer.php`:

```php
<?php

namespace Pterodactyl\Http\ViewComposers;

use Illuminate\View\View;
use Pterodactyl\Models\SourbySetting;

class SourbyThemeComposer
{
    public function compose(View $view): void
    {
        if (!class_exists(SourbySetting::class)) {
            return;
        }

        $data = [];
        try {
            foreach (SourbySetting::all() as $setting) {
                $data[$setting->name] = $setting->value;
            }
        } catch (\Exception) {
        }

        $view->with('sourby_settings', $data);
    }
}
```

- [ ] **Step 3: Rename routes/unix.php to routes/sourby.php**

```bash
mv "Unix Theme v2/pterodactyl/routes/unix.php" "Unix Theme v2/pterodactyl/routes/sourby.php"
```

Update route names in `routes/sourby.php`:
- Replace `admin.unix` → `admin.sourby`
- Replace `admin.unix.*` → `admin.sourby.*`

- [ ] **Step 4: Create sourby.php config**

```bash
cp "Unix Theme v2/pterodactyl/config/unix.php" "Unix Theme v2/pterodactyl/config/sourby.php"
```

In `config/sourby.php`:

```php
<?php

return [
    'name' => 'Sourby',
    'author' => 'LocalHost',
    'version' => '2.2.0',
    'theme' => 'sourby-unix',
    'bg' => env('SOURBY_BACKGROUND', ''),
    'logo' => env('SOURBY_LOGO', ''),
    'favicon' => env('SOURBY_FAVICON', ''),
];
```

- [ ] **Step 5: Rename model**

```bash
mv "Unix Theme v2/pterodactyl/app/Models/UnixSetting.php" "Unix Theme v2/pterodactyl/app/Models/SourbySetting.php"
```

Update `SourbySetting.php`:

```php
<?php

namespace Pterodactyl\Models;

use Illuminate\Database\Eloquent\Model;

class SourbySetting extends Model
{
    protected $table = 'sourby_settings';

    protected $fillable = ['name', 'value'];
}
```

- [ ] **Step 6: Update Blade partials directory**

```bash
mv "Unix Theme v2/pterodactyl/resources/views/partials/unix" "Unix Theme v2/pterodactyl/resources/views/partials/sourby"
```

Update all Blade @include statements:
- Replace `partials.unix.*` → `partials.sourby.*`

- [ ] **Step 7: Commit rebranding changes**

```bash
git add "Unix Theme v2/pterodactyl/app/Providers/"
git add "Unix Theme v2/pterodactyl/app/Http/ViewComposers/"
git add "Unix Theme v2/pterodactyl/app/Models/SourbySetting.php"
git add "Unix Theme v2/pterodactyl/config/sourby.php"
git add "Unix Theme v2/pterodactyl/routes/sourby.php"
git add "Unix Theme v2/pterodactyl/resources/views/partials/sourby"
git commit -m "refactor: rebrand Unix theme to Sourby theme with new namespaces and config"
```

---

### Task 3: Rebrand Billing System (namespace + config)

**Files:**
- Modify: `billing-system-v1x-v143/PanelFiles/app/Classes/PayPal/PayPalPayment.php` (add Sourby comment)
- Modify: `billing-system-v1x-v143/PanelFiles/app/Http/Controllers/Api/Client/Shop/PaymentController.php`
- Modify: `billing-system-v1x-v143/PanelFiles/PanelEdit.txt`

- [ ] **Step 1: Add Sourby branding header to PayPalPayment**

In `PayPalPayment.php`, add after opening `<?php`:

```php
<?php
/**
 * Sourby Billing System - PayPal Integration
 * Handles PayPal Checkout SDK for payment processing
 */

namespace Pterodactyl\Classes\PayPal;
```

- [ ] **Step 2: Update PaymentController comments**

Add at top of `PaymentController.php`:

```php
<?php
/**
 * Sourby Billing System - Payment Processing Controller
 * Handles PayPal and Stripe payment methods
 */

namespace Pterodactyl\Http\Controllers\Api\Client\Shop;
```

- [ ] **Step 3: Update PanelEdit.txt with Sourby references**

In `billing-system-v1x-v143/PanelEdit.txt`, replace all occurrences:
- `Pterodactyl Panel` → `Sourby Panel`
- `shop` → `sourby_shop` (in config keys)
- Add section header: `## Sourby Billing System v1.0 — Installation for v1.12.2`

- [ ] **Step 4: Commit billing system changes**

```bash
git add billing-system-v1x-v143/
git commit -m "refactor: add Sourby branding to billing system"
```

---

### Task 4: Rebrand Player List addon (namespace + config)

**Files:**
- Modify: `Player List & Counter 1.0/PanelEdit.txt`

- [ ] **Step 1: Update PanelEdit.txt with Sourby naming**

In `Player List & Counter 1.0/PanelEdit.txt`, add header:

```
### Sourby Player List & Counter 1.0 — Installation for v1.12.2
```

Replace route names:
- `admin.players` → `admin.sourby.players`
- `admin.players.*` → `admin.sourby.players.*`

- [ ] **Step 2: Add Sourby comment to controller imports**

Update the comment section to reference Sourby:

```
// Sourby Player List - Player Counter Controller
use Pterodactyl\Http\Controllers\Admin\PlayerCounterController;
```

- [ ] **Step 3: Commit player list changes**

```bash
git add "Player List & Counter 1.0/"
git commit -m "refactor: add Sourby branding to Player List addon"
```

---

### Task 5: Rebrand Custom Server Sort (comments + config)

**Files:**
- Modify: `custom-server-sort-v103/customserversort.js`
- Modify: `custom-server-sort-v103/PanelEdit.txt`

- [ ] **Step 1: Add Sourby header to customserversort.js**

At top of `customserversort.js`:

```javascript
/**
 * Sourby Custom Server Sort 1.0.3
 * DOM-injection based server list sorting with localStorage persistence
 * Compatible with Sourby v1.12.2+
 */

(() => {
```

- [ ] **Step 2: Update PanelEdit.txt**

Replace header and first line:

```
### Sourby Custom Server Sort 1.0.3 — Updated for Sourby Panel v1.12.2

This addon enables drag-and-drop reordering of servers in the Sourby dashboard.
```

- [ ] **Step 3: Update path in installation**

Replace:
```
/themes/pterodactyl/js/customserversort.js
```
With:
```
/themes/sourby/js/customserversort.js
```

- [ ] **Step 4: Commit custom sort changes**

```bash
git add custom-server-sort-v103/
git commit -m "refactor: add Sourby branding to Custom Server Sort addon"
```

---

## Phase 3: Unix Theme + Addon Integration

### Task 6: Update Unix theme Blade templates for addon integration

**Files:**
- Modify: `Unix Theme v2/pterodactyl/resources/views/templates/wrapper.blade.php`
- Modify: `Unix Theme v2/pterodactyl/resources/views/layouts/admin.blade.php`
- Create: `Unix Theme v2/pterodactyl/resources/views/partials/sourby/addon-styles.blade.php`

- [ ] **Step 1: Create addon styles partial**

In `Unix Theme v2/pterodactyl/resources/views/partials/sourby/addon-styles.blade.php`:

```blade
{{-- Sourby Addon Integration Styles --}}
@if(config('sourby_billing_enabled', true))
    <link rel="stylesheet" href="/themes/sourby/css/addons/billing.css">
@endif

@if(config('sourby_player_list_enabled', true))
    <link rel="stylesheet" href="/themes/sourby/css/addons/player-list.css">
@endif

@if(config('sourby_custom_sort_enabled', true))
    <link rel="stylesheet" href="/themes/sourby/css/addons/custom-sort.css">
@endif
```

- [ ] **Step 2: Update wrapper.blade.php to include addon styles**

After `@include('partials.sourby.head-extras')`, add:

```blade
@include('partials.sourby.addon-styles')
```

- [ ] **Step 3: Update admin.blade.php sidebar menu**

Replace the "SHOP MANAGEMENT" section header with Sourby branding:

```blade
<li class="header">SOURBY SHOP MANAGEMENT</li>
<li class="{{ ! starts_with(Route::currentRouteName(), 'admin.sourby.settings') ?: 'active' }}">
    <a href="{{ route('admin.sourby.settings.payments') }}">
        <i class="fa fa-cog"></i> <span>Shop Settings</span>
    </a>
</li>
```

- [ ] **Step 4: Update route link in admin sidebar**

Replace:
```blade
<li class="{{ ! starts_with(Route::currentRouteName(), 'admin.unix') ?: 'active' }}">
    <a href="{{ route('admin.unix') }}">
        <i class="fa fa-paint-brush"></i> <span>Unix</span>
    </a>
</li>
```

With:
```blade
<li class="{{ ! starts_with(Route::currentRouteName(), 'admin.sourby') ?: 'active' }}">
    <a href="{{ route('admin.sourby') }}">
        <i class="fa fa-paint-brush"></i> <span>Sourby Theme</span>
    </a>
</li>
```

- [ ] **Step 5: Commit integration changes**

```bash
git add "Unix Theme v2/pterodactyl/resources/views/"
git commit -m "feat: integrate Unix theme with addon styles and update sidebar navigation"
```

---

### Task 7: Create CSS files for addon theme integration

**Files:**
- Create: `Unix Theme v2/pterodactyl/public/themes/sourby/css/addons/billing.css`
- Create: `Unix Theme v2/pterodactyl/public/themes/sourby/css/addons/player-list.css`
- Create: `Unix Theme v2/pterodactyl/public/themes/sourby/css/addons/custom-sort.css`

- [ ] **Step 1: Create billing addon CSS**

In `Unix Theme v2/pterodactyl/public/themes/sourby/css/addons/billing.css`:

```css
/* Sourby Billing System Addon Styling */

.sourby-shop-section {
    background: var(--theme-bg, #1a1a1a);
    border-radius: 0.5rem;
    padding: 1.5rem;
    margin-bottom: 2rem;
    border: 1px solid var(--theme-border, #333);
}

.sourby-shop-card {
    background: var(--theme-card, #242424);
    border-radius: 0.375rem;
    padding: 1rem;
    margin-bottom: 1rem;
    transition: background-color 0.2s ease;
}

.sourby-shop-card:hover {
    background-color: var(--theme-card-hover, #2a2a2a);
}

.sourby-payment-method {
    display: flex;
    align-items: center;
    gap: 1rem;
    padding: 1rem;
    border-radius: 0.375rem;
    cursor: pointer;
    transition: all 0.2s ease;
}

.sourby-payment-method:hover {
    background-color: rgba(255, 255, 255, 0.05);
}

.sourby-payment-icon {
    width: 2rem;
    height: 2rem;
    display: flex;
    align-items: center;
    justify-content: center;
    border-radius: 0.25rem;
    background: var(--theme-accent, #0ea5e9);
}
```

- [ ] **Step 2: Create player list addon CSS**

In `Unix Theme v2/pterodactyl/public/themes/sourby/css/addons/player-list.css`:

```css
/* Sourby Player List Addon Styling */

.sourby-player-counter {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    padding: 0.5rem 1rem;
    background: var(--theme-card, #242424);
    border-radius: 0.375rem;
    font-size: 0.875rem;
    color: var(--theme-text, #e5e7eb);
}

.sourby-player-counter-icon {
    display: inline-flex;
    width: 1.25rem;
    height: 1.25rem;
    align-items: center;
    justify-content: center;
}

.sourby-player-list {
    margin-top: 1rem;
    border-top: 1px solid var(--theme-border, #333);
    padding-top: 1rem;
}

.sourby-player-item {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 0.75rem;
    margin-bottom: 0.5rem;
    background: var(--theme-input, #1f1f1f);
    border-radius: 0.25rem;
    font-size: 0.875rem;
}

.sourby-player-status {
    display: inline-block;
    width: 0.5rem;
    height: 0.5rem;
    border-radius: 50%;
    margin-right: 0.5rem;
    background-color: #22c55e;
}
```

- [ ] **Step 3: Create custom sort addon CSS**

In `Unix Theme v2/pterodactyl/public/themes/sourby/css/addons/custom-sort.css`:

```css
/* Sourby Custom Server Sort Addon Styling */

.sourby-sortable-container {
    position: relative;
}

.sourby-sortable-container .sortable-ghost {
    opacity: 0.4;
    background-color: rgba(14, 165, 233, 0.1);
    border-radius: 0.375rem;
}

.sourby-server-item {
    cursor: grab;
    transition: all 0.2s ease;
    user-select: none;
}

.sourby-server-item:active {
    cursor: grabbing;
    opacity: 0.9;
}

.sourby-sort-handle {
    display: inline-flex;
    cursor: grab;
    opacity: 0.6;
    transition: opacity 0.2s ease;
}

.sourby-sort-handle:hover {
    opacity: 1;
}

.sourby-sort-indicator {
    display: inline-block;
    padding: 0.25rem 0.5rem;
    background: var(--theme-accent, #0ea5e9);
    color: white;
    font-size: 0.75rem;
    border-radius: 0.25rem;
    margin-left: 0.5rem;
}
```

- [ ] **Step 4: Commit addon CSS files**

```bash
git add "Unix Theme v2/pterodactyl/public/themes/sourby/css/addons/"
git commit -m "feat: add Sourby addon integration CSS for billing, player list, and custom sort"
```

---

## Phase 4: Admin UI/UX Updates

### Task 8: Create admin page CSS overrides for modern look

**Files:**
- Modify: `Unix Theme v2/pterodactyl/resources/views/layouts/admin.blade.php`
- Create: `Unix Theme v2/pterodactyl/public/themes/sourby/css/admin-modern.css`

- [ ] **Step 1: Create modern admin CSS**

In `Unix Theme v2/pterodactyl/public/themes/sourby/css/admin-modern.css`:

```css
/* Sourby Admin Panel Modern UI/UX Updates */

:root {
    --sourby-admin-bg: #0f0f0f;
    --sourby-admin-card: #1a1a1a;
    --sourby-admin-border: #2d2d2d;
    --sourby-admin-text: #e5e7eb;
    --sourby-admin-accent: #0ea5e9;
    --sourby-admin-success: #22c55e;
    --sourby-admin-warning: #f59e0b;
    --sourby-admin-danger: #ef4444;
}

body.hold-transition {
    background: var(--sourby-admin-bg);
    color: var(--sourby-admin-text);
}

.main-header {
    background: var(--sourby-admin-card);
    border-bottom: 1px solid var(--sourby-admin-border);
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.3);
}

.main-sidebar {
    background: var(--sourby-admin-card);
    border-right: 1px solid var(--sourby-admin-border);
}

.sidebar-menu > li {
    border-bottom: 1px solid var(--sourby-admin-border);
}

.sidebar-menu > li > a {
    color: var(--sourby-admin-text);
    transition: all 0.2s ease;
}

.sidebar-menu > li > a:hover {
    background: rgba(14, 165, 233, 0.1);
    border-left-color: var(--sourby-admin-accent);
    color: var(--sourby-admin-accent);
}

.sidebar-menu > li.active > a {
    background: rgba(14, 165, 233, 0.15);
    border-left-color: var(--sourby-admin-accent);
    color: var(--sourby-admin-accent);
}

.content-wrapper {
    background: var(--sourby-admin-bg);
}

.content-header {
    border-bottom: 1px solid var(--sourby-admin-border);
    padding-bottom: 1rem;
    margin-bottom: 1.5rem;
}

.content-header h1 {
    color: var(--sourby-admin-text);
    font-size: 1.875rem;
    font-weight: 600;
}

.box {
    background: var(--sourby-admin-card);
    border-top: 3px solid var(--sourby-admin-accent);
    border-radius: 0.375rem;
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.3);
}

.box-header {
    background: rgba(14, 165, 233, 0.05);
    border-bottom: 1px solid var(--sourby-admin-border);
    color: var(--sourby-admin-text);
}

.btn-primary {
    background: var(--sourby-admin-accent);
    border-color: var(--sourby-admin-accent);
    color: white;
}

.btn-primary:hover {
    background: #0284c7;
    border-color: #0284c7;
}

.btn-success {
    background: var(--sourby-admin-success);
    border-color: var(--sourby-admin-success);
    color: white;
}

.btn-danger {
    background: var(--sourby-admin-danger);
    border-color: var(--sourby-admin-danger);
    color: white;
}

.form-control {
    background: var(--sourby-admin-bg);
    border-color: var(--sourby-admin-border);
    color: var(--sourby-admin-text);
}

.form-control:focus {
    background: var(--sourby-admin-bg);
    border-color: var(--sourby-admin-accent);
    color: var(--sourby-admin-text);
    box-shadow: 0 0 0 0.2rem rgba(14, 165, 233, 0.25);
}

.alert-success {
    background: rgba(34, 197, 94, 0.1);
    border-color: var(--sourby-admin-success);
    color: var(--sourby-admin-success);
}

.alert-danger {
    background: rgba(239, 68, 68, 0.1);
    border-color: var(--sourby-admin-danger);
    color: var(--sourby-admin-danger);
}

.main-footer {
    background: var(--sourby-admin-card);
    border-top: 1px solid var(--sourby-admin-border);
    color: var(--sourby-admin-text);
}

.table {
    color: var(--sourby-admin-text);
}

.table > tbody > tr > td {
    border-color: var(--sourby-admin-border);
}

.table > tbody > tr:hover {
    background: rgba(14, 165, 233, 0.05);
}

/* Shop Management Section */
.sourby-shop-admin-section {
    background: var(--sourby-admin-card);
    border-radius: 0.375rem;
    padding: 1.5rem;
    margin-bottom: 2rem;
}

.sourby-shop-admin-title {
    font-size: 1.5rem;
    font-weight: 600;
    margin-bottom: 1rem;
    color: var(--sourby-admin-text);
}

/* Unix/Sourby Theme Settings */
.sourby-theme-settings {
    background: var(--sourby-admin-card);
    border: 1px solid var(--sourby-admin-border);
    border-radius: 0.375rem;
    padding: 1.5rem;
}

.sourby-setting-group {
    margin-bottom: 1.5rem;
    padding-bottom: 1.5rem;
    border-bottom: 1px solid var(--sourby-admin-border);
}

.sourby-setting-group:last-child {
    margin-bottom: 0;
    padding-bottom: 0;
    border-bottom: none;
}

.sourby-setting-label {
    display: block;
    font-weight: 600;
    margin-bottom: 0.5rem;
    color: var(--sourby-admin-text);
}

.sourby-setting-help {
    display: block;
    font-size: 0.875rem;
    color: #9ca3af;
    margin-top: 0.25rem;
}
```

- [ ] **Step 2: Link modern admin CSS in admin.blade.php**

In `layouts/admin.blade.php`, add after existing vendor styles:

```blade
<link rel="stylesheet" href="/themes/sourby/css/admin-modern.css">
```

- [ ] **Step 3: Commit admin UI updates**

```bash
git add "Unix Theme v2/pterodactyl/public/themes/sourby/css/admin-modern.css"
git add "Unix Theme v2/pterodactyl/resources/views/layouts/admin.blade.php"
git commit -m "feat: add modern admin UI/UX with dark theme and improved styling"
```

---

### Task 9: Create shop management pages view updates

**Files:**
- Modify: `billing-system-v1x-v143/PanelFiles/resources/scripts/components/elements/ScreenBlock.tsx` (verify deletion)
- Create: `Unix Theme v2/pterodactyl/resources/views/admin/sourby/shop/settings.blade.php`

- [ ] **Step 1: Verify ScreenBlock removed**

```bash
ls -la billing-system-v1x-v143/PanelFiles/resources/scripts/components/elements/ScreenBlock.tsx 2>/dev/null && echo "File exists" || echo "File already removed"
```

- [ ] **Step 2: Create shop settings view**

In `Unix Theme v2/pterodactyl/resources/views/admin/sourby/shop/settings.blade.php`:

```blade
@extends('layouts.admin')

@section('title')
    Sourby Shop Settings
@endsection

@section('content-header')
    <h1>
        <i class="fa fa-cog"></i> Shop Settings
    </h1>
@endsection

@section('content')
    <div class="sourby-shop-admin-section">
        <h2 class="sourby-shop-admin-title">Payment Methods Configuration</h2>
        
        <div class="box">
            <div class="box-header with-border">
                <h3 class="box-title">PayPal Settings</h3>
            </div>
            <form method="POST" action="{{ route('admin.sourby.settings.payments') }}">
                {{ csrf_field() }}
                
                <div class="box-body">
                    <div class="form-group">
                        <label for="paypal_enabled">Enable PayPal</label>
                        <select name="paypal_enabled" id="paypal_enabled" class="form-control">
                            <option value="0">Disabled</option>
                            <option value="1" selected>Enabled</option>
                        </select>
                    </div>
                    
                    <div class="form-group">
                        <label for="paypal_mode">PayPal Mode</label>
                        <select name="paypal_mode" id="paypal_mode" class="form-control">
                            <option value="sandbox">Sandbox</option>
                            <option value="live">Live</option>
                        </select>
                        <small class="form-text text-muted">Select sandbox for testing, live for production</small>
                    </div>
                    
                    <div class="form-group">
                        <label for="paypal_key">Client ID</label>
                        <input type="text" name="paypal_key" id="paypal_key" class="form-control" placeholder="PayPal Client ID">
                    </div>
                    
                    <div class="form-group">
                        <label for="paypal_secret">Client Secret</label>
                        <input type="password" name="paypal_secret" id="paypal_secret" class="form-control" placeholder="PayPal Client Secret">
                    </div>
                </div>
                
                <div class="box-footer">
                    <button type="submit" class="btn btn-primary">Save Changes</button>
                </div>
            </form>
        </div>
        
        <div class="box" style="margin-top: 2rem;">
            <div class="box-header with-border">
                <h3 class="box-title">Stripe Settings</h3>
            </div>
            <form method="POST" action="{{ route('admin.sourby.settings.payments') }}">
                {{ csrf_field() }}
                
                <div class="box-body">
                    <div class="form-group">
                        <label for="stripe_enabled">Enable Stripe</label>
                        <select name="stripe_enabled" id="stripe_enabled" class="form-control">
                            <option value="0">Disabled</option>
                            <option value="1" selected>Enabled</option>
                        </select>
                    </div>
                    
                    <div class="form-group">
                        <label for="stripe_key">Public Key</label>
                        <input type="text" name="stripe_key" id="stripe_key" class="form-control" placeholder="Stripe Publishable Key">
                    </div>
                    
                    <div class="form-group">
                        <label for="stripe_secret">Secret Key</label>
                        <input type="password" name="stripe_secret" id="stripe_secret" class="form-control" placeholder="Stripe Secret Key">
                    </div>
                </div>
                
                <div class="box-footer">
                    <button type="submit" class="btn btn-primary">Save Changes</button>
                </div>
            </form>
        </div>
    </div>
@endsection
```

- [ ] **Step 3: Commit shop views**

```bash
git add "Unix Theme v2/pterodactyl/resources/views/admin/sourby/"
git commit -m "feat: add Sourby shop management admin pages with modern UI"
```

---

## Phase 5: Final Verification & Deployment

### Task 10: Create README and verify all integrations

**Files:**
- Create: `README.md` (root)
- Create: `SOURBY_INTEGRATION.md`

- [ ] **Step 1: Create root README**

In `/Users/rheninxy/Documents/Ptero/README.md`:

```markdown
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
```

- [ ] **Step 2: Create integration guide**

In `/Users/rheninxy/Documents/Ptero/SOURBY_INTEGRATION.md`:

```markdown
# Sourby Integration Guide

This document outlines the integration between the Sourby theme and all addons.

## Architecture

- **Sourby Theme (Unix Theme v2.2.0)**: Main visual theme and layout
- **Billing System**: Payment processing with theme integration
- **Player List**: Server player counter and list display
- **Custom Server Sort**: Drag-and-drop server reordering

## Database Tables

All addons work with the existing Pterodactyl schema plus these custom tables:

### Sourby Settings
```sql
CREATE TABLE sourby_settings (
  id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(255) UNIQUE,
  value TEXT,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);
```

### Billing Tables
- `payments` - Payment transaction records
- `games` - Game products in shop
- `game_category` - Shop categories

### Player Counter Tables
- `player_counter` - Player count tracking

## CSS Integration

The theme includes addon-specific CSS:

- `/themes/sourby/css/addons/billing.css` - Payment UI styling
- `/themes/sourby/css/addons/player-list.css` - Player counter styling
- `/themes/sourby/css/addons/custom-sort.css` - Drag-and-drop styling
- `/themes/sourby/css/admin-modern.css` - Admin panel modernization

## Blade Component Integration

All addon Blade components inherit Sourby theme styles automatically via:

1. **Partials**: Located in `resources/views/partials/sourby/`
   - `sidebar.blade.php` - Main navigation
   - `head-extras.blade.php` - CSS/meta tags
   - `addon-styles.blade.php` - Addon stylesheet loading

2. **Wrapper Stack**: Uses `@stack` directives for theme injection
   - `@stack('sourby-head')` - CSS injections
   - `@stack('sourby-body')` - Body-level injections

## Configuration via Environment

Control addon visibility in `.env`:

```env
SOURBY_BILLING_ENABLED=true|false
SOURBY_PLAYER_LIST_ENABLED=true|false
SOURBY_CUSTOM_SORT_ENABLED=true|false
```

## Customization

### Theme Colors

Define in `config/sourby.php`:

```php
return [
    'colors' => [
        'primary' => '#0ea5e9',
        'success' => '#22c55e',
        'warning' => '#f59e0b',
        'danger' => '#ef4444',
    ],
];
```

### Theme Settings UI

Manage in admin panel at: `/admin/sourby`

Available settings:
- Background image
- Logo image
- Favicon
- Custom colors
- Addon enablement

## Testing Addons Together

1. **Billing Integration**: Buy balance → confirm balance updates in profile
2. **Player List**: Check console → player count displays correctly
3. **Custom Sort**: Drag servers → verify localStorage persistence
4. **Theme**: Verify all components use theme colors and styles

## Troubleshooting

### Styles not loading
- Clear cache: `php artisan cache:clear`
- Rebuild CSS: `yarn run build:production`
- Check theme path in `.env`

### Addon routes not working
- Verify service providers registered in `bootstrap/app.php`
- Run migrations: `php artisan migrate`
- Check route names match in sidebar

### JavaScript errors
- Open browser console (F12)
- Check for missing imports or syntax errors
- Verify SortableJS loaded for custom sort

## Version Compatibility

- **Panel**: Pterodactyl v1.12.0+
- **Wings**: Go 1.24+ (unchanged)
- **PHP**: 8.2+
- **Laravel**: 11+
```

- [ ] **Step 3: Create git tag for release**

```bash
git tag -a v1.0.0-sourby -m "Sourby rebranding and integration complete"
```

- [ ] **Step 4: Add and commit documentation**

```bash
git add README.md SOURBY_INTEGRATION.md
git commit -m "docs: add Sourby project documentation and integration guide"
```

---

### Task 11: Final verification and GitHub push

**Files:**
- None (verification only)

- [ ] **Step 1: Verify all files are tracked**

```bash
git status
```

Expected: All files staged or committed, no untracked files in critical paths

- [ ] **Step 2: View commit history**

```bash
git log --oneline | head -20
```

Expected: 10+ commits showing rebranding and integration work

- [ ] **Step 3: Create GitHub push**

```bash
git branch -M main
git push -u origin main --tags
```

Expected: All commits and tags pushed to GitHub

- [ ] **Step 4: Verify GitHub push**

```bash
git log --oneline -5 origin/main
```

Expected: Latest commits visible on remote

- [ ] **Step 5: Final commit**

```bash
git log --oneline | wc -l
echo "Total commits: $(git log --oneline | wc -l)"
```

Record total number of commits for documentation.

---

## Summary

**Total Tasks: 11**
- Phase 1 (Git Setup): 1 task
- Phase 2 (Rebranding): 4 tasks
- Phase 3 (Theme Integration): 2 tasks
- Phase 4 (Admin UI): 2 tasks
- Phase 5 (Deployment): 2 tasks

**Expected Outcomes:**
- ✅ All addons rebranded to "Sourby"
- ✅ Unix theme fully integrated with billing, player list, and custom sort
- ✅ Modern dark admin panel UI/UX
- ✅ Complete documentation and integration guides
- ✅ Code pushed to GitHub at https://github.com/YanIanZ/pteroject

**Estimated Duration:** 2-3 hours for implementation + testing
