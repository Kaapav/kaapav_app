/**
 * KAAPAV Universal Live Sync Engine v5.1
 * Real-time script executor, styles injector, and inventory sync.
 */
(function() {
  function getStored(k) {
    try { const l = localStorage.getItem(k); if (l) return JSON.parse(l); } catch(e){}
    try { const s = sessionStorage.getItem(k); if (s) return JSON.parse(s); } catch(e){}
    try { const m = document.cookie.match(new RegExp('(^| )' + k + '=([^;]+)')); if (m) return JSON.parse(decodeURIComponent(m[2])); } catch(e){}
    return null;
  }

  function injectAndExecute(targetParent, rawHtml, containerId) {
    if (!rawHtml || !rawHtml.trim()) return;
    
    let container = document.getElementById(containerId);
    if (!container) {
      container = document.createElement('div');
      container.id = containerId;
      targetParent.appendChild(container);
    } else {
      container.innerHTML = '';
    }

    const temp = document.createElement('div');
    temp.innerHTML = rawHtml;

    Array.from(temp.childNodes).forEach(node => {
      if (node.nodeName.toLowerCase() === 'script') {
        const s = document.createElement('script');
        Array.from(node.attributes).forEach(attr => s.setAttribute(attr.name, attr.value));
        s.textContent = node.textContent;
        container.appendChild(s);
      } else {
        container.appendChild(node.cloneNode(true));
      }
    });
  }

  function syncLiveState() {
    try {
      // 1. Custom <head> Code Injection (with Script Execution)
      const headCode = localStorage.getItem('kpv_custom_head_code') || sessionStorage.getItem('kpv_custom_head_code');
      if (headCode) {
        injectAndExecute(document.head, headCode, 'kpv_injected_head_scripts');
      }

      // 2. Custom <body> Code Injection (with Script Execution)
      const bodyCode = localStorage.getItem('kpv_custom_body_code') || sessionStorage.getItem('kpv_custom_body_code');
      if (bodyCode) {
        injectAndExecute(document.body, bodyCode, 'kpv_injected_body_scripts');
      }

      // 3. Product Inventory & Stock Overrides
      const overrides = getStored('kpv_inventory_overrides');
      if (overrides && typeof MASTER_PRODUCTS !== 'undefined' && Array.isArray(MASTER_PRODUCTS)) {
        MASTER_PRODUCTS.forEach(p => {
          if (overrides[p.sku]) Object.assign(p, overrides[p.sku]);
        });
      }
    } catch(e) {}
  }

  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', syncLiveState);
  else syncLiveState();

  try {
    const ch = new BroadcastChannel('kaapav_admin_sync');
    ch.onmessage = () => syncLiveState();
  } catch(e){}
  window.addEventListener('storage', syncLiveState);
})();
