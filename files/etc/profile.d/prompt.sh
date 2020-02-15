SCREEN_SESSION_NAME=""

if [ ! -z "$STY" ]; then
  MY_HOSTNAME=$(uci get system.@system[0].hostname)
  SCREEN_SESSION_NAME=$(echo "${STY}" | sed "s|\.${MY_HOSTNAME}$||")" "
fi

export PS1='${SCREEN_SESSION_NAME}\w \$ '

case "$TERM" in
  xterm*|rxvt*|screen)
    export PS1='${SCREEN_SESSION_NAME}\[\e[1;31m\]\w \$ \[\e[0m\]'
  ;;
esac
