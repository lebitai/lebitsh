export default {
  /**
   * @param {Request} request
   * @param {{ ASSETS: { fetch: (request: Request) => Promise<Response> } }} env
   * @param {any} ctx
   * @returns {Promise<Response>}
   */
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const path = url.pathname;

    // Serve install.sh for the root path
    if (path === "/") {
      // Try to fetch install.sh from assets
      try {
        const installResponse = await env.ASSETS.fetch(new URL("/install.sh", url));
        const installScript = await installResponse.text();
        
        return new Response(installScript, {
          headers: {
            "Content-Type": "application/x-sh",
            "Content-Disposition": 'attachment; filename="install.sh"'
          }
        });
      } catch (e) {
        // Fallback response if install.sh is not found
        return new Response("#!/bin/bash\necho 'Install script not found'\nexit 1", {
          headers: {
            "Content-Type": "application/x-sh"
          }
        });
      }
    }

    // For all other paths, serve static assets
    return env.ASSETS.fetch(request);
  }
};