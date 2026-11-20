<?php

namespace Tests\Feature\Api;

use App\Enums\ReportStatus;
use App\Models\IncidentReport;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class ReportTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        Storage::fake('local');
    }

    private function payload(array $overrides = []): array
    {
        return array_merge([
            'description' => 'عند تسليم الطفل لاحظتُ كدمة على ذراعه.',
            'incident_at' => now()->subHour()->toIso8601String(),
        ], $overrides);
    }

    private function submit(User $user, array $payload): \Illuminate\Testing\TestResponse
    {
        return $this->actingAs($user, 'sanctum')->post('/api/reports', $payload, ['Accept' => 'application/json']);
    }

    public function test_a_parent_submits_a_report_with_attachments(): void
    {
        $mother = User::factory()->mother()->create();

        $response = $this->submit($mother, $this->payload([
            'files' => [UploadedFile::fake()->image('صورة.jpg', 800, 600), UploadedFile::fake()->create('clip.mp4', 2048, 'video/mp4')],
        ]));

        $response->assertCreated()
            ->assertJsonPath('report.status', 'under_review')
            ->assertJsonPath('report.attachments_count', 2)
            ->assertJsonPath('report.attachments.0.kind', 'image')
            ->assertJsonPath('report.attachments.1.kind', 'video');

        $this->assertMatchesRegularExpression('/^RIA-\d{4}-0001$/', $response->json('report.reference'));
        $this->assertCount(2, Storage::disk('local')->allFiles());
        $this->assertSame(64, strlen($response->json('report.attachments.0.sha256')));
        $this->assertArrayNotHasKey('path', $response->json('report.attachments.0'));
    }

    public function test_the_list_reports_the_real_attachment_count(): void
    {
        $mother = User::factory()->mother()->create();
        $this->submit($mother, $this->payload([
            'files' => [UploadedFile::fake()->image('a.jpg', 100, 100), UploadedFile::fake()->image('b.jpg', 100, 100)],
        ]));
        $this->submit($mother, $this->payload());

        $counts = collect($this->actingAs($mother, 'sanctum')->getJson('/api/reports')->json('reports'))
            ->pluck('attachments_count', 'reference')
            ->sort()
            ->values()
            ->all();

        $this->assertSame([0, 2], $counts);
    }

    public function test_references_count_up(): void
    {
        $father = User::factory()->father()->create();

        $this->submit($father, $this->payload());
        $second = $this->submit($father, $this->payload());

        $this->assertStringEndsWith('-0002', $second->json('report.reference'));
    }

    public function test_the_stored_fingerprint_matches_the_uploaded_file(): void
    {
        $father = User::factory()->father()->create();
        $file = UploadedFile::fake()->createWithContent('doc.pdf', "%PDF-1.4\nhello");

        $response = $this->submit($father, $this->payload(['files' => [$file]]));

        $this->assertSame(hash('sha256', "%PDF-1.4\nhello"), $response->json('report.attachments.0.sha256'));
    }

    public function test_validation_rules_from_the_app_are_enforced(): void
    {
        $father = User::factory()->father()->create();

        $this->submit($father, $this->payload(['description' => '']))->assertJsonValidationErrors('description');
        $this->submit($father, $this->payload(['incident_at' => now()->addDay()->toIso8601String()]))->assertJsonValidationErrors('incident_at');
        $this->submit($father, $this->payload(['files' => array_map(fn ($i) => UploadedFile::fake()->image("p{$i}.jpg"), range(1, 6))]))
            ->assertJsonValidationErrors('files');
        $this->submit($father, $this->payload(['files' => [UploadedFile::fake()->create('big.mp4', 31 * 1024, 'video/mp4')]]))
            ->assertJsonValidationErrors('files.0');
        $this->submit($father, $this->payload(['files' => [UploadedFile::fake()->create('run.exe', 10, 'application/x-msdownload')]]))
            ->assertJsonValidationErrors('files.0');

        $this->assertDatabaseCount('incident_reports', 0);
        $this->assertSame([], Storage::disk('local')->allFiles());
    }

    public function test_exactly_five_files_of_thirty_megabytes_are_accepted(): void
    {
        $father = User::factory()->father()->create();
        $files = array_map(fn ($i) => UploadedFile::fake()->create("v{$i}.mp4", 30 * 1024, 'video/mp4'), range(1, 5));

        $this->submit($father, $this->payload(['files' => $files]))->assertCreated();
    }

    public function test_a_parent_sees_only_their_own_reports_not_the_other_parents(): void
    {
        $father = User::factory()->father()->create();
        $mother = User::factory()->mother()->create();
        $familyCode = $this->actingAs($father, 'sanctum')->postJson('/api/family/invite')->json('code');
        $this->actingAs($mother, 'sanctum')->postJson('/api/family/link', ['code' => $familyCode])->assertOk();

        $fatherReport = $this->submit($father, $this->payload())->json('report.id');
        $this->submit($mother, $this->payload(['description' => 'بلاغ الأم']));

        $list = $this->actingAs($mother, 'sanctum')->getJson('/api/reports')->assertOk()->json('reports');
        $this->assertCount(1, $list);
        $this->assertSame('بلاغ الأم', $list[0]['excerpt']);
        // The linked partner gets 404 on the other parent's report, same as a stranger.
        $this->actingAs($mother, 'sanctum')->getJson("/api/reports/{$fatherReport}")->assertNotFound();
        $this->actingAs($mother, 'sanctum')->get("/api/reports/{$fatherReport}/pdf")->assertNotFound();
    }

    public function test_the_list_can_be_filtered_by_status(): void
    {
        $father = User::factory()->father()->create();
        $id = $this->submit($father, $this->payload())->json('report.id');
        $this->submit($father, $this->payload());
        IncidentReport::find($id)->markReviewed(User::factory()->admin()->create());

        $this->actingAs($father, 'sanctum')->getJson('/api/reports?status=reviewed')->assertJsonCount(1, 'reports');
        $this->actingAs($father, 'sanctum')->getJson('/api/reports?status=under_review')->assertJsonCount(1, 'reports');
        $this->actingAs($father, 'sanctum')->getJson('/api/reports?status=nonsense')->assertUnprocessable();
    }

    public function test_an_admin_can_view_any_report_and_mark_it_reviewed(): void
    {
        $father = User::factory()->father()->create();
        $admin = User::factory()->admin()->create();
        $id = $this->submit($father, $this->payload())->json('report.id');

        $this->actingAs($admin, 'sanctum')->getJson("/api/reports/{$id}")->assertOk();
        IncidentReport::find($id)->markReviewed($admin);

        $report = IncidentReport::find($id);
        $this->assertSame(ReportStatus::Reviewed, $report->status);
        $this->assertSame($admin->id, $report->reviewed_by);
    }

    public function test_a_submitted_report_cannot_be_edited_or_deleted(): void
    {
        $father = User::factory()->father()->create();
        $id = $this->submit($father, $this->payload())->json('report.id');

        $this->actingAs($father, 'sanctum')->putJson("/api/reports/{$id}", ['description' => 'x'])->assertStatus(405);
        $this->actingAs($father, 'sanctum')->patchJson("/api/reports/{$id}", ['description' => 'x'])->assertStatus(405);
        $this->actingAs($father, 'sanctum')->deleteJson("/api/reports/{$id}")->assertStatus(405);
        $this->assertDatabaseCount('incident_reports', 1);
    }

    public function test_guests_and_admins_cannot_submit(): void
    {
        $this->postJson('/api/reports', $this->payload())->assertUnauthorized();
        $this->submit(User::factory()->admin()->create(), $this->payload())->assertForbidden();
    }

    public function test_attachments_are_served_only_through_a_signed_link(): void
    {
        $father = User::factory()->father()->create();
        $report = $this->submit($father, $this->payload(['files' => [UploadedFile::fake()->createWithContent('a.pdf', '%PDF-1.4 secret')]]))->json('report');
        $attachmentId = $report['attachments'][0]['id'];

        // no signature -> refused
        $this->get("/api/attachments/{$attachmentId}/download")->assertForbidden();

        $url = $this->actingAs($father, 'sanctum')->getJson("/api/reports/{$report['id']}/attachments/{$attachmentId}/link")->assertOk()->json('url');
        $download = $this->get($url)->assertOk();
        $this->assertSame('%PDF-1.4 secret', $download->streamedContent());
        $this->assertStringContainsString('no-store', $download->headers->get('Cache-Control'));

        // tampered link -> refused
        $this->get($url.'x')->assertForbidden();
    }

    public function test_a_signed_link_expires(): void
    {
        $father = User::factory()->father()->create();
        $report = $this->submit($father, $this->payload(['files' => [UploadedFile::fake()->createWithContent('a.pdf', '%PDF-1.4')]]))->json('report');
        $url = $this->actingAs($father, 'sanctum')->getJson("/api/reports/{$report['id']}/attachments/{$report['attachments'][0]['id']}/link")->json('url');

        $this->travel(6)->minutes();

        $this->get($url)->assertForbidden();
    }

    public function test_only_the_author_or_an_admin_can_get_a_link(): void
    {
        $father = User::factory()->father()->create();
        $mother = User::factory()->mother()->create();
        $report = $this->submit($father, $this->payload(['files' => [UploadedFile::fake()->createWithContent('a.pdf', '%PDF-1.4')]]))->json('report');
        $path = "/api/reports/{$report['id']}/attachments/{$report['attachments'][0]['id']}/link";

        $this->actingAs($mother, 'sanctum')->getJson($path)->assertNotFound();
        $this->actingAs(User::factory()->admin()->create(), 'sanctum')->getJson($path)->assertOk();
    }

    public function test_the_pdf_is_generated_for_the_author(): void
    {
        $mother = User::factory()->mother()->create(['name' => 'أمينة']);
        $report = $this->submit($mother, $this->payload(['files' => [UploadedFile::fake()->image('a.jpg', 1200, 900)]]))->json('report');

        $response = $this->actingAs($mother, 'sanctum')->get("/api/reports/{$report['id']}/pdf")->assertOk();

        $this->assertSame('application/pdf', $response->headers->get('Content-Type'));
        $this->assertStringContainsString($report['reference'], $response->headers->get('Content-Disposition'));
        $this->assertStringStartsWith('%PDF', $response->getContent());
        $this->assertGreaterThan(5000, strlen($response->getContent()));
    }
}
