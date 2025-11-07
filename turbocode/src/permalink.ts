import * as vscode from 'vscode';
import { getRepoRoot, getCurrentSha, getRemoteUrl, parseGitHubUrl, isGitHubUrl, getRelativePath } from './gitUtils';

export async function generatePermalink(editor: vscode.TextEditor, useMain: boolean = false): Promise<string> {
    const filePath = editor.document.uri.fsPath;
    const repoRoot = await getRepoRoot(filePath);
    const remoteUrl = await getRemoteUrl(filePath);
    
    if (!isGitHubUrl(remoteUrl)) throw new Error('The remote origin is not a GitHub URL');
    const githubInfo = parseGitHubUrl(remoteUrl);
    if (!githubInfo) throw new Error('Failed to parse GitHub URL');
    
    const relativePath = getRelativePath(filePath, repoRoot).replace(/\\/g, '/');
    const start = editor.selection.start.line + 1;
    const end = editor.selection.end.line + 1;
    const ref = useMain ? 'main' : await getCurrentSha(filePath);
    const lineFrag = start === end ? `#L${start}` : `#L${start}-L${end}`;
    
    return `https://github.com/${githubInfo.owner}/${githubInfo.repo}/blob/${ref}/${relativePath}${lineFrag}`;
}

