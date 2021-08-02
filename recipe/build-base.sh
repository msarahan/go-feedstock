#!/bin/bash

set -euxo pipefail

# This is a fix for user.Current issue
export USER="${USER:-conda}"
export HOME="${HOME:-$(cd $SRC_DIR/..;pwd)}"


# Use precompiled bootstrap
if [[ ${target_platform} != "linux-64" ]]; then
  export GOROOT_BOOTSTRAP=$SRC_DIR/go-bootstrap
else
  export GOCACHE=off
fi

# Do not use GOROOT_FINAL. Otherwise, every conda environment would
# need its own non-hardlinked copy of the go (+100MB per env).
# It is better to rely on setting GOROOT during environment activation.
#
# c.f. https://github.com/conda-forge/go-feedstock/pull/21#discussion_r202513916
export GOROOT=$SRC_DIR/go


if [[ "${target_platform}" == "osx-64" ]]; then
  export GOOS=darwin
  export GOARCH=amd64
elif [[ "${target_platform}" == "osx-arm64" ]]; then
  export GOOS=darwin
  export GOARCH=arm64
fi

# Print diagnostics before building
env | sort


# Build golang
pushd $GOROOT/src
./make.bash -v
popd


# Don't need the cached build objects
rm -fr ${GOROOT}/pkg/obj


# Dropping the verbose option here, +8000 files
cp -a ${GOROOT} ${PREFIX}/go


# Remove Invalid UTF-8 Filename and conflict with libarchive
# c.f. https://github.com/conda-forge/staged-recipes/pull/9535#discussion_r403512142
# c.f. https://github.com/conda-forge/go-feedstock/issues/83
rm -f "${PREFIX}"/go/test/fixedbugs/issue27836.go
rm -rf "${PREFIX}"/go/test/fixedbugs/issue27836.dir

# Right now, it's just go and gofmt, but might be more in the future!
# We don't move files, and instead rely on soft-links
mkdir -p ${PREFIX}/bin && pushd $_

if [[ "${build_platform}" != "${target_platform}" ]]; then
  find ../go/bin/${GOOS}_${GOARCH} -type f -exec ln -s {} . \;
else
  find ../go/bin -type f -exec ln -s {} . \;
fi
