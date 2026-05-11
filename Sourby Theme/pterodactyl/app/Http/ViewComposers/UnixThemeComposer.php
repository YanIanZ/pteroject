<?php

namespace Pterodactyl\Http\ViewComposers;

use Illuminate\View\View;
use Pterodactyl\Models\UnixSetting;

class UnixThemeComposer
{
    public function compose(View $view): void
    {
        if (!class_exists(UnixSetting::class)) {
            return;
        }

        $data = [];
        try {
            foreach (UnixSetting::all() as $setting) {
                $data[$setting->name] = $setting->value;
            }
        } catch (\Exception) {
        }

        $view->with('setting_data', $data);
    }
}
