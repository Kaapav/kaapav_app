const fs = require('fs');
const path = require('path');

const CATEGORIES = [
  {
    slug: 'earrings',
    title: 'Earrings Collection',
    eyebrow: 'Fine Studs, Hoops & Drops',
    desc: 'Explore lightweight studs, classic hoops, and shimmering chandeliers crafted in 18K anti-tarnish gold.',
    filter: 'earrings',
    outDirs: ['category/earrings', 'earrings']
  },
  {
    slug: 'necklaces',
    title: 'Necklaces Collection',
    eyebrow: 'Chains, Chokers & Layering',
    desc: 'Elevate your neckline with anti-tarnish chains, delicate layering necklaces, and statement collars.',
    filter: 'necklace',
    outDirs: ['category/necklaces', 'necklaces']
  },
  {
    slug: 'bracelets',
    title: 'Bracelets & Cuffs',
    eyebrow: 'Bangles, Cuffs & Charms',
    desc: 'Lustrous anti-tarnish cuffs, charm bracelets, and adjustable bangles designed for daily elegance.',
    filter: 'bracelet',
    outDirs: ['category/bracelets', 'bracelets']
  },
  {
    slug: 'rings',
    title: 'Rings Collection',
    eyebrow: 'Adjustable Bands & Solitaires',
    desc: 'Stackable minimalist rings, sparkling CZ halos, and adjustable statement bands made for sensitive skin.',
    filter: 'ring',
    outDirs: ['category/rings', 'rings']
  },
  {
    slug: 'pendants',
    title: 'Pendants Collection',
    eyebrow: 'Four Leaf Clovers & Charms',
    desc: 'Delicate lucky charms, shimmering solitaires, and symbolic pendants in 18K anti-tarnish gold finish.',
    filter: 'pendant',
    outDirs: ['category/pendants', 'pendants']
  },
  {
    slug: 'sets',
    title: 'Pendant & Jewellery Sets',
    eyebrow: 'Curated Matching Pairs',
    desc: 'Thoughtfully paired necklace and earring sets presented in luxury velvet pouches for gifting.',
    filter: 'set',
    outDirs: ['category/sets', 'sets']
  },
  {
    slug: 'bestsellers',
    title: 'Trending Bestsellers',
    eyebrow: 'Most Loved Pieces',
    desc: 'Our highest-rated, most celebrated artificial fine jewellery pieces chosen by thousands of women.',
    filter: 'bestseller',
    outDirs: ['category/bestsellers', 'bestsellers']
  },
  {
    slug: 'shop',
    title: 'All Fine Jewellery',
    eyebrow: 'Complete 165+ Piece Collection',
    desc: 'Browse our complete catalog of 18K gold-plated, anti-tarnish, and waterproof fine artificial jewellery.',
    filter: 'all',
    outDirs: ['shop']
  }
];

