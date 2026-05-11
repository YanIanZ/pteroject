<?php

namespace Pterodactyl\Http\Controllers\Admin;

use Illuminate\View\View;
use Pterodactyl\Http\Controllers\Controller;
use Pterodactyl\Services\Helpers\SoftwareVersionService;

class BaseController extends Controller
{
    public function __construct(private readonly SoftwareVersionService $version) {}

    public function index(): View
    {
        return view('admin.index', ['version' => $this->version]);
    }
}
