chrome.commands.onCommand.addListener((command) => {
  if (command === "toggle-pin") {
    chrome.tabs.query({active: true, currentWindow: true}, (tabs) => {
      const tab = tabs[0];
      chrome.tabs.update(tab.id, {pinned: !tab.pinned});
    });
  }
});
