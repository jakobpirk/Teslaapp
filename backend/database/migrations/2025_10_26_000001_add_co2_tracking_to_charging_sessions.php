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
        Schema::table('charging_sessions', function (Blueprint $table) {
            $table->decimal('co2_emitted', 10, 2)->nullable()->after('cost')->comment('Total CO2 emissions in grams');
            $table->decimal('co2_per_kwh', 8, 2)->nullable()->after('co2_emitted')->comment('CO2 intensity in g/kWh at charging time');
            $table->decimal('renewable_percentage', 5, 2)->nullable()->after('co2_per_kwh')->comment('% of energy from renewables');
            $table->string('grid_zone', 50)->nullable()->after('renewable_percentage')->comment('Grid zone for carbon data');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('charging_sessions', function (Blueprint $table) {
            $table->dropColumn(['co2_emitted', 'co2_per_kwh', 'renewable_percentage', 'grid_zone']);
        });
    }
};
