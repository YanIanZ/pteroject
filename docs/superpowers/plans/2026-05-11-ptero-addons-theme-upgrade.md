# Ptero Addons & Theme v1.12.2 Upgrade — Implementation Plan

> **For agentic workers:** Use subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rewrite 4 addons/themes for Pterodactyl Panel v1.12.2 (Laravel 11, PHP 8.2+, React), fixing all critical/high incompatibilities without modifying the panel itself.

**Architecture:** Each addon stays in its own directory. Unix Theme replaces destructive overrides with service-provider injection + Blade section stacking. Billing replaces deprecated PayPal SDK and `laravel-invoices` with modern equivalents. Player List updates install targets. Custom Server Sort rewritten as DOM-injection JS.

**Tech Stack:** PHP 8.2+, Laravel 11, Go 1.24 (Wings unchanged), React/TypeScript, Blade, SortableJS

---

### Task 1: Unix Theme — Backend Rewrite

**Files:**
- Delete: `Unix Theme v2/pterodactyl/app/Providers/RouteServiceProvider.php`
- Modify: `Unix Theme v2/pterodactyl/app/Http/Controllers/Auth/LoginController.php`
- Modify: `Unix Theme v2/pterodactyl/app/Http/Controllers/Admin/BaseController.php`
- Modify: `Unix Theme v2/pterodactyl/app/Models/UnixSetting.php`
- Modify: `Unix Theme v2/pterodactyl/routes/unix.php`
- Modify: `Unix Theme v2/pterodactyl/config/unix.php`
- Create: `Unix Theme v2/pterodactyl/app/Providers/UnixThemeServiceProvider.php`
- Create: `Unix Theme v2/pterodactyl/app/Http/ViewComposers/UnixThemeComposer.php`

#### Step 1: Delete RouteServiceProvider.php

```bash
rm "Unix Theme v2/pterodactyl/app/Providers/RouteServiceProvider.php"
```

#### Step 2: Create UnixThemeServiceProvider.php

Write `Unix Theme v2/pterodactyl/app/Providers/UnixThemeServiceProvider.php`:

```php
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
```

#### Step 3: Create UnixThemeComposer.php

Write `Unix Theme v2/pterodactyl/app/Http/ViewComposers/UnixThemeComposer.php`:

```php
<?php

namespace Pterodactyl\Http\ViewComposers;

use Illuminate\View\View;
use Pterodactyl\Models\UnixSetting;

class UnixThemeComposer
{
    public function compose(View $view): void
    {
        if (!class_exists(UnixSetting::class)) {
            return;
        }

        $data = [];
        try {
            foreach (UnixSetting::all() as $setting) {
                $data[$setting->name] = $setting->value;
            }
        } catch (\Exception) {
        }

        $view->with('setting_data', $data);
    }
}
```

#### Step 4: Rewrite LoginController.php

Replace `Unix Theme v2/pterodactyl/app/Http/Controllers/Auth/LoginController.php`:

```php
<?php

namespace Pterodactyl\Http\Controllers\Auth;

use Carbon\CarbonImmutable;
use Illuminate\Support\Str;
use Illuminate\Http\Request;
use Pterodactyl\Models\User;
use Illuminate\Http\JsonResponse;
use Pterodactyl\Facades\Activity;
use Illuminate\Contracts\View\View;
use Illuminate\Database\Eloquent\ModelNotFoundException;

class LoginController extends AbstractLoginController
{
    public function index(): View
    {
        return view('templates/auth.core');
    }

    public function login(Request $request): JsonResponse
    {
        if ($this->hasTooManyLoginAttempts($request)) {
            $this->fireLockoutEvent($request);
            $this->sendLockoutResponse($request);
        }

        try {
            $username = $request->input('user');
            $user = User::query()->where($this->getField($username), $username)->firstOrFail();
        } catch (ModelNotFoundException) {
            $this->sendFailedLoginResponse($request);
        }

        if (!password_verify($request->input('password'), $user->password)) {
            $this->sendFailedLoginResponse($request, $user);
        }

        if (!$user->use_totp) {
            return $this->sendLoginResponse($user, $request);
        }

        Activity::event('auth:checkpoint')->withRequestMetadata()->subject($user)->log();

        $request->session()->put('auth_confirmation_token', [
            'user_id' => $user->id,
            'token_value' => $token = Str::random(64),
            'expires_at' => CarbonImmutable::now()->addMinutes(5),
        ]);

        return new JsonResponse([
            'data' => [
                'complete' => false,
                'confirmation_token' => $token,
            ],
        ]);
    }
}
```

#### Step 5: Rewrite Admin BaseController.php

Replace `Unix Theme v2/pterodactyl/app/Http/Controllers/Admin/BaseController.php`:

```php
<?php

namespace Pterodactyl\Http\Controllers\Admin;

use Illuminate\View\View;
use Pterodactyl\Http\Controllers\Controller;
use Pterodactyl\Services\Helpers\SoftwareVersionService;

class BaseController extends Controller
{
    public function __construct(private SoftwareVersionService $version) {}

    public function index(): View
    {
        return view('admin.index', ['version' => $this->version]);
    }
}
```

#### Step 6: Fix UnixSetting Model

Replace `Unix Theme v2/pterodactyl/app/Models/UnixSetting.php`:

```php
<?php

namespace Pterodactyl\Models;

use Illuminate\Database\Eloquent\Model;

class UnixSetting extends Model
{
    protected $table = 'unix_settings';

    protected $fillable = ['name', 'value'];
}
```

#### Step 7: Update routes/unix.php to FQCN arrays

Replace `Unix Theme v2/pterodactyl/routes/unix.php`:

```php
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
    Route::get('/unix/index', [UnixController::class, 'index'])->name('admin.unix.index');
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
```

#### Step 8: Strip config/unix.php to theme-only settings

Replace `Unix Theme v2/pterodactyl/config/unix.php`:

```php
<?php

return [
    'name' => 'Unix',
    'author' => 'LocalHost',
    'version' => '2.2.0',
    'bg' => env('UNIX_BACKGROUND', ''),
    'logo' => env('UNIX_LOGO', ''),
    'favicon' => env('UNIX_FAVICON', ''),
];
```

---

### Task 2: Unix Theme — Frontend Rewrite

**Files:**
- Modify: `Unix Theme v2/pterodactyl/resources/views/templates/wrapper.blade.php`
- Modify: `Unix Theme v2/pterodactyl/resources/views/templates/base/core.blade.php`
- Modify: `Unix Theme v2/pterodactyl/resources/views/templates/auth/core.blade.php`
- Modify: `Unix Theme v2/pterodactyl/resources/views/layouts/admin.blade.php`
- Modify: `Unix Theme v2/pterodactyl/resources/scripts/components/dashboard/ServerRow.tsx`
- Delete: `Unix Theme v2/pterodactyl/resources/scripts/routers/ServerRouter.tsx`
- Delete: `Unix Theme v2/pterodactyl/resources/scripts/components/DashboardContainer.tsx`
- Delete: `Unix Theme v2/pterodactyl/resources/scripts/components/dashboard/DashboardContainer.tsx`
- Create: `Unix Theme v2/pterodactyl/resources/views/partials/unix/sidebar.blade.php`
- Create: `Unix Theme v2/pterodactyl/resources/views/partials/unix/login-theme.blade.php`
- Create: `Unix Theme v2/pterodactyl/resources/views/partials/unix/head-extras.blade.php`

