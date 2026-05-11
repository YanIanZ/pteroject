@section('sourby::lg.background.image')
<style>
    .bg-neutral-900 {
        background-image: url('@isset($sourby_settings['login-bg-img']){{$sourby_settings['login-bg-img']}}@else https://wallpaperaccess.com/full/2002264.png @endisset') !important;
        background-size: cover;
    }
</style>

@endsection
