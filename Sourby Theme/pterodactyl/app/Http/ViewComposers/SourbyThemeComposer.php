<?php

namespace Pterodactyl\Http\ViewComposers;

use Illuminate\View\View;
use Pterodactyl\Models\SourbySetting;

class SourbyThemeComposer
{
    public function compose(View $view): void
    {
        if (!class_exists(SourbySetting::class)) {
            return;
        }

        $data = [];
        try {
            foreach (SourbySetting::all() as $setting) {
                $data[$setting->name] = $setting->value;
            }
        } catch (\Exception) {
        }

        $view->with('sourby_settings', $data);
    }
}