#### Step 1: Delete removed files

```bash
rm "Unix Theme v2/pterodactyl/resources/scripts/routers/ServerRouter.tsx"
rm "Unix Theme v2/pterodactyl/resources/scripts/components/DashboardContainer.tsx"
rm "Unix Theme v2/pterodactyl/resources/scripts/components/dashboard/DashboardContainer.tsx"
```

#### Step 2: Create partials/unix/sidebar.blade.php

Write `Unix Theme v2/pterodactyl/resources/views/partials/unix/sidebar.blade.php`:

```blade
<div class="container unix-sidebar">
    <div class="sidebar">
        <span class="logo">
            <img onclick="window.location.href='/account'" style="border-radius: 1.2rem;" src="https://www.gravatar.com/avatar/{{ md5(strtolower(Auth::user()->email)) }}?s=160">
        </span>
        <a class="logo-expand" href="/" style="display: flex; align-items: center; justify-content: center;">
            @isset($setting_data['enablebrandlogo'])@if($setting_data['enablebrandlogo'] == 1) @else
            <img onclick="window.location.href='/auth/login'" src="@isset($setting_data['brand-logo']){{$setting_data['brand-logo']}}@else /assets/svgs/pterodactyl.svg @endisset" style="width: 42px; padding: 4px;"> @endif @endisset
            {{ config('app.name', 'Pterodactyl') }}
        </a>
        <div class="side-wrapper">
            <div class="side-title">MENU</div>
            <div class="side-menu">
                <a class="sidebar-link discover is-active" href="/">
                    <svg viewBox="0 0 24 24" fill="currentColor">
                        <path d="M9.135 20.773v-3.057c0-.78.637-1.414 1.423-1.414h2.875c.377 0 .74.15 1.006.414.267.265.417.625.417 1v3.057c-.002.325.126.637.356.867.23.23.544.36.87.36h1.962a3.46 3.46 0 002.443-1 3.41 3.41 0 001.013-2.422V9.867c0-.735-.328-1.431-.895-1.902l-6.671-5.29a3.097 3.097 0 00-3.949.072L3.467 7.965A2.474 2.474 0 002.5 9.867v8.702C2.5 20.464 4.047 22 5.956 22h1.916c.68 0 1.231-.544 1.236-1.218l.027-.009z" />
                    </svg> {{ config('unixlang.servers', 'Servers') }}
                </a>
            </div>
        </div>
    </div>
</div>
```

#### Step 3: Create partials/unix/login-theme.blade.php

Write `Unix Theme v2/pterodactyl/resources/views/partials/unix/login-theme.blade.php`:

```blade
<link rel="stylesheet" href="/themes/unix/css/login/core.css">
```

#### Step 4: Create partials/unix/head-extras.blade.php

Write `Unix Theme v2/pterodactyl/resources/views/partials/unix/head-extras.blade.php`:

```blade
<link media="all" type="text/css" rel="stylesheet" href="/themes/unix/css/core.css"/>
<link media="all" type="text/css" rel="stylesheet" href="/themes/unix/css/alerts.css"/>
<link media="all" type="text/css" rel="stylesheet" href="/themes/unix/css/interchanging.css"/>
<script src="/themes/unix/js/buttons.js"></script>
<meta property="og:title" content="@isset($setting_data['metatitle']){{$setting_data['metatitle']}}@else {{ config('app.name', 'Pterodactyl') }} @endisset">
<meta property="og:type" content="website">
<meta property="og:url" content="/">
<meta property="og:image" content="@isset($setting_data['metaimg']){{$setting_data['metaimg']}}@else https://cdn.resourcemc.net/zAsa7/rIBOyeRU58.png/raw @endisset">
<meta property="og:description" content="@isset($setting_data['metadesc']){{$setting_data['metadesc']}}@else Manage your server with an easy-to-use Panel @endisset">
<link rel="shortcut icon" href="@isset($setting_data['unixfavicon']){{$setting_data['unixfavicon']}}@else https://cdn.resourcemc.net/zAsa7/rIBOyeRU58.png/raw @endisset">
```

#### Step 5: Rewrite wrapper.blade.php (panel v1.12.2 base + theme stacks)

Replace `Unix Theme v2/pterodactyl/resources/views/templates/wrapper.blade.php`:

```blade
<!DOCTYPE html>
<html>
    <head>
        <title>{{ config('app.name', 'Pterodactyl') }}</title>

        @section('meta')
            <meta charset="utf-8">
            <meta http-equiv="X-UA-Compatible" content="IE=edge">
            <meta content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no" name="viewport">
            <meta name="csrf-token" content="{{ csrf_token() }}">
            <meta name="robots" content="noindex">
            <link rel="apple-touch-icon" sizes="180x180" href="/favicons/apple-touch-icon.png">
            <link rel="icon" type="image/png" href="/favicons/favicon-32x32.png" sizes="32x32">
            <link rel="icon" type="image/png" href="/favicons/favicon-16x16.png" sizes="16x16">
            <link rel="manifest" href="/favicons/manifest.json">
            <link rel="mask-icon" href="/favicons/safari-pinned-tab.svg" color="#bc6e3c">
            <link rel="shortcut icon" href="/favicons/favicon.ico">
            <meta name="msapplication-config" content="/favicons/browserconfig.xml">
            <meta name="theme-color" content="#0e4688">
        @show

        @section('user-data')
            @if(!is_null(Auth::user()))
                <script>
                    window.PterodactylUser = {!! json_encode(Auth::user()->toVueObject()) !!};
                </script>
            @endif
            @if(!empty($siteConfiguration))
                <script>
                    window.SiteConfiguration = {!! json_encode($siteConfiguration) !!};
                </script>
            @endif
        @show

        @stack('unix-head')

        @yield('assets')

        @include('layouts.scripts')
    </head>
    <body class="{{ $css['body'] ?? 'bg-neutral-50' }}" style="background: var(--theme-bg);">
        @section('content')
            @yield('above-container')
            @yield('container')
            @yield('below-container')
        @show
        @section('scripts')
            {!! $asset->js('main.js') !!}
        @show
        @stack('unix-body')
    </body>
</html>
```

#### Step 6: Rewrite base/core.blade.php (panel v1.12.2 + sidebar)

Replace `Unix Theme v2/pterodactyl/resources/views/templates/base/core.blade.php`:

```blade
@extends('templates/wrapper', [
    'css' => ['body' => 'bg-neutral-800'],
])

@push('unix-head')
    @include('partials.unix.head-extras')
@endpush

@push('unix-body')
    @include('partials.unix.sidebar')
@endpush

@section('container')
    <div id="modal-portal"></div>
    <div id="app"></div>
@endsection
```

#### Step 7: Rewrite auth/core.blade.php (panel v1.12.2 + login theme)

Replace `Unix Theme v2/pterodactyl/resources/views/templates/auth/core.blade.php`:

```blade
@extends('templates/wrapper', [
    'css' => ['body' => 'bg-neutral-900']
])

@push('unix-head')
    @include('partials.unix.login-theme')
@endpush

@section('container')
    <div id="app"></div>
@endsection
```

#### Step 8: Rewrite admin.blade.php (panel v1.12.2 + Unix nav entry)

Replace `Unix Theme v2/pterodactyl/resources/views/layouts/admin.blade.php`:

