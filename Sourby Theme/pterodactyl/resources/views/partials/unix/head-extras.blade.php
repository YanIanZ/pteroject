<link media="all" type="text/css" rel="stylesheet" href="/themes/unix/css/core.css"/>
<link media="all" type="text/css" rel="stylesheet" href="/themes/unix/css/alerts.css"/>
<link media="all" type="text/css" rel="stylesheet" href="/themes/unix/css/interchanging.css"/>
<script src="/themes/unix/js/buttons.js"></script>
<meta property="og:title" content="@isset($setting_data['metatitle']){{ $setting_data['metatitle'] }}@else {{ config('app.name', 'Pterodactyl') }} @endisset">
<meta property="og:type" content="website">
<meta property="og:url" content="/">
<meta property="og:image" content="@isset($setting_data['metaimg']){{ $setting_data['metaimg'] }}@else https://cdn.resourcemc.net/zAsa7/rIBOyeRU58.png/raw @endisset">
<meta property="og:description" content="@isset($setting_data['metadesc']){{ $setting_data['metadesc'] }}@else Manage your server with an easy-to-use Panel @endisset">
<link rel="shortcut icon" href="@isset($setting_data['unixfavicon']){{ $setting_data['unixfavicon'] }}@else https://cdn.resourcemc.net/zAsa7/rIBOyeRU58.png/raw @endisset">
