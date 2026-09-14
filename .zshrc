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

# Omarchy base environment (OMARCHY_PATH, mise shims, EDITOR/BROWSER/MANPAGER).
# These files are POSIX-safe, so zsh can source them directly.
[[ -r /usr/share/omarchy/default/bash/env-bootstrap ]] && source /usr/share/omarchy/default/bash/env-bootstrap
[[ -r "${OMARCHY_PATH:-/usr/share/omarchy}/default/bash/envs" ]] && source "${OMARCHY_PATH:-/usr/share/omarchy}/default/bash/envs"

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

# Omarchy's envs already sets EDITOR (omarchy-launch-editor); nvim is the fallback.
export EDITOR="${EDITOR:-nvim}"
export VISUAL="${VISUAL:-$EDITOR}"

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
command -v mise >/dev/null && eval "$(mise activate zsh)"

# fzf: compact popup layout; fd backend respects .gitignore and is faster.
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --info=inline"
if command -v fd >/dev/null; then
  export FZF_DEFAULT_COMMAND="fd --type f --hidden --follow --exclude .git"
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND="fd --type d --hidden --follow --exclude .git"
fi

command -v nvim >/dev/null && alias vi="nvim"
if command -v eza >/dev/null; then
  # Flags follow Omarchy's bash defaults.
  alias ls="eza -lh --group-directories-first --icons=auto"
  alias lsa="ls -a"
  alias lt="eza --tree --level=2 --long --icons --git"
  alias lta="lt -a"
  alias l="eza -lah --icons"
  alias ll="eza -lh --icons --git"
  alias la="eza -lah --icons"
else
  alias ls="ls --color=auto"
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
# NOTE: ga/gd are intentionally NOT aliased here — Omarchy provides them as
# git-worktree create/remove functions (sourced below), which is the more
# distinctive use of those keys. Use `git add` / `git diff` in full.
alias gs="git status -sb"
alias g="git"
alias gc="git commit"
alias gcm="git commit -m"
alias gcam="git commit -a -m"
alias gcad="git commit -a --amend"
alias gp="git push"
alias gl="git log --oneline --graph --decorate -15"
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

# --- Omarchy functions ---
# The whole fns/ dir is bashism-free and sources cleanly in zsh. Highlights:
# tdl/tds/tdlm/tsl (tmux dev layouts), ga/gd (worktree create/remove),
# compress/decompress, iso2sd/format-drive, rsw/lsw/dsw + fip/dip/lip (rsync/ssh),
# hdl/hds/hdlm/hsl (herdr layouts).
if [[ -n "${OMARCHY_PATH:-}" && -d "$OMARCHY_PATH/default/bash/fns" ]]; then
  for f in "$OMARCHY_PATH"/default/bash/fns/*; do
    [[ -r "$f" ]] && source "$f"
  done
  unset f
fi

# try: lazy-loads on first use (like Omarchy's bash), rooted at ~/Work/tries.
if command -v try >/dev/null; then
  try() {
    unfunction try
    eval "$(SHELL=/bin/bash command try init ~/Work/tries)"
    try "$@"
  }
fi

# omarchy subcommand completion (bash's `complete` API via zsh's bashcompinit shim).
if command -v omarchy >/dev/null && [[ -r "${OMARCHY_PATH:-/usr/share/omarchy}/default/bash/completions" ]]; then
  autoload -U +X bashcompinit && bashcompinit
  source "${OMARCHY_PATH:-/usr/share/omarchy}/default/bash/completions"
fi

# --- Omarchy aliases (adapted from default/bash/aliases) ---
if command -v fzf >/dev/null && command -v bat >/dev/null; then
  # ff: fuzzy-find with file preview; eff: open the pick in $EDITOR.
  alias ff="fzf --preview 'bat --style=numbers --color=always {}'"
  alias eff='$EDITOR "$(ff)"'
  # sff <destination>: pick from recently modified files and scp it there.
  sff() {
    if [ $# -eq 0 ]; then echo "Usage: sff <destination> (e.g. sff host:/tmp/)"; return 1; fi
    local file
    file=$(find . -type f -printf '%T@\t%p\n' | sort -rn | cut -f2- | ff) && [ -n "$file" ] && scp "$file" "$1"
  }
fi
# open: detach-open a file/URL without blocking the shell.
open() (
  xdg-open "$@" >/dev/null 2>&1 &
)
# n: nvim DWIM — no args opens the current dir.
n() { if [ "$#" -eq 0 ]; then command nvim . ; else command nvim "$@"; fi; }
# AI agents (one-letter Omarchy shortcuts).
command -v omarchy-agent >/dev/null && alias a="omarchy-agent --inline"
command -v opencode >/dev/null && alias c="opencode --auto"
command -v claude >/dev/null && alias cx='printf "\033[2J\033[3J\033[H" && claude --permission-mode auto'
command -v codex >/dev/null && alias cy="codex --approve-for-me"
command -v docker >/dev/null && alias d="docker"
command -v herdr >/dev/null && alias h="herdr"
# ic/ix/icx: spin up a tmux dev layout (tdl comes from Omarchy fns above).
alias ic="tdl c"
alias ix="tdl cx"
alias icx="tdl c cx"
command -v mise >/dev/null && alias mup="MISE_MINIMUM_RELEASE_AGE=0 mise up"

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
