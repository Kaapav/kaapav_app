const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const STORE_DIR = path.join(__dirname, 'kaapav-store');
const COMMIT = '064341fe8fbe67a585676a9c69173235f6142f7a';

const filesToRestore = [
  'about-us/index.html',
  'about-us.html',
  'about/index.html',
  'about.html',
  'privacy-policy/index.html',
  'privacy-policy.html',
  'privacy/index.html',
  'privacy.html',
  'return-policy/index.html',
  'return-policy.html',
  'returns/index.html',
  'shipping-policy/index.html',
  'shipping-policy.html',
  'shipping/index.html',
  'shipping.html',
  'delivery/index.html',
  'terms-of-service/index.html',
  'terms-of-service.html',
  'terms/index.html',
  'terms.html',
  'contact-us/index.html',
  'contact-us.html',
  'contactus/index.html',
  'contactus.html',
  'contact/index.html'
];

function getCleanFooter(prefix) {
  return `
<footer class="kaapav-footer">
  <div class="kaapav-footer-grid">
    
    <div class="kaapav-footer-brand">
      <a href="${prefix}index.html">
        <img src="${prefix}assets/logo.png" alt="KAAPAV" onerror="this.src='https://www.kaapav.com/web/image/website/3/logo/KAAPAV?unique=3432751'" loading="lazy"/>
      </a>
      <div class="kaapav-footer-contact">
        <strong>Contact us:</strong><br/>
        Email: <a href="mailto:care.kaapav@gmail.com" class="footer-contact-link">care.kaapav@gmail.com</a><br/>
        Mobile: <a href="https://wa.me/919148330016?text=Hi" target="_blank" class="footer-contact-link">+91 91483 30016 (WhatsApp Only)</a>
      </div>
    </div>

    <div class="kaapav-footer-col">
      <h4>Jewellery</h4>
      <ul>
        <li><a href="${prefix}category/bracelets/index.html">Bracelets</a></li>
        <li><a href="${prefix}category/necklaces/index.html">Necklace</a></li>
        <li><a href="${prefix}category/earrings/index.html">Earrings</a></li>
        <li><a href="${prefix}category/rings/index.html">Rings</a></li>
        <li><a href="${prefix}category/pendants/index.html">Pendants</a></li>
        <li><a href="${prefix}category/sets/index.html">Pendants-Sets</a></li>
        <li><a href="${prefix}category/bestsellers/index.html">Bestsellers</a></li>
        <li><a href="${prefix}shop/index.html">All Jewellery</a></li>
      </ul>
    </div>

    <div class="kaapav-footer-col">
      <h4>Policies</h4>
      <ul>
        <li><a href="${prefix}shipping-policy/index.html">Shipping & Delivery</a></li>
        <li><a href="${prefix}return-policy/index.html">Return & Refund</a></li>
        <li><a href="${prefix}privacy-policy/index.html">Privacy Policy</a></li>
        <li><a href="${prefix}terms-of-service/index.html">Terms of Service</a></li>
        <li><a href="${prefix}about-us/index.html">About Us</a></li>
      </ul>
    </div>

    <div class="kaapav-footer-col">
      <h4>Follow Us</h4>
      <div class="kaapav-social">
        <a class="ig" href="https://www.instagram.com/kaapavfashionjewellery/" target="_blank" title="Instagram">
          <svg viewBox="0 0 24 24">
            <defs>
              <linearGradient id="igGradHist" x1="0%" y1="0%" x2="100%" y2="100%">
                <stop offset="0%" stop-color="#f58529"></stop>
                <stop offset="50%" stop-color="#dd2a7b"></stop>
                <stop offset="100%" stop-color="#515bd4"></stop>
              </linearGradient>
            </defs>
            <path fill="url(#igGradHist)" d="M7 2h10a5 5 0 0 1 5 5v10a5 5 0 0 1-5 5H7a5 5 0 0 1-5-5V7a5 5 0 0 1 5-5zm5 5a5 5 0 1 0 0 10 5 5 0 0 0 0-10zm6.5-.9a1.1 1.1 0 1 0 0 2.2 1.1 1.1 0 0 0 0-2.2z"></path>
          </svg>
        </a>
        <a class="fb" href="https://www.facebook.com/kaapavfashionjewellery" target="_blank" title="Facebook">
          <svg viewBox="0 0 320 512">
            <path fill="#1877F2" d="M279.14 288l14.22-92.66h-88.91V127.41c0-25.35 12.42-50.06 52.24-50.06h40.42V6.26S260.43 0 225.36 0c-73.22 0-121.08 44.38-121.08 124.72v70.62H22.89V288h81.39v224h100.2V288z"></path>
          </svg>
        </a>
      </div>
    </div>

  </div>

  <div class="kaapav-seo-footer"> 
    <h5>Popular Searches</h5>
    <p>
      <a href="${prefix}category/bracelets/index.html">Bracelets</a> |
      <a href="${prefix}category/earrings/index.html">Earrings</a> |
      <a href="${prefix}category/rings/index.html">Rings</a> |
      <a href="${prefix}category/necklaces/index.html">Necklaces</a> |
      <a href="${prefix}category/pendants/index.html">Pendants</a> |
      <a href="${prefix}shop/index.html">All Jewellery</a>
    </p>

    <h5>Women's Artificial Jewellery</h5>
    <p>
      <a href="${prefix}category/earrings/index.html">Earrings for Women</a> |
      <a href="${prefix}category/rings/index.html">Rings for Women</a> |
      <a href="${prefix}category/bracelets/index.html">Bracelets for Women</a> |
      <a href="${prefix}category/necklaces/index.html">Necklaces for Women</a> |
      <a href="${prefix}category/pendants/index.html">Pendants for Women</a>
    </p>

    <h5>Jewellery by Occasion</h5>
    <p>
      <a href="${prefix}category/rings/index.html">Engagement Rings</a> |
      <a href="${prefix}category/earrings/index.html">Party Wear Earrings</a> |
      <a href="${prefix}category/bracelets/index.html">Gift Bracelets</a> |
      <a href="${prefix}category/necklaces/index.html">Festive Necklaces</a>
    </p>

    <h5>Gifting Jewellery</h5>
    <p>
      <a href="${prefix}category/rings/index.html">Gifting Rings</a> |
      <a href="${prefix}category/necklaces/index.html">Gifting Necklaces</a> |
      <a href="${prefix}category/bracelets/index.html">Gifting Bracelets</a> |
      <a href="${prefix}category/pendants/index.html">Gifting Pendants</a>
    </p>

    <h5>Trending Jewellery</h5>
    <p>
      <a href="${prefix}category/earrings/index.html">Minimal Earrings</a> |
      <a href="${prefix}category/rings/index.html">Dailywear Rings</a> |
      <a href="${prefix}category/bracelets/index.html">Lightweight Bracelets</a> |
      <a href="${prefix}category/necklaces/index.html">Modern Necklaces</a>
    </p>
  </div>

  <div class="kaapav-footer-bottom">
    &copy; 2026 KAAPAV Fashion Jewellery. All rights reserved.
  </div>
</footer>
`;
}

