#!/bin/busybox sh

# ================ SPLASH ================ #

splash() {
    clear
    printf "\n"
    echo '==============================================================================='
    echo '  ██████╗ ██╗   ██╗██████╗  ██████╗ ██████╗  ██████╗ ██████╗  ██████╗ ███████╗ '
    echo ' ██╔═══██╗██║   ██║██╔══██╗██╔═══██╗██╔══██╗██╔═══██╗██╔══██╗██╔═══██╗██╔════╝ '
    echo ' ██║   ██║██║   ██║██████╔╝██║   ██║██████╔╝██║   ██║██████╔╝██║   ██║███████╗ '
    echo ' ██║   ██║██║   ██║██╔══██╗██║   ██║██╔══██╗██║   ██║██╔══██╗██║   ██║╚════██║ '
    echo ' ╚██████╔╝╚██████╔╝██║  ██║╚██████╔╝██████╔╝╚██████╔╝██║  ██║╚██████╔╝███████║ '
    echo '  ╚═════╝  ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚══════╝ '
    echo '==============================================================================='
    printf "\n"
}

footer() {
    printf "\n"
    echo '==============================================================================='
    echo '| | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | |'
    echo '| | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | |'
    echo 'v v v v v v v v v v v v v v v v v v v v v v v v v v v v v v v v v v v v v v v v'
    echo '==============================================================================='
    printf "\n"
}

# ======================================== #

# ================ Processing ================ #

# Parse the kernel command line
# Format of all command line options passed into init must be "irfs.[opt_name]"
# For example: irfs.asdf=....
cmdline() {
    local value
    value=" $(cat /proc/cmdline) "
    value="${value##* "${1}"=}"
    value="${value%% *}"
    [ "${value}" != "" ] && echo "${value}"
}

# ============================================ #


# ================ Interactive console ================ #

get_ic () {
    cmd="$(echo "$1" | sed -e "s?\\\\n?\\n?g" -e "s?\"?\\\\\"?g")"
    setsid sh -c "exec sh -c \". /funcions_init.sh && $cmd\" </dev/tty1 >/dev/tty1 2>&1"
}

# ===================================================== #


# ================ Bookkeeping ================ #

rescue_shell() {
    get_ic "shecho_red \"Error: $1;\""
    get_ic "shecho_yellow \"Dropping to rescue shell...\""
    get_ic "shecho \"Run '. /funcions_init.sh' to have access to the functions defined in /init.\""
    echo "Error: $1; Dropping to rescue shell..." >> error.dump
    setsid sh -c 'exec sh </dev/tty1 >/dev/tty1 2>&1'
}

# ============================================= #


# ================ Output ================ #

# Echo to the console
shecho () {
    printf "%s\n" "$1"
}

# Echo to the console but in green
shecho_green () {
    printf "\e[0;92m%s\e[0;00m\n" "$1"
}

# Echo to the console but in yellow
shecho_yellow() {
    printf "\e[0;93m%s\e[0;00m\n" "$1"
}

# Echo to the console but in cyan
shecho_cyan() {
    printf "\e[0;96m%s\e[0;00m\n" "$1"
}

# Echo to the console but in red
shecho_red () {
    printf "\e[0;91m%s\e[0;00m\n" "$1"
}

# Printf to the console
spf () {
    printf "%s" "$1"
}

# Printf to the console but in green
spf_green () {
    printf "\e[0;92m%s\e[0;00m" "$1"
}

# Printf to the console but in yellow
spf_yellow() {
    printf "\e[0;93m%s\e[0;00m" "$1"
}

# Printf to the console but in cyan
spf_cyan() {
    printf "\e[0;96m%s\e[0;00m" "$1"
}

# Printf to the console but in red
spf_red () {
    printf "\e[0;91m%s\e[0;00m" "$1"
}

# ======================================== #


# ================ Input ================ #

get_input () {
    read -r input && echo "$input" && unset input
}

get_secret () {
    read -rs secret && echo "$secret" && unset secret
}

# ======================================= #


# ================ Devices ================ #

get_dev() {
    findfs "$1" | grep "/dev/*"
}

get_kcmd_dev () {
    findfs "$(cmdline "$1")" | grep "/dev/*"
}

wait_for_lvm () {
    vg_uuid="$(cmdline "$1" | sed -e "s|UUID=||g")"
    while [ "$(lvm pvdisplay | grep "$vg_uuid")" = "" ]; do
        sleep 0.1
    done
}

wait_for_device () {
    while [ "$(get_dev "$1")" = "" ]; do
        sleep 0.1
    done
}

wait_for_kcmd_device () {
    while [ "$(get_kcmd_dev "$1")" = "" ]; do
        sleep 0.1
    done
}

unwait_for_device () {
    while [ "$(get_dev "$1")" != "" ]; do
        sleep 0.1
    done
}

unwait_for_kcmd_device () {
    while [ "$(get_kcmd_dev "$1")" != "" ]; do
        sleep 0.1
    done
}

enable_discard () {
    if [ "$(cmdline "irfs.root_dev_discard")" = "true" ]; then
        echo ",discard"
    fi
}

mount_dev () {
    mount -o "ro$(enable_discard)" "$1" /mnt/root \
        || rescue_shell "Unable to find root device"
}

mount_kcmd_dev () {
    mount -o "ro$(enable_discard)" "$(get_kcmd_dev "$1")" /mnt/root \
        || rescue_shell "Unable to find root device"
}

