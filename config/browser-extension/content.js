function findLink(start) {
  for (let node = start; node; node = node.parentElement) {
    if (node instanceof HTMLAnchorElement && node.href) return node;
  }
  return null;
}

document.addEventListener(
  "click",
  (event) => {
    if (event.button !== 0 || !event.altKey || event.ctrlKey || event.metaKey) return;

    const link = findLink(event.target);
    if (!link) return;

    event.preventDefault();
    event.stopImmediatePropagation();

    chrome.runtime.sendMessage({
      type: "open-alt-click-link",
      href: link.href,
    });
  },
  true,
);
