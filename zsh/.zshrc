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
# drop any stale alias so re-sourcing can (re)define these as functions
unalias nvim-gitmod nvim-git-com git-list 2>/dev/null

# list files changed in a commit, colored by status (added/modified/deleted/...).
# no arg = last commit (HEAD). git-list 1 = HEAD~1, git-list 2 = HEAD~2, ...
git-list() {
  local n=${1:-0} color=""
  [[ -t 1 ]] && color=1
  git diff-tree --no-commit-id --name-status -M -r "HEAD~$n" | awk -v color="$color" '
    BEGIN { g="\033[32m"; r="\033[31m"; y="\033[33m"; b="\033[34m"; m="\033[35m"; x="\033[0m" }
    {
      st = substr($1, 1, 1); path = $2
      if (NF > 2) path = $2 " -> " $3
      if      (st == "A") { word = "added   "; col = g }
      else if (st == "M") { word = "modified"; col = y }
      else if (st == "D") { word = "deleted "; col = r }
      else if (st == "R") { word = "renamed "; col = b }
      else if (st == "C") { word = "copied  "; col = m }
      else if (st == "T") { word = "typechg "; col = m }
      else                { word = st "       "; col = "" }
      if (!color) { col = ""; x = "" }
      printf "%s%s%s  %s\n", col, word, x, path
    }'
}

# open ALL uncommitted files in neovim: staged + unstaged + untracked (deduped)
nvim-gitmod() {
  local files
  files=$( { git diff --name-only -- ':!*.md'; git diff --cached --name-only -- ':!*.md'; git ls-files --others --exclude-standard -- ':!*.md'; } | sort -u )
  [ -z "$files" ] && { echo "nothing uncommitted"; return 0; }
  nvim ${(f)files}
}

# open all files changed in a commit. no arg = last commit (HEAD).
# nvim-git-com 1 = HEAD~1, nvim-git-com 2 = HEAD~2, ...
nvim-git-com() {
  local n=${1:-0}
  local files
  files=$(git diff-tree --no-commit-id --name-only -M --diff-filter=d -r "HEAD~$n" -- ':!*.md')
  [ -z "$files" ] && { echo "no files in HEAD~$n"; return 0; }
  nvim ${(f)files}
}
