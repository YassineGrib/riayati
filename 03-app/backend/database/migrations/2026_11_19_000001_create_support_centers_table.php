<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('support_centers', function (Blueprint $table): void {
            $table->id();
            $table->string('name');
            $table->string('kind')->index();
            $table->string('wilaya')->nullable()->index();
            foreach (['address', 'phone', 'hotline', 'email', 'website', 'hours'] as $column) {
                $table->string($column)->nullable();
            }
            $table->text('notes')->nullable();
            $table->boolean('is_published')->default(false);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('support_centers');
    }
};
