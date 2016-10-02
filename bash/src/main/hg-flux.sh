#!/usr/bin/env bash

function _hg_available_streams {
	echo "feature fix story epic release"
}

function _hg_config {
	key=$1
	echo `grep "$key" .config | cut -d'=' -f2`
}

function _hg_is_stream {
	local stream=$1

	for e in `_hg_available_streams`; do
    	if [[ "$e" == "$stream" ]]; then
        	echo "1"
        	return
    	fi
	done
	echo "0"
}

function _hg_print_usage {
	echo "Usage:"
	echo "$ hg_start <stream> <name>"
	echo "$ hg_finish <stream> <name>"
	echo "$ hg_abort <stream> <name>"
	echo "$ hg_release_start <name>"
	echo ""
	echo "<stream> is one of [`_hg_available_streams`]"
}

function _hg_branches {
	echo `hg branches --closed | cut -d' ' -f1`
}

function _hg_branch_already_exists {
	local branch=$1
	for existing_branch in `_hg_branches`; do
		if [[ "$branch" == "$existing_branch" ]]; then
			echo "1"
			return
		fi
	done
	echo "0"
}

function _hg_is_repo_clean {
	if [[ `hg status -q | wc -l` -eq 0 ]]; then
		echo "1"
	else
		echo "0"
	fi
}

function _hg_sanity_check {
	if [[ `_hg_is_repo_clean` -eq 0 ]]; then
		echo "You have uncommitted changes. Please commit before proceeding."
		return 1
	fi

	local stream=$1

	if [[ `_hg_is_stream $stream` -eq 0 ]]; then
		_hg_print_usage
		echo ""
		echo "Please provide a valid <stream>."
		return 1;
	fi

	local branch_name=$2

	if [[ "$branch_name" == "" ]]; then
		_hg_print_usage
		echo ""
		echo "Please provide a $stream <name>."
		return 1
	fi
}

function _hg_display_current_branch {
	echo "You are on `hg branch`"
}

function _hg_already_merged_in_current {
	branch=$1
	output=`hg log --rev "ancestors(.) and $branch" | wc -l`
	if [[ "$output" -eq "0" ]]; then
		echo "0"
	else
		echo "1"
	fi
}

function _hg_branches_to_merge {
	current_branch=`hg branch`
	available_branches=""
	for branch in `_hg_branches`; do
		if [[ `_hg_already_merged_in_current "$branch"` -ne "1" ]]; then
			available_branches="$available_branches $branch"
		fi
	done
	echo `echo "$available_branches" | sed -e "s/^ //g"`
}

function hg_log {
	hg log -G | less
}

function hg_start {
	_hg_sanity_check $@
	if [[ $? -ne 0 ]]; then
		return $?
	fi

	local stream=$1
	local branch=$2

	local full_branch_name="$stream/$branch"

	if [[ `_hg_branch_already_exists "$full_branch_name"` -eq 1 ]]; then
		echo "Branch $full_branch_name already exist"
		return 1
	fi

	local stable=`_hg_config STABLE`
	echo "Starting new branch [$full_branch_name] from $stable"
	hg up "$stable"
	hg branch $full_branch_name
	hg commit -m "[flux] created $stream branch $full_branch_name"
	_hg_display_current_branch
}

function hg_finish {
	_hg_sanity_check $@
	if [[ $? -ne 0 ]]; then
		return $?
	fi

	local stream=$1
	local branch=$2

	local full_branch_name="$stream/$branch"

	if [[ `_hg_branch_already_exists "$full_branch_name"` -eq 0 ]]; then
		echo "Branch $full_branch_name does not exist"
		return 1
	fi

	local develop=`_hg_config DEVELOP`
	local stable=`_hg_config STABLE`
	hg up "$full_branch_name"
	hg commit --close -m "[flux] closed $full_branch_name"

	if [[ "$stream" == "release" ]]; then
		hg up "$stable"
		hg merge "$full_branch_name"
		hg commit -m "[flux] merged $full_branch_name to $stable"
	fi

	hg up "$develop"
	hg merge "$full_branch_name"
	hg commit -m "[flux] merged $full_branch_name to $develop"
	_hg_display_current_branch
}

function hg_abort {
	_hg_sanity_check $@
	if [[ $? -ne 0 ]]; then
		return $?
	fi

	local stream=$1
	local branch=$2

	local full_branch_name="$stream/$branch"

	if [[ `_hg_branch_already_exists "$full_branch_name"` -eq 0 ]]; then
		echo "Branch $full_branch_name does not exist"
		return 1
	fi

	local develop=`_hg_config DEVELOP`
	hg up $full_branch_name
	hg commit --close -m "[flux] closed $full_branch_name without merging it"
	hg up "$develop"
	_hg_display_current_branch
}

function hg_merge {
	_hg_display_current_branch
	_PS3=$PS3
	PS3="Which branch do you want to merge? "

	more="y"
	while [[ "$more" == "y" ]]; do
		available_branches=`_hg_branches_to_merge`

		if [[ "$available_branches" == "" ]]; then
			echo "No more branches to merge"
			return 0
		fi

		branches=(`echo ${available_branches}`)

		select branch in $branches; do
			if [[ "$branch" != "" ]]; then
				echo "Merging $branch to `hg branch`"

				hg merge "$branch"
				hg commit -m "[flux] merged $branch in `hg branch`"

				break
			fi
		done

		echo -n "Merge other branch? [y/n] "
		read more
	done

	PS3=_PS3
}

# hg_contains <branch> <rev>
# tell if <rev> is contained in <branch>
function hg_contains {
	branch=$1
	rev=$2

	output=`hg log --rev "ancestors($branch) and $rev" | wc -l`
	if [[ "$output" -eq "0" ]]; then
		echo "$rev is NOT contained in $branch"
	else
		echo "$rev is contained in $branch"
	fi
}



