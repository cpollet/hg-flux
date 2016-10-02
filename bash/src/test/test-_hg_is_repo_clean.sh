#!/usr/bin/env bash

REPOSITORY=`./setup.sh`
echo "Using repository $REPOSITORY"

(
	. ../../lib/assert.sh
	. ../main/hg-flux.sh
	cd "$REPOSITORY"
	
	assert "_hg_is_repo_clean" "1"

	touch new_file

	assert "_hg_is_repo_clean" "1"

	echo "new content" > default

	assert "_hg_is_repo_clean" "0"

	assert_end _hg_is_repo_clean
)