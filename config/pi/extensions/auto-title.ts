import { completeSimple } from "@earendil-works/pi-ai";
import type { AssistantMessage, UserMessage } from "@earendil-works/pi-ai";
import type {
  ExtensionAPI,
  ExtensionContext,
  SessionEntry,
  SessionMessageEntry,
} from "@earendil-works/pi-coding-agent";

const PROVIDER = "google";
const MODEL_ID = "gemini-3.5-flash";
const THINKING = "low" as const;
const EARLY_TITLE_CHECKPOINTS = [1, 3, 5] as const;
const RECURRING_TITLE_INTERVAL = 5;
const STATE_TYPE = "auto-title-state";
const MAX_TITLE_CHARS = 72;
const MAX_MESSAGE_CHARS = 1_500;
const MAX_TRANSCRIPT_CHARS = 24_000;

const SYSTEM_PROMPT = [
  "You update concise titles for pi coding-agent sessions.",
  "Use the previous title plus only the new transcript since that title was chosen.",
  "Keep the title stable if the new transcript is a continuation of the same task.",
  "Change it when the session direction, goal, or outcome materially changed.",
  `Return only the title as plain text. The title must be <= ${MAX_TITLE_CHARS} characters, concrete, and have no trailing punctuation.`,
].join("\n");

type AutoTitleState = { title: string };
type TitlePoint = { title: string; index: number; userMessages: number };
type TextPart = { type: string; text?: string };

function isUserMessage(entry: SessionEntry): boolean {
  return entry.type === "message" && entry.message.role === "user";
}

function countUserMessages(entries: SessionEntry[]): number {
  return entries.filter(isUserMessage).length;
}

function latestTitleCheckpoint(userMessages: number): number {
  let checkpoint = 0;
  for (const earlyCheckpoint of EARLY_TITLE_CHECKPOINTS) {
    if (userMessages >= earlyCheckpoint) checkpoint = earlyCheckpoint;
  }

  const lastEarlyCheckpoint =
    EARLY_TITLE_CHECKPOINTS[EARLY_TITLE_CHECKPOINTS.length - 1] ?? 0;
  if (userMessages > lastEarlyCheckpoint) {
    checkpoint = Math.max(
      checkpoint,
      Math.floor(userMessages / RECURRING_TITLE_INTERVAL) *
        RECURRING_TITLE_INTERVAL,
    );
  }

  return checkpoint;
}

function latestState(entries: SessionEntry[]) {
  for (let i = entries.length - 1; i >= 0; i--) {
    const entry = entries[i];
    if (entry.type !== "custom" || entry.customType !== STATE_TYPE) continue;

    const title = (entry.data as AutoTitleState | undefined)?.title;
    if (typeof title === "string") return { index: i, title };
  }
}

function latestSessionInfo(entries: SessionEntry[]) {
  for (let i = entries.length - 1; i >= 0; i--) {
    const entry = entries[i];
    if (entry.type === "session_info")
      return { index: i, title: entry.name ?? "" };
  }
}

function getTitlePoint(entries: SessionEntry[]): TitlePoint {
  const state = latestState(entries);
  const info = latestSessionInfo(entries);
  const point = info && (!state || info.index > state.index) ? info : state;

  return point
    ? {
        ...point,
        userMessages: countUserMessages(entries.slice(0, point.index + 1)),
      }
    : { title: "", index: -1, userMessages: 0 };
}

function trimBlock(text: string, maxChars = MAX_MESSAGE_CHARS): string {
  const compact = text
    .replace(/[ \t]+/g, " ")
    .replace(/\n{3,}/g, "\n\n")
    .trim();
  return compact.length <= maxChars
    ? compact
    : `${compact.slice(0, maxChars).trim()}…`;
}

function textFromContent(
  content: string | readonly TextPart[] | undefined,
): string {
  if (typeof content === "string") return content;
  return (content ?? [])
    .map((part) =>
      part.type === "text"
        ? (part.text ?? "")
        : part.type === "image"
          ? "[image]"
          : "",
    )
    .filter(Boolean)
    .join("\n")
    .trim();
}

