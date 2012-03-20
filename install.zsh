#!/bin/zsh
# using zsh as scripting lang, only runs if zsh is available
#
# variables:
# don't do anything by default
dotfiles_do_bin=0
dotfiles_do_vim=0
dotfiles_do_zsh=0
# ask user which steps they want to do
dotfiles_do_ask=1
# don't skip anything by default
dotfiles_skip_check_dependency=0
dotfiles_skip_check_shell=0
dotfiles_skip_check_ssh_keys=0
dotfiles_skip_check_git_writable=0

function dotfiles_check_dependencies() {
  echo
  echo "== checking for dependencies =="
  function require {
    if ! which $1 >/dev/null 2>&1; then
      echo "[ERROR] missing $1, please install before proceeding.";
      exit 1
    else
      echo "[SUCCESS] found $1"
    fi
  }
  require "zsh"
  require "wget"
  require "ssh-keygen"
  require "git"

  echo
  echo "== checking for recommended utilities =="
  function recommend {
    if ! which $1 >/dev/null 2>&1; then
      echo "[WARNING] missing $1, recommend you install it."
    else
      echo "[SUCCESS] found $1"
    fi
  }
  recommend "ant"
  recommend "curl"
  recommend "nmap"
  recommend "nodeenv"
  recommend "python"
  recommend "rbenv"
  recommend "rsync"
  recommend "tmux"
  recommend "vim"
}

function dotfiles_switch_shell() {
  if ! which $SHELL |grep zsh >/dev/null 2>&1; then
    echo
    echo "[NOTICE] You aren't using ZSH. ZSH is awesome."
    echo -n "Switch to zsh [y/N]? ";                      read dotfiles_do_switch_zsh;
    ###############################################
    # change shell
    ###############################################
    [ "$dotfiles_do_switch_zsh" = "y" ] && {
      echo
      echo "== changing shell =="
      chsh -s `which zsh` && echo "[SUCCESS] user default shell changed to zsh"
      echo "[NOTICE] using zsh at $(which zsh) -- fix your path if this is wrong!"
      echo "         please restart your terminal session, or start a new zsh"
      echo "         You will need to run this install script again"
      exit 0
    }
  else
    echo "[SUCCESS] cool, you're using zsh"
  fi
}

function dotfiles_setup_ssh_keys() {
  if [ ! -e ~/.ssh/id_rsa.pub ]; then
    # from https://gist.github.com/1454081
    echo
    echo "[NOTICE] no ssh keys found for this user on this machine, required"
    echo
    echo "== setting up SSH keys =="
    mkdir ~/.ssh
    echo -n "Please enter your email to comment this SSH key: "; read email
    ssh-keygen -t rsa -C "$email"
    cat ~/.ssh/id_rsa.pub
    cat ~/.ssh/id_rsa.pub | pbcopy > /dev/null 2>&1
    echo "[SUCCESS] Your ssh public key is shown above and (copied to the clipboard on OSX)"
    echo "          Add it to GitHub if this computer needs push permission."
    echo "          When that's done, press [enter] to proceed."
    read
  else
    echo
    echo "[SUCCESS] found SSH keys for this user"
  fi
}

function dotfiles_determine_steps() {
  echo
  echo "== begin install =="
  # @TODO check for --all argument
  echo -n "Symlink .cvsignore (used by rsync) [y/N]? "; read dotfiles_do_cvsignore;
  echo -n "Symlink .tmux.conf [y/N]? ";                 read dotfiles_do_tmux;
  echo -n "Symlink .powconfig [y/N]? ";                 read dotfiles_do_pow;
  echo -n "Set up gitconfig [y/N]? ";                   read dotfiles_do_gitconfig;
  echo -n "Set up github [y/N]? ";                      read dotfiles_do_github;
  echo -n "Set up zsh [y/N]? ";                         read dotfiles_do_zsh;
  echo -n "Set up vim [y/N]? ";                         read dotfiles_do_vim;
  echo -n "Set up bin [y/N]? ";                         read dotfiles_do_bin;

  OS='linux'
  if [ "`uname`" = "Darwin" ]; then
    OS='osx'
    echo -n "Set up OSX Defaults [y/N]? ";                read dotfiles_do_osx;
  fi
}

