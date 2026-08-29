const fs = require('fs');
const path = require('path');

const content = fs.readFileSync(path.join(__dirname, 'live-actual-footer-source.html'), 'utf8');

const f1 = content.match(/<footer id="bottom"[\s\S]*?<\/footer>/i);
const f2 = content.match(/<footer class="kaapav-footer"[\s\S]*?<\/footer>/i);

console.log('Found Footer 1:', !!f1, f1 ? f1[0].length : 0);
console.log('Found Footer 2:', !!f2, f2 ? f2[0].length : 0);

if (f2) {
  console.log('--- FOOTER 2 CONTENT ---');
  console.log(f2[0]);
}

// Let's also check the CSS for .kaapav-footer in the live site
const cssMatch = content.match(/<style[^>]*>[\s\S]*?\.kaapav-footer[\s\S]*?<\/style>/i);
if (cssMatch) {
  console.log('--- FOOTER CSS FOUND ---');
  console.log(cssMatch[0]);
} else {
  // Check inline styles or regex
  const inlineCss = content.match(/\.kaapav-footer\s*\{[\s\S]*?\}/gi);
  console.log('--- INLINE CSS MATCHES ---', inlineCss ? inlineCss.length : 0);
}
