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

type RateLimitWindow = {
  used_percent: number;
  reset_after_seconds?: number;
};

type CodexUsage = {
  plan_type?: string;
  rate_limit: {
    allowed?: boolean;
    limit_reached?: boolean;
    primary_window: RateLimitWindow | null; // 2 days
    secondary_window: RateLimitWindow | null; // 1 week
  } | null;
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

function formatReset(seconds: number | undefined): string {
  if (!seconds) return "";
  const minutes = Math.ceil(seconds / 60);
  if (minutes < 60) return `, reset ${minutes}m`;
  const hours = Math.ceil(minutes / 60);
  if (hours < 48) return `, reset ${hours}h`;
  return `, reset ${Math.ceil(hours / 24)}d`;
}

function usageLine(theme: Theme, width: number): string[] {
  const rate_limit = usage?.rate_limit;
  if (!rate_limit?.primary_window) return [];

  const plan = usage?.plan_type ? `${usage.plan_type} ` : "";
  const primary = rate_limit.primary_window;
  const parts = [`${Math.round(primary.used_percent)}% 2d`];
  if (rate_limit.secondary_window) {
    parts.push(`${Math.round(rate_limit.secondary_window.used_percent)}% 1w`);
  }

  const limited = rate_limit.allowed === false || rate_limit.limit_reached === true;
  const label = limited ? "LIMIT" : "usage";
  const reset = limited ? formatReset(primary.reset_after_seconds) : "";
  const color = limited ? "error" : "dim";
  const text = theme.fg(color, `${label}: ${plan}${parts.join("/")}${reset}`);

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
