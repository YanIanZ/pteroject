# Pterodactyl Addons & Theme Upgrade to Panel v1.12.2

**Date:** 2026-05-11
**Scope:** Unix Theme v2, Billing System v1.4.3, Player List & Counter v1.0, Custom Server Sort v1.0.3
**Target:** Rewrite addon/theme files in place for compatibility with Pterodactyl Panel v1.12.2 (Laravel 11, PHP 8.2+, React)

## Current State

| Component | Addon Version | Built For | Has PanelEdit.txt | Install Mechanism |
|-----------|-------------|-----------|-------------------|-------------------|
| Unix Theme v2 | 2.0 | Panel 1.6.x | Yes (README.txt) | Merge into panel |
| Billing System | 1.4.3 | Panel 1.x | Yes (PanelEdit.txt) | Merge into panel |
| Player List & Counter | 1.0 | Panel 1.x | Yes (PanelEdit.txt) | Merge into panel |
| Custom Server Sort | 1.0.3 | Unknown | No (blueprint only) | Blueprint binary |

## Goals

1. Rewrite all 4 components to be compatible with panel v1.12.2
2. Non-destructive: fix addon source files, not the panel itself
3. Each addon gets an updated install guide referencing v1.12.2 paths
4. Avoid overwriting core panel files where possible (providers, routes)

---

## 1. Unix Theme v2

### Backend

#### Removals
- `app/Providers/RouteServiceProvider.php` — **DELETE.** No longer overwrite the panel's provider. Routes registered in dedicated service provider.

#### New Files
- `app/Providers/UnixThemeServiceProvider.php` — registers unix routes in `boot()` via `Route::middleware('web')->group(fn)`, registers ViewComposer
- `app/Http/ViewComposers/UnixThemeComposer.php` — shares `unix_settings` with all views via `View::composer('*', fn)` instead of per-controller `setting_data`

#### Modified Files
- `app/Http/Controllers/Auth/LoginController.php`:
  - `__construct()` takes zero args (parent `AbstractLoginController::__construct()` has zero params)
  - `index()` returns `view('templates/auth.core')` — no `setting_data`
  - `login()` uses `User::query()->where($field, $username)->firstOrFail()` + `ModelNotFoundException` (panel pattern)
  - Removes `UnixSetting` import from LoginController (moved to ViewComposer)
- `app/Http/Controllers/Admin/BaseController.php`:
  - `__construct()` uses promoted property: `private SoftwareVersionService $version`
  - `index()` returns `view('admin.index', ['version' => $this->version])` only
- `app/Models/UnixSetting.php`:
  - Add `protected $fillable = ['name', 'value']` and `protected $table = 'unix_settings'`
- `config/unix.php`:
  - Stripped to only theme-specific config keys (not a clone of app.php)
- `routes/unix.php`:
  - All routes converted from `'Controller@method'` to `[Controller::class, 'method']`

### Frontend

#### Removals
- `resources/scripts/routers/ServerRouter.tsx` — **DELETE.** Panel uses declarative `routes.ts`.
- `resources/scripts/components/dashboard/DashboardContainer.tsx` (root level duplicate) — **DELETE.**
- `resources/scripts/components/dashboard/DashboardContainer.tsx` (dashboard subdir) — **DELETE.**

#### Modified Files
- `resources/scripts/components/dashboard/ServerRow.tsx`:
  - `bytesToHuman` / `megabytesToHuman` → `bytesToString` from `@/lib/formatters`
- `resources/views/templates/wrapper.blade.php`:
  - Based on panel v1.12.2 wrapper (49 lines). Add `@stack('unix-head')` in `<head>`, `@stack('unix-body')` before `</body>`
- `resources/views/templates/base/core.blade.php`:
  - Based on panel v1.12.2 (8 lines). Add `@include('partials/unix.sidebar')` before `<div id="app">`
- `resources/views/templates/auth/core.blade.php`:
  - Based on panel v1.12.2 (7 lines). Add `@include('partials/unix.login-theme')` before `<div id="app">`
- `resources/views/layouts/admin.blade.php`:
  - Based on panel v1.12.2. Add Unix nav entry in sidebar menu