const CLEAN_FOOTER_CSS = `
<style id="kaapav-live-actual-footer-css">
.kaapav-footer {
  --gold: #c6a26a;
  --ink: #1c1c1c;
  --muted: #6f6f6f;
  background: #fffdf9;
  border-top: 1px solid rgba(198,162,106,0.35);
  padding: 64px 20px 32px;
  font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
}
.kaapav-footer-grid {
  max-width: 1200px;
  margin: 0 auto 32px;
  display: grid;
  grid-template-columns: 1.2fr 1fr 1fr 1fr;
  gap: 40px;
  align-items: start;
}
.kaapav-footer-brand {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  gap: 10px;
}
.kaapav-footer-brand img { max-width: 130px; height: auto; margin-bottom: 8px; }
.kaapav-footer-contact { font-size: 13.5px; color: var(--muted); line-height: 1.8; }
.kaapav-footer-contact a.footer-contact-link { color: var(--ink); text-decoration: none; font-weight: 500; transition: color .3s ease; }
.kaapav-footer-contact a.footer-contact-link:hover { color: var(--gold); text-decoration: underline; }
.kaapav-footer-col h4 {
  font-size: 13px;
  letter-spacing: .22em;
  text-transform: uppercase;
  color: var(--ink);
  margin-bottom: 18px;
  display: inline-block;
  padding-bottom: 6px;
  border-bottom: 2px solid var(--gold);
}
.kaapav-footer-col ul { list-style: none; padding: 0; margin: 0; }
.kaapav-footer-col li { margin-bottom: 10px; }
.kaapav-footer-col ul a { font-size: 13.5px; color: var(--muted); text-decoration: none; transition: color .3s ease; }
.kaapav-footer-col ul a:hover { color: var(--gold); }
.kaapav-social { display: flex; gap: 12px; margin-top: 12px; }
.kaapav-social a {
  width: 38px;
  height: 38px;
  background: #ffffff;
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 4px 12px rgba(0,0,0,0.08);
  border: 1px solid rgba(198,162,106,0.25);
  transition: transform .3s ease, box-shadow .3s ease;
}
.kaapav-social a:hover { transform: translateY(-3px); box-shadow: 0 8px 20px rgba(198,162,106,0.3); }
.kaapav-social svg { width: 18px; height: 18px; }
.kaapav-seo-footer {
  max-width: 1200px;
  margin: 40px auto 0;
  padding-top: 32px;
  border-top: 1px solid rgba(198,162,106,0.25);
  font-size: 13px;
  color: var(--muted);
  text-align: center;
}
.kaapav-seo-footer h5 { font-size: 12px; letter-spacing: .18em; text-transform: uppercase; color: var(--ink); margin-bottom: 8px; text-align: center; }
.kaapav-seo-footer p { line-height: 1.8; margin-bottom: 20px; text-align: center; }
.kaapav-seo-footer a { color: var(--muted); text-decoration: none; transition: color .25s ease; }
.kaapav-seo-footer a:hover { color: var(--gold); }
.kaapav-footer-bottom {
  border-top: 1px solid rgba(198,162,106,0.25);
  padding-top: 20px;
  margin-top: 20px;
  text-align: center;
  font-size: 12.5px;
  color: #888;
}
@media (max-width: 900px) { .kaapav-footer-grid { grid-template-columns: 1fr 1fr; gap: 28px; } }
@media (max-width: 560px) {
  .kaapav-footer { padding: 48px 16px 28px; }
  .kaapav-footer-grid { grid-template-columns: 1fr; text-align: center; }
  .kaapav-footer-brand { align-items: center; text-align: center; }
  .kaapav-social { justify-content: center; }
}
</style>
`;

filesToRestore.forEach(relFile => {
  try {
    const gitPath = `worker/kaapav-store/${relFile}`;
    const raw = execSync(`git show ${COMMIT}:${gitPath}`, { encoding: 'utf8' });
    const fullPath = path.join(STORE_DIR, relFile);
    const dir = path.dirname(fullPath);
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });

    let content = raw;
    const rel = path.relative(STORE_DIR, path.dirname(fullPath));
    const depth = (!rel || rel === '.') ? 0 : rel.split(path.sep).length;
    const prefix = depth === 0 ? './' : '../'.repeat(depth);

    // Replace footer with clean depth-relative footer
    content = content.replace(/<footer[\s\S]*?<\/footer>/gi, '');
    if (content.includes('</body>')) {
      content = content.replace('</body>', getCleanFooter(prefix) + '\n</body>');
    }
    if (!content.includes('kaapav-live-actual-footer-css')) {
      content = content.replace('</head>', CLEAN_FOOTER_CSS + '\n</head>');
    }

    fs.writeFileSync(fullPath, content, 'utf8');
    console.log('Successfully restored from history:', relFile);
  } catch (err) {
    console.error('Error restoring', relFile, err.message);
  }
});

console.log('All previous policies restored from repository history!');