```blade
<!DOCTYPE html>
<html>
    <head>
        <meta charset="utf-8">
        <meta http-equiv="X-UA-Compatible" content="IE=edge">
        <title>{{ config('app.name', 'Pterodactyl') }} - @yield('title')</title>
        <meta content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no" name="viewport">
        <meta name="_token" content="{{ csrf_token() }}">

        <link rel="apple-touch-icon" sizes="180x180" href="/favicons/apple-touch-icon.png">
        <link rel="icon" type="image/png" href="/favicons/favicon-32x32.png" sizes="32x32">
        <link rel="icon" type="image/png" href="/favicons/favicon-16x16.png" sizes="16x16">
        <link rel="manifest" href="/favicons/manifest.json">
        <link rel="mask-icon" href="/favicons/safari-pinned-tab.svg" color="#bc6e3c">
        <link rel="shortcut icon" href="/favicons/favicon.ico">
        <meta name="msapplication-config" content="/favicons/browserconfig.xml">
        <meta name="theme-color" content="#0e4688">

        @include('layouts.scripts')

        @section('scripts')
            {!! Theme::css('vendor/select2/select2.min.css?t={cache-version}') !!}
            {!! Theme::css('vendor/bootstrap/bootstrap.min.css?t={cache-version}') !!}
            {!! Theme::css('vendor/adminlte/admin.min.css?t={cache-version}') !!}
            {!! Theme::css('vendor/adminlte/colors/skin-blue.min.css?t={cache-version}') !!}
            {!! Theme::css('vendor/sweetalert/sweetalert.min.css?t={cache-version}') !!}
            {!! Theme::css('vendor/animate/animate.min.css?t={cache-version}') !!}
            {!! Theme::css('css/pterodactyl.css?t={cache-version}') !!}
            <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/4.7.0/css/font-awesome.min.css">
            <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/ionicons/2.0.1/css/ionicons.min.css">

            <!--[if lt IE 9]>
            <script src="https://oss.maxcdn.com/html5shiv/3.7.3/html5shiv.min.js"></script>
            <script src="https://oss.maxcdn.com/respond/1.4.2/respond.min.js"></script>
            <![endif]-->
        @show
    </head>
    <body class="hold-transition skin-blue fixed sidebar-mini">
        <div class="wrapper">
            <header class="main-header">
                <a href="{{ route('index') }}" class="logo">
                    <span>{{ config('app.name', 'Pterodactyl') }}</span>
                </a>
                <nav class="navbar navbar-static-top">
                    <a href="#" class="sidebar-toggle" data-toggle="push-menu" role="button">
                        <span class="sr-only">Toggle navigation</span>
                        <span class="icon-bar"></span>
                        <span class="icon-bar"></span>
                        <span class="icon-bar"></span>
                    </a>
                    <div class="navbar-custom-menu">
                        <ul class="nav navbar-nav">
                            <li class="user-menu">
                                <a href="{{ route('account') }}">
                                    <img src="https://www.gravatar.com/avatar/{{ md5(strtolower(Auth::user()->email)) }}?s=160" class="user-image" alt="User Image">
                                    <span class="hidden-xs">{{ Auth::user()->name_first }} {{ Auth::user()->name_last }}</span>
                                </a>
                            </li>
                            <li>
                                <li><a href="{{ route('index') }}" data-toggle="tooltip" data-placement="bottom" title="Exit Admin Control"><i class="fa fa-server"></i></a></li>
                            </li>
                            <li>
                                <li><a href="{{ route('auth.logout') }}" id="logoutButton" data-toggle="tooltip" data-placement="bottom" title="Logout"><i class="fa fa-sign-out"></i></a></li>
                            </li>
                        </ul>
                    </div>
                </nav>
            </header>
            <aside class="main-sidebar">
                <section class="sidebar">
                    <ul class="sidebar-menu">
                        <li class="header">BASIC ADMINISTRATION</li>
                        <li class="{{ Route::currentRouteName() !== 'admin.index' ?: 'active' }}">
                            <a href="{{ route('admin.index') }}">
                                <i class="fa fa-home"></i> <span>Overview</span>
                            </a>
                        </li>
                        <li class="{{ ! starts_with(Route::currentRouteName(), 'admin.settings') ?: 'active' }}">
                            <a href="{{ route('admin.settings')}}">
                                <i class="fa fa-wrench"></i> <span>Settings</span>
                            </a>
                        </li>
                        <li class="{{ ! starts_with(Route::currentRouteName(), 'admin.api') ?: 'active' }}">
                            <a href="{{ route('admin.api.index')}}">
                                <i class="fa fa-gamepad"></i> <span>Application API</span>
                            </a>
                        </li>
                        <li class="header">MANAGEMENT</li>
                        <li class="{{ ! starts_with(Route::currentRouteName(), 'admin.databases') ?: 'active' }}">
                            <a href="{{ route('admin.databases') }}">
                                <i class="fa fa-database"></i> <span>Databases</span>
                            </a>
                        </li>
                        <li class="{{ ! starts_with(Route::currentRouteName(), 'admin.locations') ?: 'active' }}">
                            <a href="{{ route('admin.locations') }}">
                                <i class="fa fa-globe"></i> <span>Locations</span>
                            </a>
                        </li>
                        <li class="{{ ! starts_with(Route::currentRouteName(), 'admin.nodes') ?: 'active' }}">
                            <a href="{{ route('admin.nodes') }}">
                                <i class="fa fa-sitemap"></i> <span>Nodes</span>
                            </a>
                        </li>
                        <li class="{{ ! starts_with(Route::currentRouteName(), 'admin.servers') ?: 'active' }}">
                            <a href="{{ route('admin.servers') }}">
                                <i class="fa fa-server"></i> <span>Servers</span>
                            </a>
                        </li>
                        <li class="{{ ! starts_with(Route::currentRouteName(), 'admin.users') ?: 'active' }}">
                            <a href="{{ route('admin.users') }}">
                                <i class="fa fa-users"></i> <span>Users</span>
                            </a>
                        </li>
                        <li class="header">SERVICE MANAGEMENT</li>
                        <li class="{{ ! starts_with(Route::currentRouteName(), 'admin.mounts') ?: 'active' }}">
                            <a href="{{ route('admin.mounts') }}">
                                <i class="fa fa-magic"></i> <span>Mounts</span>
                            </a>
                        </li>
                        <li class="{{ ! starts_with(Route::currentRouteName(), 'admin.nests') ?: 'active' }}">
                            <a href="{{ route('admin.nests') }}">
                                <i class="fa fa-th-large"></i> <span>Nests</span>
                            </a>
                        </li>
                        <li class="{{ ! starts_with(Route::currentRouteName(), 'admin.unix') ?: 'active' }}">
                            <a href="{{ route('admin.unix') }}">
                                <i class="fa fa-paint-brush"></i> <span>Unix</span>
                            </a>
                        </li>
                    </ul>
                </section>
            </aside>
            <div class="content-wrapper">
                <section class="content-header">
                    @yield('content-header')
                </section>
                <section class="content">
                    <div class="row">
                        <div class="col-xs-12">
                            @if (count($errors) > 0)
                                <div class="alert alert-danger">
                                    There was an error validating the data provided.<br><br>
                                    <ul>
                                        @foreach ($errors->all() as $error)
                                            <li>{{ $error }}</li>
                                        @endforeach
                                    </ul>
                                </div>
                            @endif
                            @foreach (Alert::getMessages() as $type => $messages)
                                @foreach ($messages as $message)
                                    <div class="alert alert-{{ $type }} alert-dismissable" role="alert">
                                        {{ $message }}
                                    </div>
                                @endforeach
                            @endforeach
                        </div>
                    </div>
                    @yield('content')
                </section>
            </div>
            <footer class="main-footer">
                <div class="pull-right small text-gray" style="margin-right:10px;margin-top:-7px;">
                    <strong><i class="fa fa-fw {{ $appIsGit ? 'fa-git-square' : 'fa-code-fork' }}"></i></strong> {{ $appVersion }}<br />
                    <strong><i class="fa fa-fw fa-clock-o"></i></strong> {{ round(microtime(true) - LARAVEL_START, 3) }}s
                </div>
                Copyright &copy; 2015 - {{ date('Y') }} <a href="https://pterodactyl.io/">Pterodactyl Software</a>.
            </footer>
        </div>
        @section('footer-scripts')
            <script src="/js/keyboard.polyfill.js" type="application/javascript"></script>
            <script>keyboardeventKeyPolyfill.polyfill();</script>

            {!! Theme::js('vendor/jquery/jquery.min.js?t={cache-version}') !!}
            {!! Theme::js('vendor/sweetalert/sweetalert.min.js?t={cache-version}') !!}
            {!! Theme::js('vendor/bootstrap/bootstrap.min.js?t={cache-version}') !!}
            {!! Theme::js('vendor/slimscroll/jquery.slimscroll.min.js?t={cache-version}') !!}
            {!! Theme::js('vendor/adminlte/app.min.js?t={cache-version}') !!}
            {!! Theme::js('vendor/bootstrap-notify/bootstrap-notify.min.js?t={cache-version}') !!}
            {!! Theme::js('vendor/select2/select2.full.min.js?t={cache-version}') !!}
            {!! Theme::js('js/admin/functions.js?t={cache-version}') !!}
            <script src="/js/autocomplete.js" type="application/javascript"></script>

            @if(Auth::user()->root_admin)
                <script>
                    $('#logoutButton').on('click', function (event) {
                        event.preventDefault();

                        var that = this;
                        swal({
                            title: 'Do you want to log out?',
                            type: 'warning',
                            showCancelButton: true,
                            confirmButtonColor: '#d9534f',
                            cancelButtonColor: '#d33',
                            confirmButtonText: 'Log out'
                        }, function () {
                             $.ajax({
                                type: 'POST',
                                url: '{{ route('auth.logout') }}',
                                data: {
                                    _token: '{{ csrf_token() }}'
                                },complete: function () {
                                    window.location.href = '{{route('auth.login')}}';
                                }
                        });
                    });
                });
                </script>
            @endif

            <script>
                $(function () {
                    $('[data-toggle="tooltip"]').tooltip();
                })
            </script>
        @show
    </body>
</html>
```

