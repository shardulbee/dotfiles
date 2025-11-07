import * as vscode from 'vscode';
import { generatePermalink } from './permalink';
import { JjLogProvider } from './jjLogProvider';
import { execJj, getBookmarks } from './jjUtils';

const LOG_URI = vscode.Uri.parse('jj://log');
let logProvider: JjLogProvider;

/**
 * Activate the extension
 */
export function activate(context: vscode.ExtensionContext) {
    console.log('TurboCode extension is now active');

    // Register the "Open GitHub Permalink" command
    const openPermalinkCommand = vscode.commands.registerCommand(
        'turbocode.github.openPermalink',
        async () => {
            await openGitHubPermalink(false);
        }
    );

    // Register the "Open GitHub Permalink on Main" command
    const openPermalinkOnMainCommand = vscode.commands.registerCommand(
        'turbocode.github.openPermalinkOnMain',
        async () => {
            await openGitHubPermalink(true);
        }
    );

    // Register JJ log provider
    logProvider = new JjLogProvider();
    const registration = vscode.workspace.registerTextDocumentContentProvider('jj', logProvider);
    context.subscriptions.push(registration);

    // Register JJ commands
    registerJjCommands(context);

    context.subscriptions.push(openPermalinkCommand);
    context.subscriptions.push(openPermalinkOnMainCommand);
}

/**
 * Register all JJ log commands
 */
