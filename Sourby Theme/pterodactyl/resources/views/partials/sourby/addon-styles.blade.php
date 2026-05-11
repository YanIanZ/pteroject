{{-- Sourby Addon Integration Styles --}}
@if(config('sourby_billing_enabled', true))
    <link rel="stylesheet" href="/themes/sourby/css/addons/billing.css">
@endif

@if(config('sourby_player_list_enabled', true))
    <link rel="stylesheet" href="/themes/sourby/css/addons/player-list.css">
@endif

@if(config('sourby_custom_sort_enabled', true))
    <link rel="stylesheet" href="/themes/sourby/css/addons/custom-sort.css">
@endif
