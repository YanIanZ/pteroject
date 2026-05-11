<?php

namespace Pterodactyl\Models;

use Illuminate\Database\Eloquent\Model;

class UnixSetting extends Model
{
    protected string $table = 'unix_settings';

    protected array $fillable = ['name', 'value'];
}