mount_subvol () {
    mount -o "ro,subvolid=$(cmdline "$2")$(enable_discard)" "$1" /mnt/root \
        || rescue_shell "Unable to find root device"
}

mount_kcmd_subvol () {
    mount -o "ro,subvolid=$(cmdline "$2")$(enable_discard)" "$(get_kcmd_dev "$1")" /mnt/root \
        || rescue_shell "Unable to find root device"
}

lvm_online () {
    wait_for_lvm "$1"
    lvm vgchange -ay || rescue_shell "vgchange failed."
    lvm vgscan --mknodes || rescue_shell "vgscan failed."
    shecho_green "LVM online"
}

# ========================================= #


# ================ cryptography ================ #

# Open cryptsetup device with a passphrase
kcmd_crypt_open_with_passphrase () {
    ppp="$(get_secret)"
    if [ "$(cmdline "irfs.root_dev_discard")" = "true" ]; then
        echo "$ppp" | cryptsetup open --type luks --allow-discards "$(get_kcmd_dev "$1")" cryptvol \
            || rescue_shell "Failed to open the encrypted partition with cryptsetup"
    else
        echo "$ppp" | cryptsetup open --type luks "$(get_kcmd_dev "$1")" cryptvol \
            || rescue_shell "Failed to open the encrypted partition with cryptsetup"
    fi
    ppp="00000000000000000000000000000000000000000000000000000000000000000000000000" && unset ppp
}

kcmd_crypt_open_keydrive_with_passphrase () {
    ppp="$(get_secret)"
    echo "$ppp" | cryptsetup open --type luks "$(get_kcmd_dev "$1")" keydrive \
        || rescue_shell "Failed to open the encrypted keydrive partition with cryptsetup"
    ppp="00000000000000000000000000000000000000000000000000000000000000000000000000" && unset ppp
}

crypt_open_with_keydrive () {
    key="${1}/$(cmdline "irfs.keyfile")"
    if [ "$(cmdline "irfs.root_dev_discard")" = "true" ]; then
        cryptsetup open --type luks -d "$key" --allow-discards "$2" cryptvol \
            || rescue_shell "Failed to open the encrypted partition with cryptsetup"
    else
        cryptsetup open --type luks -d "$key" "$2" cryptvol \
            || rescue_shell "Failed to open the encrypted partition with cryptsetup"
    fi
}

# ============================================== #


# ================ INIT ================ #

/bin/busybox --install -s || rescue_shell "Failed to install busybox"
grep -B999 "^#.*== INIT ==" /init > /funcions_init.sh || rescue_shell "Failed to export init functions"

mkdir -p /etc /mnt/root
touch /etc/mtab
sync

mount -t devtmpfs none /dev || rescue_shell "Failed to mount devtmpfs"
mount -t proc proc /proc || rescue_shell "Failed to mount procfs"
mount -t sysfs none /sys || rescue_shell "Failed to mount sysfs"

echo 1 > /proc/sys/kernel/printk

shecho_green "$(splash)"

if [ "$(cmdline "irfs.crypt_uuid")" != "" ]; then
    wait_for_kcmd_device "irfs.crypt_uuid"

    if [ "$(cmdline "irfs.key_drive_uuid")" = "" ]; then
        get_ic "shecho_yellow \"Decrypting root partition...\""
        prompt="Input passphrase for encrypted volume on partition: $(get_kcmd_dev "irfs.crypt_uuid")\n> "
        get_ic "spf \"$prompt\""
        get_ic "kcmd_crypt_open_with_passphrase \"irfs.crypt_uuid\""
        get_ic "shecho_green \"!! Decryption successful !!\""
    else
        get_ic "shecho_yellow \"Please insert key drive...\""
        wait_for_kcmd_device "irfs.key_drive_uuid"

        get_ic "shecho_yellow \"Decrypting key drive...\""
        prompt="Input passphrase for encrypted volume on partition: $(get_kcmd_dev "irfs.key_drive_uuid")\n> "
        get_ic "spf \"$prompt\""

        get_ic "kcmd_crypt_open_keydrive_with_passphrase \"irfs.key_drive_uuid\""
        get_ic "shecho \"Key drive decrypted\""

        mkdir -p "/tmp/keydrive"
        mount -o ro "/dev/mapper/keydrive" "/tmp/keydrive" \
            || rescue_shell "Unable to find key drive device"
        get_ic "shecho_yellow \"Decrypting root partition...\""
        crypt_open_with_keydrive "/tmp/keydrive" "$(get_kcmd_dev "irfs.crypt_uuid")"
        umount /dev/mapper/keydrive
        cryptsetup close keydrive
        get_ic "shecho_green \"!! Decryption successful !!\""

        get_ic "shecho_yellow \"Please remove key drive...\""
        unwait_for_kcmd_device "irfs.key_drive_uuid"
    fi
fi

lvm_online "irfs.root_pv_uuid"

if [ "$(cmdline "irfs.btrfs_subvol_id")" = "" ]; then
    mount_dev "/dev/mapper/vg0-root"
else
    mount_subvol "/dev/mapper/vg0-root" "irfs.btrfs_subvol_id"
fi

if [ "$(cmdline "irfs.rescue")" = "true" ]; then
    rescue_shell "Rescue shell requested from arguments"
fi

umount /proc /sys /dev || rescue_shell "Failed to unmount temporary filesystems"

shecho_green "$(footer)"

exec switch_root /mnt/root /sbin/init || rescue_shell "Failed to switch to real root filesystem"

# ====================================== #
