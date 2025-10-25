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
        Schema::create('carbon_intensity_data', function (Blueprint $table) {
            $table->uuid('id')->primary();

            // Location/zone
            $table->string('zone')->index()->comment('Grid zone (DK1, DK2 for Denmark)');
            $table->string('country_code')->default('DK')->comment('ISO country code');

            // Timestamp
            $table->timestamp('timestamp')->index()->comment('Timestamp for this data point');

            // Carbon intensity
            $table->decimal('co2_per_kwh', 8, 2)->comment('CO2 emissions in grams per kWh');
            $table->decimal('co2_intensity', 8, 2)->nullable()->comment('Carbon intensity index');

            // Energy mix (percentages)
            $table->decimal('renewable_percentage', 5, 2)->nullable()->comment('% from renewables');
            $table->decimal('fossil_percentage', 5, 2)->nullable()->comment('% from fossil fuels');

            // Generation breakdown (if available)
            $table->decimal('wind_percentage', 5, 2)->nullable();
            $table->decimal('solar_percentage', 5, 2)->nullable();
            $table->decimal('hydro_percentage', 5, 2)->nullable();
            $table->decimal('nuclear_percentage', 5, 2)->nullable();
            $table->decimal('coal_percentage', 5, 2)->nullable();
            $table->decimal('gas_percentage', 5, 2)->nullable();

            // Data classification
            $table->boolean('is_forecast')->default(false)->comment('Is this forecasted or actual data');
            $table->decimal('forecast_confidence', 5, 2)->nullable()->comment('Confidence in forecast 0-100');

            // Metadata
            $table->timestamp('fetched_at')->useCurrent()->comment('When this data was retrieved');
            $table->string('data_source')->default('energinet')->comment('API provider');
            $table->json('raw_data')->nullable()->comment('Full API response');

            $table->timestamps();

            // Indexes
            $table->index(['zone', 'timestamp'], 'idx_zone_timestamp');
            $table->index(['timestamp', 'is_forecast'], 'idx_timestamp_forecast');
            $table->unique(['zone', 'timestamp', 'is_forecast'], 'unique_carbon_data');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('carbon_intensity_data');
    }
};