#### Step 9: Fix ServerRow.tsx imports

In `Unix Theme v2/pterodactyl/resources/scripts/components/dashboard/ServerRow.tsx`, replace:
```
import { bytesToHuman, megabytesToHuman } from '@/helpers';
```
with:
```
import { bytesToString } from '@/lib/formatters';
```

Then replace all occurrences of `bytesToHuman(` with `bytesToString(` and remove `megabytesToHuman` usage (or alias `mbToBytes` from the same import).

---

### Task 3: Billing System — Remove deprecated PayPal SDK

**Files:**
- Delete: `billing-system-v1x-v143/PanelFiles/app/Classes/PayPal/sdk/` (entire directory)
- Delete: `billing-system-v1x-v143/PanelFiles/app/Classes/PayPal/PayPalExecution.php` (if exists)
- Modify: `billing-system-v1x-v143/PanelFiles/app/Classes/PayPal/PayPalPayment.php`
- Modify: `billing-system-v1x-v143/PanelFiles/app/Http/Controllers/Api/Client/Shop/PaymentController.php`
- Modify: `billing-system-v1x-v143/PanelEdit.txt` (composer/install instructions)

#### Step 1: Delete deprecated sdk directory

```bash
rm -rf "billing-system-v1x-v143/PanelFiles/app/Classes/PayPal/sdk/"
```

#### Step 2: Delete PayPalExecution if exists

```bash
test -f "billing-system-v1x-v143/PanelFiles/app/Classes/PayPal/PayPalExecution.php" && rm "billing-system-v1x-v143/PanelFiles/app/Classes/PayPal/PayPalExecution.php"
```

#### Step 3: Rewrite PayPalPayment.php with PayPal Checkout SDK

Replace `billing-system-v1x-v143/PanelFiles/app/Classes/PayPal/PayPalPayment.php`:

```php
<?php

namespace Pterodactyl\Classes\PayPal;

use PayPalCheckoutSdk\Core\PayPalHttpClient;
use PayPalCheckoutSdk\Core\ProductionEnvironment;
use PayPalCheckoutSdk\Core\SandboxEnvironment;
use PayPalCheckoutSdk\Orders\OrdersCreateRequest;
use PayPalCheckoutSdk\Orders\OrdersCaptureRequest;

class PayPalPayment
{
    const APPROVAL_URL_REL = 'approve';

    public static function client(string $clientId, string $clientSecret, string $mode = 'live'): PayPalHttpClient
    {
        $environment = $mode === 'live'
            ? new ProductionEnvironment($clientId, $clientSecret)
            : new SandboxEnvironment($clientId, $clientSecret);

        return new PayPalHttpClient($environment);
    }

    public static function createOrder(string $clientId, string $clientSecret, string $mode, float $amount, string $currency, string $returnUrl, string $cancelUrl): array
    {
        $client = self::client($clientId, $clientSecret, $mode);

        $request = new OrdersCreateRequest();
        $request->prefer('return=representation');
        $request->body = [
            'intent' => 'CAPTURE',
            'purchase_units' => [[
                'amount' => [
                    'currency_code' => $currency,
                    'value' => number_format($amount, 2, '.', ''),
                ],
                'description' => 'Balance Upload',
            ]],
            'application_context' => [
                'return_url' => $returnUrl,
                'cancel_url' => $cancelUrl,
            ],
        ];

        $response = $client->execute($request);

        if ($response->statusCode !== 201) {
            return ['status' => 'error', 'message' => 'Failed to create PayPal order'];
        }

        $approvalUrl = '';
        foreach ($response->result->links as $link) {
            if ($link->rel === self::APPROVAL_URL_REL) {
                $approvalUrl = $link->href;
                break;
            }
        }

        return [
            'status' => 'success',
            'orderId' => $response->result->id,
            'redirectUrl' => $approvalUrl,
        ];
    }

    public static function captureOrder(string $clientId, string $clientSecret, string $mode, string $orderId): array
    {
        $client = self::client($clientId, $clientSecret, $mode);

        $request = new OrdersCaptureRequest($orderId);
        $request->prefer('return=representation');

        $response = $client->execute($request);

        if ($response->statusCode !== 201 && $response->statusCode !== 200) {
            return ['status' => 'error', 'message' => 'Failed to capture PayPal payment'];
        }

        return [
            'status' => 'success',
            'data' => $response->result,
        ];
    }
}
```

#### Step 4: Rewrite PaymentController.php (PayPal portion + remove laravel-invoices)

Replace `billing-system-v1x-v143/PanelFiles/app/Http/Controllers/Api/Client/Shop/PaymentController.php`:

