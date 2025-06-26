# Debian Development Container

A customizable Debian-based Docker development environment with ZSH, Oh-My-Zsh, and Powerlevel10k. This project provides a ready-to-use development container that can be accessed via `docker exec` and comes with a fully configured shell environment.

## Features

- Debian stable base image (Bookworm)
- Customizable username (defaults to "developer")
- ZSH with Oh-My-Zsh and Powerlevel10k theme
- Common development and system tools pre-installed
- Ability to add custom packages during build
- Built-in retry mechanisms for package installation
- Multiple Debian mirrors for improved accessibility
- Configurable network settings (host network usage for build)
- Support for specifying volumes between host and container
- Passwordless sudo access
- Git configuration
- Useful aliases and plugins
- Persistent container for development work

## Prerequisites

- Docker installed and running on your host system
- Basic familiarity with Docker commands
- Bash shell (for running the build script)

## Quick Start

1. Clone or download this repository
2. Make the build script executable:
   ```bash
   chmod +x build.sh
   ```
3. Build the default container (uses host network to work with proxies/tunnels):
   ```bash
   ./build.sh
   ```
4. Run the container (with optional volume mounting):
   ```bash
   docker run -it --network host --name devcontainer -v $(pwd)/your/host/directory:/home/developer/your/container/directory debian-dev:latest
   ```
5. For subsequent access to a running container:
   ```bash
   docker exec -it devcontainer zsh
   ```

> **Note**: If you're behind a proxy or using tunneling software like nekoray-tun, the build process will use your host's network configuration, making it work in restricted network environments.

## Customization Options

### Custom Username

Build with a specific username:
```bash
./build.sh --username john
```

### Network Configuration

Run the container with a specific network setting (default is "host"):
```bash
./build.sh --network host
```

Specify a different Docker network, such as "bridge":
```bash
./build.sh --network bridge
```

### Additional Packages

Install extra packages during build (comma-separated list):
```bash
./build.sh --packages "nodejs,npm,python3,python3-pip"
```

### Custom Tag

Specify a custom image tag:
```bash
./build.sh --tag my-debian-dev:1.0
```

### Combined Options

You can combine all options:
```bash
./build.sh --username developer --packages "nodejs,npm,python3" --tag dev-env:latest --network bridge
```

## Example Configurations

### Node.js Development Environment
```bash
./build.sh --username nodedev --packages "nodejs,npm,yarn" --tag node-dev:latest
```

### Python Development Environment
```bash
./build.sh --username pydev --packages "python3,python3-pip,python3-venv" --tag python-dev:latest
```

### Full Stack Development
```bash
./build.sh --username fullstack --packages "nodejs,npm,python3,postgresql-client" --tag fullstack:latest
```

## Included Tools and Packages

### Base Packages
- git
- curl
- wget
- zsh
- sudo
- locales
- ca-certificates
- gnupg
- apt-transport-https
- fonts-powerline
- less
- nano
- vim
- htop
- procps
- net-tools
- iputils-ping
- dnsutils

### ZSH Plugins
- git
- docker
- sudo
- history
- command-not-found
- zsh-autosuggestions
- zsh-syntax-highlighting
## Network and Volume Configuration

### Build-time Network Features

- **Host Network Usage**: The `build.sh` script uses `--network=host` for Docker build, allowing it to work with proxies and tunnels like nekoray-tun.
- **Multiple Debian Mirrors**: The Dockerfile configures multiple Debian mirrors (including regional ones) for better accessibility.
- **Retry Mechanism**: Package installation includes a built-in retry system that automatically retries failed downloads.

### Volume and Runtime Network Options

The container can use different network modes and specify volumes when running:

#### Network Modes
- **host**: Use the host machine's network stack directly (default).
- **bridge**: Use Docker's default bridge network.
- **custom**: If you have a custom network setup, specify its name.
  
  To run the container with a specified network, use:
  ```bash
  docker run --network <network-mode> -it --name devcontainer debian-dev:latest
  ```

#### Volume Mounting
  
  You can map directories between your host and the container to persist data:
  ```bash
  docker run -it --name devcontainer -v /host/path:/container/path debian-dev:latest
  ```

## Persistent Development Environment

For a persistent development environment, you can:

1. Create a named volume:
   ```bash
   docker volume create dev-home
   ```

2. Run the container with the volume mounted to the user's home:
   ```bash
   docker run -it --name devcontainer -v dev-home:/home/developer debian-dev:latest
   ```

3. Your work will persist even if the container is stopped and restarted.

## File Structure

```
/
├── Dockerfile         # Defines the Docker image
├── inituser.sh        # Sets up user environment inside container
├── build.sh           # Script to build the Docker image
└── README.md          # This documentation
```

## Troubleshooting

### Container Won't Start
If the container fails to start, check:
- Docker service is running
- You have proper permissions to run Docker commands
- No port conflicts if you're exposing ports

### ZSH Configuration Issues
If you encounter ZSH configuration issues:
- Ensure the container was built successfully
- Check if Oh-My-Zsh was installed correctly
- Verify the Powerlevel10k theme is available
- Try rebuilding the container with `--no-cache` option:
  ```bash
  docker build --no-cache --build-arg USERNAME="$USERNAME" -t "$TAG" .
  ```

### Font Issues
If Powerlevel10k icons don't display correctly:
- Ensure your terminal uses a Nerd Font or a Powerline-compatible font
- Install a compatible font like "MesloLGS NF" or "Fira Code"

## Extending The Container

You can modify the Dockerfile and inituser.sh to add more functionality:
- Add more packages to the base installation
- Configure additional development tools
- Add custom dotfiles
- Set up project-specific requirements

## License

This project is open-source and available under the MIT License.

