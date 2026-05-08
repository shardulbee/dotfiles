import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";

const COMMAND = "fast";
const STATUS_KEY = "fast";
const SERVICE_TIER = "priority";
const SUPPORTED_MODELS = new Set([
	"openai/gpt-5.4",
	"openai/gpt-5.5",
	"openai-codex/gpt-5.4",
	"openai-codex/gpt-5.5",
]);

type RecordPayload = Record<string, unknown>;

function isRecord(value: unknown): value is RecordPayload {
	return typeof value === "object" && value !== null && !Array.isArray(value);
}

function modelKey(ctx: ExtensionContext): string {
	return ctx.model ? `${ctx.model.provider}/${ctx.model.id}` : "none";
}

function supportsFast(ctx: ExtensionContext): boolean {
	return SUPPORTED_MODELS.has(modelKey(ctx));
}

export default function (pi: ExtensionAPI) {
	let requested = false;

	function isActive(ctx: ExtensionContext): boolean {
		return requested && supportsFast(ctx);
	}

	function updateStatus(ctx: ExtensionContext) {
		ctx.ui.setStatus(
			STATUS_KEY,
			isActive(ctx) ? ctx.ui.theme.fg("accent", "fast") : undefined,
		);
	}

	function notifyState(ctx: ExtensionContext) {
		if (!requested) {
			ctx.ui.notify("Fast mode off.", "info");
			return;
		}

		if (supportsFast(ctx)) {
			ctx.ui.notify(`Fast mode on for ${modelKey(ctx)}.`, "info");
			return;
		}

		ctx.ui.notify(`Fast mode requested, but ${modelKey(ctx)} is unsupported.`, "warning");
	}

	pi.registerCommand(COMMAND, {
		description: "Toggle OpenAI fast mode for this session",
		handler: async (args, ctx) => {
			if (args.trim()) {
				ctx.ui.notify("Usage: /fast", "error");
				return;
			}

			requested = !requested;
			updateStatus(ctx);
			notifyState(ctx);
		},
	});

	pi.on("session_start", (_event, ctx) => {
		requested = false;
		updateStatus(ctx);
	});

	pi.on("model_select", (_event, ctx) => {
		updateStatus(ctx);
		if (requested && !supportsFast(ctx)) {
			ctx.ui.notify(`Fast mode inactive for unsupported model ${modelKey(ctx)}.`, "warning");
		}
	});

	pi.on("before_provider_request", (event, ctx) => {
		if (!isActive(ctx) || !isRecord(event.payload)) return;
		return { ...event.payload, service_tier: SERVICE_TIER };
	});
}
