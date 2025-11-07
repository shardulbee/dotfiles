import * as vscode from 'vscode';
import { generatePermalink } from './permalink';
import { JjLogProvider } from './jjLogProvider';
import { execJj, getBookmarks } from './jjUtils';

const LOG_URI = vscode.Uri.parse('jj://log/log');
let logProvider: JjLogProvider;

export function activate(context: vscode.ExtensionContext) {
    logProvider = new JjLogProvider();
    context.subscriptions.push(vscode.workspace.registerTextDocumentContentProvider('jj', logProvider));
    context.subscriptions.push({ dispose: () => logProvider.dispose() });

    context.subscriptions.push(
        vscode.commands.registerCommand('turbocode.github.openPermalink', () => openGitHubPermalink(false)),
        vscode.commands.registerCommand('turbocode.github.openPermalinkOnMain', () => openGitHubPermalink(true))
    );

    registerJjCommands(context);
}

function registerJjCommands(context: vscode.ExtensionContext): void {
    context.subscriptions.push(
        vscode.commands.registerCommand('jj.log.open', async () => {
            const doc = await vscode.workspace.openTextDocument(LOG_URI);
            await vscode.window.showTextDocument(doc, { preview: false, viewColumn: vscode.ViewColumn.Active });
        }),
        vscode.commands.registerCommand('jj.log.toggleExpand', async () => {
            const editor = vscode.window.activeTextEditor;
            if (!editor || editor.document.uri.scheme !== 'jj') return;
            if (logProvider.getMappedLines().length === 0) {
                vscode.window.showWarningMessage('Log view not loaded. Try refreshing.');
                return;
            }
            const commit = logProvider.getCommitAtLine(editor.selection.active.line);
            if (commit) {
                logProvider.toggleExpand(commit.commitId);
            }
        })
    );

    context.subscriptions.push(
        vscode.commands.registerCommand('jj.log.edit', async () => {
            const commit = await getSelectedCommit();
            if (!commit) return;
            try {
                await execJj(['edit', '-r', commit.commitId], getRepoRoot());
                showSuccessAndRefresh('Checked out commit');
            } catch (e: any) {
                vscode.window.showErrorMessage(`Failed: ${e.message}`);
            }
        }),
        vscode.commands.registerCommand('jj.log.describe', async () => {
            const commit = await getSelectedCommit();
            if (!commit) return;
            const message = await vscode.window.showInputBox({ prompt: 'Enter commit message', value: commit.summary });
            if (!message) return;
            try {
                await execJj(['describe', '-r', commit.commitId, '-m', message], getRepoRoot());
                showSuccessAndRefresh('Updated commit message');
            } catch (e: any) {
                vscode.window.showErrorMessage(`Failed: ${e.message}`);
            }
        }),
        vscode.commands.registerCommand('jj.log.rebase', async () => {
            const commit = await getSelectedCommit();
            if (!commit) return;
            const dest = await vscode.window.showInputBox({ prompt: 'Rebase onto (revision)', placeHolder: '@, main, or commit ID' });
            if (!dest) return;
            try {
                await execJj(['rebase', '-r', commit.commitId, '-d', dest], getRepoRoot());
                showSuccessAndRefresh('Rebased commit');
            } catch (e: any) {
                vscode.window.showErrorMessage(`Failed: ${e.message}`);
            }
        }),
        vscode.commands.registerCommand('jj.log.squash', async () => {
            const commit = await getSelectedCommit();
            if (!commit) return;
            try {
                await execJj(['squash', '-r', commit.commitId, '-d', '@'], getRepoRoot());
                showSuccessAndRefresh('Squashed into current commit');
            } catch (e: any) {
                vscode.window.showErrorMessage(`Failed: ${e.message}`);
            }
        }),
        vscode.commands.registerCommand('jj.log.abandon', async () => {
            const commit = await getSelectedCommit();
            if (!commit) return;
            if (await vscode.window.showWarningMessage(`Abandon commit ${commit.commitId.substring(0, 8)}?`, { modal: true }, 'Abandon') !== 'Abandon') return;
            try {
                await execJj(['abandon', commit.commitId], getRepoRoot());
                showSuccessAndRefresh('Abandoned commit');
            } catch (e: any) {
                vscode.window.showErrorMessage(`Failed: ${e.message}`);
            }
        }),
        vscode.commands.registerCommand('jj.log.openPatch', async () => {
            const commit = await getSelectedCommit();
            if (!commit) return;
            try {
                const patch = await execJj(['show', '-r', commit.commitId, '--color=never'], getRepoRoot());
                const doc = await vscode.workspace.openTextDocument({ content: patch, language: 'diff' });
                await vscode.window.showTextDocument(doc);
            } catch (e: any) {
                vscode.window.showErrorMessage(`Failed: ${e.message}`);
            }
        })
    );

    context.subscriptions.push(
        vscode.commands.registerCommand('jj.log.bookmark', async () => {
            const commit = await getSelectedCommit();
            if (!commit) return;
            const action = await vscode.window.showQuickPick([
                { label: 'Create bookmark here', id: 'create' },
                { label: 'Move existing bookmark', id: 'move' },
                { label: 'Rename bookmark', id: 'rename' },
                { label: 'Delete bookmark', id: 'delete' }
            ], { placeHolder: 'Select bookmark action' });
            if (!action) return;
            const repoRoot = getRepoRoot();
            try {
                if (action.id === 'create') {
                    const name = await vscode.window.showInputBox({ prompt: 'Bookmark name' });
                    if (!name) return;
                    await execJj(['bookmark', 'set', name, '-r', commit.commitId], repoRoot);
                    showSuccessAndRefresh(`Created bookmark: ${name}`);
                } else if (action.id === 'move') {
                    const bookmarks = await getBookmarks(repoRoot);
                    if (bookmarks.length === 0) { vscode.window.showErrorMessage('No bookmarks found'); return; }
                    const bookmark = await vscode.window.showQuickPick(bookmarks, { placeHolder: 'Select bookmark to move' });
                    if (!bookmark) return;
                    await execJj(['bookmark', 'set', bookmark, '-r', commit.commitId], repoRoot);
                    showSuccessAndRefresh(`Moved bookmark: ${bookmark}`);
                } else if (action.id === 'rename') {
                    const bookmarks = await getBookmarks(repoRoot);
                    if (bookmarks.length === 0) { vscode.window.showErrorMessage('No bookmarks found'); return; }
                    const oldName = await vscode.window.showQuickPick(bookmarks, { placeHolder: 'Select bookmark to rename' });
                    if (!oldName) return;
                    const newName = await vscode.window.showInputBox({ prompt: 'New bookmark name', value: oldName });
                    if (!newName) return;
                    await execJj(['bookmark', 'rename', oldName, newName], repoRoot);
                    showSuccessAndRefresh(`Renamed bookmark: ${oldName} → ${newName}`);
                } else if (action.id === 'delete') {
                    const bookmarks = await getBookmarks(repoRoot);
                    if (bookmarks.length === 0) { vscode.window.showErrorMessage('No bookmarks found'); return; }
                    const bookmark = await vscode.window.showQuickPick(bookmarks, { placeHolder: 'Select bookmark to delete' });
                    if (!bookmark) return;
                    if (await vscode.window.showWarningMessage(`Delete bookmark "${bookmark}"?`, { modal: true }, 'Delete') !== 'Delete') return;
                    await execJj(['bookmark', 'delete', bookmark], repoRoot);
                    showSuccessAndRefresh(`Deleted bookmark: ${bookmark}`);
                }
            } catch (e: any) {
                vscode.window.showErrorMessage(`Failed: ${e.message}`);
            }
        }),
        vscode.commands.registerCommand('jj.log.fetch', async () => {
            try {
                await execJj(['git', 'fetch'], getRepoRoot());
                showSuccessAndRefresh('Fetched from remote');
            } catch (e: any) {
                vscode.window.showErrorMessage(`Failed: ${e.message}`);
            }
        }),
        vscode.commands.registerCommand('jj.log.push', async () => {
            const commit = await getSelectedCommit();
            if (!commit) return;
            let bookmarkName: string | undefined;
            if (commit.bookmarks.length === 1) {
                bookmarkName = commit.bookmarks[0];
            } else if (commit.bookmarks.length > 1) {
                bookmarkName = await vscode.window.showQuickPick(commit.bookmarks, { placeHolder: 'Select bookmark to push' });
            } else {
                const bookmarks = await getBookmarks(getRepoRoot());
                if (bookmarks.length === 0) { vscode.window.showErrorMessage('No bookmarks found'); return; }
                bookmarkName = await vscode.window.showQuickPick(bookmarks, { placeHolder: 'Select bookmark to push' });
            }
            if (!bookmarkName) return;
            try {
                await execJj(['git', 'push', '-b', bookmarkName], getRepoRoot());
                vscode.window.showInformationMessage(`Pushed bookmark: ${bookmarkName}`);
            } catch (e: any) {
                vscode.window.showErrorMessage(`Failed: ${e.message}`);
            }
        }),
        vscode.commands.registerCommand('jj.log.refresh', async () => {
            logProvider.refresh();
            setTimeout(() => logProvider.restoreCursorPosition(), 100);
        })
    );
}

