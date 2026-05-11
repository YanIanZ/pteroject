# Graph Report - /Users/rheninxy/Documents/Ptero/docs/superpowers/plans  (2026-05-11)

## Corpus Check
- Corpus is ~7,600 words - fits in a single context window. You may not need a graph.

## Summary
- 49 nodes · 55 edges · 10 communities (9 shown, 1 thin omitted)
- Extraction: 78% EXTRACTED · 20% INFERRED · 2% AMBIGUOUS · INFERRED: 11 edges (avg confidence: 0.87)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Addon Service Provider Pattern|Addon Service Provider Pattern]]
- [[_COMMUNITY_Legacy Billing System|Legacy Billing System]]
- [[_COMMUNITY_Core Platform Stack|Core Platform Stack]]
- [[_COMMUNITY_Sourby Rebrand Integration|Sourby Rebrand Integration]]
- [[_COMMUNITY_Addon CSS Bundle|Addon CSS Bundle]]
- [[_COMMUNITY_Payment Gateway Integration|Payment Gateway Integration]]
- [[_COMMUNITY_Sourby Repository & Branding|Sourby Repository & Branding]]
- [[_COMMUNITY_Custom Server Sort|Custom Server Sort]]
- [[_COMMUNITY_Player List & Counter|Player List & Counter]]
- [[_COMMUNITY_Screen Block Component|Screen Block Component]]

## God Nodes (most connected - your core abstractions)
1. `Pterodactyl Panel v1.12.2` - 10 edges
2. `Billing System v1.x (v1.43)` - 7 edges
3. `Sourby (Rebranded Pterodactyl Panel)` - 6 edges
4. `SourbyThemeServiceProvider` - 5 edges
5. `Unix Theme v2.2.0` - 5 edges
6. `Sourby Unix Theme v2.2.0` - 4 edges
7. `Sourby Billing System (PayPal + Stripe)` - 4 edges
8. `addon-styles.blade.php (Addon CSS Loader)` - 4 edges
9. `Custom Server Sort 1.0.3` - 4 edges
10. `UnixThemeServiceProvider` - 4 edges

## Surprising Connections (you probably didn't know these)
- `Sourby (Rebranded Pterodactyl Panel)` --semantically_similar_to--> `Pterodactyl Panel v1.12.2`  [INFERRED] [semantically similar]
  docs/superpowers/plans/2026-05-11-ptero-sourby-rebrand-integration.md → docs/superpowers/plans/2026-05-11-ptero-addons-theme-upgrade.md
- `Sourby Billing System (PayPal + Stripe)` --semantically_similar_to--> `Billing System v1.x (v1.43)`  [INFERRED] [semantically similar]
  docs/superpowers/plans/2026-05-11-ptero-sourby-rebrand-integration.md → docs/superpowers/plans/2026-05-11-ptero-addons-theme-upgrade.md
- `Sourby Custom Server Sort 1.0.3` --semantically_similar_to--> `Custom Server Sort 1.0.3`  [INFERRED] [semantically similar]
  docs/superpowers/plans/2026-05-11-ptero-sourby-rebrand-integration.md → docs/superpowers/plans/2026-05-11-ptero-addons-theme-upgrade.md
- `SourbyThemeServiceProvider` --references--> `Service Provider Injection Pattern`  [INFERRED]
  docs/superpowers/plans/2026-05-11-ptero-sourby-rebrand-integration.md → docs/superpowers/plans/2026-05-11-ptero-addons-theme-upgrade.md
- `Sourby Unix Theme v2.2.0` --conceptually_related_to--> `Unix Theme v2.2.0`  [AMBIGUOUS]
  docs/superpowers/plans/2026-05-11-ptero-sourby-rebrand-integration.md → docs/superpowers/plans/2026-05-11-ptero-addons-theme-upgrade.md

## Hyperedges (group relationships)
- **Sourby Theme Package (Service Provider + Composer + Model)** — 2026-05-11-ptero-sourby-rebrand-integration_sourby-theme-service-provider, 2026-05-11-ptero-sourby-rebrand-integration_sourby-theme-composer, 2026-05-11-ptero-sourby-rebrand-integration_sourby-setting [INFERRED]
- **Sourby Addon CSS Bundle (Billing + Player List + Custom Sort Styles)** — 2026-05-11-ptero-sourby-rebrand-integration_sourby-billing-css, 2026-05-11-ptero-sourby-rebrand-integration_sourby-player-list-css, 2026-05-11-ptero-sourby-rebrand-integration_sourby-custom-sort-css [EXTRACTED]
- **Payment Gateway Duality (PayPal + Stripe via PaymentController)** — 2026-05-11-ptero-addons-theme-upgrade_paypal-payment, 2026-05-11-ptero-addons-theme-upgrade_payment-controller, 2026-05-11-ptero-addons-theme-upgrade_stripe [EXTRACTED]

