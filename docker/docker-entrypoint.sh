#!/bin/sh
set -e

# Environment variable validation
if [ "$MCP_MODE" = "http" ] && [ -z "$AUTH_TOKEN" ] && [ -z "$AUTH_TOKEN_FILE" ]; then
    echo "ERROR: AUTH_TOKEN or AUTH_TOKEN_FILE is required for HTTP mode"
    exit 1
fi

# Validate AUTH_TOKEN_FILE if provided
if [ -n "$AUTH_TOKEN_FILE" ] && [ ! -f "$AUTH_TOKEN_FILE" ]; then
    echo "ERROR: AUTH_TOKEN_FILE specified but file not found: $AUTH_TOKEN_FILE"
    exit 1
fi

# Database initialization with file locking to prevent race conditions
if [ ! -f "/app/data/nodes.db" ]; then
    echo "Database not found. Initializing..."
    # Use a lock file to prevent multiple containers from initializing simultaneously
    (
        flock -x 200
        # Double-check inside the lock
        if [ ! -f "/app/data/nodes.db" ]; then
            echo "Initializing database..."
            cd /app && node dist/scripts/rebuild.js || {
                echo "ERROR: Database initialization failed"
                exit 1
            }
        fi
    ) 200>/app/data/.db.lock
fi

# Trap signals for graceful shutdown
# In stdio mode, don't output anything to stdout as it breaks JSON-RPC
if [ "$MCP_MODE" = "stdio" ]; then
    # Silent trap - no output at all
    trap 'kill -TERM $PID 2>/dev/null || true' TERM INT EXIT
else
    # In HTTP mode, output to stderr
    trap 'echo "Shutting down..." >&2; kill -TERM $PID 2>/dev/null' TERM INT EXIT
fi

# Execute the main command in background
# In stdio mode, use the wrapper for clean output
if [ "$MCP_MODE" = "stdio" ]; then
    # Debug: Log to stderr to check if wrapper exists
    if [ "$DEBUG_DOCKER" = "true" ]; then
        echo "MCP_MODE is stdio, checking for wrapper..." >&2
        ls -la /app/dist/mcp/stdio-wrapper.js >&2 || echo "Wrapper not found!" >&2
    fi
    
    if [ -f "/app/dist/mcp/stdio-wrapper.js" ]; then
        # Use the stdio wrapper for clean JSON-RPC output
        exec node /app/dist/mcp/stdio-wrapper.js
    else
        # Fallback: run with explicit environment
        exec env MCP_MODE=stdio DISABLE_CONSOLE_OUTPUT=true LOG_LEVEL=error node /app/dist/mcp/index.js
    fi
else
    # HTTP mode or other
    exec "$@"
fi