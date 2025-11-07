import * as vscode from 'vscode';
import { execJj, parseLogOutput, getLogCommand, getCommitDetails, parseAnsiCodes, AnsiCode, CommitInfo, ExpandedCommitInfo } from './jjUtils';

// Get output channel from extension
let outputChannel: vscode.OutputChannel | undefined;

export function setOutputChannel(channel: vscode.OutputChannel) {
    outputChannel = channel;
}

function log(message: string) {
    console.log(message);
    if (outputChannel) {
        outputChannel.appendLine(message);
    }
}

const LOG_URI = vscode.Uri.parse('jj://log/log');

export class JjLogProvider implements vscode.TextDocumentContentProvider {
    private _onDidChange = new vscode.EventEmitter<vscode.Uri>();
    private expandedCommits = new Set<string>(); // commitId -> expanded
    private lineToCommit = new Map<number, CommitInfo>(); // line number -> commit info
    private commitToLine = new Map<string, number>(); // commitId -> line number
    private currentContent = '';
    private lastSelectedCommitId: string | undefined; // For preserving cursor position
    private ansiCodes: AnsiCode[] = []; // Store ANSI codes for decoration
    private decorationTypes = new Map<string, vscode.TextEditorDecorationType>();
    private isContentLoading = false; // Track if content is being loaded

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
        // Clear ANSI codes before refresh (but keep line mappings until new content loads)
        this.ansiCodes = [];
        console.log('Refresh called. Current mappings:', this.lineToCommit.size);
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
     * Check if a commit is expanded
     */
    isExpanded(commitId: string): boolean {
        return this.expandedCommits.has(commitId);
    }

    /**
     * Toggle expansion of a commit
     */
    toggleExpand(commitId: string): void {
        const wasExpanded = this.expandedCommits.has(commitId);
        console.log(`Toggling commit ${commitId}, was expanded: ${wasExpanded}`);
        
        if (wasExpanded) {
            this.expandedCommits.delete(commitId);
            console.log(`Removed from expanded set. Current expanded:`, Array.from(this.expandedCommits));
        } else {
            this.expandedCommits.add(commitId);
            console.log(`Added to expanded set. Current expanded:`, Array.from(this.expandedCommits));
        }
        this.refresh();
    }

