#!/bin/bash
set +o posix

PREFIX=${0%/*/*}
CELLAR=$PREFIX/Cellar
REPO=$PREFIX/Homebrew
LIBRARY=$REPO/Library
TAPS=$LIBRARY/Taps/*/*
REPOS="$REPO $TAPS"

CACHE="$HOME/Library/Caches/Homebrew"
LOGS="$HOME/Library/Logs/Homebrew"
LOCKS="$PREFIX/var/homebrew/locks"
PINS="$PREFIX/var/homebrew/pinned"

FORMULA="find $TAPS -name $2.rb"
LATEST=$([ -d $CELLAR/$2 ] && ls -r $CELLAR/$2 | head -n1)
KEG="$CELLAR/$2/$LATEST"
LINK_DIRS="bin,etc,include,lib,sbin,share,var"
LINKS="eval cd $KEG && find {$LINK_DIRS} -not -type d 2> /dev/null"
XARG="xargs -n1 -I{}"
CUT="cut -f2 -d\""

[ $1 == install ] && URI="https://homebrew.bintray.com/bottles/$2-$(b ver $2).mojave.bottle.tar.gz"

case "$1" in
  list)       ls $CELLAR ;;
  search)     find $TAPS -name *$2* | $XARG basename {} .rb ;;
  update)     for D in $REPOS; do git -C $D rebase origin/master; done ;;

  install)    curl -L $URI | tar zxv -C $CELLAR && b link $2 ;;
  uninstall)  [[ $2 ]] && b unlink $2 && rm -r $CELLAR/$2 ;;
  upgrade)    b uninstall $2 && b install $2 $LATEST ;;
  link)       ($LINKS) | $XARG ln -s $KEG/{} $PREFIX/{} ;;
  unlink)     ($LINKS) | $XARG rm $PREFIX/{} ;;
  pin)        ln -s $KEG $PINS/$2 ;;
  unpin)      rm $PINS/$2 ;;

  edit)       $EDITOR $($FORMULA) ;;
  cat)        cat $($FORMULA) ;;
  info)       cat $($FORMULA) | egrep "homepage |desc " | $CUT ;;
  desc)       cat $($FORMULA) | egrep "desc " | $CUT ;;
  url)        cat $($FORMULA) | egrep "url " | $CUT ;;
  ver)        cat $($FORMULA) | egrep "url " | egrep -o '[0-9][0-9\.]+[0-9]' ;;
  home)       cat $($FORMULA) | egrep "homepage " | $CUT | xargs open ;;
  deps)       cat $($FORMULA) | egrep "depends_on " | $CUT ;;
  uses)       pt -le "depends_on \"$2\"\$" $TAPS | $XARG basename {} .rb ;;

  --cache)    echo $CACHE ;;
  log)        git -C $REPO log ;;
  cleanup)    rm -rf $CACHE/* $LOGS/* $LOCKS/* > /dev/null ;;
  version)    git -C $REPO describe --tags --dirty --abbrev=7 ;;
esac
