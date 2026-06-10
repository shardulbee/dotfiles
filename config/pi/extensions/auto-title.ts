// Keep the session title current by asking a small model to retitle from the
// user transcript — after the first user message, then every fifth.
import { completeSimple } from "@earendil-works/pi-ai";
import type {
  ExtensionAPI,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent";

const PROVIDER = "openai-codex";
const MODEL = "gpt-5.5";
const TITLE_CHARS = 72;
const SYSTEM_PROMPT = `Write one concise pi session title. Use the previous title and only the new transcript. Keep it for the same task; change it only for a material direction, goal, or outcome change. Plain text only, <= ${TITLE_CHARS} chars, no trailing punctuation.`;

export default function (pi: ExtensionAPI) {
  async function updateTitle(ctx: ExtensionContext, force = false) {
    const fail = (message: string) => {
      if (ctx.hasUI) ctx.ui.notify(`Title failed: ${message}`, "error");
    };

    try {
      const branch = ctx.sessionManager.getBranch();

      const users = branch.filter(
        (e) => e.type === "message" && e.message.role === "user",
      ).length;
      if (!force && users !== 1 && (users < 5 || users % 5 !== 0)) return;

      // The latest session_info holds the previous title and marks where the
      // "new" transcript begins.
      let infoIdx = branch.length - 1;
      while (infoIdx >= 0 && branch[infoIdx].type !== "session_info") infoIdx--;
      const info = branch[infoIdx];
      const previousTitle = (info?.type === "session_info" && info.name) || "";

      // Compact transcript of user messages since that boundary.
      const blocks: string[] = [];
      for (const entry of branch.slice(infoIdx + 1)) {
        if (entry.type !== "message" || entry.message.role !== "user") continue;
        const content = entry.message.content;
        let text =
          typeof content === "string"
            ? content
            : content
                .map((p) =>
                  p.type === "text"
                    ? (p.text ?? "")
                    : p.type === "image"
                      ? "[image]"
                      : "",
                )
                .join("\n");
        text = text
          .replace(/[ \t]+/g, " ")
          .replace(/\n{3,}/g, "\n\n")
          .trim();
        if (text.length > 1_500) text = `${text.slice(0, 1_500).trim()}…`;
        if (text) blocks.push(text);
      }

      let transcript = blocks.join("\n\n").trim();
      if (!transcript) return fail("no new user messages since the last title");
      if (transcript.length > 24_000)
        transcript = `[Earlier recent transcript truncated]\n${transcript.slice(-24_000).trim()}`;

      const model = ctx.modelRegistry.find(PROVIDER, MODEL);
      if (!model) return fail(`model ${PROVIDER}/${MODEL} not found`);
      const auth = await ctx.modelRegistry.getApiKeyAndHeaders(model);
      if (!auth.ok) return fail(`missing API key for ${PROVIDER}/${MODEL}`);

      const prompt = `Previous title: ${previousTitle || "(none)"}\n\nNew transcript since that title:\n${transcript}\n\nUpdate the title. Return only the title.`;
      const response = await completeSimple(
        model,
        {
          systemPrompt: SYSTEM_PROMPT,
          messages: [{ role: "user", content: prompt, timestamp: Date.now() }],
        },
        {
          apiKey: auth.apiKey,
          headers: auth.headers,
          reasoning: "minimal",
          maxTokens: 160,
        },
      );
      if (response.stopReason === "aborted") return fail("title model aborted");
      if (response.stopReason === "error")
        return fail(response.errorMessage ?? "title model errored");

      const title = response.content
        .map((p) => (p.type === "text" ? (p.text ?? "") : ""))
        .join(" ")
        .replace(/\s+/gu, " ")
        .trim()
        .slice(0, TITLE_CHARS)
        .replace(/[.!?。！？]+$/gu, "")
        .trim();
      if (!title) return fail("title model returned an empty title");
      pi.setSessionName(title);
    } catch (error) {
      fail(error instanceof Error ? error.message : String(error));
    }
  }

  pi.registerCommand("title", {
    description: "Generate a session title now",
    handler: async (_args, ctx) => updateTitle(ctx, true),
  });

  // Deferred so titling never sits on the agent_start path
  pi.on("agent_start", (_event, ctx) => {
    setTimeout(() => void updateTitle(ctx), 0);
  });
}
