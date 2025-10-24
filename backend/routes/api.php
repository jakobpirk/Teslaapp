<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\ChargingSessionController;
use App\Http\Controllers\Api\FaceAuthController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
*/

Route::prefix('v1')->group(function () {

    // Health check
    Route::get('/health', function () {
        return response()->json([
            'status' => 'ok',
            'timestamp' => now()->toIso8601String(),
        ]);
    });

    // Charging Sessions Routes
    Route::prefix('charging-sessions')->group(function () {
        Route::get('/', [ChargingSessionController::class, 'index']);
        Route::post('/', [ChargingSessionController::class, 'store']);
        Route::get('/{id}', [ChargingSessionController::class, 'show']);
        Route::put('/{id}', [ChargingSessionController::class, 'update']);
        Route::delete('/{id}', [ChargingSessionController::class, 'destroy']);
        Route::get('/vehicle/{vehicleId}', [ChargingSessionController::class, 'getByVehicle']);
        Route::get('/vehicle/{vehicleId}/recent', [ChargingSessionController::class, 'getMostRecent']);
        Route::get('/vehicle/{vehicleId}/date-range', [ChargingSessionController::class, 'getByDateRange']);
    });

    // Face Authentication Routes
    Route::prefix('face-auth')->group(function () {
        Route::post('/enrollments', [FaceAuthController::class, 'registerEnrollment']);
        Route::get('/enrollments/{userId}', [FaceAuthController::class, 'getEnrollment']);
        Route::delete('/enrollments/{userId}', [FaceAuthController::class, 'deleteEnrollment']);
        Route::post('/verify', [FaceAuthController::class, 'verifyAuthentication']);
        Route::post('/sessions/verify', [FaceAuthController::class, 'verifySessionToken']);
        Route::post('/sessions/invalidate', [FaceAuthController::class, 'invalidateSession']);
    });
});
