<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            // Automatic charging feature toggle
            $table->boolean('auto_charging_enabled')->default(false)->after('pricing_region');

            // Low battery threshold settings
            $table->boolean('low_battery_protection_enabled')->default(false)->after('auto_charging_enabled');
            $table->integer('low_battery_threshold')->nullable()->after('low_battery_protection_enabled')
                ->comment('Battery percentage at which emergency charging starts');
            $table->integer('low_battery_stop_limit')->nullable()->after('low_battery_threshold')
                ->comment('Battery percentage at which emergency charging stops');

            // Add indices
            $table->index('auto_charging_enabled');
            $table->index('low_battery_protection_enabled');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropIndex(['auto_charging_enabled']);
            $table->dropIndex(['low_battery_protection_enabled']);

            $table->dropColumn([
                'auto_charging_enabled',
                'low_battery_protection_enabled',
                'low_battery_threshold',
                'low_battery_stop_limit',
            ]);
        });
    }
};
