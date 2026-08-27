chrome.runtime.onMessage.addListener((message, sender) => {
  if (!message || message.type !== "open-alt-click-link" || !message.href) return;

  chrome.tabs.create({
    url: message.href,
    active: false,
    index: sender.tab && sender.tab.index !== undefined ? sender.tab.index + 1 : undefined,
    openerTabId: sender.tab && sender.tab.id,
    windowId: sender.tab && sender.tab.windowId,
  });
});
