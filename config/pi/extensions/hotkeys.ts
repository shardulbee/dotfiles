// Shortcuts that suspend pi's TUI, run a fullscreen program, and restore.
import { spawn } from "node:child_process";
import type {
  ExtensionAPI,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent";

const HOTKEYS = [
  ["alt+j", "jjui"],
  ["alt+e", "nvim"],
] as const;

async function openTui(ctx: ExtensionContext, command: string): Promise<void> {
  await ctx.ui.custom<void>(async (tui, _theme, _keybindings, done) => {
    try {
      tui.stop(); // hand the terminal to the child
      await new Promise<void>((resolve) => {
        spawn(command, [], { cwd: ctx.cwd, stdio: "inherit" })
          .on("error", () => resolve())
          .on("close", () => resolve());
      });
    } finally {
      tui.start();
      done();
      tui.requestRender(true);
    }
    return { render: () => [], invalidate: () => {} };
  });
}

export default function (pi: ExtensionAPI) {
  for (const [key, command] of HOTKEYS)
    pi.registerShortcut(key, {
      description: `Open ${command}`,
      handler: (ctx) => openTui(ctx, command),
    });
}
