// Sync pi's theme to the terminal background color. Terminals don't push
// background changes, so we poll with an OSC 11 query and read the reply
// off stdin.
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

// OSC 11 reply, e.g. "\x1b]11;rgb:ffff/ffff/ffff" — top hex byte per component
const OSC11 =
  /\x1b\]11;rgb:([0-9a-f]{2})[0-9a-f]*\/([0-9a-f]{2})[0-9a-f]*\/([0-9a-f]{2})[0-9a-f]*/gi;

type ThemeMode = "dark" | "light";

function detectMode(buffer: string): ThemeMode | null {
  // .at(-1): a stale reply from a timed-out query may precede the current one
  const m = [...buffer.matchAll(OSC11)].at(-1);
  if (!m) return null;
  const [r, g, b] = m.slice(1).map((h) => parseInt(h, 16));
  // Rec. 709 luma
  return 0.2126 * r + 0.7152 * g + 0.0722 * b < 128 ? "dark" : "light";
}

export default function (pi: ExtensionAPI) {
  let pollTimer: ReturnType<typeof setInterval> | undefined;

  pi.on("session_start", (_event, ctx) => {
    clearInterval(pollTimer);
    if (!ctx.hasUI) return;

    let busy = false;
    let lastMode: ThemeMode | null = null;
    // Fallback in case the terminal never answers
    ctx.ui.setTheme("light");

    pollTimer = setInterval(() => {
      const { stdin, stdout } = process;
      // Query only while pi owns stdin in raw mode; otherwise the reply
      // would leak into someone else's input (shell, external editor)
      if (busy || !stdin.isTTY || !stdout.isTTY || !stdin.isRaw) return;
      busy = true;

      let buffer = "";
      const finish = (): void => {
        stdin.off("data", onData);
        clearTimeout(timeout);
        busy = false;
        const mode = detectMode(buffer);
        if (mode && mode !== lastMode) ctx.ui.setTheme((lastMode = mode));
      };
      const onData = (data: Buffer | string): void => {
        buffer += data.toString();
        if (detectMode(buffer)) finish();
      };
      // Some terminals ignore OSC 11 and never reply
      const timeout = setTimeout(finish, 250);
      stdin.on("data", onData);
      stdin.resume();
      stdout.write("\x1b]11;?\x07");
    }, 100);
  });

  pi.on("session_shutdown", () => clearInterval(pollTimer));
}
