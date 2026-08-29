const fs = require('fs');
const html = fs.readFileSync('kaapav-store/index.html', 'utf8');

const topMenuStart = html.indexOf('id="top_menu"');
if (topMenuStart !== -1) {
  const topMenuEnd = html.indexOf('</ul>', topMenuStart);
  console.log('--- TOP MENU HTML ---');
  console.log(html.substring(topMenuStart, topMenuEnd + 5));
}

const footerIdx = html.indexOf('<footer');
const closingFooterIdx = html.indexOf('</footer>');
console.log('\n--- FOOTER POSITION ---');
console.log('Footer starts at:', footerIdx, 'ends at:', closingFooterIdx);

const afterFooter = html.substring(closingFooterIdx + 9);
console.log('\n--- AFTER FOOTER CONTENT CHECK ---');
console.log('Has feedback after footer:', afterFooter.includes('customer-feedback') || afterFooter.includes('kpv-reviews') || afterFooter.includes('FEEDBACK'));

// Let's print all sections between main and closing body
const bodyEnd = html.indexOf('</body>');
console.log('\n--- ALL OCCURRENCES OF FEEDBACK IN ENTIRE FILE ---');
let pos = 0;
while ((pos = html.toLowerCase().indexOf('feedback', pos)) !== -1) {
  console.log(`Pos ${pos}: ${html.substring(Math.max(0, pos - 40), Math.min(html.length, pos + 80)).replace(/\n/g, ' ')}`);
  pos += 8;
}