function dotfiles_setup_git() {
  echo
  echo "== setting up git == "
  echo "You can run this again if you mess up. Leave blank to skip username/email fields."
  echo -n "Please enter your full name: "; read fullname
  # in case we skipped the email in the ssh section
  if [ "$email" = "" ]; then
    echo -n "Please enter your email: "; read email
  fi
  [[ $fullname    != '' ]] && git config --global user.name "$fullname"
  [[ $email       != '' ]] && git config --global user.email "$email"

  # auto color all the things!
  git config --global color.ui auto

  # use cvsignore (symlink)
  git config --global core.excludesfile ~/.dotfiles/.cvsignore

  # vim as diff tool
  git config --global diff.tool vimdiff

  # set up browser for fugitive :Gbrowse
  [ $OS = "osx" ] && git config --global web.browser open

  # a couple aliases
  git config --global alias.co checkout
  git config --global alias.st status

  echo "[SUCCESS] global .gitconfig generated/updated!"
}

function dotfiles_setup_github() {
  echo
  echo "== setting up github == "
  echo "You can run this again if you mess up."
  echo -n "Please enter your github username:  "; read githubuser
  echo -n "Please enter your github api token: "; read githubtoken
  [[ $githubuser  != '' ]] && git config --global github.user "$githubuser"
  [[ $githubtoken != '' ]] && git config --global github.token "$githubtoken"
  echo "[SUCCESS] global .gitconfig updated with github info"
}

function dotfiles_determine_github_write() {
  echo
  echo "== github configuration =="

  GITHUB_URL='git://github.com/davidosomething'

  echo "Checking for existing .gitconfig with github token..."
  if ! git config --global --get github.token >/dev/null 2>&1; then
    echo '[WARNING] missing github token, disabling write access to repositories.'
    echo '          this machine will not be able to push edits back to the repository!'
  elif [ `git config --global --get github.user` = "davidosomething" ]; then
    GITHUB_URL='git@github.com:davidosomething'
    echo '[SUCCESS] github token found and github user is davidosomething,'
    echo '          your dotfiles will be cloned with write access.'
  fi
}

###############################################
# symlink config files
###############################################

function dotfiles_symlink_cvsignore() {
  echo
  echo "== symlink .cvsignore =="
  [ -f ~/.cvsignore ] && { mv ~/.cvsignore ~/.cvsignore.old && echo "[NOTICE] Moved old ~/.cvsignore folder into ~/.cvsignore.old" }
  ln -fs ~/.dotfiles/.cvsignore ~/.cvsignore && echo "[SUCCESS] .cvsignore symlinked"
}

function dotfiles_symlink_tmuxconf() {
  echo
  echo "== symlink .tmux.conf =="
  [ -f ~/.tmux.conf ] && { mv ~/.tmux.conf ~/.tmux.conf.old && echo "[NOTICE] Moved old ~/.tmux.conf folder into ~/.tmux.conf.old" }
  ln -fs ~/.dotfiles/.tmux.conf ~/.tmux.conf && echo "[SUCCESS] .tmux.conf symlinked"
}

function dotfiles_symlink_powconfig() {
  echo
  echo "== symlink .powconfig =="
  [ -f ~/.powconfig ] && { mv ~/.powconfig ~/.powconfig.old && echo "[NOTICE] Moved old ~/.powconfig into ~/.powconfig.old" }
  ln -fs ~/.dotfiles/.powconfig ~/.powconfig && echo "[SUCCESS] .powconfig symlinked"
}

###############################################
# the following require git and github set up
###############################################

