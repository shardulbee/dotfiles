import * as vscode from 'vscode';
import { generatePermalink } from './permalink';
import { JjLogProvider } from './jjLogProvider';
import { execJj, getBookmarks, isJjRepository, getWorkspaceRoot } from './jjUtils';

const LOG_URI = vscode.Uri.parse('jj://log/log');
let logProvider: JjLogProvider;
let outputChannel: vscode.OutputChannel;

/**
 * Activate the extension
 */
export function activate(context: vscode.ExtensionContext) {
    // Create output channel for debugging
    outputChannel = vscode.window.createOutputChannel('TurboCode');
    outputChannel.appendLine('=== TurboCode extension is now active ===');
    outputChannel.appendLine('Extension activation complete');
    outputChannel.show(true); // Show the output channel
    
    console.log('=== TurboCode extension is now active ===');
    console.log('Extension activation complete');

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
    // Set output channel for logging
    const { setOutputChannel } = require('./jjLogProvider');
    setOutputChannel(outputChannel);
    const registration = vscode.workspace.registerTextDocumentContentProvider('jj', logProvider);
    context.subscriptions.push(registration);
    
    // Clean up on deactivate
    context.subscriptions.push({
        dispose: () => {
            if (logProvider && typeof (logProvider as any).dispose === 'function') {
                (logProvider as any).dispose();
            }
        }
    });

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
            // Check if we're in a JJ repository
            const workspaceRoot = getWorkspaceRoot();
            if (!workspaceRoot) {
                vscode.window.showErrorMessage('No workspace folder open');
                return;
            }

            const isJjRepo = await isJjRepository();
            if (!isJjRepo) {
                vscode.window.showErrorMessage(`Not a JJ repository: ${workspaceRoot}`);
                return;
            }

            try {
                const doc = await vscode.workspace.openTextDocument(LOG_URI);
                const editor = await vscode.window.showTextDocument(doc, { 
                    preview: false,
                    viewColumn: vscode.ViewColumn.Active
                });
                
                // Set a custom title if possible
                if (editor) {
                    // The document should now have content from the provider
                    console.log('JJ log view opened, document URI:', doc.uri.toString());
                }
            } catch (error: any) {
                vscode.window.showErrorMessage(`Failed to open JJ log: ${error.message}`);
                console.error('Error opening JJ log:', error);
            }
        })
    );

    // Toggle expand
    context.subscriptions.push(
        vscode.commands.registerCommand('jj.log.toggleExpand', async () => {
            try {
                vscode.window.showInformationMessage('Toggle expand command called!');
                
                const editor = vscode.window.activeTextEditor;
                if (!editor) {
                    vscode.window.showWarningMessage('No active editor');
                    return;
                }
                
                if (editor.document.uri.scheme !== 'jj') {
                    vscode.window.showWarningMessage(`Wrong scheme: ${editor.document.uri.scheme}. Please open the JJ log view first (Cmd+Shift+J)`);
                    return;
                }

                const line = editor.selection.active.line;
                // Get all mapped lines for debugging
                const mappedLines = logProvider.getMappedLines();
                const isLoading = logProvider.isContentLoadingNow();
                console.log(`Toggle expand - Line ${line} (UI shows ${line + 1}), Mapped lines:`, mappedLines, `Is loading: ${isLoading}`);
                
                // Check if content is actually loaded by checking if we have mappings
                // The loading flag might be stuck, so we check mappings instead
                if (mappedLines.length === 0) {
                    if (isLoading) {
                        vscode.window.showWarningMessage(`Log view is still loading. Please wait a moment and try again.`);
                    } else {
                        vscode.window.showWarningMessage(`No commits mapped! The log view may not be fully loaded. Try refreshing (gR or Cmd+Shift+P > "JJ: Refresh Log").`);
                    }
                    return;
                }
                
                vscode.window.showInformationMessage(`Checking line ${line} (UI shows ${line + 1}). Found ${mappedLines.length} mapped commits.`);
                
                const commit = logProvider.getCommitAtLine(line);
                
                if (commit) {
                    const wasExpanded = logProvider.isExpanded(commit.commitId);
                    logProvider.toggleExpand(commit.commitId);
                    const status = wasExpanded ? 'Collapsed' : 'Expanded';
                    vscode.window.showInformationMessage(`JJ: ${status} commit ${commit.commitId.substring(0, 8)}`);
                } else {
                    vscode.window.showWarningMessage(`No commit found at line ${line}. Move cursor to a commit line.`);
                }
            } catch (error: any) {
                vscode.window.showErrorMessage(`Error in toggleExpand: ${error.message}`);
                console.error('Error in toggleExpand:', error);
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

