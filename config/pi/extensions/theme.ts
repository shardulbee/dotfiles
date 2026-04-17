import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

type ThemeMode = "dark" | "light";
type Rgb = { r: number; g: number; b: number };

const OSC11_REPLY_PATTERN = /\x1b\]11;rgb:[0-9a-fA-F/]+(?:\x07|\x1b\\)/g;
const RGB_PATTERN = /rgb:([0-9a-fA-F]{2,4})\/([0-9a-fA-F]{2,4})\/([0-9a-fA-F]{2,4})/;
const POLL_INTERVAL_MS = 100;
const QUERY_TIMEOUT_MS = 250;
const MAX_BUFFER_SIZE = 1024;

function extractLatestOsc11Reply(buffer: string): string | null {
	const replies = buffer.match(OSC11_REPLY_PATTERN);
	if (!replies || replies.length === 0) {
		return null;
	}
	return replies[replies.length - 1];
}

function parseHexByte(component: string): number {
	return Number.parseInt(component.slice(0, 2), 16) || 0;
}

function parseOsc11Rgb(raw: string): Rgb | null {
	const match = raw.match(RGB_PATTERN);
	if (!match) {
		return null;
	}
	return {
		r: parseHexByte(match[1]),
		g: parseHexByte(match[2]),
		b: parseHexByte(match[3]),
	};
}

function modeFromRgb({ r, g, b }: Rgb): ThemeMode {
	return 0.2126 * r + 0.7152 * g + 0.0722 * b < 128 ? "dark" : "light";
}

export default function (pi: ExtensionAPI) {
	let pollTimer: ReturnType<typeof setInterval> | null = null;
	let inFlight = false;
	let lastMode: ThemeMode | null = null;

	pi.on("session_start", (_event, ctx) => {
		if (pollTimer) {
			clearInterval(pollTimer);
			pollTimer = null;
		}
		inFlight = false;
		lastMode = null;
		ctx.ui.setTheme("dark");

		pollTimer = setInterval(() => {
			if (inFlight || !process.stdin.isTTY || !process.stdout.isTTY) {
				return;
			}
			inFlight = true;

			let buffer = "";
			function finish(raw: string) {
				process.stdin.off("data", onData);
				clearTimeout(timeout);

				const rgb = parseOsc11Rgb(raw);
				if (rgb) {
					const mode = modeFromRgb(rgb);
					if (mode !== lastMode) {
						lastMode = mode;
						ctx.ui.setTheme(mode);
					}
				}

				inFlight = false;
			}

			function onData(data: Buffer | string) {
				buffer += typeof data === "string" ? data : data.toString("utf8");
				const reply = extractLatestOsc11Reply(buffer);
				if (reply) {
					finish(reply);
					return;
				}
				if (buffer.length > MAX_BUFFER_SIZE) {
					buffer = buffer.slice(-MAX_BUFFER_SIZE);
				}
			}

			const timeout = setTimeout(() => finish(""), QUERY_TIMEOUT_MS);
			process.stdin.on("data", onData);
			process.stdin.resume();
			process.stdout.write("\x1b]11;?\x07");
		}, POLL_INTERVAL_MS);
	});

	pi.on("session_shutdown", () => {
		if (pollTimer) {
			clearInterval(pollTimer);
			pollTimer = null;
		}
	});
}
