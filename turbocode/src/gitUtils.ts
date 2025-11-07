import { exec } from 'child_process';
import { promisify } from 'util';
import * as path from 'path';

const execAsync = promisify(exec);

export interface GitHubInfo {
    owner: string;
    repo: string;
}

async function execGit(command: string, cwd: string): Promise<string> {
    const { stdout, stderr } = await execAsync(command, { cwd });
    if (stderr && !stdout) throw new Error(stderr);
    return stdout.trim();
}

export async function getRepoRoot(filePath: string): Promise<string> {
    return execGit('git rev-parse --show-toplevel', path.dirname(filePath));
}

export async function getCurrentSha(filePath: string): Promise<string> {
    return execGit('git rev-parse HEAD', path.dirname(filePath));
}

export async function getRemoteUrl(filePath: string): Promise<string> {
    return execGit('git remote get-url origin', path.dirname(filePath));
}

export function parseGitHubUrl(remoteUrl: string): GitHubInfo | null {
    const httpsMatch = remoteUrl.match(/https:\/\/github\.com\/([^\/]+)\/([^\/]+?)(\.git)?$/);
    if (httpsMatch) return { owner: httpsMatch[1], repo: httpsMatch[2] };
    const sshMatch = remoteUrl.match(/git@github\.com:([^\/]+)\/([^\/]+?)(\.git)?$/);
    if (sshMatch) return { owner: sshMatch[1], repo: sshMatch[2] };
    return null;
}

export function isGitHubUrl(remoteUrl: string): boolean {
    return remoteUrl.includes('github.com');
}

export function getRelativePath(filePath: string, repoRoot: string): string {
    return path.relative(repoRoot, filePath);
}

