@extends('layouts.admin')

@section('title')
    Sourby Shop Settings
@endsection

@section('content-header')
    <h1>
        <i class="fa fa-cog"></i> Shop Settings
    </h1>
@endsection

@section('content')
    <div class="sourby-shop-admin-section">
        <h2 class="sourby-shop-admin-title">Payment Methods Configuration</h2>

        <div class="box">
            <div class="box-header with-border">
                <h3 class="box-title">PayPal Settings</h3>
            </div>
            <form method="POST" action="{{ route('admin.sourby.settings.payments') }}">
                {{ csrf_field() }}

                <div class="box-body">
                    <div class="form-group">
                        <label for="paypal_enabled">Enable PayPal</label>
                        <select name="paypal_enabled" id="paypal_enabled" class="form-control">
                            <option value="0">Disabled</option>
                            <option value="1" selected>Enabled</option>
                        </select>
                    </div>

                    <div class="form-group">
                        <label for="paypal_mode">PayPal Mode</label>
                        <select name="paypal_mode" id="paypal_mode" class="form-control">
                            <option value="sandbox">Sandbox</option>
                            <option value="live">Live</option>
                        </select>
                        <small class="form-text text-muted">Select sandbox for testing, live for production</small>
                    </div>

                    <div class="form-group">
                        <label for="paypal_key">Client ID</label>
                        <input type="text" name="paypal_key" id="paypal_key" class="form-control" placeholder="PayPal Client ID">
                    </div>

                    <div class="form-group">
                        <label for="paypal_secret">Client Secret</label>
                        <input type="password" name="paypal_secret" id="paypal_secret" class="form-control" placeholder="PayPal Client Secret">
                    </div>
                </div>

                <div class="box-footer">
                    <button type="submit" class="btn btn-primary">Save Changes</button>
                </div>
            </form>
        </div>

        <div class="box" style="margin-top: 2rem;">
            <div class="box-header with-border">
                <h3 class="box-title">Stripe Settings</h3>
            </div>
            <form method="POST" action="{{ route('admin.sourby.settings.payments') }}">
                {{ csrf_field() }}

                <div class="box-body">
                    <div class="form-group">
                        <label for="stripe_enabled">Enable Stripe</label>
                        <select name="stripe_enabled" id="stripe_enabled" class="form-control">
                            <option value="0">Disabled</option>
                            <option value="1" selected>Enabled</option>
                        </select>
                    </div>

                    <div class="form-group">
                        <label for="stripe_key">Public Key</label>
                        <input type="text" name="stripe_key" id="stripe_key" class="form-control" placeholder="Stripe Publishable Key">
                    </div>

                    <div class="form-group">
                        <label for="stripe_secret">Secret Key</label>
                        <input type="password" name="stripe_secret" id="stripe_secret" class="form-control" placeholder="Stripe Secret Key">
                    </div>
                </div>

                <div class="box-footer">
                    <button type="submit" class="btn btn-primary">Save Changes</button>
                </div>
            </form>
        </div>
    </div>
@endsection
