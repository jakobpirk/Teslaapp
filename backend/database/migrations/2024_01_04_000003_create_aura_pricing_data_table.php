<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * This table stores the full Aura API response for each date,
     * including statistics and all chart series data.
     */
    public function up(): void
    {
        Schema::create('aura_pricing_data', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->date('date')->unique();
            $table->json('statistics'); // East/west statistics (highest, lowest, avg)
            $table->json('chart_series'); // All chart series (electricity price, transport, taxes)
            $table->decimal('min_y_axis_value', 10, 4)->nullable();
            $table->timestamps();

            $table->index('date');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('aura_pricing_data');
    }
};
