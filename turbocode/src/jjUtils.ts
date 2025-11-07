import { execFile } from 'child_process';
import { promisify } from 'util';
import * as vscode from 'vscode';

const execFileAsync = promisify(execFile);

export interface CommitInfo {
    commitId: string;
    changeId: string;
    bookmarks: string[];
    summary: string;
    lineNumber: number;
}

export interface ExpandedCommitInfo extends CommitInfo {
    fullCommitId: string;
    author: string;
    timestamp: string;
    files: string[];
}

/**
 * Get the workspace root directory
 * Returns the first workspace folder, or undefined if none exists
 */
export function getWorkspaceRoot(): string | undefined {
    const workspaceFolders = vscode.workspace.workspaceFolders;
    if (workspaceFolders && workspaceFolders.length > 0) {
        return workspaceFolders[0].uri.fsPath;
    }
    return undefined;
}

/**
 * Execute a jj command and return stdout
 * If cwd is not provided, resolves the JJ repo root and uses that
 */
export async function execJj(args: string[], cwd?: string): Promise<string> {
    // Determine working directory
    let workingDir: string;
    
    if (cwd) {
        workingDir = cwd;
    } else {
        // Try to get the JJ repo root, which will use workspace root as starting point
        try {
            workingDir = await getJjRepoRoot();
        } catch {
            // Fall back to workspace root or process.cwd() if not in a repo
            workingDir = getWorkspaceRoot() || process.cwd();
        }
    }
    
    if (!workingDir) {
        throw new Error('Cannot determine working directory for JJ command');
    }
    
    try {
        const { stdout, stderr } = await execFileAsync('jj', args, {
            cwd: workingDir,
            maxBuffer: 10 * 1024 * 1024 // 10MB
        });
        // If there's stderr but no stdout, treat it as an error
        if (stderr && !stdout) {
            throw new Error(stderr);
        }
        // If there's both stdout and stderr, include stderr in the error message for context
        // but still return stdout (some commands output warnings to stderr)
        return stdout;
    } catch (error: any) {
        // Include stderr in error message if available
        let errorMessage = error.message || String(error);
        if (error.stderr) {
            errorMessage = `${errorMessage}\n${error.stderr}`;
        }
        throw new Error(`JJ command failed (from ${workingDir}): ${errorMessage}`);
    }
}

/**
 * Get the repository root directory
 * Returns the JJ repository root, or throws if not in a JJ repository
 */
export async function getJjRepoRoot(): Promise<string> {
    // Use workspace root as starting point, or current directory
    const startDir = getWorkspaceRoot() || process.cwd();
    
    if (!startDir) {
        throw new Error('No workspace folder open and cannot determine current directory');
    }
    
    try {
        // Run jj root directly to find the repo root
        const { stdout, stderr } = await execFileAsync('jj', ['root'], {
            cwd: startDir,
            maxBuffer: 1024 * 1024 // 1MB should be enough for a path
        });
        
        const repoRoot = stdout.trim();
        if (!repoRoot) {
            throw new Error(`jj root returned empty result`);
        }
        
        return repoRoot;
    } catch (error: any) {
        const errorMsg = error.stderr || error.message || String(error);
        throw new Error(`Not a JJ repository (checked from: ${startDir}): ${errorMsg}`);
    }
}

/**
 * Check if the current workspace is a JJ repository
 */
export async function isJjRepository(): Promise<boolean> {
    try {
        await getJjRepoRoot();
        return true;
    } catch {
        return false;
    }
}

/**
 * Parse the log output with tab-delimited tail
 * Format: ascii graph + commit_id + change_id + bookmarks + summary
 * The template appends tabs at the end, so we need to find the tab-separated values
 */
