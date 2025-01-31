#!/usr/bin/env bash

#############################
# Build tar.gz in a container
#############################
build-release() {
    # Args:
    # $1 version

    export VERSION=$1
    if [ -z "$VERSION" ]; then
        echo "First argument should be version"
        exit 1
    fi

    # Ensure the types and unit tests are ok, but don't bother with linting
    ./ul test-mypy
    ./ul test-pytest

    info "Releasing Ulauncher $VERSION"

    set -e

    create_deb

    # Upload if tag doesn't contain "test"
    if [[ $(echo "$VERSION" | tr '[:upper:]' '[:lower:]') != *test* ]]; then
        launchpad_upload
        aur_update
    fi
}

create_deb() {
    DEB_VERSION=$(echo "$VERSION" | tr "-" "~")
    step1="ln -s /var/node_modules preferences-src" # take node modules from cache
    step2="ln -s /var/bower_components preferences-src"
    step3="./ul test"
    step4="./ul build-deb --deb"
    step5="./ul build-targz"

    h1 "Creating .deb"
    set -x
    docker run \
        -v $(pwd):/root/ulauncher \
        --name ulauncher-deb \
        $BUILD_IMAGE \
        bash -c "$step1 && $step2 && $step3 && $step4 && $step5"
    set +x
    docker cp ulauncher-deb:/tmp/ulauncher_$VERSION.tar.gz .
    docker cp "ulauncher-deb:/tmp/ulauncher_${DEB_VERSION}_all.deb" "ulauncher_${VERSION}_all.deb"
    docker rm ulauncher-deb
}

aur_update() {
    # Note that this script does not need to run with Docker in any specific
    # environment/distro, but it was written that way and it works,
    # so it still does use Docker and https://hub.docker.com/r/ulauncher/arch
    h1 "Push new PKGBUILD to AUR stable channel"
    workdir=/home/notroot/ulauncher
    chmod 600 scripts/aur_key
    sudo chown 1000:1000 scripts/aur_key

    docker run \
        --rm \
        -u notroot \
        -w $workdir \
        -v $(pwd):$workdir \
        ulauncher/arch:5.0 \
        bash -c "./ul aur-update $VERSION"
}

launchpad_upload() {
    # check if release name contains prerelease-separator "-" to decide which PPA to use
    if [[ "$VERSION" == *-* ]]; then
        PPA="agornostal/ulauncher-dev"
    else
        PPA="agornostal/ulauncher"
    fi
    
    jammy="PPA=$PPA RELEASE=jammy ./ul build-deb $VERSION --upload"
    impish="PPA=$PPA RELEASE=impish ./ul build-deb $VERSION --upload"
    focal="PPA=$PPA RELEASE=focal ./ul build-deb $VERSION --upload"

    # extracts ~/.shh for uploading package to ppa.launchpad.net via sftp
    # then uploads each release
    h1 "Launchpad upload"
    set -x
    docker run \
        --rm \
        -v $(pwd):/root/ulauncher \
        $BUILD_IMAGE \
        bash -c "tar -xvf scripts/launchpad.ssh.tar -C / && $jammy && $impish && $focal"
    set +x
}
