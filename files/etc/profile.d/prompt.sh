SCREEN_SESSION_NAME=$(screen -ls | sed -n 's|[^a-z0-9]*\([0-9][0-9]*\.[a-zA-Z][a-zA-Z0-9-]*\).*Attached.*|\1|p')

if [ ! -z "$SCREEN_SESSION_NAME" ]; then
   SCREEN_SESSION_NAME="$SCREEN_SESSION_NAME "
fi

export PS1='${SCREEN_SESSION_NAME}\w \$ '

case "$TERM" in
        xterm*|rxvt*|screen)
                export PS1='${SCREEN_SESSION_NAME}\[\e[1;31m\]\w \$ \[\e[0m\]'
                ;;
esac

