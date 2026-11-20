// Renders the 6 feed posts (1080x1350) and 6 stories (1080x1920) as PNG into out/social/ and copies to deliverables/Social/
import { execSync } from "node:child_process";
import { copyFileSync, mkdirSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const rootDir = dirname(dirname(fileURLToPath(import.meta.url)));

const names = {
  Post1: "riayati-post-01-intro",
  Post2: "riayati-post-02-report-pdf",
  Post3: "riayati-post-03-calendar",
  Post4: "riayati-post-04-library",
  Post5: "riayati-post-05-centers",
  Post6: "riayati-post-06-privacy",
  Story1: "riayati-story-01-intro",
  Story2: "riayati-story-02-report-pdf",
  Story3: "riayati-story-03-calendar",
  Story4: "riayati-story-04-library",
  Story5: "riayati-story-05-centers",
  Story6: "riayati-story-06-privacy",
};

const outPosts = join(rootDir, "out/social/posts");
const outStories = join(rootDir, "out/social/stories");
const delivPosts = join(rootDir, "deliverables/Social/Posts");
const delivStories = join(rootDir, "deliverables/Social/Stories");

mkdirSync(outPosts, { recursive: true });
mkdirSync(outStories, { recursive: true });
mkdirSync(delivPosts, { recursive: true });
mkdirSync(delivStories, { recursive: true });

for (const [id, file] of Object.entries(names)) {
  const isPost = id.startsWith("Post");
  const outDir = isPost ? outPosts : outStories;
  const delivDir = isPost ? delivPosts : delivStories;
  const outPath = join(outDir, `${file}.png`);
  const delivPath = join(delivDir, `${file}.png`);

  console.log(`Rendering ${id} -> ${outPath}...`);
  execSync(`npx remotion still src/index.ts ${id} "${outPath}" --image-format=png`, { cwd: rootDir, stdio: "inherit" });
  copyFileSync(outPath, delivPath);
  console.log(`Copied to ${delivPath}`);
}
console.log("All social graphics rendered and delivered successfully.");

