import * as vscode from 'vscode';
import * as path from 'path';
import { getGitInfo, parseGitHubUrl, isGitHubUrl, getRelativePath } from './gitUtils';

export interface LineRange {
    start: number;
    end: number;
}

/**
 * Get the current line range from the active editor
 * Returns either the selected lines or the current cursor line
 */
export function getLineRange(editor: vscode.TextEditor): LineRange {
    const selection = editor.selection;
    
    // Line numbers are 0-indexed in VS Code, but 1-indexed in GitHub
    const start = selection.start.line + 1;
    const end = selection.end.line + 1;
    
    return { start, end };
}

/**
 * Build a GitHub permalink URL
 */
export function buildGitHubPermalink(
    owner: string,
    repo: string,
    ref: string,
    filePath: string,
    lineRange: LineRange
): string {
    // Normalize file path to use forward slashes
    const normalizedPath = filePath.replace(/\\/g, '/');
    
    let url = `https://github.com/${owner}/${repo}/blob/${ref}/${normalizedPath}`;
    
    // Add line range fragment
    if (lineRange.start === lineRange.end) {
        url += `#L${lineRange.start}`;
    } else {
        url += `#L${lineRange.start}-L${lineRange.end}`;
    }
    
    return url;
}

/**
 * Generate a GitHub permalink for the current file and selection
 */
export async function generatePermalink(
    editor: vscode.TextEditor,
    useMain: boolean = false
): Promise<string> {
    const filePath = editor.document.uri.fsPath;
    
    // Get git information
    const gitInfo = await getGitInfo(filePath);
    
    // Verify it's a GitHub remote
    if (!isGitHubUrl(gitInfo.remoteUrl)) {
        throw new Error('The remote origin is not a GitHub URL');
    }
    
    // Parse GitHub URL
    const githubInfo = parseGitHubUrl(gitInfo.remoteUrl);
    if (!githubInfo) {
        throw new Error('Failed to parse GitHub URL');
    }
    
    // Get relative file path from repo root
    const relativePath = getRelativePath(filePath, gitInfo.repoRoot);
    
    // Get line range
    const lineRange = getLineRange(editor);
    
    // Determine the ref (SHA or "main")
    const ref = useMain ? 'main' : gitInfo.currentSha;
    
    // Build and return the permalink
    return buildGitHubPermalink(
        githubInfo.owner,
        githubInfo.repo,
        ref,
        relativePath,
        lineRange
    );
}