export function parseLogOutput(output: string): CommitInfo[] {
    const lines = output.split('\n');
    const commits: CommitInfo[] = [];
    let lineNumber = 0;

    for (const line of lines) {
        lineNumber++;
        if (!line.trim()) {
            continue;
        }

        // The template format is: graph + " " + commit_id + " " + change_id + " " + bookmarks + " " + summary
        // The template appends space-separated values at the end
        // We need to extract the last few space-separated tokens
        // But the graph may contain spaces, so we need to be smart about it
        
        // Look for a hex commit ID (12 chars) near the end - that's our anchor
        // Format: ... <commit_id_12chars> <change_id_12chars> <bookmarks> <summary>
        const hex12Match = line.match(/\b([a-f0-9]{12})\b/i);
        if (hex12Match) {
            const commitId = hex12Match[1];
            const commitIdIndex = hex12Match.index!;
            
            // Get everything after the commit ID
            const afterCommitId = line.substring(commitIdIndex + 12).trim();
            const tokens = afterCommitId.split(/\s+/);
            
            if (tokens.length >= 2) {
                // tokens[0] should be change_id, tokens[1+] might be bookmarks, last is summary
                const changeId = tokens[0];
                
                // Find where summary starts (it's usually the longest token or contains spaces)
                // Bookmarks are usually short, summary might be multiple words
                // Let's assume: change_id, then bookmarks (if any, comma-separated or space-separated), then summary
                // Actually, bookmarks in the template are space-separated, summary is the last part
                
                // Try to find the summary - it's usually the last significant token(s)
                // Bookmarks might be empty or space-separated
                let summary = '';
                let bookmarksStr = '';
                
                if (tokens.length === 2) {
                    // Only change_id and summary
                    summary = tokens[1];
                } else if (tokens.length >= 3) {
                    // change_id, bookmarks (might be multiple), summary
                    // Summary is usually the longest or last token
                    // Let's take everything after change_id as potential bookmarks+summary
                    // The summary is the last token, bookmarks are everything in between
                    const lastToken = tokens[tokens.length - 1];
                    // If last token looks like a summary (has lowercase, not all hex), it's the summary
                    if (lastToken.match(/[a-z]/i) && !lastToken.match(/^[a-f0-9]+$/i)) {
                        summary = lastToken;
                        bookmarksStr = tokens.slice(1, -1).join(' ');
                    } else {
                        // All might be bookmarks, summary is empty or in the line itself
                        bookmarksStr = tokens.slice(1).join(' ');
                    }
                }
                
                // Extract bookmarks (they might be space-separated or comma-separated)
                const bookmarks = bookmarksStr 
                    ? bookmarksStr.split(/[\s,]+/).map(b => b.trim()).filter(b => b && !b.match(/^[a-f0-9]{12}$/i))
                    : [];
                
                // If we found a valid commit ID and change ID
                if (commitId && changeId && changeId.match(/^[a-f0-9]+$/i)) {
                    commits.push({
                        commitId,
                        changeId,
                        bookmarks,
                        summary: summary || '',
                        lineNumber
                    });
                }
            }
        }
    }

    return commits;
}

/**
 * ANSI color code information
 */
export interface AnsiCode {
    start: number;
    end: number;
    color?: string;
    backgroundColor?: string;
    bold?: boolean;
    dim?: boolean;
}

/**
 * Parse ANSI escape codes and return positions with color info
 */
