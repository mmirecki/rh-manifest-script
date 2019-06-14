#!/bin/bash

echo "$(whoami)"
CURRENT_DIR="$(pwd)"
PROJECTS_FILE="$CURRENT_DIR/projects"
BRANCH=$1
DOWNSTREAM_USER=$2
echo $PROJECTS_FILE

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
        # echo "Installing retrodep from github.com/release-engineering/retrodep"
        # go get github.com/release-engineering/retrodep
    fi
else
    cp $RETRODEP $TMP_DIR 
    RETRODEP="$TMP_DIR/retrodep"   
fi

# MM
TMP_DIR="/tmp/tmp.W1fqdmCiH5"
cd $TMP_DIR

mkdir distgit


function prepare_manifests() {
    PROJECT=$1
    US_REPO=$2
    echo "==========\n   prepare_manifests:  $PROJECT  $REPO"
    cd distgit
    git clone ssh://pkgs.devel.redhat.com/containers/$PROJECT
    cd $PROJECT
    git checkout -b retrodepbranch $BRANCH
    mapfile < source-repos SOURCEREPOS
    DS_REPO=$(echo $SOURCEREPOS | awk -F ' ' '{print $1}')
    DS_HASH=$(echo $SOURCEREPOS | awk -F ' ' '{print $2}')
    DS_PROJECT=$(echo $DS_REPO | awk -F '/' '{print $5}')
    cd ../..


    #git clone "https://github.com/kubevirt/$PROJECT.git"
   # git clone ssh://$DOWNSTREAM_USER@code.engineering.redhat.com/$DS_REPO
    git clone $DS_REPO
    cd $DS_PROJECT
    git checkout -b retrodepbranch $DS_HASH
    echo "RUNNING RETRODEP $(pwd)"
    $RETRODEP -importpath $US_REPO . > ../${PROJECT}_rh-manifest.txt
    cd ..
    #rm -rf $PROJECT
    cp -r $PROJECT ${PROJECT}_bak
}


function update_manifests() {
    PROJECT=$1
    echo "=======  handle_project:  $PROJECT"
    #git clone ssh://pkgs.devel.redhat.com/containers/$PROJECT
    cd distgit/$PROJECT
    cp ../../${PROJECT}_rh-manifest.txt rh-manifest.txt
    git status|grep "rh-manifest.txt"
    CHANGED=$?
    if [ $CHANGED -eq 0 ]
    then 
        git add rh-manifest.txt
        git commit -m "Update in rh-manifest"
        #git push origin HEAD:$BRANCH
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
    # prepare_manifests $LINE

done

cat $PROJECTS_FILE | while read LINE
do
    if [[ -z "$LINE" ]]; then
        return
    fi
    update_manifests $LINE

done


echo "TEMPDIR: $TMP_DIR"
#rm -rf  $TMP_DIR









#git clone ssh://mmirecki@code.engineering.redhat.com/bridge-marker
 #/home/mmirecki/go/src/github.com/release-engineering/retrodep/bin/retrodep -importpath github.com/kubevirt/bridge-marker  ./bridge-marker/  2> /dev/null |tee manifest
#rm -rf bridge-marker
#git clone ssh://pkgs.devel.redhat.com/containers/bridge-marker
#cd bridge-marker/

#git checkout origin/cnv-2.0-rhel-8

#cp ../manifest .


#git clone ssh://pkgs.devel.redhat.com/containers/sriov-cni


#sriov-cni