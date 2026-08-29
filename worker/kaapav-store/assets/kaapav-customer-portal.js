/**
 * KAAPAV CUSTOMER ACCOUNT, ORDERS, WISHLIST & 7-DAY RETURN/EXCHANGE PORTAL
 * Production Engine for kaapav.com
 */

(function() {
  const CUSTOMER_API = 'https://wa.kaapav.com/api/customer';
  const WA_NUMBER = '919148330016';
  const WA_LINK = 'https://wa.me/' + WA_NUMBER;

  let customerProfile = null;
  let customerAddress = null;
  let customerWishlist = [];
  let ordersCache = [];
  let pendingAuthEmail = '';
  let activeReturnOrderId = '';
  let returnRequestSubmitting = false;

  // ── Wishlist Local Store ──
  function getWishlistMap() {
    try {
      return JSON.parse(localStorage.getItem('kpv_wishlist_items') || '{}');
    } catch (e) {
      return {};
    }
  }

  function saveWishlistMap(map) {
    try {
      localStorage.setItem('kpv_wishlist_items', JSON.stringify(map));
      localStorage.setItem('kp_wl', JSON.stringify(Object.keys(map)));
    } catch (e) {}
    updateWishlistCount();
  }

  function getWishlistCount() {
    return Object.keys(getWishlistMap()).length;
  }

  function updateWishlistCount() {
    const count = getWishlistCount();
    document.querySelectorAll('#hdrWishlistCount, .hdr-wl-badge, .kpv-wl-count').forEach(el => {
      el.textContent = count;
      el.style.display = count > 0 ? 'inline-block' : 'none';
    });
  }

  function toggleWishlist(sku, productData = {}) {
    if (!sku) return;
    const map = getWishlistMap();
    const isAdding = !map[sku];

    if (isAdding) {
      map[sku] = {
        sku: sku,
        name: productData.name || 'Fine Jewellery',
        price: Number(productData.price) || 299,
        image: productData.image || productData.image_url || './assets/logo.png',
        category: productData.category || 'Jewellery',
        addedAt: Date.now()
      };
      saveWishlistMap(map);
      showToast('Added to Wishlist ❤️');
      if (hasValidCustomerToken()) {
        customerApi('/wishlist', { method: 'POST', body: JSON.stringify({ sku }) }).catch(() => {});
      }
    } else {
      delete map[sku];
      saveWishlistMap(map);
      showToast('Removed from Wishlist');
      if (hasValidCustomerToken()) {
        customerApi(`/wishlist/${encodeURIComponent(sku)}`, { method: 'DELETE' }).catch(() => {});
      }
    }

    renderWishlist();
  }

  // ── Session Helpers ──
  function getCustomerToken() {
    return String(localStorage.getItem('kp_customer_token') || '').trim();
  }

  function getCustomerTokenExpiry() {
    return String(localStorage.getItem('kp_customer_token_expires') || '').trim();
  }

  function hasValidCustomerToken() {
    const token = getCustomerToken();
    const exp = getCustomerTokenExpiry();
    if (!token || !exp) return false;
    const t = Date.parse(exp);
    return Number.isFinite(t) && t > Date.now();
  }

  function saveCustomerSession(data) {
    if (data?.token) localStorage.setItem('kp_customer_token', data.token);
    if (data?.expiresAt) localStorage.setItem('kp_customer_token_expires', data.expiresAt);
    if (data?.account?.email) localStorage.setItem('customerEmail', data.account.email);
    if (data?.account?.phone) localStorage.setItem('customerPhone', data.account.phone);
    customerProfile = data?.account || null;
    updateHeaderAccountBtn();
  }

  function clearCustomerSession() {
    localStorage.removeItem('kp_customer_token');
    localStorage.removeItem('kp_customer_token_expires');
    customerProfile = null;
    customerAddress = null;
    customerWishlist = [];
    ordersCache = [];
    updateHeaderAccountBtn();
  }

  async function customerApi(path, opts = {}) {
    const headers = {
      ...(opts.headers || {}),
      'Content-Type': 'application/json',
    };
    const token = getCustomerToken();
    if (token) {
      headers.Authorization = `Bearer ${token}`;
    }

    const res = await fetch(`${CUSTOMER_API}${path}`, {
      ...opts,
      headers,
    });

    const data = await res.json().catch(() => ({}));
    if (!res.ok || data.success === false) {
      throw new Error(data.error || data.message || 'Request failed');
    }
    return data;
  }

  function esc(v) {
    return String(v ?? '').replace(/[&<>"']/g, m => ({
      '&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#039;'
    }[m]));
  }

  function money(n) {
    return '₹' + Number(n || 0).toLocaleString('en-IN');
  }

  function fmtDate(v) {
    if (!v) return '-';
    try {
      return new Date(String(v).replace(' ', 'T')).toLocaleDateString('en-IN', {
        day: '2-digit', month: 'short', year: 'numeric'
      });
    } catch { return String(v); }
  }

  function showToast(msg) {
    if (window.toast && typeof window.toast === 'function') {
      window.toast(msg);
    } else {
      let t = document.getElementById('toast') || document.getElementById('kpvPortalToast');
      if (!t) {
        t = document.createElement('div');
        t.id = 'kpvPortalToast';
        t.style.cssText = 'position:fixed;bottom:30px;left:50%;transform:translateX(-50%);background:#1C1917;color:#fff;padding:12px 24px;border-radius:30px;font-size:13px;font-weight:500;z-index:9999999;transition:0.3s;box-shadow:0 10px 30px rgba(0,0,0,0.3)';
        document.body.appendChild(t);
      }
      t.textContent = msg;
      t.style.opacity = '1';
      t.style.display = 'block';
      setTimeout(() => { t.style.opacity = '0'; setTimeout(() => t.style.display = 'none', 300); }, 2500);
    }
  }

  // ── Inject DOM Drawers & Modals ──
  function injectPortalDOM() {
    if (document.getElementById('customerPortalDrw')) return;

    const portalHTML = `
      <!-- Customer Account & Orders Drawer -->
      <div class="kpv-portal-drw" id="customerPortalDrw">
        <div class="kpv-portal-bg" onclick="window.KaapavPortal.close()"></div>
        <div class="kpv-portal-panel">
          <div class="kpv-drw-hdr">
            <span class="kpv-drw-title" id="kpvPortalTitle">Account</span>
            <button class="kpv-drw-close" onclick="window.KaapavPortal.close()">✕</button>
          </div>
          <div class="kpv-drw-body" id="kpvPortalBody"></div>
          <div class="kpv-drw-footer" id="kpvPortalFooter"></div>
        </div>
      </div>

      <!-- Wishlist Drawer -->
      <div class="kpv-portal-drw" id="kpvWishlistDrw">
        <div class="kpv-portal-bg" onclick="window.KaapavPortal.closeWishlist()"></div>
        <div class="kpv-portal-panel">
          <div class="kpv-drw-hdr">
            <span class="kpv-drw-title">Your Wishlist (<span id="kpvWlCountHeader">0</span>)</span>
            <button class="kpv-drw-close" onclick="window.KaapavPortal.closeWishlist()">✕</button>
          </div>
          <div class="kpv-drw-body" id="kpvWishlistBody"></div>
          <div class="kpv-drw-footer" id="kpvWishlistFooter"></div>
        </div>
      </div>

      <!-- Order Details Modal -->
      <div class="kpv-portal-mo" id="kpvOrderDetailMo">
        <div class="kpv-portal-box">
          <div class="kpv-drw-hdr">
            <span class="kpv-drw-title">Order Details</span>
            <button class="kpv-drw-close" onclick="window.KaapavPortal.closeOrderDetails()">✕</button>
          </div>
          <div class="kpv-drw-body" id="kpvOrderDetailBody"></div>
        </div>
      </div>

      <!-- 7-Day Return / Exchange Modal -->
      <div class="kpv-portal-mo" id="kpvReturnRequestMo">
        <div class="kpv-portal-box">
          <div class="kpv-drw-hdr">
            <span class="kpv-drw-title">Return / Exchange</span>
            <button class="kpv-drw-close" onclick="window.KaapavPortal.closeReturnRequest()">✕</button>
          </div>
          <div class="kpv-drw-body" id="kpvReturnRequestBody"></div>
        </div>
      </div>

      <!-- Saved Address Modal -->
      <div class="kpv-portal-mo" id="kpvSavedAddressMo">
        <div class="kpv-portal-box">
          <div class="kpv-drw-hdr">
            <span class="kpv-drw-title">Delivery Address</span>
            <button class="kpv-drw-close" onclick="window.KaapavPortal.closeSavedAddress()">✕</button>
          </div>
          <div class="kpv-drw-body" id="kpvSavedAddressBody"></div>
        </div>
      </div>
    `;

    document.body.insertAdjacentHTML('beforeend', portalHTML);
  }

  // ── Wishlist View ──
  function openWishlist() {
    injectPortalDOM();
    document.getElementById('kpvWishlistDrw').classList.add('on');
    renderWishlist();
  }

  function closeWishlist() {
    const d = document.getElementById('kpvWishlistDrw');
    if (d) d.classList.remove('on');
  }

  function renderWishlist() {
    const map = getWishlistMap();
    const items = Object.values(map);
    const bodyEl = document.getElementById('kpvWishlistBody');
    const headCount = document.getElementById('kpvWlCountHeader');
    const footEl = document.getElementById('kpvWishlistFooter');

    if (headCount) headCount.textContent = items.length;
    updateWishlistCount();

    if (!items.length) {
      if (bodyEl) {
        bodyEl.innerHTML = `
          <div style="text-align:center;padding:60px 20px;color:#78716C">
            <div style="font-size:38px;margin-bottom:12px">🤍</div>
            <strong style="display:block;font-size:16px;color:#1C1917;margin-bottom:4px">Your wishlist is empty</strong>
            Save your favourite jewellery pieces to view them anytime.
          </div>
        `;
      }
      if (footEl) footEl.innerHTML = `<button class="kpv-btn-secondary" onclick="window.KaapavPortal.closeWishlist()">Continue Shopping</button>`;
      return;
    }

    if (bodyEl) {
      bodyEl.innerHTML = items.map(item => `
        <div style="display:flex;gap:14px;padding:12px 0;border-bottom:1px solid #EDE8DF;align-items:center">
          <img src="${item.image || './assets/logo.png'}" style="width:60px;height:60px;border-radius:10px;object-fit:cover;background:#F5F0E8;border:1px solid #EDE8DF" onerror="this.src='./assets/logo.png'">
          <div style="flex:1;min-width:0">
            <div style="font-size:13px;font-weight:600;color:#1C1917;white-space:nowrap;overflow:hidden;text-overflow:ellipsis">${esc(item.name)}</div>
            <div style="font-size:12.5px;color:#9A7424;font-weight:700;margin-top:2px">${money(item.price)}</div>
            <div style="font-size:10.5px;color:#78716C">SKU: ${esc(item.sku)}</div>
          </div>
          <div style="display:flex;flex-direction:column;gap:6px;align-items:flex-end">
            <button onclick="window.KaapavStore ? window.KaapavStore.addToCart('${esc(item.sku)}', 1, true) : location.href='./product/index.html?sku=${encodeURIComponent(item.sku)}'" style="padding:6px 12px;background:#1C1917;color:#E8C170;border:none;border-radius:6px;font-size:11.5px;font-weight:600;cursor:pointer">+ Bag</button>
            <button onclick="window.KaapavPortal.toggleWishlist('${esc(item.sku)}')" style="background:none;border:none;color:#A8A29E;cursor:pointer;font-size:14px" title="Remove">🗑</button>
          </div>
        </div>
      `).join('');
    }

    if (footEl) {
      footEl.innerHTML = `
        <button class="kpv-btn-primary" onclick="window.KaapavPortal.closeWishlist(); location.href='./shop/index.html'">Explore More Jewellery</button>
      `;
    }
  }

  // ── Render Views ──
  async function refreshCustomerProfile() {
    if (!hasValidCustomerToken()) {
      clearCustomerSession();
      return null;
    }
    try {
      const data = await customerApi('/me', { method: 'GET' });
      customerProfile = data.account || null;
      customerAddress = data.address || null;
      customerWishlist = Array.isArray(data.wishlist) ? data.wishlist : [];
      if (customerProfile?.email) localStorage.setItem('customerEmail', customerProfile.email);
      updateHeaderAccountBtn();
      return data;
    } catch (e) {
      clearCustomerSession();
      return null;
    }
  }

  function updateHeaderAccountBtn() {
    const btns = document.querySelectorAll('.hdr-btn-signin, a[href*="admin/index.html"], .kpv-account-btn');
    const isLogged = hasValidCustomerToken();

    btns.forEach(btn => {
      if (btn.classList.contains('hdr-btn-circle')) return;
      if (isLogged && customerProfile?.email) {
        const initial = (customerProfile.name || customerProfile.email).charAt(0).toUpperCase();
        btn.innerHTML = `<span style="display:inline-flex;align-items:center;justify-content:center;width:20px;height:20px;border-radius:50%;background:#9A7424;color:#fff;font-size:10px;margin-right:6px;font-weight:700">${esc(initial)}</span> Account`;
        btn.removeAttribute('href');
        btn.style.cursor = 'pointer';
        btn.onclick = (e) => { e.preventDefault(); openPortal(); };
      } else {
        btn.textContent = 'Sign in';
        btn.removeAttribute('href');
        btn.style.cursor = 'pointer';
        btn.onclick = (e) => { e.preventDefault(); openPortal(); };
      }
    });

    updateWishlistCount();
  }

  function openPortal() {
    injectPortalDOM();
    document.getElementById('customerPortalDrw').classList.add('on');
    renderHome();
  }

  function closePortal() {
    const d = document.getElementById('customerPortalDrw');
    if (d) d.classList.remove('on');
  }

  async function renderHome() {
    const isLogged = hasValidCustomerToken();
    const titleEl = document.getElementById('kpvPortalTitle');
    const bodyEl = document.getElementById('kpvPortalBody');
    const footEl = document.getElementById('kpvPortalFooter');

    titleEl.textContent = isLogged ? 'My Account' : 'Login / Sign up';

    if (isLogged) {
      if (!customerProfile) {
        bodyEl.innerHTML = `<div style="text-align:center;padding:40px 20px;color:#78716C">Loading your KAAPAV profile...</div>`;
        await refreshCustomerProfile();
      }

      const email = customerProfile?.email || localStorage.getItem('customerEmail') || 'Customer';
      const initial = email.charAt(0).toUpperCase();
      const wlCount = getWishlistCount();

      bodyEl.innerHTML = `
        <div class="kpv-pf-hero">
          <div class="kpv-pf-avatar">${esc(initial)}</div>
          <div class="kpv-pf-title">Welcome to KAAPAV</div>
          <div class="kpv-pf-sub">Logged in as <strong>${esc(email)}</strong></div>
        </div>

        <div class="kpv-pf-mini">
          <div class="kpv-pf-stat" onclick="window.KaapavPortal.openOrders()">
            <strong>${ordersCache.length || '•'}</strong>
            <span>Orders</span>
          </div>
          <div class="kpv-pf-stat" onclick="window.KaapavPortal.openWishlist()">
            <strong>${wlCount}</strong>
            <span>Wishlist</span>
          </div>
          <div class="kpv-pf-stat" onclick="window.openCartDrawer ? window.openCartDrawer() : null">
            <strong>Bag</strong>
            <span>Cart</span>
          </div>
        </div>

        <div class="kpv-pf-card">
          <div class="kpv-pf-row" onclick="window.KaapavPortal.openOrders()">
            <div class="kpv-pf-left">
              <div class="kpv-pf-ico">📦</div>
              <div>
                <div class="kpv-pf-name">My Orders</div>
                <div class="kpv-pf-note">View status, tracking, and 7-day returns</div>
              </div>
            </div>
            <div class="kpv-pf-arr">›</div>
          </div>

          <div class="kpv-pf-row" onclick="window.KaapavPortal.openWishlist()">
            <div class="kpv-pf-left">
              <div class="kpv-pf-ico">🤍</div>
              <div>
                <div class="kpv-pf-name">Wishlist</div>
                <div class="kpv-pf-note">${wlCount} saved jewellery piece${wlCount === 1 ? '' : 's'}</div>
              </div>
            </div>
            <div class="kpv-pf-arr">›</div>
          </div>

          <div class="kpv-pf-row" onclick="window.KaapavPortal.openSavedAddress()">
            <div class="kpv-pf-left">
              <div class="kpv-pf-ico">📍</div>
              <div>
                <div class="kpv-pf-name">Delivery Address</div>
                <div class="kpv-pf-note">Manage saved shipping details</div>
              </div>
            </div>
            <div class="kpv-pf-arr">›</div>
          </div>

          <div class="kpv-pf-row" onclick="window.open('${WA_LINK}', '_blank')">
            <div class="kpv-pf-left">
              <div class="kpv-pf-ico">💬</div>
              <div>
                <div class="kpv-pf-name">WhatsApp Concierge</div>
                <div class="kpv-pf-note">Chat with Kaapav care</div>
              </div>
            </div>
            <div class="kpv-pf-arr">›</div>
          </div>
        </div>
      `;

      footEl.innerHTML = `
        <button class="kpv-btn-secondary" onclick="window.KaapavPortal.logout()" style="color:#DC2626;border-color:#FCA5A5">Sign Out</button>
      `;
      return;
    }

    // Guest login view
    const storedEmail = localStorage.getItem('customerEmail') || '';
    bodyEl.innerHTML = `
      <div class="kpv-pf-hero">
        <div class="kpv-pf-avatar">👤</div>
        <div class="kpv-pf-title">Welcome to KAAPAV</div>
        <div class="kpv-pf-sub">Enter your email to view your orders, wishlist, 7-day return / exchange, and saved address.</div>
      </div>

      <div class="kpv-pf-card">
        <label class="kpv-form-lbl" for="kpv_auth_email">Email address</label>
        <input class="kpv-form-inp" id="kpv_auth_email" type="email" placeholder="name@domain.com" value="${esc(storedEmail)}">
        <button class="kpv-btn-primary" id="kpvSendOtpBtn" onclick="window.KaapavPortal.sendOtp()">Continue with Email OTP</button>
        <div style="font-size:11.5px;color:#78716C;text-align:center;margin-top:10px;line-height:1.5">
          New to Kaapav? Account is created automatically on your first login.
        </div>
      </div>
    `;

    footEl.innerHTML = `
      <button class="kpv-btn-secondary" onclick="window.KaapavPortal.close()">Continue Shopping</button>
    `;
  }

  async function sendOtp() {
    const input = document.getElementById('kpv_auth_email');
    const email = String(input?.value || pendingAuthEmail || '').trim().toLowerCase();

    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      showToast('Please enter a valid email address');
      return;
    }

    pendingAuthEmail = email;
    const btn = document.getElementById('kpvSendOtpBtn');
    if (btn) { btn.disabled = true; btn.textContent = 'Sending OTP...'; }

    try {
      const res = await fetch(`${CUSTOMER_API}/auth/send-otp`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email }),
      });
      const data = await res.json().catch(() => ({}));
      if (!res.ok || data.success === false) {
        throw new Error(data.error || data.message || 'Could not send OTP');
      }

      localStorage.setItem('customerEmail', email);
      renderOtpScreen(email);
      showToast('6-digit OTP sent to your email');
    } catch (e) {
      showToast(e.message || 'Could not send OTP');
      if (btn) { btn.disabled = false; btn.textContent = 'Continue with Email OTP'; }
    }
  }

  function renderOtpScreen(email) {
    const titleEl = document.getElementById('kpvPortalTitle');
    const bodyEl = document.getElementById('kpvPortalBody');
    const footEl = document.getElementById('kpvPortalFooter');

    titleEl.textContent = 'Verify OTP';
    bodyEl.innerHTML = `
      <div class="kpv-pf-hero">
        <div class="kpv-pf-avatar">✉️</div>
        <div class="kpv-pf-title">Enter Verification Code</div>
        <div class="kpv-pf-sub">We sent a 6-digit OTP to <strong>${esc(email)}</strong>.</div>
      </div>

      <div class="kpv-pf-card">
        <label class="kpv-form-lbl" for="kpv_auth_otp">6-digit OTP</label>
        <input class="kpv-form-inp" id="kpv_auth_otp" type="tel" maxlength="6" inputmode="numeric" placeholder="••••••" style="text-align:center;font-size:22px;letter-spacing:6px;font-weight:700">
        <button class="kpv-btn-primary" id="kpvVerifyBtn" onclick="window.KaapavPortal.verifyOtp()">Verify & Sign In</button>
        <button class="kpv-btn-secondary" onclick="window.KaapavPortal.sendOtp()">Resend OTP</button>
        <button class="kpv-btn-secondary" onclick="window.KaapavPortal.renderHome()">← Change Email</button>
        <div style="font-size:11px;color:#78716C;text-align:center;margin-top:10px">OTP is valid for 10 minutes.</div>
      </div>
    `;

    footEl.innerHTML = '';
    setTimeout(() => document.getElementById('kpv_auth_otp')?.focus(), 150);
  }

  async function verifyOtp() {
    const otp = String(document.getElementById('kpv_auth_otp')?.value || '').trim();
    if (!/^\d{6}$/.test(otp)) {
      showToast('Enter valid 6-digit OTP');
      return;
    }

    const btn = document.getElementById('kpvVerifyBtn');
    if (btn) { btn.disabled = true; btn.textContent = 'Verifying...'; }

    try {
      const data = await customerApi('/auth/verify-otp', {
        method: 'POST',
        body: JSON.stringify({
          email: pendingAuthEmail,
          otp,
          phone: localStorage.getItem('customerPhone') || '',
          customerId: localStorage.getItem('customer_id') || '',
        }),
      });

      saveCustomerSession(data);
      await refreshCustomerProfile();
      showToast('Logged in successfully');
      renderHome();
    } catch (e) {
      showToast(e.message || 'OTP verification failed');
      if (btn) { btn.disabled = false; btn.textContent = 'Verify & Sign In'; }
    }
  }

  async function logout() {
    try {
      if (getCustomerToken()) await customerApi('/logout', { method: 'POST' });
    } catch (e) {}
    clearCustomerSession();
    showToast('Signed out successfully');
    renderHome();
  }

  // ── Orders & 7-Day Return Logic ──
  async function openOrders() {
    injectPortalDOM();
    document.getElementById('customerPortalDrw').classList.add('on');
    document.getElementById('kpvPortalTitle').textContent = 'My Orders';

    if (!hasValidCustomerToken()) {
      renderHome();
      return;
    }

    const bodyEl = document.getElementById('kpvPortalBody');
    const footEl = document.getElementById('kpvPortalFooter');

    bodyEl.innerHTML = `<div style="text-align:center;padding:40px 20px;color:#78716C">Loading your orders...</div>`;
    footEl.innerHTML = `<button class="kpv-btn-secondary" onclick="window.KaapavPortal.renderHome()">← Back to Account</button>`;

    await fetchOrders();
  }

  async function fetchOrders() {
    try {
      const data = await customerApi(`/orders?t=${Date.now()}`, { method: 'GET' });
      ordersCache = data.orders || [];
      renderOrdersList(ordersCache);
    } catch (e) {
      document.getElementById('kpvPortalBody').innerHTML = `
        <div style="text-align:center;padding:40px 20px;color:#78716C">
          <div style="font-size:32px;margin-bottom:10px">⚠️</div>
          Could not load orders.<br><span style="font-size:12px;color:#991B1B">${esc(e.message)}</span>
        </div>
      `;
    }
  }

  function parseItems(items) {
    if (Array.isArray(items)) return items;
    try {
      const p = JSON.parse(items || '[]');
      return Array.isArray(p) ? p : [];
    } catch { return []; }
  }

  function isReturnEligible(order) {
    return order?.return_eligible === true || Number(order?.return_eligible || 0) === 1;
  }

  function isOpenReturnRequest(req) {
    if (!req) return false;
    const closed = ['rejected', 'refunded', 'completed', 'cancelled'];
    return !closed.includes(String(req.status || '').toLowerCase());
  }

  function renderOrdersList(orders) {
    const bodyEl = document.getElementById('kpvPortalBody');
    if (!orders.length) {
      bodyEl.innerHTML = `
        <div style="text-align:center;padding:60px 20px;color:#78716C">
          <div style="font-size:36px;margin-bottom:12px">🛍️</div>
          <strong style="display:block;font-size:16px;color:#1C1917;margin-bottom:4px">No orders placed yet</strong>
          Browse our collections and place an order to track it here.
        </div>
      `;
      return;
    }

    bodyEl.innerHTML = orders.map(o => {
      const items = parseItems(o.items);
      const status = String(o.status || 'pending').toLowerCase();
      const paymentStatus = String(o.payment_status || 'unpaid').toLowerCase();
      const latestReturn = o.return_request || null;
      const openReturn = isOpenReturnRequest(latestReturn);
      const eligible = isReturnEligible(o);

      let badgeClass = status;
      if (paymentStatus === 'paid' && status === 'pending') badgeClass = 'paid';

      return `
        <div class="kpv-od-card">
          <div class="kpv-od-top">
            <div>
              <div class="kpv-od-id">#${esc(o.order_id)}</div>
              <div class="kpv-od-date">${fmtDate(o.created_at)}</div>
            </div>
            <span class="kpv-od-badge ${badgeClass}">${esc(status.toUpperCase())}</span>
          </div>

          <div class="kpv-od-items-preview">
            ${items.map(it => `
              <img class="kpv-od-thumb" src="${it.image || it.image_url || './assets/logo.png'}" alt="${esc(it.name || '')}" onerror="this.src='./assets/logo.png'">
            `).join('')}
          </div>

          <div class="kpv-od-summary-row">
            <span>${items.length} item${items.length === 1 ? '' : 's'}</span>
            <span>${money(o.total)}</span>
          </div>

          ${latestReturn ? `
            <div style="background:#FFFDF7;border:1px solid #E6C87C;border-radius:8px;padding:8px 10px;font-size:11.5px;color:#9A7424;margin-bottom:10px">
              Return Request: <strong>${esc((latestReturn.status || 'submitted').toUpperCase())}</strong>
            </div>
          ` : (eligible ? `
            <div style="background:#F0FDF4;border:1px solid #BBF7D0;border-radius:8px;padding:8px 10px;font-size:11.5px;color:#15803D;margin-bottom:10px">
              Eligible for 7-Day Return / Exchange
            </div>
          ` : '')}

          <div class="kpv-od-actions">
            <button class="kpv-od-btn" onclick="window.KaapavPortal.openOrderDetails('${esc(o.order_id)}')">View Details</button>
            ${eligible && !openReturn ? `
              <button class="kpv-od-btn return" onclick="window.KaapavPortal.openReturnRequest('${esc(o.order_id)}')">Return / Exchange</button>
            ` : ''}
            ${o.tracking_url ? `<a class="kpv-od-btn" href="${esc(o.tracking_url)}" target="_blank">Track</a>` : ''}
          </div>
        </div>
      `;
    }).join('');
  }

  function openOrderDetails(orderId) {
    const order = ordersCache.find(x => String(x.order_id) === String(orderId));
    if (!order) return;

    const items = parseItems(order.items);
    const latestReturn = order.return_request || null;
    const eligible = isReturnEligible(order);

    const bodyEl = document.getElementById('kpvOrderDetailBody');
    bodyEl.innerHTML = `
      <div class="kpv-pf-card">
        <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:10px">
          <strong style="font-size:14px;color:#1C1917">Order #${esc(order.order_id)}</strong>
          <span class="kpv-od-badge ${String(order.status||'').toLowerCase()}">${esc((order.status||'').toUpperCase())}</span>
        </div>
        <div style="font-size:12px;color:#78716C;line-height:1.6">
          Placed on: ${fmtDate(order.created_at)}<br>
          Payment: <strong>${esc(order.payment_status || 'unpaid')}</strong>
        </div>
      </div>

      <div class="kpv-pf-card">
        <div class="kpv-form-lbl">Items Ordered</div>
        ${items.map(it => `
          <div style="display:flex;gap:12px;align-items:center;padding:8px 0;border-bottom:1px solid #F5F0E8">
            <img class="kpv-od-thumb" src="${it.image || it.image_url || './assets/logo.png'}" onerror="this.src='./assets/logo.png'">
            <div style="flex:1;min-width:0">
              <div style="font-size:12.5px;font-weight:600;color:#1C1917">${esc(it.name || it.sku)}</div>
              <div style="font-size:11px;color:#78716C">Qty: ${it.qty || 1} • SKU: ${esc(it.sku || '')}</div>
            </div>
            <div style="font-size:12.5px;font-weight:700;color:#1C1917">${money((it.price || 0) * (it.qty || 1))}</div>
          </div>
        `).join('')}
      </div>

      <div class="kpv-pf-card">
        <div class="kpv-form-lbl">Bill Summary</div>
        <div style="display:flex;justify-content:space-between;font-size:12.5px;margin-bottom:6px"><span>Subtotal</span><span>${money(order.subtotal || order.total)}</span></div>
        <div style="display:flex;justify-content:space-between;font-size:12.5px;margin-bottom:6px"><span>Shipping</span><span>${Number(order.shipping_cost || 0) === 0 ? 'FREE' : money(order.shipping_cost)}</span></div>
        <div style="display:flex;justify-content:space-between;font-size:14px;font-weight:700;color:#1C1917;border-top:1px solid #F5F0E8;padding-top:8px"><span>Total Amount</span><span>${money(order.total)}</span></div>
      </div>

      ${eligible ? `
        <button class="kpv-btn-primary" onclick="window.KaapavPortal.closeOrderDetails(); window.KaapavPortal.openReturnRequest('${esc(order.order_id)}')">
          Start 7-Day Return / Exchange
        </button>
      ` : ''}
    `;

    document.getElementById('kpvOrderDetailMo').classList.add('on');
  }

  function closeOrderDetails() {
    const m = document.getElementById('kpvOrderDetailMo');
    if (m) m.classList.remove('on');
  }

  // ── 7-Day Return & Exchange Workflow ──
  function openReturnRequest(orderId) {
    const order = ordersCache.find(x => String(x.order_id) === String(orderId));
    if (!order) return;

    activeReturnOrderId = String(order.order_id);
    const items = parseItems(order.items);
    const bodyEl = document.getElementById('kpvReturnRequestBody');

    bodyEl.innerHTML = `
      <div class="kpv-rr-policy">
        <strong>7-Day Return / Exchange Window</strong><br>
        This order is eligible within 7 days of delivery. Submitting creates an instant return/exchange request in our system. A reverse pickup will be scheduled.
      </div>

      <label class="kpv-form-lbl" for="kpv_rr_type">Request Type</label>
      <select class="kpv-form-inp" id="kpv_rr_type">
        <option value="return">Return for Full Refund</option>
        <option value="exchange">Exchange with Replacement SKU</option>
      </select>

      <div class="kpv-form-lbl">Items Scope</div>
      <div class="kpv-rr-choice">
        <label class="kpv-rr-radio">
          <input type="radio" name="kpv_rr_scope" value="full_order" checked onchange="document.getElementById('kpvRrItemsBox').classList.remove('on')">
          Full Order
        </label>
        <label class="kpv-rr-radio">
          <input type="radio" name="kpv_rr_scope" value="items" onchange="document.getElementById('kpvRrItemsBox').classList.add('on')">
          Selected Items
        </label>
      </div>

      <div class="kpv-rr-items-box" id="kpvRrItemsBox">
        ${items.map((it, idx) => `
          <div class="kpv-rr-item-row">
            <input class="kpv-rr-check" type="checkbox" data-index="${idx}" data-sku="${esc(it.sku || '')}">
            <div>
              <div class="kpv-rr-item-name">${esc(it.name || it.sku)}</div>
              <div class="kpv-rr-item-sub">SKU: ${esc(it.sku || '')} • Ordered: ${it.qty || 1}</div>
            </div>
            <input class="kpv-rr-qty-inp" type="number" min="1" max="${it.qty || 1}" value="1">
          </div>
        `).join('')}
      </div>

      <label class="kpv-form-lbl" for="kpv_rr_reason">Reason</label>
      <select class="kpv-form-inp" id="kpv_rr_reason">
        <option value="damaged">Damaged / Defective piece</option>
        <option value="wrong_item">Wrong item delivered</option>
        <option value="not_as_expected">Not as expected in look/feel</option>
        <option value="size_issue">Size / Fit issue</option>
        <option value="changed_mind">Changed mind</option>
        <option value="other">Other reason</option>
      </select>

      <label class="kpv-form-lbl" for="kpv_rr_notes">Reason Details</label>
      <textarea class="kpv-form-inp" id="kpv_rr_notes" rows="3" placeholder="Please describe the issue clearly..."></textarea>

      <button class="kpv-btn-primary" id="kpvSubmitReturnBtn" onclick="window.KaapavPortal.submitReturnRequest()">Submit Return / Exchange Request</button>
    `;

    document.getElementById('kpvReturnRequestMo').classList.add('on');
  }

  function closeReturnRequest() {
    const m = document.getElementById('kpvReturnRequestMo');
    if (m) m.classList.remove('on');
    activeReturnOrderId = '';
  }

  async function submitReturnRequest() {
    if (returnRequestSubmitting || !activeReturnOrderId) return;
    const reasonText = String(document.getElementById('kpv_rr_notes')?.value || '').trim();
    if (reasonText.length < 3) {
      showToast('Please provide details for the reason');
      return;
    }

    const requestType = document.getElementById('kpv_rr_type')?.value || 'return';
    const requestScope = document.querySelector('input[name="kpv_rr_scope"]:checked')?.value || 'full_order';
    const reasonCode = document.getElementById('kpv_rr_reason')?.value || 'other';

    const selectedItems = [];
    if (requestScope === 'items') {
      document.querySelectorAll('#kpvRrItemsBox .kpv-rr-check:checked').forEach(c => {
        const row = c.closest('.kpv-rr-item-row');
        const qty = Number(row?.querySelector('.kpv-rr-qty-inp')?.value || 1);
        selectedItems.push({
          line_index: Number(c.dataset.index),
          sku: c.dataset.sku,
          quantity: qty,
        });
      });
      if (!selectedItems.length) {
        showToast('Please select at least one item');
        return;
      }
    }

    returnRequestSubmitting = true;
    const btn = document.getElementById('kpvSubmitReturnBtn');
    if (btn) { btn.disabled = true; btn.textContent = 'Submitting Request...'; }

    try {
      const data = await customerApi(`/orders/${encodeURIComponent(activeReturnOrderId)}/return-requests`, {
        method: 'POST',
        body: JSON.stringify({
          request_type: requestType,
          request_scope: requestScope,
          reason_code: reasonCode,
          reason_text: reasonText,
          items: selectedItems,
        }),
      });

      closeReturnRequest();
      showToast('Return request submitted: ' + (data?.request?.request_id || ''));
      await fetchOrders();
    } catch (e) {
      showToast(e.message || 'Failed to submit return request');
    } finally {
      returnRequestSubmitting = false;
      if (btn) { btn.disabled = false; btn.textContent = 'Submit Return / Exchange Request'; }
    }
  }

  // ── Saved Address Management ──
  function openSavedAddress() {
    const bodyEl = document.getElementById('kpvSavedAddressBody');
    const addr = customerAddress || {};

    bodyEl.innerHTML = `
      <div class="kpv-pf-card">
        <label class="kpv-form-lbl" for="kpv_addr_name">Full Name</label>
        <input class="kpv-form-inp" id="kpv_addr_name" value="${esc(addr.name || '')}" placeholder="Full Name">

        <label class="kpv-form-lbl" for="kpv_addr_phone">Contact Phone</label>
        <input class="kpv-form-inp" id="kpv_addr_phone" value="${esc(addr.phone || '')}" placeholder="10-digit mobile number">

        <label class="kpv-form-lbl" for="kpv_addr_street">Street Address</label>
        <textarea class="kpv-form-inp" id="kpv_addr_street" rows="2" placeholder="House/Flat no, Building, Street, Area">${esc(addr.address || '')}</textarea>

        <div style="display:grid;grid-template-columns:1fr 1fr;gap:10px">
          <div>
            <label class="kpv-form-lbl" for="kpv_addr_city">City</label>
            <input class="kpv-form-inp" id="kpv_addr_city" value="${esc(addr.city || '')}" placeholder="City">
          </div>
          <div>
            <label class="kpv-form-lbl" for="kpv_addr_pincode">Pincode</label>
            <input class="kpv-form-inp" id="kpv_addr_pincode" value="${esc(addr.pincode || '')}" placeholder="6-digit Pincode">
          </div>
        </div>

        <label class="kpv-form-lbl" for="kpv_addr_state">State</label>
        <input class="kpv-form-inp" id="kpv_addr_state" value="${esc(addr.state || '')}" placeholder="State">

        <button class="kpv-btn-primary" id="kpvSaveAddrBtn" onclick="window.KaapavPortal.saveAddress()">Save Delivery Address</button>
      </div>
    `;

    document.getElementById('kpvSavedAddressMo').classList.add('on');
  }

  function closeSavedAddress() {
    const m = document.getElementById('kpvSavedAddressMo');
    if (m) m.classList.remove('on');
  }

  async function saveAddress() {
    const name = document.getElementById('kpv_addr_name')?.value?.trim();
    const phone = document.getElementById('kpv_addr_phone')?.value?.trim();
    const address = document.getElementById('kpv_addr_street')?.value?.trim();
    const city = document.getElementById('kpv_addr_city')?.value?.trim();
    const state = document.getElementById('kpv_addr_state')?.value?.trim();
    const pincode = document.getElementById('kpv_addr_pincode')?.value?.trim();

    if (!address || !pincode) {
      showToast('Address and Pincode are required');
      return;
    }

    const btn = document.getElementById('kpvSaveAddrBtn');
    if (btn) { btn.disabled = true; btn.textContent = 'Saving Address...'; }

    try {
      await customerApi('/address', {
        method: 'POST',
        body: JSON.stringify({ name, phone, address, city, state, pincode }),
      });
      customerAddress = { name, phone, address, city, state, pincode };
      closeSavedAddress();
      showToast('Address saved successfully');
    } catch (e) {
      showToast(e.message || 'Could not save address');
    } finally {
      if (btn) { btn.disabled = false; btn.textContent = 'Save Delivery Address'; }
    }
  }

  function autoWireCardWishlistButtons() {
    const wlMap = getWishlistMap();

    // 1. Wire all card grids (Category, Shop, Bestsellers, Related)
    const cards = document.querySelectorAll('.product-card, .spotlight-card, .oe_product_cart, .prod-card-v2, .compass-card, .o_wsale_product_grid_wrapper .oe_product, .related-card');
    cards.forEach(card => {
      if (card.querySelector('.kpv-card-wl-btn, .spotlight-wl-btn')) return;
      const titleEl = card.querySelector('h3, h4, h5, .o_wsale_products_item_title, .card-title, .spotlight-card-title, .related-card-title, strong');
      const imgEl = card.querySelector('img');
      const priceEl = card.querySelector('.oe_currency_value, .price, .product-price, .card-price, .spotlight-price, .related-card-price');
      const linkEl = card.querySelector('a[href*="sku="]');
      const skuFromLink = linkEl?.href ? new URL(linkEl.href, window.location.href).searchParams.get('sku') : null;
      const sku = skuFromLink || (imgEl?.alt?.match(/\[(\d+)\]/)?.[1]) || (card.getAttribute('data-sku')) || (titleEl?.textContent?.trim() || '');
      if (!sku) return;

      const isWl = Boolean(wlMap[sku]);
      const btn = document.createElement('button');
      btn.className = 'kpv-card-wl-btn' + (isWl ? ' active' : '');
      btn.innerHTML = isWl ? '❤️' : '🤍';
      btn.title = 'Add to Wishlist';
      btn.onclick = (e) => {
        e.preventDefault();
        e.stopPropagation();
        toggleWishlist(sku, {
          name: titleEl?.textContent?.trim() || sku,
          price: parseFloat(priceEl?.textContent?.replace(/[^\d.]/g, '') || 299),
          image: imgEl?.src || './assets/logo.png',
        });
        btn.classList.toggle('active');
        btn.innerHTML = btn.classList.contains('active') ? '❤️' : '🤍';
      };

      const mediaWrap = card.querySelector('.card-media-wrap, .spotlight-card-media, .oe_product_image, .card-media, .product-image, .related-card-media') || card;
      mediaWrap.style.position = 'relative';
      mediaWrap.appendChild(btn);
    });

    // 2. Wire Product Detail Page (PDP)
    wirePdpWishlistButton();
  }

  function wirePdpWishlistButton() {
    const ctaGroup = document.querySelector('.cta-actions-group');
    if (!ctaGroup || document.getElementById('btnPdpWishlist')) return;

    const skuMatch = new URLSearchParams(window.location.search).get('sku');
    const titleEl = document.getElementById('prodTitle');
    const priceEl = document.getElementById('prodPrice');
    const imgEl = document.getElementById('mainProdImage');
    const sku = skuMatch || titleEl?.textContent?.trim() || '';
    if (!sku) return;

    const wlMap = getWishlistMap();
    const isWl = Boolean(wlMap[sku]);

    const pdpBtn = document.createElement('button');
    pdpBtn.id = 'btnPdpWishlist';
    pdpBtn.className = 'btn-wishlist-pdp';
    pdpBtn.style.cssText = 'height:48px;padding:0 18px;background:#FAF7F2;border:1.5px solid rgba(196,148,50,0.35);border-radius:12px;display:flex;align-items:center;justify-content:center;gap:8px;font-size:13.5px;font-weight:600;color:#1C1917;cursor:pointer;transition:all 0.2s ease;';
    pdpBtn.innerHTML = `<span>${isWl ? '❤️' : '🤍'}</span> <span>${isWl ? 'Wishlisted' : 'Wishlist'}</span>`;
    pdpBtn.title = 'Save to Wishlist';

    pdpBtn.onclick = (e) => {
      e.preventDefault();
      const adding = !getWishlistMap()[sku];
      toggleWishlist(sku, {
        name: titleEl?.textContent?.trim() || sku,
        price: parseFloat(priceEl?.textContent?.replace(/[^\d.]/g, '') || 299),
        image: imgEl?.src || '../assets/logo.png',
      });
      pdpBtn.innerHTML = `<span>${adding ? '❤️' : '🤍'}</span> <span>${adding ? 'Wishlisted' : 'Wishlist'}</span>`;
    };

    ctaGroup.appendChild(pdpBtn);
  }

  // ── Global API Export ──
  window.KaapavPortal = {
    open: openPortal,
    close: closePortal,
    renderHome,
    sendOtp,
    verifyOtp,
    logout,
    openOrders,
    openOrderDetails,
    closeOrderDetails,
    openReturnRequest,
    closeReturnRequest,
    submitReturnRequest,
    openSavedAddress,
    closeSavedAddress,
    saveAddress,
    openWishlist,
    closeWishlist,
    toggleWishlist,
    renderWishlist,
    getWishlistCount,
    autoWireCardWishlistButtons,
    wirePdpWishlistButton
  };

  // Wire Global openWishlistToast to open Wishlist drawer
  window.openWishlistToast = openWishlist;

  // Initialize on load & observe DOM mutations
  document.addEventListener('DOMContentLoaded', () => {
    injectPortalDOM();
    updateHeaderAccountBtn();
    updateWishlistCount();
    autoWireCardWishlistButtons();
    if (hasValidCustomerToken()) {
      refreshCustomerProfile();
    }

    // Auto re-wire when product grids update
    const observer = new MutationObserver(() => {
      autoWireCardWishlistButtons();
    });
    observer.observe(document.body, { childList: true, subtree: true });
  });

})();
