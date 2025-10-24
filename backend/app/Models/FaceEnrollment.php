<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class FaceEnrollment extends Model
{
    use HasFactory, HasUuids;

    protected $table = 'face_enrollments';

    protected $fillable = [
        'user_id',
        'enrolled_at',
        'is_active',
        'device_id',
        'biometric_type',
    ];

    protected $casts = [
        'enrolled_at' => 'datetime',
        'is_active' => 'boolean',
    ];

    public $incrementing = false;
    protected $keyType = 'string';
    public $timestamps = true;
}
