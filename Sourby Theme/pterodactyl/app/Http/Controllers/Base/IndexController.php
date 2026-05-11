<?php

namespace Pterodactyl\Http\Controllers\Base;

use Illuminate\View\View;
use Illuminate\View\Factory as ViewFactory;
use Pterodactyl\Models\UnixSetting;
use Pterodactyl\Http\Controllers\Controller;
use Pterodactyl\Contracts\Repository\ServerRepositoryInterface;

class IndexController extends Controller
{
    /**
     * IndexController constructor.
     */
    public function __construct(
        protected ServerRepositoryInterface $repository,
        protected ViewFactory $view,
    ) {
    }

    /**
     * Returns listing of user's servers with Unix theme settings.
     */
    public function index(): View
    {
        $data = [];
        foreach (UnixSetting::all() as $setting) {
            $data[$setting->name] = $setting->value;
        }

        return view('templates/base.core', ['setting_data' => $data]);
    }
}
