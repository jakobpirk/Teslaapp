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
        Schema::create('weather_forecasts', function (Blueprint $table) {
            $table->uuid('id')->primary();

            // Location (Denmark, but storing lat/lon for flexibility)
            $table->decimal('latitude', 10, 7);
            $table->decimal('longitude', 10, 7);
            $table->string('location_name')->nullable()->comment('City/region name');

            // Forecast timestamp
            $table->timestamp('forecast_timestamp')->index()->comment('The timestamp this forecast is for');

            // Weather conditions
            $table->decimal('temp_c', 5, 2)->comment('Temperature in Celsius');
            $table->decimal('temp_f', 5, 2)->comment('Temperature in Fahrenheit');
            $table->decimal('wind_kph', 6, 2)->comment('Wind speed in km/h');
            $table->decimal('wind_mph', 6, 2)->comment('Wind speed in mph');
            $table->integer('wind_degree')->comment('Wind direction in degrees');
            $table->string('wind_dir')->comment('Wind direction compass');

            // Atmospheric conditions
            $table->integer('pressure_mb')->comment('Pressure in millibars');
            $table->integer('humidity')->comment('Humidity percentage');
            $table->integer('cloud')->comment('Cloud cover percentage 0-100');

            // Precipitation
            $table->decimal('precip_mm', 6, 2)->default(0)->comment('Precipitation in mm');
            $table->integer('chance_of_rain')->default(0)->comment('Chance of rain %');
            $table->integer('chance_of_snow')->default(0)->comment('Chance of snow %');

            // Solar/visibility
            $table->decimal('uv_index', 4, 2)->nullable()->comment('UV index');
            $table->integer('vis_km')->nullable()->comment('Visibility in km');

            // Condition
            $table->string('condition_text')->comment('Weather condition description');
            $table->string('condition_code')->comment('Weather condition code');

            // Forecast metadata
            $table->boolean('is_day')->default(true)->comment('Is daytime');
            $table->timestamp('fetched_at')->useCurrent()->comment('When this forecast was retrieved');
            $table->string('data_source')->default('weatherapi')->comment('API provider');

            // Full API response for debugging
            $table->json('raw_data')->nullable()->comment('Full API response');

            $table->timestamps();

            // Indexes
            $table->index(['latitude', 'longitude', 'forecast_timestamp'], 'idx_location_forecast');
            $table->index('forecast_timestamp');
            $table->index('fetched_at');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('weather_forecasts');
    }
};