```php
<?php

namespace Pterodactyl\Http\Controllers\Api\Client\Shop;

use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Auth;
use Pterodactyl\Models\User;
use Stripe\Exception\ApiErrorException;
use Pterodactyl\Exceptions\DisplayException;
use Pterodactyl\Classes\PayPal\PayPalPayment;
use Pterodactyl\Http\Requests\Api\Client\ShopRequest;
use Pterodactyl\Http\Controllers\Api\Client\ClientApiController;
use Pterodactyl\Contracts\Repository\SettingsRepositoryInterface;

class PaymentController extends ClientApiController
{
    protected SettingsRepositoryInterface $settingsRepository;

    public function __construct(SettingsRepositoryInterface $settingsRepository)
    {
        parent::__construct();
        $this->settingsRepository = $settingsRepository;
    }

    public function getDetails(ShopRequest $request): array
    {
        $provider = $request->input('provider', '');
        $sessionId = $request->input('sessionId', '');
        $payerId = $request->input('payerId', '');

        $paymentState = '';
        $paymentMessage = '';

        if ($provider === 'paypal') {
            if (empty($sessionId) || empty($payerId)) {
                goto showView;
            }

            $existingTxn = DB::table('payments')
                ->where('payment_type', 'paypal')
                ->where('session_id', $sessionId)
                ->exists();

            if ($existingTxn) {
                goto showView;
            }

            $orderId = $sessionId;
            $capture = PayPalPayment::captureOrder(
                $this->settingsRepository->get('settings::shop::paypal::key', ''),
                $this->settingsRepository->get('settings::shop::paypal::secret', ''),
                $this->settingsRepository->get('settings::shop::paypal::mode', 'live'),
                $orderId
            );

            if ($capture['status'] !== 'success') {
                $paymentState = 'error';
                $paymentMessage = 'Failed to verify the payment. Please contact us!';
                goto showView;
            }

            $capturedAmount = (float) $capture['data']->purchase_units[0]->payments->captures[0]->amount->value;

            DB::table('payments')->insert([
                'payment_type' => 'paypal',
                'user_id' => Auth::user()->id,
                'amount' => $capturedAmount,
                'invoice_number' => '',
                'session_id' => $sessionId,
                'completed' => 1,
                'created_at' => Carbon::now(),
            ]);

            $user = User::query()->find(Auth::user()->id);
            $user->update(['credit' => $user->credit + $capturedAmount]);

            $paymentState = 'success';
            $paymentMessage = "You've successfully uploaded balance to your account.";
        }

        if ($provider === 'stripe') {
            $paymentData = DB::table('payments')
                ->where('payment_type', 'stripe')
                ->where('session_id', $sessionId)
                ->where('completed', 0)
                ->get();

            if (count($paymentData) < 1) {
                $paymentState = 'error';
                $paymentMessage = 'Payment not found.';
                goto showView;
            }

            \Stripe\Stripe::setApiKey($this->settingsRepository->get('settings::shop::stripe::secret', ''));

            try {
                $checkoutSession = \Stripe\Checkout\Session::retrieve($sessionId);
            } catch (ApiErrorException $e) {
                $paymentState = 'error';
                $paymentMessage = 'Payment not found.';
                goto showView;
            }

            try {
                $intent = \Stripe\PaymentIntent::retrieve($checkoutSession->payment_intent);
            } catch (ApiErrorException $e) {
                $paymentState = 'error';
                $paymentMessage = 'Failed to verify the payment. Please contact us!';
                goto showView;
            }

            DB::table('payments')->where('id', $paymentData[0]->id)->update(['completed' => 1]);

            $user = User::query()->find(Auth::user()->id);
            $user->update(['credit' => $user->credit + $paymentData[0]->amount]);

            $paymentState = 'success';
            $paymentMessage = "You've successfully uploaded balance to your account.";
        }

        showView:

        return [
            'success' => true,
            'data' => [
                'stripeKey' => $this->settingsRepository->get('settings::shop::stripe::key', ''),
                'enabled' => [
                    'paypal' => (int) $this->settingsRepository->get('settings::shop::paypal::enabled', 1),
                    'stripe' => (int) $this->settingsRepository->get('settings::shop::stripe::enabled', 1),
                ],
                'minAmount' => $this->settingsRepository->get('settings::shop::min_amount', 0),
                'maxAmount' => $this->settingsRepository->get('settings::shop::max_amount', 100),
                'currency' => $this->settingsRepository->get('settings::shop::currency', 'USD'),
                'paymentState' => $paymentState,
                'paymentMessage' => $paymentMessage,
                'balance' => Auth::user()->credit,
                'transactions' => DB::table('payments')
                    ->where('user_id', Auth::user()->id)
                    ->orderBy('created_at', 'DESC')
                    ->get(),
            ],
        ];
    }

    public function paypal(ShopRequest $request): array
    {
        $this->validate($request, [
            'amount' => 'required|numeric|min:' . $this->settingsRepository->get('settings::shop::min_amount', 0) . '|max:' . $this->settingsRepository->get('settings::shop::max_amount', 100),
        ]);

        $amount = $request->input('amount', 10);

        if (is_null(Auth::user()->country) || is_null(Auth::user()->address) || is_null(Auth::user()->zip_code)) {
            throw new DisplayException('Please complete your personal details before you upload balance.');
        }

        $order = PayPalPayment::createOrder(
            $this->settingsRepository->get('settings::shop::paypal::key', ''),
            $this->settingsRepository->get('settings::shop::paypal::secret', ''),
            $this->settingsRepository->get('settings::shop::paypal::mode', 'live'),
            (float) $amount,
            $this->settingsRepository->get('settings::shop::currency', 'USD'),
            route('index') . '/shop/payments/paypal/success/' . '{orderID}',
            route('index') . '/shop/payments/paypal/cancelled'
        );

        if ($order['status'] !== 'success') {
            throw new DisplayException('Failed to make the transaction. Please try again later.');
        }

        return [
            'success' => true,
            'data' => [
                'redirectUrl' => $order['redirectUrl'],
            ],
        ];
    }

    public function stripe(ShopRequest $request): array
    {
        $this->validate($request, [
            'amount' => 'required|numeric|min:' . $this->settingsRepository->get('settings::shop::min_amount', 0) . '|max:' . $this->settingsRepository->get('settings::shop::max_amount', 100),
        ]);

        $amount = $request->input('amount', 10);

        if (is_null(Auth::user()->country) || is_null(Auth::user()->address) || is_null(Auth::user()->zip_code)) {
            throw new DisplayException('Please complete your personal details before you upload balance.');
        }

        \Stripe\Stripe::setApiKey($this->settingsRepository->get('settings::shop::stripe::secret', ''));

        try {
            $product = \Stripe\Product::create([
                'name' => $amount . ' ' . $this->settingsRepository->get('settings::shop::currency', 'USD') . ' Balance',
                'description' => 'Balance Upload',
            ]);

            $price = \Stripe\Price::create([
                'product' => $product->id,
                'unit_amount' => $amount * 100,
                'currency' => $this->settingsRepository->get('settings::shop::currency', 'USD'),
            ]);

            $session = \Stripe\Checkout\Session::create([
                'payment_method_types' => ['card'],
                'line_items' => [[
                    'price' => $price->id,
                    'quantity' => 1,
                ]],
                'mode' => 'payment',
                'success_url' => route('index') . '/shop/payments/stripe/success/{CHECKOUT_SESSION_ID}',
                'cancel_url' => route('index') . '/shop/payments/stripe/cancelled',
            ]);
        } catch (ApiErrorException $e) {
            throw new DisplayException('Failed to make the payment: ' . $e->getMessage());
        }

        DB::table('payments')->insert([
            'payment_type' => 'stripe',
            'user_id' => Auth::user()->id,
            'amount' => $amount,
            'invoice_number' => '',
            'session_id' => $session['id'],
            'completed' => 0,
            'created_at' => Carbon::now(),
        ]);

        return [
            'success' => true,
            'data' => [
                'sessionId' => $session['id'],
            ],
        ];
    }
}
```

