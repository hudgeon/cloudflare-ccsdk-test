export { ClaudeCodeSDK } from './container';

export default {
  async fetch(request: Request, env: any, ctx: any): Promise<Response> {
    try {
      // Get a specific container instance based on a simple hash
      // This ensures we don't create too many containers
      const id = env.CLAUDE_CODE_SDK.idFromName('claude-code-container');
      const container = env.CLAUDE_CODE_SDK.get(id);

      // Forward the request to the container
      return await container.fetch(request);
    } catch (error) {
      return new Response(`Worker error: ${error instanceof Error ? error.message : String(error)}`, {
        status: 500,
        headers: { 'Content-Type': 'text/plain' }
      });
    }
  },
};