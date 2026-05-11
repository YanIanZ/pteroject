@extends('templates/wrapper', [
    'css' => ['body' => 'bg-neutral-900']
])

@push('unix-head')
    @include('partials.unix.login-theme')
@endpush

@section('container')
    <div id="app"></div>
@endsection
