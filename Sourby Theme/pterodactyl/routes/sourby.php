<?php

use Illuminate\Support\Facades\Route;
use Pterodactyl\Http\Controllers\Admin\BaseController;
use Pterodactyl\Http\Controllers\Admin\Unix\UnixController;
use Pterodactyl\Http\Controllers\Admin\Unix\UpdateController;
use Pterodactyl\Http\Controllers\Admin\Unix\SupportController;
use Pterodactyl\Http\Controllers\Admin\Unix\AlertsController;
use Pterodactyl\Http\Controllers\Admin\Unix\LoginController as UnixLoginController;
use Pterodactyl\Http\Controllers\Admin\Unix\MetaController;
use Pterodactyl\Http\Controllers\Admin\Unix\AdvancedController;
use Pterodactyl\Http\Controllers\Admin\Unix\ConnectController;
use Pterodactyl\Http\Controllers\Admin\Unix\BackgroundController;
use Pterodactyl\Http\Controllers\Admin\Unix\UnixSettingController;

Route::get('/', [BaseController::class, 'index'])->name('admin.index');

Route::group(['prefix' => 'sourby'], function () {
    Route::get('/', [UnixController::class, 'index'])->name('admin.sourby');
    Route::get('/updates', [UpdateController::class, 'index'])->name('admin.sourby.update');
    Route::get('/support', [SupportController::class, 'index'])->name('admin.sourby.support');
    Route::get('/alerts', [AlertsController::class, 'index'])->name('admin.sourby.alerts');
    Route::get('/login-page', [UnixLoginController::class, 'index'])->name('admin.sourby.login');
    Route::get('/meta', [MetaController::class, 'index'])->name('admin.sourby.meta');
    Route::get('/advanced', [AdvancedController::class, 'index'])->name('admin.sourby.advanced');
    Route::get('/connectivity', [ConnectController::class, 'index'])->name('admin.sourby.connect');
    Route::get('/background', [BackgroundController::class, 'index'])->name('admin.sourby.background');
    Route::post('/setting', [UnixSettingController::class, 'settingSubmit'])->name('admin.sourby.setting');
});
