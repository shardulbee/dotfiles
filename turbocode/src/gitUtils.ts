import { exec } from 'child_process';
import { promisify } from 'util';
import * as path from 'path';

const execAsync = promisify(exec);

export interface GitInfo {
    repoRoot: string;
    remoteName: string;
    remoteUrl: string;
    currentSha: string;
}

export interface GitHubInfo {
    owner: string;
    repo: string;
}

/**
 * Execute a git command in the specified directory
 */
async function execGit(command: string, cwd: string): Promise<string> {
    try {
        const { stdout, stderr } = await execAsync(command, { cwd });
        if (stderr && !stdout) {
            throw new Error(stderr);
        }
        return stdout.trim();
    } catch (error: any) {
        throw new Error(`Git command failed: ${error.message}`);
    }
}

/**
 * Get the git repository root directory for a given file path
 */
export async function getRepoRoot(filePath: string): Promise<string> {
    const fileDir = path.dirname(filePath);
    const repoRoot = await execGit('git rev-parse --show-toplevel', fileDir);
    return repoRoot;
}

/**
 * Get the current git SHA for a file
 */
export async function getCurrentSha(filePath: string): Promise<string> {
    const fileDir = path.dirname(filePath);
    const sha = await execGit('git rev-parse HEAD', fileDir);
    return sha;
}

/**
 * Get the remote URL for the origin remote
 */
export async function getRemoteUrl(filePath: string): Promise<string> {
    const fileDir = path.dirname(filePath);
    const remoteUrl = await execGit('git remote get-url origin', fileDir);
    return remoteUrl;
}

/**
 * Parse a GitHub remote URL to extract owner and repo
 * Supports both HTTPS and SSH formats:
 * - https://github.com/owner/repo.git
 * - git@github.com:owner/repo.git
 */
export function parseGitHubUrl(remoteUrl: string): GitHubInfo | null {
    // HTTPS format: https://github.com/owner/repo.git
    const httpsMatch = remoteUrl.match(/https:\/\/github\.com\/([^\/]+)\/([^\/]+?)(\.git)?$/);
    if (httpsMatch) {
        return {
            owner: httpsMatch[1],
            repo: httpsMatch[2]
        };
    }

    // SSH format: git@github.com:owner/repo.git
    const sshMatch = remoteUrl.match(/git@github\.com:([^\/]+)\/([^\/]+?)(\.git)?$/);
    if (sshMatch) {
        return {
            owner: sshMatch[1],
            repo: sshMatch[2]
        };
    }

    return null;
}

/**
 * Check if a remote URL is a GitHub URL
 */
export function isGitHubUrl(remoteUrl: string): boolean {
    return remoteUrl.includes('github.com');
}

/**
 * Get the relative path of a file from the repository root
 */
export function getRelativePath(filePath: string, repoRoot: string): string {
    return path.relative(repoRoot, filePath);
}

/**
 * Get all git information needed for creating a permalink
 */
export async function getGitInfo(filePath: string): Promise<GitInfo> {
    const repoRoot = await getRepoRoot(filePath);
    const remoteUrl = await getRemoteUrl(filePath);
    const currentSha = await getCurrentSha(filePath);

    return {
        repoRoot,
        remoteName: 'origin',
        remoteUrl,
        currentSha
    };
}

