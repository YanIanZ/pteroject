<?php

namespace Pterodactyl\Http\ViewComposers;

use Illuminate\View\View;
use Illuminate\Support\Facades\Schema;
use Pterodactyl\Models\UnixSetting;

class UnixThemeComposer
{
    public function compose(View $view): void
    {
        $data = [];

        if (!class_exists(UnixSetting::class)) {
            $view->with('setting_data', $data);
            return;
        }

        try {
            if (Schema::hasTable('unix_settings')) {
                foreach (UnixSetting::all() as $setting) {
                    $data[$setting->name] = $setting->value;
                }
            }
        } catch (\Throwable) {
        }

        $view->with('setting_data', $data);
    }
}
