<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * Adds per-vehicle charging settings to allow users to configure
     * custom charging limits and preferences for each vehicle individually.
     */
    public function up(): void
    {
        Schema::table('vehicles', function (Blueprint $table) {
            // Charging limit (50-100%)
            $table->integer('charge_limit')->default(80)->after('vehicle_config')
                ->comment('Maximum charge level percentage (50-100)');

            // Automatic charging feature toggle per vehicle
            $table->boolean('auto_charging_enabled')->default(false)->after('charge_limit')
                ->comment('Enable automatic smart charging for this vehicle');

            // Low battery protection settings per vehicle
            $table->boolean('low_battery_protection_enabled')->default(false)->after('auto_charging_enabled')
                ->comment('Enable low battery protection for this vehicle');

            $table->integer('low_battery_threshold')->default(20)->after('low_battery_protection_enabled')
                ->comment('Battery percentage at which to warn or start emergency charging (5-95)');

            $table->integer('low_battery_stop_limit')->default(80)->after('low_battery_threshold')
                ->comment('Battery percentage at which to stop emergency charging (10-100)');

            // Add indices for filtering
            $table->index('auto_charging_enabled');
            $table->index('low_battery_protection_enabled');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('vehicles', function (Blueprint $table) {
            $table->dropIndex(['auto_charging_enabled']);
            $table->dropIndex(['low_battery_protection_enabled']);

            $table->dropColumn([
                'charge_limit',
                'auto_charging_enabled',
                'low_battery_protection_enabled',
                'low_battery_threshold',
                'low_battery_stop_limit',
            ]);
        });
    }
};
