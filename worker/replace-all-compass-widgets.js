const fs = require('fs');
const path = require('path');

const indexPath = path.join(__dirname, 'kaapav-store', 'index.html');
let html = fs.readFileSync(indexPath, 'utf8');

const SPOTLIGHT_HTML = `
<!-- ============================================
     FEATURED BESTSELLERS SPOTLIGHT (CLEAN & LUXURY)
     ============================================ -->
<section class="kaapav-bestsellers-spotlight" id="featured-bestsellers">
  <div class="bestsellers-spotlight-inner">
    
    <div class="spotlight-header">
      <span class="spotlight-eyebrow">Handcrafted Elegance</span>
      <h2 class="spotlight-title">Featured Bestsellers</h2>
      <p class="spotlight-subtitle">Our most coveted 18K anti-tarnish jewellery pieces</p>
    </div>

    <div class="spotlight-grid">
      <div class="spotlight-card">
        <div class="spotlight-card-media">
          <a href="./product/index.html?sku=KPV-BR-001">
            <img src="https://pub-929fe7fe40a94b96b00ec1ee6a858564.r2.dev/products/KPV-BR-001/images/0.jpg" alt="Dual Butterfly Charm Bangle" loading="lazy" onerror="this.src='./assets/logo.png'">
          </a>
          <span class="spotlight-discount-badge">50% OFF</span>
        </div>
        <div class="spotlight-card-body">
          <div class="spotlight-category">Bracelets</div>
          <a href="./product/index.html?sku=KPV-BR-001" class="spotlight-card-title">Dual Butterfly Charm Bangle – Rose Gold</a>
          <div class="spotlight-price-row">
            <span class="spotlight-price">₹ 499.00</span>
            <span class="spotlight-mrp">₹ 999.00</span>
          </div>
          <div class="spotlight-cta-group">
            <button class="spotlight-btn-add" onclick="window.KaapavStore.addToCart('KPV-BR-001', 1, true)">Add to Bag</button>
            <a href="./product/index.html?sku=KPV-BR-001" class="spotlight-btn-view">View</a>
          </div>
        </div>
      </div>

      <div class="spotlight-card">
        <div class="spotlight-card-media">
          <a href="./product/index.html?sku=KPV-NK-001">
            <img src="https://pub-929fe7fe40a94b96b00ec1ee6a858564.r2.dev/products/KPV-NK-001/images/0.jpg" alt="Sparkling Floral Cluster Pendant Necklace" loading="lazy" onerror="this.src='./assets/logo.png'">
          </a>
          <span class="spotlight-discount-badge">50% OFF</span>
        </div>
        <div class="spotlight-card-body">
          <div class="spotlight-category">Necklaces</div>
          <a href="./product/index.html?sku=KPV-NK-001" class="spotlight-card-title">Sparkling Floral Cluster Pendant Necklace</a>
          <div class="spotlight-price-row">
            <span class="spotlight-price">₹ 499.00</span>
            <span class="spotlight-mrp">₹ 999.00</span>
          </div>
          <div class="spotlight-cta-group">
            <button class="spotlight-btn-add" onclick="window.KaapavStore.addToCart('KPV-NK-001', 1, true)">Add to Bag</button>
            <a href="./product/index.html?sku=KPV-NK-001" class="spotlight-btn-view">View</a>
          </div>
        </div>
      </div>

      <div class="spotlight-card">
        <div class="spotlight-card-media">
          <a href="./product/index.html?sku=KPV-ER-001">
            <img src="https://pub-929fe7fe40a94b96b00ec1ee6a858564.r2.dev/products/KPV-ER-001/images/0.jpg" alt="Black & Clear CZ Floral Stud Earrings" loading="lazy" onerror="this.src='./assets/logo.png'">
          </a>
          <span class="spotlight-discount-badge">50% OFF</span>
        </div>
        <div class="spotlight-card-body">
          <div class="spotlight-category">Earrings</div>
          <a href="./product/index.html?sku=KPV-ER-001" class="spotlight-card-title">Black & Clear CZ Floral Stud Earrings</a>
          <div class="spotlight-price-row">
            <span class="spotlight-price">₹ 299.00</span>
            <span class="spotlight-mrp">₹ 599.00</span>
          </div>
          <div class="spotlight-cta-group">
            <button class="spotlight-btn-add" onclick="window.KaapavStore.addToCart('KPV-ER-001', 1, true)">Add to Bag</button>
            <a href="./product/index.html?sku=KPV-ER-001" class="spotlight-btn-view">View</a>
          </div>
        </div>
      </div>

      <div class="spotlight-card">
        <div class="spotlight-card-media">
          <a href="./product/index.html?sku=KPV-RG-001">
            <img src="https://pub-929fe7fe40a94b96b00ec1ee6a858564.r2.dev/products/KPV-RG-001/images/0.jpg" alt="Rose Prism Solitaire Ring" loading="lazy" onerror="this.src='./assets/logo.png'">
          </a>
          <span class="spotlight-discount-badge">40% OFF</span>
        </div>
        <div class="spotlight-card-body">
          <div class="spotlight-category">Rings</div>
          <a href="./product/index.html?sku=KPV-RG-001" class="spotlight-card-title">Rose Prism Solitaire Ring – Yellow Gold</a>
          <div class="spotlight-price-row">
            <span class="spotlight-price">₹ 299.00</span>
            <span class="spotlight-mrp">₹ 499.00</span>
          </div>
          <div class="spotlight-cta-group">
            <button class="spotlight-btn-add" onclick="window.KaapavStore.addToCart('KPV-RG-001', 1, true)">Add to Bag</button>
            <a href="./product/index.html?sku=KPV-RG-001" class="spotlight-btn-view">View</a>
          </div>
        </div>
      </div>
    </div>

    <div class="spotlight-footer-cta">
      <a href="./category/bestsellers/index.html" class="spotlight-btn-explore">
        View All Bestsellers <span>&rarr;</span>
      </a>
    </div>

  </div>
</section>
`;

// Replace all occurrences of <section class="compass-realm"...</section> everywhere
while (html.includes('<section class="compass-realm"')) {
  const start = html.indexOf('<section class="compass-realm"');
  const end = html.indexOf('</section>', start) + 10;
  html = html.substring(0, start) + SPOTLIGHT_HTML + html.substring(end);
}

// Also replace inside any <template class="s_embed_code_saved"> where compass-realm might be wrapped
html = html.replace(/<section class="compass-realm"[\s\S]*?<\/section>/gi, SPOTLIGHT_HTML);

// Remove duplicate spotlight sections if more than 1 exists
const parts = html.split('<section class="kaapav-bestsellers-spotlight" id="featured-bestsellers">');
if (parts.length > 2) {
  let cleaned = parts[0] + '<section class="kaapav-bestsellers-spotlight" id="featured-bestsellers">' + parts[1];
  for (let i = 2; i < parts.length; i++) {
    const afterSection = parts[i].indexOf('</section>');
    if (afterSection !== -1) {
      cleaned += parts[i].substring(afterSection + 10);
    } else {
      cleaned += parts[i];
    }
  }
  html = cleaned;
}

fs.writeFileSync(indexPath, html, 'utf8');

console.log('Successfully replaced ALL instances of compass-realm with the Featured Bestsellers spotlight!');
