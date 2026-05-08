# ── Prompt: foldername: branchname ───────────────────────────────────────────
autoload -Uz vcs_info
precmd() { vcs_info }

zstyle ':vcs_info:git:*' formats '%F{yellow} %b%f'
zstyle ':vcs_info:*' enable git

setopt PROMPT_SUBST
PROMPT='%F{cyan}%1d%f${vcs_info_msg_0_} %F{white}❯%f '

# ── PATH ─────────────────────────────────────────────────────────────────────
export PATH="$HOME/.local/share/bob/nvim-bin:$PATH"   # neovim via bob
export PATH="$HOME/.rbenv/bin:$PATH"                   # rbenv
eval "$(rbenv init -)"

# ── Env vars ─────────────────────────────────────────────────────────────────
export LANG=en_US.UTF-8
export OLLAMA_API_BASE="http://localhost:11434"
export NX_DAEMON=false

# ── Aliases ───────────────────────────────────────────────────────────────────
source ~/aliases.sh

# ── Completions ───────────────────────────────────────────────────────────────
fpath+=("$(brew --prefix)/share/zsh/site-functions")
autoload -Uz compinit && compinit

# ── fzf ──────────────────────────────────────────────────────────────────────
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

alias gst='git status'
