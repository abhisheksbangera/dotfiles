# Auto-attach to tmux, interactive shells only.
# Set ZSH_NO_TMUX=1 to opt out. Placed above instant-prompt on purpose:
# anything needing console input must come before the p10k block.
if [[ -z "${TMUX:-}" && $- == *i* && -z "${ZSH_NO_TMUX:-}" ]] && command -v tmux >/dev/null; then
  exec tmux new-session -A -s main
fi

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

### Added by Zinit's installer
if [[ ! -f "$HOME/.local/share/zinit/zinit.git/zinit.zsh" ]]; then
    print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
        print -P "%F{33} %F{34}Installation successful.%f%b" || \
        print -P "%F{160} The clone has failed.%f%b"
fi

# Guarded so a failed clone doesn't break every new shell.
[[ -f "$HOME/.local/share/zinit/zinit.git/zinit.zsh" ]] && source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"

### End of Zinit's installer chunk

# Install zinit:
# bash -c "$(curl --fail --show-error --silent --location https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh)"
# zinit self-update

[[ -d "$HOME/.local/bin" ]] && export PATH="$HOME/.local/bin:$PATH"

export EDITOR="nvim"
export VISUAL="nvim"

# NOTE: the old zinit-annex-* block was deleted on purpose — annexes have
# been merged into main zinit for years and only produce warnings now.
# NOTE: the old `autoload -Uz _zinit` / `_comps[zinit]=_zinit` lines were
# part of the legacy installer and are no longer needed.

zinit ice depth=1; zinit light romkatv/powerlevel10k
zinit light zsh-users/zsh-completions

autoload -Uz compinit && compinit -C
zinit cdreplay -q

zinit light Aloxaf/fzf-tab
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-history-substring-search
# syntax-highlighting must stay last: it wraps widgets from the plugins above.
zinit light zsh-users/zsh-syntax-highlighting

# zoxide provides `cd` (smart) + `cdi` (interactive) itself — no dumb aliases.
command -v zoxide >/dev/null && eval "$(zoxide init zsh --cmd cd)"
command -v fzf >/dev/null && eval "$(fzf --zsh)"

# fzf: compact popup layout; fd backend respects .gitignore and is faster.
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --info=inline"
if command -v fd >/dev/null; then
  export FZF_DEFAULT_COMMAND="fd --type f --hidden --follow --exclude .git"
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND="fd --type d --hidden --follow --exclude .git"
fi

command -v nvim >/dev/null && alias vi="nvim"
alias ls="ls --color=auto"
if command -v eza >/dev/null; then
  alias l="eza -lah --icons"
  alias ll="eza -lh --icons --git"
  alias la="eza -lah --icons"
  alias lt="eza --tree --level=2 --icons"
else
  alias l="ls -lah --color=auto"
fi

# --- Safety nets ---
alias cp="cp -i"
alias mv="mv -i"
alias rm="rm -I"          # prompt once when deleting >3 files (no trash-cli installed)
alias mkdir="mkdir -p"
REPORTTIME=10             # report wall-clock time for commands running longer than 10s
setopt interactivecomments # allow `# comments` in interactive commands

# Alt-s: prepend (or toggle) sudo on the current command line.
sudo-command-line() {
  [[ -z "$BUFFER" ]] && zle up-history
  if [[ "$LBUFFER" == "sudo "* ]]; then
    LBUFFER="${LBUFFER#sudo }"
  else
    LBUFFER="sudo $LBUFFER"
  fi
}
zle -N sudo-command-line
bindkey '\es' sudo-command-line

# --- Git + forges ---
alias gs="git status -sb"
alias ga="git add"
alias gc="git commit"
alias gp="git push"
alias gl="git log --oneline --graph --decorate -15"
alias gd="git diff"
command -v lazygit >/dev/null && alias lg="lazygit"
if command -v gh >/dev/null; then
  alias ghpr="gh pr status"
  alias ghv="gh repo view --web"
fi

# --- Navigation helpers ---
setopt auto_cd              # bare `..` or dirname cds instead of "permission denied"
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
setopt auto_pushd pushd_ignore_dups  # `cd` pushes onto the dir stack; `dirs -v`, `cd -2`
mkcd() { mkdir -p "$1" && cd "$1"; } # mkcd new/dir
command -v fzf >/dev/null && command -v nvim >/dev/null && vf() { # vf: fuzzy-open a file in nvim
  local file
  file=$(fzf) && nvim "$file"
}
# y: yazi file manager that keeps the shell cwd on exit (yazi must be installed).
if command -v yazi >/dev/null; then
  y() {
    local tmp
    tmp="$(mktemp -t yazi-cwd.XXXXXX)" || return
    yazi "$@" --cwd-file="$tmp"
    local cwd
    cwd="$(cat -- "$tmp" 2>/dev/null)" && [[ -n "$cwd" && "$cwd" != "$PWD" ]] && cd -- "$cwd"
    rm -f -- "$tmp"
  }
fi

# --- Tmux ---
alias ta="tmux attach -t main 2>/dev/null || tmux new -s main"
alias tls="tmux ls"
alias tn="tmux new -s"
# Ctrl-f: jump via tmux-sessionizer (ThePrimeagen upstream, ~/.local/bin).
# Search paths configured in ~/.config/tmux-sessionizer/tmux-sessionizer.conf.
if command -v tmux-sessionizer >/dev/null; then
  bindkey -s '^f' 'tmux-sessionizer\n'
fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f "$HOME/.p10k.zsh" ]] || source "$HOME/.p10k.zsh"

bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
# Up/Down: substring search through history (needs the plugin loaded above).
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

HISTSIZE=20000
HISTFILE="$HOME/.zsh_history"
SAVEHIST="$HISTSIZE"
setopt append_history
setopt share_history
setopt inc_append_history
setopt extended_history
setopt hist_ignore_space
setopt hist_ignore_dups
setopt hist_save_no_dups
setopt hist_find_no_dups
setopt hist_expire_dups_first

zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompcache"
[[ -d "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompcache" ]] || mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompcache" >/dev/null 2>&1
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always "$realpath" 2>/dev/null || ls --color=always "$realpath"'
# Cover zoxide helpers regardless of init flags (default `z`/`zi` vs `--cmd cd`).
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza -1 --color=always "$realpath" 2>/dev/null || ls --color=always "$realpath"'
zstyle ':fzf-tab:complete:__zoxide_zi:*' fzf-preview 'eza -1 --color=always "$realpath" 2>/dev/null || ls --color=always "$realpath"'
