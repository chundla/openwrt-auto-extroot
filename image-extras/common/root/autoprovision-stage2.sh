#!/bin/sh

# autoprovision stage 2: this script will be executed upon boot if the extroot was successfully mounted (i.e. rc.local is run from the extroot overlay)

. /root/autoprovision-functions.sh

installPackages()
{
    signalAutoprovisionWaitingForUser

    until (opkg update)
     do
        cat >/etc/resolv.conf <<EOF
search ld.lan
nameserver 9.9.9.9
nameserver 9.9.9.11
EOF
        sleep 30
        log "opkg update failed. No internet connection? Retrying in 15 seconds..."
        sleep 15
        # Initiate a synchronous time update.
        ntpd -d -q -n -p openwrt.pool.ntp.org
    done

    signalAutoprovisionWorking

    log "Autoprovisioning stage2 is about to install packages"
    # switch ssh from dropbear to openssh (needed to install sshtunnel)
    opkg remove dropbear
    opkg install openssh-server openssh-client openssh-keygen openssh-sftp-server sshtunnel

    /etc/init.d/sshd enable
    chmod 0700 /root/.ssh
    /etc/init.d/sshd start
    rm -rf /etc/dropbear

    # save opkg lists stored on extroot instead of ram
    #sed -i -e "/^lists_dir\s/s:/var/opkg-lists$:/usr/lib/opkg/lists:" /etc/opkg.conf
    #opkg update

    # CUSTOMIZE
    # install some more packages that don't need any extra steps
    #opkg install lua luci ppp-mod-pppoe screen mc unzip logrotate
    opkg download --cache /tmp ath10k-board-qca4019 ath10k-firmware-qca4019 ath10k-firmware-qca9888
    opkg remove ath10k-firmware-qca4019-ct ath10k-firmware-qca9888-ct kmod-ath10k-ct
    opkg install --cache /tmp ath10k-firmware-qca4019 ath10k-firmware-qca9888 kmod-ath10k
    opkg download --cache /tmp dnsmasq-full ip-full
    opkg remove dnsmasq ip
    opkg install --cache /tmp dnsmasq-full ip-full
    opkg install --force-overwrite syslog-ng
    opkg install ca-certificates collectd collectd-mod-cpu collectd-mod-cpufreq collectd-mod-ethstat collectd-mod-exec collectd-mod-interface collectd-mod-iptables 
    opkg install collectd-mod-iwinfo collectd-mod-load collectd-mod-memory collectd-mod-network collectd-mod-ping collectd-mod-processes collectd-mod-rrdtool 
    opkg install collectd-mod-sqm collectd-mod-syslog collectd-mod-thermal collectd-mod-wireless curl diffutils e2fsprogs htop jsonfilter
    opkg install git git-http iw iwinfo logrotate luci-app-advanced-reboot luci-app-attendedsysupgrade luci-app-firewall luci-app-package-manager
    opkg install luci-app-statistics luci-app-usteer luci-base luci-lib-uqr luci-light luci-mod-admin-full luci-mod-dashboard luci-mod-network luci-mod-status luci-mod-system 
    opkg install luci-proto-ipv6 luci-proto-ppp luci-proto-wireguard luci-ssl luci-theme-bootstrap luci-theme-material nano netifd nmap-full nginx-full 
    opkg install luci-ssl-nginx nginx-mod-luci nginx-mod-luci-ssl nginx-ssl nginx-ssl-util parted smcroute tcpdump tmux ucode ucode-mod-fs ucode-mod-html 
    opkg install ucode-mod-math ucode-mod-nl80211 ucode-mod-rtnl ucode-mod-ubus ucode-mod-uci ucode-mod-uloop unzip usteer usbmuxd usbutils wakeonlan wget-ssl wireguard-tools 
    opkg install wpad-mbedtls zsh zoneinfo-core zoneinfo-america

}

setupohmyzsh()
{
    # setup ohmyzsh once zsh is installed
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)">/dev/null

    # move custom ohmyzsh configurations to ohmyzsh directory
    rm -r /root/.oh-my-zsh/custom
    cp -r /root/zshcustom/custom /root/.oh-my-zsh/
    rm /root/.zshrc
    cp /root/zshcustom/.zshrc /root/.zshrc
    rm -r /root/zshcustom

    # set zsh as default shell
    which zsh && sed -i -- 's:/bin/ash:'`which zsh`':g' /etc/passwd
}

openwrtscripts()
{
    if [ -e /usr/lib ]; then
        mv /root/OpenWrtScripts /usr/lib/
    fi
}

autoprovisionStage2()
{
    log "Autoprovisioning stage2 speaking"

    # TODO this is a rather sloppy way to test whether stage2 has been done already, but this is a shell script...
    if [ $(uci get system.@system[0].log_type) == "file" ]; then
        log "Seems like autoprovisioning stage2 has been done already. Running stage3."
        #/root/autoprovision-stage3.py
    else
        signalAutoprovisionWorking

        log "Starting ntpd to update system time; otherwise the openwrt.org certificates are rejected as not yet valid."
        # Added -l hoping that it may help against ntpd quitting.
        ntpd -l -N -p openwrt.pool.ntp.org

        # CUSTOMIZE: with an empty argument it will set a random password and only ssh key based login will work.
        # please note that stage2 requires internet connection to install packages and you most probably want to log in
        # on the GUI to set up a WAN connection. but on the other hand you don't want to end up using a publically
        # available default password anywhere, therefore the random here...
        setRootPassword "u:lwf1f=pl~y.|kk+7#\`r\#aat\l*&3qd:w6y?n@11%'=pgo.&70rve,|17?8h\`r"

        openwrtscripts
        installPackages
        setupohmyzsh

        crontab - <<EOF
0 0 * * * /usr/sbin/logrotate /etc/logrotate.conf
EOF

        cat >/etc/rc.local <<EOF
# Put your custom commands here that should be executed once
# the system init finished. By default this file does nothing.

# performance governor
echo performance > /sys/devices/system/cpu/cpufreq/policy0/scaling_governor

# disable firewall
/etc/init.d/firewall disable
/etc/init.d/firewall stop

#disable dnsmasq
/etc/init.d/dnsmasq disable
/etc/init.d/dnsmasq stop

# Revert root shell to ash if zsh is not available
if grep -q '^root:.*:/usr/bin/zsh$' /etc/passwd && [ ! -x /usr/bin/zsh ]; then
    # zsh is root shell, but zsh was not found or not executable: revert to default ash
    [ -x /usr/bin/logger ] && /usr/bin/logger -s "Reverting root shell to ash, as zsh was not found on the system"
    sed -i -- 's:/usr/bin/zsh:/bin/ash:g' /etc/passwd
fi

usbmuxd
exit 0
EOF

        mkdir -p /var/log/backup_logs
        mkdir -p /root/backup_logs

        # logrotate is complaining without this directory
        mkdir -p /var/lib

        uci set system.@system[0].log_type=file
        uci set system.@system[0].log_file=/var/log/syslog
        uci set system.@system[0].log_size=0

        uci commit
        sync

        sync
        reboot
    fi
}

autoprovisionStage2