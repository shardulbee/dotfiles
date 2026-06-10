// Show Codex rate-limit usage above the editor when a codex model is active.
import type {
  ExtensionAPI,
  ExtensionContext,
  Theme,
} from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";

const PROVIDER = "openai-codex";
const ENDPOINT = "https://chatgpt.com/backend-api/wham/usage";
const TTL_MS = 60_000;

type CodexUsage = {
  rate_limit: {
    primary_window: { used_percent: number }; // 2 days
    secondary_window: { used_percent: number }; // 1 week
  };
};

let usage: CodexUsage | undefined;
let fetchedAtMs = 0;

async function refresh(ctx: ExtensionContext): Promise<void> {
  if (usage && Date.now() - fetchedAtMs < TTL_MS) return;

  const token = await ctx.modelRegistry.getApiKeyForProvider(PROVIDER);
  if (!token) return;

  const res = await fetch(ENDPOINT, {
    headers: {
      Authorization: `Bearer ${token}`,
      "OAI-Language": "en-US",
      Referer: "https://chatgpt.com/codex/cloud/settings/analytics",
    },
    signal: ctx.signal,
  });
  if (!res.ok) return;

  usage = (await res.json()) as CodexUsage;
  fetchedAtMs = Date.now();
}

function usageLine(theme: Theme, width: number): string[] {
  if (!usage) return [];
  const { primary_window, secondary_window } = usage.rate_limit;
  const text = theme.fg(
    "dim",
    `usage: ${Math.round(primary_window.used_percent)}% (2d)/${Math.round(secondary_window.used_percent)}% (1w)`,
  );
  // right-aligned
  const padding = " ".repeat(Math.max(0, width - visibleWidth(text)));
  return [truncateToWidth(padding + text, width, "")];
}

async function update(ctx: ExtensionContext): Promise<void> {
  if (ctx.model?.provider !== PROVIDER) {
    ctx.ui.setWidget("codex-usage", undefined);
    return;
  }
  await refresh(ctx).catch(() => {});
  ctx.ui.setWidget(
    "codex-usage",
    (_tui, theme) => ({
      invalidate() {},
      render: (width: number) => usageLine(theme, width),
    }),
    { placement: "aboveEditor" },
  );
}

export default function (pi: ExtensionAPI) {
  const kick = (_event: unknown, ctx: ExtensionContext): void =>
    void update(ctx).catch(() => {});
  pi.on("session_start", kick);
  pi.on("model_select", kick);
  pi.on("agent_end", kick);
}
