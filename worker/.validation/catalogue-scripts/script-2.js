
const API = 'https://wa.kaapav.com/api/catalogue';
const EVENT_API = 'https://wa.kaapav.com/api/catalogue/events';
const ORDER_API = 'https://wa.kaapav.com/api/orders/catalogue';
const CUSTOMER_API = 'https://wa.kaapav.com/api/customer';
const WA = 'https://wa.me/919148330016';
const RZP_KEY = 'rzp_live_3G5rPyrp66kRAB';
const FREE_SHIP = 498;
const SHIP_COST = 50;
const PRODUCT_CACHE_KEY = 'kpv_catalogue_products_v1';
const PRODUCT_CACHE_MAX_AGE = 10 * 60 * 1000;
let razorpayLoader = null;

function loadRazorpay(){
  if(typeof Razorpay !== 'undefined') return Promise.resolve();
  if(razorpayLoader) return razorpayLoader;
  razorpayLoader = new Promise((resolve,reject)=>{
    const existing=document.querySelector('script[data-kpv-razorpay]');
    if(existing){
      existing.addEventListener('load',resolve,{once:true});
      existing.addEventListener('error',()=>reject(new Error('Razorpay failed to load')),{once:true});
      return;
    }
    const script=document.createElement('script');
    script.src='https://checkout.razorpay.com/v1/checkout.js';
    script.async=true;
    script.dataset.kpvRazorpay='1';
    script.onload=resolve;
    script.onerror=()=>reject(new Error('Razorpay failed to load'));
    document.head.appendChild(script);
  });
  return razorpayLoader;
}

function hydrateProductsFromCache(){
  try{
    const cached=JSON.parse(localStorage.getItem(PRODUCT_CACHE_KEY)||'null');
    if(!cached||!Array.isArray(cached.products)||Date.now()-Number(cached.ts||0)>PRODUCT_CACHE_MAX_AGE) return false;
    products=cached.products.map(p=>({...p,images:sjson(p.images,[]),tags:sjson(p.tags,[])}));
    applyFilters();
    return true;
  }catch(e){ return false; }
}

function cacheProducts(){
  try{ localStorage.setItem(PRODUCT_CACHE_KEY,JSON.stringify({ts:Date.now(),products})); }catch(e){}
}

(async function(){

  try{

    const customerId =
      location.pathname.replace(/^\/+/,'')
      .split('/')[0]
      .toUpperCase();

    if(!customerId) return;

    const res = await fetch(
      `https://wa.kaapav.com/api/customer-id/${customerId}`
    );

    const data = await res.json();

if(data?.phone){

  localStorage.setItem('customerPhone', data.phone);
  localStorage.setItem('phone', data.phone);
  localStorage.setItem('customer_id', customerId);
  localStorage.setItem('customerId', customerId);

  trackCatalogueEvent('CatalogueClick');

  console.log(
    'âœ… Catalogue identity loaded:',
    customerId,
    data.phone
  );

}

  }catch(err){
    console.error(err);
  }

})();

function getCurrentCustomerId(){
  const fromPath = location.pathname
    .replace(/^\/+/, '')
    .split('/')[0]
    .trim()
    .toUpperCase();

  if(/^[A-Z0-9]{6}$/.test(fromPath)){
    return fromPath;
  }

  return String(
    localStorage.getItem('customer_id') ||
    localStorage.getItem('customerId') ||
    ''
  ).trim().toUpperCase();
}

function getCurrentCustomerPhone(){
  return String(
    localStorage.getItem('customerPhone') ||
    localStorage.getItem('kpv_wa_phone') ||
    localStorage.getItem('phone') ||
    ''
  ).trim();
}

async function linkCustomerIdentityFromCid(){
  if(!hasValidCustomerToken()) return;

  const customerId = getCurrentCustomerId();
  const phone = getCurrentCustomerPhone();

  if(!customerId && !phone) return;

  try{
    const data = await customerApi('/link-identity', {
      method:'POST',
      body: JSON.stringify({
        customerId,
        phone,
      }),
    });

    console.log('CUSTOMER_IDENTITY_LINKED', data);

    if(data?.phone){
      localStorage.setItem('customerPhone', data.phone);
      localStorage.setItem('phone', data.phone);
    }

    if(data?.customerId){
      localStorage.setItem('customer_id', data.customerId);
      localStorage.setItem('customerId', data.customerId);
    }
  }catch(e){
    console.warn('CID link skipped:', e.message);
  }
}

const CATS = {
  all:      { emoji:'âœ¨', label:'All' },
  Bracelets:{ emoji:'ðŸ“¿', label:'Bracelets' },
  Necklaces:{ emoji:'âœ¨', label:'Necklaces' },
  Sets:     { emoji:'ðŸŽ', label:'Sets' },
  Pendants: { emoji:'ðŸ’Ž', label:'Pendants' },
  Rings:    { emoji:'ðŸ’', label:'Rings' },
  Earrings: { emoji:'ðŸ‘‚', label:'Earrings' },
};

const CAT_SUBS = {
  all:'Discover all', Bracelets:'Wrist edit', Necklaces:'Statement layers',
  Sets:'Complete looks', Pendants:'Everyday icons', Rings:'Signature accents',
  Earrings:'Face-framing'
};
const CAT_ICONS = {
  all:`<svg viewBox="0 0 32 32" aria-hidden="true"><path d="M16 3l2.1 7.1L25 12l-6.9 1.9L16 21l-2.1-7.1L7 12l6.9-1.9L16 3Z"/><path d="M25 21l1.2 4 3.8 1-3.8 1L25 31l-1.2-4-3.8-1 3.8-1L25 21Z"/></svg>`,
  Bracelets:`<svg viewBox="0 0 32 32" aria-hidden="true"><path d="M7 9c2.8-3.2 6-4.8 9-4.8S22.2 5.8 25 9"/><path d="M6 11.5c-1 2.1-1.5 4.2-1.5 6.4C4.5 24 9.6 28 16 28s11.5-4 11.5-10.1c0-2.2-.5-4.3-1.5-6.4"/><rect x="13" y="7.5" width="6" height="5" rx="1.5"/></svg>`,
  Necklaces:`<svg viewBox="0 0 32 32" aria-hidden="true"><path d="M5 5c1 10.5 4.8 16 11 16S26 15.5 27 5"/><path d="M16 21l-4 4 4 4 4-4-4-4Z"/></svg>`,
  Sets:`<svg viewBox="0 0 32 32" aria-hidden="true"><path d="M5 7h22v18H5z"/><path d="M16 7v18M5 13h22"/><path d="M16 7c-3-4-7-2-6 1 1 2 4 2 6-1Zm0 0c3-4 7-2 6 1-1 2-4 2-6-1Z"/></svg>`,
  Pendants:`<svg viewBox="0 0 32 32" aria-hidden="true"><path d="M7 4c1.4 7.8 4.4 12 9 12s7.6-4.2 9-12"/><path d="M16 16l-5 6 5 7 5-7-5-6Z"/><path d="M13 22h6"/></svg>`,
  Rings:`<svg viewBox="0 0 32 32" aria-hidden="true"><ellipse cx="16" cy="20" rx="9" ry="8"/><path d="M11 10l5-6 5 6-5 4-5-4Z"/><path d="M13 9h6"/></svg>`,
  Earrings:`<svg viewBox="0 0 32 32" aria-hidden="true"><path d="M10 5a3 3 0 1 0 0 .1M22 5a3 3 0 1 0 0 .1"/><path d="M10 8v5l-4 6 4 8 4-8-4-6Zm12 0v5l-4 6 4 8 4-8-4-6Z"/></svg>`
};
function categoryIcon(key){ return CAT_ICONS[key] || CAT_ICONS.all; }


const TAGS = {
  'Fast Moving':{ color:'#DC2626', bg:'#FEE2E2', emoji:'ðŸ”¥' },
  'New Arrival':{ color:'#2563EB', bg:'#DBEAFE', emoji:'âœ¨' },
  'Bestseller':{ color:'#D97706', bg:'#FEF3C7', emoji:'â­' },
  'On Offer':{ color:'#059669', bg:'#D1FAE5', emoji:'ðŸŽ' },
  'Limited':{ color:'#7C3AED', bg:'#EDE9FE', emoji:'â³' },
  'Trending':{ color:'#DB2777', bg:'#FCE7F3', emoji:'ðŸ“ˆ' },
  'Clearance':{ color:'#6B7280', bg:'#F3F4F6', emoji:'ðŸ·ï¸' },
};

let products=[], filtered=[], activeCat='all', activeSort='default', q='';
let cart={}, wishlist=new Set(), curProd=null, curQty=1, curGallIdx=0;
let appliedCoupon = null;
let customerProfile = null;
let customerAddress = null;
let customerWishlist = [];
let pendingAuthEmail = '';

function getCustomerToken(){
  return String(localStorage.getItem('kp_customer_token') || '').trim();
}

function getCustomerTokenExpiry(){
  return String(localStorage.getItem('kp_customer_token_expires') || '').trim();
}

function hasValidCustomerToken(){
  const token = getCustomerToken();
  const exp = getCustomerTokenExpiry();

  if(!token || !exp) return false;

  const t = Date.parse(exp);
  return Number.isFinite(t) && t > Date.now();
}

function saveCustomerSession(data){
  if(data?.token){
    localStorage.setItem('kp_customer_token', data.token);
  }

  if(data?.expiresAt){
    localStorage.setItem('kp_customer_token_expires', data.expiresAt);
  }

  if(data?.account?.email){
    localStorage.setItem('customerEmail', data.account.email);
  }

  customerProfile = data?.account || null;
}

function clearCustomerSession(){
  localStorage.removeItem('kp_customer_token');
  localStorage.removeItem('kp_customer_token_expires');
  customerProfile = null;
  customerAddress = null;
  customerWishlist = [];
}

async function customerApi(path, opts = {}){
  const headers = {
    ...(opts.headers || {}),
    'Content-Type': 'application/json',
  };

  const token = getCustomerToken();

  if(token){
    headers.Authorization = `Bearer ${token}`;
  }

  const res = await fetch(`${CUSTOMER_API}${path}`, {
    ...opts,
    headers,
  });

  const data = await res.json().catch(() => ({}));

  if(!res.ok || data.success === false){
    throw new Error(data.error || data.message || 'Request failed');
  }

  return data;
}

async function refreshCustomerProfile(){
  if(!hasValidCustomerToken()){
    clearCustomerSession();
    return null;
  }

  try{
    const data = await customerApi('/me', { method:'GET' });

    customerProfile = data.account || null;
    customerAddress = data.address || null;
    customerWishlist = Array.isArray(data.wishlist) ? data.wishlist : [];

    if(customerProfile?.email){
      localStorage.setItem('customerEmail', customerProfile.email);
    }

    return data;
  }catch(e){
    clearCustomerSession();
    return null;
  }
}

function normalizeCoupon(v) {
  return String(v || '').trim().toUpperCase();
}

function checkoutTotals() {
  const sub = cartTotal();
  const ship = sub >= FREE_SHIP ? 0 : SHIP_COST;
  const discount = appliedCoupon ? Number(appliedCoupon.discount || 0) : 0;

  return {
    sub,
    ship,
    discount,
    total: Math.max(0, sub - discount + ship),
  };
}

function updateCheckoutPayable() {
  const t = checkoutTotals();

  const discountRow = document.getElementById('co_discount_row');
  const discountCode = document.getElementById('co_discount_code');
  const discountAmt = document.getElementById('co_discount_amt');
  const totalEl = document.getElementById('co_total');
  const payBtn = document.getElementById('payBtn');

  if (discountRow) {
    discountRow.style.display = t.discount > 0 ? 'flex' : 'none';
  }

  if (discountCode) {
    discountCode.textContent = appliedCoupon?.code ? `(${appliedCoupon.code})` : '';
  }

  if (discountAmt) {
    discountAmt.textContent = t.discount;
  }

  if (totalEl) {
    totalEl.textContent = `â‚¹${t.total}`;
  }

  if (payBtn) {
    payBtn.textContent = `Pay â‚¹${t.total} with Razorpay`;
  }
}