- All hardcoded styled-components CSS hashes removed from Blade templates

#### New Files
- `resources/views/partials/unix/sidebar.blade.php` — theme sidebar (formerly inline in core.blade.php)
- `resources/views/partials/unix/login-theme.blade.php` — login page theme extras
- `resources/views/partials/unix/head-extras.blade.php` — CSS/font includes

### Styling
- All `.styled-components-hash` classes removed from Blade
- Theme styles move to `public/themes/unix/css/core.css`
- FontAwesome Pro 5 CDN replaced with FontAwesome Free 5 (already in panel)

---

## 2. Billing System v1.4.3

### Removals
- `app/Classes/PayPal/sdk/*` — entire 28-file deprecated PayPal REST SDK deleted
- Composer dependency `laraveldaily/laravel-invoices:^3.0` removed from instructions

### Modified Files
- `app/Classes/PayPal/PayPalPayment.php`:
  - Rewritten to use `paypal/paypal-checkout-sdk` (PHP 8.2+ compatible)
- `app/Http/Controllers/Api/Client/Shop/PaymentController.php`:
  - Invoice generation rewritten using Blade view + `barryvdh/laravel-dompdf`
  - All `DB::table()` queries → Eloquent (`Server::query()`, `User::query()`)
- All other controllers (`ShopController`, `ServerRenewController`, `CategoriesController`, `GamesController`, `PaymentsController`, `PlayersController`):
  - `DB::table()` → Eloquent models throughout
- `resources/scripts/components/elements/ScreenBlock.tsx`:
  - Remove `<SuspendedBox />` insertion (move to Dashboard)
- `resources/scripts/components/dashboard/DashboardContainer.tsx`:
  - Add `<SuspendedBox />` here instead
- `PanelEdit.txt`:
  - Updated composer requirements: `stripe/stripe-php`, `paypal/paypal-checkout-sdk`, `barryvdh/laravel-dompdf`
  - Updated line references for v1.12.2 routes (api-client.php, admin.php)
  - Add instruction to register `settings.renew` permission

### New Files
- `resources/views/admin/shop/invoice.blade.php` — Blade invoice template (replaces laravel-invoices)

---

## 3. Player List & Counter v1.0

### Modified Files
- `PanelEdit.txt`:
  - Update `ServerConsole.tsx` target → `server/console/ServerConsoleContainer.tsx` with updated insertion point
  - Admin routes: `'PlayerCounterController@method'` → `[Admin\PlayerCounterController::class, 'method']`
- No backend code changes needed (controllers, models, migrations are structurally compatible)

---

## 4. Custom Server Sort v1.0.3

### Removals
- `customserversort.blueprint` — **DELETE.** Blueprint binary, not used.
- `customserversort.html` — **DELETE.** Replaced entirely.

### New Files
- `customserversort.js` — Self-contained JS module:
  - MutationObserver on `#app` subtree to detect dashboard server list render
  - Target server rows by `data-server-uuid` attribute or semantic DOM (not CSS hashes)
  - SortableJS integration on the server list container
  - Persist order to `localStorage` keyed by user UUID
  - No React import needed — pure DOM manipulation
- `PanelEdit.txt`:
  - Copy `customserversort.js` to `public/themes/pterodactyl/js/`
  - Add `<script src="/themes/pterodactyl/js/customserversort.js"></script>` in `wrapper.blade.php` after `{!! $asset->js('main.js') !!}`
  - No panel source file modifications needed

---

## Implementation Order

1. Unix Theme v2 (most complex, establishes patterns for others)
2. Billing System v1.4.3
3. Player List & Counter v1.0
4. Custom Server Sort v1.0.3

## Constraints

- PHP 8.2+ required by panel
- Laravel 11 patterns: no `$namespace` on RouteServiceProvider, FQCN route arrays, promoted constructor properties
- React: declarative `routes.ts`, component tree at `server/console/`, `server/files/`, etc.
- All fixes written to addon source directories; panel untouched
- Each addon gets updated `PanelEdit.txt` or installation instructions
