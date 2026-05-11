@section('sourby::lg.login.header')
<header>
    <!-- MENU -->
    <link rel="shortcut icon" href="@isset($sourby_settings['sourbyfavicon']){{$sourby_settings['sourbyfavicon']}}@else https://cdn.resourcemc.net/zAsa7/rIBOyeRU58.png/raw @endisset">
    <link rel="stylesheet" href="https://pro.fontawesome.com/releases/v5.10.0/css/all.css" integrity="sha384-AYmEC3Yw5cVb3ZcuHtOA93w35dYTsvhLPVnYs9eStHfGJvOvKxVfELGroGkvsg+p" crossorigin="anonymous"/>
    <link rel="stylesheet" href="/themes/sourby/css/login/interchanging.css"/>
    <meta name="theme-color" content="@isset($sourby_settings['metacolor']){{$sourby_settings['metacolor']}}@else #0045ff @endisset">
    <meta property="og:title" content="@isset($sourby_settings['metatitle']){{$sourby_settings['metatitle']}}@else {{ config('app.name', 'Pterodactyl') }}  @endisset">
    <meta property="og:type" content="website">
    <meta property="og:url" content="/">
    <meta property="og:image" content="@isset($sourby_settings['metaimg']){{$sourby_settings['metaimg']}}@else https://cdn.resourcemc.net/zAsa7/rIBOyeRU58.png/raw @endisset">
    <meta property="og:description" content="@isset($sourby_settings['metadesc']){{$sourby_settings['metadesc']}}@else Manage your server with an easy-to-use Panel @endisset">

    @isset($sourby_settings['loginbgtype']) @if($sourby_settings['loginbgtype'] == 2)
    @yield('sourby::background.image')
    @endif @endisset

    @isset($sourby_settings['loginbgtype']) @if($sourby_settings['loginbgtype'] == 3)
    @yield('sourby::background.video')
    @endif @endisset

    <div id="{{ config('sourby.author', 'n/a') }} {{ config('sourby.version', 'unset') }}" class="menu">
      <div class="logo" style="display: flex; align-items: center;">
       @isset($sourby_settings['enablebrandlogo'])@if($sourby_settings['enablebrandlogo'] == 1)  @else
      <img class="logo-padding" onclick="window.location.href='/auth/login'" src="@isset($sourby_settings['brand-logo']){{$sourby_settings['brand-logo']}}@else /assets/svgs/pterodactyl.svg @endisset" style="width: 64px; padding: 5px; cursor: pointer;"> @endif @endisset
       <a class="logo-padding" href="/auth/login">{{ config('app.name', 'Pterodactyl') }}</a></div>
      <div class="btn"><a href="@isset($sourby_settings['mainbtnurl']){{$sourby_settings['mainbtnurl']}}@else Our Website @endisset" target="_blank" style="color:white; padding: 5px;">@isset($sourby_settings['mainbtnname']){{$sourby_settings['mainbtnname']}}@else Our Website @endisset </a></div>
    </div>
  </header>

@endsection

