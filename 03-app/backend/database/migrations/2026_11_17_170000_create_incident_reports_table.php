<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('incident_reports', function (Blueprint $table) {
            $table->id();
            $table->string('reference', 20)->unique();
            // Reports are evidence: the author row can never be removed while reports exist.
            $table->foreignId('user_id')->constrained()->restrictOnDelete();
            $table->text('description');
            $table->timestamp('incident_at');
            $table->string('status', 20)->default('under_review')->index();
            $table->timestamp('reviewed_at')->nullable();
            $table->foreignId('reviewed_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();
            $table->index(['user_id', 'created_at']);
        });

        Schema::create('report_attachments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('incident_report_id')->constrained()->restrictOnDelete();
            $table->string('path');            // on the private disk, random name
            $table->string('original_name');
            $table->string('mime', 100);
            $table->string('kind', 10);        // image | video | file
            $table->unsignedBigInteger('size');
            $table->char('sha256', 64);        // fingerprint taken at upload, proves the file was not altered
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('report_attachments');
        Schema::dropIfExists('incident_reports');
    }
};
