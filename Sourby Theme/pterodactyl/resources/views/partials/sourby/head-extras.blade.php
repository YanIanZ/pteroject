<link media="all" type="text/css" rel="stylesheet" href="/themes/sourby/css/core.css"/>
<link media="all" type="text/css" rel="stylesheet" href="/themes/sourby/css/alerts.css"/>
<link media="all" type="text/css" rel="stylesheet" href="/themes/sourby/css/interchanging.css"/>
<script src="/themes/sourby/js/buttons.js"></script>
<meta property="og:title" content="@isset($sourby_settings['metatitle']){{ $sourby_settings['metatitle'] }}@else {{ config('app.name', 'Pterodactyl') }} @endisset">
<meta property="og:type" content="website">
<meta property="og:url" content="/">
<meta property="og:image" content="@isset($sourby_settings['metaimg']){{ $sourby_settings['metaimg'] }}@else https://cdn.resourcemc.net/zAsa7/rIBOyeRU58.png/raw @endisset">
<meta property="og:description" content="@isset($sourby_settings['metadesc']){{ $sourby_settings['metadesc'] }}@else Manage your server with an easy-to-use Panel @endisset">
<link rel="shortcut icon" href="@isset($sourby_settings['sourbyfavicon']){{ $sourby_settings['sourbyfavicon'] }}@else https://cdn.resourcemc.net/zAsa7/rIBOyeRU58.png/raw @endisset">
