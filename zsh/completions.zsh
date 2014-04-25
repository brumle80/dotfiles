##
# completion zstyles

##
# tab completion paths, top precedence
command -v brew >/dev/null 2>&1 && {
  fpath=(
    $(brew --prefix)/share/zsh/site-functions
    $(brew --prefix)/share/zsh-completions
  )
}

##
# top precedence! So my dotfiles zsh-completions override the previous brew
fpath=(
  $ZSH_DOTFILES/zsh-completions/src
  $fpath
)

# remove duplicates in fpath array
typeset -U fpath

# load completion - the -U means look in fpath, -z means on first run
# -i means ignore security errors
autoload -Uz compinit && compinit -i

# in Bold, specify what type the completion is, e.g. a file or an alias or a cmd
zstyle ':completion:*:descriptions' format '%F{black}%B%d%b%f'

# group all by the description above
zstyle ':completion:*' group-name ''

# colorful completion
zstyle ':completion:*' list-colors ''

zstyle ':completion:*' list-dirs-first yes

# use case-insensitive completion if case-sensitive failed generated no hits
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}'

# expand completions as much as possible on tab
# e.g. start expanding a path up to wherever it can be until error
zstyle ':completion:*' expand 'yes'

# don't autocomplete homedirs
zstyle ':completion::complete:cd:*' tag-order '! users'

# use /etc/hosts and known_hosts for hostname completion
[[ -f ~/.ssh/known_hosts ]] && _ssh_hosts=(${${${${(f)"$(<$HOME/.ssh/known_hosts)"}:#[\|]*}%%\ *}%%,*}) || _ssh_hosts=()
[[ -f ~/.ssh/config ]] && _ssh_config=($(cat ~/.ssh/config | sed -ne 's/Host[=\t ]//p')) || _ssh_config=()
[[ -f /etc/hosts ]] && : ${(A)_etc_hosts:=${(s: :)${(ps:\t:)${${(f)~~"$(</etc/hosts)"}%%\#*}##[:blank:]#[^[:blank:]]#}}} || _etc_hosts=()
hosts=(
  "$_ssh_config[@]"
  "$_global_ssh_hosts[@]"
  "$_ssh_hosts[@]"
  "$_etc_hosts[@]"
  "$HOST"
  localhost
)
zstyle ':completion:*:hosts' hosts $hosts

# don't complete usernames
zstyle ':completion:*' users ''

# show descriptions for options
zstyle ':completion:*' verbose yes