function dotfiles_clone() {
  echo
  echo "== cloning dotfiles repo =="
  git clone --recursive $GITHUB_URL/dotfiles.git ~/.dotfiles && echo "[SUCCESS] cloned dotfiles repo"
  echo
  echo "== cloning and updating submodules =="
  cd ~/.dotfiles && git submodule update --init --quiet && echo "[SUCCESS] submodules updated"
}

function dotfiles_symlink_zsh() {
  echo
  echo "== symlink zsh dotfiles =="
  [ -f ~/.zshrc ] && mv ~/.zshrc ~/.dotfiles/.zshrc.old
  [ -f ~/.zshenv ] && mv ~/.zshenv ~/.dotfiles/.zshenv.old
  echo "[NOTICE] Your old .zshrc and .zshenv are now ~/.dotfiles/.zsh*.old"

  ln -fs ~/.dotfiles/.zshrc ~/.zshrc && ln -fs ~/.dotfiles/.zshenv ~/.zshenv && {
    echo "[SUCCESS] Your new .zshrc and .zshenv are symlinks to ~/.dotfiles/.zsh*"
    echo "          Create .zshrc.local with any additional fpaths and .zshenv.local with"
    echo "          correct paths! There are a few stock configs in ~/.dotfiles/"
  }

  [ ! -f ~/.zshenv.local ] && {
    echo "source ~/.dotfiles/.zshenv.local.$OS" >> ~/.zshenv.local
    echo "[NOTICE] You didn't have a .zshenv.local file so one was created for"
    echo "          you. It just sources ~/.dotfiles/.zshenv.local.$OS for now."
  }

  [ ! -f ~/.zshrc.local ] && {
    echo "source ~/.dotfiles/.zshrc.local.$OS" >> ~/.zshrc.local
    echo "[NOTICE] You didn't have a .zshrc.local file so one was created for"
    echo "          you. It just sources ~/.dotfiles/.zshrc.local.$OS for now."
  }
}

function dotfiles_symlink_vim() {
  echo
  echo "== symlink .vim folder and vim dotfiles =="
  [ -d ~/.vim ] && { mv ~/.vim ~/.vim.old && echo "[NOTICE] Moved old ~/.vim folder into ~/.vim.old (just in case)" }
  ln -fs ~/.dotfiles/vim ~/.vim && echo "[SUCCESS] Your ~/.vim folder is a symlink to ~/.dotfiles/vim"

  mkdir -p ~/.dotfiles/vim/_temp
  mkdir -p ~/.dotfiles/vim/_backup
  echo "[SUCCESS] Created backup and temp folders for vim"

  # just in case
  [ -f ~/.vimrc ] && { mv ~/.vimrc ~/.vimrc.old }
  [ -f ~/.gvimrc ] && { mv ~/.gvimrc ~/.gvimrc.old }
  echo "[NOTICE] Your old .?vimrc is now ~/.?vimrc.old"

  # create softlink to (g)vimrc
  ln -fs ~/.dotfiles/.vimrc ~/.vimrc && echo "[SUCCESS] Your new .vimrc is a symlink to ~/.dotfiles/.vimrc"
  ln -fs ~/.dotfiles/.gvimrc ~/.gvimrc && echo "[SUCCESS] Your new .gvimrc is a symlink to ~/.dotfiles/.gvimrc"
}

