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
        Schema::create('charging_factors', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->string('name')->unique(); // 'price', 'weather', 'carbon_intensity', etc.
            $table->string('display_name');
            $table->text('description')->nullable();
            $table->decimal('weight', 5, 2)->default(1.00); // Factor weight in decision making
            $table->boolean('is_enabled')->default(true);
            $table->string('unit')->nullable(); // '$/kWh', '°C', 'gCO2/kWh', etc.
            $table->string('data_type')->default('numeric'); // 'numeric', 'boolean', 'categorical'
            $table->json('configuration')->nullable(); // Factor-specific configuration
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('charging_factors');
    }
};
