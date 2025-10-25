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
        Schema::create('charging_sessions', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->string('vehicle_id')->index();
            $table->timestamp('start_time')->index();
            $table->timestamp('end_time')->nullable();
            $table->decimal('energy_added', 10, 2);
            $table->decimal('cost', 10, 2);
            $table->decimal('charge_rate', 10, 2)->nullable();
            $table->integer('start_battery_level')->nullable();
            $table->integer('end_battery_level')->nullable();
            $table->timestamps();

            $table->index(['vehicle_id', 'start_time']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('charging_sessions');
    }
};
