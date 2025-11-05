import * as vscode from 'vscode';
import { generatePermalink } from './permalink';

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

    context.subscriptions.push(openPermalinkCommand);
    context.subscriptions.push(openPermalinkOnMainCommand);
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

