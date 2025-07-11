#!/usr/bin/env zsh
set -e

# Get username from environment or use default
USERNAME=${USERNAME:-$(whoami)}
HOME_DIR="/home/${USERNAME}"


function show_progress() {
    echo ""
    echo "=============================================="
    show_message "$1"
    echo "=============================================="
    echo ""
}

function show_message() {
    echo "🔹 $1"
}

function show_success() {
    echo -e "\033[32m✅ $1\033[0m"
}

function show_error() {
    echo -e "\033[31m❌ $1\033[0m"
}

function show_warning() {
    echo -e "\033[33m⚠️ $1\033[0m"
}

function install_fzf(){
    show_progress "Installing fzf..."
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/junegunn/fzf/master/install)" "" --bin
    if [ $? -eq 0 ]; then
        sudo mv "${HOME_DIR}/bin/fzf" "/usr/bin/fzf"
        sudo chmod +x "/usr/bin/fzf"
        show_success "fzf installed successfully"
    else
        show_error "fzf installation failed"
    fi
}

# Check if fzf version is at least 0.48.0
function check_fzf_version() {
    local fzf_ver=${"$(fzf --version)"#fzf }
    # fzf_ver is something like "0.62.0 (d226d841)"
    local major_ver=$(echo "$fzf_ver" | cut -d'.' -f1)
    local minor_ver=$(echo "$fzf_ver" | cut -d'.' -f2)
    local patch_ver=$(echo "$fzf_ver" | cut -d'.' -f3 | cut -d' ' -f1)
    if [[ "$major_ver" -gt 0 || ( "$major_ver" -eq 0 && "$minor_ver" -ge 48 ) ]]; then
        return 0  # Version is compatible
    else
        return 1  # Version is not compatible
    fi
}

# Main setup process
show_progress "Initializing environment for user: ${USERNAME}"

# Ensure we're in the user's home directory
cd "${HOME_DIR}"
rm -rf "${HOME_DIR}/.oh-my-zsh" 2>/dev/null || true
rm -rf "${HOME_DIR}/.p10k.zsh" 2>/dev/null || true
rm -rf "${HOME_DIR}/.zshrc" 2>/dev/null || true

show_message "Checking fzf version ..."
# Check if fzf is installed and get its version
if ! command -v fzf &> /dev/null; then
    show_warning "fzf is not installed. Proceeding with installation."
    install_fzf
else
    show_message "fzf is installed. Checking version..."
    if ! check_fzf_version; then
        show_warning "fzf version is not compatible. Proceeding with installation."
        install_fzf
    else
        show_success "fzf is already installed and compatible."
    fi
fi

# Install Oh-My-Zsh
show_message "Installing Oh-My-Zsh..."

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
if [ $? -eq 0 ]; then
    show_success "Oh-My-Zsh installed successfully"
else
    show_error "Oh-My-Zsh installation failed"
fi

mkdir -p "${HOME_DIR}/.oh-my-zsh/custom/plugins"
mkdir -p "${HOME_DIR}/.oh-my-zsh/custom/themes"
mkdir -p "${HOME_DIR}/.local/bin"

# Install Powerlevel10k theme
show_progress "Installing Powerlevel10k theme..."
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${HOME_DIR}/.oh-my-zsh/custom/themes/powerlevel10k
if [ $? -eq 0 ]; then
    show_success "Powerlevel10k theme installed successfully"
else
    show_error "Powerlevel10k installation failed"
fi

# Install ZSH plugins
show_progress "Installing ZSH plugins..."
if [ ! -d "${HOME_DIR}/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]; then
    git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git "${HOME_DIR}/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
    if [ $? -eq 0 ]; then
        show_success "zsh-autosuggestions plugin installed successfully"
    else
        show_error "zsh-autosuggestions installation failed"
    fi
fi

if [ ! -d "${HOME_DIR}/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]; then
    git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git "${HOME_DIR}/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
    if [ $? -eq 0 ]; then
        show_success "zsh-syntax-highlighting plugin installed successfully"
    else
        show_error "zsh-syntax-highlighting installation failed"
    fi
fi

if [ ! -d "${HOME_DIR}/.oh-my-zsh/custom/plugins/zsh-history-substring-search" ]; then
    git clone --depth=1 https://github.com/zsh-users/zsh-history-substring-search.git "${HOME_DIR}/.oh-my-zsh/custom/plugins/zsh-history-substring-search"
    if [ $? -eq 0 ]; then
        show_success "zsh-history-substring-search plugin installed successfully"
    else
        show_error "zsh-history-substring-search installation failed"
    fi
fi

if [ ! -d "${HOME_DIR}/.oh-my-zsh/custom/plugins/zsh-autocomplete" ]; then
    git clone --depth=1 https://github.com/marlonrichert/zsh-autocomplete.git "${HOME_DIR}/.oh-my-zsh/custom/plugins/zsh-autocomplete"
    if [ $? -eq 0 ]; then
        show_success "zsh-autocomplete plugin installed successfully"
    else
        show_error "zsh-autocomplete installation failed"
    fi
fi

# Create ZSH configuration files if they don't exist or if we're forcing regeneration
show_progress "Creating .zshrc configuration..."
    
# Create .zshrc file
cat > "${HOME_DIR}/.zshrc" << 'EOL'
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

# Uncomment the following line to display red dots whilst waiting for completion.
COMPLETION_WAITING_DOTS="true"

# Standard plugins
plugins=(
  git
  zsh-autocomplete
  zsh-autosuggestions
  zsh-syntax-highlighting
  zsh-history-substring-search
  fzf
  docker
  sudo
  command-not-found
)

source $ZSH/oh-my-zsh.sh

# User configuration
export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nano'
fi

# Source Powerlevel10k configuration
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# Add local bin to PATH
[[ -d $HOME/.local/bin ]] && export PATH="$HOME/.local/bin:$PATH"

# Aliases
alias rawls="/bin/ls"
alias ls='exa --icons --group-directories-first'
alias ll='ls -lah'
alias la='ls -al'
alias l='ls -lah'
alias grep='grep --color=auto'
alias cl='clear'
alias ..='cd ..'
alias ...='cd ../..'

# If zoxide is installed, initialize it
if command -v zoxide &> /dev/null; then
    eval "$(zoxide init zsh)"
fi
EOL

show_success ".zshrc created successfully"

# Create the Powerlevel10k configuration file
if [ ! -f "${HOME_DIR}/.p10k.zsh" ]; then
    show_progress "Creating Powerlevel10k configuration..."
    
    cat > "${HOME_DIR}/.p10k.zsh" << 'EOL'
# Generated by Powerlevel10k configuration wizard
# Basic configuration to get a nice-looking prompt immediately
# For customization, see: https://github.com/romkatv/powerlevel10k

'builtin' 'local' '-a' 'p10k_config_opts'
[[ ! -o 'aliases'         ]] || p10k_config_opts+=('aliases')
[[ ! -o 'sh_glob'         ]] || p10k_config_opts+=('sh_glob')
[[ ! -o 'no_brace_expand' ]] || p10k_config_opts+=('no_brace_expand')
'builtin' 'setopt' 'no_aliases' 'no_sh_glob' 'brace_expand'

() {
  emulate -L zsh -o extended_glob

  # Unset all configuration options. This allows you to apply configuration changes without
  # restarting zsh. Edit ~/.p10k.zsh and type `source ~/.p10k.zsh`.
  unset -m '(POWERLEVEL9K_*|DEFAULT_USER)~POWERLEVEL9K_GITSTATUS_DIR'

  # Zsh >= 5.1 is required.
  autoload -Uz is-at-least && is-at-least 5.1 || return

  # Left prompt segments.
  typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
    os_icon                 # OS icon
    dir                     # current directory
    vcs                     # git status
  )

  # Right prompt segments.
  typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(
    status                  # exit code of the last command
    command_execution_time  # duration of the last command
    background_jobs         # presence of background jobs
    time                    # current time
  )

  # Basic style settings
  typeset -g POWERLEVEL9K_MODE=nerdfont-v3
  typeset -g POWERLEVEL9K_PROMPT_ON_NEWLINE=true
  typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=true
  typeset -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX=""
  typeset -g POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX="%F{blue}❯%f "

  typeset -g POWERLEVEL9K_OS_ICON_FOREGROUND=232
  typeset -g POWERLEVEL9K_OS_ICON_BACKGROUND=7
  typeset -g POWERLEVEL9K_DIR_FOREGROUND=254
  typeset -g POWERLEVEL9K_DIR_FOREGROUND=254

  typeset -g POWERLEVEL9K_VCS_CLEAN_BACKGROUND=2
  typeset -g POWERLEVEL9K_VCS_MODIFIED_BACKGROUND=3
  typeset -g POWERLEVEL9K_VCS_UNTRACKED_BACKGROUND=2
  typeset -g POWERLEVEL9K_VCS_CONFLICTED_BACKGROUND=3
  typeset -g POWERLEVEL9K_VCS_LOADING_BACKGROUND=8

  # Enable OK_PIPE, ERROR_PIPE and ERROR_SIGNAL status states to allow us to enable, disable and
  # style them independently from the regular OK and ERROR state.
  typeset -g POWERLEVEL9K_STATUS_EXTENDED_STATES=true

  # Status on success. No content, just an icon. No need to show it if prompt_char is enabled as
  # it will signify success by turning green.
  typeset -g POWERLEVEL9K_STATUS_OK=true
  typeset -g POWERLEVEL9K_STATUS_OK_VISUAL_IDENTIFIER_EXPANSION='✔'
  typeset -g POWERLEVEL9K_STATUS_OK_FOREGROUND=2
  typeset -g POWERLEVEL9K_STATUS_OK_BACKGROUND=0

  # Status when some part of a pipe command fails but the overall exit status is zero. It may look
  # like this: 1|0.
  typeset -g POWERLEVEL9K_STATUS_OK_PIPE=true
  typeset -g POWERLEVEL9K_STATUS_OK_PIPE_VISUAL_IDENTIFIER_EXPANSION='✔'
  typeset -g POWERLEVEL9K_STATUS_OK_PIPE_FOREGROUND=2
  typeset -g POWERLEVEL9K_STATUS_OK_PIPE_BACKGROUND=0

  # Status when it's just an error code (e.g., '1'). No need to show it if prompt_char is enabled as
  # it will signify error by turning red.
  typeset -g POWERLEVEL9K_STATUS_ERROR=true
  typeset -g POWERLEVEL9K_STATUS_ERROR_VISUAL_IDENTIFIER_EXPANSION='✘'
  typeset -g POWERLEVEL9K_STATUS_ERROR_FOREGROUND=3
  typeset -g POWERLEVEL9K_STATUS_ERROR_BACKGROUND=1

  # Status when the last command was terminated by a signal.
  typeset -g POWERLEVEL9K_STATUS_ERROR_SIGNAL=true
  # Use terse signal names: "INT" instead of "SIGINT(2)".
  typeset -g POWERLEVEL9K_STATUS_VERBOSE_SIGNAME=false
  typeset -g POWERLEVEL9K_STATUS_ERROR_SIGNAL_VISUAL_IDENTIFIER_EXPANSION='✘'
  typeset -g POWERLEVEL9K_STATUS_ERROR_SIGNAL_FOREGROUND=3
  typeset -g POWERLEVEL9K_STATUS_ERROR_SIGNAL_BACKGROUND=1

  # Execution time
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND=0
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_BACKGROUND=3
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_PRECISION=3
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_THRESHOLD=0

  # Time format
  typeset -g POWERLEVEL9K_TIME_FORMAT="%D{%H:%M:%S}"

  # VCS CONFIG
  typeset -g POWERLEVEL9K_VCS_CLEAN_FOREGROUND=76
  typeset -g POWERLEVEL9K_VCS_MODIFIED_FOREGROUND=178
  typeset -g POWERLEVEL9K_VCS_UNTRACKED_FOREGROUND=176

  # Transient prompt
  typeset -g POWERLEVEL9K_TRANSIENT_PROMPT=same-dir

  # Instant prompt mode
  typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet

  # Hot reload
  typeset -g POWERLEVEL9K_DISABLE_HOT_RELOAD=false
}

(( ${#p10k_config_opts} )) && setopt ${p10k_config_opts[@]}
'builtin' 'unset' 'p10k_config_opts'
EOL
    show_success "Powerlevel10k configuration created"
else
    show_success "Powerlevel10k configuration already exists"
fi

# Create a .gitconfig with some default settings
show_progress "Creating git configuration..."
    
cat > "${HOME_DIR}/.gitconfig" << EOL
[user]
    name = ${USERNAME}
    email = ${USERNAME}@example.com

[color]
    ui = auto

[core]
    editor = vim
    autocrlf = input

[alias]
    st = status
    co = checkout
    ci = commit
    br = branch
    lg = log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative
EOL
show_success "Git configuration created"

# Set correct permissions
chown -R ${USERNAME}:${USERNAME} "${HOME_DIR}"
chmod -R 755 "${HOME_DIR}/.oh-my-zsh" 2>/dev/null || true

show_progress "Finishing up..."
show_success "Environment initialization complete for user: ${USERNAME}"
