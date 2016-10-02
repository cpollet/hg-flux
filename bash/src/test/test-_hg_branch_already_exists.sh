#!/usr/bin/env bash

REPOSITORY=`./setup.sh`
echo "Using repository $REPOSITORY"

(
	. ../../lib/assert.sh
	. ../main/hg-flux.sh
	cd "$REPOSITORY"
	
	assert "_hg_branch_already_exists release/r1" "1"
	assert "_hg_branch_already_exists new_branch" "0"

	assert_end _hg_branch_already_exists
)