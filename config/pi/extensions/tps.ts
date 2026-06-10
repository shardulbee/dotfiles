// Notify output tokens/second after each agent turn.
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  let startMs: number | null = null;

  pi.on("agent_start", () => {
    startMs = Date.now();
  });

  pi.on("agent_end", (event, ctx) => {
    if (!ctx.hasUI || startMs === null) return;
    const seconds = (Date.now() - startMs) / 1000;
    startMs = null;

    let output = 0;
    for (const m of event.messages)
      if (m.role === "assistant") output += m.usage.output || 0;

    if (output > 0 && seconds > 0)
      ctx.ui.notify(`TPS ${(output / seconds).toFixed(1)} tok/s`, "info");
  });
}
