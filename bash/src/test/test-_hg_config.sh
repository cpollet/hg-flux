#!/usr/bin/env bash

REPOSITORY=`./setup.sh`
echo "Using repository $REPOSITORY"

(
	. ../../lib/assert.sh
	. ../main/hg-flux.sh
	cd "$REPOSITORY"
	
	assert "_hg_config STABLE" "stable"
	assert "_hg_config DEVELOP" "default"

	assert_end examples
)