<?php

namespace Pterodactyl\Http\ViewComposers;

use Illuminate\View\View;
use Illuminate\Support\Facades\Schema;
use Pterodactyl\Models\SourbySetting;

class SourbyThemeComposer
{
    public function compose(View $view): void
    {
        $data = [];

        if (!class_exists(SourbySetting::class)) {
            $view->with('sourby_settings', $data);
            return;
        }

        try {
            if (Schema::hasTable('sourby_settings')) {
                foreach (SourbySetting::all() as $setting) {
                    $data[$setting->name] = $setting->value;
                }
            }
        } catch (\Throwable) {
            // DB unavailable or schema check failed — degrade gracefully
        }

        $view->with('sourby_settings', $data);
    }
}
