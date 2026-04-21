# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile
#umask 022

if [ -z "$TMUX" ]; then
    if [ ! -z "$SSH_TTY" ]; then
        # we're not in a tmux session'
        if [[ $SSH_AUTH_SOCK && `readlink ~/.ssh/ssh_auth_sock` != $SSH_AUTH_SOCK ]]; then
            ln -sf $SSH_AUTH_SOCK ~/.ssh/ssh_auth_sock
        fi
    fi
fi

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
        . "$HOME/.bashrc"
    fi
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi


# Created by `pipx` on 2025-03-08 19:01:03
export PATH="$PATH:$HOME/.local/bin"

# Added by LM Studio CLI (lms)
export PATH="$PATH:$HOME/.lmstudio/bin"
# End of LM Studio CLI section

. "$HOME/.cargo/env"