## Communities (10 total, 1 thin omitted)

### Community 0 - "Addon Service Provider Pattern"
Cohesion: 0.29
Nodes (10): admin.unix.* Routes, unix.php Config, UnixSetting (Eloquent Model), UnixThemeComposer, UnixThemeServiceProvider, admin.sourby.* Routes, sourby.php Config, SourbySetting (Eloquent Model) (+2 more)

### Community 1 - "Legacy Billing System"
Cohesion: 0.29
Nodes (7): Billing System v1.x (v1.43), laravel-invoices Library (Deprecated), PanelEdit.txt (Billing Installation), PaymentController (Billing), PayPalPayment (PayPal Checkout SDK Wrapper), PayPal REST API SDK (Deprecated), ShopController (Billing - Eloquent Conversion)

### Community 2 - "Core Platform Stack"
Cohesion: 0.33
Nodes (6): Blade (Laravel Templating), Go 1.24 (Wings), Laravel 11, PHP 8.2+, Pterodactyl Panel v1.12.2, React/TypeScript

### Community 3 - "Sourby Rebrand Integration"
Cohesion: 0.33
Nodes (6): RouteServiceProvider.php (Deleted), Service Provider Injection Pattern, Unix Theme v2.2.0, Sourby Admin Modern CSS (Dark Theme), SOURBY_INTEGRATION.md (Integration Guide), Sourby Unix Theme v2.2.0

### Community 4 - "Addon CSS Bundle"
Cohesion: 0.4
Nodes (5): Blade @stack/@push Section Stacking Pattern, addon-styles.blade.php (Addon CSS Loader), Sourby Billing Addon CSS, Sourby Custom Sort Addon CSS, Sourby Player List Addon CSS

### Community 5 - "Payment Gateway Integration"
Cohesion: 0.5
Nodes (4): PayPal Checkout SDK, Sourby Billing System (PayPal + Stripe), Sourby Shop Settings View (Blade), Stripe Payment Integration

### Community 6 - "Sourby Repository & Branding"
Cohesion: 0.67
Nodes (3): pteroject (GitHub Repository), Sourby (Rebranded Pterodactyl Panel), Sourby Custom Server Sort 1.0.3

### Community 7 - "Custom Server Sort"
Cohesion: 0.67
Nodes (3): Custom Server Sort 1.0.3, DOM-Injection JavaScript Pattern, SortableJS

### Community 8 - "Player List & Counter"
Cohesion: 0.67
Nodes (3): Player List & Counter 1.0, ServerConsoleContainer.tsx, Sourby Player List & Counter 1.0

## Ambiguous Edges - Review These
- `Sourby Unix Theme v2.2.0` → `Unix Theme v2.2.0`  [AMBIGUOUS]
  docs/superpowers/plans/2026-05-11-ptero-sourby-rebrand-integration.md · relation: conceptually_related_to

## Knowledge Gaps
- **24 isolated node(s):** `Sourby Billing Addon CSS`, `Sourby Player List Addon CSS`, `Sourby Custom Sort Addon CSS`, `Sourby Admin Modern CSS (Dark Theme)`, `Sourby Shop Settings View (Blade)` (+19 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **1 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What is the exact relationship between `Sourby Unix Theme v2.2.0` and `Unix Theme v2.2.0`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._
- **Why does `Pterodactyl Panel v1.12.2` connect `Core Platform Stack` to `Legacy Billing System`, `Sourby Rebrand Integration`, `Sourby Repository & Branding`, `Custom Server Sort`, `Player List & Counter`?**
  _High betweenness centrality (0.553) - this node is a cross-community bridge._
- **Why does `Unix Theme v2.2.0` connect `Sourby Rebrand Integration` to `Core Platform Stack`, `Addon CSS Bundle`?**
  _High betweenness centrality (0.519) - this node is a cross-community bridge._
- **Why does `Service Provider Injection Pattern` connect `Sourby Rebrand Integration` to `Addon Service Provider Pattern`?**
  _High betweenness centrality (0.319) - this node is a cross-community bridge._
- **Are the 2 inferred relationships involving `SourbyThemeServiceProvider` (e.g. with `UnixThemeServiceProvider` and `Service Provider Injection Pattern`) actually correct?**
  _`SourbyThemeServiceProvider` has 2 INFERRED edges - model-reasoned connections that need verification._
- **What connects `Sourby Billing Addon CSS`, `Sourby Player List Addon CSS`, `Sourby Custom Sort Addon CSS` to the rest of the system?**
  _24 weakly-connected nodes found - possible documentation gaps or missing edges._