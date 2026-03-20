/**
 * main.js — progressive enhancement
 *
 * No compatibility shims for ancient engines.
 * If the browser runs this at all, it supports ES6+ and modern DOM APIs.
 * Everything here is additive — the page is fully usable without JS.
 */

(() => {
  "use strict";

  // ── 1. KEYBOARD HOTKEYS ─────────────────────────────────────────────────────
  // Reads data-hot attributes from <a class="mitem"> elements.
  // Pressing the hotkey letter jumps to the section or follows the href.

  const menubar = document.getElementById("menubar");
  const hotkeys = new Map();

  if (menubar) {
    menubar.querySelectorAll("a[data-hot]").forEach((link) => {
      hotkeys.set(link.dataset.hot.toLowerCase(), link);
    });
  }

  document.addEventListener("keydown", (e) => {
    // Ignore when typing in a form element
    const tag = document.activeElement?.tagName ?? "";
    if (["INPUT", "TEXTAREA", "SELECT"].includes(tag)) return;
    // Ignore modified keys (Ctrl+C, Alt+something, etc.)
    if (e.ctrlKey || e.altKey || e.metaKey) return;

    const link = hotkeys.get(e.key.toLowerCase());
    if (!link) return;

    const href = link.getAttribute("href");
    if (!href) return;

    if (href.startsWith("#")) {
      e.preventDefault();
      const target = document.getElementById(href.slice(1));
      target?.scrollIntoView({ behavior: "smooth", block: "start" });
    } else {
      window.location.href = href;
    }
  });

  // ── 2. COPY BUTTONS ─────────────────────────────────────────────────────────
  // Injects a <button class="copy-btn"> before each <pre>.
  // Uses Clipboard API with execCommand fallback.

  const copyToClipboard = async (text) => {
    if (navigator.clipboard) {
      try {
        await navigator.clipboard.writeText(text);
        return true;
      } catch {}
    }
    // Legacy fallback
    const ta = Object.assign(document.createElement("textarea"), {
      value: text,
      style: "position:absolute;left:-9999px;top:0",
    });
    document.body.appendChild(ta);
    ta.select();
    const ok = document.execCommand("copy");
    document.body.removeChild(ta);
    return ok;
  };

  document.querySelectorAll("pre").forEach((pre) => {
    const btn = document.createElement("button");
    btn.className = "copy-btn";
    btn.textContent = "copy";
    btn.setAttribute("aria-label", "Copy code to clipboard");

    btn.addEventListener("click", async () => {
      const text = pre.textContent ?? pre.innerText;
      const ok = await copyToClipboard(text);
      if (ok) {
        btn.textContent = "ok!";
        btn.classList.add("copied");
        setTimeout(() => {
          btn.textContent = "copy";
          btn.classList.remove("copied");
        }, 1500);
      }
    });

    pre.before(btn);
    pre.style.borderTop = "none";
    pre.style.marginTop = "0";
  });

  // ── 3. TABLE ZEBRA STRIPING ─────────────────────────────────────────────────
  // nth-child fallback is in base.css for modern browsers.
  // This class-based approach still runs for any browser that loads the JS.

  document.querySelectorAll("tbody").forEach((tbody) => {
    tbody.querySelectorAll("tr").forEach((tr, i) => {
      if (i % 2 === 1) tr.classList.add("tr-even");
    });
  });

  // ── 4. ACTIVE NAV HIGHLIGHT — IntersectionObserver ─────────────────────────
  // Watches h2 headings. When one enters the viewport, highlight its nav item.
  // Much more accurate than the old scroll-position math.

  if (menubar && "IntersectionObserver" in window) {
    const content = document.getElementById("content");
    const headings = content ? [...content.querySelectorAll("h2")] : [];
    const links = [...menubar.querySelectorAll("a.mitem")];

    const setActive = (id) => {
      links.forEach((link) => {
        const href = link.getAttribute("href");
        link.classList.toggle("mitem-active", href === `#${id}`);
      });
    };

    // Track which headings are currently visible
    const visible = new Set();

    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            visible.add(entry.target.id);
          } else {
            visible.delete(entry.target.id);
          }
        });

        // Activate the topmost visible heading
        for (const heading of headings) {
          if (visible.has(heading.id)) {
            setActive(heading.id);
            return;
          }
        }
      },
      {
        rootMargin: "-10% 0px -80% 0px",
        threshold: 0,
      },
    );

    headings.forEach((h) => h.id && observer.observe(h));
  }

  // ── 5. WRAP TABLES IN SCROLL CONTAINER ─────────────────────────────────────
  // On mobile, tables overflow. Wrap them so they scroll horizontally
  // instead of breaking the layout.

  const isMobile = () => window.innerWidth <= 600;

  const wrapTables = () => {
    if (!isMobile()) return;
    document.querySelectorAll(".content-body table").forEach((table) => {
      if (table.parentElement.classList.contains("table-wrap")) return;
      const wrapper = document.createElement("div");
      wrapper.className = "table-wrap";
      table.before(wrapper);
      wrapper.appendChild(table);
    });
  };

  wrapTables();
})();