async function applyCoupon() {
  const input = document.getElementById('co_coupon');
  const msg = document.getElementById('co_coupon_msg');
  const code = normalizeCoupon(input?.value);

  if (!code) {
    toast('Enter coupon code');
    return;
  }

  try {
    const res = await fetch('https://wa.kaapav.com/api/catalogue/coupons/validate', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        code,
        orderTotal: cartTotal(),
      }),
    });

    const data = await res.json();

    if (!res.ok || !data.success) {
      appliedCoupon = null;
      updateCheckoutPayable();
      if (msg) msg.textContent = data.error || data.message || 'Invalid coupon';
      toast(data.error || data.message || 'Invalid coupon');
      return;
    }

    appliedCoupon = data.coupon;
    updateCheckoutPayable();

    if (msg) {
      msg.textContent = `${appliedCoupon.code} applied â€” â‚¹${appliedCoupon.discount} off`;
    }

    toast(`${appliedCoupon.code} applied ðŸŽŸï¸`);
  } catch (e) {
    appliedCoupon = null;
    updateCheckoutPayable();
    toast('Could not apply coupon. Try again.');
  }
}
let showInStockOnly=false, recentSearches=[], shareProd=null;
try{ recentSearches=JSON.parse(localStorage.getItem('kp_searches')||'[]') }catch{}

// â”€â”€ STATE PERSISTENCE â”€â”€
function loadState(){
  try{ cart=JSON.parse(localStorage.getItem('kp_cart')||'{}') }catch{}
  try{ wishlist=new Set(JSON.parse(localStorage.getItem('kp_wl')||'[]')) }catch{}
}
function saveCart(){ localStorage.setItem('kp_cart',JSON.stringify(cart)) }
function saveWL(){ localStorage.setItem('kp_wl',JSON.stringify([...wishlist])) }

async function trackCatalogueEvent(eventName, data = {}) {
  try {
    const phone =
      localStorage.getItem('customerPhone') ||
      localStorage.getItem('phone') ||
      '';

    if (!phone) return;

    const params = new URLSearchParams(location.search);

   return await fetch('https://wa.kaapav.com/api/customer-events', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        phone,
        source: 'catalogue',
        event: eventName,
        sku: data.sku || '',
        product_name: data.product_name || '',
        category: data.category || '',
        price: data.price || 0,
        quantity: data.quantity || 1,
        cart_total: data.cart_total || 0,
        checkout_items: JSON.stringify(
  data.checkout_items || []
),
        page_url: location.href,
        utm_source: params.get('utm_source') || '',
        utm_medium: params.get('utm_medium') || '',
        utm_campaign: params.get('utm_campaign') || '',
        customer_name: localStorage.getItem('customerName') || ''
      })
    });
  } catch (e) {
    console.error('Catalogue event error', e);
  }
}

// â”€â”€ FETCH â”€â”€
async function fetchProducts(){
  setSpin(true);
  try{
    const r=await fetch(API+'?t='+Date.now(),{cache:'no-store'});
    const d=await r.json();
    if(d.success){
      products=d.products.map(p=>({...p,images:sjson(p.images,[]),tags:sjson(p.tags,[])}));
      cacheProducts(); applyFilters(); setSpin(false);
    }
  }catch(e){ setSpin('err'); }
}
function sjson(v,fb){ if(Array.isArray(v))return v; try{return JSON.parse(v)}catch{return fb} }
function setSpin(s){
  const d=document.getElementById('sd');
  d.className='sync-dot'+(s===true?' spin':s==='err'?' err':'');
}

// â”€â”€ FILTER â”€â”€
function applyFilters(){
  let l=[...products];
  if(activeCat!=='all') l=l.filter(p=>p.category===activeCat);
  if(showInStockOnly) l=l.filter(p=>p.stock>0);
  if(q){ const lq=q.toLowerCase(); l=l.filter(p=>
    p.name.toLowerCase().includes(lq)||p.sku.toLowerCase().includes(lq)||
    (p.description||'').toLowerCase().includes(lq)||p.tags.some(t=>t.toLowerCase().includes(lq)));
  }
  if(activeSort==='price_asc') l.sort((a,b)=>a.price-b.price);
  else if(activeSort==='price_desc') l.sort((a,b)=>b.price-a.price);
  else if(activeSort==='name') l.sort((a,b)=>a.name.localeCompare(b.name));
  else if(activeSort==='new') l.sort((a,b)=>new Date(b.created_at||0)-new Date(a.created_at||0));
  else l.sort((a,b)=>(b.is_featured||0)-(a.is_featured||0));
  filtered=l;
  renderCats(); renderGrid();
  document.getElementById('sCt').textContent=l.length+' items';
}

function toggleAvail(){
  showInStockOnly=!showInStockOnly;
  const c=document.getElementById('availChip');
  c.classList.toggle('on',showInStockOnly);
  c.textContent=showInStockOnly?'âœ… In Stock Only':'âœ… In Stock Only';
  applyFilters();
}

// â”€â”€ CATS â”€â”€
let categoryLoopRAF=0;
let categoryLoopPauseUntil=0;
function renderCats(){
  const ct={};
  products.forEach(p=>{ ct[p.category]=(ct[p.category]||0)+1 });
  const cards=(copy=false)=>Object.entries(CATS).map(([k,c])=>{
    const n=k==='all'?products.length:(ct[k]||0);
    const active=activeCat===k;
    return `<button class="cat${active?' on':''}" data-cat="${k}" onclick="setCat('${k}')" aria-pressed="${active}" ${copy?'tabindex="-1" aria-hidden="true"':''}>
      <span class="cat-icon">${categoryIcon(k)}</span>
      <span class="cat-copy"><span class="cat-label">${c.label}</span><span class="cat-sub">${CAT_SUBS[k]||'Curated edit'}</span></span>
      <span class="n">${n}</span>
    </button>`;
  }).join('');
  const rail=document.getElementById('catTabs');
  rail.innerHTML=`<div class="cat-loop-group">${cards(false)}</div><div class="cat-loop-group cat-loop-clone" aria-hidden="true">${cards(true)}</div>`;
  initCategoryLoop();
}
function initCategoryLoop(){
  const rail=document.getElementById('catTabs');
  if(!rail) return;
  cancelAnimationFrame(categoryLoopRAF);
  const first=rail.querySelector('.cat-loop-group');
  const reduce=window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  let visible=true, hovering=false;
  if(rail._catObserver) rail._catObserver.disconnect();
  if('IntersectionObserver' in window){
    rail._catObserver=new IntersectionObserver(entries=>{visible=!!entries[0]?.isIntersecting},{threshold:.01});
    rail._catObserver.observe(rail);
  }
  const pause=(ms=5000)=>{categoryLoopPauseUntil=performance.now()+ms};
  if(!rail._catLoopBound){
    ['pointerdown','touchstart','wheel','keydown'].forEach(ev=>rail.addEventListener(ev,()=>pause(),{passive:true}));
    rail.addEventListener('mouseenter',()=>{rail._catHover=true});
    rail.addEventListener('mouseleave',()=>{rail._catHover=false;pause(1200)});
    rail._catLoopBound=true;
  }
  const step=(ts)=>{
    if(!reduce && visible && !document.hidden && !rail._catHover && ts>categoryLoopPauseUntil && rail.scrollWidth>rail.clientWidth+12){
      rail.scrollLeft+=0.24;
      const boundary=first?.offsetWidth||0;
      if(boundary && rail.scrollLeft>=boundary) rail.scrollLeft-=boundary;
    }
    categoryLoopRAF=requestAnimationFrame(step);
  };
  categoryLoopRAF=requestAnimationFrame(step);
}
function setCat(c){
  activeCat=c;
  categoryLoopPauseUntil=performance.now()+6000;
  applyFilters();
  if(c!=='all'&&typeof kpvTrack!=='undefined') kpvTrack.categoryView(c);
}

// sort chips
document.querySelectorAll('.chip').forEach(b=>{
  b.addEventListener('click',()=>{
    document.querySelectorAll('.chip').forEach(x=>x.classList.remove('on'));
    b.classList.add('on'); activeSort=b.dataset.s; applyFilters();
  });
});

// search
document.getElementById('si').addEventListener('input',e=>{ q=e.target.value.trim(); applyFilters(); });

// â”€â”€ GRID â”€â”€
function renderGrid(){
  const g=document.getElementById('grid');
  if(!products.length){ shimmer(); return; }
  if(!filtered.length){
    g.innerHTML=`<div class="empty-grid"><div class="ei">ðŸ”</div><p>Nothing found</p><p style="color:var(--gray-l);font-size:11px">Try a different search</p></div>`;
    return;
  }
  g.innerHTML=filtered.map((p,index)=>cardHTML(p,index)).join('');
}

