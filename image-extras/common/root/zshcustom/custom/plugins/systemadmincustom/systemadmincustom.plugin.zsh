# Slimmed down systemadmin plugin

## determine external IP address
geteip() {
    curl -s -S -4 https://icanhazip.com
    # curl -s -S -6 https://icanhazip.com
}

## determine local IP address(es)
getip() {
    if (( ${+commands[ip]} )); then
        ip addr | awk '/inet /{print $2}' | command grep -v 127.0.0.1
    else
        ifconfig | awk '/inet /{print $2}' | command grep -v 127.0.0.1
    fi
}

## directory LS
dls () {
    print -l *(/)
}
