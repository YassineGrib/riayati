<?php

namespace Tests\Feature\Admin;

use App\Filament\Resources\AdminActivities\AdminActivityResource;
use App\Filament\Resources\AdminActivities\Pages\ListAdminActivities;
use App\Filament\Resources\Contents\Pages\CreateContent;
use App\Filament\Resources\Contents\Pages\EditContent;
use App\Filament\Resources\Contents\Pages\ListContents;
use App\Filament\Resources\IncidentReports\Pages\ListIncidentReports;
use App\Filament\Resources\IncidentReports\Pages\ViewIncidentReport;
use App\Filament\Resources\SupportCenters\Pages\CreateSupportCenter;
use App\Filament\Resources\SupportCenters\Pages\EditSupportCenter;
use App\Filament\Resources\SupportCenters\Pages\ListSupportCenters;
use App\Models\AdminActivity;
use App\Models\Content;
use App\Models\IncidentReport;
use App\Models\SupportCenter;
use App\Models\User;
use App\Services\AdminActivityLog;
use App\Services\AttachmentLinks;
use App\Services\ReportPdf;
use Filament\Facades\Filament;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Storage;
use Livewire\Livewire;
use Tests\TestCase;

class AdminActivityLogTest extends TestCase
{
    use RefreshDatabase;

    private User $admin;

    protected function setUp(): void
    {
        parent::setUp();
        $this->admin = User::factory()->admin()->create();
        $this->actingAs($this->admin);
        Filament::setCurrentPanel(Filament::getPanel('admin'));
    }

    private function report(): IncidentReport
    {
        return IncidentReport::create(['reference' => IncidentReport::nextReference(), 'user_id' => User::factory()->father()->create()->id, 'description' => 'Evidence', 'incident_at' => now(), 'status' => 'under_review']);
    }

    private function assertLogged(string $action, $subject): void
    {
        $rows = AdminActivity::where('action', $action)->where('subject_type', $subject->getMorphClass())->where('subject_id', $subject->id)->get();
        $this->assertCount(1, $rows);
        $this->assertSame($this->admin->id, $rows->first()->admin_id);
    }

    public function test_service_stores_metadata_subject_and_request_ip(): void
    {
        $center = SupportCenter::create(['name' => 'Test', 'kind' => 'ngo']);
        request()->server->set('REMOTE_ADDR', '192.0.2.1');
        app(AdminActivityLog::class)->record($this->admin, 'custom', $center, ['example' => true]);
        $log = AdminActivity::where('action', 'custom')->firstOrFail();
        $this->assertSame(['example' => true], $log->meta);
        $this->assertSame('192.0.2.1', $log->ip);
        $this->assertTrue($log->subject->is($center));
    }

    public function test_content_and_center_crud_call_sites_write_once(): void
    {
        Livewire::test(CreateContent::class)->fillForm(['title' => 'Test', 'slug' => 'test', 'type' => 'article', 'body' => '<p>Test</p>', 'is_published' => false])->call('create')->assertHasNoFormErrors();
        $content = Content::firstOrFail();
        $this->assertLogged('content.created', $content);
        Livewire::test(EditContent::class, ['record' => $content->id])->fillForm(['title' => 'Updated'])->call('save')->assertHasNoFormErrors();
        $this->assertLogged('content.updated', $content);
        Livewire::test(ListContents::class)->callTableAction('delete', $content);
        $this->assertLogged('content.deleted', $content);
        Livewire::test(CreateSupportCenter::class)->fillForm(['name' => 'Test', 'kind' => 'ngo', 'is_published' => false])->call('create')->assertHasNoFormErrors();
        $center = SupportCenter::firstOrFail();
        $this->assertLogged('center.created', $center);
        Livewire::test(EditSupportCenter::class, ['record' => $center->id])->fillForm(['name' => 'Updated'])->call('save')->assertHasNoFormErrors();
        $this->assertLogged('center.updated', $center);
        Livewire::test(ListSupportCenters::class)->callTableAction('delete', $center);
        $this->assertLogged('center.deleted', $center);
    }

    public function test_review_actions_record_once_even_when_repeated(): void
    {
        $report = $this->report();
        Livewire::test(ViewIncidentReport::class, ['record' => $report->id])->callAction('markReviewed');
        $this->assertLogged('report.reviewed', $report);
        Livewire::test(ListIncidentReports::class)->callTableAction('markReviewed', $report);
        $this->assertLogged('report.reviewed', $report);
        $other = $this->report();
        Livewire::test(ListIncidentReports::class)->callTableAction('markReviewed', $other);
        $this->assertLogged('report.reviewed', $other);
    }

    public function test_pdf_and_attachment_access_are_logged_but_parent_access_is_not(): void
    {
        $report = $this->report();
        $this->mock(ReportPdf::class)->shouldReceive('render')->andReturn('%PDF-test');
        Livewire::test(ViewIncidentReport::class, ['record' => $report->id])->callAction('downloadPdf')->assertFileDownloaded($report->reference.'.pdf');
        $this->assertLogged('report.pdf_downloaded', $report);
        Storage::fake('local');
        Storage::disk('local')->put('evidence.txt', 'test');
        $file = $report->attachments()->create(['path' => 'evidence.txt', 'original_name' => 'test.txt', 'mime' => 'text/plain', 'kind' => 'file', 'size' => 4, 'sha256' => hash('sha256', 'test')]);
        $url = AttachmentLinks::for($file);
        $this->get($url)->assertOk();
        $this->assertLogged('attachment.opened', $file);
        $this->actingAs($report->user);
        $this->get($url)->assertOk();
        $this->assertLogged('attachment.opened', $file);
    }

    public function test_log_resource_is_read_only_filtered_and_admin_only(): void
    {
        $center = SupportCenter::create(['name' => 'Test', 'kind' => 'ngo']);
        $log = AdminActivity::firstOrFail();
        app(AdminActivityLog::class)->record($this->admin, 'custom', $center);
        $page = Livewire::test(ListAdminActivities::class)->assertCanSeeTableRecords(AdminActivity::all())->assertTableActionDoesNotExist('delete')->assertTableActionDoesNotExist('edit');
        $page->filterTable('action', 'custom')->assertCanNotSeeTableRecords([$log]);
        $this->assertFalse(AdminActivityResource::canCreate());
        $this->assertFalse(AdminActivityResource::canEdit($log));
        $this->assertFalse(AdminActivityResource::canDelete($log));
        $this->assertFalse(AdminActivityResource::canDeleteAny());
        $page->resetTableFilters()->filterTable('admin_id', $this->admin->id)->assertCanSeeTableRecords(AdminActivity::all());
        $url = AdminActivityResource::getUrl();
        auth()->logout();
        $this->get($url)->assertRedirect('/admin/login');
        foreach ([User::factory()->father()->create(), User::factory()->mother()->create()] as $parent) {
            $this->actingAs($parent);
            $this->get($url)->assertForbidden();
            Livewire::test(ListAdminActivities::class)->assertForbidden();
        }
    }
}
