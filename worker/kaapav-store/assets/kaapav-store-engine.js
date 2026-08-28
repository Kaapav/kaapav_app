/**
 * KAAPAV Storefront Unified Commerce Engine v1.0
 * Shared Inventory, Dynamic Catalog, Cart Drawer, and Razorpay Checkout
 * Compatible with wa.kaapav.com backend APIs
 */
(function(window, document) {
  "use strict";

  const CONFIG = {
    API_BASE: "https://wa.kaapav.com/api",
    CATALOGUE_API: "https://wa.kaapav.com/api/catalogue",
    ORDER_API: "https://wa.kaapav.com/api/orders/catalogue",
    CONFIRM_API: "https://wa.kaapav.com/api/orders/confirm",
    COUPON_API: "https://wa.kaapav.com/api/catalogue/coupons/validate",
    EVENTS_API: "https://wa.kaapav.com/api/customer-events",
    RZP_KEY: "rzp_live_3G5rPyrp66kRAB",
    FREE_SHIPPING_THRESHOLD: 498,
    STANDARD_SHIPPING: 50,
    CACHE_KEY: "kpv_store_products_v1",
    CART_KEY: "kpv_store_cart_v1",
    CACHE_TTL: 10 * 60 * 1000 // 10 minutes
  };

  let products = [];
  let cart = {};
  let appliedCoupon = null;
  let razorpayLoadedPromise = null;

  // ── 1. HELPERS & UTILITIES ──
  function safeJson(val, fallback) {
    if (typeof val === "object" && val !== null) return val;
    try { return JSON.parse(val); } catch(e) { return fallback; }
  }

  function formatPrice(val) {
    return "₹" + Number(val || 0).toLocaleString("en-IN");
  }

  function toast(msg, type = "info") {
    let el = document.getElementById("kpv-toast");
    if (!el) {
      el = document.createElement("div");
      el.id = "kpv-toast";
      document.body.appendChild(el);
    }
    el.textContent = msg;
    el.className = "kpv-toast show " + type;
    clearTimeout(el._timer);
    el._timer = setTimeout(() => { el.className = "kpv-toast"; }, 3200);
  }

  function getUrlParam(key) {
    return new URLSearchParams(window.location.search).get(key);
  }

  function getSkuFromPath() {
    const fromParam = getUrlParam("sku");
    if (fromParam) return fromParam.trim();
    const parts = window.location.pathname.split("/").filter(Boolean);
    const last = parts.pop();
    if (last && last !== "product" && last !== "index.html") {
      return last.replace(/\.html$/i, "").trim();
    }
    return null;
  }

  // ── 2. PRODUCT FETCHING & CACHING ──
  async function fetchProducts() {
    // Try memory
    if (products.length) return products;

    // Try cache
    try {
      const cached = JSON.parse(localStorage.getItem(CONFIG.CACHE_KEY) || "null");
      if (cached && Array.isArray(cached.products) && (Date.now() - cached.ts < CONFIG.CACHE_TTL)) {
        products = cached.products;
        // background revalidate
        revalidateProducts();
        return products;
      }
    } catch(e) {}

    return await revalidateProducts();
  }

  async function revalidateProducts() {
    try {
      const res = await fetch(CONFIG.CATALOGUE_API + "?t=" + Date.now(), { cache: "no-store" });
      const data = await res.json();
      if (data.success && Array.isArray(data.products)) {
        products = data.products.map(p => ({
          ...p,
          images: safeJson(p.images, [p.image_url || ""]),
          tags: safeJson(p.tags, []),
          stock: Number(p.stock != null ? p.stock : 5),
          price: Number(p.price || 0),
          compare_price: Number(p.compare_price || 0)
        }));
        try {
          localStorage.setItem(CONFIG.CACHE_KEY, JSON.stringify({ ts: Date.now(), products }));
        } catch(e) {}
        window.dispatchEvent(new CustomEvent("kpv:products-loaded", { detail: { products } }));
        return products;
      }
    } catch(e) {
      console.warn("Product feed fetch error:", e);
    }
    return products;
  }

  // ── 3. CART STATE MANAGEMENT ──
  function loadCart() {
    try {
      cart = JSON.parse(localStorage.getItem(CONFIG.CART_KEY) || "{}");
    } catch(e) { cart = {}; }
    updateCartBadges();
  }

  function saveCart() {
    try {
      localStorage.setItem(CONFIG.CART_KEY, JSON.stringify(cart));
    } catch(e) {}
    updateCartBadges();
    renderCartDrawer();
  }

  function addToCart(sku, qty = 1, openDrawer = true) {
    sku = String(sku);
    const prod = products.find(p => p.sku === sku);
    if (!prod) {
      toast("Product not found", "error");
      return;
    }
    if (prod.stock <= 0) {
      toast("Item is currently out of stock", "warn");
      return;
    }

    const currentQty = cart[sku] ? cart[sku].qty : 0;
    const newQty = currentQty + qty;

    const img = (Array.isArray(prod.images) && prod.images[0]) ? prod.images[0] : (prod.image_url || "/assets/logo.png");

    cart[sku] = {
      sku: prod.sku,
      name: prod.name,
      category: prod.category || "",
      price: prod.price,
      compare_price: prod.compare_price || 0,
      image: img,
      image_url: img,
      qty: newQty
    };

    saveCart();
    toast("Added " + prod.name + " to your bag 🛍️", "success");

    trackEvent("AddToCart", {
      sku: prod.sku,
      product_name: prod.name,
      price: prod.price,
      quantity: qty
    });

    if (openDrawer) openCartDrawer();
  }

  function updateCartQty(sku, qty) {
    sku = String(sku);
    if (!cart[sku]) return;
    if (qty <= 0) {
      delete cart[sku];
    } else {
      cart[sku].qty = qty;
    }
    saveCart();
  }

  function removeFromCart(sku) {
    sku = String(sku);
    delete cart[sku];
    saveCart();
  }

  function getCartTotals() {
    const items = Object.values(cart);
    const count = items.reduce((sum, i) => sum + i.qty, 0);
    const subtotal = items.reduce((sum, i) => sum + (i.price * i.qty), 0);
    const isFreeShip = subtotal >= CONFIG.FREE_SHIPPING_THRESHOLD || subtotal === 0;
    const shipping = isFreeShip ? 0 : CONFIG.STANDARD_SHIPPING;
    
    let discount = 0;
    if (appliedCoupon) {
      if (appliedCoupon.type === "percent") {
        discount = Math.round((subtotal * Number(appliedCoupon.value || 0)) / 100);
        if (appliedCoupon.max_discount) discount = Math.min(discount, Number(appliedCoupon.max_discount));
      } else {
        discount = Math.round(Number(appliedCoupon.value || 0));
      }
      discount = Math.max(0, Math.min(discount, subtotal));
    }

    const total = Math.max(0, subtotal - discount + shipping);
    const progressToFreeShip = Math.min(100, Math.round((subtotal / CONFIG.FREE_SHIPPING_THRESHOLD) * 100));
    const amountNeededForFreeShip = Math.max(0, CONFIG.FREE_SHIPPING_THRESHOLD - subtotal);

    return {
      items,
      count,
      subtotal,
      shipping,
      discount,
      total,
      isFreeShip,
      progressToFreeShip,
      amountNeededForFreeShip
    };
  }

  function updateCartBadges() {
    const totals = getCartTotals();
    document.querySelectorAll(".hdr-cart-badge, #hdrCartCount, .cart-count-badge").forEach(el => {
      el.textContent = totals.count;
      el.style.display = totals.count > 0 ? "inline-flex" : "none";
    });
  }

  // ── 4. CART DRAWER UI & INTERACTIONS ──
  function ensureDrawerMarkup() {
    if (document.getElementById("kpv-cart-drawer")) return;

    const drawerHtml = `
      <div id="kpv-cart-overlay" class="kpv-cart-overlay" onclick="window.KaapavStore.closeCartDrawer()"></div>
      <div id="kpv-cart-drawer" class="kpv-cart-drawer">
        <div class="kpv-drawer-header">
          <div class="kpv-drawer-title">
            <span>Your Shopping Bag</span>
            <span class="kpv-drawer-badge" id="kpvDrawerCount">0</span>
          </div>
          <button class="kpv-drawer-close" onclick="window.KaapavStore.closeCartDrawer()">&times;</button>
        </div>

        <div class="kpv-shipping-meter-wrap" id="kpvShipMeterWrap">
          <div class="kpv-ship-msg" id="kpvShipMsg">Add ₹498 for FREE Delivery</div>
          <div class="kpv-meter-bar">
            <div class="kpv-meter-fill" id="kpvMeterFill" style="width:0%"></div>
          </div>
        </div>

        <div class="kpv-drawer-items" id="kpvDrawerItems">
          <!-- Items injected here -->
        </div>

        <div class="kpv-drawer-footer" id="kpvDrawerFooter">
          <div class="kpv-summary-row">
            <span>Subtotal</span>
            <span id="kpvSubtotal">₹0</span>
          </div>
          <div class="kpv-summary-row" id="kpvDiscountRow" style="display:none;color:#10B981;">
            <span>Discount (<span id="kpvCouponLabel"></span>)</span>
            <span id="kpvDiscount">-₹0</span>
          </div>
          <div class="kpv-summary-row">
            <span>Estimated Shipping</span>
            <span id="kpvShipping">₹50</span>
          </div>
          <div class="kpv-summary-row kpv-total-row">
            <span>Total Payable</span>
            <span id="kpvTotal">₹0</span>
          </div>

          <button class="kpv-btn-checkout" id="kpvCheckoutBtn" onclick="window.KaapavStore.openCheckoutModal()">
            Proceed to Checkout &bull; <span id="kpvBtnPayable">₹0</span>
          </button>
          
          <button class="kpv-btn-wa" onclick="window.KaapavStore.orderViaWhatsApp()">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M12.031 6.172c-3.181 0-5.767 2.586-5.768 5.766-.001 1.298.38 2.27 1.019 3.287l-.711 2.598 2.664-.698c.972.531 1.874.819 2.8.82h.005c3.181 0 5.767-2.586 5.768-5.766 0-3.18-2.586-5.767-5.777-5.767zm3.387 8.248c-.141.398-.716.732-1.008.777-.282.043-.637.072-2.032-.505-1.782-.738-2.92-2.55-3.009-2.668-.088-.118-.72-1.026-.72-1.956 0-.931.472-1.385.642-1.574.17-.189.37-.236.494-.236.124 0 .248.001.353.006.113.005.263-.043.411.314.153.37.522 1.272.568 1.365.046.094.076.204.015.326-.062.122-.093.197-.185.305-.093.107-.196.24-.28.322-.093.093-.19.194-.082.38.108.185.48 0.793 1.027 1.282.705.628 1.299.822 1.484.914.185.093.294.077.402-.046.108-.124.463-.538.587-.723.123-.185.247-.154.416-.093.17.062 1.077.508 1.262.6.185.093.308.139.354.216.046.077.046.446-.095.844z"/></svg>
            Order via WhatsApp
          </button>
        </div>
      </div>
    `;

    const wrap = document.createElement("div");
    wrap.innerHTML = drawerHtml;
    document.body.appendChild(wrap);
  }

  function renderCartDrawer() {
    ensureDrawerMarkup();
    const totals = getCartTotals();
    
    // Header badge
    const badge = document.getElementById("kpvDrawerCount");
    if (badge) badge.textContent = totals.count;

    // Shipping meter
    const msg = document.getElementById("kpvShipMsg");
    const fill = document.getElementById("kpvMeterFill");
    if (msg && fill) {
      if (totals.subtotal === 0) {
        msg.textContent = "Add items to your bag for Free Delivery";
        fill.style.width = "0%";
      } else if (totals.isFreeShip) {
        msg.innerHTML = "✨ You have qualified for <strong>FREE Delivery</strong>!";
        fill.style.width = "100%";
        fill.style.background = "#10B981";
      } else {
        msg.innerHTML = "Add <strong>₹" + totals.amountNeededForFreeShip + "</strong> more for <strong>FREE Delivery</strong>";
        fill.style.width = totals.progressToFreeShip + "%";
        fill.style.background = "linear-gradient(90deg, #C49432, #E2B755)";
      }
    }

    // Items list
    const itemsEl = document.getElementById("kpvDrawerItems");
    if (itemsEl) {
      if (!totals.items.length) {
        itemsEl.innerHTML = `
          <div class="kpv-empty-cart">
            <div style="font-size:44px;margin-bottom:12px">🛍️</div>
            <h3 style="font-family:var(--serif, serif);font-size:22px;margin-bottom:6px">Your Bag is Empty</h3>
            <p style="font-size:13px;color:#78716C;margin-bottom:20px">Explore our handcrafted fine jewellery pieces.</p>
            <a href="/shop/index.html" class="kpv-btn-shop-now" onclick="window.KaapavStore.closeCartDrawer()">Explore Collection</a>
          </div>
        `;
      } else {
        itemsEl.innerHTML = totals.items.map(item => `
          <div class="kpv-cart-item" data-sku="${item.sku}">
            <img src="${item.image}" alt="${item.name}" class="kpv-item-thumb" onerror="this.src='/assets/logo.png'">
            <div class="kpv-item-details">
              <div class="kpv-item-name">${item.name}</div>
              <div class="kpv-item-sku">SKU: ${item.sku}</div>
              <div class="kpv-item-price-row">
                <span class="kpv-item-price">₹${item.price}</span>
                ${item.compare_price > item.price ? `<span class="kpv-item-mrp">₹${item.compare_price}</span>` : ""}
              </div>
              <div class="kpv-qty-stepper">
                <button onclick="window.KaapavStore.updateCartQty('${item.sku}', ${item.qty - 1})">-</button>
                <span>${item.qty}</span>
                <button onclick="window.KaapavStore.updateCartQty('${item.sku}', ${item.qty + 1})">+</button>
              </div>
            </div>
            <button class="kpv-item-remove" onclick="window.KaapavStore.removeFromCart('${item.sku}')" title="Remove">&times;</button>
          </div>
        `).join("");
      }
    }

    // Totals & Footer
    const subtotalEl = document.getElementById("kpvSubtotal");
    const shippingEl = document.getElementById("kpvShipping");
    const totalEl = document.getElementById("kpvTotal");
    const btnPayableEl = document.getElementById("kpvBtnPayable");
    const footerEl = document.getElementById("kpvDrawerFooter");
    const checkoutBtn = document.getElementById("kpvCheckoutBtn");

    if (subtotalEl) subtotalEl.textContent = formatPrice(totals.subtotal);
    if (shippingEl) shippingEl.innerHTML = totals.isFreeShip ? "<span style='color:#10B981;font-weight:600'>FREE</span>" : formatPrice(totals.shipping);
    if (totalEl) totalEl.textContent = formatPrice(totals.total);
    if (btnPayableEl) btnPayableEl.textContent = formatPrice(totals.total);

    if (footerEl) {
      footerEl.style.display = totals.items.length ? "block" : "none";
    }
    if (checkoutBtn) {
      checkoutBtn.disabled = totals.items.length === 0;
    }
  }

  function openCartDrawer() {
    ensureDrawerMarkup();
    renderCartDrawer();
    document.getElementById("kpv-cart-drawer")?.classList.add("open");
    document.getElementById("kpv-cart-overlay")?.classList.add("open");
    document.body.style.overflow = "hidden";
  }

  function closeCartDrawer() {
    document.getElementById("kpv-cart-drawer")?.classList.remove("open");
    document.getElementById("kpv-cart-overlay")?.classList.remove("open");
    document.body.style.overflow = "";
  }

  // ── 5. CHECKOUT & RAZORPAY INTEGRATION ──
  function loadRazorpay() {
    if (typeof Razorpay !== "undefined") return Promise.resolve();
    if (razorpayLoadedPromise) return razorpayLoadedPromise;
    razorpayLoadedPromise = new Promise((resolve, reject) => {
      const existing = document.querySelector("script[data-kpv-razorpay]");
      if (existing) {
        existing.addEventListener("load", resolve, { once: true });
        existing.addEventListener("error", () => reject(new Error("Razorpay load failed")), { once: true });
        return;
      }
      const s = document.createElement("script");
      s.src = "https://checkout.razorpay.com/v1/checkout.js";
      s.async = true;
      s.dataset.kpvRazorpay = "1";
      s.onload = resolve;
      s.onerror = () => reject(new Error("Razorpay failed to load"));
      document.head.appendChild(s);
    });
    return razorpayLoadedPromise;
  }

  function ensureCheckoutModalMarkup() {
    if (document.getElementById("kpv-checkout-modal")) return;

    const modalHtml = `
      <div id="kpv-checkout-overlay" class="kpv-checkout-overlay" onclick="window.KaapavStore.closeCheckoutModal()"></div>
      <div id="kpv-checkout-modal" class="kpv-checkout-modal">
        <div class="kpv-co-header">
          <div style="font-family:var(--serif,serif);font-size:22px;font-weight:600">Secure Express Checkout</div>
          <button class="kpv-co-close" onclick="window.KaapavStore.closeCheckoutModal()">&times;</button>
        </div>

        <div class="kpv-co-body">
          <form id="kpvCheckoutForm" onsubmit="window.KaapavStore.handleCheckoutSubmit(event)">
            
            <div class="kpv-form-section-title">1. Customer Information</div>
            <div class="kpv-form-grid">
              <div class="kpv-field-wrap">
                <label>Full Name *</label>
                <input type="text" id="co_name" required placeholder="e.g. Priya Sharma">
              </div>
              <div class="kpv-field-wrap">
                <label>WhatsApp / Phone (10 digits) *</label>
                <div style="position:relative">
                  <span style="position:absolute;left:12px;top:50%;transform:translateY(-50%);font-size:13px;color:#78716C;font-weight:600">+91</span>
                  <input type="tel" id="co_phone" maxlength="10" pattern="[0-9]{10}" required placeholder="9876543210" style="padding-left:46px;">
                </div>
              </div>
              <div class="kpv-field-wrap" style="grid-column:1/-1">
                <label>Email Address (For Invoicing & Tracking) *</label>
                <input type="email" id="co_email" required placeholder="priya@example.com">
              </div>
            </div>

            <div class="kpv-form-section-title" style="margin-top:20px">2. Delivery Address</div>
            <div class="kpv-form-grid">
              <div class="kpv-field-wrap" style="grid-column:1/-1">
                <label>House / Flat / Street Address *</label>
                <input type="text" id="co_address" required placeholder="Flat No, Building, Street Name">
              </div>
              <div class="kpv-field-wrap">
                <label>Pincode *</label>
                <input type="text" id="co_pincode" maxlength="6" pattern="[0-9]{6}" required placeholder="6-digit Pincode" onchange="window.KaapavStore.lookupPincode(this.value)">
              </div>
              <div class="kpv-field-wrap">
                <label>City *</label>
                <input type="text" id="co_city" required placeholder="City">
              </div>
              <div class="kpv-field-wrap" style="grid-column:1/-1">
                <label>State *</label>
                <input type="text" id="co_state" required placeholder="State">
              </div>
            </div>

            <div class="kpv-form-section-title" style="margin-top:20px">3. Have a Coupon?</div>
            <div class="kpv-coupon-box">
              <input type="text" id="co_coupon_input" placeholder="Enter promo code" style="text-transform:uppercase">
              <button type="button" onclick="window.KaapavStore.applyCoupon()">Apply</button>
            </div>
            <div id="co_coupon_status" class="kpv-coupon-status"></div>

            <div class="kpv-order-review-box">
              <div class="kpv-rev-row"><span>Items Total</span><span id="coRevSubtotal">₹0</span></div>
              <div class="kpv-rev-row" id="coRevDiscountRow" style="display:none;color:#10B981;"><span>Discount</span><span id="coRevDiscount">-₹0</span></div>
              <div class="kpv-rev-row"><span>Delivery</span><span id="coRevShipping">₹0</span></div>
              <div class="kpv-rev-row kpv-rev-total"><span>Grand Total</span><span id="coRevGrandTotal">₹0</span></div>
            </div>

            <button type="submit" class="kpv-btn-pay-now" id="coSubmitBtn">
              🔒 Pay with Razorpay / UPI &bull; <span id="coBtnTotal">₹0</span>
            </button>

            <div style="text-align:center;margin-top:12px;font-size:11px;color:#78716C">
              Secured by 256-Bit SSL Encryption &bull; Official Razorpay Gateway
            </div>
          </form>
        </div>
      </div>
    `;

    const wrap = document.createElement("div");
    wrap.innerHTML = modalHtml;
    document.body.appendChild(wrap);
  }

  function openCheckoutModal() {
    closeCartDrawer();
    ensureCheckoutModalMarkup();

    const totals = getCartTotals();
    if (!totals.items.length) {
      toast("Your bag is empty", "warn");
      return;
    }

    try {
      const savedPhone = localStorage.getItem("customerPhone") || localStorage.getItem("phone") || "";
      const savedName = localStorage.getItem("customerName") || "";
      const savedEmail = localStorage.getItem("customerEmail") || "";
      if (savedPhone) document.getElementById("co_phone").value = savedPhone.replace(/^91/, "");
      if (savedName) document.getElementById("co_name").value = savedName;
      if (savedEmail) document.getElementById("co_email").value = savedEmail;
    } catch(e) {}

    updateCheckoutReview();
    document.getElementById("kpv-checkout-modal")?.classList.add("open");
    document.getElementById("kpv-checkout-overlay")?.classList.add("open");
    document.body.style.overflow = "hidden";

    trackEvent("InitiateCheckout", {
      cart_total: totals.total,
      item_count: totals.count
    });
  }

  function closeCheckoutModal() {
    document.getElementById("kpv-checkout-modal")?.classList.remove("open");
    document.getElementById("kpv-checkout-overlay")?.classList.remove("open");
    document.body.style.overflow = "";
  }

  function updateCheckoutReview() {
    const totals = getCartTotals();
    const sub = document.getElementById("coRevSubtotal");
    const discRow = document.getElementById("coRevDiscountRow");
    const disc = document.getElementById("coRevDiscount");
    const ship = document.getElementById("coRevShipping");
    const grand = document.getElementById("coRevGrandTotal");
    const btnTot = document.getElementById("coBtnTotal");

    if (sub) sub.textContent = formatPrice(totals.subtotal);
    if (discRow) discRow.style.display = totals.discount > 0 ? "flex" : "none";
    if (disc) disc.textContent = "- " + formatPrice(totals.discount);
    if (ship) ship.innerHTML = totals.isFreeShip ? "<span style='color:#10B981;font-weight:600'>FREE</span>" : formatPrice(totals.shipping);
    if (grand) grand.textContent = formatPrice(totals.total);
    if (btnTot) btnTot.textContent = formatPrice(totals.total);
  }

  async function applyCoupon() {
    const input = document.getElementById("co_coupon_input");
    const status = document.getElementById("co_coupon_status");
    const code = (input?.value || "").trim().toUpperCase();

    if (!code) {
      toast("Please enter a coupon code");
      return;
    }

    const totals = getCartTotals();
    try {
      const res = await fetch(CONFIG.COUPON_API, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ code, orderTotal: totals.subtotal })
      });
      const data = await res.json();
      if (!res.ok || !data.success) {
        appliedCoupon = null;
        if (status) {
          status.className = "kpv-coupon-status err";
          status.textContent = data.error || data.message || "Invalid coupon code";
        }
        toast(data.error || "Invalid coupon", "error");
      } else {
        appliedCoupon = data.coupon;
        if (status) {
          status.className = "kpv-coupon-status ok";
          status.textContent = "Coupon " + appliedCoupon.code + " applied successfully!";
        }
        toast("Coupon " + appliedCoupon.code + " applied! 🎟️", "success");
      }
    } catch(e) {
      appliedCoupon = null;
      toast("Error applying coupon", "error");
    }
    updateCheckoutReview();
    renderCartDrawer();
  }

  async function lookupPincode(pincode) {
    pincode = String(pincode).trim();
    if (pincode.length !== 6) return;
    try {
      const res = await fetch("https://api.postalpincode.in/pincode/" + pincode);
      const data = await res.json();
      if (data && data[0] && data[0].Status === "Success" && data[0].PostOffice?.length) {
        const po = data[0].PostOffice[0];
        const cityField = document.getElementById("co_city");
        const stateField = document.getElementById("co_state");
        if (cityField && !cityField.value) cityField.value = po.District || po.Block || "";
        if (stateField && !stateField.value) stateField.value = po.State || "";
      }
    } catch(e) {}
  }

  async function handleCheckoutSubmit(e) {
    e.preventDefault();
    const btn = document.getElementById("coSubmitBtn");
    const totals = getCartTotals();
    
    if (!totals.items.length) {
      toast("Cart is empty", "error");
      return;
    }

    const name = document.getElementById("co_name").value.trim();
    const phone = document.getElementById("co_phone").value.replace(/\D/g, "").slice(-10);
    const email = document.getElementById("co_email").value.trim().toLowerCase();
    const address = document.getElementById("co_address").value.trim();
    const pincode = document.getElementById("co_pincode").value.trim();
    const city = document.getElementById("co_city").value.trim();
    const state = document.getElementById("co_state").value.trim();

    if (phone.length !== 10) {
      toast("Enter a valid 10-digit phone number", "error");
      return;
    }

    try {
      localStorage.setItem("customerPhone", "91" + phone);
      localStorage.setItem("phone", "91" + phone);
      localStorage.setItem("customerName", name);
      localStorage.setItem("customerEmail", email);
    } catch(e) {}

    btn.disabled = true;
    btn.innerHTML = "Creating Secure Checkout...";

    try {
      const rzpPromise = loadRazorpay();

      const payload = {
        name,
        phone: "91" + phone,
        email,
        address,
        city,
        state,
        pincode,
        items: totals.items.map(i => ({
          sku: i.sku,
          name: i.name,
          category: i.category || "",
          price: i.price,
          qty: i.qty,
          image: i.image || "",
          image_url: i.image || ""
        })),
        subtotal: totals.subtotal,
        shipping: totals.shipping,
        couponCode: appliedCoupon?.code || "",
        discount: totals.discount,
        total: totals.total
      };

      const res = await fetch(CONFIG.ORDER_API, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload)
      });

      const orderData = await res.json();
      if (!res.ok || !orderData.success) {
        throw new Error(orderData.error || orderData.message || "Could not create order");
      }

      await rzpPromise;
      if (typeof Razorpay === "undefined") {
        throw new Error("Payment gateway could not load. Please retry.");
      }

      btn.innerHTML = "Opening Razorpay Gateway...";

      const rzp = new Razorpay({
        key: CONFIG.RZP_KEY,
        amount: Number(orderData.total || totals.total) * 100,
        currency: "INR",
        name: "KAAPAV Fashion Jewellery",
        description: "Order " + orderData.orderId,
        image: "https://www.kaapav.com/assets/logo.png",
        prefill: {
          name,
          contact: "+91" + phone,
          email
        },
        theme: { color: "#C49432" },
        handler: function(resp) {
          const paidOrderId = orderData.orderId;
          const paidPhone = "91" + phone;
          const paidPaymentId = resp.razorpay_payment_id;

          cart = {};
          appliedCoupon = null;
          saveCart();

          fetch(CONFIG.CONFIRM_API, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            keepalive: true,
            body: JSON.stringify({
              orderId: paidOrderId,
              paymentId: paidPaymentId,
              phone: paidPhone
            })
          }).catch(err => console.error("Confirm error:", err));

          trackEvent("Purchase", {
            orderId: paidOrderId,
            value: totals.total,
            phone: paidPhone,
            name
          });

          closeCheckoutModal();
          showSuccessScreen(paidOrderId, totals.total, name);
        },
        modal: {
          ondismiss: function() {
            btn.disabled = false;
            btn.innerHTML = "🔒 Pay with Razorpay / UPI &bull; " + formatPrice(totals.total);
            toast("Payment was not completed. You can try again.");
          }
        }
      });

      rzp.open();

    } catch(e) {
      btn.disabled = false;
      btn.innerHTML = "🔒 Pay with Razorpay / UPI &bull; " + formatPrice(totals.total);
      console.error("Order creation failure:", e);
      toast(e.message || "Failed to initiate payment", "error");
    }
  }

  function showSuccessScreen(orderId, total, name) {
    const overlay = document.createElement("div");
    overlay.className = "kpv-success-overlay";
    overlay.innerHTML = `
      <div class="kpv-success-card">
        <div style="font-size:52px;margin-bottom:12px">✨</div>
        <h2 style="font-family:var(--serif,serif);font-size:28px;color:#1C1917;margin-bottom:8px">Thank You, ${name}!</h2>
        <p style="color:#78716C;font-size:14px;margin-bottom:18px">Your order has been confirmed successfully.</p>
        <div style="background:#FAF7F2;border:1px solid rgba(196,148,50,0.3);border-radius:12px;padding:16px;margin-bottom:20px;text-align:left">
          <div style="font-size:12px;color:#78716C">Order Reference:</div>
          <div style="font-size:18px;font-weight:700;color:#9A7424">${orderId}</div>
          <div style="font-size:13px;color:#1C1917;margin-top:6px">Amount Paid: <strong>₹${total}</strong></div>
        </div>
        <p style="font-size:12.5px;color:#78716C;line-height:1.6;margin-bottom:24px">
          📦 We will pack and dispatch your jewellery within 24 hours.<br>
          Updates will be delivered directly to your WhatsApp!
        </p>
        <div style="display:flex;gap:10px;justify-content:center">
          <a href="/shop/index.html" class="kpv-btn-shop-now" style="display:inline-block">Continue Shopping</a>
          <a href="https://wa.me/919148330016?text=Hi%20KAAPAV,%20I%20just%20placed%20Order%20${orderId}" target="_blank" class="kpv-btn-wa" style="display:inline-flex;padding:12px 20px;border-radius:10px;margin-top:0">Chat on WhatsApp</a>
        </div>
      </div>
    `;
    document.body.appendChild(overlay);
  }

  function orderViaWhatsApp() {
    const totals = getCartTotals();
    if (!totals.items.length) {
      toast("Your bag is empty");
      return;
    }
    const lines = totals.items.map(i => "• " + i.name + " (" + i.sku + ") × " + i.qty + " - ₹" + (i.price * i.qty)).join("\n");
    const text = "Hi KAAPAV, I would like to order:\n\n" + lines + "\n\n*Total:* ₹" + totals.total;
    window.location.href = "https://wa.me/919148330016?text=" + encodeURIComponent(text);
  }

  // ── 6. ANALYTICS & PIXEL TRACKING ──
  function trackEvent(eventName, data = {}) {
    const phone = localStorage.getItem("customerPhone") || "";
    try {
      if (typeof window.fbq === "function") {
        window.fbq("track", eventName, data);
      }
    } catch(e) {}

    try {
      if (window.dataLayer && Array.isArray(window.dataLayer)) {
        window.dataLayer.push({ event: eventName, ...data });
      }
    } catch(e) {}

    if (phone) {
      fetch(CONFIG.EVENTS_API, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          phone,
          source: "storefront",
          event: eventName,
          sku: data.sku || "",
          product_name: data.product_name || "",
          price: data.price || 0,
          cart_total: data.cart_total || 0,
          page_url: window.location.href
        })
      }).catch(() => {});
    }
  }

  // ── 7. DOM INITIALIZATION ──
  function injectStyles() {
    if (document.getElementById("kpv-store-engine-styles")) return;
    const style = document.createElement("style");
    style.id = "kpv-store-engine-styles";
    style.textContent = `
      /* Cart Drawer & Overlays */
      .kpv-cart-overlay, .kpv-checkout-overlay {
        position: fixed; inset: 0; background: rgba(20, 16, 12, 0.65);
        backdrop-filter: blur(8px); z-index: 10000; opacity: 0; pointer-events: none;
        transition: opacity 0.3s cubic-bezier(0.16, 1, 0.3, 1);
      }
      .kpv-cart-overlay.open, .kpv-checkout-overlay.open { opacity: 1; pointer-events: auto; }

      .kpv-cart-drawer {
        position: fixed; top: 0; right: 0; bottom: 0; width: min(440px, 100%);
        background: #FAF7F2; z-index: 10001; transform: translateX(100%);
        box-shadow: -10px 0 40px rgba(0,0,0,0.18); display: flex; flex-direction: column;
        transition: transform 0.35s cubic-bezier(0.16, 1, 0.3, 1);
      }
      .kpv-cart-drawer.open { transform: translateX(0); }

      .kpv-drawer-header {
        display: flex; align-items: center; justify-content: space-between;
        padding: 20px 24px; border-bottom: 1px solid rgba(196,148,50,0.2);
        background: #FFF;
      }
      .kpv-drawer-title { font-family: var(--serif, serif); font-size: 22px; font-weight: 600; color: #1C1917; display: flex; align-items: center; gap: 8px; }
      .kpv-drawer-badge { background: #C49432; color: #FFF; font-size: 11px; font-weight: 700; border-radius: 12px; padding: 2px 8px; font-family: var(--sans, sans-serif); }
      .kpv-drawer-close { background: none; border: none; font-size: 28px; cursor: pointer; color: #78716C; line-height: 1; }

      .kpv-shipping-meter-wrap { padding: 14px 24px; background: #F4EFE6; border-bottom: 1px solid rgba(196,148,50,0.15); }
      .kpv-ship-msg { font-size: 12.5px; color: #44403C; margin-bottom: 8px; text-align: center; }
      .kpv-meter-bar { height: 6px; background: #E5DCCF; border-radius: 6px; overflow: hidden; }
      .kpv-meter-fill { height: 100%; transition: width 0.3s ease; }

      .kpv-drawer-items { flex: 1; overflow-y: auto; padding: 16px 24px; display: flex; flex-direction: column; gap: 14px; }
      .kpv-cart-item { display: flex; gap: 14px; background: #FFF; border: 1px solid rgba(196,148,50,0.2); border-radius: 14px; padding: 12px; position: relative; }
      .kpv-item-thumb { width: 70px; height: 70px; object-fit: cover; border-radius: 10px; background: #FAF7F2; flex-shrink: 0; }
      .kpv-item-details { flex: 1; min-width: 0; }
      .kpv-item-name { font-size: 13px; font-weight: 600; color: #1C1917; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; margin-bottom: 3px; }
      .kpv-item-sku { font-size: 10.5px; color: #A8A29E; margin-bottom: 6px; }
      .kpv-item-price-row { display: flex; align-items: baseline; gap: 6px; margin-bottom: 8px; }
      .kpv-item-price { font-size: 14px; font-weight: 700; color: #1C1917; }
      .kpv-item-mrp { font-size: 11.5px; text-decoration: line-through; color: #A8A29E; }
      .kpv-qty-stepper { display: inline-flex; align-items: center; border: 1px solid #D6D3D1; border-radius: 6px; background: #FAF7F2; }
      .kpv-qty-stepper button { width: 26px; height: 26px; border: none; background: none; font-weight: 600; font-size: 14px; cursor: pointer; color: #44403C; }
      .kpv-qty-stepper span { padding: 0 8px; font-size: 12px; font-weight: 600; }
      .kpv-item-remove { position: absolute; top: 8px; right: 10px; background: none; border: none; font-size: 20px; color: #A8A29E; cursor: pointer; }
      .kpv-item-remove:hover { color: #EF4444; }

      .kpv-empty-cart { text-align: center; padding: 60px 20px; margin: auto; }
      .kpv-btn-shop-now { display: inline-block; background: #C49432; color: #FFF; font-size: 13px; font-weight: 600; padding: 12px 24px; border-radius: 25px; text-decoration: none; }

      .kpv-drawer-footer { padding: 20px 24px; background: #FFF; border-top: 1px solid rgba(196,148,50,0.2); }
      .kpv-summary-row { display: flex; justify-content: space-between; font-size: 13px; color: #78716C; margin-bottom: 8px; }
      .kpv-total-row { font-size: 17px; font-weight: 700; color: #1C1917; margin-top: 12px; padding-top: 12px; border-top: 1px dashed rgba(196,148,50,0.3); }
      .kpv-btn-checkout { width: 100%; padding: 14px; background: linear-gradient(135deg, #ECCF8D, #C4983E); color: #1A1A1A; border: none; border-radius: 12px; font-size: 14px; font-weight: 700; cursor: pointer; margin-top: 14px; text-transform: uppercase; letter-spacing: 0.05em; }
      .kpv-btn-checkout:hover { filter: brightness(1.05); }
      .kpv-btn-wa { width: 100%; padding: 12px; background: #25D366; color: #FFF; border: none; border-radius: 12px; font-size: 13px; font-weight: 600; cursor: pointer; margin-top: 8px; display: flex; align-items: center; justify-content: center; gap: 6px; text-decoration: none; }

      /* Checkout Modal */
      .kpv-checkout-modal {
        position: fixed; top: 50%; left: 50%; transform: translate(-50%, -50%) scale(0.94);
        width: min(580px, calc(100% - 32px)); max-height: 90vh; background: #FFF;
        border-radius: 20px; z-index: 10002; opacity: 0; pointer-events: none;
        box-shadow: 0 25px 60px rgba(0,0,0,0.25); display: flex; flex-direction: column;
        transition: all 0.3s cubic-bezier(0.16, 1, 0.3, 1);
      }
      .kpv-checkout-modal.open { transform: translate(-50%, -50%) scale(1); opacity: 1; pointer-events: auto; }
      .kpv-co-header { display: flex; justify-content: space-between; align-items: center; padding: 20px 24px; border-bottom: 1px solid #F0ECE4; }
      .kpv-co-close { background: none; border: none; font-size: 28px; cursor: pointer; color: #78716C; }
      .kpv-co-body { padding: 24px; overflow-y: auto; }
      .kpv-form-section-title { font-size: 11.5px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.12em; color: #9A7424; margin-bottom: 12px; }
      .kpv-form-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; margin-bottom: 12px; }
      .kpv-field-wrap { display: flex; flex-direction: column; gap: 4px; }
      .kpv-field-wrap label { font-size: 11px; font-weight: 600; color: #44403C; text-transform: uppercase; letter-spacing: 0.05em; }
      .kpv-field-wrap input { padding: 10px 14px; border: 1px solid #D6D3D1; border-radius: 8px; font-size: 13px; font-family: inherit; }
      .kpv-field-wrap input:focus { outline: none; border-color: #C49432; }

      .kpv-coupon-box { display: flex; gap: 8px; margin-bottom: 6px; }
      .kpv-coupon-box input { flex: 1; padding: 10px 14px; border: 1px solid #D6D3D1; border-radius: 8px; font-size: 13px; }
      .kpv-coupon-box button { padding: 10px 18px; background: #FAF5EB; border: 1px solid #C49432; color: #9A7424; font-weight: 700; border-radius: 8px; cursor: pointer; font-size: 12px; }
      .kpv-coupon-status { font-size: 12px; margin-bottom: 12px; }
      .kpv-coupon-status.ok { color: #10B981; }
      .kpv-coupon-status.err { color: #EF4444; }

      .kpv-order-review-box { background: #FAF7F2; border: 1px solid rgba(196,148,50,0.25); border-radius: 12px; padding: 16px; margin: 18px 0; }
      .kpv-rev-row { display: flex; justify-content: space-between; font-size: 13px; color: #78716C; margin-bottom: 6px; }
      .kpv-rev-total { font-size: 16px; font-weight: 700; color: #1C1917; margin-top: 10px; padding-top: 10px; border-top: 1px dashed rgba(196,148,50,0.3); }
      .kpv-btn-pay-now { width: 100%; padding: 15px; background: linear-gradient(135deg, #ECCF8D, #C4983E); color: #1A1A1A; border: none; border-radius: 12px; font-size: 14.5px; font-weight: 700; cursor: pointer; text-transform: uppercase; letter-spacing: 0.06em; }

      /* Toast & Success */
      .kpv-toast {
        position: fixed; bottom: 24px; left: 50%; transform: translateX(-50%) translateY(100px);
        background: #1C1917; color: #FFF; padding: 12px 24px; border-radius: 30px;
        font-size: 13px; font-weight: 500; z-index: 100000; box-shadow: 0 10px 30px rgba(0,0,0,0.25);
        opacity: 0; transition: all 0.3s cubic-bezier(0.16, 1, 0.3, 1); pointer-events: none;
      }
      .kpv-toast.show { transform: translateX(-50%) translateY(0); opacity: 1; pointer-events: auto; }
      .kpv-toast.success { background: #064E3B; color: #A7F3D0; border: 1px solid #10B981; }
      .kpv-toast.error { background: #7F1D1D; color: #FECACA; border: 1px solid #EF4444; }
      .kpv-toast.warn { background: #78350F; color: #FDE68A; border: 1px solid #F59E0B; }

      .kpv-success-overlay {
        position: fixed; inset: 0; background: rgba(20, 16, 12, 0.75); backdrop-filter: blur(10px);
        z-index: 100005; display: flex; align-items: center; justify-content: center; padding: 20px;
      }
      .kpv-success-card {
        background: #FFF; border-radius: 24px; max-width: 480px; width: 100%;
        padding: 36px 28px; text-align: center; box-shadow: 0 30px 80px rgba(0,0,0,0.3);
      }
    `;
    document.head.appendChild(style);
  }

  // ── 8. PUBLIC API EXPOSURE ──
  window.KaapavStore = {
    CONFIG,
    fetchProducts,
    getProducts: () => products,
    getProductBySku: (sku) => products.find(p => p.sku === String(sku)),
    getCart: () => cart,
    getCartTotals,
    addToCart,
    updateCartQty,
    removeFromCart,
    openCartDrawer,
    closeCartDrawer,
    openCheckoutModal,
    closeCheckoutModal,
    applyCoupon,
    lookupPincode,
    handleCheckoutSubmit,
    orderViaWhatsApp,
    toast,
    trackEvent,
    getUrlParam,
    getSkuFromPath
  };

  // Auto initialize on DOM ready
  document.addEventListener("DOMContentLoaded", () => {
    injectStyles();
    loadCart();
    fetchProducts();
  });

})(window, document);
