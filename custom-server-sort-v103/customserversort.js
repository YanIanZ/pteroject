/**
 * Sourby Custom Server Sort 1.0.3
 * DOM-injection based server list sorting with localStorage persistence
 * Compatible with Sourby v1.12.2+
 */

(() => {
  if (!window.Sortable) {
    const s = document.createElement('script');
    s.src = 'https://cdn.jsdelivr.net/npm/sortablejs@latest/Sortable.min.js';
    s.onload = init;
    document.head.appendChild(s);
  } else {
    init();
  }

  function init() {
    let sortable = null;

    const storageKey = () => {
      const userId = window.PterodactylUser ? window.PterodactylUser.uuid : 'anon';
      return 'server_order_' + userId;
    };

    const load = () => {
      const stored = localStorage.getItem(storageKey());
      if (!stored || !sortable) return;
      sortable.sort(stored.split('|'));
    };

    const save = () => {
      if (!sortable) return;
      localStorage.setItem(
        storageKey(),
        sortable.toArray().filter(id => id.startsWith('/server/')).join('|')
      );
    };

    const findServerList = () => {
      const links = document.querySelectorAll('a[href^="/server/"]');
      if (links.length === 0) return null;

      for (const link of links) {
        let parent = link.parentElement;
        let depth = 0;
        while (parent && depth < 10) {
          const children = Array.from(parent.children).filter(c =>
            c.querySelector('a[href^="/server/"]')
          );
          if (children.length > 1) return parent;
          parent = parent.parentElement;
          depth++;
        }
      }
      return links[links.length - 1]?.parentElement;
    };

    const attachSortable = () => {
      const container = findServerList();
      if (!container || sortable) return;

      sortable = Sortable.create(container, {
        animation: 150,
        delay: ('ontouchstart' in window || navigator.maxTouchPoints > 0) ? 100 : 0,
        handle: 'a',
        dataIdAttr: 'href',
        filter: 'div[class*="Spinner"], div[class*="Skeleton"]',
        onEnd: () => save(),
      });

      load();
    };

    const observer = new MutationObserver(() => {
      if (window.location.pathname === '/' || window.location.pathname === '') {
        attachSortable();
      }
    });

    observer.observe(document.getElementById('app') || document.body, {
      childList: true,
      subtree: true,
    });

    attachSortable();
  }
})();
