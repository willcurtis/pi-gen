#!/bin/bash -e

# Add the WLAN Pi Packagecloud apt repositories from keys pinned in this repo,
# instead of piping packagecloud.io's setup script into bash as root.
# The result matches what that script installs: the same source and keyring
# paths, so existing devices and tooling see no difference.
#
# Key fingerprints (check against https://packagecloud.io/wlanpi/<repo>/gpgkey
# when Packagecloud rotates a key):
#   wlanpi/main  79378B543F37160CB0589D7F52DC523CF37BC36B
#   wlanpi/dev   AD717AB09410DD7CB21D43C93EF5894BA8D018F8

# ca-certificates for the HTTPS repo. curl and gnupg were previously pulled in
# by the setup script, and later steps rely on them (for example the Kismet
# key import in wlanpi2-full), so install them here to keep the image the same.
on_chroot <<CHEOF
	apt-get update
	apt-get install -y ca-certificates curl gnupg
CHEOF

add_packagecloud_repo() {
	local repo="$1"
	local keyring="/etc/apt/keyrings/wlanpi_${repo}-archive-keyring.gpg"
	local url="https://packagecloud.io/wlanpi/${repo}/debian/"

	log "Add packagecloud wlanpi/${repo} repository"
	gpg --dearmor < "files/wlanpi_${repo}.gpg.key" > "${STAGE_WORK_DIR}/wlanpi_${repo}-archive-keyring.gpg"
	install -d -m 755 "${ROOTFS_DIR}/etc/apt/keyrings"
	install -m 644 "${STAGE_WORK_DIR}/wlanpi_${repo}-archive-keyring.gpg" "${ROOTFS_DIR}${keyring}"
	cat > "${ROOTFS_DIR}/etc/apt/sources.list.d/wlanpi_${repo}.list" <<-EOF
		deb [signed-by=${keyring}] ${url} ${RELEASE} main
		deb-src [signed-by=${keyring}] ${url} ${RELEASE} main
	EOF
	chmod 644 "${ROOTFS_DIR}/etc/apt/sources.list.d/wlanpi_${repo}.list"
}

add_packagecloud_repo main

if [ "${INCLUDE_PACKAGECLOUD_DEV}" = "1" ]; then
	add_packagecloud_repo dev
else
	log "Skipping add packagecloud wlanpi/dev repository - see GitHub Actions workflow inputs"
fi

on_chroot <<CHEOF
	apt-get update
CHEOF
