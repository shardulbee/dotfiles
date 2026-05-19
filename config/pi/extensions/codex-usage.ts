import type { ExtensionAPI, ExtensionContext, Theme } from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";

const PROVIDER = "openai-codex";
const ENDPOINT = "https://chatgpt.com/backend-api/wham/usage";
const WIDGET_KEY = "codex-usage";
const TTL_MS = 60_000;
const PRIMARY_LABEL = "2d";
const SECONDARY_LABEL = "1w";

type CodexUsage = {
  rate_limit: {
    primary_window: { used_percent: number };
    secondary_window: { used_percent: number };
  };
};

let usage: CodexUsage | undefined;
let fetchedAtMs = 0;

async function fetchUsage(ctx: ExtensionContext): Promise<CodexUsage | undefined> {
  if (ctx.signal?.aborted) return;

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
  return (await res.json()) as CodexUsage;
}

async function refreshUsage(ctx: ExtensionContext): Promise<void> {
  if (usage && Date.now() - fetchedAtMs < TTL_MS) return;

  try {
    const next = await fetchUsage(ctx);
    if (!next) return;

    usage = next;
    fetchedAtMs = Date.now();
  } catch {
    return;
  }
}

function usageLine(theme: Theme, width: number): string[] {
  if (!usage) return [];

  const primary = usage.rate_limit.primary_window;
  const secondary = usage.rate_limit.secondary_window;
  const text = theme.fg(
    "dim",
    `usage: ${Math.round(primary.used_percent)}% (${PRIMARY_LABEL})/${Math.round(secondary.used_percent)}% (${SECONDARY_LABEL})`,
  );

  const padding = " ".repeat(Math.max(0, width - visibleWidth(text)));
  return [truncateToWidth(padding + text, width, "")];
}

function showWidget(ctx: ExtensionContext): void {
  if (ctx.model?.provider !== PROVIDER) {
    ctx.ui.setWidget(WIDGET_KEY, undefined);
    return;
  }

  ctx.ui.setWidget(
    WIDGET_KEY,
    (_tui, theme) => ({
      invalidate() {},
      render: (width: number) => usageLine(theme, width),
    }),
    { placement: "aboveEditor" },
  );
}

async function update(ctx: ExtensionContext): Promise<void> {
  if (ctx.model?.provider !== PROVIDER) {
    showWidget(ctx);
    return;
  }

  await refreshUsage(ctx);
  showWidget(ctx);
}

function updateLater(ctx: ExtensionContext): void {
  void update(ctx).catch(() => undefined);
}

export default function (pi: ExtensionAPI) {
  pi.on("session_start", (_event, ctx) => updateLater(ctx));
  pi.on("model_select", (_event, ctx) => updateLater(ctx));
  pi.on("agent_end", (_event, ctx) => updateLater(ctx));
}
