<?php

namespace App\Services;

use App\Models\IncidentReport;
use Illuminate\Support\Facades\Storage;
use Mpdf\Config\ConfigVariables;
use Mpdf\Config\FontVariables;
use Mpdf\Mpdf;
use Mpdf\Output\Destination;

/** Builds the structured Arabic (RTL) PDF of one incident report. */
class ReportPdf
{
    public function render(IncidentReport $report): string
    {
        $tmp = [];
        $images = $this->embeddableImages($report, $tmp);

        try {
            $html = view('pdf.report', ['report' => $report, 'images' => $images])->render();
            $mpdf = $this->mpdf();
            $mpdf->SetTitle('تقرير البلاغ '.$report->reference);
            $mpdf->SetAuthor('رعايتي');
            $mpdf->SetHTMLFooter('<div dir="ltr" style="text-align:center;font-size:9pt;color:#5a5e57">{PAGENO} / {nb}</div>');
            $mpdf->WriteHTML($html);

            return $mpdf->Output('', Destination::STRING_RETURN);
        } finally {
            foreach ($tmp as $file) {
                @unlink($file);
            }
        }
    }

    private function mpdf(): Mpdf
    {
        $dir = storage_path('app/mpdf');
        if (! is_dir($dir)) {
            mkdir($dir, 0775, true);
        }

        $fontDirs = (new ConfigVariables())->getDefaults()['fontDir'];
        $fontData = (new FontVariables())->getDefaults()['fontdata'];

        $mpdf = new Mpdf([
            'mode' => 'utf-8',
            'format' => 'A4',
            'margin_top' => 18, 'margin_bottom' => 18, 'margin_left' => 16, 'margin_right' => 16,
            'tempDir' => $dir,
            'fontDir' => array_merge($fontDirs, [resource_path('fonts')]),
            'fontdata' => $fontData + [
                'plexar' => ['R' => 'IBMPlexSansArabic-Regular.ttf', 'B' => 'IBMPlexSansArabic-Bold.ttf', 'useOTL' => 0xFF, 'useKashida' => 0],
            ],
            'default_font' => 'plexar',
        ]);
        $mpdf->SetDirectionality('rtl');

        return $mpdf;
    }

    /**
     * Photos are shrunk before embedding so a 12 MP phone picture does not exhaust memory.
     *
     * @return array<int, string> attachment id => temp JPEG path
     */
    private function embeddableImages(IncidentReport $report, array &$tmp): array
    {
        $out = [];
        foreach ($report->attachments->where('kind', 'image') as $attachment) {
            $source = Storage::disk('local')->path($attachment->path);
            if (! is_file($source) || ! function_exists('imagecreatefromstring')) {
                continue;
            }
            $image = @imagecreatefromstring((string) file_get_contents($source));
            if (! $image) {
                continue;
            }
            $w = imagesx($image);
            $h = imagesy($image);
            $scale = min(1, 1000 / max($w, 1));
            $resized = imagescale($image, (int) max(1, $w * $scale), (int) max(1, $h * $scale));
            $file = tempnam(sys_get_temp_dir(), 'ria').'.jpg';
            imagejpeg($resized, $file, 82);
            $tmp[] = $file;
            $out[$attachment->id] = $file;
        }

        return $out;
    }
}