function dotfiles_symlink_bin() {
  echo
  echo "== create ~/bin and symlink some scripts =="
  [ ! -d ~/bin ] && { mkdir ~/bin && echo "[SUCCESS] Created local bin folder" }
  for f in ~/.dotfiles/bin/*
  do
    BIN_NAME=$(basename $f)
    [ ! -f ~/bin/$BIN_NAME ] && ln -fs $f ~/bin/$BIN_NAME && echo "[SUCCESS] ~/bin/$BIN_NAME symlinked"
  done
}

function dotfiles_setup_osx() {
  echo
  echo "== set up OSX defaults =="
  . ~/.dotfiles/.osx && echo "[SUCCESS] OSX defaults written"
}

###############################################
# usage
###############################################

function dotfiles_usage() {
  echo "usage:                  ./install.zsh [options] [setups]"
  echo
  echo "options:"
  echo "  -h | --help           show usage (you're looking at it)"
  echo "  -v | --version        show version info"
  echo "  --skip-dependency     don't check for dependencies"
  echo "  --skip-shell          don't check if zsh is the default shell"
  echo "  --skip-ssh            don't check for SSH keys"
  echo "  --read-only           don't check if github user is davidosomething"
  echo "  --skip-checks         don't check for anything. OVERRIDES ALL SKIPS"
  echo "  --all                 perform all install actions. OVERRIDES SETUPS"
  echo
  echo "setups:"
  echo "  By specifying a setup you will run only the ones specified."
  echo "  Valid setups to run include:"
  echo "  bin, osx, vim, zsh"
  echo
}

###############################################
# read parameters
###############################################

while [ "$1" != "" ]; do
  case $1 in
    -h | --help )         dotfiles_usage
                          exit 0
                          ;;
    -v | --version )      echo "davidosomething environment setup version 0.1"
                          exit 0
                          ;;
    --skip-dependency )   dotfiles_skip_check_dependency=1
                          ;;
    --skip-shell )        dotfiles_skip_check_shell=1
                          ;;
    --skip-ssh )          dotfiles_skip_check_ssh_keys=1
                          ;;
    --read-only )         dotfiles_skip_check_git_writable=1
                          ;;
    --skip-all )          dotfiles_skip_check_dependency=1
                          dotfiles_skip_check_shell=1
                          dotfiles_skip_check_ssh_keys=1
                          dotfiles_skip_check_git_writable=1
                          ;;
    bin )                 dotfiles_do_bin=1
                          dotfiles_do_ask=0
                          ;;
    osx )                 dotfiles_do_osx=1
                          dotfiles_do_ask=0
                          ;;
    vim )                 dotfiles_do_vim=1
                          dotfiles_do_ask=0
                          ;;
    zsh )                 dotfiles_do_zsh=1
                          dotfiles_do_ask=0
                          ;;
    --all )               dotfiles_do_bin=1
                          dotfiles_do_vim=1
                          dotfiles_do_zsh=1
                          dotfiles_do_ask=0
                          ;;
    * )                   echo
                          echo "[ERROR] Invalid argument: $1"
                          dotfiles_usage
                          exit 1
  esac
  shift
done

###############################################
# start doing shit here
###############################################

[ dotfiles_skip_check_shell      != 1 ]  && dotfiles_switch_shell
[ dotfiles_skip_check_dependency != 1 ]  && dotfiles_check_dependencies
[ dotfiles_skip_check_ssh_keys   != 1 ]  && dotfiles_setup_ssh_keys
[ dotfiles_do_ask       != 1 ]  && dotfiles_determine_steps

[ "$dotfiles_do_gitconfig:l" = "y" ] && dotfiles_setup_git
[ "$dotfiles_do_github:l"    = "y" ] && dotfiles_setup_github

[ dotfiles_skip_check_git_writable != 1 ] && dotfiles_determine_github_write
[ ! -d ~/.dotfiles ] && dotfiles_clone

# vim and zsh use bin
[ "$dotfiles_do_bin:l"       = "y" ] && dotfiles_symlink_bin
[ "$dotfiles_do_vim:l"       = "y" ] && dotfiles_symlink_vim
[ "$dotfiles_do_cvsignore:l" = "y" ] && dotfiles_symlink_cvsignore
[ "$dotfiles_do_pow:l"       = "y" ] && dotfiles_symlink_tmuxconf
[ "$dotfiles_do_tmux:l"      = "y" ] && dotfiles_symlink_powconfig
# do this last since it modifies paths
[ "$dotfiles_do_zsh:l"       = "y" ] && dotfiles_symlink_zsh

[ "$dotfiles_do_osx:l" = "y" ] && dotfiles_setup_osx

echo
echo "[SUCCESS] ALL DONE!!!!!!11111"
