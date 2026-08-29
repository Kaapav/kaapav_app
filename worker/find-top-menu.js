const fs = require('fs');
const html = fs.readFileSync('kaapav-store/index.html', 'utf8');

const regex = /<ul role="menu" id="top_menu"[\s\S]*?<\/ul>/g;
let m;
while ((m = regex.exec(html)) !== null) {
  console.log('Top menu at:', m.index);
  console.log(m[0]);
}
