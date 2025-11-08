import * as vscode from "vscode";
import {
  execJj,
  parseLogOutput,
  getLogCommand,
  CommitInfo,
} from "./jjUtils";
import { stripAnsi, parseAnsiLine, DecorationRange } from "./ansi";

const LOG_URI = vscode.Uri.parse("jj://log/log");

export class JjLogProvider implements vscode.TextDocumentContentProvider {
  private _onDidChange = new vscode.EventEmitter<vscode.Uri>();
  private expandedCommits = new Set<string>();
  private lineToCommit = new Map<number, CommitInfo>();
  private commitToLine = new Map<string, number>();
  private lastSelectedCommitId: string | undefined;
  private lineDecorations = new Map<number, DecorationRange[]>();
  private activeDecorations: vscode.TextEditorDecorationType[] = [];

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

      // Strip ANSI for parsing to avoid breaking commit detection
      const strippedOutput = stripAnsi(rawOutput);
      const commits = parseLogOutput(strippedOutput);
      if (commits.length === 0)
        return "No commits found.\n\n" + strippedOutput.substring(0, 500);

      this.lineToCommit.clear();
      this.commitToLine.clear();
      const linesWithAnsi: string[] = [];
      const originalLinesColored = rawOutput.split("\n");
      const originalLinesStripped = strippedOutput.split("\n");

      for (const commit of commits) {
        let commitLineStripped = "";
        let commitLineColored = "";
        let commitLineIndex = -1;
        for (let j = 0; j < originalLinesStripped.length; j++) {
          if (
            originalLinesStripped[j].includes(commit.changeId) &&
            originalLinesStripped[j].includes(commit.commitId)
          ) {
            commitLineStripped = originalLinesStripped[j];
            commitLineColored = originalLinesColored[j];
            commitLineIndex = j;
            break;
          }
        }
        if (!commitLineStripped) continue;

        const currentLine = linesWithAnsi.length;
        linesWithAnsi.push(commitLineColored);
        this.lineToCommit.set(currentLine, commit);
        this.commitToLine.set(commit.commitId, currentLine);

        if (commit.summary) {
          let descLineColored = "";
          if (
            commitLineIndex + 1 < originalLinesColored.length &&
            originalLinesStripped[commitLineIndex + 1].match(/^[\s│├╭╰╯╮─◆~]*\s+/)
          ) {
            descLineColored = originalLinesColored[commitLineIndex + 1];
          }
          if (!descLineColored) {
            const indentMatch = commitLineStripped.match(/^(\s*[│├╭╰╯╮─◆@~ ]*)/);
            const indent = indentMatch?.[1] || "  ";
            // Try to preserve ANSI styling from commit line for the indent
            const commitLineAnsiMatch = commitLineColored.match(/^(\u001b\[[0-9;]*m)*/);
            const ansiPrefix = commitLineAnsiMatch?.[0] || "";
            descLineColored = ansiPrefix + indent + commit.summary;
          }
          linesWithAnsi.push(descLineColored);
          this.lineToCommit.set(currentLine + 1, commit);
        }

        if (this.expandedCommits.has(commit.commitId)) {
          const files = await execJj(
            [
              "show",
              "-r",
              commit.commitId,
              "--summary",
              "--color=always",
              "-T",
              "",
            ],
            workspaceRoot
          );
          const fileLines = files
            .split("\n")
            .filter((line: string) => line && !line.startsWith("..."));
          linesWithAnsi.push(...fileLines, "");
        }
      }

      // Parse ANSI line by line
      this.lineDecorations.clear();
      const cleanLines: string[] = [];
      for (let i = 0; i < linesWithAnsi.length; i++) {
        const parsed = parseAnsiLine(linesWithAnsi[i]);
        cleanLines.push(parsed.text);
        if (parsed.decorations.length > 0) {
          this.lineDecorations.set(i, parsed.decorations);
        }
      }

      return cleanLines.join("\n");
    } catch (error: any) {
      return `Error loading JJ log:\n\n${
        error.message || String(error)
      }\n\nPress 'r' to refresh.`;
    }
  }

  applyDecorations(editor: vscode.TextEditor): void {
    if (editor.document.uri.scheme !== "jj") return;
    
    for (const dec of this.activeDecorations) dec.dispose();
    this.activeDecorations = [];
    
    const styleToRanges = new Map<string, vscode.Range[]>();
    for (const [lineNum, decorations] of this.lineDecorations) {
      for (const dec of decorations) {
        const key = `${dec.fg || ''}:${dec.bright ? 'b' : ''}:${dec.bold ? 'B' : ''}`;
        if (!styleToRanges.has(key)) styleToRanges.set(key, []);
        styleToRanges.get(key)!.push(new vscode.Range(lineNum, dec.start, lineNum, dec.end));
      }
    }
    
    for (const [key, ranges] of styleToRanges) {
      const [fg, bright, bold] = key.split(':');
      const opts: vscode.DecorationRenderOptions = {};
      if (fg) {
        const name = bright ? `terminal.ansiBright${fg[0].toUpperCase() + fg.slice(1)}` : `terminal.ansi${fg[0].toUpperCase() + fg.slice(1)}`;
        opts.color = new vscode.ThemeColor(name);
      }
      if (bold) opts.fontWeight = 'bold';
      const type = vscode.window.createTextEditorDecorationType(opts);
      editor.setDecorations(type, ranges);
      this.activeDecorations.push(type);
    }
  }

  dispose(): void {
    for (const dec of this.activeDecorations) dec.dispose();
    this._onDidChange.dispose();
  }
}
