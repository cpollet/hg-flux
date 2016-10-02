#!/usr/bin/env bash

REPOSITORY=`./setup.sh`
echo "Using repository $REPOSITORY"

(
	. ../../lib/assert.sh
	. ../main/hg-flux.sh
	cd "$REPOSITORY"
	
	assert "_hg_branches" "default release/r1 feature/f2 feature/f1 feature/f3 closed stable"

	assert_end _hg_branches
)