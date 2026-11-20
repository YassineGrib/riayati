<?php

namespace App\Console\Commands;

use App\Services\Assistant\ContentIndexer;
use Illuminate\Console\Command;

class AssistantReindex extends Command
{
    protected $signature = 'assistant:reindex';

    protected $description = 'Reindex published texts enabled for the legal assistant';

    public function handle(ContentIndexer $indexer): int
    {
        $result = $indexer->reindexAll();
        $this->info("Indexed: {$result['indexed']}; failed: {$result['failed']}");

        return $result['failed'] > 0 ? self::FAILURE : self::SUCCESS;
    }
}
