#!/bin/bash

CURRENT_DIR="$(pwd)"
PROJECTS_FILE="$CURRENT_DIR/projects"
BRANCH=$1
DOWNSTREAM_USER=$2
MANIFETST_FILE=rh-manifest.txt

TMP_DIR=$(mktemp -d)

# Retrodep straight from the repo has some bugs that limit it's usability
# Use local version untile that is fixed
RETRODEP="./retrodep"
if [ ! -f "$RETRODEP" ]; then
    # If no local retrodep version detected, use the global one
    RETRODEP="retrodep"
    if [ $(which $RETRODEP &>/dev/null; echo $?) -eq 1 ]; then
        echo "No retrodep detected, exiting"
        exit 1
    fi
else
    cp $RETRODEP $TMP_DIR 
    RETRODEP="$TMP_DIR/retrodep"   
fi

cd $TMP_DIR

mkdir distgit

function prepare_manifests() {
    PROJECT=$1
    US_REPO=$2
    echo "Preparing manifest file for $PROJECT"
    cd distgit
    git clone ssh://pkgs.devel.redhat.com/containers/$PROJECT
    cd $PROJECT
    git checkout -b retrodepbranch $BRANCH

    if test -f "source-repos"; then
        echo "Checking out repo pointed by source-repos file"
        mapfile < source-repos SOURCEREPOS
        DS_REPO=$(echo $SOURCEREPOS | awk -F ' ' '{print $1}')
        DS_HASH=$(echo $SOURCEREPOS | awk -F ' ' '{print $2}')
        DS_PROJECT=$(echo $DS_REPO | awk -F '/' '{print $5}')
        cd ../..

        git clone $DS_REPO
        cd $DS_PROJECT
        git checkout -b retrodepbranch $DS_HASH
        echo "Running retrodep"
        $RETRODEP -importpath $US_REPO . > ../${PROJECT}_$MANIFETST_FILE
        cd ..
        rm -rf $DS_PROJECT

    elif test -f "sources"; then
        echo "Getting sources from src tar file"
        rhpkg sources
        TAR_FILE=$(find . -name *tar.gz)
        mkdir tar
        cp $TAR_FILE tar/
        cd tar
        tar -xvf $TAR_FILE
        $RETRODEP -importpath $US_REPO . > ../../../${PROJECT}_$MANIFETST_FILE
        cd ..
        rm -rf tar
        cd ../..
    else
        echo "NO SOURCES FOUND"
    fi


}

function update_manifests() {
    PROJECT=$1

    if [ ! -f ${PROJECT}_$MANIFETST_FILE ]; then
        echo "No maniftest file generated for: $PROJECT"
        return 1
    fi

    cd distgit/$PROJECT

    cp ../../${PROJECT}_$MANIFETST_FILE $MANIFETST_FILE
    git status|grep "$MANIFETST_FILE"
    CHANGED=$?
    if [ $CHANGED -eq 0 ]
    then 
        git add rh-manifest.txt
        git commit -m "Update in rh-manifest"
        PUSH_BRANCH=$(echo $BRANCH | awk -F '/' '{print $2}')
        git push origin HEAD:$PUSH_BRANCH
        echo "Pushed new manifest for $PROJECT"
    else
        echo "No changes in $PROJECT"
    fi
    cd ../..

}

cat $PROJECTS_FILE | while read LINE
do
    if [[ -z "$LINE" ]]; then
        return
    fi
    prepare_manifests $LINE

done

cat $PROJECTS_FILE | while read LINE
do
    if [[ -z "$LINE" ]]; then
        return
    fi
    update_manifests $LINE
done

echo "Deleting tempdir: $TMP_DIR"
rm -rf $TMP_DIR