function registerJjCommands(context: vscode.ExtensionContext): void {
    // Open log view
    context.subscriptions.push(
        vscode.commands.registerCommand('jj.log.open', async () => {
            const doc = await vscode.workspace.openTextDocument(LOG_URI);
            await vscode.window.showTextDocument(doc, { preview: false });
        })
    );

    // Toggle expand
    context.subscriptions.push(
        vscode.commands.registerCommand('jj.log.toggleExpand', async () => {
            const editor = vscode.window.activeTextEditor;
            if (!editor || editor.document.uri.scheme !== 'jj') {
                return;
            }

            const line = editor.selection.active.line;
            const commit = logProvider.getCommitAtLine(line);
            if (commit) {
                logProvider.toggleExpand(commit.commitId);
            }
        })
    );

    // Edit/checkout
    context.subscriptions.push(
        vscode.commands.registerCommand('jj.log.edit', async () => {
            const commit = await getSelectedCommit();
            if (!commit) return;

            try {
                await execJj(['edit', '-r', commit.commitId]);
                await showSuccessAndRefresh('Checked out commit');
            } catch (error: any) {
                await showError(`Failed to checkout: ${error.message}`);
            }
        })
    );

    // Describe
    context.subscriptions.push(
        vscode.commands.registerCommand('jj.log.describe', async () => {
            const commit = await getSelectedCommit();
            if (!commit) return;

            const message = await vscode.window.showInputBox({
                prompt: 'Enter commit message',
                value: commit.summary
            });

            if (!message) return;

            try {
                await execJj(['describe', '-r', commit.commitId, '-m', message]);
                await showSuccessAndRefresh('Updated commit message');
            } catch (error: any) {
                await showError(`Failed to describe: ${error.message}`);
            }
        })
    );

    // Rebase
    context.subscriptions.push(
        vscode.commands.registerCommand('jj.log.rebase', async () => {
            const commit = await getSelectedCommit();
            if (!commit) return;

            const dest = await vscode.window.showInputBox({
                prompt: 'Rebase onto (revision)',
                placeHolder: '@, main, or commit ID'
            });

            if (!dest) return;

            try {
                await execJj(['rebase', '-r', commit.commitId, '-d', dest]);
                await showSuccessAndRefresh('Rebased commit');
            } catch (error: any) {
                await showError(`Failed to rebase: ${error.message}`);
            }
        })
    );

    // Squash
    context.subscriptions.push(
        vscode.commands.registerCommand('jj.log.squash', async () => {
            const commit = await getSelectedCommit();
            if (!commit) return;

            try {
                await execJj(['squash', '-r', commit.commitId, '-d', '@']);
                await showSuccessAndRefresh('Squashed into current commit');
            } catch (error: any) {
                await showError(`Failed to squash: ${error.message}`);
            }
        })
    );

    // Abandon
    context.subscriptions.push(
        vscode.commands.registerCommand('jj.log.abandon', async () => {
            const commit = await getSelectedCommit();
            if (!commit) return;

            const confirmed = await vscode.window.showWarningMessage(
                `Abandon commit ${commit.commitId.substring(0, 8)}?`,
                { modal: true },
                'Abandon'
            );

            if (confirmed !== 'Abandon') return;

            try {
                await execJj(['abandon', commit.commitId]);
                await showSuccessAndRefresh('Abandoned commit');
            } catch (error: any) {
                await showError(`Failed to abandon: ${error.message}`);
            }
        })
    );

    // Open patch
    context.subscriptions.push(
        vscode.commands.registerCommand('jj.log.openPatch', async () => {
            const commit = await getSelectedCommit();
            if (!commit) return;

            try {
                const patch = await execJj(['show', '-r', commit.commitId, '--color=never']);
                const doc = await vscode.workspace.openTextDocument({
                    content: patch,
                    language: 'diff'
                });
                await vscode.window.showTextDocument(doc);
            } catch (error: any) {
                await showError(`Failed to show patch: ${error.message}`);
            }
        })
    );

    // Bookmark actions
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

            try {
                switch (action.id) {
                    case 'create': {
                        const name = await vscode.window.showInputBox({
                            prompt: 'Bookmark name'
                        });
                        if (!name) return;
                        await execJj(['bookmark', 'set', name, '-r', commit.commitId]);
                        await showSuccessAndRefresh(`Created bookmark: ${name}`);
                        break;
                    }
                    case 'move': {
                        const bookmarks = await getBookmarks();
                        if (bookmarks.length === 0) {
                            await showError('No bookmarks found');
                            return;
                        }
                        const bookmark = await vscode.window.showQuickPick(bookmarks, {
                            placeHolder: 'Select bookmark to move'
                        });
                        if (!bookmark) return;
                        await execJj(['bookmark', 'set', bookmark, '-r', commit.commitId]);
                        await showSuccessAndRefresh(`Moved bookmark: ${bookmark}`);
                        break;
                    }
                    case 'rename': {
                        const bookmarks = await getBookmarks();
                        if (bookmarks.length === 0) {
                            await showError('No bookmarks found');
                            return;
                        }
                        const oldName = await vscode.window.showQuickPick(bookmarks, {
                            placeHolder: 'Select bookmark to rename'
                        });
                        if (!oldName) return;
                        const newName = await vscode.window.showInputBox({
                            prompt: 'New bookmark name',
                            value: oldName
                        });
                        if (!newName) return;
                        await execJj(['bookmark', 'rename', oldName, newName]);
                        await showSuccessAndRefresh(`Renamed bookmark: ${oldName} → ${newName}`);
                        break;
                    }
                    case 'delete': {
                        const bookmarks = await getBookmarks();
                        if (bookmarks.length === 0) {
                            await showError('No bookmarks found');
                            return;
                        }
                        const bookmark = await vscode.window.showQuickPick(bookmarks, {
                            placeHolder: 'Select bookmark to delete'
                        });
                        if (!bookmark) return;
                        const confirmed = await vscode.window.showWarningMessage(
                            `Delete bookmark "${bookmark}"?`,
                            { modal: true },
                            'Delete'
                        );
                        if (confirmed !== 'Delete') return;
                        await execJj(['bookmark', 'delete', bookmark]);
                        await showSuccessAndRefresh(`Deleted bookmark: ${bookmark}`);
                        break;
                    }
                }
            } catch (error: any) {
                await showError(`Failed: ${error.message}`);
            }
        })
    );

    // Fetch
    context.subscriptions.push(
        vscode.commands.registerCommand('jj.log.fetch', async () => {
            try {
                await execJj(['git', 'fetch']);
                await showSuccessAndRefresh('Fetched from remote');
            } catch (error: any) {
                await showError(`Failed to fetch: ${error.message}`);
            }
        })
    );

    // Push bookmark
    context.subscriptions.push(
        vscode.commands.registerCommand('jj.log.push', async () => {
            const commit = await getSelectedCommit();
            if (!commit) return;

            let bookmarkName: string | undefined;

            if (commit.bookmarks.length === 1) {
                bookmarkName = commit.bookmarks[0];
            } else if (commit.bookmarks.length > 1) {
                const selected = await vscode.window.showQuickPick(commit.bookmarks, {
                    placeHolder: 'Select bookmark to push'
                });
                if (!selected) return;
                bookmarkName = selected;
            } else {
                const allBookmarks = await getBookmarks();
                if (allBookmarks.length === 0) {
                    await showError('No bookmarks found');
                    return;
                }
                const selected = await vscode.window.showQuickPick(allBookmarks, {
                    placeHolder: 'Select bookmark to push'
                });
                if (!selected) return;
                bookmarkName = selected;
            }

            try {
                await execJj(['git', 'push', '-b', bookmarkName]);
                await showSuccess(`Pushed bookmark: ${bookmarkName}`);
            } catch (error: any) {
                await showError(`Failed to push: ${error.message}`);
            }
        })
    );

    // Refresh
    context.subscriptions.push(
        vscode.commands.registerCommand('jj.log.refresh', async () => {
            logProvider.refresh();
            setTimeout(() => {
                logProvider.restoreCursorPosition();
            }, 100);
        })
    );
}

