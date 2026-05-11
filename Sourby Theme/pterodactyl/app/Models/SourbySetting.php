<?php

namespace Pterodactyl\Models;

use Illuminate\Database\Eloquent\Model;

class SourbySetting extends Model
{
    protected $table = 'sourby_settings';

    protected $fillable = ['name', 'value'];
}