function messageBlock(entry: SessionMessageEntry): string | undefined {
  const { message } = entry;
  if (message.role !== "user" && message.role !== "assistant") return undefined;

  const label = message.role === "user" ? "User" : "Assistant";
  const text = trimBlock(textFromContent(message.content));
  return text ? `[${label}]\n${text}` : undefined;
}

function recentTranscript(entries: SessionEntry[]): string {
  const blocks: string[] = [];
  for (const entry of entries) {
    if (entry.type === "message") {
      const block = messageBlock(entry);
      if (block) blocks.push(block);
    }
  }

  const transcript = blocks.join("\n\n").trim();
  return transcript.length <= MAX_TRANSCRIPT_CHARS
    ? transcript
    : `[Earlier recent transcript truncated]\n${transcript.slice(-MAX_TRANSCRIPT_CHARS).trim()}`;
}

function buildUserPrompt(
  previousTitle: string,
  transcript: string,
): UserMessage {
  return {
    role: "user",
    content: [
      `Previous title: ${previousTitle || "(none)"}`,
      "",
      "New transcript since that title:",
      transcript,
      "",
      "Update the title for the whole session. Return only the title as plain text.",
    ].join("\n"),
    timestamp: Date.now(),
  };
}

function assistantText(message: AssistantMessage): string {
  return message.content
    .filter((part) => part.type === "text")
    .map((part) => part.text)
    .join("\n")
    .trim();
}

function cleanTitle(raw: string): string {
  const title = raw
    .trim()
    .replace(/[.!?。！？]+$/gu, "")
    .trim();
  return title &&
    title.length <= MAX_TITLE_CHARS &&
    !/[\r\n`{}[\]]/u.test(title)
    ? title
    : "";
}

async function generateTitle(
  ctx: ExtensionContext,
  previousTitle: string,
  transcript: string,
): Promise<string> {
  const model = ctx.modelRegistry.find(PROVIDER, MODEL_ID);
  if (!model) return "";

  const auth = await ctx.modelRegistry.getApiKeyAndHeaders(model);
  if (!auth.ok) return "";

  const response = await completeSimple(
    model,
    {
      systemPrompt: SYSTEM_PROMPT,
      messages: [buildUserPrompt(previousTitle, transcript)],
    },
    {
      apiKey: auth.apiKey,
      headers: auth.headers,
      reasoning: THINKING,
      maxTokens: 160,
    },
  );

  return response.stopReason === "error" || response.stopReason === "aborted"
    ? ""
    : cleanTitle(assistantText(response));
}

export default function (pi: ExtensionAPI) {
  async function maybeUpdateTitle(ctx: ExtensionContext): Promise<void> {
    const branch = ctx.sessionManager.getBranch();
    const point = getTitlePoint(branch);
    const totalUserMessages = countUserMessages(branch);
    const checkpoint = latestTitleCheckpoint(totalUserMessages);
    if (checkpoint <= point.userMessages) return;

    const transcript = recentTranscript(branch.slice(point.index + 1));
    if (!transcript) return;

    const leafId = ctx.sessionManager.getLeafId();
    const nextTitle = await generateTitle(ctx, point.title, transcript);
    if (!nextTitle || ctx.sessionManager.getLeafId() !== leafId) return;

    if (nextTitle !== (ctx.sessionManager.getSessionName() ?? "")) {
      pi.setSessionName(nextTitle);
    }
    pi.appendEntry<AutoTitleState>(STATE_TYPE, { title: nextTitle });
  }

  pi.on("session_start", (_event, ctx) => {});

  pi.on("agent_end", (_event, ctx) => {
    void maybeUpdateTitle(ctx).catch(() => {});
  });

  pi.on("session_shutdown", (_event, ctx) => {
    if (ctx.hasUI) ctx.ui.setTitle("");
  });
}
