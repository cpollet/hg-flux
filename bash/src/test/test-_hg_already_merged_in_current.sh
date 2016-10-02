#!/usr/bin/env bash

REPOSITORY=`./setup.sh`
echo "Using repository $REPOSITORY"

(
	. ../../lib/assert.sh
	. ../main/hg-flux.sh
	cd "$REPOSITORY"
	
	hg up default
	assert "_hg_already_merged_in_current feature/f1" "0"
	assert "_hg_already_merged_in_current feature/f3" "1"

	assert_end _hg_already_merges_in_current
)