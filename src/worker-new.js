export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const path = url.pathname;
    const userAgent = request.headers.get("User-Agent") || "";
    
    console.log("Path:", path);
    console.log("User-Agent:", userAgent);
    
    // Check if it's a command line request
    const isCommandLineRequest = userAgent.toLowerCase().includes("curl") || 
                                userAgent.toLowerCase().includes("wget");
    
    // Module routes
    const modules = ['system', 'docker', 'dev', 'tools', 'mining'];
    const modulePath = path.slice(1).split('/')[0];
    
    // Simple installer script
    const installScript = `#!/bin/bash
# Lebit.sh Simple Installer
set -e

# Colors
RED='\\033[0;31m'
GREEN='\\033[0;32m'
YELLOW='\\033[1;33m'
NC='\\033[0m'

# Functions
info() { echo -e "[INFO] $1"; }
success() { echo -e "\${GREEN}[SUCCESS] $1\${NC}"; }
warning() { echo -e "\${YELLOW}[WARNING] $1\${NC}"; }
error() { echo -e "\${RED}[ERROR] $1\${NC}" >&2; }

# Check root
if [ "$(id -u)" -eq 0 ]; then
    BIN_DIR="/usr/local/bin"
else
    BIN_DIR="$HOME/.local/bin"
    mkdir -p "$BIN_DIR"
fi

# Download launcher
info "Downloading Lebit.sh launcher..."
LAUNCHER_URL="https://raw.githubusercontent.com/lebitai/lebitsh/main/src/launcher.sh"

if curl -fsSL "$LAUNCHER_URL" -o "$BIN_DIR/lebitsh"; then
    chmod +x "$BIN_DIR/lebitsh"
    success "Lebit.sh installed successfully!"
    echo ""
    info "Usage:"
    echo "  lebitsh              # Interactive menu"
    echo "  lebitsh system       # System management"
    echo "  lebitsh docker       # Docker management"
    echo "  lebitsh dev          # Development tools"
    echo "  lebitsh tools        # System utilities"
    echo "  lebitsh mining       # Mining tools"
    echo "  lebitsh help         # Show help"
    echo ""
    
    if [ "$(id -u)" -ne 0 ] && ! echo "$PATH" | grep -q "$BIN_DIR"; then
        warning "Add $BIN_DIR to your PATH:"
        echo "  echo 'export PATH=\\"$BIN_DIR:\\$PATH\\"' >> ~/.bashrc"
        echo "  source ~/.bashrc"
        echo ""
        info "Or run directly: $BIN_DIR/lebitsh"
    fi
else
    error "Failed to download launcher"
    exit 1
fi`;

    // Module installer generator
    const generateModuleScript = (module) => {
      return `#!/bin/bash
# Lebit.sh ${module} Module Quick Installer
set -e
echo "[INFO] Installing Lebit.sh and running ${module} module..."
if curl -fsSL https://lebit.sh/install | sh; then
    echo "[INFO] Running ${module} module..."
    if command -v lebitsh >/dev/null 2>&1; then
        lebitsh ${module}
    else
        for dir in /usr/local/bin $HOME/.local/bin; do
            if [ -f "$dir/lebitsh" ]; then
                "$dir/lebitsh" ${module}
                exit 0
            fi
        done
        echo "[ERROR] lebitsh not found. Please run 'lebitsh ${module}' manually."
        exit 1
    fi
else
    echo "[ERROR] Failed to install Lebit.sh"
    exit 1
fi`;
    };
    
    // Handle command line requests
    if (isCommandLineRequest) {
      // Module-specific installers
      if (modules.includes(modulePath)) {
        console.log(`Serving ${modulePath} module script`);
        return new Response(generateModuleScript(modulePath), {
          headers: {
            "Content-Type": "text/plain; charset=utf-8",
            "Cache-Control": "no-cache, no-store, must-revalidate"
          }
        });
      }
      
      // Main installer
      if (path === "/" || path === "/install" || path === "/install/") {
        console.log("Serving install script");
        return new Response(installScript, {
          headers: {
            "Content-Type": "text/plain; charset=utf-8",
            "Cache-Control": "no-cache, no-store, must-revalidate"
          }
        });
      }
    }
    
    // Handle browser requests
    if (!isCommandLineRequest) {
      if (modules.includes(modulePath)) {
        return Response.redirect(`${url.origin}/modules.html#${modulePath}`, 302);
      }
      
      if (path === "/install" || path === "/install/") {
        return new Response(installScript, {
          headers: {
            "Content-Type": "text/plain; charset=utf-8",
            "Content-Disposition": 'attachment; filename="install.sh"',
            "Cache-Control": "no-cache, no-store, must-revalidate"
          }
        });
      }
    }
    
    // Serve static assets
    console.log("Serving static assets for path:", path);
    return env.ASSETS.fetch(request);
  }
};