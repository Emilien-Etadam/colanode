import { Notification } from 'electron';

import { eventBus } from '@colanode/client/lib';
import { AppService } from '@colanode/client/services';
import { createDebugger, getNodeModel } from '@colanode/core';

const debug = createDebugger('desktop:notifications');

export class AppNotifications {
  private readonly app: AppService;

  constructor(app: AppService) {
    this.app = app;
  }

  public init() {
    debug('Initializing notifications service');

    eventBus.subscribe(async (event) => {
      if (event.type === 'workspace.mention.received') {
        await this.handleMentionReceived(event);
      }
    });
  }

  private async handleMentionReceived(event: {
    type: 'workspace.mention.received';
    accountId: string;
    workspaceId: string;
    nodeId: string;
    mentionedUserId: string;
    mentionId: string;
    rootId: string;
  }) {
    debug(`Handling mention received for node ${event.nodeId}`);

    try {
      const account = this.app.getAccount(event.accountId);
      if (!account) {
        debug(`Account ${event.accountId} not found`);
        return;
      }

      const workspace = account.getWorkspace(event.workspaceId);
      if (!workspace) {
        debug(`Workspace ${event.workspaceId} not found`);
        return;
      }

      // Fetch the node that contains the mention
      const node = await workspace.database
        .selectFrom('nodes')
        .selectAll()
        .where('id', '=', event.nodeId)
        .executeTakeFirst();

      if (!node) {
        debug(`Node ${event.nodeId} not found`);
        return;
      }

      // Fetch the author of the message
      const author = await workspace.database
        .selectFrom('users')
        .selectAll()
        .where('id', '=', node.created_by)
        .executeTakeFirst();

      const authorName = author?.name || 'Someone';

      // Get the node model to extract content
      const model = getNodeModel(node.type);
      let messagePreview = 'You have been mentioned';

      // Try to extract a text preview from the node
      if (node.attributes && typeof node.attributes === 'object') {
        const attributes = node.attributes as any;
        if (attributes.content) {
          // Extract first text from content blocks
          const blocks = attributes.content;
          for (const blockId of Object.keys(blocks)) {
            const block = blocks[blockId];
            if (block.content && Array.isArray(block.content)) {
              const textLeafs = block.content.filter(
                (leaf: any) => leaf.type === 'text' && leaf.text
              );
              if (textLeafs.length > 0) {
                messagePreview = textLeafs
                  .map((leaf: any) => leaf.text)
                  .join('')
                  .substring(0, 100);
                break;
              }
            }
          }
        }
      }

      // Get workspace name for context
      const workspaceName = workspace.workspace.name;

      // Show the notification
      const notification = new Notification({
        title: `${authorName} mentioned you in ${workspaceName}`,
        body: messagePreview,
        silent: false,
        timeoutType: 'default',
      });

      notification.on('click', () => {
        debug(`Notification clicked for node ${event.nodeId}`);
        // TODO: Navigate to the message when clicked
        // This would require integration with the UI layer
      });

      notification.show();

      debug(
        `Notification shown for mention in node ${event.nodeId} from ${authorName}`
      );
    } catch (error) {
      debug(`Error handling mention notification: ${error}`);
    }
  }
}
