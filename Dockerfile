# Base Debian development environment with ZSH, Oh-My-Zsh, and Powerlevel10k
# With improved network resilience and retry mechanisms
FROM debian:bookworm-slim

# Add custom shell function for progress display
SHELL ["/bin/bash", "-c"]

# Build arguments
ARG USERNAME=developer
ARG EXTRA_PACKAGES=""
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Set non-interactive frontend to avoid prompts
ENV DEBIAN_FRONTEND=noninteractive

# Configure apt for better network resilience
RUN echo "==> Configuring apt for better network resilience..." && \
    echo 'Acquire::Retries "5";' > /etc/apt/apt.conf.d/80-retries && \
    echo 'APT::Acquire::Retries "5";' >> /etc/apt/apt.conf.d/80-retries && \
    echo 'Acquire::https::Timeout "30";' > /etc/apt/apt.conf.d/80-timeouts && \
    echo 'Acquire::http::Timeout "30";' >> /etc/apt/apt.conf.d/80-timeouts && \
    echo 'APT::Get::Assume-Yes "true";' > /etc/apt/apt.conf.d/80-assume-yes && \
    echo 'APT::Install-Recommends "false";' > /etc/apt/apt.conf.d/80-no-recommends && \
    echo 'Acquire::Check-Valid-Until "false";' > /etc/apt/apt.conf.d/80-no-check-valid

# Install base packages with retry logic
RUN set -e; \
    echo "==> Updating package lists..."; \
    # Define function for retrying apt commands (POSIX compatible syntax)
    apt_retry() { \
        local cmd="$@"; \
        local max_attempts=5; \
        local attempt=1; \
        until eval $cmd; do \
            echo "🔄 Command failed, retrying ($attempt/$max_attempts)..."; \
            sleep 3; \
            attempt=$((attempt + 1)); \
            if [ $attempt -gt $max_attempts ]; then \
                echo "❌ Failed after $max_attempts attempts"; \
                return 1; \
            fi; \
        done; \
        return 0; \
    }; \
    # Use the retry function for all apt operations
    apt_retry "apt-get clean"; \
    apt_retry "apt-get update"; \
    echo "==> Upgrading base system..."; \
    apt_retry "apt-get upgrade"; \
    echo "==> Installing base packages..."; \
    apt_retry "apt-get install \
    sudo \
    curl \
    wget \
    git \
    zsh \
    bat \
    zoxide \
    locales \
    exa \
    ca-certificates \
    gnupg \
    gnutls-bin \
    libcurl4-openssl-dev \
    apt-transport-https \
    fonts-powerline \
    less \
    nano \
    vim \
    neovim \
    htop \
    btop \
    procps \
    net-tools \
    iputils-ping \
    dnsutils"; \
    \
    # Install any extra packages specified by build arg
    if [ ! -z "$EXTRA_PACKAGES" ]; then \
        echo "==> Installing extra packages: $EXTRA_PACKAGES"; \
        apt_retry "apt-get install $EXTRA_PACKAGES"; \
    fi; \
    # Configure locale
    echo "==> Configuring en_US locale..."; \
    sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen; \
    dpkg-reconfigure --frontend=noninteractive locales; \
    update-locale LANG=en_US.UTF-8; \
    # Clean up
    echo "==> Cleaning up package cache..."; \
    apt-get autoremove; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*

# Set environment variables
ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

# Create user with sudo access
RUN echo "==> Creating user: $USERNAME..." && \
    groupadd --gid $USER_GID $USERNAME && \
    useradd --uid $USER_UID --gid $USER_GID -m $USERNAME && \
    echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME && \
    chmod 0440 /etc/sudoers.d/$USERNAME && \
    echo "==> User created successfully"

# Set up home directory
WORKDIR /home/$USERNAME

# Set user
USER $USERNAME

# Copy initialization script
COPY --chown=$USERNAME:$USERNAME inituser.sh /home/$USERNAME/inituser.sh
RUN echo "==> Running user initialization script..." && \
    chmod +x /home/$USERNAME/inituser.sh && \
    /home/$USERNAME/inituser.sh && \
    echo "==> User environment initialized successfully" && \
    rm /home/$USERNAME/inituser.sh

# Set working directory and default command
WORKDIR /home/$USERNAME
CMD ["zsh"]