function cardHTML(p,index=99){
  const disc=p.compare_price>p.price?Math.round((1-p.price/p.compare_price)*100):0;
  const inWl=wishlist.has(p.sku);
  const imgs=p.images.length?p.images:(p.image_url?[p.image_url]:[]);
  // Use JSON.stringify safely for onclick attribute
  const imgsJson=JSON.stringify(imgs).replace(/"/g,'&quot;');
  const imgH=imgs.length
    ?`<img class="c-img" src="${imgs[0]}" alt="${p.name}" loading="${index<4?'eager':'lazy'}" fetchpriority="${index<2?'high':'auto'}" decoding="async" onerror="this.style.display='none';this.nextElementSibling.style.display='flex'"><div class="c-ph" style="display:none">${CATS[p.category]?.emoji||'ðŸ’Ž'}</div>`
    :`<div class="c-ph">${CATS[p.category]?.emoji||'ðŸ’Ž'}</div>`;
  const tbdgs=p.tags.slice(0,2).map(t=>{ const tc=TAGS[t]; return tc?`<span class="bdg" style="background:${tc.bg};color:${tc.color}">${tc.emoji} ${t}</span>`:'' }).join('');
 const feat=p.is_featured?`<span class="bdg bdg-feat">Bestseller</span>`:'';
const sbdg=p.stock===0?`<span class="s-badge s-out">Sold Out</span>`:p.stock<=5?`<span class="s-badge s-low">Only ${p.stock} Left</span>`:'';
  const tagChips=p.tags.slice(0,2).map(t=>{ const tc=TAGS[t]; return tc?`<span class="t-chip" style="background:${tc.bg};color:${tc.color}">${t}</span>`:'' }).join('');
  return `<div class="card" onclick="openProd('${p.sku}')">
    ${imgH}
    <div class="c-badges">${feat}${tbdgs}</div>
    ${sbdg}
    <button class="wl-btn" onclick="toggleWL(event,'${p.sku}')">${inWl?'â¤ï¸':'ðŸ¤'}</button>
    <div class="c-body">
      <div class="c-cat">${CATS[p.category]?.emoji||''} ${CATS[p.category]?.label||p.category}</div>
      <div class="c-name">${p.name}</div>
      <div class="c-price">
        <span class="c-sale">â‚¹${p.price}</span>
        ${p.compare_price>p.price?`<span class="c-mrp">â‚¹${p.compare_price}</span><span class="c-disc">${disc}% OFF</span>`:''}
      </div>
      ${tagChips?`<div class="c-tags">${tagChips}</div>`:''}
    </div>
    <button class="qadd" onclick="quickAdd(event,'${p.sku}')">+ Add to Cart</button>
  </div>`;
}

function shimmer(){
  document.getElementById('grid').innerHTML=Array(6).fill(0).map(()=>`
    <div class="sh-card"><div class="sh-img sh"></div>
    <div class="sh-body"><div class="sh-line sh" style="width:60%"></div>
    <div class="sh-line sh" style="width:90%"></div>
    <div class="sh-line sh" style="width:40%"></div></div></div>`).join('');
}

// â”€â”€ WISHLIST â”€â”€
function toggleWL(e, sku){
  e.stopPropagation();

  const p = products.find(x => x.sku === sku);

  if(wishlist.has(sku)){
    wishlist.delete(sku);
    toast('Removed from wishlist');
  } else {
    wishlist.add(sku);
    toast('Added to wishlist â¤ï¸');

    if(p){
      trackCatalogueEvent('AddToWishlist',{
        sku:p.sku,
        product_name:p.name,
        category:p.category,
        price:p.price
      });
    }
  }

const _wp=products.find(x=>x.sku===sku); if(_wp&&typeof kpvTrack!=='undefined') kpvTrack.addToWishlist({id:_wp.sku,name:_wp.name,price:_wp.price,category:_wp.category});
  saveWL(); updateWLCount(); renderGrid();
}
function updateWLCount(){
  const btn=document.querySelector('button.hdr-btn[onclick="openWishlist()"]');
  const ct=document.getElementById('wlCt');
  if(ct) ct.textContent=wishlist.size||'';
  if(btn){
    btn.classList.toggle('has-items',wishlist.size>0);
    const icon=btn.querySelector('.wish-icon');
    if(icon){
      icon.className=(wishlist.size>0?'fa-solid':'fa-regular')+' fa-heart hdr-ico wish-icon';
    }
  }
}
function openWishlist(){ document.getElementById('wlDrw').classList.add('on'); renderWL(); }
function closeWishlist(){ document.getElementById('wlDrw').classList.remove('on'); }
function renderWL(){
  const items=[...wishlist].map(s=>products.find(p=>p.sku===s)).filter(Boolean);
  const b=document.getElementById('wlBody');
  const f=document.getElementById('wlFoot');
  if(!items.length){ b.innerHTML=`<div class="empty-drw"><div class="ei">ðŸ¤</div><p>Your wishlist is empty</p></div>`; f.innerHTML=''; return; }
  b.innerHTML=items.map(p=>{
    const imgs=p.images.length?p.images:(p.image_url?[p.image_url]:[]);
    return `<div class="wi">
      ${imgs.length?`<img class="wi-img" src="${imgs[0]}" alt="${p.name}" loading="lazy">`:`<div class="wi-img" style="display:flex;align-items:center;justify-content:center;font-size:22px">${CATS[p.category]?.emoji||'ðŸ’Ž'}</div>`}
      <div class="wi-name">${p.name}</div>
      <div class="wi-price">â‚¹${p.price}</div>
      <button class="wi-add" onclick="addFromWL('${p.sku}')">+ Cart</button>
    </div>`;
  }).join('');
  f.innerHTML='';
}
function addFromWL(sku){ addToCart(sku,1); toast('Added to cart ðŸ›’'); }

// â”€â”€ CART â”€â”€
function cartTotal(){ return Object.values(cart).reduce((s,i)=>s+i.price*i.qty,0); }
function cartCount(){ return Object.values(cart).reduce((s,i)=>s+i.qty,0); }
function updateCartCount(){ document.getElementById('cartCt').textContent=cartCount()||0; }

function addToCart(sku, qty = 1) {
  const p = products.find(x => x.sku === sku);
  if (!p) return;

  const currentQty = cart[sku] ? cart[sku].qty : 0;
  const maxCanAdd = p.stock - currentQty;

  if (maxCanAdd <= 0) {
    toast(`That's all we have in stock right now! ðŸ¥°`);
    return;
  }

  const actualQty = Math.min(qty, maxCanAdd);
  if (actualQty < qty) toast(`We only had ${p.stock} left â€” added what we could! ðŸ›ï¸`);

  if (cart[sku]) cart[sku].qty += actualQty;
  else cart[sku] = { sku:p.sku, name:p.name, price:p.price, image:p.image_url || '', category:p.category, qty: actualQty };

  saveCart();
  updateCartCount();

  trackCatalogueEvent('AddToCart', {
    sku: p.sku,
    product_name: p.name,
    category: p.category,
    price: p.price,
    quantity: actualQty
  });
}

function quickAdd(e, sku) {
  e.stopPropagation();
  const _p = products.find(x => x.sku === sku);
  if (!_p) return;
  if (_p.stock === 0) { toast('Out of stock ðŸ˜•'); return; }
  const currentQty = cart[sku] ? cart[sku].qty : 0;
  if (currentQty >= _p.stock) { toast(`You've got all ${_p.stock} we have! ðŸ¥°`); return; }
  addToCart(sku, 1);
  if (typeof kpvTrack !== 'undefined') kpvTrack.addToCart({id:_p.sku,name:_p.name,price:_p.price,category:_p.category}, 1);
  toast('Added to cart ðŸ›’');
}

function openCart(){ document.getElementById('cartDrw').classList.add('on'); renderCart(); }
function closeCart(){ document.getElementById('cartDrw').classList.remove('on'); }

function renderCart(){
  const items=Object.values(cart);
  const b=document.getElementById('cartBody');
  const f=document.getElementById('cartFoot');
  if(!items.length){
    b.innerHTML=`<div class="empty-drw"><div class="ei">ðŸ›’</div><p>Your cart is empty</p></div>`;
    f.innerHTML=''; return;
  }
  const sub=cartTotal();
  const ship=sub>=FREE_SHIP?0:SHIP_COST;
  const total=sub+ship;
  const pct=Math.min(100,Math.round(sub/FREE_SHIP*100));

  b.innerHTML=`
    <div class="fs-bar">
      <div class="fs-lbl">${ship===0?'ðŸŽ‰ Free shipping unlocked!':'Add â‚¹'+(FREE_SHIP-sub)+' more for free shipping'}</div>
      <div class="fs-track"><div class="fs-fill" style="width:${pct}%"></div></div>
      <div class="fs-msg">Free shipping on orders above â‚¹${FREE_SHIP}</div>
    </div>
    ${items.map(i=>`<div class="ci">
      ${i.image?`<img class="ci-img" src="${i.image}" loading="lazy">`:`<div class="ci-img" style="display:flex;align-items:center;justify-content:center;font-size:22px">${CATS[i.category]?.emoji||'ðŸ’Ž'}</div>`}
      <div class="ci-info">
        <div class="ci-name">${i.name}</div>
        <div class="ci-cat">${CATS[i.category]?.label||i.category}</div>
        <div class="ci-row">
          <span class="ci-price">â‚¹${i.price*i.qty}</span>
          <div class="ci-qty">
            <button class="ci-qb" onclick="chgQty('${i.sku}',-1)">âˆ’</button>
            <span class="ci-qv">${i.qty}</span>
            <button class="ci-qb" onclick="chgQty('${i.sku}',1)">+</button>
          </div>
          <button class="ci-del" onclick="removeCart('${i.sku}')">ðŸ—‘</button>
        </div>
      </div>
    </div>`).join('')}
  `;

  f.innerHTML=`
    <div class="cart-sum">
      <div class="sum-row"><span>Subtotal</span><span>â‚¹${sub}</span></div>
      <div class="sum-row"><span>Shipping</span><span>${ship===0?'FREE':'â‚¹'+ship}</span></div>
      <div class="sum-row total"><span>Total</span><span>â‚¹${total}</span></div>
    </div>
    <button class="btn-checkout" onclick="openCheckout()">Proceed to Checkout â†’</button>
    <button class="btn-wa-cart" onclick="orderViaWA()">
      <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor"><path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413z"/></svg>
      Order via WhatsApp
    </button>
  `;
}

function chgQty(sku, d) {
  if (!cart[sku]) return;
  const p = products.find(x => x.sku === sku);
  const maxQty = p ? p.stock : 999;
  const newQty = Math.max(1, Math.min(maxQty, cart[sku].qty + d));
  if (d > 0 && newQty === cart[sku].qty) { toast(`That's all we have in stock right now! ðŸ¥°`); return; }
  cart[sku].qty = newQty;
  saveCart(); updateCartCount(); renderCart();
}
function removeCart(sku){ delete cart[sku]; saveCart(); updateCartCount(); renderCart(); }

function orderViaWA(){
  const items=Object.values(cart);
  if(!items.length) return;
  const sub=cartTotal(); const ship=sub>=FREE_SHIP?0:SHIP_COST;
  const msg=`Hi! I want to order:\n\n${items.map(i=>`â€¢ ${i.name} x${i.qty} â€” â‚¹${i.price*i.qty}`).join('\n')}\n\nSubtotal: â‚¹${sub}\nShipping: â‚¹${ship}\nTotal: â‚¹${sub+ship}\n\nPlease help me complete the order!`;
  window.open(`${WA}?text=${encodeURIComponent(msg)}`, '_blank');
}

// â”€â”€ MY ORDERS SCREEN â”€â”€
let ordersCache = [];

function getStoredProfileEmail(){
  return String(localStorage.getItem('customerEmail') || '')
    .trim()
    .toLowerCase();
}

function openProfile(){
  document.getElementById('ordersDrw').classList.add('on');
  if(typeof kpvTrack !== 'undefined') kpvTrack.pageView('profile');
  renderProfileHome();
}

async function renderProfileHome(){
  const email = getStoredProfileEmail();
  const wlCount = wishlist.size || 0;
  const cartItems = cartCount();

  document.getElementById('profileTitle').textContent = 'Profile';

  if(hasValidCustomerToken() && !customerProfile){
    document.getElementById('ordersBody').innerHTML = `
      <div class="od-empty">
        <div class="ei">â³</div>
        Loading your KAAPAV profile...
      </div>
    `;

    await refreshCustomerProfile();

  }

  if(customerProfile?.email){
    const displayEmail = customerProfile.email;
    const initial = displayEmail.charAt(0).toUpperCase();

    document.getElementById('ordersBody').innerHTML = `
      <div class="pf-hero">
        <div class="pf-avatar">${esc(initial)}</div>
        <div class="pf-title">Welcome to KAAPAV</div>
        <div class="pf-sub">
          Logged in as <strong>${esc(displayEmail)}</strong>
        </div>
      </div>

      <div class="pf-mini">
        <div class="pf-stat">
          <strong>${wlCount}</strong>
          <span>Wishlist</span>
        </div>
        <div class="pf-stat">
          <strong>${cartItems}</strong>
          <span>Cart Items</span>
        </div>
      </div>

      <div class="pf-card">
        <div class="pf-row" onclick="openProfileOrders()">
          <div class="pf-left">
            <div class="pf-ico">ðŸ“¦</div>
            <div>
              <div class="pf-name">My Orders</div>
              <div class="pf-note">View order status, payment and tracking</div>
            </div>
          </div>
          <div class="pf-arr">â€º</div>
        </div>

        <div class="pf-row" onclick="openProfileWishlist()">
          <div class="pf-left">
            <div class="pf-ico">ðŸ¤</div>
            <div>
              <div class="pf-name">Wishlist</div>
              <div class="pf-note">${wlCount} saved design${wlCount === 1 ? '' : 's'}</div>
            </div>
          </div>
          <div class="pf-arr">â€º</div>
        </div>

        <div class="pf-row" onclick="openProfileCart()">
          <div class="pf-left">
            <div class="pf-ico">ðŸ›’</div>
            <div>
              <div class="pf-name">Cart</div>
              <div class="pf-note">${cartItems} item${cartItems === 1 ? '' : 's'} in cart</div>
            </div>
          </div>
          <div class="pf-arr">â€º</div>
        </div>

        <div class="pf-row" onclick="window.open('${WA}','_blank')">
          <div class="pf-left">
            <div class="pf-ico">ðŸ’¬</div>
            <div>
              <div class="pf-name">WhatsApp Support</div>
              <div class="pf-note">Chat with KAAPAV</div>
            </div>
          </div>
          <div class="pf-arr">â€º</div>
        </div>
      </div>

      <div class="pf-card">
        <div class="od-kv"><span>Email</span><strong>${esc(displayEmail)}</strong></div>
        <div class="od-kv"><span>Session</span><strong>Active</strong></div>
      </div>
    `;

    document.getElementById('ordersFoot').innerHTML = `
      <button class="btn-checkout" onclick="customerLogout()">Logout</button>
    `;

    return;
  }

  document.getElementById('ordersBody').innerHTML = `
    <div class="pf-hero">
      <div class="pf-avatar">ðŸ‘¤</div>
      <div class="pf-title">Login / Sign up</div>
      <div class="pf-sub">
        Continue with email OTP to view your orders, wishlist and saved address.
      </div>
    </div>

    <div class="pf-mini">
      <div class="pf-stat">
        <strong>${wlCount}</strong>
        <span>Wishlist</span>
      </div>
      <div class="pf-stat">
        <strong>${cartItems}</strong>
        <span>Cart Items</span>
      </div>
    </div>

    <div class="pf-card">
      <div class="co-lbl">Email address</div>
      <input class="co-inp" id="auth_email" type="email" placeholder="Enter your email" value="${esc(email)}">
      <button class="btn-checkout" onclick="sendCustomerOtp()">Continue with Email OTP</button>
      <div class="pf-note" style="text-align:center;line-height:1.5">
        New customer? Account will be created automatically after OTP verification.
      </div>
    </div>

    <div class="pf-card">
      <div class="pf-row" onclick="openProfileWishlist()">
        <div class="pf-left">
          <div class="pf-ico">ðŸ¤</div>
          <div>
            <div class="pf-name">Wishlist</div>
            <div class="pf-note">${wlCount} saved design${wlCount === 1 ? '' : 's'} on this device</div>
          </div>
        </div>
        <div class="pf-arr">â€º</div>
      </div>

      <div class="pf-row" onclick="openProfileCart()">
        <div class="pf-left">
          <div class="pf-ico">ðŸ›’</div>
          <div>
            <div class="pf-name">Cart</div>
            <div class="pf-note">${cartItems} item${cartItems === 1 ? '' : 's'} in cart</div>
          </div>
        </div>
        <div class="pf-arr">â€º</div>
      </div>
    </div>
  `;

  document.getElementById('ordersFoot').innerHTML = `
    <button class="btn-checkout" onclick="closeOrders()">Continue Shopping</button>
  `;
}

async function sendCustomerOtp(){
  const input = document.getElementById('auth_email');

  const email = String(input?.value || pendingAuthEmail || '')
    .trim()
    .toLowerCase();

  if(!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)){
    toast('Enter valid email');
    return;
  }

  pendingAuthEmail = email;

  const bodyEl = document.getElementById('ordersBody');

  bodyEl.innerHTML = `
    <div class="od-empty">
      <div class="ei">â³</div>
      Sending OTP to <strong>${esc(email)}</strong>...
    </div>
  `;

  try{
    const res = await fetch(`${CUSTOMER_API}/auth/send-otp`, {
      method:'POST',
      headers:{ 'Content-Type':'application/json' },
      body: JSON.stringify({ email }),
    });

    const data = await res.json().catch(() => ({}));

    console.log('CUSTOMER_OTP_SEND_RESPONSE', res.status, data);

    if(!res.ok || data.success === false){
      throw new Error(data.error || data.message || 'Could not send OTP');
    }

    localStorage.setItem('customerEmail', email);

    renderCustomerOtpScreen(email);
    toast('OTP sent to your email');
  }catch(e){
    console.error('OTP send UI error:', e);

    bodyEl.innerHTML = `
      <div class="pf-hero">
        <div class="pf-avatar">âš ï¸</div>
        <div class="pf-title">OTP could not be sent</div>
        <div class="pf-sub">${esc(e.message || 'Please try again.')}</div>
      </div>

      <div class="pf-card">
        <button class="btn-checkout" onclick="renderProfileHome()">Try Again</button>
      </div>
    `;

    toast(e.message || 'Could not send OTP');
  }
}