function getRepoRoot(): string {
    const root = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
    if (!root) throw new Error('No workspace folder open');
    return root;
}

async function getSelectedCommit() {
    const editor = vscode.window.activeTextEditor;
    if (!editor || editor.document.uri.scheme !== 'jj') {
        vscode.window.showErrorMessage('Please open the JJ log view first');
        return undefined;
    }
    const commit = logProvider.getCommitAtLine(editor.selection.active.line);
    if (!commit) {
        vscode.window.showErrorMessage('No commit selected');
        return undefined;
    }
    return commit;
}

function showSuccessAndRefresh(message: string): void {
    vscode.window.showInformationMessage(message);
    logProvider.refresh();
    setTimeout(() => logProvider.restoreCursorPosition(), 100);
}

async function openGitHubPermalink(useMain: boolean): Promise<void> {
    const editor = vscode.window.activeTextEditor;
    if (!editor) {
        vscode.window.showErrorMessage('No active editor found');
        return;
    }
    if (editor.document.isUntitled) {
        vscode.window.showErrorMessage('The current file is not saved');
        return;
    }
    try {
        await vscode.window.withProgress(
            { location: vscode.ProgressLocation.Notification, title: 'Generating GitHub permalink...', cancellable: false },
            async () => {
                await vscode.env.openExternal(vscode.Uri.parse(await generatePermalink(editor, useMain)));
            }
        );
    } catch (e: any) {
        vscode.window.showErrorMessage(`Failed: ${e.message || 'Unknown error'}`);
    }
}

export function deactivate() {}

