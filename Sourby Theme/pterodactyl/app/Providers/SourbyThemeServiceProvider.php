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
