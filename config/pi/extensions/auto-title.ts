import { completeSimple } from "@earendil-works/pi-ai";
import type {
  ExtensionAPI,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent";

const TITLE_CHARS = 72;
const MODEL = "openai-codex/gpt-5.5";
const SYSTEM_PROMPT = `Write one concise pi session title. Use the previous title and only the new transcript. Keep it for the same task; change it only for a material direction, goal, or outcome change. Plain text only, <= ${TITLE_CHARS} chars, no trailing punctuation.`;

export default function (pi: ExtensionAPI) {
  async function updateTitle(ctx: ExtensionContext, force = false) {
    const fail = (message: string) => {
      if (ctx.hasUI) ctx.ui.notify(`Title failed: ${message}`, "error");
    };

    try {
      const branch = ctx.sessionManager.getBranch();

      // Run after the first user message, then every fifth user message.
      const users = branch.filter(
        (entry) => entry.type === "message" && entry.message.role === "user",
      ).length;
      if (!force && users !== 1 && (users < 5 || users % 5 !== 0)) return;

      // Use the latest session name as the previous title and transcript boundary.
      let titleIndex = -1;
      let previousTitle = "";
      for (let index = branch.length - 1; index >= 0; index--) {
        const entry = branch[index];
        if (entry.type !== "session_info") continue;
        titleIndex = index;
        previousTitle = entry.name ?? "";
        break;
      }

      // Build compact user-message transcript since that boundary.
      const blocks: string[] = [];
      for (const entry of branch.slice(titleIndex + 1)) {
        if (entry.type !== "message" || entry.message.role !== "user") continue;
        const content = entry.message.content;
        let text = "";
        if (typeof content === "string") text = content;
        else {
          for (const part of content) {
            if (part.type === "text") text += `${part.text ?? ""}\n`;
            if (part.type === "image") text += "[image]\n";
          }
        }

        text = text
          .replace(/[ \t]+/g, " ")
          .replace(/\n{3,}/g, "\n\n")
          .trim();
        if (text.length > 1_500) text = `${text.slice(0, 1_500).trim()}…`;
        if (text) blocks.push(text);
      }

      let transcript = blocks.join("\n\n").trim();
      if (!transcript) return fail("no new user messages since the last title");
      if (transcript.length > 24_000) {
        transcript = `[Earlier recent transcript truncated]\n${transcript.slice(-24_000).trim()}`;
      }

      // Ask the title model.
      const model = ctx.modelRegistry.find("openai-codex", "gpt-5.5");
      if (!model) return fail(`model ${MODEL} not found`);
      const auth = await ctx.modelRegistry.getApiKeyAndHeaders(model);
      if (!auth.ok) return fail(`missing API key for ${MODEL}`);
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

      let title = "";
      for (const part of response.content)
        if (part.type === "text") title += `${part.text}\n`;
      title = title.replace(/\s+/gu, " ").trim().slice(0, TITLE_CHARS);
      title = title.replace(/[.!?。！？]+$/gu, "").trim();
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

  pi.on("agent_start", (_event, ctx) => {
    setTimeout(() => void updateTitle(ctx), 0);
  });
}
