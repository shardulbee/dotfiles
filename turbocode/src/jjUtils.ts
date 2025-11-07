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
 * Execute a jj command and return stdout
 */
export async function execJj(args: string[], cwd?: string): Promise<string> {
    try {
        const { stdout, stderr } = await execFileAsync('jj', args, {
            cwd: cwd || process.cwd(),
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
        throw new Error(`JJ command failed: ${errorMessage}`);
    }
}

/**
 * Get the repository root directory
 */
export async function getJjRepoRoot(): Promise<string> {
    try {
        const result = await execJj(['root']);
        return result.trim();
    } catch (error: any) {
        throw new Error(`Not a JJ repository: ${error.message}`);
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

        // The template format is: graph + "\t" + commit_id + "\t" + change_id + "\t" + bookmarks + "\t" + summary
        // We need to find the tab-separated values at the end
        // Split by tabs and work backwards
        const parts = line.split('\t');
        
        // We need at least 4 parts after the graph (commit_id, change_id, bookmarks, summary)
        // But the graph itself may contain tabs, so we need to be careful
        // The last 4 parts should be: commit_id, change_id, bookmarks, summary
        if (parts.length >= 4) {
            // Take the last 4 parts
            const commitId = parts[parts.length - 4].trim();
            const changeId = parts[parts.length - 3].trim();
            const bookmarksStr = parts[parts.length - 2].trim();
            const summary = parts[parts.length - 1].trim();

            // Validate that commitId looks like a commit ID (hex string)
            if (commitId && /^[a-f0-9]+$/i.test(commitId)) {
                const bookmarks = bookmarksStr ? bookmarksStr.split(',').map(b => b.trim()).filter(Boolean) : [];

                commits.push({
                    commitId,
                    changeId,
                    bookmarks,
                    summary,
                    lineNumber
                });
            }
        }
    }

    return commits;
}

/**
 * Generate log command with template
 */
export function getLogCommand(n: number = 100): string[] {
    // JJ template: tab-separated values for parsing
    const template = 'commit_id.short() ++ "\t" ++ change_id.shortest(12) ++ "\t" ++ bookmarks.map(|b| b.name()).join(",") ++ "\t" ++ description.first_line()';
    return [
        'log',
        `-n`, String(n),
        '--color=never',
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
        if (!trimmed) continue;
        
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
