<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\Assistant\AssistantService;
use App\Services\Assistant\AssistantUnavailable;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AssistantController extends Controller
{
    public function __invoke(Request $request, AssistantService $assistant): JsonResponse
    {
        abort_unless($request->user()->role->isParent(), 403);
        $data = $request->validate(['question' => ['required', 'string', 'max:'.config('riayati.assistant.max_question_chars')]]);
        try {
            return response()->json($assistant->answer($data['question']));
        } catch (AssistantUnavailable) {
            return response()->json(['message' => 'المساعد غير متاح حاليًا، حاول لاحقًا.'], 503);
        }
    }
}
