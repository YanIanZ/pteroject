<?php

namespace Pterodactyl\Models;

use Illuminate\Database\Eloquent\Model;

class UnixSetting extends Model
{
    protected $table = 'unix_settings';

    protected $fillable = ['name', 'value'];
}