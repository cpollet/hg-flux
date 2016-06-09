#!/usr/bin/env bash

(
	cd $TARGET

	rm -rf repository
	mkdir repository
	cd repository
	echo -e "STABLE=stable\nDEVELOP=default" > .config

	hg init

	touch default
	hg add default
	hg commit -m "added default"

	hg branch stable
	touch stable
	hg add stable
	hg commit -m "started stable"

	hg up stable
	hg branch feature/f1
	touch f1
	hg add f1
	hg commit -m "added f1"

	hg up stable
	hg branch feature/f2
	touch f2
	hg add f2
	hg commit -m "added f2"	

	hg up stable
	hg branch release/r1
	touch r1
	hg add r1
	hg commit -m "added r1"

	hg up default
	hg branch closed
	touch closed
	hg add closed
	hg commit -m "added closed"
	hg commit --close-branch -m "closed"
) 1>/dev/null

echo "$TARGET/repository"