function renderCustomerOtpScreen(email){
  pendingAuthEmail = String(email || pendingAuthEmail || '')
    .trim()
    .toLowerCase();

  document.getElementById('profileTitle').textContent = 'Verify OTP';

  document.getElementById('ordersBody').innerHTML = `
    <div class="pf-hero">
      <div class="pf-avatar">âœ‰ï¸</div>
      <div class="pf-title">Enter OTP</div>
      <div class="pf-sub">
        We sent a 6-digit OTP to <strong>${esc(pendingAuthEmail)}</strong>.
      </div>
    </div>

    <div class="pf-card">
      <div class="co-lbl">6-digit OTP</div>

      <input
        class="co-inp"
        id="auth_otp"
        type="tel"
        inputmode="numeric"
        maxlength="6"
        placeholder="Enter OTP"
        autocomplete="one-time-code"
        style="text-align:center;font-size:22px;letter-spacing:6px;font-weight:600"
      >

<button class="btn-checkout" onclick="window.verifyCustomerOtp()" style="margin-top:8px">
  Verify & Continue
</button>

<button
  class="od-load"
  onclick="resendCustomerOtp()"
  style="margin-top:8px;background:#fff;color:var(--dark);border:0.5px solid var(--border)"
>
  Resend OTP
</button>

<button
  class="od-load"
  onclick="renderProfileHome()"
  style="margin-top:8px;background:#fff;color:var(--dark);border:0.5px solid var(--border)"
>
  â† Change Email
</button>

      <div class="pf-note" style="text-align:center;margin-top:8px">
        OTP is valid for 10 minutes.
      </div>
    </div>
  `;

document.getElementById('ordersFoot').innerHTML = '';
  
  setTimeout(() => document.getElementById('auth_otp')?.focus(), 150);
}

function resendCustomerOtp(){
  if(!pendingAuthEmail){
    renderProfileHome();
    return;
  }

  document.getElementById('ordersBody').innerHTML = `
    <div class="pf-card">
      <div class="co-lbl">Email address</div>
      <input class="co-inp" id="auth_email" type="email" value="${esc(pendingAuthEmail)}">
    </div>
  `;

  sendCustomerOtp();
}

async function verifyCustomerOtp(){
  const btn = document.querySelector('#ordersBody .btn-checkout');
  const otp = String(document.getElementById('auth_otp')?.value || '').trim();

  console.log('VERIFY_CLICKED', {
    otpLength: otp.length,
    pendingAuthEmail,
    customerId: typeof getCurrentCustomerId === 'function' ? getCurrentCustomerId() : '',
    phone: typeof getCurrentCustomerPhone === 'function' ? getCurrentCustomerPhone() : '',
  });

  if(!/^\d{6}$/.test(otp)){
    toast('Enter valid 6-digit OTP');
    return;
  }

  if(!pendingAuthEmail){
    pendingAuthEmail = String(localStorage.getItem('customerEmail') || '')
      .trim()
      .toLowerCase();
  }

  if(!pendingAuthEmail){
    toast('Email missing. Please request OTP again.');
    renderProfileHome();
    return;
  }

  try{
    if(btn){
      btn.disabled = true;
      btn.textContent = 'Verifying...';
    }

    const data = await customerApi('/auth/verify-otp', {
      method:'POST',
      body: JSON.stringify({
        email: pendingAuthEmail,
        otp,
        phone: typeof getCurrentCustomerPhone === 'function' ? getCurrentCustomerPhone() : '',
        customerId: typeof getCurrentCustomerId === 'function' ? getCurrentCustomerId() : '',
      }),
    });

    console.log('VERIFY_SUCCESS', data);

    saveCustomerSession(data);
    await refreshCustomerProfile();

    if(typeof linkCustomerIdentityFromCid === 'function'){
      await linkCustomerIdentityFromCid();
    }

    toast('Logged in successfully');
    renderProfileHome();
  }catch(e){
    console.error('VERIFY_FAILED', e);
    toast(e.message || 'OTP verification failed');

    if(btn){
      btn.disabled = false;
      btn.textContent = 'Verify & Continue';
    }
  }
}

window.verifyCustomerOtp = verifyCustomerOtp;


async function customerLogout(){
  try{
    if(getCustomerToken()){
      await customerApi('/logout', { method:'POST' });
    }
  }catch(e){
    console.warn('Logout API failed:', e);
  }

  clearCustomerSession();
  toast('Logged out');
  renderProfileHome();
}


async function openProfileOrders(){
  document.getElementById('ordersDrw').classList.add('on');
  document.getElementById('profileTitle').textContent = 'My Orders';

  if(!hasValidCustomerToken()){
    document.getElementById('ordersBody').innerHTML = `
      <div class="pf-hero">
        <div class="pf-avatar">ðŸ”</div>
        <div class="pf-title">Login required</div>
        <div class="pf-sub">
          Login with email OTP to securely view your KAAPAV orders.
        </div>
      </div>
      <div class="pf-card">
        <button class="btn-checkout" onclick="renderProfileHome()">Login / Sign up</button>
      </div>
    `;

    document.getElementById('ordersFoot').innerHTML = `
      <button class="btn-checkout" onclick="renderProfileHome()">â† Back to Profile</button>
    `;
    return;
  }

  document.getElementById('ordersBody').innerHTML = `
    <div class="od-phone-box">
      <div class="od-note">Loading your verified KAAPAV orders...</div>
    </div>
  `;

  document.getElementById('ordersFoot').innerHTML = `
    <button class="btn-checkout" onclick="renderProfileHome()">â† Back to Profile</button>
  `;

  await fetchCustomerOrders();
}

function openProfileWishlist(){
  closeOrders();
  openWishlist();
}

function openProfileCart(){
  closeOrders();
  openCart();
}

function profileLoginComingSoon(){
  toast('Login/Register is next. Profile shell is ready.');
}

function esc(v){
  return String(v ?? '').replace(/[&<>"']/g, m => ({
    '&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#039;'
  }[m]));
}
function money(n){ return 'â‚¹' + Number(n || 0).toLocaleString('en-IN'); }
function fmtDate(v){
  if(!v) return '-';
  try{
    return new Date(String(v).replace(' ', 'T')).toLocaleDateString('en-IN', {
      day:'2-digit', month:'short', year:'numeric'
    });
  }catch{ return String(v); }
}
function getStoredOrderPhone(){
  const raw = localStorage.getItem('customerPhone') || localStorage.getItem('phone') || localStorage.getItem('kpv_wa_phone') || '';
  const d = String(raw).replace(/\D/g,'');
  if(d.startsWith('91') && d.length >= 12) return d.slice(0, 12);
  if(d.length >= 10) return '91' + d.slice(-10);
  return '';
}
function saveOrderPhoneFromInput(){
  const d = String(document.getElementById('od_phone')?.value || '').replace(/\D/g,'').slice(-10);
  if(d.length !== 10){ toast('Enter valid 10-digit WhatsApp number'); return; }
  const phone91 = '91' + d;
  localStorage.setItem('customerPhone', phone91);
  localStorage.setItem('phone', phone91);
  fetchCustomerOrders();
}
function renderOrdersPhoneForm(note='Enter your WhatsApp number to view your KAAPAV orders.'){
  const saved = getStoredOrderPhone().replace(/^91/, '');
  document.getElementById('ordersBody').innerHTML = `
    <div class="od-phone-box">
      <div class="od-note">${esc(note)}</div>
      <input class="od-inp" id="od_phone" type="tel" maxlength="10" placeholder="WhatsApp number" value="${esc(saved)}">
      <button class="od-load" onclick="saveOrderPhoneFromInput()">Load My Orders</button>
    </div>
    <div class="od-empty"><div class="ei">ðŸ“¦</div>Orders will appear here after checkout.</div>
  `;
}
function openOrders(){
document.getElementById('ordersDrw').classList.add('on');
  openProfileOrders();
}
function closeOrders(){ document.getElementById('ordersDrw').classList.remove('on'); }
function closeOrderDetails() {
  document
    .getElementById(
      'orderDetailMo'
    )
    .classList
    .remove('on');
}

let returnRequestSubmitting =
  false;

let activeReturnOrderId =
  '';

function closeReturnRequest() {
  document
    .getElementById(
      'returnRequestMo'
    )
    .classList
    .remove('on');

  activeReturnOrderId = '';
  returnRequestSubmitting =
    false;
}

function isReturnEligible(order) {
  return (
    order?.return_eligible === true ||
    Number(
      order?.return_eligible || 0
    ) === 1
  );
}

function isOpenReturnRequest(
  request
) {
  if (!request) {
    return false;
  }

  const closed = [
    'rejected',
    'refunded',
    'completed',
    'cancelled',
  ];

  return !closed.includes(
    String(
      request.status || ''
    ).toLowerCase()
  );
}

function returnRequestLabel(
  request
) {
  if (!request) {
    return '';
  }

  const type =
    String(
      request.request_type ||
      'return'
    );

  const status =
    String(
      request.status ||
      'requested'
    );

  return (
    `${type.replace(/_/g, ' ')}` +
    ` â€” ` +
    `${status.replace(/_/g, ' ')}`
  );
}

function returnWindowText(order) {
  if (
    !isReturnEligible(order) &&
    order?.return_ineligible_reason
  ) {
    return order.return_ineligible_reason;
  }

  if (order?.return_expires_at) {
    return (
      `Available until ` +
      `${fmtDate(order.return_expires_at)}` +
      ` â€” 7 days from purchase date.`
    );
  }

  return 'Return information unavailable.';
}

function toggleReturnScope() {
  const scope =
    document.querySelector(
      'input[name="rr_scope"]:checked'
    )?.value ||
    'full_order';

  document
    .getElementById(
      'rrItems'
    )
    ?.classList
    .toggle(
      'on',
      scope === 'items'
    );
}