function generateCategoryHtml(cat) {
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no">
  <meta name="theme-color" content="#FAF7F2">
  <meta name="robots" content="index, follow, max-image-preview:large">
  <title>${cat.title} | KAAPAV Fine Jewellery</title>
  <meta name="description" content="${cat.desc}">
  <link rel="canonical" href="https://www.kaapav.com/${cat.slug === 'shop' ? 'shop/index.html' : 'category/' + cat.slug + '/index.html'}">
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Cormorant+Garamond:ital,wght@0,400;0,500;0,600;0,700;1,400;1,600&family=Jost:wght@300;400;500;600;700&display=swap" rel="stylesheet">
  
  <!-- KAAPAV Store Commerce Engine -->
  <script src="/assets/kaapav-store-engine.js"></script>

  <style>
    :root {
      --bg-mesh: radial-gradient(at 0% 0%, rgba(247, 239, 227, 0.95) 0, transparent 55%),
                 radial-gradient(at 100% 0%, rgba(238, 220, 190, 0.85) 0, transparent 50%),
                 radial-gradient(at 50% 40%, rgba(253, 250, 245, 1) 0, transparent 100%),
                 #FAF7F2;
      --gold: #C49432;
      --gold-l: #E2B755;
      --gold-d: #9A7424;
      --gold-grad: linear-gradient(135deg, #F5D77F 0%, #C49432 50%, #9A7424 100%);
      --maroon: #5C1324;
      --maroon-d: #380B16;
      --ink: #1C1917;
      --ink-soft: #44403C;
      --muted: #78716C;
      --border-gold: rgba(196, 148, 50, 0.22);
      --shadow-sm: 0 4px 16px rgba(60, 40, 20, 0.04);
      --shadow-md: 0 12px 32px rgba(60, 40, 20, 0.08);
      --shadow-lg: 0 20px 50px rgba(60, 40, 20, 0.12);
      --serif: "Cormorant Garamond", Georgia, serif;
      --sans: "Jost", -apple-system, BlinkMacSystemFont, sans-serif;
    }

    * { box-sizing: border-box; margin: 0; padding: 0; -webkit-tap-highlight-color: transparent; }
    body {
      background: var(--bg-mesh);
      background-attachment: fixed;
      color: var(--ink);
      font-family: var(--sans);
      min-height: 100vh;
      display: flex;
      flex-direction: column;
      overflow-x: hidden;
    }
    a { color: inherit; text-decoration: none; cursor: pointer; }
    button { font: inherit; cursor: pointer; transition: all 0.25s cubic-bezier(0.16, 1, 0.3, 1); }
    img { display: block; max-width: 100%; }
    .shell { width: min(1280px, calc(100% - 32px)); margin: auto; }

    /* Top Announcement Bar */
    .top-announcement-bar {
      background: linear-gradient(90deg, #5C1324, #7A1C30, #5C1324);
      color: #FDF4DC;
      padding: 8px 16px;
      text-align: center;
      font-size: 12px;
      font-weight: 500;
      letter-spacing: 0.06em;
      text-transform: uppercase;
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 12px;
      z-index: 1000;
    }
    .top-announcement-bar strong { color: #F5D77F; font-weight: 700; }

    /* Top Navigation Header */
    .kaapav-main-header {
      background: rgba(250, 247, 242, 0.94);
      backdrop-filter: blur(14px);
      border-bottom: 1px solid var(--border-gold);
      position: sticky;
      top: 0;
      z-index: 999;
      box-shadow: var(--shadow-sm);
    }
    .header-shell {
      max-width: 1320px;
      margin: 0 auto;
      padding: 10px 24px;
      display: flex;
      align-items: center;
      justify-content: space-between;
      min-height: 72px;
    }
    .header-brand-wrap { display: flex; align-items: center; text-decoration: none; }
    .header-logo-img { height: 46px; width: auto; object-fit: contain; }
    .header-nav-menu { display: flex; align-items: center; gap: clamp(14px, 2vw, 32px); list-style: none; margin: 0; padding: 0; }
    .nav-link-item {
      font-family: var(--sans);
      font-size: 12.5px;
      letter-spacing: 0.12em;
      font-weight: 600;
      text-transform: uppercase;
      color: #9A7424;
      text-decoration: none;
      padding: 8px 0;
      display: inline-flex;
      align-items: center;
      gap: 4px;
      transition: color 0.2s ease;
    }
    .nav-link-item:hover { color: var(--maroon); }
    .nav-dropdown-wrap { position: relative; }
    .nav-dropdown-menu {
      position: absolute;
      top: 100%;
      left: 0;
      background: #FFF;
      border: 1px solid var(--border-gold);
      border-radius: 14px;
      padding: 10px 0;
      min-width: 200px;
      box-shadow: var(--shadow-lg);
      display: none;
      flex-direction: column;
      z-index: 1000;
    }
    .nav-dropdown-wrap:hover .nav-dropdown-menu { display: flex; }
    .nav-dropdown-menu a { padding: 9px 18px; font-size: 12.5px; color: var(--ink-soft); text-decoration: none; font-weight: 500; }
    .nav-dropdown-menu a:hover { background: #FAF5EB; color: var(--gold-d); }
    
    .header-actions-wrap { display: flex; align-items: center; gap: 12px; }
    .hdr-btn-circle {
      width: 42px;
      height: 42px;
      border-radius: 50%;
      background: #FFF;
      border: 1px solid var(--border-gold);
      display: flex;
      align-items: center;
      justify-content: center;
      cursor: pointer;
      position: relative;
      transition: all 0.2s ease;
    }
    .hdr-btn-circle:hover { background: #FAF5EB; transform: translateY(-1px); }
    .hdr-cart-badge {
      position: absolute;
      top: -3px;
      right: -3px;
      background: var(--maroon);
      color: #fff;
      font-size: 9.5px;
      font-weight: 700;
      border-radius: 10px;
      padding: 2px 6px;
      display: none;
    }
    @media(max-width:992px){ .header-nav-menu { display:none!important; } }

    /* Category Hero & Filter Controls */
    .shop-hero-section {
      padding: clamp(30px, 4.5vw, 54px) 0 24px;
      text-align: center;
    }
    .shop-hero-eyebrow {
      font-size: 11.5px;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 0.16em;
      color: var(--gold-d);
      margin-bottom: 8px;
    }
    .shop-hero-title {
      font-family: var(--serif);
      font-size: clamp(34px, 5vw, 52px);
      font-weight: 600;
      color: var(--ink);
      margin-bottom: 10px;
    }
    .shop-hero-subtitle {
      font-size: 14.5px;
      color: var(--muted);
      max-width: 620px;
      margin: 0 auto 24px;
      line-height: 1.6;
    }

    /* Category Pills Nav */
    .cat-nav-row {
      display: flex;
      justify-content: center;
      gap: 10px;
      flex-wrap: wrap;
      margin-bottom: 30px;
    }
    .cat-nav-btn {
      padding: 8px 18px;
      border-radius: 24px;
      font-size: 12.5px;
      font-weight: 600;
      text-transform: uppercase;
      letter-spacing: 0.06em;
      background: #FFF;
      color: var(--ink-soft);
      border: 1px solid var(--border-gold);
      box-shadow: var(--shadow-sm);
      transition: all 0.2s ease;
    }
    .cat-nav-btn:hover { background: #FAF5EB; border-color: var(--gold); }
    .cat-nav-btn.active {
      background: var(--gold-grad);
      color: #1A1A1A;
      border-color: var(--gold);
      box-shadow: 0 4px 14px rgba(196,148,50,0.3);
      font-weight: 700;
    }

    /* Interactive Filter Bar */
    .shop-filter-bar {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 14px;
      padding: 14px 20px;
      background: #FFF;
      border: 1px solid var(--border-gold);
      border-radius: 18px;
      box-shadow: var(--shadow-sm);
      margin-bottom: 32px;
      flex-wrap: wrap;
    }
    .filter-pills-wrap { display: flex; gap: 8px; overflow-x: auto; padding-bottom: 2px; }
    .price-pill {
      padding: 7px 14px;
      border-radius: 20px;
      font-size: 12px;
      font-weight: 600;
      background: #FAF7F2;
      border: 1px solid var(--border-gold);
      color: var(--ink-soft);
      cursor: pointer;
      white-space: nowrap;
      transition: all 0.2s ease;
    }
    .price-pill:hover { background: #FAF5EB; border-color: var(--gold); }
    .price-pill.active { background: #1C1917; color: #F5D77F; border-color: #1C1917; }

    .sort-search-wrap { display: flex; align-items: center; gap: 12px; flex-wrap: wrap; }
    .search-box-input {
      padding: 8px 14px;
      border-radius: 10px;
      border: 1px solid var(--border-gold);
      font-size: 13px;
      outline: none;
      background: #FAF7F2;
      width: 180px;
    }
    .search-box-input:focus { border-color: var(--gold); background: #FFF; }
    .sort-select {
      padding: 8px 14px;
      border-radius: 10px;
      border: 1px solid var(--border-gold);
      font-size: 13px;
      outline: none;
      background: #FAF7F2;
      color: var(--ink);
      cursor: pointer;
    }

    /* Product Grid */
    .products-grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(260px, 1fr));
      gap: clamp(16px, 2.5vw, 26px);
      margin-bottom: 80px;
    }
    .product-card {
      background: #FFF;
      border: 1px solid var(--border-gold);
      border-radius: 20px;
      overflow: hidden;
      display: flex;
      flex-direction: column;
      box-shadow: var(--shadow-sm);
      transition: all 0.3s cubic-bezier(0.16, 1, 0.3, 1);
      position: relative;
    }
    .product-card:hover { transform: translateY(-4px); box-shadow: var(--shadow-md); border-color: var(--gold); }
    .card-media-wrap { width: 100%; aspect-ratio: 1; background: #FAF7F2; overflow: hidden; position: relative; }
    .card-media-wrap img { width: 100%; height: 100%; object-fit: cover; transition: transform 0.4s ease; }
    .product-card:hover .card-media-wrap img { transform: scale(1.04); }
    .card-discount-tag { position: absolute; top: 12px; left: 12px; background: #064E3B; color: #A7F3D0; font-size: 10.5px; font-weight: 700; padding: 3px 8px; border-radius: 6px; }
    .card-content { padding: 18px; display: flex; flex-direction: column; flex: 1; }
    .card-category { font-size: 11px; text-transform: uppercase; letter-spacing: 0.08em; color: var(--gold-d); font-weight: 700; margin-bottom: 4px; }
    .card-title { font-family: var(--serif); font-size: 19px; font-weight: 600; color: var(--ink); line-height: 1.3; margin-bottom: 8px; flex: 1; display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; }
    .card-price-row { display: flex; align-items: baseline; gap: 8px; margin-bottom: 14px; }
    .card-price { font-size: 20px; font-weight: 700; color: var(--ink); }
    .card-mrp { font-size: 13.5px; text-decoration: line-through; color: var(--muted); }
    .card-cta-group { display: flex; gap: 8px; margin-top: auto; }
    .card-btn-add { flex: 1; padding: 11px; background: var(--gold-grad); color: #1A1A1A; border: none; border-radius: 10px; font-size: 12.5px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.04em; }
    .card-btn-add:hover { filter: brightness(1.06); }
    .card-btn-view { padding: 11px 16px; background: #FAF7F2; border: 1px solid #D6D3D1; border-radius: 10px; font-size: 12px; font-weight: 600; color: var(--ink-soft); }

    /* Footer */
    .kaapav-luxury-footer { background: var(--maroon-d); color: #F5EBE1; padding: 60px 0 30px; margin-top: auto; }
    .footer-grid { display: grid; grid-template-columns: 2fr 1fr 1fr 1.5fr; gap: 40px; max-width: 1280px; margin: 0 auto 40px; padding: 0 24px; }
    .footer-col h4 { font-family: var(--serif); font-size: 20px; color: #F5D77F; margin-bottom: 18px; }
    .footer-col ul { list-style: none; display: flex; flex-direction: column; gap: 10px; }
    .footer-col a { color: #D6C7B2; font-size: 13.5px; transition: color 0.2s; }
    .footer-col a:hover { color: #FFF; }
    .footer-bottom { border-top: 1px solid rgba(226,183,85,0.2); text-align: center; padding-top: 24px; font-size: 12.5px; color: #A89F91; }

    @media(max-width:768px) {
      .footer-grid { grid-template-columns: 1fr 1fr; gap: 30px; }
      .shop-filter-bar { flex-direction: column; align-items: stretch; }
      .sort-search-wrap { justify-content: space-between; }
      .search-box-input { width: 100%; }
    }
    @media(max-width:540px) {
      .footer-grid { grid-template-columns: 1fr; }
      .products-grid { grid-template-columns: repeat(2, 1fr); gap: 12px; }
      .card-content { padding: 12px; }
      .card-title { font-size: 15px; }
      .card-price { font-size: 16px; }
      .card-mrp { font-size: 11px; }
      .card-btn-view { display: none; }
    }
  </style>
</head>
<body>

  <!-- Top Announcement Bar -->
  <div class="top-announcement-bar">
    <span>✨ Free Express Delivery on all orders above <strong>₹498</strong> &bull; Anti-Tarnish 18K Gold Plated</span>
  </div>

  <!-- Top Sticky Navigation -->
  <header class="kaapav-main-header">
    <div class="header-shell">
      <a href="/index.html" class="header-brand-wrap">
        <img src="/assets/logo.png" alt="KAAPAV Logo" class="header-logo-img" onerror="this.src='/assets/kaapav-logo.png'">
      </a>

      <nav class="header-nav-menu">
        <a href="/shop/index.html" class="nav-link-item ${cat.slug === 'shop' ? 'active' : ''}">All Jewellery</a>
        <div class="nav-dropdown-wrap">
          <a href="/shop/index.html" class="nav-link-item">Categories ▾</a>
          <div class="nav-dropdown-menu">
            <a href="/category/earrings/index.html">Earrings</a>
            <a href="/category/necklaces/index.html">Necklaces</a>
            <a href="/category/bracelets/index.html">Bracelets</a>
            <a href="/category/rings/index.html">Rings</a>
            <a href="/category/pendants/index.html">Pendants</a>
            <a href="/category/sets/index.html">Sets</a>
          </div>
        </div>
        <a href="/category/bestsellers/index.html" class="nav-link-item ${cat.slug === 'bestsellers' ? 'active' : ''}">Bestsellers</a>
        <a href="/about-us/index.html" class="nav-link-item">Our Story</a>
        <a href="/contact-us/index.html" class="nav-link-item">Contact</a>
      </nav>

      <div class="header-actions-wrap">
        <button class="hdr-btn-circle" onclick="document.getElementById('shopSearchInput')?.focus()" title="Search">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#1C1917" stroke-width="2"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/></svg>
        </button>
        <button class="hdr-btn-circle" onclick="window.KaapavStore.openCartDrawer()" title="Shopping Bag">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#1C1917" stroke-width="2"><path d="M6 2 3 6v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6l-3-4Z"/><path d="M3 6h18"/><path d="M16 10a4 4 0 0 1-8 0"/></svg>
          <span class="hdr-cart-badge" id="hdrCartCount">0</span>
        </button>
      </div>
    </div>
  </header>

  <main class="shell">
    <section class="shop-hero-section">
      <div class="shop-hero-eyebrow">${cat.eyebrow}</div>
      <h1 class="shop-hero-title">${cat.title}</h1>
      <p class="shop-hero-subtitle">${cat.desc}</p>

      <!-- Category Switcher Pills -->
      <div class="cat-nav-row">
        <a href="/shop/index.html" class="cat-nav-btn ${cat.slug === 'shop' ? 'active' : ''}">All</a>
        <a href="/category/earrings/index.html" class="cat-nav-btn ${cat.slug === 'earrings' ? 'active' : ''}">Earrings</a>
        <a href="/category/necklaces/index.html" class="cat-nav-btn ${cat.slug === 'necklaces' ? 'active' : ''}">Necklaces</a>
        <a href="/category/bracelets/index.html" class="cat-nav-btn ${cat.slug === 'bracelets' ? 'active' : ''}">Bracelets</a>
        <a href="/category/rings/index.html" class="cat-nav-btn ${cat.slug === 'rings' ? 'active' : ''}">Rings</a>
        <a href="/category/pendants/index.html" class="cat-nav-btn ${cat.slug === 'pendants' ? 'active' : ''}">Pendants</a>
        <a href="/category/sets/index.html" class="cat-nav-btn ${cat.slug === 'sets' ? 'active' : ''}">Sets</a>
        <a href="/category/bestsellers/index.html" class="cat-nav-btn ${cat.slug === 'bestsellers' ? 'active' : ''}">🔥 Bestsellers</a>
      </div>
    </section>

    <!-- Filter & Sort Bar -->
    <div class="shop-filter-bar">
      <div class="filter-pills-wrap">
        <button class="price-pill active" onclick="setPriceFilter('all', this)">All Prices</button>
        <button class="price-pill" onclick="setPriceFilter('under499', this)">Under ₹499</button>
        <button class="price-pill" onclick="setPriceFilter('499to799', this)">₹499 - ₹799</button>
        <button class="price-pill" onclick="setPriceFilter('above799', this)">₹799+</button>
      </div>

      <div class="sort-search-wrap">
        <input type="text" id="shopSearchInput" class="search-box-input" placeholder="Search ${cat.slug}..." oninput="handleSearch(this.value)">
        <select id="sortSelect" class="sort-select" onchange="handleSort(this.value)">
          <option value="featured">Featured</option>
          <option value="price_low">Price: Low to High</option>
          <option value="price_high">Price: High to Low</option>
          <option value="discount">Highest Discount</option>
        </select>
      </div>
    </div>

    <!-- Product Grid -->
    <div class="products-grid" id="shopProductGrid">
      <div style="grid-column:1/-1;text-align:center;padding:60px 20px;color:var(--muted)">
        Loading ${cat.title}...
      </div>
    </div>
  </main>

  <!-- Luxury Maroon Footer -->
  <footer class="kaapav-luxury-footer">
    <div class="footer-grid">
      <div class="footer-col">
        <h4 style="font-size:24px;letter-spacing:0.05em">KAAPAV</h4>
        <p style="font-size:13.5px;color:#D6C7B2;line-height:1.7;margin-bottom:16px">
          Elevating everyday modern elegance with handcrafted anti-tarnish fashion jewellery made for contemporary style.
        </p>
        <p style="font-size:12px;color:#A89F91">GST Registered &bull; Made with Love in India</p>
      </div>

      <div class="footer-col">
        <h4>Collections</h4>
        <ul>
          <li><a href="/category/earrings/index.html">Earrings</a></li>
          <li><a href="/category/necklaces/index.html">Necklaces</a></li>
          <li><a href="/category/bracelets/index.html">Bracelets</a></li>
          <li><a href="/category/rings/index.html">Rings</a></li>
          <li><a href="/category/pendants/index.html">Pendants</a></li>
          <li><a href="/category/sets/index.html">Pendant Sets</a></li>
        </ul>
      </div>

      <div class="footer-col">
        <h4>Customer Care</h4>
        <ul>
          <li><a href="/shipping-policy/index.html">Shipping & Delivery</a></li>
          <li><a href="/return-policy/index.html">Returns & Exchanges</a></li>
          <li><a href="/privacy-policy/index.html">Privacy Policy</a></li>
          <li><a href="/terms-of-service/index.html">Terms of Service</a></li>
          <li><a href="/faq/index.html">FAQ & Help</a></li>
        </ul>
      </div>

      <div class="footer-col">
        <h4>Connect & Order</h4>
        <p style="font-size:13px;color:#D6C7B2;margin-bottom:12px">Support available Mon - Sat (10am - 7pm)</p>
        <a href="https://wa.me/919148330016" target="_blank" style="display:inline-flex;align-items:center;gap:8px;background:#25D366;color:#FFF;padding:10px 18px;border-radius:10px;font-size:13px;font-weight:600;text-decoration:none">
          WhatsApp: +91 91483 30016
        </a>
      </div>
    </div>
    <div class="footer-bottom">
      &copy; 2026 KAAPAV Fashion Jewellery. All rights reserved.
    </div>
  </footer>

  <script>
    const CATEGORY_FILTER = '${cat.filter}';
    let baseProducts = [];
    let activePriceRange = 'all';
    let activeSort = 'featured';
    let activeSearchQuery = '';

    async function initShop() {
      const all = await window.KaapavStore.fetchProducts();
      
      if (CATEGORY_FILTER === 'all') {
        baseProducts = all;
      } else if (CATEGORY_FILTER === 'bestseller') {
        baseProducts = all.slice(0, 24);
      } else {
        baseProducts = all.filter(p => {
          const cat = (p.category || '').toLowerCase();
          const name = (p.name || '').toLowerCase();
          return cat.includes(CATEGORY_FILTER) || name.includes(CATEGORY_FILTER);
        });
      }

      applyFiltersAndRender();
    }

    function setPriceFilter(range, btnEl) {
      activePriceRange = range;
      document.querySelectorAll('.price-pill').forEach(b => b.classList.remove('active'));
      if (btnEl) btnEl.classList.add('active');
      applyFiltersAndRender();
    }

    function handleSort(val) {
      activeSort = val;
      applyFiltersAndRender();
    }

    function handleSearch(val) {
      activeSearchQuery = val.trim().toLowerCase();
      applyFiltersAndRender();
    }

    function applyFiltersAndRender() {
      let filtered = [...baseProducts];

      // 1. Price Filter
      if (activePriceRange === 'under499') filtered = filtered.filter(p => p.price < 499);
      else if (activePriceRange === '499to799') filtered = filtered.filter(p => p.price >= 499 && p.price <= 799);
      else if (activePriceRange === 'above799') filtered = filtered.filter(p => p.price > 799);

      // 2. Search Query
      if (activeSearchQuery) {
        filtered = filtered.filter(p => (p.name || '').toLowerCase().includes(activeSearchQuery) || (p.sku || '').toLowerCase().includes(activeSearchQuery));
      }

      // 3. Sorting
      if (activeSort === 'price_low') filtered.sort((a, b) => a.price - b.price);
      else if (activeSort === 'price_high') filtered.sort((a, b) => b.price - a.price);
      else if (activeSort === 'discount') {
        filtered.sort((a, b) => {
          const discA = a.compare_price > a.price ? (a.compare_price - a.price) : 0;
          const discB = b.compare_price > b.price ? (b.compare_price - b.price) : 0;
          return discB - discA;
        });
      }

      renderGrid(filtered);
    }

    function renderGrid(items) {
      const grid = document.getElementById('shopProductGrid');
      if (!grid) return;

      if (!items.length) {
        grid.innerHTML = \`
          <div style="grid-column:1/-1;text-align:center;padding:60px 20px;color:var(--muted)">
            <div style="font-size:40px;margin-bottom:12px">💎</div>
            <h3 style="font-family:var(--serif);font-size:22px;color:#1C1917;margin-bottom:8px">No matching jewellery pieces</h3>
            <p style="font-size:13.5px">Try adjusting your price or search filter.</p>
          </div>
        \`;
        return;
      }

      grid.innerHTML = items.map(p => {
        const img = (Array.isArray(p.images) && p.images[0]) ? p.images[0] : (p.image_url || '/assets/logo.png');
        const discPct = p.compare_price > p.price ? Math.round(((p.compare_price - p.price) / p.compare_price) * 100) : 0;

        return \`
          <div class="product-card">
            <div class="card-media-wrap">
              <a href="/product/index.html?sku=\${p.sku}">
                <img src="\${img}" alt="\${p.name}" loading="lazy" onerror="this.src='/assets/logo.png'">
              </a>
              \${discPct > 0 ? \`<span class="card-discount-tag">\${discPct}% OFF</span>\` : ''}
            </div>
            <div class="card-content">
              <div class="card-category">\${p.category || 'Fine Jewellery'}</div>
              <a href="/product/index.html?sku=\${p.sku}" class="card-title">\${p.name}</a>
              <div class="card-price-row">
                <span class="card-price">₹\${p.price}</span>
                \${p.compare_price > p.price ? \`<span class="card-mrp">₹\${p.compare_price}</span>\` : ''}
              </div>
              <div class="card-cta-group">
                <button class="card-btn-add" onclick="window.KaapavStore.addToCart('\${p.sku}', 1, true)">
                  Add to Bag
                </button>
                <a href="/product/index.html?sku=\${p.sku}" class="card-btn-view">
                  View
                </a>
              </div>
            </div>
          </div>
        \`;
      }).join('');
    }

    document.addEventListener('DOMContentLoaded', initShop);
  </script>
</body>
</html>`;
}

const baseDir = path.join(__dirname, 'kaapav-store');

CATEGORIES.forEach(cat => {
  const html = generateCategoryHtml(cat);
  cat.outDirs.forEach(sub => {
    const dir = path.join(baseDir, sub);
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
    fs.writeFileSync(path.join(dir, 'index.html'), html, 'utf8');
  });

  if (cat.slug === 'shop') {
    fs.writeFileSync(path.join(baseDir, 'shop.html'), html, 'utf8');
  }
});

console.log('✅ All luxury category pages and shop compiled successfully.');
