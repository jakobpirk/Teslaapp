<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return response()->json([
        'message' => 'Tessie Backend API',
        'version' => '1.0.0',
        'docs' => '/api/v1/health'
    ]);
});