export function parseAnsiCodes(text: string): { cleanText: string; codes: AnsiCode[] } {
    const codes: AnsiCode[] = [];
    // eslint-disable-next-line no-control-regex
    const ansiRegex = /\x1b\[([0-9;]*)m/g;
    let cleanText = '';
    let lastIndex = 0;
    let currentColor: { color?: string; backgroundColor?: string; bold?: boolean; dim?: boolean } = {};
    let offset = 0;

    let match;
    // eslint-disable-next-line no-control-regex
    while ((match = ansiRegex.exec(text)) !== null) {
        // Add text before this code
        cleanText += text.substring(lastIndex, match.index);
        const codeStart = cleanText.length;
        
        // Parse the ANSI code
        const code = match[1];
        if (code === '0' || code === '') {
            // Reset
            currentColor = {};
        } else {
            const parts = code.split(';');
            for (const part of parts) {
                const num = parseInt(part, 10);
                if (num === 1) {
                    currentColor.bold = true;
                } else if (num === 2) {
                    currentColor.dim = true;
                } else if (num >= 30 && num <= 37) {
                    // Foreground colors
                    currentColor.color = ansiToColor(num - 30);
                } else if (num >= 40 && num <= 47) {
                    // Background colors
                    currentColor.backgroundColor = ansiToColor(num - 40);
                } else if (num >= 90 && num <= 97) {
                    // Bright foreground colors
                    currentColor.color = ansiToBrightColor(num - 90);
                } else if (num >= 100 && num <= 107) {
                    // Bright background colors
                    currentColor.backgroundColor = ansiToBrightColor(num - 100);
                } else if (num >= 38 && num <= 39) {
                    // Extended colors (skip for now)
                } else if (num >= 48 && num <= 49) {
                    // Extended background colors (skip for now)
                }
            }
        }
        
        // Store the code info if it has styling
        if (currentColor.color || currentColor.backgroundColor || currentColor.bold || currentColor.dim) {
            codes.push({
                start: codeStart,
                end: codeStart, // Will be updated when we find the next code
                ...currentColor
            });
        }
        
        lastIndex = match.index + match[0].length;
    }
    
    // Add remaining text
    cleanText += text.substring(lastIndex);
    
    // Update end positions
    for (let i = 0; i < codes.length; i++) {
        if (i < codes.length - 1) {
            codes[i].end = codes[i + 1].start;
        } else {
            codes[i].end = cleanText.length;
        }
    }
    
    return { cleanText, codes };
}

/**
 * Convert ANSI color number to hex color
 */
function ansiToColor(num: number): string {
    const colors = [
        '#000000', // black
        '#cd3131', // red
        '#0dbc79', // green
        '#e5e510', // yellow
        '#2472c8', // blue
        '#bc3fbc', // magenta
        '#11a8cd', // cyan
        '#e5e5e5'  // white
    ];
    return colors[num] || '#ffffff';
}

/**
 * Convert ANSI bright color number to hex color
 */
function ansiToBrightColor(num: number): string {
    const colors = [
        '#666666', // bright black
        '#f14c4c', // bright red
        '#23d18b', // bright green
        '#f5f543', // bright yellow
        '#3b8eea', // bright blue
        '#d670d6', // bright magenta
        '#29b8db', // bright cyan
        '#e5e5e5'  // bright white
    ];
    return colors[num] || '#ffffff';
}

/**
 * Strip ANSI escape codes from a string (simple version)
 */
export function stripAnsiCodes(text: string): string {
    const { cleanText } = parseAnsiCodes(text);
    return cleanText;
}

/**
 * Generate log command with template
 * We use a template that appends parseable data but preserves the graph structure
 */
export function getLogCommand(n: number = 100): string[] {
    // JJ template: space-separated values appended at the end for parsing
    // Format: <graph> <commit_id> <change_id> <bookmarks> <summary>
    // Using spaces instead of tabs to preserve graph structure better
    const template = 'commit_id.short() ++ " " ++ change_id.shortest(12) ++ " " ++ bookmarks.map(|b| b.name()).join(" ") ++ " " ++ description.first_line()';
    return [
        'log',
        `-n`, String(n),
        '--color=always',  // Enable colors for the graph (we'll strip them)
        '-T', template
    ];
}

/**
 * Get detailed commit info
 */
export async function getCommitDetails(commitId: string): Promise<ExpandedCommitInfo> {
    const template = 'commit_id.full() ++ "\t" ++ change_id.shortest(12) ++ "\t" ++ bookmarks.map(|b| b.name()).join(",") ++ "\t" ++ description.first_line() ++ "\t" ++ author.name() ++ "\t" ++ timestamp.format("%Y-%m-%d %H:%M:%S")';
    
    const output = await execJj(['log', '-r', commitId, '-T', template, '--color=never']);
    const logLines = output.trim().split('\n');
    
    if (logLines.length === 0) {
        throw new Error(`Commit ${commitId} not found`);
    }

    const parts = logLines[0].split('\t');
    const fullCommitId = parts[0] || commitId;
    const changeId = parts[1] || '';
    const bookmarksStr = parts[2] || '';
    const summary = parts[3] || '';
    const author = parts[4] || '';
    const timestamp = parts[5] || '';

    const bookmarks = bookmarksStr ? bookmarksStr.split(',').map(b => b.trim()).filter(Boolean) : [];

    // Get file list from show --summary
    // The output format varies, so we try to extract file paths
    const showOutput = await execJj(['show', '-r', commitId, '--summary', '--color=never']);
    const lines = showOutput.split('\n');
    const files: string[] = [];
    let inFilesSection = false;
    
    for (const line of lines) {
        const trimmed = line.trim();
        if (!trimmed) {
            continue;
        }
        
        // Skip header lines
        if (trimmed.startsWith('Commit ID:') || 
            trimmed.startsWith('Change ID:') ||
            trimmed.startsWith('Author:') ||
            trimmed.startsWith('Timestamp:') ||
            trimmed.startsWith('Description:') ||
            trimmed.startsWith('Summary:')) {
            continue;
        }
        
        // Look for file section markers
        if (trimmed.includes('files:') || trimmed.includes('Files:')) {
            inFilesSection = true;
            continue;
        }
        
        // If we're in the files section or the line looks like a file path
        if (inFilesSection || (trimmed.includes('/') || trimmed.includes('\\') || trimmed.match(/^[A-Za-z]/))) {
            // Remove status prefixes like "M ", "A ", "R ", etc.
            const filePath = trimmed.replace(/^[AMR?]\s+/, '').trim();
            if (filePath && !filePath.startsWith('...')) {
                files.push(filePath);
            }
        }
    }

    return {
        commitId: commitId.substring(0, 12),
        changeId,
        bookmarks,
        summary,
        lineNumber: 0,
        fullCommitId,
        author,
        timestamp,
        files
    };
}

/**
 * Get list of all bookmarks
 */
export async function getBookmarks(): Promise<string[]> {
    try {
        const output = await execJj(['bookmark', 'list', '--color=never']);
        const lines = output.split('\n').filter(line => line.trim());
        return lines.map(line => {
            const match = line.match(/^\s*(\S+)/);
            return match ? match[1] : '';
        }).filter(Boolean);
    } catch (error) {
        return [];
    }
}
