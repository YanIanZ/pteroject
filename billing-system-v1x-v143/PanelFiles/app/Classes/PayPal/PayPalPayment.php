<?php
/**
 * Sourby Billing System - PayPal Integration
 * Handles PayPal Checkout SDK for payment processing
 */

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
