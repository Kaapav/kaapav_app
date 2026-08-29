/**
 * KAAPAV SEO Script Injection Engine
 * Fetches custom head & body code from the backend settings API
 * and injects them into the current page for all visitors.
 *
 * Cached in sessionStorage to avoid repeated API calls per session.
 * Cache TTL: 10 minutes (re-fetches after that within same session).
 */
(function () {
  'use strict';

  var API = 'https://wa.kaapav.com/api/seo-scripts';
  var CACHE_KEY = 'kpv_seo_cache';
  var CACHE_TTL = 10 * 60 * 1000; // 10 minutes

  function injectHead(html) {
    if (!html) return;
    var container = document.createElement('div');
    container.innerHTML = html;
    var nodes = Array.from(container.childNodes);
    for (var i = 0; i < nodes.length; i++) {
      var node = nodes[i];
      if (node.tagName === 'SCRIPT') {
        var s = document.createElement('script');
        var attrs = Array.from(node.attributes);
        for (var j = 0; j < attrs.length; j++) {
          s.setAttribute(attrs[j].name, attrs[j].value);
        }
        s.textContent = node.textContent;
        document.head.appendChild(s);
      } else {
        document.head.appendChild(node.cloneNode(true));
      }
    }
  }

  function injectBody(html) {
    if (!html) return;
    var container = document.createElement('div');
    container.innerHTML = html;
    var nodes = Array.from(container.childNodes);
    for (var i = 0; i < nodes.length; i++) {
      var node = nodes[i];
      if (node.tagName === 'SCRIPT') {
        var s = document.createElement('script');
        var attrs = Array.from(node.attributes);
        for (var j = 0; j < attrs.length; j++) {
          s.setAttribute(attrs[j].name, attrs[j].value);
        }
        s.textContent = node.textContent;
        document.body.appendChild(s);
      } else {
        document.body.appendChild(node.cloneNode(true));
      }
    }
  }

  function applyScripts(data) {
    try { injectHead(data.custom_head_code); } catch (e) { /* silent */ }
    try { injectBody(data.custom_body_code); } catch (e) { /* silent */ }
  }

  // Check sessionStorage cache first
  try {
    var cached = sessionStorage.getItem(CACHE_KEY);
    if (cached) {
      var parsed = JSON.parse(cached);
      if (parsed.ts && (Date.now() - parsed.ts) < CACHE_TTL) {
        applyScripts(parsed.data);
        return;
      }
    }
  } catch (e) { /* ignore */ }

  // Fetch from API
  var xhr = new XMLHttpRequest();
  xhr.open('GET', API, true);
  xhr.timeout = 4000;
  xhr.onload = function () {
    if (xhr.status === 200) {
      try {
        var resp = JSON.parse(xhr.responseText);
        if (resp.success) {
          var data = {
            custom_head_code: resp.custom_head_code || '',
            custom_body_code: resp.custom_body_code || ''
          };
          applyScripts(data);
          try {
            sessionStorage.setItem(CACHE_KEY, JSON.stringify({ ts: Date.now(), data: data }));
          } catch (e) { /* quota */ }
        }
      } catch (e) { /* parse error */ }
    }
  };
  xhr.send();
})();
