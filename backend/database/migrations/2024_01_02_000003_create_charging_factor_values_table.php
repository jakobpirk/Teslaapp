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
        Schema::create('charging_factor_values', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('charging_factor_id')->constrained()->onDelete('cascade');
            $table->timestamp('timestamp')->index();
            $table->string('location')->nullable()->index();
            $table->decimal('value', 10, 4)->nullable(); // Numeric value
            $table->text('value_text')->nullable(); // Text/categorical value
            $table->boolean('value_boolean')->nullable(); // Boolean value
            $table->json('metadata')->nullable();
            $table->timestamps();

            $table->index(['charging_factor_id', 'timestamp']);
            $table->index(['charging_factor_id', 'timestamp', 'location']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('charging_factor_values');
    }
};
