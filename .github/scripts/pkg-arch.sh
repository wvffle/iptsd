#!/usr/bin/env bash

if [ -z "$1" ]; then
	$0 install
	$0 build
	$0 sign
	$0 release
	exit
fi

case "$1" in
install)
	pacman -Syu --noconfirm
	pacman -S --noconfirm sudo binutils fakeroot base-devel meson libinih
	;;
build)
	# Fix permissions (can't makepkg as
	echo "nobody ALL=(ALL) NOPASSWD: /usr/bin/pacman" >> /etc/sudoers
	chown -R nobody .

	# Package compression settings (Matches latest Arch)
	export PKGEXT='.pkg.tar.zst'
	export COMPRESSZST=(zstd -c -T0 --ultra -20 -)

	# Build
	su nobody --pty -p -s /bin/bash -c 'makepkg -f --noconfirm'
	;;
sign)
	# import GPG key
	echo "$GPG_KEY" | base64 -d | gpg --import --no-tty --batch --yes
	export GPG_TTY=$(tty)

	# sign package
	ls *.pkg.tar.zst | xargs -L1 gpg --detach-sign --batch \
		--no-tty -u $GPG_KEY_ID
	;;
release)
	mkdir release
	mv *.pkg.tar.zst{,.sig} release
	;;
esac
