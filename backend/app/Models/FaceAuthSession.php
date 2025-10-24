<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class FaceAuthSession extends Model
{
    use HasFactory, HasUuids;

    protected $table = 'face_auth_sessions';

    protected $fillable = [
        'user_id',
        'enrollment_id',
        'authenticated_at',
        'expires_at',
        'is_authenticated',
        'confidence_score',
        'method',
    ];

    protected $casts = [
        'authenticated_at' => 'datetime',
        'expires_at' => 'datetime',
        'is_authenticated' => 'boolean',
        'confidence_score' => 'float',
    ];

    public $incrementing = false;
    protected $keyType = 'string';
    public $timestamps = true;
}