    /**
     * Get commit info for a line number
     * If the line is within expanded details, find the parent commit
     */
    getCommitAtLine(line: number): CommitInfo | undefined {
        console.log(`getCommitAtLine called for line ${line}`);
        console.log(`Mapped lines:`, Array.from(this.lineToCommit.keys()).sort((a, b) => a - b));
        
        // Direct match
        if (this.lineToCommit.has(line)) {
            const commit = this.lineToCommit.get(line);
            console.log(`Direct match found:`, commit?.commitId);
            return commit;
        }

        // Find the nearest commit line above this line
        let nearestLine = -1;
        for (const [commitLine] of this.lineToCommit) {
            if (commitLine <= line && commitLine > nearestLine) {
                nearestLine = commitLine;
            }
        }

        if (nearestLine >= 0) {
            const commit = this.lineToCommit.get(nearestLine);
            console.log(`Nearest commit found at line ${nearestLine}:`, commit?.commitId);
            return commit;
        }

        console.log(`No commit found for line ${line}`);
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
     * Get all mapped line numbers (for debugging)
     */
    getMappedLines(): number[] {
        return Array.from(this.lineToCommit.keys()).sort((a, b) => a - b);
    }

    /**
     * Provide content for the jj://log document
     */
    async provideTextDocumentContent(uri: vscode.Uri): Promise<string> {
        log('=== JjLogProvider.provideTextDocumentContent called ===');
        log(`URI: ${uri.toString()}`);
        this.isContentLoading = true;
        
        try {
            // Ensure we have a valid workspace
            const workspaceRoot = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
            if (!workspaceRoot) {
                const errorMsg = 'Error: No workspace folder open. Please open a workspace folder first.';
                console.error(errorMsg);
                return errorMsg;
            }

            log(`Workspace root: ${workspaceRoot}`);
            const logArgs = getLogCommand(100);
            log(`Running JJ command: jj ${logArgs.join(' ')}`);
            
            const rawOutput = await execJj(logArgs);
            log(`JJ command output length: ${rawOutput?.length || 0}`);
            
            if (!rawOutput || !rawOutput.trim()) {
                const errorMsg = 'Error: JJ log command returned empty output.';
                log(errorMsg);
                return errorMsg;
            }
            
            // Show first 1000 chars of raw output for debugging
            log(`Raw output (first 1000 chars):\n${rawOutput.substring(0, 1000)}`);
            
            // Parse ANSI codes for decoration from raw output
            const { cleanText: output, codes: rawAnsiCodes } = parseAnsiCodes(rawOutput);
            log(`After ANSI strip, output length: ${output.length}`);
            log(`Clean output (first 1000 chars):\n${output.substring(0, 1000)}`);
            
            const commits = parseLogOutput(output);
            log(`Parsed commits: ${commits.length}`);
            
            if (commits.length === 0 && output.length > 0) {
                log(`WARNING: Output exists but no commits parsed. Output has ${output.split('\n').length} lines`);
                log(`First 10 lines of output:\n${output.split('\n').slice(0, 10).join('\n')}`);
                log(`Looking for tab-separated values. Sample line analysis:`);
                const sampleLines = output.split('\n').slice(0, 5);
                for (let i = 0; i < sampleLines.length; i++) {
                    const line = sampleLines[i];
                    const parts = line.split('\t');
                    log(`  Line ${i}: ${parts.length} tab-separated parts. Last 4: ${parts.slice(-4).join(' | ')}`);
                }
            }
            
            if (commits.length === 0) {
                this.isContentLoading = false;
                return 'No commits found in repository.\n\nRaw output:\n' + output.substring(0, 500);
            }
            
            // Build line mappings
            this.lineToCommit.clear();
            this.commitToLine.clear();
            
            const lines: string[] = [];
            let currentLine = 0;
            let contentOffset = 0; // Track position in final content
            const ansiCodeMap = new Map<number, AnsiCode[]>(); // Map line index to ANSI codes

            // Split output into lines to find the original graph
            const originalLines = output.split('\n');
            
            // Map ANSI codes to line positions in the original output
            let charOffset = 0;
            for (let lineIdx = 0; lineIdx < originalLines.length; lineIdx++) {
                const line = originalLines[lineIdx];
                const lineStart = charOffset;
                const lineEnd = charOffset + line.length;
                
                // Find ANSI codes that apply to this line
                const lineCodes: AnsiCode[] = [];
                for (const code of rawAnsiCodes) {
                    if (code.start >= lineStart && code.start < lineEnd) {
                        // Adjust code position relative to line start
                        lineCodes.push({
                            ...code,
                            start: code.start - lineStart,
                            end: Math.min(code.end - lineStart, line.length)
                        });
                    }
                }
                if (lineCodes.length > 0) {
                    ansiCodeMap.set(lineIdx, lineCodes);
                }
                
                charOffset += line.length + 1; // +1 for newline
            }

            log(`Starting to process ${commits.length} commits`);
            let commitsProcessed = 0;
            
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
                    console.log(`Warning: Could not find original line for commit ${commit.commitId}`);
                    continue;
                }
                
                commitsProcessed++;

                // Extract graph part: find the 12-char commit ID and remove template data after it
                // The template format is: <graph> <commit_id_12chars> <change_id> <bookmarks> <summary>
                // We want to show the graph with commit ID, then description on next line (like normal jj log)
                const hex12Match = commitLine.match(/\b([a-f0-9]{12})\b/i);
                let graphLine = commitLine;
                let graphLength = commitLine.length;
                
                if (hex12Match) {
                    // Everything up to and including the commit ID is the graph part
                    // In normal jj log, the graph shows: @  <commit_id> <bookmarks> <author> <date>
                    // Then description is on the next line
                    const commitIdIndex = hex12Match.index!;
                    // Keep the commit ID in the graph line
                    graphLine = commitLine.substring(0, commitIdIndex + 12).trimEnd();
                    graphLength = graphLine.length;
                }
                
                // Find the original line index to get ANSI codes
                let originalLineIdx = -1;
                for (let i = 0; i < originalLines.length; i++) {
                    if (originalLines[i] === commitLine) {
                        originalLineIdx = i;
                        break;
                    }
                }
                
                // Store ANSI codes for this display line (only for graph part)
                if (originalLineIdx >= 0 && ansiCodeMap.has(originalLineIdx)) {
                    const lineCodes = ansiCodeMap.get(originalLineIdx)!;
                    // Filter codes that are within the graph part
                    const graphCodes = lineCodes.filter(code => code.end <= graphLength);
                    if (graphCodes.length > 0) {
                        // Store with absolute position in final content
                        if (!this.ansiCodes) {
                            this.ansiCodes = [];
                        }
                        for (const code of graphCodes) {
                            // Calculate absolute position in final content
                            const absStart = contentOffset + code.start;
                            const absEnd = contentOffset + code.end;
                            this.ansiCodes.push({
                                ...code,
                                start: absStart,
                                end: absEnd
                            });
                        }
                    }
                }

                // Add the graph line
                lines.push(graphLine);
                contentOffset += graphLine.length + 1; // +1 for newline
                console.log(`Mapping commit ${commit.commitId.substring(0, 8)} to line ${currentLine}`);
                this.lineToCommit.set(currentLine, commit);
                this.commitToLine.set(commit.commitId, currentLine);
                currentLine++;
                
                // Add description line if present
                if (commit.summary) {
                    const indent = graphLine.match(/^(\s*[│├╭╰╯╮─◆@~ ]*)/)?.[1] || '  ';
                    const descLine = indent + commit.summary;
                    lines.push(descLine);
                    contentOffset += descLine.length + 1;
                    // Don't increment currentLine - we only map the graph line, not description lines
                }

                // If expanded, add details
                const isExpanded = this.expandedCommits.has(commit.commitId);
                // Note: currentLine was already incremented, so the commit is at currentLine - 1
                console.log(`Commit ${commit.commitId} mapped to line ${currentLine - 1}, isExpanded: ${isExpanded}`);
                
                if (isExpanded) {
                    try {
                        console.log(`Fetching details for expanded commit ${commit.commitId}`);
                        const details = await getCommitDetails(commit.commitId);
                        const detailLines = [
                            `  Commit ID: ${details.fullCommitId}`,
                            `  Change ID: ${details.changeId}`,
                            ...(details.bookmarks.length > 0 ? [`  Bookmarks: ${details.bookmarks.join(', ')}`] : []),
                            `  Author: ${details.author}`,
                            `  Time: ${details.timestamp}`,
                            `  Summary: ${details.summary}`,
                            ...(details.files.length > 0 ? [
                                `  Files:`,
                                ...details.files.slice(0, 20).map(f => `    ${f}`),
                                ...(details.files.length > 20 ? [`    ... and ${details.files.length - 20} more`] : [])
                            ] : []),
                            '' // Empty line after expansion
                        ];
                        lines.push(...detailLines);
                        // Update contentOffset for all detail lines
                        for (const detailLine of detailLines) {
                            contentOffset += detailLine.length + 1; // +1 for newline
                        }
                        // Note: We don't update currentLine here because we only map commit header lines
                    } catch (error) {
                        const errorLine = `  Error loading details: ${error}`;
                        lines.push(errorLine);
                        contentOffset += errorLine.length + 1;
                    }
                }
            }

            this.currentContent = lines.join('\n');
            log('=== Content Generation Complete ===');
            log(`Content length: ${this.currentContent.length}`);
            log(`Total lines generated: ${lines.length}`);
            log(`Commits processed: ${commitsProcessed} out of ${commits.length}`);
            log(`ANSI codes to apply: ${this.ansiCodes.length}`);
            log(`Expanded commits: ${Array.from(this.expandedCommits).join(', ')}`);
            log(`Mapped commit lines: ${Array.from(this.lineToCommit.keys()).sort((a, b) => a - b).join(', ')}`);
            log(`Total commits mapped: ${this.lineToCommit.size}`);
            log('===================================');
            this.isContentLoading = false;
            
            // Apply decorations after document is opened
            setTimeout(() => this.applyDecorations(), 200);
            
            return this.currentContent;
        } catch (error: any) {
            this.isContentLoading = false;
            const errorMsg = error.message || String(error);
            const fullError = `Error loading JJ log:\n\n${errorMsg}\n\nPress 'r' to refresh.`;
            console.error('Error in provideTextDocumentContent:', error);
            console.error('Stack:', error.stack);
            return fullError;
        }
    }

    /**
     * Check if content is currently loading
     */
    isContentLoadingNow(): boolean {
        return this.isContentLoading;
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

    /**
     * Apply ANSI color decorations to the editor
     */
    private applyDecorations(): void {
        const editor = vscode.window.activeTextEditor;
        if (!editor || editor.document.uri.scheme !== 'jj') {
            return;
        }

        // Clear existing decorations
        for (const decorationType of this.decorationTypes.values()) {
            decorationType.dispose();
        }
        this.decorationTypes.clear();

        // Group codes by their styling to create decoration types
        const decorationRanges = new Map<string, vscode.Range[]>();
        
        for (const code of this.ansiCodes) {
            const key = `${code.color || ''}-${code.backgroundColor || ''}-${code.bold ? 'bold' : ''}-${code.dim ? 'dim' : ''}`;
            
            if (!decorationRanges.has(key)) {
                decorationRanges.set(key, []);
            }
            
            // Convert character positions to line/column
            const startPos = editor.document.positionAt(code.start);
            const endPos = editor.document.positionAt(code.end);
            decorationRanges.get(key)!.push(new vscode.Range(startPos, endPos));
        }

        // Create and apply decorations
        for (const [key, ranges] of decorationRanges) {
            const parts = key.split('-');
            const color = parts[0] || undefined;
            const backgroundColor = parts[1] || undefined;
            const bold = parts[2] === 'bold';
            const dim = parts[3] === 'dim';

            const decorationType = vscode.window.createTextEditorDecorationType({
                color: color,
                backgroundColor: backgroundColor,
                fontWeight: bold ? 'bold' : undefined,
                opacity: dim ? '0.7' : undefined
            });

            editor.setDecorations(decorationType, ranges);
            this.decorationTypes.set(key, decorationType);
        }
    }

    /**
     * Dispose resources
     */
    dispose(): void {
        for (const decorationType of this.decorationTypes.values()) {
            decorationType.dispose();
        }
        this.decorationTypes.clear();
        this._onDidChange.dispose();
    }
}
