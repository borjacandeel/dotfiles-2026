# Fish shell config - Rose Pine theme

# greeting
set fish_greeting ""

# aliases
alias ls='ls --color=auto'
alias ll='ls -la --color=auto'
alias la='ls -A --color=auto'
alias l='ls -CF --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

# git aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate'
alias gd='git diff'
alias gco='git checkout'
alias gb='git branch'

# pacman aliases
alias pacinstall='sudo pacman -S'
alias pacremove='sudo pacman -Rns'
alias pacsearch='pacman -Ss'
alias pacupdate='sudo pacman -Syu'
alias yayinstall='yay -S'

# vim
alias vim='nvim'
alias vi='nvim'

# starship prompt (if installed)
if command -v starship > /dev/null
    starship init fish | source
end

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH

# pnpm
set --export PNPM_HOME "$HOME/.local/share/pnpm"
if not string match --quiet $PNPM_HOME $PATH
    set --export PATH $PNPM_HOME $PATH
end

# Set PATH
set --export PATH $HOME/.local/bin $HOME/.cargo/bin $PATH

# Colors for ls
set -x LS_COLORS 'di=1;34:ln=1;36:so=1;35:pi=1;33:ex=1;32:bd=1;33:cd=1;33:su=1;31:sg=1;31:tw=1;32:ow=1;32'

# Colorize man pages
set -x LESS_TERMCAP_mb (printf '\033[01;31m')
set -x LESS_TERMCAP_md (printf '\033[01;31m')
set -x LESS_TERMCAP_me (printf '\033[0m')
set -x LESS_TERMCAP_se (printf '\033[0m')
set -x LESS_TERMCAP_so (printf '\033[01;44;33m')
set -x LESS_TERMCAP_ue (printf '\033[0m')
set -x LESS_TERMCAP_us (printf '\033[01;32m')
