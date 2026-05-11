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
