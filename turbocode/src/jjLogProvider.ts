import * as vscode from 'vscode';
import { execJj, parseLogOutput, getLogCommand, getCommitDetails, CommitInfo, ExpandedCommitInfo } from './jjUtils';

const LOG_URI = vscode.Uri.parse('jj://log');

export class JjLogProvider implements vscode.TextDocumentContentProvider {
    private _onDidChange = new vscode.EventEmitter<vscode.Uri>();
    private expandedCommits = new Set<string>(); // commitId -> expanded
    private lineToCommit = new Map<number, CommitInfo>(); // line number -> commit info
    private commitToLine = new Map<string, number>(); // commitId -> line number
    private currentContent = '';
    private lastSelectedCommitId: string | undefined; // For preserving cursor position

    readonly onDidChange = this._onDidChange.event;

    /**
     * Refresh the log view
     */
    refresh(): void {
        // Preserve expanded state and selected commit
        const editor = vscode.window.activeTextEditor;
        if (editor && editor.document.uri.scheme === 'jj') {
            const commit = this.getCommitAtLine(editor.selection.active.line);
            if (commit) {
                this.lastSelectedCommitId = commit.commitId;
            }
        }
        this._onDidChange.fire(LOG_URI);
    }

    /**
     * Restore cursor position after refresh
     */
    async restoreCursorPosition(): Promise<void> {
        if (!this.lastSelectedCommitId) {
            return;
        }

        const line = this.commitToLine.get(this.lastSelectedCommitId);
        if (line !== undefined) {
            const editor = vscode.window.activeTextEditor;
            if (editor && editor.document.uri.scheme === 'jj') {
                const position = new vscode.Position(line, 0);
                editor.selection = new vscode.Selection(position, position);
                editor.revealRange(new vscode.Range(position, position), vscode.TextEditorRevealType.InCenter);
            }
        }
    }

    /**
     * Toggle expansion of a commit
     */
    toggleExpand(commitId: string): void {
        if (this.expandedCommits.has(commitId)) {
            this.expandedCommits.delete(commitId);
        } else {
            this.expandedCommits.add(commitId);
        }
        this.refresh();
    }

    /**
     * Get commit info for a line number
     * If the line is within expanded details, find the parent commit
     */
    getCommitAtLine(line: number): CommitInfo | undefined {
        // Direct match
        if (this.lineToCommit.has(line)) {
            return this.lineToCommit.get(line);
        }

        // Find the nearest commit line above this line
        let nearestLine = -1;
        for (const [commitLine] of this.lineToCommit) {
            if (commitLine <= line && commitLine > nearestLine) {
                nearestLine = commitLine;
            }
        }

        if (nearestLine >= 0) {
            return this.lineToCommit.get(nearestLine);
        }

        return undefined;
    }

    /**
     * Get commit info by commit ID
     */
    getCommitById(commitId: string): CommitInfo | undefined {
        const line = this.commitToLine.get(commitId);
        if (line !== undefined) {
            return this.lineToCommit.get(line);
        }
        return undefined;
    }

    /**
     * Provide content for the jj://log document
     */
    async provideTextDocumentContent(uri: vscode.Uri): Promise<string> {
        try {
            const logArgs = getLogCommand(100);
            const output = await execJj(logArgs);
            const commits = parseLogOutput(output);
            
            // Build line mappings
            this.lineToCommit.clear();
            this.commitToLine.clear();
            
            const lines: string[] = [];
            let currentLine = 0;

            // Split output into lines to find the original graph
            const originalLines = output.split('\n');

            for (const commit of commits) {
                // Find the original line containing this commit
                let commitLine = '';
                for (const origLine of originalLines) {
                    if (origLine.includes(commit.commitId) && origLine.includes(commit.changeId)) {
                        commitLine = origLine;
                        break;
                    }
                }

                if (!commitLine) {
                    continue;
                }

                // Extract graph part: everything except the last 4 tab-separated parts
                const parts = commitLine.split('\t');
                let graphPart = commitLine;
                if (parts.length >= 4) {
                    // Remove the last 4 parts (commit_id, change_id, bookmarks, summary)
                    const graphParts = parts.slice(0, parts.length - 4);
                    graphPart = graphParts.join('\t');
                }
                
                // Build display line with bookmarks and summary
                let displayLine = graphPart.trimEnd();
                if (commit.bookmarks.length > 0) {
                    displayLine += ` [${commit.bookmarks.join(', ')}]`;
                }
                displayLine += ` ${commit.summary}`;

                lines.push(displayLine);
                this.lineToCommit.set(currentLine, commit);
                this.commitToLine.set(commit.commitId, currentLine);
                currentLine++;

                // If expanded, add details
                if (this.expandedCommits.has(commit.commitId)) {
                    try {
                        const details = await getCommitDetails(commit.commitId);
                        lines.push(`  Commit ID: ${details.fullCommitId}`);
                        lines.push(`  Change ID: ${details.changeId}`);
                        if (details.bookmarks.length > 0) {
                            lines.push(`  Bookmarks: ${details.bookmarks.join(', ')}`);
                        }
                        lines.push(`  Author: ${details.author}`);
                        lines.push(`  Time: ${details.timestamp}`);
                        lines.push(`  Summary: ${details.summary}`);
                        if (details.files.length > 0) {
                            lines.push(`  Files:`);
                            for (const file of details.files.slice(0, 20)) { // Limit to 20 files
                                lines.push(`    ${file}`);
                            }
                            if (details.files.length > 20) {
                                lines.push(`    ... and ${details.files.length - 20} more`);
                            }
                        }
                        lines.push(''); // Empty line after expansion
                        // Note: We don't update currentLine here because we only map commit header lines
                    } catch (error) {
                        lines.push(`  Error loading details: ${error}`);
                    }
                }
            }

            this.currentContent = lines.join('\n');
            return this.currentContent;
        } catch (error: any) {
            const errorMsg = error.message || String(error);
            return `Error loading JJ log:\n\n${errorMsg}\n\nPress 'r' to refresh.`;
        }
    }

    /**
     * Preserve expanded state after refresh
     */
    preserveExpandedState(): Set<string> {
        return new Set(this.expandedCommits);
    }

    /**
     * Restore expanded state
     */
    restoreExpandedState(expanded: Set<string>): void {
        this.expandedCommits = expanded;
    }
}