---

### Task 4: Billing System — Eloquent conversion + SuspendedBox relocation + PanelEdit update

**Files:**
- Modify: `billing-system-v1x-v143/PanelFiles/app/Http/Controllers/Api/Client/Shop/ShopController.php`
- Modify: `billing-system-v1x-v143/PanelFiles/app/Http/Controllers/Api/Client/Servers/ServerRenewController.php`
- Modify: `billing-system-v1x-v143/PanelFiles/app/Http/Controllers/Admin/Shop/SettingsController.php`
- Modify: `billing-system-v1x-v143/PanelFiles/app/Http/Controllers/Admin/Shop/CategoriesController.php`
- Modify: `billing-system-v1x-v143/PanelFiles/app/Http/Controllers/Admin/Shop/GamesController.php`
- Modify: `billing-system-v1x-v143/PanelFiles/app/Http/Controllers/Admin/Shop/PaymentsController.php`
- Modify: `billing-system-v1x-v143/PanelFiles/resources/scripts/components/elements/ScreenBlock.tsx` (addon's copy)
- Create: `billing-system-v1x-v143/PanelFiles/resources/scripts/components/dashboard/SuspendedBoxIntegration.tsx`
- Rewrite: `billing-system-v1x-v143/PanelEdit.txt`

#### Step 1: Convert DB::table() → Eloquent in ShopController.php

In `billing-system-v1x-v143/PanelFiles/app/Http/Controllers/Api/Client/Shop/ShopController.php`:

Add import at top (after existing `use Illuminate\Support\Facades\DB;`):
```php
use Pterodactyl\Models\User;
```

Replace lines 165-172:
```php
// OLD:
DB::table('servers')->where('id', '=', $newServer->id)->update([
    'product_id' => $game[0]->id,
    'expired_at' => Carbon::now()->addDays(30),
]);

DB::table('users')->where('id', '=', Auth::user()->id)->update([
    'credit' => Auth::user()->credit - $game[0]->price,
]);

// NEW:
$newServer->update([
    'product_id' => $game[0]->id,
    'expired_at' => Carbon::now()->addDays(30),
]);

User::query()->where('id', Auth::user()->id)->update([
    'credit' => Auth::user()->credit - $game[0]->price,
]);
```

Note: `DB::table('game_category')`, `DB::table('games')`, `DB::table('nodes')`, `DB::table('allocations')`, `DB::table('eggs')`, `DB::table('egg_variables')` stay as-is — these are read-only queries for custom addon tables or simple lookups. Only server/user writes are converted to Eloquent.

#### Step 2: Convert DB::table() → Eloquent in ServerRenewController.php

In `billing-system-v1x-v143/PanelFiles/app/Http/Controllers/Api/Client/Servers/ServerRenewController.php`:

Add import at top (after `use Illuminate\Support\Facades\DB;`):
```php
use Pterodactyl\Models\User;
```

Replace lines 102-108:
```php
// OLD:
DB::table('users')->where('id', '=', Auth::user()->id)->update([
    'credit' => Auth::user()->credit - $game[0]->price,
]);

DB::table('servers')->where('id', '=', $server->id)->update([
    'expired_at' => Carbon::parse($server->expired_at)->addDays(30),
]);

// NEW:
User::query()->where('id', Auth::user()->id)->update([
    'credit' => Auth::user()->credit - $game[0]->price,
]);

$server->update([
    'expired_at' => Carbon::parse($server->expired_at)->addDays(30),
]);
```

Note: `DB::table('games')` in this file stays as-is (custom addon table, no Eloquent model).

#### Step 3: Convert DB::table() → Eloquent in GamesController.php

In `billing-system-v1x-v143/PanelFiles/app/Http/Controllers/Admin/Shop/GamesController.php`:

Add imports at top:
```php
use Pterodactyl\Models\Node;
use Pterodactyl\Models\Egg;
use Pterodactyl\Models\Server;
```

Replace `DB::table('nodes')->get()` → `Node::query()->get()` (lines 83, 184)
Replace `DB::table('eggs')->get()` → `Egg::query()->get()` (lines 84, 185)
Replace `DB::table('eggs')->where('id', '=', ...)` → `Egg::query()->where('id', '=', ...)` (lines 125, 225)
Replace `DB::table('nodes')->where('id', '=', $node_id)->get()` → `Node::query()->where('id', $node_id)->get()` (lines 131, 231)
Replace `DB::table('servers')->where('product_id', '=', $game[0]->id)->get()` (line 323) → `Server::query()->where('product_id', $game[0]->id)->get()`

Note: `DB::table('game_category')` and `DB::table('games')` stay as-is (custom addon tables).

#### Step 4: Verify remaining DB::table usage

```bash
rg "DB::table" "billing-system-v1x-v143/PanelFiles/app/"
```

Only `game_category`, `games`, and `payments` table queries should remain (custom addon tables without Eloquent models). Any `servers`, `users`, `nodes`, `eggs` references must have been converted.

#### Step 5: Remove SuspendedBox from ScreenBlock

Delete the file `billing-system-v1x-v143/PanelFiles/resources/scripts/components/elements/ScreenBlock.tsx` (the addon only provides the insertion `import SuspendedBox...` and `<SuspendedBox />` at this path — the `SuspendedBox` component itself lives elsewhere).

#### Step 6: Create SuspendedBoxIntegration.tsx in dashboard

Write `billing-system-v1x-v143/PanelFiles/resources/scripts/components/dashboard/SuspendedBoxIntegration.tsx`:

```tsx
import React from 'react';
import SuspendedBox from '@/components/server/SuspendedBox';

export default () => {
    return <SuspendedBox />;
};
```

#### Step 7: Rewrite PanelEdit.txt

Rewrite `billing-system-v1x-v143/PanelEdit.txt` with updated instructions for v1.12.2. Key changes:
- Remove `composer require paypal/rest-api-sdk-php:*` and `composer require laraveldaily/laravel-invoices:^3.0`
- Add `composer require paypal/paypal-checkout-sdk`
- Remove `apt install php8.0-intl`
- Update server routes: add `Route::get('/renew', [...])->withoutMiddleware(...)` — the `AuthenticateServerAccess` middleware class must be imported
- ScreenBlock.tsx insertion replaced with DashboardContainer.tsx `SuspendedBoxIntegration` insertion
- Update `NavigationBar.tsx` Shop link to use `faShoppingCart` → verify it's in the panel's `@fortawesome/free-solid-svg-icons` imports already

Write the complete replacement `PanelEdit.txt`:

```
/routes/api-client.php
Add below: Route::delete('/api-keys/{identifier}', [Client\ApiKeyController::class, 'delete']);

Route::get('/personal', [Client\PersonalSettingsController::class, 'index']);
Route::post('/personal', [Client\PersonalSettingsController::class, 'savePersonalSettings']);

Add below: Route::post('/rename', [Client\Servers\SettingsController::class, 'rename']);

use Pterodactyl\Http\Middleware\AuthenticateServerAccess;

Route::get('/renew', [Client\Servers\ServerRenewController::class, 'index'])->withoutMiddleware([AuthenticateServerAccess::class]);
Route::post('/renew', [Client\Servers\ServerRenewController::class, 'renew'])->withoutMiddleware([AuthenticateServerAccess::class]);

Add below: Route::get('/permissions', [Client\ClientController::class, 'permissions']);

Route::group(['prefix' => '/shop'], function () {
    Route::get('/categories', [Client\Shop\ShopController::class, 'categories']);
    Route::get('/categories/{category}', [Client\Shop\ShopController::class, 'games']);
    Route::post('/order', [Client\Shop\ShopController::class, 'order']);
    Route::post('/payment', [Client\Shop\PaymentController::class, 'getDetails']);
    Route::post('/payment/paypal', [Client\Shop\PaymentController::class, 'paypal']);
    Route::post('/payment/stripe', [Client\Shop\PaymentController::class, 'stripe']);
});

/routes/admin.php
Add at bottom:

Route::group(['prefix' => 'shop'], function () {
    Route::group(['prefix' => 'settings'], function () {
        Route::get('/payments', [Admin\Shop\SettingsController::class, 'payments'])->name('admin.shop.settings.payments');
        Route::get('/servers', [Admin\Shop\SettingsController::class, 'servers'])->name('admin.shop.settings.servers');
        Route::get('/tos', [Admin\Shop\SettingsController::class, 'tos'])->name('admin.shop.settings.tos');
        Route::post('/payments', [Admin\Shop\SettingsController::class, 'savePayments']);
        Route::post('/settings', [Admin\Shop\SettingsController::class, 'saveSettings'])->name('admin.shop.settings');
        Route::post('/servers', [Admin\Shop\SettingsController::class, 'saveServerSettings']);
        Route::post('/tos', [Admin\Shop\SettingsController::class, 'saveTos']);
    });
    Route::group(['prefix' => 'payments'], function () {
        Route::get('/', [Admin\Shop\PaymentsController::class, 'index'])->name('admin.shop.payments');
    });
    Route::group(['prefix' => 'categories'], function () {
        Route::get('/', [Admin\Shop\CategoriesController::class, 'index'])->name('admin.shop.categories');
        Route::get('/games', [Admin\Shop\GamesController::class, 'index'])->name('admin.shop.categories.games.categories');
        Route::post('/create', [Admin\Shop\CategoriesController::class, 'create'])->name('admin.shop.categories.create');
        Route::delete('/delete', [Admin\Shop\CategoriesController::class, 'delete'])->name('admin.shop.categories.delete');
        Route::group(['prefix' => '{id}'], function () {
            Route::get('/edit', [Admin\Shop\CategoriesController::class, 'edit'])->name('admin.shop.categories.edit');
            Route::post('/edit', [Admin\Shop\CategoriesController::class, 'update']);
            Route::group(['prefix' => 'games'], function () {
                Route::get('/', [Admin\Shop\GamesController::class, 'games'])->name('admin.shop.categories.games');
                Route::get('/create', [Admin\Shop\GamesController::class, 'create'])->name('admin.shop.categories.games.create');
                Route::get('/{gameId}/edit', [Admin\Shop\GamesController::class, 'edit'])->name('admin.shop.categories.games.edit');
                Route::post('/create', [Admin\Shop\GamesController::class, 'store']);
                Route::post('/{gameId}/edit', [Admin\Shop\GamesController::class, 'update']);
                Route::post('/{gameId}/move', [Admin\Shop\GamesController::class, 'move'])->name('admin.shop.categories.games.move');
                Route::delete('/delete', [Admin\Shop\GamesController::class, 'delete'])->name('admin.shop.categories.games.delete');
            });
        });
    });
});

/app/Http/Requests/Admin/UserFormRequest.php
Add after 'root_admin' in the rules() return array:
'country', 'address', 'zip_code', 'credit',

/app/Models/User.php
Add to $fillable after 'root_admin':
'country', 'address', 'zip_code', 'credit',

Add to $validationRules after 'totp_secret' => 'nullable|string':
'country' => 'nullable|string',
'address' => 'nullable|string',
'zip_code' => 'nullable|string',
'credit' => 'sometimes',

/app/Services/Servers/DetailsModificationService.php
Add after 'description' => Arr::get($data, 'description') ?? '':
'expired_at' => Arr::get($data, 'expired_at') ?? null,

/app/Http/Controllers/Admin/ServersController.php
Add 'expired_at' to the setDetails forceFill array (after 'description')

/app/Console/Kernel.php
After $schedule->command(CleanServiceBackupFilesCommand::class)->daily():
$schedule->command(\Pterodactyl\Console\Commands\Server\DeleteExpiresServersCommand::class)->everyMinute();

/resources/views/layouts/admin.blade.php
Above <li class="header">SERVICE MANAGEMENT</li>:

<li class="header">SHOP MANAGEMENT</li>
<li class="{{ ! starts_with(Route::currentRouteName(), 'admin.shop.settings') ?: 'active' }}">
    <a href="{{ route('admin.shop.settings.payments') }}">
        <i class="fa fa-cog"></i> <span>Settings</span>
    </a>
</li>
<li class="{{ ! starts_with(Route::currentRouteName(), 'admin.shop.categories') || starts_with(Route::currentRouteName(), 'admin.shop.categories.games') ?: 'active' }}">
    <a href="{{ route('admin.shop.categories') }}">
        <i class="fa fa-list"></i> <span>Categories</span>
    </a>
</li>
<li class="{{ ! starts_with(Route::currentRouteName(), 'admin.shop.categories.games') ?: 'active' }}">
    <a href="{{ route('admin.shop.categories.games.categories') }}">
        <i class="fa fa-play"></i> <span>Games</span>
    </a>
</li>
<li class="{{ ! starts_with(Route::currentRouteName(), 'admin.shop.payments') ?: 'active' }}">
    <a href="{{ route('admin.shop.payments') }}">
        <i class="fa fa-money"></i> <span>Payments</span>
    </a>
</li>

/resources/scripts/routers/routes.ts
Add import after ServerActivityLogContainer:
import PersonalSettingsContainer from '@/components/dashboard/PersonalSettingsContainer';

Add to 'server' array:
{
    path: '/personal',
    name: 'Personal Settings',
    component: PersonalSettingsContainer,
},

/resources/scripts/components/App.tsx
Add after AuthenticationRouter lazy import:
const ShopRouter = lazy(() => import(/* webpackChunkName: "shop" */ '@/routers/ShopRouter'));

Add above <AuthenticatedRoute path={'/'}>:
<AuthenticatedRoute path={'/shop'}>
    <Spinner.Suspense>
        <ShopRouter />
    </Spinner.Suspense>
</AuthenticatedRoute>

/resources/scripts/components/dashboard/DashboardContainer.tsx
Add import:
import SuspendedBox from '@/components/server/settings/SuspendedBox';

Add <SuspendedBox /> inside the main render, before the server list section.

/resources/scripts/components/NavigationBar.tsx
Add faShoppingCart to the FontAwesome icons import.

Add above {rootAdmin && (:
<Tooltip placement={'bottom'} content={'Shop'}>
    <NavLink to={'/shop'}>
        <FontAwesomeIcon icon={faShoppingCart} />
    </NavLink>
</Tooltip>

After all files are copied to /var/www/pterodactyl/:
- composer require stripe/stripe-php
- composer require paypal/paypal-checkout-sdk
- yarn install
- yarn add @stripe/stripe-js
- yarn run build:production
- php artisan migrate
- php artisan optimize
```

---

### Task 5: Player List & Counter — Update install target paths

**File:** `Player List & Counter 1.0/PanelEdit.txt`

#### Step 1: Update ServerConsole.tsx target

Replace all references to `ServerConsole.tsx` with the correct v1.12.2 path:

```
/resources/scripts/components/server/ServerConsole.tsx
→ /resources/scripts/components/server/console/ServerConsoleContainer.tsx
```

Update import insertion:
```
import PowerControls from '@/components/server/PowerControls';
→ import PowerButtons from '@/components/server/console/PowerButtons';

import PlayerCounter from '@/components/server/PlayerCounter';
→ import PlayerCounter from '@/components/server/PlayerCounter';
```

Update JSX insertion point:
```
above the <Can action={[ 'control.start', 'control.stop', 'control.restart' ]} matchAny> line
→ above the <Can action={[...]} matchAny> line (line 43 in ServerConsoleContainer.tsx)
```

#### Step 2: Update route syntax

Replace:
```php
Route::get('/', 'PlayerCounterController@index')->name('admin.players');
Route::post('/create', 'PlayerCounterController@create')->name('admin.players.create');
Route::post('/update', 'PlayerCounterController@update')->name('admin.players.update');
Route::delete('/delete', 'PlayerCounterController@delete')->name('admin.players.delete');
```

With:
```php
use Pterodactyl\Http\Controllers\Admin\PlayerCounterController;

Route::get('/', [PlayerCounterController::class, 'index'])->name('admin.players');
Route::post('/create', [PlayerCounterController::class, 'create'])->name('admin.players.create');
Route::post('/update', [PlayerCounterController::class, 'update'])->name('admin.players.update');
Route::delete('/delete', [PlayerCounterController::class, 'delete'])->name('admin.players.delete');
```

#### Step 3: Update api-client route

Replace:
```php
Route::get('/players', 'Servers\PlayersController@index');
```
With:
```php
use Pterodactyl\Http\Controllers\Api\Client\Servers\PlayersController;

Route::get('/players', [PlayersController::class, 'index']);
```

---

### Task 6: Custom Server Sort — Complete Rewrite

**Files:**
- Delete: `custom-server-sort-v103/customserversort.blueprint`
- Delete: `custom-server-sort-v103/customserversort.html`
- Create: `custom-server-sort-v103/customserversort.js`
- Create: `custom-server-sort-v103/PanelEdit.txt`

#### Step 1: Delete old files

```bash
rm "custom-server-sort-v103/customserversort.blueprint"
rm "custom-server-sort-v103/customserversort.html"
```

#### Step 2: Create customserversort.js

Write `custom-server-sort-v103/customserversort.js`:

```javascript
(() => {
  if (!window.Sortable) {
    const s = document.createElement('script');
    s.src = 'https://cdn.jsdelivr.net/npm/sortablejs@latest/Sortable.min.js';
    s.onload = init;
    document.head.appendChild(s);
  } else {
    init();
  }

  function init() {
    let sortable = null;

    const storageKey = () => {
      const userId = window.PterodactylUser ? window.PterodactylUser.uuid : 'anon';
      return 'server_order_' + userId;
    };

    const load = () => {
      const stored = localStorage.getItem(storageKey());
      if (!stored || !sortable) return;
      sortable.sort(stored.split('|'));
    };

    const save = () => {
      if (!sortable) return;
      localStorage.setItem(
        storageKey(),
        sortable.toArray().filter(id => id.startsWith('/server/')).join('|')
      );
    };

    const findServerList = () => {
      const links = document.querySelectorAll('a[href^="/server/"]');
      if (links.length === 0) return null;

      for (const link of links) {
        let parent = link.parentElement;
        let depth = 0;
        while (parent && depth < 10) {
          const children = Array.from(parent.children).filter(c =>
            c.querySelector('a[href^="/server/"]')
          );
          if (children.length > 1) return parent;
          parent = parent.parentElement;
          depth++;
        }
      }
      return links[links.length - 1]?.parentElement;
    };

    const attachSortable = () => {
      const container = findServerList();
      if (!container || sortable) return;

      sortable = Sortable.create(container, {
        animation: 150,
        delay: ('ontouchstart' in window || navigator.maxTouchPoints > 0) ? 100 : 0,
        handle: 'a',
        dataIdAttr: 'href',
        filter: 'div[class*="Spinner"], div[class*="Skeleton"]',
        onEnd: () => save(),
      });

      load();
    };

    const observer = new MutationObserver(() => {
      if (window.location.pathname === '/' || window.location.pathname === '') {
        attachSortable();
      }
    });

    observer.observe(document.getElementById('app') || document.body, {
      childList: true,
      subtree: true,
    });

    attachSortable();
  }
})();
```

#### Step 3: Create PanelEdit.txt

Write `custom-server-sort-v103/PanelEdit.txt`:

```
### Custom Server Sort 1.0.3 — Updated for Pterodactyl Panel v1.12.2

1. Copy customserversort.js to the panel:
   cp customserversort.js /var/www/pterodactyl/public/themes/pterodactyl/js/customserversort.js

2. Add script tag to wrapper.blade.php:
   Open /var/www/pterodactyl/resources/views/templates/wrapper.blade.php
   Add this line after {!! $asset->js('main.js') !!}:

   <script src="/themes/pterodactyl/js/customserversort.js"></script>

3. Rebuild frontend:
   cd /var/www/pterodactyl
   yarn run build:production

4. Clear cache:
   php artisan view:clear && php artisan cache:clear
```

---

### Final Task: Unix Theme PanelEdit/README

**File:** Modify/rewrite `Unix Theme v2/README.txt` into `Unix Theme v2/PanelEdit.txt`

Write `Unix Theme v2/PanelEdit.txt`:

```
### Unix Theme v2.2.0 — Updated for Pterodactyl Panel v1.12.2

### INSTALLATION

#### Step 1: Copy theme files
Copy the contents of the 'pterodactyl/' folder into your Pterodactyl panel root
(/var/www/pterodactyl/), merging all directories.

#### Step 2: Register the theme service provider
Open bootstrap/app.php and add:
    ->withProviders([
        Pterodactyl\Providers\UnixThemeServiceProvider::class,
    ])
...or add to config/app.php providers array:
    Pterodactyl\Providers\UnixThemeServiceProvider::class,

#### Step 3: Register the admin middleware alias (if not present)
Open app/Http/Kernel.php and ensure 'admin' alias maps to:
    'admin' => \Pterodactyl\Http\Middleware\AdminAuthenticate::class,

#### Step 4: Run migrations
    php artisan migrate

#### Step 5: Build frontend
    yarn install
    yarn run build:production

#### Step 6: Clear caches
    php artisan route:clear && php artisan config:clear && php artisan view:clear && php artisan cache:clear

### IMPORTANT NOTES
- This theme REQUIRES panel v1.12.0+. Not compatible with older versions.
- The theme no longer overwrites RouteServiceProvider — routes are registered via UnixThemeServiceProvider.
- Theme settings are shared to views via ViewComposer, not per-controller.
- FontAwesome Pro classes have been replaced with FontAwesome Free 4/5 icons.
```
