const fs = require('fs');
const content = fs.readFileSync('kaapav-store/index.html', 'utf8');

// Find sections in index.html
const sections = [];
const secRegex = /<section[^>]*>/gi;
let m;
while ((m = secRegex.exec(content)) !== null) {
  sections.push(m[0]);
}
console.log('Total sections in index.html:', sections.length);
sections.slice(0, 10).forEach(s => console.log('Section:', s));

// Find links with images or banner classes
const bannerLinks = [];
const linkRegex = /<a[^>]*href=["']([^"']+)["'][^>]*>[\s\S]*?<\/a>/gi;
while ((m = linkRegex.exec(content)) !== null) {
  if (m[0].includes('<img') || m[0].includes('banner') || m[0].includes('hero') || m[0].includes('btn')) {
    bannerLinks.push({ href: m[1], snippet: m[0].substring(0, 200).replace(/\n/g, ' ') });
  }
}
console.log('Banner/Image/Button links found:', bannerLinks.length);
bannerLinks.slice(0, 10).forEach(b => console.log(b));
