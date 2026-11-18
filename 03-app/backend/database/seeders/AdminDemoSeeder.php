<?php

namespace Database\Seeders;

use App\Enums\ReportStatus;
use App\Enums\Role;
use App\Models\Family;
use App\Models\IncidentReport;
use App\Models\ReportAttachment;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class AdminDemoSeeder extends Seeder
{
    /**
     * Seed 12 incident reports with mixed statuses and attachments for admin demonstration.
     * Idempotent: running multiple times will not duplicate accounts or reports.
     */
    public function run(): void
    {
        // 1. Ensure father and mother exist without modifying passwords
        $father = User::where('role', Role::Father)->first();
        if (! $father) {
            $family = Family::first() ?? Family::create();
            $father = User::create([
                'name' => 'ياسين بن عبد الله',
                'email' => 'father@riayati.test',
                'password' => Str::password(16, symbols: false),
                'role' => Role::Father,
                'family_id' => $family->id,
                'terms_accepted_at' => now(),
            ]);
        }

        $mother = User::where('role', Role::Mother)->first();
        if (! $mother) {
            $family = Family::where('id', $father->family_id)->first() ?? Family::create();
            $mother = User::create([
                'name' => 'أمينة الزهراء',
                'email' => 'mother@riayati.test',
                'password' => Str::password(16, symbols: false),
                'role' => Role::Mother,
                'family_id' => $family->id,
                'terms_accepted_at' => now(),
            ]);
        }

        $admin = User::where('role', Role::Admin)->first();
        if (! $admin) {
            $admin = User::create([
                'name' => 'المسؤول التجريبي',
                'email' => 'admin@riayati.test',
                'password' => Str::password(16, symbols: false),
                'role' => Role::Admin,
                'terms_accepted_at' => now(),
            ]);
        }

        // Tiny valid binary files for realistic previews and signed URL tests
        $tinyJpeg = base64_decode('/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAP//////////////////////////////////////////////////////////////////////////////////////wgALCAABAAEBAREA/8QAFBABAAAAAAAAAAAAAAAAAAAAAP/aAAgBAQABPxA=');
        $tinyPng = base64_decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==');
        $tinyPdf = "%PDF-1.4\n1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj\n2 0 obj<</Type/Pages/Kids[3 0 R]/Count 1>>endobj\n3 0 obj<</Type/Page/MediaBox[0 0 612 792]/Parent 2 0 R/Resources<<>>>>endobj\nxref\n0 4\n0000000000 65535 f \n0000000010 00000 n \n0000000060 00000 n \n0000000118 00000 n \ntrailer<</Size 4/Root 1 0 R>>\nstartxref\n205\n%%EOF\n";

        // 12 realistic reports spread across the last 3 weeks
        // 5 under_review, 7 reviewed; 4 within the last 7 days
        $reportsData = [
            [
                'reference' => 'RIA-2026-0142',
                'user' => $mother,
                'status' => ReportStatus::UnderReview,
                'incident_at' => Carbon::now()->subDays(1)->setTime(9, 30),
                'created_at' => Carbon::now()->subDays(1)->setTime(9, 41),
                'description' => 'عند تسليم الطفل بعد الزيارة لاحظتُ كدمة على ذراعه ولم يُقدَّم أي تفسير. صوّرتُ المكان فورًا وأرفقتُ الصورة والفيديو.',
                'attachments' => [
                    ['name' => 'صورة_الكدمة.jpg', 'mime' => 'image/jpeg', 'content' => $tinyJpeg],
                    ['name' => 'تقرير_طبي_مبدئي.pdf', 'mime' => 'application/pdf', 'content' => $tinyPdf],
                ],
            ],
            [
                'reference' => 'RIA-2026-0141',
                'user' => $father,
                'status' => ReportStatus::UnderReview,
                'incident_at' => Carbon::now()->subDays(2)->setTime(20, 10),
                'created_at' => Carbon::now()->subDays(2)->setTime(20, 30),
                'description' => 'تأخرت الأم في إعادة المحضون عن الموعد المحدد في الاتفاقية بساعتين ونصف دون إشعار مسبق.',
                'attachments' => [],
            ],
            [
                'reference' => 'RIA-2026-0140',
                'user' => $mother,
                'status' => ReportStatus::UnderReview,
                'incident_at' => Carbon::now()->subDays(4)->setTime(8, 45),
                'created_at' => Carbon::now()->subDays(4)->setTime(9, 15),
                'description' => 'حضر الأب لاستلام الأطفال في حالة عصبية شديدة وتلفظ بعبارات غير لائقة أمام الصغار مما أثار فزعهم ورفضهم الذهاب معه. تم توثيق الموقف بمحضر كتابي وصور مرفقة للمحادثة النصية السابقة للموعد.',
                'attachments' => [
                    ['name' => 'لقطة_شاشة_محادثة.png', 'mime' => 'image/png', 'content' => $tinyPng],
                    ['name' => 'صورة_السيارة.jpg', 'mime' => 'image/jpeg', 'content' => $tinyJpeg],
                    ['name' => 'إشعار_محضر.pdf', 'mime' => 'application/pdf', 'content' => $tinyPdf],
                ],
            ],
            [
                'reference' => 'RIA-2026-0139',
                'user' => $father,
                'status' => ReportStatus::UnderReview,
                'incident_at' => Carbon::now()->subDays(6)->setTime(16, 20),
                'created_at' => Carbon::now()->subDays(6)->setTime(17, 00),
                'description' => 'رفضت الأم السماح لي بمكالمة الطفل المرئية الأسبوعية المقررة في الحكم القضائي رغم الاتصال ثلاث مرات في الموعد المحدد.',
                'attachments' => [
                    ['name' => 'سجل_الاتصالات.png', 'mime' => 'image/png', 'content' => $tinyPng],
                ],
            ],
            [
                'reference' => 'RIA-2026-0138',
                'user' => $father,
                'status' => ReportStatus::Reviewed,
                'incident_at' => Carbon::now()->subDays(9)->setTime(18, 5),
                'created_at' => Carbon::now()->subDays(9)->setTime(18, 30),
                'reviewed_at' => Carbon::now()->subDays(8)->setTime(10, 15),
                'description' => 'تم منع الزيارة الأسبوعية المقررة بحجة وعكة صحية خفيفة للطفل دون إرسال أي تقرير طبي أو وصفة تؤكد ذلك.',
                'attachments' => [
                    ['name' => 'رسالة_الاعتذار.png', 'mime' => 'image/png', 'content' => $tinyPng],
                ],
            ],
            [
                'reference' => 'RIA-2026-0137',
                'user' => $mother,
                'status' => ReportStatus::UnderReview,
                'incident_at' => Carbon::now()->subDays(10)->setTime(13, 0),
                'created_at' => Carbon::now()->subDays(10)->setTime(13, 30),
                'description' => 'إلغاء الزيارة في اللحظة الأخيرة برسالة نصية مقتضبة دون تقديم بديل أو تعويض زمني للمحضون.',
                'attachments' => [],
            ],
            [
                'reference' => 'RIA-2026-0135',
                'user' => $father,
                'status' => ReportStatus::Reviewed,
                'incident_at' => Carbon::now()->subDays(12)->setTime(19, 45),
                'created_at' => Carbon::now()->subDays(12)->setTime(20, 10),
                'reviewed_at' => Carbon::now()->subDays(11)->setTime(14, 0),
                'description' => 'رفضت الأم استلام الحقيبة المدرسية والواجبات المنزلية المقررة للطفل أثناء التسليم الدوري.',
                'attachments' => [
                    ['name' => 'صورة_الحقيبة.jpg', 'mime' => 'image/jpeg', 'content' => $tinyJpeg],
                ],
            ],
            [
                'reference' => 'RIA-2026-0134',
                'user' => $mother,
                'status' => ReportStatus::Reviewed,
                'incident_at' => Carbon::now()->subDays(14)->setTime(15, 30),
                'created_at' => Carbon::now()->subDays(14)->setTime(16, 10),
                'reviewed_at' => Carbon::now()->subDays(13)->setTime(11, 45),
                'description' => 'اصطحاب شخص غير ذي صفة قانونية أثناء استلام الطفل بنقطة التلاقي الرسمية دون اتفاق مسبق.',
                'attachments' => [
                    ['name' => 'بيان_الواقعة.pdf', 'mime' => 'application/pdf', 'content' => $tinyPdf],
                ],
            ],
            [
                'reference' => 'RIA-2026-0133',
                'user' => $father,
                'status' => ReportStatus::Reviewed,
                'incident_at' => Carbon::now()->subDays(16)->setTime(11, 15),
                'created_at' => Carbon::now()->subDays(16)->setTime(11, 40),
                'reviewed_at' => Carbon::now()->subDays(15)->setTime(16, 20),
                'description' => 'استلام الابن في ملابس غير ملائمة للأجواء الماطرة وإصابته بنزلة برد تم علاجه منها لدى الطبيب.',
                'attachments' => [
                    ['name' => 'وصفة_طبية.pdf', 'mime' => 'application/pdf', 'content' => $tinyPdf],
                    ['name' => 'فاتورة_صيدلية.jpg', 'mime' => 'image/jpeg', 'content' => $tinyJpeg],
                ],
            ],
            [
                'reference' => 'RIA-2026-0132',
                'user' => $mother,
                'status' => ReportStatus::Reviewed,
                'incident_at' => Carbon::now()->subDays(18)->setTime(17, 30),
                'created_at' => Carbon::now()->subDays(18)->setTime(18, 00),
                'reviewed_at' => Carbon::now()->subDays(17)->setTime(9, 30),
                'description' => 'إعادة الطفل بعد موعد الزيارة وهو يعاني من إجهاد مفرط لعدم مراعاة مواعيد نومه واستيقاظه.',
                'attachments' => [],
            ],
            [
                'reference' => 'RIA-2026-0131',
                'user' => $mother,
                'status' => ReportStatus::Reviewed,
                'incident_at' => Carbon::now()->subDays(20)->setTime(11, 20),
                'created_at' => Carbon::now()->subDays(20)->setTime(11, 45),
                'reviewed_at' => Carbon::now()->subDays(19)->setTime(14, 00),
                'description' => 'عدم التزام الأب بدفع المصاريف العلاجية المتفق عليها في جدول النفقات للشهر الجاري.',
                'attachments' => [],
            ],
            [
                'reference' => 'RIA-2026-0130',
                'user' => $father,
                'status' => ReportStatus::Reviewed,
                'incident_at' => Carbon::now()->subDays(21)->setTime(10, 00),
                'created_at' => Carbon::now()->subDays(21)->setTime(10, 30),
                'reviewed_at' => Carbon::now()->subDays(20)->setTime(12, 10),
                'description' => 'تغيير مكان اللقاء المحدد مسبقًا بدون موافقة مشتركة مما تسبب في تعذر إتمام الزيارة في وقتها.',
                'attachments' => [
                    ['name' => 'رسالة_تغيير_المكان.png', 'mime' => 'image/png', 'content' => $tinyPng],
                    ['name' => 'محضر_عدم_حضور.pdf', 'mime' => 'application/pdf', 'content' => $tinyPdf],
                ],
            ],
        ];

        foreach ($reportsData as $item) {
            // Check if record already exists by reference for idempotency
            $report = IncidentReport::where('reference', $item['reference'])->first();

            if (! $report) {
                $report = IncidentReport::create([
                    'reference' => $item['reference'],
                    'user_id' => $item['user']->id,
                    'status' => $item['status'],
                    'incident_at' => $item['incident_at'],
                    'description' => $item['description'],
                    'created_at' => $item['created_at'],
                    'updated_at' => $item['created_at'],
                ]);

                // Force fill review metadata if reviewed
                if ($item['status'] === ReportStatus::Reviewed) {
                    $report->forceFill([
                        'reviewed_at' => $item['reviewed_at'] ?? $item['created_at']->copy()->addDay(),
                        'reviewed_by' => $admin->id,
                    ])->save();
                }
            }

            // Ensure attachments exist
            if ($report->attachments()->count() === 0 && ! empty($item['attachments'])) {
                foreach ($item['attachments'] as $att) {
                    $ext = pathinfo($att['name'], PATHINFO_EXTENSION);
                    $path = "reports/{$report->id}/".Str::random(40).".{$ext}";

                    Storage::disk('local')->put($path, $att['content']);

                    $report->attachments()->create([
                        'path' => $path,
                        'original_name' => $att['name'],
                        'mime' => $att['mime'],
                        'kind' => ReportAttachment::kindFor($att['mime']),
                        'size' => strlen($att['content']),
                        'sha256' => hash('sha256', $att['content']),
                    ]);
                }
            }
        }
    }
}
