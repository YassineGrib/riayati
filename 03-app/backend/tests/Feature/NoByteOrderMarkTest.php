<?php

namespace Tests\Feature;

use Tests\TestCase;

/**
 * A UTF-8 byte order mark at the start of a PHP file is printed before every
 * response. It once made the report PDF start with EF BB BF instead of "%PDF",
 * so viewers showed a blank page. Windows editors add it silently.
 */
class NoByteOrderMarkTest extends TestCase
{
    public function test_no_php_source_file_starts_with_a_byte_order_mark(): void
    {
        $offenders = [];

        foreach (['app', 'bootstrap', 'config', 'database', 'lang', 'resources', 'routes', 'tests'] as $dir) {
            $iterator = new \RecursiveIteratorIterator(
                new \RecursiveDirectoryIterator(base_path($dir), \FilesystemIterator::SKIP_DOTS)
            );

            foreach ($iterator as $file) {
                if ($file->isFile() && str_ends_with($file->getFilename(), '.php')) {
                    if (file_get_contents($file->getPathname(), false, null, 0, 3) === "\xEF\xBB\xBF") {
                        $offenders[] = str_replace(base_path().DIRECTORY_SEPARATOR, '', $file->getPathname());
                    }
                }
            }
        }

        $this->assertSame([], $offenders, 'Remove the BOM from: '.implode(', ', $offenders));
    }
}
