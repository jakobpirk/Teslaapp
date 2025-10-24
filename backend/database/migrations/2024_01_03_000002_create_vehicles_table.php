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
        Schema::create('vehicles', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('user_id');
            $table->string('tessie_vehicle_id')->unique(); // Vehicle ID from Tessie
            $table->string('display_name');
            $table->string('vin')->nullable();
            $table->string('model')->nullable(); // Model S, 3, X, Y, etc.
            $table->string('color')->nullable();
            $table->integer('year')->nullable();
            $table->decimal('battery_capacity', 8, 2)->nullable(); // kWh
            $table->boolean('is_active')->default(true);
            $table->json('vehicle_config')->nullable(); // Store additional Tesla config
            $table->timestamps();

            $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');
            $table->index(['user_id', 'is_active']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('vehicles');
    }
};
