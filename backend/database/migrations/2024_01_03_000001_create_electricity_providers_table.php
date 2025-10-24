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
        Schema::create('electricity_providers', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->string('name')->unique();
            $table->string('display_name');
            $table->string('country', 2); // ISO country code
            $table->string('region')->nullable();
            $table->string('api_base_url');
            $table->text('description')->nullable();
            $table->boolean('is_active')->default(true);
            $table->json('pricing_structure')->nullable(); // Store rate types, time windows, etc.
            $table->timestamps();

            $table->index(['country', 'is_active']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('electricity_providers');
    }
};
