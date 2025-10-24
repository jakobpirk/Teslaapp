<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\ChargingSessionController;
use App\Http\Controllers\Api\FaceAuthController;
use App\Http\Controllers\Api\PricingHistoryController;
use App\Http\Controllers\Api\ChargingRecommendationController;

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

    // Authentication Routes (Public)
    Route::prefix('auth')->group(function () {
        Route::post('/register', [AuthController::class, 'register']);
        Route::post('/login', [AuthController::class, 'login']);
        Route::post('/forgot-password', [AuthController::class, 'forgotPassword']);
        Route::post('/verify-reset-code', [AuthController::class, 'verifyResetCode']);
        Route::post('/reset-password', [AuthController::class, 'resetPassword']);
    });

    // Protected Authentication Routes
    Route::middleware('auth:sanctum')->group(function () {
        Route::post('/auth/logout', [AuthController::class, 'logout']);
        Route::get('/auth/me', [AuthController::class, 'me']);
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

    // Pricing History Routes
    Route::prefix('pricing')->group(function () {
        Route::get('/', [PricingHistoryController::class, 'index']);
        Route::get('/current', [PricingHistoryController::class, 'current']);
        Route::get('/today-tomorrow', [PricingHistoryController::class, 'todayAndTomorrow']);
        Route::get('/average', [PricingHistoryController::class, 'average']);
    });

    // Charging Recommendation Routes
    Route::prefix('charging-recommendations')->group(function () {
        Route::post('/vehicle/{vehicleId}/generate', [ChargingRecommendationController::class, 'generate']);
        Route::get('/vehicle/{vehicleId}/latest', [ChargingRecommendationController::class, 'latest']);
        Route::get('/vehicle/{vehicleId}', [ChargingRecommendationController::class, 'index']);
        Route::get('/{id}', [ChargingRecommendationController::class, 'show']);
        Route::post('/{id}/executed', [ChargingRecommendationController::class, 'markExecuted']);
        Route::patch('/{id}/status', [ChargingRecommendationController::class, 'updateStatus']);
    });
});
