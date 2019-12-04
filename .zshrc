eval "$(starship init zsh)"

# >>> my export init >>>
export iam="$(whoami)"
export CONDA_HOME="/Users/${iam}/opt/anaconda3"
export PATH=${CONDA_HOME}/bin:$PATH
# <<< my export init <<<

# added by Anaconda3 2019.10 installer
# >>> conda init >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$(CONDA_REPORT_ERRORS=false '/Users/bigo/opt/anaconda3/bin/conda' shell.bash hook 2> /dev/null)"
if [ $? -eq 0 ]; then
    \eval "$__conda_setup"
else
    if [ -f "/Users/bigo/opt/anaconda3/etc/profile.d/conda.sh" ]; then
        . "/Users/bigo/opt/anaconda3/etc/profile.d/conda.sh"
        CONDA_CHANGEPS1=false conda activate base
    else
        \export PATH="/Users/bigo/opt/anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda init <<<

# <<< direnv init <<<
# Ref Url: https://github.com/direnv/direnv/wiki/Python
show_virtual_env() {
  if [[ -n "$VIRTUAL_ENV" && -n "$DIRENV_DIR" ]]; then
    echo "($(basename $VIRTUAL_ENV))"
  fi
}
PS1='$(show_virtual_env)'$PS1
eval "$(direnv hook zsh)"
# <<< direnv init <<<

alias ..='cd ..'
alias ...='cd ../..'
alias ls='ls -GwF'
alias ll='ls -alh'

source /Users/bigo/.zsh/completion.zsh

zstyle ':completion:*:*:git:*' script ~/.zsh/git-completion.bash
fpath=(~/.zsh $fpath)

# Initialize the completion system
autoload -Uz compinit
# autoload -Uz compinit && compinit

# Cache completion if nothing changed - faster startup time
typeset -i updated_at=$(date +'%j' -r ~/.zcompdump 2>/dev/null || stat -f '%Sm' -t '%j' ~/.zcompdump 2>/dev/null)
if [ $(date +'%j') != $updated_at ]; then
  compinit -i
else
  compinit -C -i
fi

# Enhanced form of menu completion called `menu selection'
zmodload -i zsh/complist

source /Users/bigo/.zsh/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
source /Users/bigo/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
source /Users/bigo/.zsh/history.zsh

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/bigo/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/bigo/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/bigo/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/bigo/google-cloud-sdk/completion.zsh.inc'; fi

export PATH=$PATH:~/bin:~/src/scripts
