#!/bin/bash

set -ex

if [ -z ${CONFIG_FILE} ]
then
	echo "CONFIG_FILE is not set"
	exit 1
fi

source $KOKORO_GFILE_DIR/common.sh
cd runtimes-common/appengine/runtime_builders
python template_builder.py -f "config/${CONFIG_FILE}"
