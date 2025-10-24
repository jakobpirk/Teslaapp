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
        Schema::create('face_auth_sessions', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->string('user_id')->index();
            $table->string('enrollment_id');
            $table->timestamp('authenticated_at');
            $table->timestamp('expires_at')->index();
            $table->boolean('is_authenticated')->default(true);
            $table->decimal('confidence_score', 5, 4)->default(0.95);
            $table->string('method')->default('faceBiometric');
            $table->timestamps();

            $table->foreign('enrollment_id')
                ->references('id')
                ->on('face_enrollments')
                ->onDelete('cascade');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('face_auth_sessions');
    }
};
