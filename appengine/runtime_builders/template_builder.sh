#!/bin/bash

set -ex

if [ -z ${CONFIG_FILE} ]
then
  echo "CONFIG_FILE is not set"
  exit 1
fi

if [ -z "${BAZEL_VERSION:+set}" ]
then
  BAZEL_VERSION=0.19.2
fi

# Install the given bazel version on linux
function update_bazel_linux {
  BAZEL_FILE="bazel-${BAZEL_VERSION}-installer-linux-x86_64.sh"
  rm -rf ~/bazel
  mkdir ~/bazel

  pushd ~/bazel
  cp $KOKORO_GFILE_DIR/$BAZEL_FILE .
  chmod +x $BAZEL_FILE
  "./$BAZEL_FILE" --user
  rm $BAZEL_FILE
  popd

  PATH="/home/kbuilder/bin:$PATH"
}

# Read the bazel version set from Job Config.
update_bazel_linux
# Running Bazel version to command.
bazel version

# default Cloud SDK version
if [ -z "${GCLOUD_FILE:+set}" ]; then
  GCLOUD_FILE=google-cloud-sdk-232.0.0-linux-x86_64.tar.gz
fi

# $KOKORO_ROOT is hardcoded to /tmpfs by kokoro
cp $KOKORO_GFILE_DIR/$GCLOUD_FILE .

# Hide the output here, it's long.
tar -xzf $GCLOUD_FILE
CUR_DIR=$(pwd)
export PATH=$CUR_DIR/google-cloud-sdk/bin:$PATH

export CLOUDSDK_PROJECT=gcp-runtimes
if [ -n "${DOCKER_NAMESPACE:+set}" ];
then
  export CLOUDSDK_PROJECT=$(echo $DOCKER_NAMESPACE | cut -d'/' -f2)
fi
gcloud config set project $CLOUDSDK_PROJECT
gcloud components install beta -q
gcloud components install alpha -q
gcloud auth configure-docker -q
#source $KOKORO_GFILE_DIR/common.sh
cd github/runtimes-common/appengine/runtime_builders
yes | sudo pip install -U pip setuptools wheel
yes | sudo pip install ruamel.yaml
python template_builder.py -f "${KOKORO_GFILE_DIR}/${CONFIG_FILE}"
