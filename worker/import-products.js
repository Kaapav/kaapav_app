// import-products.js
// Run: node import-products.js
// Then paste the output SQL into D1 console at dash.cloudflare.com
// Or run: wrangler d1 execute kaapav-db --file=products.sql

const fs = require('fs');
const path = require('path');

// ── Category mapping ──
const catMap = {
  'Bracelet':     'bracelet',
  'Necklace':     'necklace',
  'Earrings':     'earrings',
  'Pendant':      'pendant',
  'Rings':        'rings',
  'Pendant Sets': 'pendant_sets',
};

// ── Parse CSV (handles quoted fields with commas) ──
function parseCSV(content) {
  const lines = content.split(/\r?\n/).filter(l => l.trim());
  const headers = parseRow(lines[0]);
  return lines.slice(1).map(line => {
    const values = parseRow(line);
    const obj = {};
    headers.forEach((h, i) => obj[h.trim()] = (values[i] || '').trim());
    return obj;
  });
}

function parseRow(line) {
  const result = [];
  let current = '';
  let inQuotes = false;
  for (let i = 0; i < line.length; i++) {
    if (line[i] === '"') {
      inQuotes = !inQuotes;
    } else if (line[i] === ',' && !inQuotes) {
      result.push(current);
      current = '';
    } else {
      current += line[i];
    }
  }
  result.push(current);
  return result;
}

function escape(str) {
  return (str || '').replace(/'/g, "''");
}

// ── Read CSV ──
const csvPath = path.join(__dirname, 'Whatsapp_Catalogue.csv');
const content = fs.readFileSync(csvPath, 'latin1');
const rows = parseCSV(content).filter(r => r['retailer_id']);

console.log(`Found ${rows.length} products`);

// ── Generate SQL ──
const sqls = [];

// Create table if not exists
sqls.push(`CREATE TABLE IF NOT EXISTS products (
  sku TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  price REAL NOT NULL,
  compare_price REAL,
  category TEXT,
  stock INTEGER DEFAULT 50,
  image_url TEXT,
  images TEXT,
  is_active INTEGER DEFAULT 1,
  is_featured INTEGER DEFAULT 0,
  track_inventory INTEGER DEFAULT 1,
  tags TEXT DEFAULT '[]',
  website_link TEXT,
  material TEXT,
  created_at TEXT DEFAULT (datetime('now')),
  updated_at TEXT DEFAULT (datetime('now'))
);`);

sqls.push('');
sqls.push('-- Products import');
sqls.push('BEGIN TRANSACTION;');

for (const row of rows) {
  const sku          = escape(row['retailer_id']);
  const name         = escape(row['title']);
  const description  = escape(row['description']);
  const price        = parseFloat(row['sale_price']) || parseFloat(row['price']) || 499;
  const comparePrice = parseFloat(row['price']) || 999;
  const catRaw       = row['facebook_product_category'] || 'Bracelet';
  const category     = catMap[catRaw] || 'bracelet';
  const imageUrl     = escape(row['image_link']);
  const images       = JSON.stringify([row['image_link'], row['additional_image_link'], row['additional_image_link1']].filter(Boolean));
  const isActive     = row['status'] === 'active' ? 1 : 0;
  const websiteLink  = escape(row['website_link']);
  const material     = escape(row['material']);

  sqls.push(`INSERT OR REPLACE INTO products (sku, name, description, price, compare_price, category, stock, image_url, images, is_active, is_featured, track_inventory, tags, website_link, material)
VALUES ('${sku}', '${name}', '${description}', ${price}, ${comparePrice}, '${category}', 50, '${imageUrl}', '${escape(images)}', ${isActive}, 0, 1, '[]', '${websiteLink}', '${material}');`);
}

sqls.push('COMMIT;');
sqls.push('');
sqls.push(`SELECT COUNT(*) as imported FROM products;`);

const sql = sqls.join('\n');

// ── Write SQL file ──
fs.writeFileSync(path.join(__dirname, 'products.sql'), sql);
console.log('✅ products.sql generated');
console.log('');
console.log('Next steps:');
console.log('  Option A (recommended):');
console.log('  wrangler d1 execute kaapav-db --file=products.sql');
console.log('');
console.log('  Option B (manual):');
console.log('  1. Open dash.cloudflare.com → D1 → kaapav-db → Console');
console.log('  2. Paste contents of products.sql');
console.log('  3. Run query');
