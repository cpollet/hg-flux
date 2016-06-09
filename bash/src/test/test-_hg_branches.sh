#!/usr/bin/env bash

REPOSITORY=`./setup.sh`
echo "Using repository $REPOSITORY"

(
	. ../../lib/assert.sh
	. ../main/hg-flux.sh
	cd "$REPOSITORY"
	
	assert "_hg_branches" "release/r1 feature/f2 feature/f1 closed stable default"

	assert_end examples
)