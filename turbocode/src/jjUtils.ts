import { execFile } from "child_process";
import { promisify } from "util";

const execFileAsync = promisify(execFile);

export interface CommitInfo {
  commitId: string;
  changeId: string;
  bookmarks: string[];
  summary: string;
}

export async function execJj(args: string[], cwd: string): Promise<string> {
  const { stdout } = await execFileAsync("jj", args, {
    cwd,
    maxBuffer: 10 * 1024 * 1024,
  });
  return stdout;
}

export function parseLogOutput(output: string): CommitInfo[] {
  const commits: CommitInfo[] = [];
  const lines = output.split("\n");

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    if (!line.trim() || line.includes("(elided revisions)")) continue;

    const changeIdMatch =
      line.match(/\b([a-z0-9]{12})\b/) || line.match(/\b([a-z0-9]{8})\b/);
    const commitIdMatch =
      line.match(/\b([a-f0-9]{12})\b/i) || line.match(/\b([a-f0-9]{8})\b/i);
    if (!changeIdMatch || !commitIdMatch) continue;

    const changeId = changeIdMatch[1];
    const commitId = commitIdMatch[1];
    const middlePart = line
      .substring(changeIdMatch.index! + changeId.length, commitIdMatch.index!)
      .trim();
    const tokens = middlePart.split(/\s+/).filter((t) => t.length > 0);

    const bookmarks = tokens.filter(
      (t) =>
        !t.includes("@") &&
        !t.match(/^\d{4}-\d{2}-\d{2}$/) &&
        !t.match(/^\d{2}:\d{2}:\d{2}$/) &&
        t !== "git_head()"
    );

    let summary = "";
    if (i + 1 < lines.length) {
      const descMatch = lines[i + 1].match(/^[\s│├╭╰╯╮─◆~]*\s+(.+)$/);
      if (descMatch) summary = descMatch[1].trim();
    }

    commits.push({ commitId, changeId, bookmarks, summary });
  }

  return commits;
}

export function getLogCommand(n: number = 100): string[] {
  return ["log", "-n", String(n), "--color=never", "-T", "builtin_log_compact"];
}

export async function getBookmarks(cwd: string): Promise<string[]> {
  return (await execJj(["bookmark", "list", "--color=never"], cwd))
    .trim()
    .split("\n")
    .map((l) => l.match(/^\s*(\S+)/)?.[1])
    .filter(Boolean) as string[];
}
