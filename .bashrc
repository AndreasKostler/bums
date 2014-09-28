# Emacs
alias ec='/Applications/Emacs.app/Contents/MacOS/bin/emacsclient'
alias aquamacs='open -a /Applications/Aquamacs.app $1'
alias emacs='open -a /Applications/Emacs.app $1'

# Homebrew
export ARCHFLAGS="-arch x86_64"

if [ -f $(brew --prefix)/etc/bash_completion ]; then
    . $(brew --prefix)/etc/bash_completion
fi

# Java

function setjdk() {
  if [ $# -ne 0 ]; then
    removeFromPath '/System/Library/Frameworks/JavaVM.framework/Home/bin'
    if [ -n "${JAVA_HOME+x}" ]; then
      removeFromPath $JAVA_HOME
    fi
    export JAVA_HOME=`/usr/libexec/java_home -v $@`
    export PATH=$JAVA_HOME/bin:$PATH
  fi
}
function removeFromPath() {
  export PATH=$(echo $PATH | sed -E -e "s;:$1;;" -e "s;$1:?;;")
}

# SBT Options
function sbt_omnia() {
   SBT_REPOS=$HOME/omnia/tooling.repositories/repositories
   SBT_JAVA_HOME=`setjdk 1.6`
   SBT_JAVA_OPTS="-Dsbt.override.build.repos=true -Dsbt.repository.config=$SBT_REPOS -Dfile.encoding=UTF8 -XX:+CMSClassUnloadingEnabled -XX:+UseConcMarkSweepGC -XX:MaxPermSize=256m -Xms512m -Xmx1g"

   JAVA_HOME=$SBT_JAVA_HOME JVM_OPTS=$SBT_JAVA_OPTS ./sbt "$@"
}

setjdk 1.8


