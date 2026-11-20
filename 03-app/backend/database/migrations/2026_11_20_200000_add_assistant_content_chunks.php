<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('contents', fn (Blueprint $table) => $table->boolean('use_in_assistant')->default(false));
        Schema::create('content_chunks', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('content_id')->constrained()->cascadeOnDelete();
            $table->unsignedInteger('position');
            $table->text('text');
            $table->json('embedding');
            $table->timestamps();
            $table->index('content_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('content_chunks');
        Schema::table('contents', fn (Blueprint $table) => $table->dropColumn('use_in_assistant'));
    }
};
