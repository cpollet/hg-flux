#!/usr/bin/env bash

(
	cd ../..
	rm -rf target
	mkdir target
	cd target
)

export TARGET=$(
	cd ../../target
	echo `pwd`
)
echo "Target is $TARGET"

failed=""
for file in `ls test-*`; do
	echo "Executing $file..."
	./$file
	if [[ "$?" -ne "0" ]]; then
		failed="$failed $file"
	else
		echo " success"
	fi
done

if [[ "$failed" != "" ]]; then
	echo "FAILURE: $failed"
else
	echo "SUCCESS"
fi