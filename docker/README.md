# Docker Build Updates for n8n MCP Server

## Overview

This directory contains updated Docker configurations for building the n8n MCP server with improved accuracy and additional AI capabilities.

## Recent Updates

### Build Improvements

The Docker build process has been significantly improved to address multiple issues in the original implementation:

- **Fixed build context and dependency management**: The previous Dockerfile had numerous issues with package resolution and build context that were never properly tested
- **Added proper multi-stage builds**: Optimized for both development and production environments
- **Improved layer caching**: Better utilization of Docker layer caching for faster rebuilds
- **Enhanced error handling**: More robust error handling during the build process

### AI Capabilities Enhancement

**Added n8n LangChain Integration**: The Docker build now includes n8n LangChain nodes to properly test and validate AI node functionality within the MCP server. This ensures that AI-related queries and operations work correctly when interfacing with the MCP server.

**⚠️ Image Size Impact**: Adding the LangChain package increases the Docker image size from ~400MB to ~1.6GB. While this addition enables AI node testing, the actual functionality and necessity of this integration is still under evaluation.

**Optimization Opportunity**: If you encounter issues with the LangChain integration or find it unnecessary for your use case, please consider creating an issue or pull request to remove this dependency and reduce the image size. The maintainer is open to feedback on whether this addition provides sufficient value to justify the 4x increase in image size.

### Author's Note

> **Disclaimer**: The original Dockerfile contained multiple critical errors and appeared to be written without proper testing or validation. The current maintainer has updated the build process with proper labels pointing to their Git repository for easier tracking and follow-up purposes. This is purely for maintenance and development transparency - no copyright infringement is intended.

## Usage

### MCP Server Configuration

To use this MCP server remotely, add the following configuration to your MCP client:

```json
{
  "mcpServers": {
    "n8n-remote": {
      "command": "npx",
      "args": [
        "-y",
        "mcp-remote",
        "https://[url]:[?port]/mcp",
        "--header",
        "Authorization: Bearer ${AUTH_TOKEN}"
      ],
      "env": {
        "AUTH_TOKEN": "[A Very Very Long Token]"
      }
    }
  }
}
```

### Configuration Parameters

- **`[url]`**: Replace with your server's URL or IP address
- **`[?port]`**: Replace with the port number (optional if using standard ports)
- **`[A Very Very Long Token]`**: Replace with your actual authentication token

### Building the Docker Image

```bash
# Build the image
docker build -t n8n-mcp-server .

# Run the container with environment variables
docker run -p 8080:8080 \
  -e AUTH_TOKEN="your-very-long-auth-token" \
  -e TRUST_PROXY="true" \
  -e N8N_API_URL="https://your-n8n-instance.com" \
  -e N8N_API_KEY="your-n8n-api-key" \
  n8n-mcp-server
```

### Using Docker Compose with Traefik (Recommended)

**Included Demo Configuration**: This repository includes a working `compose.yaml` file that demonstrates a production-ready setup with Traefik reverse proxy. This configuration has been tested and runs smoothly in production.

The included `compose.yaml` features:
- **Traefik Integration**: Automatic SSL certificates via Let's Encrypt
- **Production Ready**: Proper restart policies and user permissions
- **Environment Variables**: All required variables with sensible defaults
- **Volume Mounting**: Persistent data storage
- **Network Configuration**: External proxied network for Traefik

**Key Features of the Demo Setup:**
- Uses Traefik labels for automatic service discovery
- SSL/TLS termination with automatic certificate renewal
- Configurable domain and path routing
- Load balancer configuration for high availability

**To use the demo configuration:**

1. Copy the included `compose.yaml` to your deployment directory
2. Create a `.env` file with your environment variables:

```bash
AUTH_TOKEN=your-very-long-auth-token
N8N_API_URL=https://your-n8n-instance.com
N8N_API_KEY=your-n8n-api-key
TRUST_PROXY=true
PORT=3000
```

3. Update the Traefik labels in `compose.yaml` with your domain
4. Run the stack:

```bash
docker-compose up -d
```

**Note**: The demo uses an external Traefik network called `proxied`. Ensure your Traefik instance is configured with this network.

### Environment Variables

**Important Note**: Do NOT try to mount `.env` files into the container or copy it during build - it won't work. Instead, pass environment variables through docker-compose environment section or `-e` flags with `docker run`. Extract values from your `.env` file and pass them as environment variables.

**Pre-configured in Dockerfile**:
- `MCP_MODE`: Already set in the Dockerfile
- `USE_FIXED_HTTP`: Already set in the Dockerfile

**Required Environment Variables**:
- `AUTH_TOKEN`: Authentication token for MCP server access
- `PORT`: Server port (only if you want to change from default)
- `TRUST_PROXY`: Set to `true` if behind Cloudflare, Traefik, or other reverse proxy
- `N8N_API_URL`: n8n instance URL (required if you want MCP to manage n8n for you)
- `N8N_API_KEY`: n8n API key (required if you want MCP to manage n8n for you)

**Optional**:
- `NODE_ENV`: Environment mode (development/production)

## Testing AI Nodes

With the addition of n8n LangChain nodes, you can now test AI-related functionality:

1. Query available AI nodes through the MCP interface
2. Test AI workflow creation and execution
3. Validate AI tool integration capabilities
4. Verify LangChain node compatibility

## Support

For issues, improvements, or contributions, please refer to the main repository linked in the Docker labels.