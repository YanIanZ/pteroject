<?php

namespace Pterodactyl\Providers;

use Illuminate\Support\Facades\Route;
use Illuminate\Support\ServiceProvider;
use Pterodactyl\Http\ViewComposers\UnixThemeComposer;

class UnixThemeServiceProvider extends ServiceProvider
{
    public function boot(): void
    {
        Route::middleware(['web', 'auth.session', 'csrf'])->prefix('/admin')
            ->group(base_path('routes/unix.php'));

        view()->composer('*', UnixThemeComposer::class);
    }

    public function register(): void
    {
        $this->mergeConfigFrom(__DIR__ . '/../../config/unix.php', 'unix');
    }
}
