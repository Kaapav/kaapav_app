
(() => {
  const body = document.body;

  let stopTimer = null;
  let animationFrame = null;

  const TOP_LIMIT = 45;
  const STOP_DELAY = 220;

  function showFullNavigation() {
    body.classList.remove(
      'kp-is-scrolling',
      'kp-scroll-stopped'
    );
  }

  function showOnlyCategories() {
    body.classList.remove('kp-is-scrolling');
    body.classList.add('kp-scroll-stopped');
  }

  function hideNavigationDuringScroll() {
    body.classList.add('kp-is-scrolling');
    body.classList.remove('kp-scroll-stopped');
  }

  function handleScroll() {
    clearTimeout(stopTimer);

    if (animationFrame) return;

    animationFrame = requestAnimationFrame(() => {
      animationFrame = null;

      if (window.scrollY < TOP_LIMIT) {
        showFullNavigation();
        return;
      }

      hideNavigationDuringScroll();

      stopTimer = setTimeout(() => {
        if (window.scrollY < TOP_LIMIT) {
          showFullNavigation();
          return;
        }

        showOnlyCategories();
      }, STOP_DELAY);
    });
  }

  window.addEventListener('scroll', handleScroll, {
    passive:true
  });

  window.addEventListener('resize', () => {
    clearTimeout(stopTimer);

    if (window.scrollY < TOP_LIMIT) {
      showFullNavigation();
    } else {
      showOnlyCategories();
    }

    if (typeof fixStickyOffsets === 'function') {
      setTimeout(fixStickyOffsets, 80);
    }
  });

  if (window.scrollY >= TOP_LIMIT) {
    showOnlyCategories();
  }
})();
