import { spawn } from "node:child_process";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

async function openTui(ctx: ExtensionContext, command: string): Promise<void> {
  await ctx.ui.custom<void>(async (tui, _theme, _keybindings, done) => {
    try {
      tui.stop();
      await new Promise<void>((resolve) => {
        const child = spawn(command, [], { cwd: ctx.cwd, stdio: "inherit" });
        child.on("error", () => resolve());
        child.on("close", () => resolve());
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
  pi.registerShortcut("alt+j", {
    description: "Open jjui",
    handler: (ctx) => openTui(ctx, "jjui"),
  });

  pi.registerShortcut("alt+e", {
    description: "Open nvim",
    handler: (ctx) => openTui(ctx, "nvim"),
  });
}