function openReturnRequest(
  orderId
) {
  const order =
    ordersCache.find(
      (item) =>
        String(item.order_id) ===
        String(orderId)
    );

  if (!order) {
    return;
  }

  const latest =
    order.return_request ||
    null;

  if (
    isOpenReturnRequest(
      latest
    )
  ) {
    toast(
      `Request already ` +
      `${String(
        latest.status ||
        'submitted'
      ).replace(/_/g, ' ')}`
    );

    return;
  }

  if (
    !isReturnEligible(order)
  ) {
    toast(
      order.return_ineligible_reason ||
      'Return or exchange is not available for this order'
    );

    return;
  }

  activeReturnOrderId =
    String(order.order_id);

  const items =
    parseOrderItems(
      order.items
    );

  document
    .getElementById(
      'returnRequestBody'
    )
    .innerHTML = `
      <div class="rr-policy">
        <strong>
          7-day return / exchange window
        </strong>
        <br>

        This order is eligible from its
        purchase date until
        ${esc(
          fmtDate(
            order.return_expires_at ||
            ''
          )
        )}.

        A â‚¹60 reverse-shipping fee may
        apply.

        Submitting this form creates a
        review request only. It does not
        cancel the order or trigger a
        refund.
      </div>

      <label
        class="co-lbl"
        for="rr_type"
      >
        Request type
      </label>

      <select
        class="co-inp"
        id="rr_type"
      >
        <option value="return">
          Return
        </option>

        <option value="exchange">
          Exchange
        </option>
      </select>

      <div class="co-lbl">
        Request scope
      </div>

      <div class="rr-choice">
        <label class="rr-radio">
          <input
            type="radio"
            name="rr_scope"
            value="full_order"
            checked
            onchange="toggleReturnScope()"
          >

          Full order
        </label>

        <label class="rr-radio">
          <input
            type="radio"
            name="rr_scope"
            value="items"
            onchange="toggleReturnScope()"
          >

          Selected items
        </label>
      </div>

      <div
        class="rr-items"
        id="rrItems"
      >
        ${
          items.map(
            (item, index) => {
              const orderedQty =
                Math.max(
                  1,
                  Number(
                    item.qty ||
                    item.quantity ||
                    1
                  )
                );

              return `
                <div class="rr-item">
                  <input
                    class="rr-item-check"
                    type="checkbox"
                    data-line-index="${index}"
                    data-sku="${esc(
                      item.sku || ''
                    )}"
                  >

                  <div>
                    <div class="rr-item-name">
                      ${esc(
                        item.name ||
                        item.sku ||
                        'Jewellery'
                      )}
                    </div>

                    <div class="rr-item-sku">
                      ${esc(
                        item.sku || ''
                      )}
                      Â· ordered
                      ${orderedQty}
                    </div>
                  </div>

                  <input
                    class="rr-qty"
                    type="number"
                    min="1"
                    max="${orderedQty}"
                    value="1"
                    aria-label="Return quantity"
                  >
                </div>
              `;
            }
          ).join('') ||
          `
            <div class="od-note">
              No returnable items found.
            </div>
          `
        }
      </div>

      <label
        class="co-lbl"
        for="rr_reason_code"
      >
        Reason
      </label>

      <select
        class="co-inp"
        id="rr_reason_code"
      >
        <option value="damaged">
          Damaged / defective
        </option>

        <option value="wrong_item">
          Wrong item received
        </option>

        <option value="not_as_expected">
          Not as expected
        </option>

        <option value="size_issue">
          Size / fit issue
        </option>

        <option value="changed_mind">
          Changed mind
        </option>

        <option value="other">
          Other
        </option>
      </select>

      <label
        class="co-lbl"
        for="rr_reason_text"
      >
        Reason details
      </label>

      <textarea
        class="co-inp"
        id="rr_reason_text"
        rows="3"
        maxlength="1000"
        placeholder="Explain the issue clearly"
      ></textarea>

      <label
        class="co-lbl"
        for="rr_customer_note"
      >
        Additional note
      </label>

      <textarea
        class="co-inp"
        id="rr_customer_note"
        rows="2"
        maxlength="2000"
        placeholder="For exchange, mention the preferred replacement"
      ></textarea>

      <button
        class="rr-submit"
        id="rrSubmit"
        onclick="submitReturnRequest()"
      >
        Submit Request
      </button>
    `;

  document
    .getElementById(
      'returnRequestMo'
    )
    .classList
    .add('on');
}

async function submitReturnRequest() {
  if (
    returnRequestSubmitting ||
    !activeReturnOrderId
  ) {
    return;
  }

  const order =
    ordersCache.find(
      (item) =>
        String(item.order_id) ===
        String(
          activeReturnOrderId
        )
    );

  if (!order) {
    return;
  }

  const requestType =
    String(
      document
        .getElementById(
          'rr_type'
        )
        ?.value ||
      'return'
    );

  const requestScope =
    document.querySelector(
      'input[name="rr_scope"]:checked'
    )?.value ||
    'full_order';

  const reasonCode =
    String(
      document
        .getElementById(
          'rr_reason_code'
        )
        ?.value ||
      'other'
    );

  const reasonText =
    String(
      document
        .getElementById(
          'rr_reason_text'
        )
        ?.value ||
      ''
    ).trim();

  const customerNote =
    String(
      document
        .getElementById(
          'rr_customer_note'
        )
        ?.value ||
      ''
    ).trim();

  if (
    reasonText.length < 3
  ) {
    toast(
      'Please enter the return or exchange reason'
    );

    return;
  }

  const selectedItems = [];

  if (
    requestScope === 'items'
  ) {
    document
      .querySelectorAll(
        '#rrItems .rr-item-check:checked'
      )
      .forEach(
        (check) => {
          const row =
            check.closest(
              '.rr-item'
            );

          const qtyInput =
            row?.querySelector(
              '.rr-qty'
            );

          const maxQty =
            Math.max(
              1,
              Number(
                qtyInput?.max ||
                1
              )
            );

          const quantity =
            Math.min(
              maxQty,
              Math.max(
                1,
                Number(
                  qtyInput?.value ||
                  1
                )
              )
            );

          selectedItems.push({
            line_index:
              Number(
                check.dataset
                  .lineIndex
              ),

            sku:
              check.dataset.sku ||
              '',

            quantity,
          });
        }
      );

    if (
      !selectedItems.length
    ) {
      toast(
        'Select at least one item'
      );

      return;
    }
  }

  returnRequestSubmitting =
    true;

  const submitButton =
    document.getElementById(
      'rrSubmit'
    );

  if (submitButton) {
    submitButton.disabled =
      true;

    submitButton.textContent =
      'Submitting...';
  }

  try {
    const result =
      await customerApi(
        `/orders/${encodeURIComponent(
          activeReturnOrderId
        )}/return-requests`,
        {
          method: 'POST',

          body:
            JSON.stringify({
              request_type:
                requestType,

              request_scope:
                requestScope,

              reason_code:
                reasonCode,

              reason_text:
                reasonText,

              customer_note:
                customerNote,

              items:
                selectedItems,
            }),
        }
      );

    const requestId =
      result?.request
        ?.request_id ||
      '';

    closeReturnRequest();

    toast(
      requestId
        ? `Request submitted: ${requestId}`
        : 'Return request submitted'
    );

    await fetchCustomerOrders();
  } catch (error) {
    console.error(
      'Return request error:',
      error
    );

    toast(
      error.message ||
      'Could not submit return request'
    );
  } finally {
    returnRequestSubmitting =
      false;

    if (submitButton) {
      submitButton.disabled =
        false;

      submitButton.textContent =
        'Submit Request';
    }
  }
}

function parseOrderItems(items) {
  if(Array.isArray(items)) return items;
  try{
    const parsed = JSON.parse(items || '[]');
    return Array.isArray(parsed) ? parsed : [];
  }catch{ return []; }
}
function orderBadgeClass(o){
  const payment = String(o.payment_status || '').toLowerCase();
  const status = String(o.status || '').toLowerCase();
  return payment === 'paid' ? (status || 'paid') : (payment || status || 'pending');
}
function orderBadgeText(o){
  const payment = String(o.payment_status || '').toLowerCase();
  const status = String(o.status || 'pending').toLowerCase();
  if(payment && payment !== 'paid') return payment;
  return status || payment || 'pending';
}
function deliveryAddressHTML(o){
  const name = esc(o.shipping_name || o.customer_name || '');
  const phone = esc(o.shipping_phone || o.phone || '');
  const address = esc(o.shipping_address || '');
  const city = esc(o.shipping_city || '');
  const state = esc(o.shipping_state || '');
  const pin = esc(String(o.shipping_pincode || '').replace(/\D/g,''));

  const line1 = [name, phone].filter(Boolean).join(' â€¢ ');
  const line2 = [address, city, state].filter(Boolean).join(', ');
  const line3 = pin ? `Pincode: ${pin}` : '';

  return [line1, line2, line3].filter(Boolean).join('<br>') || 'Not available yet';
}

function orderStep(label, value){
  return `
    <div class="od-step ${value ? 'on' : ''}">
      <span class="od-dot"></span>
      <span>${esc(label)}${value ? ' â€” ' + fmtDate(value) : ''}</span>
    </div>
  `;
}

function openOrderDetails(
  orderId
) {
  const order =
    ordersCache.find(
      (item) =>
        String(item.order_id) ===
        String(orderId)
    );

  if (!order) {
    return;
  }

  const items =
    parseOrderItems(
      order.items
    );

  const helpText =
    encodeURIComponent(
      `Hi KAAPAV, I need help with order ${order.order_id}`
    );

  const latestReturn =
    order.return_request ||
    null;

  const openReturn =
    isOpenReturnRequest(
      latestReturn
    );

  const eligible =
    isReturnEligible(
      order
    );

  const returnSection =
    latestReturn
      ? `
        <div class="rr-status">
          <strong>
            ${esc(
              returnRequestLabel(
                latestReturn
              )
            )}
          </strong>

          <span>
            Request ID:
            ${esc(
              latestReturn
                .request_id ||
              ''
            )}
          </span>

          <span>
            Submitted:
            ${fmtDate(
              latestReturn
                .requested_at ||
              latestReturn
                .created_at ||
              ''
            )}
          </span>
        </div>
      `
      : `
        <div class="rr-status">
          <strong>
            ${
              eligible
                ? 'Eligible for return / exchange'
                : 'Return / exchange unavailable'
            }
          </strong>

          <span>
            ${esc(
              returnWindowText(
                order
              )
            )}
          </span>
        </div>
      `;

  document
    .getElementById(
      'orderDetailBody'
    )
    .innerHTML = `
      <div class="od-section">
        <div class="od-section-title">
          Order
        </div>

        <div class="od-kv">
          <span>Order ID</span>
          <strong>
            ${esc(order.order_id)}
          </strong>
        </div>

        <div class="od-kv">
          <span>Placed</span>
          <strong>
            ${fmtDate(order.created_at)}
          </strong>
        </div>

        <div class="od-kv">
          <span>Status</span>
          <strong>
            ${esc(
              order.status ||
              'pending'
            )}
          </strong>
        </div>

        <div class="od-kv">
          <span>Payment</span>
          <strong>
            ${esc(
              order.payment_status ||
              'unpaid'
            )}
          </strong>
        </div>
      </div>

      <div class="od-section">
        <div class="od-section-title">
          Delivery Address
        </div>

        <div class="od-kv">
          <span>Name</span>
          <strong>
            ${esc(
              order.shipping_name ||
              order.customer_name ||
              ''
            )}
          </strong>
        </div>

        <div class="od-kv">
          <span>Phone</span>
          <strong>
            ${esc(
              order.shipping_phone ||
              order.phone ||
              ''
            )}
          </strong>
        </div>

        <div class="od-kv od-address">
          <span>Address</span>
          <strong>
            ${deliveryAddressHTML(
              order
            )}
          </strong>
        </div>
      </div>

      <div class="od-section">
        <div class="od-section-title">
          Items
        </div>

        ${
          items.length
            ? items.map(
                (item) => `
                  <div class="od-kv">
                    <span>
                      ${esc(
                        item.name ||
                        item.sku ||
                        'Jewellery'
                      )}
                      Ã—
                      ${Number(
                        item.qty ||
                        item.quantity ||
                        1
                      )}
                    </span>

                    <strong>
                      ${money(
                        Number(
                          item.price ||
                          0
                        ) *
                        Number(
                          item.qty ||
                          item.quantity ||
                          1
                        )
                      )}
                    </strong>
                  </div>
                `
              ).join('')
            : `
                <div class="od-kv">
                  <span>Items</span>
                  <strong>-</strong>
                </div>
              `
        }
      </div>

      <div class="od-section">
        <div class="od-section-title">
          Bill Summary
        </div>

        <div class="od-kv">
          <span>Subtotal</span>
          <strong>
            ${money(order.subtotal)}
          </strong>
        </div>

        <div class="od-kv">
          <span>Discount</span>
          <strong>
            ${money(order.discount)}
          </strong>
        </div>

        <div class="od-kv">
          <span>Shipping</span>
          <strong>
            ${
              Number(
                order.shipping_cost ||
                0
              ) === 0
                ? 'FREE'
                : money(
                    order.shipping_cost
                  )
            }
          </strong>
        </div>

        <div class="od-kv">
          <span>Total</span>
          <strong>
            ${money(order.total)}
          </strong>
        </div>
      </div>

      <div class="od-section">
        <div class="od-section-title">
          Shipping
        </div>

        <div class="od-kv">
          <span>Courier</span>
          <strong>
            ${esc(
              order.courier ||
              'Not assigned yet'
            )}
          </strong>
        </div>

        <div class="od-kv">
          <span>AWB</span>
          <strong>
            ${esc(
              order.awb_number ||
              'Not generated yet'
            )}
          </strong>
        </div>

        <div class="od-kv">
          <span>Tracking ID</span>
          <strong>
            ${esc(
              order.tracking_id ||
              'Not generated yet'
            )}
          </strong>
        </div>

        <div class="od-kv od-address">
          <span>Ship to</span>
          <strong>
            ${deliveryAddressHTML(
              order
            )}
          </strong>
        </div>
      </div>

      <div class="od-section">
        <div class="od-section-title">
          Timeline
        </div>

        <div class="od-timeline">
          ${orderStep(
            'Order placed',
            order.created_at
          )}

          ${orderStep(
            'Payment received',
            order.paid_at
          )}

          ${orderStep(
            'Shipped',
            order.shipped_at
          )}

          ${orderStep(
            'Delivered',
            order.delivered_at
          )}

          ${
            order.cancelled_at
              ? orderStep(
                  'Cancelled',
                  order.cancelled_at
                )
              : ''
          }
        </div>
      </div>

      <div class="od-section">
        <div class="od-section-title">
          Returns & Exchanges
        </div>

        ${returnSection}

        ${
          eligible &&
          !openReturn
            ? `
              <button
                class="rr-submit"
                data-order-id="${esc(
                  order.order_id
                )}"
                onclick="openReturnRequest(this.dataset.orderId)"
              >
                Start Return / Exchange
              </button>
            `
            : ''
        }
      </div>

      <div class="od-actions">
        ${
          order.payment_link &&
          String(
            order.payment_status
          ).toLowerCase() !==
          'paid'
            ? `
              <a
                class="od-btn od-pay"
                href="${esc(
                  order.payment_link
                )}"
                target="_blank"
              >
                Pay Now
              </a>
            `
            : ''
        }

        ${
          order.tracking_url
            ? `
              <a
                class="od-btn"
                href="${esc(
                  order.tracking_url
                )}"
                target="_blank"
              >
                Track Order
              </a>
            `
            : ''
        }

        <a
          class="od-btn od-wa"
          href="${WA}?text=${helpText}"
          target="_blank"
        >
          WhatsApp Help
        </a>
      </div>
    `;

  document
    .getElementById(
      'orderDetailMo'
    )
    .classList
    .add('on');
}

