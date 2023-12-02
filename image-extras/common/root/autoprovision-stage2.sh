#!/bin/sh

# autoprovision stage 2: this script will be executed upon boot if the extroot was successfully mounted (i.e. rc.local is run from the extroot overlay)

. /root/autoprovision-functions.sh

installPackages()
{
    signalAutoprovisionWaitingForUser

    until (opkg update)
     do
      log "opkg update failed. No internet connection? Retrying in 15 seconds..."
       sleep 15
        # Initiate a synchronous time update.
        ntpd -d -q -n -p openwrt.pool.ntp.org
    done

    signalAutoprovisionWorking

    log "Autoprovisioning stage2 is about to install packages"
    # switch ssh from dropbear to openssh (needed to install sshtunnel)
    opkg remove dropbear
    opkg install openssh-server openssh-sftp-server sshtunnel

    /etc/init.d/sshd enable
    mkdir /root/.ssh
    chmod 0700 /root/.ssh
    mv /etc/dropbear/authorized_keys /root/.ssh/
    rm -rf /etc/dropbear

    # save opkg lists stored on extroot instead of ram
    sed -i -e "/^lists_dir\s/s:/var/opkg-lists$:/usr/lib/opkg/lists:" /etc/opkg.conf
    opkg update

    # CUSTOMIZE
    # install some more packages that don't need any extra steps
    #opkg install lua luci ppp-mod-pppoe screen mc unzip logrotate
    
    opkg download --cache /tmp ath10k-firmware-qca4019 ath10k-firmware-qca9888 kmod-ath10k
    opkg remove ath10k-firmware-qca4019-ct ath10k-firmware-qca9888-ct kmod-ath10k-ct
    opkg install --cache /tmp ath10k-firmware-qca4019 ath10k-firmware-qca9888 kmod-ath10k
    opkg install --force-overwrite syslog-ng
    opkg install adguardhome ath10k-board-qca4019 ath10k-board-qca9888 attendedsysupgrade-common auc base-files busybox ca-bundle ca-certificates nginx luci-ssl-nginx nginx-mod-luci nginx-mod-luci-ssl nginx-mod-ubus nginx-ssl nginx-ssl-util nginx-util
    opkg install cgi-io collectd collectd-mod-cpu collectd-mod-cpufreq collectd-mod-ethstat collectd-mod-exec collectd-mod-interface collectd-mod-iptables collectd-mod-iwinfo collectd-mod-load collectd-mod-memory
    opkg install collectd-mod-network collectd-mod-rrdtool collectd-mod-sensors collectd-mod-sqm collectd-mod-thermal collectd-mod-wireless curl diffutils dnscrypt-proxy2 dnsmasq dropbear fstools
    opkg install fwtool getrandom git git-http glib2 hostapd-common ip-full iptables-mod-ipopt iptables-zz-legacy iw iwinfo jansson4 jshn jsonfilter kernel kmod-cfg80211 kmod-crypto-acompress
    opkg install kmod-crypto-aead kmod-crypto-ccm kmod-crypto-cmac kmod-crypto-crc32c kmod-crypto-ctr kmod-crypto-gcm kmod-crypto-gf128 kmod-crypto-ghash kmod-crypto-hash kmod-crypto-hmac
    opkg install kmod-crypto-kpp kmod-crypto-lib-chacha20 kmod-crypto-lib-chacha20poly1305 kmod-crypto-lib-curve25519 kmod-crypto-lib-poly1305 kmod-crypto-manager kmod-crypto-null kmod-crypto-rng
    opkg install kmod-crypto-seqiv kmod-crypto-sha512 kmod-gpio-button-hotplug kmod-hwmon-core kmod-ifb kmod-ipt-core kmod-ipt-ipopt kmod-leds-gpio kmod-lib-crc-ccitt kmod-lib-crc16 kmod-lib-crc32c
    opkg install kmod-lib-lzo kmod-mac80211 kmod-nf-conntrack kmod-nf-conntrack-netlink kmod-nf-conntrack6 kmod-nf-flow kmod-nf-ipt kmod-nf-log kmod-nf-log6 kmod-nf-nat kmod-nf-reject kmod-nf-reject6
    opkg install kmod-nfnetlink kmod-nft-core kmod-nft-fib kmod-nft-nat kmod-nft-offload kmod-nls-base kmod-kmod-pppox kmod-sched-cake kmod-sched-core kmod-scsi-core kmod-slhc kmod-udptunnel4
    opkg install kmod-udptunnel6 kmod-usb-core kmod-usb-dwc3 kmod-usb-dwc3-qcom kmod-usb-ehci kmod-usb-ledtrig-usbport kmod-usb-xhci-hcd kmod-usb2 kmod-usb3 kmod-wireguard libatomic1
    opkg install libattr libblkid1 libblobmsg-json20230523 libbpf1 libc libcap libcomerr0 libcurl4 libdbi libelf1 libext2fs2 libfdisk1 libffi libgcc1 libip4tc2 libip6tc2 libiptext0 libiptext6-0 libiwinfo-data
    opkg install libiwinfo20230701 libjson-c5 libjson-script20230523 libltdl7 liblua5.1.5 liblua5.3-5.3 liblucihttp-ucode liblucihttp0 libmbedtls12 libmnl0 libncurses6 libnftnl11 libnghttp2-14 libnl-tiny1 libopenssl3
    opkg install libparted libpcap1 libpcre libpcre2 libpopt0 libpthread libreadline8 librrd1 librt libsensors5 libsmartcols1 libss2 libssh2-1 libstdcpp6 libsysfs2 libubox20230523 libubus20230605 libuci20130104 
    opkg install libuclient20201210 libucode20220812 libucode20230711 libustream-mbedtls20201210 libuuid1 libxtables12 lm-sensors lm-sensors-detect logrotate luci-app-advanced-reboot luci-app-attendedsysupgrade luci-app-firewall
    opkg install luci-app-nlbwmon luci-app-opkg luci-app-sqm luci-app-statistics luci-base luci-light luci-mod-admin-full luci-mod-dashboard luci-mod-network luci-mod-status luci-mod-system luci-proto-ipv6 
    opkg install luci-proto-ppp luci-proto-wireguard luci-ssl luci-theme-bootstrap luci-theme-material monit mtd nano netifd netperf nftables-json nlbwmon nmap-full odhcp6c odhcpd-ipv6only
    opkg install openwrt-keyring opkg parted perl perlbase-base perlbase-bytes perlbase-class perlbase-config perlbase-cwd perlbase-errno perlbase-essential perlbase-fcntl perlbase-file 
    opkg install perlbase-filehandle perlbase-i18n perlbase-integer perlbase-io perlbase-list perlbase-locale perlbase-params perlbase-posix perlbase-re perlbase-scalar perlbase-selectsaver 
    opkg install perlbase-socket perlbase-symbol perlbase-tie perlbase-unicore perlbase-utf8 perlbase-xsloader ppp procd procd-seccomp procd-ujail px5g-mbedtls rpcd rpcd-mod-file rpcd-mod-iwinfo 
    opkg install rpcd-mod-luci rpcd-mod-rpcsys rpcd-mod-rrdns rpcd-mod-ucode rrdtool1 sqm-scripts sysfsutils tc-tiny tcpdump terminfo ubi-utils uboot-envtools ubox ubus ubusd uci uclient-fetch 
    opkg install ucode ucode-mod-fs ucode-mod-html ucode-mod-math ucode-mod-nl80211 ucode-mod-rtnl ucode-mod-ubus ucode-mod-uci ucode-mod-uloop uhttpd uhttpd-mod-ubus unzip urandom-seed urngd usign wget-ssl 
    opkg install wireguard-tools wireless-regdb wpad-basic-mbedtls xtables-legacy zlib zsh

    # setup ohmyzsh once zsh is installed
    
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

    # move custom ohmyzsh configurations to ohmyzsh directory

    rm -r /root/.oh-my-zsh/custom
    cp -r /root/zshcustom/custom /root/.oh-my-zsh/
    rm /root/.zshrc
    cp /root/zshcustom/.zshrc /root/.zshrc
    rm -r /root/zshcustom

    # set zsh as default shell

    which zsh && sed -i -- 's:/bin/ash:'`which zsh`':g' /etc/passwd

    # just in case if we were run in a firmware that didn't already have luci
    /etc/init.d/uhttpd enable
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
        #setRootPassword ""

        installPackages

        crontab - <<EOF
0 0 * * * /usr/sbin/logrotate /etc/logrotate.conf
EOF

        cat >/etc/rc.local <<EOF

# performance governor
echo performance > /sys/devices/system/cpu/cpufreq/policy0/scaling_governor

#Change % when cpu scales up
echo "5" > /sys/devices/system/cpu/cpufreq/ondemand/up_threshold

#Multiple of sampling rate (.02 seconds) to scale down = .04 seconds
echo "2" > /sys/devices/system/cpu/cpufreq/ondemand/sampling_down_factor

# min scaling frequency: set to 800MHz because of L2 cache issues
echo 800000 > /sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq

# Disable Airtime Fairness (ATF) (default 3)
echo 0 > /sys/kernel/debug/ieee80211/phy0/airtime_flags
echo 0 > /sys/kernel/debug/ieee80211/phy1/airtime_flags

# Revert root shell to ash if zsh is not available
if grep -q '^root:.*:/usr/bin/zsh$' /etc/passwd && [ ! -x /usr/bin/zsh ]; then
    # zsh is root shell, but zsh was not found or not executable: revert to default ash
    [ -x /usr/bin/logger ] && /usr/bin/logger -s "Reverting root shell to ash, as zsh was not found on the system"
    sed -i -- 's:/usr/bin/zsh:/bin/ash:g' /etc/passwd
fi

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
        reboot
    fi
}

autoprovisionStage2