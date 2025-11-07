import * as vscode from "vscode";
import {
  execJj,
  parseLogOutput,
  getLogCommand,
  CommitInfo,
} from "./jjUtils";

const LOG_URI = vscode.Uri.parse("jj://log/log");

export class JjLogProvider implements vscode.TextDocumentContentProvider {
  private _onDidChange = new vscode.EventEmitter<vscode.Uri>();
  private expandedCommits = new Set<string>();
  private lineToCommit = new Map<number, CommitInfo>();
  private commitToLine = new Map<string, number>();
  private lastSelectedCommitId: string | undefined;

  readonly onDidChange = this._onDidChange.event;

  refresh(): void {
    const editor = vscode.window.activeTextEditor;
    if (editor?.document.uri.scheme === "jj") {
      const commit = this.getCommitAtLine(editor.selection.active.line);
      if (commit) this.lastSelectedCommitId = commit.commitId;
    }
    this._onDidChange.fire(LOG_URI);
  }

  async restoreCursorPosition(): Promise<void> {
    const line = this.lastSelectedCommitId
      ? this.commitToLine.get(this.lastSelectedCommitId)
      : undefined;
    if (line !== undefined) {
      const editor = vscode.window.activeTextEditor;
      if (editor?.document.uri.scheme === "jj") {
        const pos = new vscode.Position(line, 0);
        editor.selection = new vscode.Selection(pos, pos);
        editor.revealRange(
          new vscode.Range(pos, pos),
          vscode.TextEditorRevealType.InCenter
        );
      }
    }
  }

  isExpanded(commitId: string): boolean {
    return this.expandedCommits.has(commitId);
  }

  toggleExpand(commitId: string): void {
    if (this.expandedCommits.has(commitId)) {
      this.expandedCommits.delete(commitId);
    } else {
      this.expandedCommits.add(commitId);
    }
    this.refresh();
  }

  getCommitAtLine(line: number): CommitInfo | undefined {
    if (this.lineToCommit.has(line)) return this.lineToCommit.get(line);
    let nearestLine = -1;
    for (const [commitLine] of this.lineToCommit) {
      if (commitLine <= line && commitLine > nearestLine)
        nearestLine = commitLine;
    }
    return nearestLine >= 0 ? this.lineToCommit.get(nearestLine) : undefined;
  }

  getCommitById(commitId: string): CommitInfo | undefined {
    const line = this.commitToLine.get(commitId);
    return line !== undefined ? this.lineToCommit.get(line) : undefined;
  }

  getMappedLines(): number[] {
    return Array.from(this.lineToCommit.keys()).sort((a, b) => a - b);
  }

  async provideTextDocumentContent(uri: vscode.Uri): Promise<string> {
    try {
      const workspaceRoot = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
      if (!workspaceRoot) return "Error: No workspace folder open.";

      const rawOutput = await execJj(getLogCommand(100), workspaceRoot);
      if (!rawOutput?.trim())
        return "Error: JJ log command returned empty output.";

      const commits = parseLogOutput(rawOutput);
      if (commits.length === 0)
        return "No commits found.\n\n" + rawOutput.substring(0, 500);

      this.lineToCommit.clear();
      this.commitToLine.clear();
      const lines: string[] = [];
      let currentLine = 0;
      const originalLines = rawOutput.split("\n");

      for (const commit of commits) {
        let commitLine = "";
        let commitLineIndex = -1;
        for (let j = 0; j < originalLines.length; j++) {
          if (
            originalLines[j].includes(commit.changeId) &&
            originalLines[j].includes(commit.commitId)
          ) {
            commitLine = originalLines[j];
            commitLineIndex = j;
            break;
          }
        }
        if (!commitLine) continue;

        lines.push(commitLine);
        this.lineToCommit.set(currentLine, commit);
        this.commitToLine.set(commit.commitId, currentLine);
        currentLine++;

        if (commit.summary) {
          let descLine = "";
          if (
            commitLineIndex + 1 < originalLines.length &&
            originalLines[commitLineIndex + 1].match(/^[\s│├╭╰╯╮─◆~]*\s+/)
          ) {
            descLine = originalLines[commitLineIndex + 1];
          }
          if (!descLine) {
            const indent =
              commitLine.match(/^(\s*[│├╭╰╯╮─◆@~ ]*)/)?.[1] || "  ";
            descLine = indent + commit.summary;
          }
          lines.push(descLine);
          this.lineToCommit.set(currentLine, commit);
          currentLine++;
        }

        if (this.expandedCommits.has(commit.commitId)) {
          const files = await execJj(
            [
              "show",
              "-r",
              commit.commitId,
              "--summary",
              "--color=never",
              "-T",
              "",
            ],
            workspaceRoot
          );
          lines.push(
            ...files
              .split("\n")
              .filter((line: string) => line && !line.startsWith("...")),
            ""
          );
        }
      }

      return lines.join("\n");
    } catch (error: any) {
      return `Error loading JJ log:\n\n${
        error.message || String(error)
      }\n\nPress 'r' to refresh.`;
    }
  }

  dispose(): void {
    this._onDidChange.dispose();
  }
}
