// Add inline "▶ Run" buttons to hica code blocks that embed the playground
(function () {
  var PLAYGROUND_URL = "https://cladam.github.io/hica/playground/";

  // Pages where input() is used — playground JS bundle doesn't support it
  var NO_PLAYGROUND_PAGES = ["level-36"];

  function addPlaygroundButtons() {
    var path = window.location.pathname;
    if (NO_PLAYGROUND_PAGES.some(function (p) { return path.indexOf(p) !== -1; })) return;

    var codeBlocks = document.querySelectorAll("code.language-hica");

    codeBlocks.forEach(function (codeEl) {
      var pre = codeEl.parentElement;
      if (!pre || pre.tagName !== "PRE") return;
      if (pre.querySelector(".playground-btn")) return;

      var code = codeEl.textContent;
      if (!/fun\s+main\s*\(/.test(code)) return;

      var encoded = btoa(unescape(encodeURIComponent(code)));

      // Create button
      var btn = document.createElement("button");
      btn.className = "playground-btn";
      btn.textContent = "▶ Run";
      btn.title = "Run this code in the embedded Hica Playground";

      // Create collapsible iframe container (hidden initially)
      var wrapper = document.createElement("div");
      wrapper.className = "playground-embed";
      wrapper.style.display = "none";

      var closeBtn = document.createElement("button");
      closeBtn.className = "playground-close";
      closeBtn.textContent = "✕ Close";
      closeBtn.title = "Close playground";

      var iframe = document.createElement("iframe");
      iframe.className = "playground-iframe";
      iframe.allow = "clipboard-write";
      iframe.loading = "lazy";

      wrapper.appendChild(closeBtn);
      wrapper.appendChild(iframe);

      // Insert wrapper after the pre block
      pre.parentNode.insertBefore(wrapper, pre.nextSibling);

      // Toggle playground on click
      btn.addEventListener("click", function () {
        if (wrapper.style.display === "none") {
          // Load the playground with this code
          iframe.src = PLAYGROUND_URL + "#code=" + encoded;
          wrapper.style.display = "block";
          btn.textContent = "▶ Running…";
          btn.classList.add("active");
          // Scroll into view
          wrapper.scrollIntoView({ behavior: "smooth", block: "nearest" });
        } else {
          wrapper.style.display = "none";
          iframe.src = "about:blank";
          btn.textContent = "▶ Run";
          btn.classList.remove("active");
        }
      });

      closeBtn.addEventListener("click", function () {
        wrapper.style.display = "none";
        iframe.src = "about:blank";
        btn.textContent = "▶ Run";
        btn.classList.remove("active");
      });

      pre.style.position = "relative";
      pre.appendChild(btn);
    });
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", addPlaygroundButtons);
  } else {
    addPlaygroundButtons();
  }

  var observer = new MutationObserver(function () {
    setTimeout(addPlaygroundButtons, 100);
  });
  var content = document.getElementById("content");
  if (content) {
    observer.observe(content, { childList: true, subtree: true });
  }
})();
