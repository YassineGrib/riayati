<?php

namespace Tests\Feature\Admin;

use App\Enums\ReportStatus;
use App\Filament\Resources\IncidentReports\IncidentReportResource;
use App\Filament\Resources\IncidentReports\Pages\ViewIncidentReport;
use App\Models\Family;
use App\Models\IncidentReport;
use App\Models\User;
use Filament\Facades\Filament;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Storage;
use Livewire\Livewire;
use Tests\TestCase;

class IncidentReportViewTest extends TestCase
{
    use RefreshDatabase;

    private User $admin;

    protected function setUp(): void
    {
        parent::setUp();
        $this->admin = User::factory()->admin()->create();
        $this->actingAs($this->admin);
        Filament::setCurrentPanel(Filament::getPanel('admin'));
        Storage::fake('local');
    }

    private function report(array $attributes = [], ?User $reporter = null): IncidentReport
    {
        return IncidentReport::create(array_merge([
            'reference' => IncidentReport::nextReference(),
            'user_id' => ($reporter ?? User::factory()->father()->create())->id,
            'description' => 'لاحظت كدمة عند تسليم الطفل',
            'incident_at' => now()->subHour(),
            'status' => ReportStatus::UnderReview,
        ], $attributes));
    }

    private function url(IncidentReport $report): string
    {
        return IncidentReportResource::getUrl('view', ['record' => $report]);
    }

    public function test_view_shows_reporter_and_timeline_but_never_the_linked_partner(): void
    {
        $this->freezeTime();
        $family = Family::create();
        $reporter = User::factory()->mother()->create([
            'name' => 'أمينة', 'phone' => '0550123456', 'wilaya' => 'الجزائر', 'family_id' => $family->id,
        ]);
        $partner = User::factory()->father()->create([
            'name' => 'اسم الشريك السري', 'phone' => '0660999888', 'family_id' => $family->id,
        ]);
        $report = $this->report([], $reporter);
        $this->travel(1)->hours();
        $reviewer = User::factory()->admin()->create(['name' => 'مسؤول المراجعة']);
        $report->markReviewed($reviewer);

        $this->get($this->url($report))->assertOk()
            ->assertSee($report->reference)->assertSee($report->description)
            ->assertSee('مقدّم البلاغ')->assertSee('أمينة')->assertSee('أم')
            ->assertSee($reporter->phone)->assertSee($reporter->wilaya)
            ->assertSee('تمت المراجعة')->assertSee($reviewer->name)
            ->assertSee($report->created_at->format('Y-m-d H:i'))
            ->assertSee($report->reviewed_at->format('Y-m-d H:i'))
            ->assertDontSee($partner->name)->assertDontSee($partner->phone)->assertDontSee($partner->email);
    }

    public function test_evidence_tiles_use_expiring_signed_links_and_never_expose_storage_paths(): void
    {
        $report = $this->report();
        $attachments = collect();
        foreach (['image' => ['image/png', 'png'], 'file' => ['application/pdf', 'pdf'], 'video' => ['video/mp4', 'mp4']] as $kind => [$mime, $extension]) {
            $path = 'reports/private-evidence/secret-'.$kind.'.'.$extension;
            Storage::disk('local')->put($path, 'evidence '.$kind);
            $attachments->push($report->attachments()->create([
                'path' => $path, 'original_name' => 'دليل.'.$extension,
                'mime' => $mime, 'kind' => $kind, 'size' => 2048,
                'sha256' => hash('sha256', $kind),
            ]));
        }

        $response = $this->get($this->url($report))->assertOk();
        $dom = new \DOMDocument;
        @$dom->loadHTML('<?xml encoding="UTF-8">'.$response->getContent());
        $xpath = new \DOMXPath($dom);
        $urls = [];
        foreach ($attachments as $index => $attachment) {
            $response->assertDontSee($attachment->path, false)->assertSee($attachment->original_name)
                ->assertSee(substr($attachment->sha256, 0, 12).'…')->assertSee('2 KB');
            $nodes = $xpath->query('//a[contains(@href, "/attachments/'.$attachment->id.'/download?")]');
            $this->assertCount(1, $nodes);
            $link = $nodes->item(0);
            $this->assertSame('_blank', $link->getAttribute('target'));
            $this->assertContains('noopener', explode(' ', $link->getAttribute('rel')));
            $url = $link->getAttribute('href');
            $this->assertStringContainsString('signature=', $url);
            $this->assertSame('evidence '.$attachment->kind, $this->get($url)->assertOk()->streamedContent());
            if ($attachment->kind === 'image') {
                $this->assertSame($url, $xpath->query('.//img', $link)->item(0)->getAttribute('src'));
            } else {
                $this->assertCount(1, $xpath->query('.//svg', $link));
            }
            $copyButtons = $xpath->query('//button[contains(@aria-label, "SHA-256")]');
            $this->assertCount(3, $copyButtons);
            $this->assertSame($attachment->sha256, $copyButtons->item($index)->getAttribute('data-fingerprint'));
            $this->assertStringContainsString('clipboard.writeText($el.dataset.fingerprint)', $copyButtons->item($index)->getAttribute('x-on:click'));
            $urls[] = $url;
        }

        $this->travel(6)->minutes();
        foreach ($urls as $url) {
            $this->get($url)->assertForbidden();
        }
    }

