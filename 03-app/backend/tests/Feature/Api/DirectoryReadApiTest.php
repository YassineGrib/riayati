<?php

namespace Tests\Feature\Api;

use App\Models\Content;
use App\Models\SupportCenter;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class DirectoryReadApiTest extends TestCase
{
    use RefreshDatabase;

    private function content(array $data = []): Content
    {
        return Content::create(array_merge(['type' => 'article', 'title' => 'Needle', 'slug' => 'sample', 'body' => '<script>alert("x")</script>', 'is_published' => true, 'created_by' => User::factory()->admin()->create()->id], $data));
    }

    public function test_guests_receive_401(): void
    {
        foreach (['/api/contents', '/api/contents/sample', '/api/centers', '/api/centers/1'] as $url) {
            $this->getJson($url)->assertUnauthorized();
        }
    }

    public function test_content_visibility_filters_pagination_and_raw_html(): void
    {
        $item = $this->content();
        $draft = $this->content(['slug' => 'draft', 'is_published' => false]);
        for ($i = 0; $i < 21; $i++) {
            $this->content(['slug' => 'law-'.$i, 'title' => 'Other', 'type' => 'law']);
        }
        foreach ([User::factory()->father()->create(), User::factory()->mother()->create()] as $parent) {
            $this->withToken($parent->createToken('test')->plainTextToken);
            $this->getJson('/api/contents')->assertOk()->assertJsonCount(20, 'data')->assertJsonPath('total', 22)->assertJsonMissingPath('data.0.body')->assertJsonMissingPath('data.0.created_by');
            $this->getJson('/api/contents?type=article&q=Needle')->assertJsonCount(1, 'data')->assertJsonPath('data.0.id', $item->id)->assertJsonPath('data.0.type_label', 'مقال');
            $this->getJson('/api/contents?type=law&q=Needle')->assertJsonCount(0, 'data');
            $response = $this->getJson('/api/contents/sample')->assertOk()->assertJsonPath('data.body', $item->body);
            $this->assertSame('application/json', $response->headers->get('Content-Type'));
            $this->getJson('/api/contents/draft')->assertNotFound();
            $this->getJson('/api/contents/missing')->assertNotFound();
        }
    }

    public function test_centers_visibility_filters_and_detail(): void
    {
        $center = SupportCenter::create(['name' => 'Needle', 'kind' => 'court', 'wilaya' => '16', 'is_published' => true, 'notes' => 'Private detail']);
        $draft = SupportCenter::create(['name' => 'Needle', 'kind' => 'court', 'wilaya' => '16']);
        SupportCenter::create(['name' => 'Other', 'kind' => 'ngo', 'wilaya' => '31', 'is_published' => true]);
        $this->withToken(User::factory()->mother()->create()->createToken('test')->plainTextToken);
        $this->getJson('/api/centers')->assertJsonCount(2, 'data')->assertJsonMissingPath('data.0.notes')->assertJsonMissingPath('data.0.is_published');
        $this->getJson('/api/centers?kind=court&wilaya=16&q=Needle')->assertJsonCount(1, 'data')->assertJsonPath('data.0.id', $center->id);
        $this->getJson('/api/centers?kind=ngo&wilaya=16')->assertJsonCount(0, 'data');
        $this->getJson('/api/centers/'.$center->id)->assertOk()->assertJsonPath('data.notes', 'Private detail');
        $this->getJson('/api/centers/'.$draft->id)->assertNotFound();
        $this->getJson('/api/centers/999')->assertNotFound();
        $this->getJson('/api/centers?kind=invalid')->assertUnprocessable();
        $this->getJson('/api/contents?type=invalid')->assertUnprocessable();
    }
}
