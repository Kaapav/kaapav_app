/**
 * Patch all kaapav-store HTML files to include the SEO injection script.
 * Adds <script src="/assets/kaapav-seo-inject.js"></script> right before </head>.
 * Skips files that already have it. Skips admin pages.
 *
 * Run: node inject-seo-tag.js
 */
const fs = require('fs');
const path = require('path');

const STORE_DIR = path.join(__dirname, 'kaapav-store');
const SCRIPT_TAG = '<script src="/assets/kaapav-seo-inject.js" defer></script>';
const MARKER = 'kaapav-seo-inject.js';

function getAllHtmlFiles(dir) {
  const results = [];
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      // Skip admin directory
      if (entry.name === 'admin') continue;
      results.push(...getAllHtmlFiles(fullPath));
    } else if (entry.name.endsWith('.html') && entry.name !== 'admin.html') {
      results.push(fullPath);
    }
  }
  return results;
}

const files = getAllHtmlFiles(STORE_DIR);
let patched = 0;
let skipped = 0;

for (const file of files) {
  const content = fs.readFileSync(file, 'utf8');
  const rel = path.relative(STORE_DIR, file);

  if (content.includes(MARKER)) {
    console.log(`  SKIP  ${rel} (already has injection tag)`);
    skipped++;
    continue;
  }

  // Insert before </head>
  const headCloseIndex = content.indexOf('</head>');
  if (headCloseIndex === -1) {
    console.log(`  WARN  ${rel} (no </head> found, skipping)`);
    skipped++;
    continue;
  }

  const newContent =
    content.slice(0, headCloseIndex) +
    `  ${SCRIPT_TAG}\n` +
    content.slice(headCloseIndex);

  fs.writeFileSync(file, newContent, 'utf8');
  console.log(`  DONE  ${rel}`);
  patched++;
}

console.log(`\nPatched: ${patched} | Skipped: ${skipped} | Total: ${files.length}`);