    public function test_empty_evidence_and_5000_character_arabic_description_render_without_truncation(): void
    {
        $description = str_repeat('بلاغ ', 1000);
        $this->assertSame(5000, mb_strlen($description));
        $report = $this->report(['description' => $description]);

        $this->get($this->url($report))->assertOk()->assertSee($description)->assertSee('لا توجد مرفقات');
    }

    public function test_description_and_filenames_are_escaped(): void
    {
        $report = $this->report(['description' => '<script>alert("description")</script>']);
        $report->attachments()->create([
            'path' => 'private/file.pdf', 'original_name' => '<script>alert("file")</script>.pdf',
            'mime' => 'application/pdf', 'kind' => 'file', 'size' => 20, 'sha256' => str_repeat('a', 64),
        ]);
        $this->get($this->url($report))->assertOk()->assertSee($report->description)
            ->assertDontSee($report->description, false)->assertDontSee('<script>alert("file")</script>', false);
    }

    public function test_pdf_action_downloads_a_real_pdf_with_the_reference_filename(): void
    {
        $report = $this->report();
        $page = Livewire::test(ViewIncidentReport::class, ['record' => $report->id])
            ->callAction('downloadPdf')
            ->assertFileDownloaded($report->reference.'.pdf', contentType: 'application/pdf');

        $body = base64_decode($page->effects['download']['content']);
        $this->assertStringStartsWith('%PDF', $body);
        $this->assertGreaterThan(5000, strlen($body));
    }

    public function test_review_action_updates_the_timeline_and_hides_after_review(): void
    {
        $this->freezeTime();
        $report = $this->report();
        Livewire::test(ViewIncidentReport::class, ['record' => $report->id])
            ->assertActionVisible('markReviewed')->callAction('markReviewed')
            ->assertActionHidden('markReviewed')->assertSee($this->admin->name)
            ->assertSee(now()->format('Y-m-d H:i'));

        $this->assertSame(ReportStatus::Reviewed, $report->refresh()->status);
        $this->assertSame($this->admin->id, $report->reviewed_by);
        $this->assertSame(now()->toDateTimeString(), $report->reviewed_at->toDateTimeString());
    }

    public function test_stale_review_action_preserves_the_first_reviewer_and_time(): void
    {
        $report = $this->report();
        $page = Livewire::test(ViewIncidentReport::class, ['record' => $report->id]);
        $firstAdmin = User::factory()->admin()->create();
        $report->markReviewed($firstAdmin);
        $timestamp = $report->reviewed_at->toDateTimeString();
        $this->travel(1)->hours();
        $page->callAction('markReviewed');

        $this->assertSame($firstAdmin->id, $report->refresh()->reviewed_by);
        $this->assertSame($timestamp, $report->reviewed_at->toDateTimeString());
        Livewire::test(ViewIncidentReport::class, ['record' => $report->id])->assertActionHidden('markReviewed');
    }

    public function test_parents_cannot_open_the_view_even_for_their_own_reports(): void
    {
        foreach ([User::factory()->father()->create(), User::factory()->mother()->create()] as $parent) {
            $report = $this->report([], $parent);
            $this->actingAs($parent)->get($this->url($report))->assertForbidden();
        }
    }
}
