# docker-openclaw

A Docker image for running [OpenClaw](https://openclaw.ai) on umbrelOS.

## What is this?

This is a containerized version of OpenClaw with a web-based setup wizard. It provides:

- A simple setup UI to configure your API keys (Anthropic/OpenAI)
- Automatic gateway management
- Homebrew pre-installed for OpenClaw to install additional tools
- Persistent configuration and workspace storage

## What we changed from vanilla OpenClaw

### 1. Web-based setup wizard

Instead of requiring manual configuration, this image provides a web UI on first launch where you can enter your API key and select your preferred model.

### 2. Insecure HTTP mode enabled (`allowInsecureAuth: true`)

We disable OpenClaw's device pairing and HTTPS requirements. See the warning below for why this matters.

### 3. Automatic token injection

The proxy server automatically injects the gateway authentication token into all requests, so users don't need to manually authenticate after umbrelOS login.

### 4. Homebrew instead of apt

We replace `apt` and `apt-get` with a script that tells OpenClaw to use Homebrew. This is because:
- Homebrew installs to userspace and persists across container rebuilds
- apt packages are lost when the container is recreated
- OpenClaw can install tools it needs via `brew install` and they'll persist

## Why these changes?

umbrelOS provides its own authentication layer that protects all apps. When you access an app through umbrelOS, you've already authenticated. This means:

- We can skip OpenClaw's built-in device pairing (redundant behind umbrelOS auth)
- We can use HTTP instead of HTTPS (umbrelOS handles TLS termination)
- We can auto-inject tokens (the user already proved their identity to umbrelOS)

This creates a seamless experience where you just open the app and start using it.

---

## WARNING: Do NOT run this outside of umbrelOS

**This image is specifically designed for umbrelOS and removes important security features.**

### What could go wrong?

If you run this container outside of umbrelOS (or any environment without an authenticating reverse proxy):

1. **Anyone on your network can access OpenClaw** - There's no login screen or device pairing
2. **Your API keys are exposed** - Anyone who can reach the port can make API calls using your Anthropic/OpenAI keys
3. **Full system access** - OpenClaw is an AI agent that can run commands, read/write files, and access the network. An attacker could use it to compromise your system
4. **No audit trail** - Without device pairing, you can't tell who did what

### Why is it safe on umbrelOS?

umbrelOS puts an authentication proxy in front of all apps. You must log into your umbrelOS dashboard before you can access any app. This means:

- Only authenticated users can reach OpenClaw
- The network port isn't directly exposed
- umbrelOS handles user identity

### What if I want to run this elsewhere?

Don't use this image. Instead:

1. Install OpenClaw directly: `npm install -g openclaw`
2. Run `openclaw gateway` with proper authentication configured
3. Use HTTPS with device pairing enabled
4. See the [official OpenClaw docs](https://docs.openclaw.ai) for secure deployment options

---

## Usage (on umbrelOS)

This image is meant to be installed through the umbrelOS app store. If you're running it manually:

```yaml
services:
  openclaw:
    image: ghcr.io/lukechilds/docker-openclaw:latest
    ports:
      - "18789:18789"
    volumes:
      - ./data:/data
      - ./data/linuxbrew:/home/linuxbrew
```

## License

MIT
