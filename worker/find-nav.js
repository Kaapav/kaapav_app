const fs = require('fs');
const html = fs.readFileSync('kaapav-store/index.html', 'utf8');

let pos = 0;
while ((pos = html.indexOf('ALL JEWELLERY', pos)) !== -1) {
  console.log(`Pos ${pos}: ${html.substring(Math.max(0, pos - 100), Math.min(html.length, pos + 200)).replace(/\n/g, ' ')}`);
  pos += 13;
}