async function fetchCustomerOrders(){
  if(!hasValidCustomerToken()){
    renderProfileHome();
    return;
  }

  try{
    const data = await customerApi(`/orders?t=${Date.now()}`, {
      method:'GET',
    });

    ordersCache = data.orders || [];
    renderCustomerOrders(ordersCache);
  }catch(e){
    console.error('Orders load error:', e);

    document.getElementById('ordersBody').innerHTML = `
      <div class="od-empty">
        <div class="ei">âš ï¸</div>
        Could not load your orders.<br>${esc(e.message || 'Please try again.')}
      </div>
    `;
  }
}

function renderCustomerOrders(
  orders
) {
  const email =
    customerProfile?.email ||
    getStoredProfileEmail();

  const phoneBox = `
    <div class="od-phone-box">
      <div class="od-note">
        Showing orders for verified email
        <strong>
          ${esc(email)}
        </strong>
      </div>

      <button
        class="od-load"
        onclick="fetchCustomerOrders()"
      >
        Refresh Orders
      </button>
    </div>
  `;

  if (!orders.length) {
    document
      .getElementById(
        'ordersBody'
      )
      .innerHTML =
        phoneBox +
        `
          <div class="od-empty">
            <div class="ei">
              ðŸ›ï¸
            </div>

            No orders found for this
            account yet.

            <br>

            Place an order from the
            catalogue and it will show
            here.
          </div>
        `;

    return;
  }

  document
    .getElementById(
      'ordersBody'
    )
    .innerHTML =
      phoneBox +
      orders.map(
        (order) => {
          const items =
            parseOrderItems(
              order.items
            );

          const badge =
            orderBadgeClass(
              order
            );

          const helpText =
            encodeURIComponent(
              `Hi KAAPAV, I need help with order ${order.order_id}`
            );

          const latestReturn =
            order.return_request ||
            null;

          const openReturn =
            isOpenReturnRequest(
              latestReturn
            );

          const eligible =
            isReturnEligible(
              order
            );

          const returnLine =
            latestReturn
              ? `
                <div class="od-note">
                  Return / exchange:
                  <strong>
                    ${esc(
                      returnRequestLabel(
                        latestReturn
                      )
                    )}
                  </strong>
                </div>
              `
              : `
                <div class="od-note">
                  ${esc(
                    returnWindowText(
                      order
                    )
                  )}
                </div>
              `;

          return `
            <div class="od-card">
              <div class="od-top">
                <div>
                  <div class="od-id">
                    ${esc(
                      order.order_id
                    )}
                  </div>

                  <div class="od-date">
                    ${fmtDate(
                      order.created_at
                    )}
                  </div>
                </div>

                <span
                  class="od-pill od-${esc(
                    badge
                  )}"
                >
                  ${esc(
                    orderBadgeText(
                      order
                    )
                  )}
                </span>
              </div>

              <div class="od-items">
                ${
                  items.length
                    ? items.map(
                        (item) => `
                          <div class="od-item">
                            <span>
                              ${esc(
                                item.name ||
                                item.sku ||
                                'Jewellery'
                              )}
                              Ã—
                              ${Number(
                                item.qty ||
                                item.quantity ||
                                1
                              )}
                            </span>

                            <strong>
                              ${money(
                                Number(
                                  item.price ||
                                  0
                                ) *
                                Number(
                                  item.qty ||
                                  item.quantity ||
                                  1
                                )
                              )}
                            </strong>
                          </div>
                        `
                      ).join('')
                    : `
                        <div class="od-item">
                          <span>
                            Items saved in order
                          </span>

                          <strong>-</strong>
                        </div>
                      `
                }
              </div>

              <div class="od-total">
                <span>Total</span>

                <strong>
                  ${money(order.total)}
                </strong>
              </div>

              ${returnLine}

              <div class="od-actions">
                <button
                  class="od-btn"
                  data-order-id="${esc(
                    order.order_id
                  )}"
                  onclick="openOrderDetails(this.dataset.orderId)"
                >
                  View Details
                </button>

                ${
                  eligible &&
                  !openReturn
                    ? `
                      <button
                        class="od-btn od-return"
                        data-order-id="${esc(
                          order.order_id
                        )}"
                        onclick="openReturnRequest(this.dataset.orderId)"
                      >
                        Return / Exchange
                      </button>
                    `
                    : ''
                }

                ${
                  order.payment_link &&
                  String(
                    order.payment_status
                  ).toLowerCase() !==
                  'paid'
                    ? `
                      <a
                        class="od-btn od-pay"
                        href="${esc(
                          order.payment_link
                        )}"
                        target="_blank"
                      >
                        Pay Now
                      </a>
                    `
                    : ''
                }

                ${
                  order.tracking_url
                    ? `
                      <a
                        class="od-btn"
                        href="${esc(
                          order.tracking_url
                        )}"
                        target="_blank"
                      >
                        Track
                      </a>
                    `
                    : ''
                }

                ${
                  order.awb_number
                    ? `
                      <span class="od-btn">
                        AWB:
                        ${esc(
                          order.awb_number
                        )}
                      </span>
                    `
                    : ''
                }

                <a
                  class="od-btn od-wa"
                  href="${WA}?text=${helpText}"
                  target="_blank"
                >
                  Help
                </a>
              </div>
            </div>
          `;
        }
      ).join('');
}

// â”€â”€ CHECKOUT â”€â”€
function openCheckout(){
  if(!Object.keys(cart).length){ toast('Cart is empty'); return; }
  appliedCoupon = null;
  closeCart();
if(typeof kpvTrack!=='undefined') kpvTrack.initiateCheckout({value:cartTotal(),numItems:cartCount(),productIds:Object.keys(cart)});
trackCatalogueEvent('InitiateCheckout',{
  cart_total:cartTotal(),
  total_items:cartCount(),
  checkout_items:Object.values(cart).map(item=>({
    sku:item.sku,
    name:item.name,
    category:item.category,
    qty:item.qty,
    price:item.price,
  }))
});
  const sub = cartTotal();
const ship = sub >= FREE_SHIP ? 0 : SHIP_COST;
const total = sub + ship;
  const items=Object.values(cart);
const savedEmail = localStorage.getItem('customerEmail') || '';
  document.getElementById('coBody').innerHTML=`
    <div style="padding:0 0 15px">
      <div class="co-lbl">Delivery details</div>
      <input class="co-inp" id="co_name" placeholder="Full name *" type="text">
      <input class="co-inp" id="co_phone" placeholder="WhatsApp number * (10 digits)" type="tel" maxlength="10">
<input class="co-inp" id="co_email" placeholder="Email for order updates *" type="email" value="${esc(savedEmail)}">
      <input class="co-inp" id="co_addr" placeholder="Full address *" type="text">
      <div class="co-row">
        <input class="co-inp" id="co_city" placeholder="City *" type="text">
        <input class="co-inp" id="co_pin" placeholder="Pincode *" type="tel" maxlength="6">
      </div>
      <input class="co-inp" id="co_state" placeholder="State *" type="text">
    </div>
    <div class="co-sum">
    <div class="co-reassure">
      <strong>Order updates made simple.</strong><br>
      Your order confirmation and courier updates will be sent on WhatsApp + email.
    </div>
      ${items.map(i=>`<div class="co-item"><span>${i.name} Ã— ${i.qty}</span><span>â‚¹${i.price*i.qty}</span></div>`).join('')}
      <div class="co-item"><span>Shipping</span><span>${ship===0?'FREE':'â‚¹'+ship}</span></div>
      <div class="co-item" style="gap:8px;align-items:center">
  <input class="co-inp" id="co_coupon" placeholder="Coupon code" style="margin:0;flex:1;text-transform:uppercase">
  <button type="button" class="btn-checkout" onclick="applyCoupon()" style="width:auto;margin:0;padding:11px 14px">Apply</button>
</div>
<div id="co_coupon_msg" style="font-size:12px;color:var(--gold);margin:4px 0 8px"></div>
<div class="co-item" id="co_discount_row" style="display:none">
  <span>Discount <b id="co_discount_code"></b></span>
  <span>-â‚¹<span id="co_discount_amt">0</span></span>
</div>
<div class="co-item tot"><span>Total</span><span id="co_total">â‚¹${total}</span></div>
    </div>
<button class="btn-pay" id="payBtn" onclick="doCheckout()">Pay â‚¹${total} with Razorpay</button>
    <button class="btn-wa-cart" onclick="orderViaWA();closeCheckout()" style="margin-bottom:10px">
      <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor"><path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413z"/></svg>
      Or order via WhatsApp
    </button>
    <p class="pay-secure">ðŸ”’ Secured by Razorpay Â· SSL Encrypted</p>
  `;
  document.getElementById('coMo').classList.add('on');
}
function closeCheckout(){ document.getElementById('coMo').classList.remove('on'); }

let addressWarningShown = false;

function isAddressComplete(address){

  if(!address) return false;

  return (
    address.length >= 12 &&
    /\d/.test(address)
  );
}

