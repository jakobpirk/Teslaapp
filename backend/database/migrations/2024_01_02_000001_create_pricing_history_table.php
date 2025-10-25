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
        Schema::create('pricing_history', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->timestamp('timestamp')->unique();
            $table->decimal('price_per_kwh', 10, 4);
            $table->string('currency', 3)->default('USD');
            $table->string('utility_provider')->nullable();
            $table->string('rate_type')->nullable(); // 'off-peak', 'mid-peak', 'peak'
            $table->json('metadata')->nullable(); // Additional pricing info
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('pricing_history');
    }
};