/**
 * Get the currently selected commit from the log view
 */
async function getSelectedCommit() {
    const editor = vscode.window.activeTextEditor;
    if (!editor || editor.document.uri.scheme !== 'jj') {
        vscode.window.showErrorMessage('Please open the JJ log view first');
        return undefined;
    }

    const line = editor.selection.active.line;
    const commit = logProvider.getCommitAtLine(line);
    if (!commit) {
        vscode.window.showErrorMessage('No commit selected');
        return undefined;
    }

    return commit;
}

/**
 * Show success message and refresh log
 */
async function showSuccessAndRefresh(message: string): Promise<void> {
    vscode.window.showInformationMessage(message);
    logProvider.refresh();
    // Wait a bit for the content to update, then restore cursor
    setTimeout(() => {
        logProvider.restoreCursorPosition();
    }, 100);
}

/**
 * Show success message
 */
async function showSuccess(message: string): Promise<void> {
    vscode.window.showInformationMessage(message);
}

/**
 * Show error message
 */
async function showError(message: string): Promise<void> {
    vscode.window.showErrorMessage(message);
}

/**
 * Open a GitHub permalink in the browser
 */
async function openGitHubPermalink(useMain: boolean): Promise<void> {
    try {
        // Get the active editor
        const editor = vscode.window.activeTextEditor;
        if (!editor) {
            vscode.window.showErrorMessage('No active editor found');
            return;
        }

        // Check if the document is saved (has a file path)
        if (editor.document.isUntitled) {
            vscode.window.showErrorMessage('The current file is not saved');
            return;
        }

        // Show progress indicator
        await vscode.window.withProgress(
            {
                location: vscode.ProgressLocation.Notification,
                title: 'Generating GitHub permalink...',
                cancellable: false
            },
            async () => {
                // Generate the permalink
                const permalink = await generatePermalink(editor, useMain);

                // Open the permalink in the default browser
                const uri = vscode.Uri.parse(permalink);
                await vscode.env.openExternal(uri);
            }
        );
    } catch (error: any) {
        // Show error message
        const errorMessage = error.message || 'Unknown error occurred';
        vscode.window.showErrorMessage(`Failed to open GitHub permalink: ${errorMessage}`);
    }
}

/**
 * Deactivate the extension
 */
export function deactivate() {
    console.log('TurboCode extension is now deactivated');
}