function showPaymentSuccessScreen(orderId) {
  closeCheckout();

  document.body.style.overflow = '';

  setTimeout(() => {
    document.querySelectorAll('.razorpay-container').forEach(el => {
      try { el.remove(); } catch(e) {}
    });
  }, 500);

  document.getElementById('grid').innerHTML = `
    <div style="grid-column:1/-1;text-align:center;padding:60px 20px">
      <div style="font-size:56px;margin-bottom:16px">ðŸŽ‰</div>
      <div style="font-family:var(--font-serif);font-size:24px;color:var(--dark);margin-bottom:8px">Payment Received!</div>
      <div style="font-size:13px;color:var(--gray);margin-bottom:6px">Order ID: <strong>${orderId}</strong></div>
      <div style="font-size:13px;color:var(--gray);margin-bottom:20px">Confirmation will arrive on WhatsApp shortly âœ…</div>
      <button onclick="openOrders()" style="background:var(--dark);color:var(--gold-l);border:none;border-radius:10px;padding:12px 28px;font-family:var(--font-sans);font-size:13px;cursor:pointer;margin-bottom:10px">View My Orders</button>
      <br>
      <button onclick="location.reload()" style="background:var(--cream);color:var(--dark);border:0.5px solid var(--border);border-radius:10px;padding:11px 24px;font-family:var(--font-sans);font-size:13px;cursor:pointer">Continue Shopping</button>
    </div>
  `;

  window.scrollTo({ top: 0, behavior: 'smooth' });
}

async function doCheckout(){
  const totals = checkoutTotals();
  const total = totals.total;
  const name=document.getElementById('co_name')?.value.trim();
const phone=document.getElementById('co_phone')?.value.trim();
const emailRaw = document.getElementById('co_email')?.value.trim().toLowerCase() || '';
const email = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(emailRaw) ? emailRaw : '';

if (emailRaw && !email) {
  toast('Email looks off â€” add a valid one for courier updates.');
  return;
}

if (!emailRaw) {
  toast('Please add your email for invoice and courier updates.');
  return;
}

if (!email) {
  toast('Please enter a valid email for invoice and courier updates.');
  return;
}

localStorage.setItem('customerEmail', email);
localStorage.setItem('customerPhone', '91' + phone);
localStorage.setItem('phone', '91' + phone);

  const addr=document.getElementById('co_addr')?.value.trim();
  const city=document.getElementById('co_city')?.value.trim();
  const pin=document.getElementById('co_pin')?.value.trim();
  const state=document.getElementById('co_state')?.value.trim();
  if(!name||!phone||!email||!addr||!city||!pin||!state){
  toast('Please fill all fields');
  return;
}

let addressWarningShown = false;

if(!isAddressComplete(addr)){

  if(!addressWarningShown){

    toast('Add House/Flat No, Area/Locality and Pincode for smooth delivery.');

    addressWarningShown = true;
  }

  return;
}
  if(phone.length!==10){ toast('Enter valid 10-digit number'); return; }
  if(pin.length!==6){ toast('Enter valid 6-digit pincode'); return; }

  const btn=document.getElementById('payBtn');
  btn.disabled = true;
btn.textContent = 'Creating secure checkout...';
const razorpayReady = loadRazorpay();

  const items = Object.values(cart).map(i => ({
  sku: i.sku,
  name: i.name,
  category: i.category || '',
  price: i.price,
  qty: i.qty,
  image: i.image || i.image_url || '',
  image_url: i.image_url || i.image || ''
}));
  try {
    const res=await fetch(ORDER_API,{
      method:'POST',
      headers:{'Content-Type':'application/json'},
      body:JSON.stringify({
  name,
  phone:'91'+phone,
  address:addr,
  email,
  city,
  state,
  pincode:pin,
  items,
  subtotal:cartTotal(),
  shipping:cartTotal()>=FREE_SHIP?0:SHIP_COST,
  couponCode: appliedCoupon?.code || normalizeCoupon(document.getElementById('co_coupon')?.value),
discount: totals.discount,
  total:cartTotal()
})
    });
const data = await res.json();

if (!res.ok || !data.success) {
  throw new Error(data.error || data.message || 'Order failed');
}
await razorpayReady;
if (typeof Razorpay === 'undefined') {
  throw new Error('Secure payment could not load. Please retry on a stable connection.');
}
const payableTotal = Number(data.total || total);
btn.textContent = 'Opening Razorpay...';
const rzp=new Razorpay({
  key: RZP_KEY,
  amount: payableTotal * 100,
  currency: 'INR',
  name: 'KAAPAV Fashion Jewellery',
  description: 'Order '+data.orderId,
  prefill:{ 
  name, 
  contact:'+91'+phone,
  ...(email ? { email } : {})
},
  theme:{ color:'#C49432' },

  webview_intent: true,
  config: {
    display: {
      blocks: {
        banks: {
          name: 'All Payment Options',
          instruments: [
            { method: 'upi' },
            { method: 'card' },
            { method: 'wallet' },
            { method: 'netbanking' }
          ]
        }
      },
      sequence: ['block.banks'],
      preferences: {
        show_default_blocks: false
      }
    }
  },

handler: function(resp){
  const paidOrderId = data.orderId;
  const paidPhone = '91' + phone;
  const paidPaymentId = resp.razorpay_payment_id;

  const purchasePayload = {
    value: payableTotal,
    orderId: paidOrderId,
    numItems: cartCount(),
    productIds: Object.keys(cart),
    contents: Object.values(cart).map(i => ({
      id: i.sku,
      quantity: i.qty,
      item_price: i.price
    })),
    phone: paidPhone,
    name
  };

  // Show success screen IMMEDIATELY. Never wait for backend here.
cart = {};
saveCart();
updateCartCount();

showPaymentSuccessScreen(paidOrderId);

  try {
    if (typeof kpvTrack !== 'undefined') {
      kpvTrack.purchase(purchasePayload);
    }
  } catch(e) {
    console.error('Purchase tracking error:', e);
  }

  // Backend confirmation runs in background.
  fetch('https://wa.kaapav.com/api/orders/confirm', {
    method: 'POST',
    headers: {'Content-Type':'application/json'},
    keepalive: true,
    body: JSON.stringify({
      orderId: paidOrderId,
      paymentId: paidPaymentId,
      phone: paidPhone
    })
  }).catch(e => {
    console.error('Background confirm error:', e);
  });
},
      modal:{ ondismiss:function(){
        btn.disabled=false; btn.textContent=`Pay â‚¹${payableTotal} with Razorpay`;
        toast('Payment cancelled. You can try again from checkout.');
      }}
    });
    requestAnimationFrame(() => {
  rzp.open();
});
  } catch(e){
    btn.disabled=false; btn.textContent=`Pay â‚¹${checkoutTotals().total} with Razorpay`;
    console.error('Checkout error:', e);
toast(e.message || 'Something went wrong. Try WhatsApp order.');
  }
}

