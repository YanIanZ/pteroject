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

Route::group(['prefix' => 'unix'], function () {
    Route::get('/', [UnixController::class, 'index'])->name('admin.unix');
    Route::get('/updates', [UpdateController::class, 'index'])->name('admin.unix.update');
    Route::get('/support', [SupportController::class, 'index'])->name('admin.unix.support');
    Route::get('/alerts', [AlertsController::class, 'index'])->name('admin.unix.alerts');
    Route::get('/login-page', [UnixLoginController::class, 'index'])->name('admin.unix.login');
    Route::get('/meta', [MetaController::class, 'index'])->name('admin.unix.meta');
    Route::get('/advanced', [AdvancedController::class, 'index'])->name('admin.unix.advanced');
    Route::get('/connectivity', [ConnectController::class, 'index'])->name('admin.unix.connect');
    Route::get('/background', [BackgroundController::class, 'index'])->name('admin.unix.background');
    Route::post('/setting', [UnixSettingController::class, 'settingSubmit'])->name('admin.unix.setting');
});
