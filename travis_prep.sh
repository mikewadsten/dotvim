#!/bin/sh

set -eu

git clone --depth=1 https://github.com/thinca/vim-themis /tmp/themis

NEED_TO_CLONE=0
if ! test -d $HOME/vim-7.4/bin
then
    NEED_TO_CLONE=1
fi
if ! test -d $HOME/vim-8.0/bin
then
    NEED_TO_CLONE=1
fi

if [ $NEED_TO_CLONE != 0 ]
then
    echo "One or more Vim versions is not cached, downloading Vim..."
    git clone https://github.com/vim/vim $HOME/vim
    cd $HOME/vim
fi

if ! test -d $HOME/vim-7.4/bin
then
    echo "Building Vim 7.4"
    git --git-dir=$HOME/vim/.git worktree add --checkout $HOME/vim-7-src v7.4
    cd $HOME/vim-7-src
    ./configure --prefix=$HOME/vim-7.4 --enable-cscope
    make && make install
fi

if ! test -d $HOME/vim-8.0/bin
then
    echo "Building Vim 8.0"
    git --git-dir=$HOME/vim/.git worktree add --checkout $HOME/vim-8-src v8.0.1850
    cd $HOME/vim-8-src
    ./configure --prefix=$HOME/vim-8.0 --enable-cscope
    make && make install
fi

if ! test -d $HOME/global/bin
then
    echo "Downloading and building Global"
    wget -q https://ftp.gnu.org/gnu/global/global-6.5.5.tar.gz -O $HOME/global-6.5.5.tar.gz
    mkdir $HOME/global-6.5.5-src
    cd $HOME
    tar xvzf global-6.5.5.tar.gz -C $HOME/global-6.5.5-src
    cd $HOME/global-6.5.5-src
    ./configure --prefix=$HOME/global
    make && make install
fi
