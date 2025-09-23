import { Container } from '@cloudflare/containers';

export class ClaudeCodeSDK extends Container {
  // Default port for the container
  defaultPort = 8080;

  // Set the timeout for sleeping the container after inactivity
  sleepAfter = "30m";

  // Environment variables to pass to the container
  env = {
    NODE_ENV: 'production',
    PORT: '8080'
  };

  // Enable internet access for the container
  enableInternet = true;

  constructor(ctx: any, env: any) {
    super(ctx, env);

    // Pass through environment variables from Worker to Container
    if (env.CLAUDE_CODE_OAUTH_TOKEN) {
      this.env.CLAUDE_CODE_OAUTH_TOKEN = env.CLAUDE_CODE_OAUTH_TOKEN;
    }
    if (env.CLAUDE_CODE_SDK_CONTAINER_API_KEY) {
      this.env.CLAUDE_CODE_SDK_CONTAINER_API_KEY = env.CLAUDE_CODE_SDK_CONTAINER_API_KEY;
    }
  }

  async fetch(request: Request): Promise<Response> {
    try {
      // Start the container and wait for it to be ready
      await this.startAndWaitForPorts();

      // Forward the request to the container
      return await this.containerFetch(request);
    } catch (error) {
      return new Response(`Container error: ${error instanceof Error ? error.message : String(error)}`, {
        status: 500,
        headers: { 'Content-Type': 'text/plain' }
      });
    }
  }
};