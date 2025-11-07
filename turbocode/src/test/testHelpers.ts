import { execJj, getLogCommand } from '../jjUtils';
import * as path from 'path';
import * as fs from 'fs';
import { promisify } from 'util';
import { execFile } from 'child_process';

const execFileAsync = promisify(execFile);

export function getTestDataDir(): string {
    return path.resolve(__dirname, 'data');
}

export function getTestRepoPath(name: string = 'test-repo'): string {
    return path.join(getTestDataDir(), name);
}

export interface TestRepoInfo {
    repoPath: string;
    initialCommitId: string;
}

export async function createTestRepo(name: string = 'test-repo'): Promise<TestRepoInfo> {
    const testRepoPath = getTestRepoPath(name);
    
    if (fs.existsSync(testRepoPath)) {
        fs.rmSync(testRepoPath, { recursive: true, force: true });
    }
    
    const testDataDir = getTestDataDir();
    if (!fs.existsSync(testDataDir)) {
        fs.mkdirSync(testDataDir, { recursive: true });
    }
    
    await execFileAsync('jj', ['git', 'init', testRepoPath]);
    
    const testFile = path.join(testRepoPath, 'test.txt');
    fs.writeFileSync(testFile, 'test content');
    
    await execJj(['commit', '-m', 'Initial commit'], testRepoPath);
    
    const logOutput = await execJj(['log', '-r', '@', '-T', 'commit_id'], testRepoPath);
    const initialCommitId = logOutput.trim();
    
    return { repoPath: testRepoPath, initialCommitId };
}

export function cleanupTestRepo(repoPath: string): void {
    if (fs.existsSync(repoPath)) {
        fs.rmSync(repoPath, { recursive: true, force: true });
    }
}

export async function addFile(repoPath: string, filePath: string, content: string): Promise<void> {
    const fullPath = path.join(repoPath, filePath);
    const dir = path.dirname(fullPath);
    
    if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
    }
    
    fs.writeFileSync(fullPath, content);
}

export async function commit(repoPath: string, message: string): Promise<string> {
    await execJj(['commit', '-m', message], repoPath);
    
    // After commit, @ is the new empty working copy, @- is the commit we just created
    const logOutput = await execJj(['log', '-r', '@-', '-T', 'commit_id'], repoPath);
    // Extract commit ID from the output (it's on the line with @ or ○ marker)
    // Format: "@  <commit_id>" or "○  <commit_id>"
    const lines = logOutput.trim().split('\n');
    for (const line of lines) {
        // Find the hex commit ID (40 chars) in the line
        const match = line.match(/\b([a-f0-9]{40})\b/i);
        if (match) {
            return match[1];
        }
    }
    // Fallback: return trimmed output (shouldn't happen)
    return logOutput.trim();
}

export async function commitFile(repoPath: string, filePath: string, content: string, message: string): Promise<string> {
    await addFile(repoPath, filePath, content);
    return await commit(repoPath, message);
}

export async function commitFiles(repoPath: string, files: Array<{ path: string; content: string; message: string }>): Promise<string[]> {
    const commitIds: string[] = [];
    
    for (const file of files) {
        const commitId = await commitFile(repoPath, file.path, file.content, file.message);
        commitIds.push(commitId);
    }
    
    return commitIds;
}

export async function createBookmark(repoPath: string, bookmarkName: string, commitId?: string): Promise<void> {
    const args = ['bookmark', 'set', bookmarkName];
    if (commitId) {
        args.push('-r', commitId);
    }
    await execJj(args, repoPath);
}

export async function deleteBookmark(repoPath: string, bookmarkName: string): Promise<void> {
    await execJj(['bookmark', 'delete', bookmarkName], repoPath);
}

export async function newCommit(repoPath: string, message?: string): Promise<string> {
    const args = ['new'];
    if (message) {
        args.push('-m', message);
    }
    await execJj(args, repoPath);
    
    const logOutput = await execJj(['log', '-r', '@', '-T', 'commit_id'], repoPath);
    return logOutput.trim();
}

export async function isJjAvailable(): Promise<boolean> {
    try {
        await execFileAsync('jj', ['--version']);
        return true;
    } catch {
        return false;
    }
}

export async function getLogWithTemplate(repoPath: string, count: number): Promise<string> {
    const args = getLogCommand(count);
    return await execJj(args, repoPath);
}