/* trackCatalogueEvent('Purchase',{
  cart_total: total,
  checkout_items: items.map(i => ({
    sku: i.sku,
    name: i.name,
    qty: i.qty,
    price: i.price
  }))
}); */
// â”€â”€ PRODUCT MODAL â”€â”€
function openProd(sku){
  const p=products.find(x=>x.sku===sku); if(!p) return;
  curProd=p; curQty=1; curGallIdx=0;
if(typeof kpvTrack!=='undefined') kpvTrack.viewContent({id:p.sku,name:p.name,price:p.price,category:p.category,image:p.image_url||''});
trackCatalogueEvent('ViewContent',{
  sku:p.sku,
  product_name:p.name,
  category:p.category,
  price:p.price
});
  const imgs=p.images.length?p.images:(p.image_url?[p.image_url]:[]);
  const disc=p.compare_price>p.price?Math.round((1-p.price/p.compare_price)*100):0;
  const sav=p.compare_price>p.price?p.compare_price-p.price:0;
  const imgsJson = JSON.stringify(imgs).replace(/"/g, '&quot;');

  document.getElementById('pgal').innerHTML=imgs.length
    ?`<img id="gm" class="g-main" src="${imgs[0]}"
    onclick="openImageViewer(JSON.parse(this.dataset.imgs), curGallIdx)"
    data-imgs="${imgsJson}" alt="${p.name}" style="cursor:zoom-in">
      ${imgs.length>1?`<div class="g-thumbs">${imgs.map((u,i)=>`<img class="g-th${i===0?' on':''}" src="${u}" onclick="setGI(${i})" loading="lazy">`).join('')}</div>`:''}`
    :`<div class="g-ph">${CATS[p.category]?.emoji||'ðŸ’Ž'}</div>`;

  const tagsH=p.tags.map(t=>{ const tc=TAGS[t]; return tc?`<span class="t-chip" style="background:${tc.bg};color:${tc.color};font-size:11px;padding:3px 7px;border-radius:8px">${tc.emoji} ${t}</span>`:'' }).join('');
  const stockC=p.stock===0?`<span class="i-chip i-out">âŒ Out of stock</span>`:p.stock<=5?`<span class="i-chip i-low">âš ï¸ Only ${p.stock} left</span>`:`<span class="i-chip">âœ… In stock</span>`;
  const inWl=wishlist.has(p.sku);

  // You may also like
  const ymal=products.filter(x=>x.category===p.category&&x.sku!==p.sku).slice(0,8);
  const ymalH=ymal.length?`
    <div class="m-div"></div>
    <div class="ymal">
      <div class="ymal-title">You may also like</div>
      <div class="ymal-scroll">
        ${ymal.map(x=>{
          const xi=x.images.length?x.images:(x.image_url?[x.image_url]:[]);
          return `<div class="ymal-card" onclick="closePMOd();setTimeout(()=>openProd('${x.sku}'),120)">
            ${xi.length?`<img class="ymal-img" src="${xi[0]}" loading="lazy">`:`<div class="ymal-img" style="display:flex;align-items:center;justify-content:center;font-size:22px">${CATS[x.category]?.emoji||'ðŸ’Ž'}</div>`}
            <div class="ymal-body"><div class="ymal-name">${x.name}</div><div class="ymal-price">â‚¹${x.price}</div></div>
          </div>`;
        }).join('')}
      </div>
    </div>`:'';

  document.getElementById('pbody').innerHTML=`
    <div style="display:flex;align-items:flex-start;justify-content:space-between;gap:8px">
      <div>
        <div class="m-cat">${CATS[p.category]?.emoji||''} ${CATS[p.category]?.label||p.category}</div>
        <div class="m-name">${p.name}</div>
      </div>
      <button onclick="openShare('${p.sku}')" style="flex-shrink:0;margin-top:4px;background:var(--cream);border:0.5px solid var(--border);border-radius:8px;padding:6px 10px;cursor:pointer;font-size:13px">ðŸ“¤</button>
    </div>
    <div class="m-sku">SKU: ${p.sku}</div>
    <div class="m-pr">
      <span class="m-sale">â‚¹${p.price}</span>
      ${p.compare_price>p.price?`<span class="m-mrp">â‚¹${p.compare_price}</span><span class="m-sav">Save â‚¹${sav} (${disc}% off)</span>`:''}
    </div>
    ${tagsH?`<div class="m-tags">${tagsH}</div>`:''}
    <div class="m-div"></div>
    ${p.description?`<div class="m-lbl">About this piece</div><p class="m-desc">${p.description}</p><div class="m-div"></div>`:''}
    <div class="m-info">
      ${stockC}
      <span class="i-chip">ðŸšš Free shipping â‚¹498+</span>
      <span class="i-chip">â†©ï¸ 7-day returns</span>
      <span class="i-chip">ðŸ’³ Online payment</span>
    </div>
    ${p.website_link?`<a class="wl-link" href="${p.website_link}" target="_blank">ðŸŒ View on Website  â†’  Buy Now</a>`:''}
    <div class="qty-row">
      <span class="qty-lbl">Qty:</span>
      <div class="qty-ctrl">
        <button class="qty-btn" onclick="setQty(-1)">âˆ’</button>
        <span class="qty-val" id="qv">1</span>
        <button class="qty-btn" onclick="setQty(1)">+</button>
      </div>
    </div>
    ${ymalH}
  `;

  // Sticky ATC - append after pbody
  document.getElementById('pbox').insertAdjacentHTML('beforeend', `
    <div class="sticky-atc" id="satc">
      <button class="btn-cart" onclick="addFromModal()">${inWl?'â¤ï¸':''} Add to Cart</button>
      <button class="btn-buy" onclick="buyNow()">Buy Now</button>
      <button class="btn-wa-m" onclick="waOrder()" title="WhatsApp">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413z"/></svg>
      </button>
    </div>
  `);

  document.getElementById('pmo').classList.add('on');
  document.body.style.overflow='hidden';
}

function setGI(i){
  const p=curProd; const imgs=p.images.length?p.images:(p.image_url?[p.image_url]:[]);
  curGallIdx=i;
  const m=document.getElementById('gm'); if(m) m.src=imgs[i];
  document.querySelectorAll('.g-th').forEach((t,j)=>t.classList.toggle('on',j===i));
}
function setQty(d) {
  if (!curProd) return;
  const maxQty = curProd.stock || 0;
  const newQty = Math.max(1, Math.min(maxQty, curQty + d));
  if (d > 0 && newQty === curQty && curQty === maxQty) { toast(`That's the last of them! ðŸ¥°`); return; }
  curQty = newQty;
  const v = document.getElementById('qv');
  if (v) v.textContent = curQty;
}
function addFromModal(){ if(!curProd) return; addToCart(curProd.sku,curQty); if(typeof kpvTrack!=='undefined') kpvTrack.addToCart({id:curProd.sku,name:curProd.name,price:curProd.price,category:curProd.category},curQty); toast('Added to cart ðŸ›’'); closePMOd(); }
function buyNow(){
  if(!curProd) return;
  if(curProd.stock===0){ toast('Out of stock'); return; }
  cart={}; addToCart(curProd.sku,curQty); saveCart(); updateCartCount();
if(typeof kpvTrack!=='undefined') kpvTrack.addToCart({id:curProd.sku,name:curProd.name,price:curProd.price,category:curProd.category},curQty);
  closePMOd(); setTimeout(openCheckout,300);
}
function waOrder(){
  if(!curProd) return;
  const msg=`Hi! I want to order:\n\n*${curProd.name}*\nSKU: ${curProd.sku}\nQty: ${curQty}\nPrice: â‚¹${curProd.price*curQty}\n\nPlease help me place the order.`;
  window.open(`${WA}?text=${encodeURIComponent(msg)}`,'_blank');
}
function closePMO(e){ if(e.target===document.getElementById('pmo')) closePMOd(); }
function closePMOd(){ document.getElementById('pmo').classList.remove('on'); document.body.style.overflow=''; curProd=null; const s=document.getElementById('satc'); if(s) s.remove(); }

// â”€â”€ TOAST â”€â”€
function toast(msg){ const t=document.getElementById('toast'); t.textContent=msg; t.classList.add('on'); setTimeout(()=>t.classList.remove('on'),2200); }

// â”€â”€ STICKY OFFSETS â”€â”€
function fixStickyOffsets(){
  const hdr=document.querySelector('.hdr');
  const trust=document.querySelector('.trust-strip');
  const cats=document.querySelector('.cats');
  if(!hdr||!trust||!cats) return;
  const hh=Math.ceil(hdr.getBoundingClientRect().height);
  const th=Math.ceil(trust.getBoundingClientRect().height);
  const ch=Math.ceil(cats.getBoundingClientRect().height);
  document.documentElement.style.setProperty('--hdr-h', hh+'px');
  document.documentElement.style.setProperty('--trust-h', th+'px');
  document.documentElement.style.setProperty('--cat-h', (hh+th+ch)+'px');
}

// â”€â”€ IMAGE VIEWER â”€â”€
let viewerImages = [];
let viewerIndex = 0;

function openImageViewer(images, startIdx) {
  viewerImages = Array.isArray(images) ? images.filter(Boolean) : [];
  if (!viewerImages.length) return;
  viewerIndex = Math.max(0, Math.min(startIdx || 0, viewerImages.length - 1));
  updateViewerImage();
  document.getElementById('imgViewer').classList.add('on');
  document.body.style.overflow = 'hidden';
}

function closeImageViewer() {
  document.getElementById('imgViewer').classList.remove('on');
  document.getElementById('ivImg').style.transform = 'scale(1)';
  viewerScale = 1;
  viewerImages = [];
  viewerIndex = 0;
  if (!document.getElementById('pmo').classList.contains('on')) {
    document.body.style.overflow = '';
  }
}

function updateViewerImage() {
  const img = document.getElementById('ivImg');
  const counter = document.getElementById('ivCounter');
  const prev = document.getElementById('ivPrev');
  const next = document.getElementById('ivNext');
  img.src = viewerImages[viewerIndex];
  img.style.transform = 'scale(1)';
  viewerScale = 1;
  counter.textContent = (viewerIndex + 1) + ' / ' + viewerImages.length;
  const show = viewerImages.length > 1 ? 'flex' : 'none';
  prev.style.display = show;
  next.style.display = show;
}

function prevImage() {
  if (!viewerImages.length) return;
  viewerIndex = (viewerIndex - 1 + viewerImages.length) % viewerImages.length;
  updateViewerImage();
}

function nextImage() {
  if (!viewerImages.length) return;
  viewerIndex = (viewerIndex + 1) % viewerImages.length;
  updateViewerImage();
}


// â”€â”€ SWIPE + ZOOM + KEYBOARD â”€â”€
let touchStartX = 0, didSwipe = false;
let viewerScale = 1, viewerLastTap = 0, pinchStartDist = 0;
function getPinchDist(t){ return Math.hypot(t[0].clientX-t[1].clientX,t[0].clientY-t[1].clientY); }
document.getElementById('imgViewer').addEventListener('touchstart',function(e){
  if(e.touches.length===2){ pinchStartDist=getPinchDist(e.touches); }
  else if(e.touches.length===1){
    const now=Date.now();
    if(now-viewerLastTap<300){ viewerScale=viewerScale>1?1:2.5; document.getElementById('ivImg').style.transform='scale('+viewerScale+')'; }
    viewerLastTap=now; touchStartX=e.changedTouches[0].clientX; didSwipe=false;
  }
},{passive:true});
document.getElementById('imgViewer').addEventListener('touchmove',function(e){
  if(e.touches.length===2){ const d=getPinchDist(e.touches); viewerScale=Math.min(4,Math.max(1,viewerScale*(d/pinchStartDist))); pinchStartDist=d; document.getElementById('ivImg').style.transform='scale('+viewerScale+')'; }
},{passive:true});
document.getElementById('imgViewer').addEventListener('touchend',function(e){
  if(e.touches.length===0&&viewerScale===1){ const diff=touchStartX-e.changedTouches[0].clientX; if(Math.abs(diff)>50){ didSwipe=true; if(diff>0)nextImage(); else prevImage(); } }
});
document.addEventListener('keydown',function(e){
  if(!document.getElementById('imgViewer').classList.contains('on')) return;
  if(e.key==='ArrowLeft')prevImage(); else if(e.key==='ArrowRight')nextImage(); else if(e.key==='Escape')closeImageViewer();
});

// â”€â”€ SEARCH SUGGESTIONS â”€â”€
function saveSearch(term){ if(!term||term.length<2) return; recentSearches=recentSearches.filter(s=>s!==term).slice(0,6); recentSearches.unshift(term); localStorage.setItem('kp_searches',JSON.stringify(recentSearches)); }
function showSuggestions(){
  const box=document.getElementById('suggestions');
  const val=document.getElementById('si').value.trim().toLowerCase();
  if(!val&&!recentSearches.length){ box.classList.remove('on'); return; }
  let html='';
  if(!val && recentSearches.length){
    html=recentSearches.map(s=>`<div class="sug-item" onclick="pickSug('${s}')"><span class="sug-ico">ðŸ•</span>${s}</div>`).join('');
    html+=`<div class="sug-clear" onclick="clearSearches()">Clear recent searches</div>`;
  } else if(val){
    const matches=[...new Set(products.filter(p=>p.name.toLowerCase().includes(val)||p.tags.some(t=>t.toLowerCase().includes(val))).map(p=>p.name))].slice(0,5);
    const cats=Object.entries(CATS).filter(([k])=>k!=='all'&&k.toLowerCase().includes(val)).map(([k,c])=>`<div class="sug-item" onclick="setCat('${k}');hideSugg()"><span class="sug-ico">${c.emoji}</span>${c.label}</div>`).join('');
    html=cats+matches.map(n=>`<div class="sug-item" onclick="pickSug('${n.replace(/'/g,"\'")}')"><span class="sug-ico">ðŸ”</span>${n}</div>`).join('');
  }
  if(html){ box.innerHTML=html; box.classList.add('on'); } else box.classList.remove('on');
}
function pickSug(term){ document.getElementById('si').value=term; q=term; saveSearch(term); hideSugg(); applyFilters(); }
function hideSugg(){ document.getElementById('suggestions').classList.remove('on'); }
function clearSearches(){ recentSearches=[]; localStorage.removeItem('kp_searches'); hideSugg(); }
document.getElementById('si').addEventListener('input',e=>{ q=e.target.value.trim(); applyFilters(); showSuggestions(); });
document.getElementById('si').addEventListener('focus',()=>showSuggestions());
document.addEventListener('click',e=>{ if(!e.target.closest('.search-wrap')) hideSugg(); });
document.getElementById('si').addEventListener('keydown',e=>{ if(e.key==='Enter'&&q){ saveSearch(q); hideSugg(); applyFilters(); }});

// â”€â”€ SHARE â”€â”€
function openShare(sku){
  shareProd=products.find(p=>p.sku===sku);
  if(!shareProd) return;
  document.getElementById('shareTitle').textContent=shareProd.name;
  document.getElementById('shareMo').classList.add('on');
}
function closeShare(e){ if(e.target===document.getElementById('shareMo')||e.currentTarget===document.getElementById('shareMo')&&e.target.closest('.share-box')===null) document.getElementById('shareMo').classList.remove('on'); }
function shareWA(){
  if(!shareProd) return;
  const msg=`Hi! Check out this product from KAAPAV:\n\n*${shareProd.name}*\nPrice: â‚¹${shareProd.price}\n\n${shareProd.website_link||'https://catalogue.kaapav.com'}`;
if(typeof kpvTrack!=='undefined') kpvTrack.whatsappIntent(shareProd||null);

  window.open('https://wa.me/?text='+encodeURIComponent(msg),'_blank');
  document.getElementById('shareMo').classList.remove('on');
}
function shareCopy(){
  const url=shareProd?.website_link||'https://catalogue.kaapav.com';
  navigator.clipboard?.writeText(url).then(()=>toast('Link copied! ðŸ”—')).catch(()=>toast('Copy: '+url));
  document.getElementById('shareMo').classList.remove('on');
}
function shareNative(){
  if(!shareProd) return;
  const url=shareProd.website_link||'https://catalogue.kaapav.com';
  if(navigator.share){ navigator.share({title:shareProd.name,text:'Check out this jewellery from KAAPAV!',url}).catch(()=>{}); }
  else shareCopy();
  document.getElementById('shareMo').classList.remove('on');
}

// â”€â”€ PULL TO REFRESH â”€â”€
let ptrStartY=0, ptrActive=false;
document.addEventListener('touchstart',e=>{ if(window.scrollY===0) ptrStartY=e.touches[0].clientY; },{passive:true});
document.addEventListener('touchmove',e=>{
  if(window.scrollY>0) return;
  const dy=e.touches[0].clientY-ptrStartY;
  if(dy>60&&!ptrActive){ ptrActive=true; document.getElementById('ptr').classList.add('show'); document.getElementById('ptrTxt').textContent='Release to refresh'; }
},{passive:true});
document.addEventListener('touchend',()=>{
  if(ptrActive){ ptrActive=false; document.getElementById('ptrTxt').textContent='Refreshing...'; fetchProducts().finally(()=>{ setTimeout(()=>document.getElementById('ptr').classList.remove('show'),600); }); }
});

// â”€â”€ BACK TO TOP â”€â”€
window.addEventListener('scroll',()=>{
  document.getElementById('btt').classList.toggle('on',window.scrollY>400);
});

// â”€â”€ INIT â”€â”€
loadState(); updateCartCount(); updateWLCount();
window.verifyCustomerOtp = verifyCustomerOtp;
refreshCustomerProfile().then(() => linkCustomerIdentityFromCid());
if(!hydrateProductsFromCache()) shimmer();
fetchProducts();
setTimeout(fixStickyOffsets, 100);
window.addEventListener('resize', fixStickyOffsets, {passive:true});
if('ResizeObserver' in window){
  const stickyResizeObserver=new ResizeObserver(fixStickyOffsets);
  ['.hdr','.trust-strip','.cats'].forEach(sel=>{
    const el=document.querySelector(sel);
    if(el) stickyResizeObserver.observe(el);
  });
}
setInterval(fetchProducts, 30000);
document.addEventListener('visibilitychange',()=>{ if(!document.hidden) fetchProducts(); });
