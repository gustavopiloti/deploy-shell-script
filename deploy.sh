#! /bin/bash

# Check if current branch is master
if [ $(git rev-parse --abbrev-ref HEAD) != "master" ]
then
    echo "You are not in master branch"

    exit 0
fi

DATETIME=$(date +"%Y%m%d%H%M")

if [ -f "deploy_history.json" ]
then
    FIRSTDEPLOY=0
    LASTDEPLOYDATETIME=$(cat deploy_history.json | jq ".deploys[0].dateTime")
    # TODO: Manipular a data para Y-m-d H:M
    # LASTDEPLOYDATETIME=$(date -d ${JSON} +"%Y%m%d%H%M")

    echo "Last deploy ${LASTDEPLOYDATETIME}"

    STARTCOMMITHASH=$(cat deploy_history.json | jq ".deploys[0].endCommitHash")
    # Remove first and last quotes
    STARTCOMMITHASH=${STARTCOMMITHASH:1:-1}
    ENDCOMMITHASH=$(git rev-parse HEAD)

    # Check if there are new commits
    if [ ${STARTCOMMITHASH} == ${ENDCOMMITHASH} ]
    then
        echo "There are no changes. Not deployed."
        
        exit 0
    fi

    PROJECTNAME=$(cat deploy_history.json | jq ".projectName")
    # Remove first and last quotes
    PROJECTNAME=${PROJECTNAME:1:-1}

    # NEWITEM=[{"dateTime":${DATETIME},"startCommitHash":'"'${STARTCOMMITHASH}'"',"endCommitHash":'"'${ENDCOMMITHASH}'"'}]

    # JSON=$(cat deploy_history.json | jq ".")
    # echo $JSON | jq ".deploys |= ${NEWITEM} + ." > deploy_history.json

    # echo "deploy_history.json updated"
else
    FIRSTDEPLOY=1
    echo "Running first deploy"

    PROJECTNAME=$(basename `pwd`)

    # User input for project name
    read -e -p "Insert the project name: " -i ${PROJECTNAME} PROJECTNAME

    STARTCOMMITHASH=$(git rev-list --max-parents=0 HEAD)
    # ENDCOMMITHASH=$(git rev-parse HEAD)

    # JSON={"projectName":'"'${PROJECTNAME}'"',"deploys":[{"dateTime":${DATETIME},"startCommitHash":'"'${STARTCOMMITHASH}'"',"endCommitHash":'"'${ENDCOMMITHASH}'"'}]}

    # jq -n ${JSON} > deploy_history.json

    # echo "deploy_history.json created"
fi

# Create git arquive package
echo "Creating package"
FOLDERNAME="${PROJECTNAME}-${DATETIME}"
git archive --output=${FOLDERNAME} HEAD $(git diff --name-only --diff-filter=ACMRT ${STARTCOMMITHASH} HEAD)
echo "Package created"

# Check if zip file size > 0
if [ $(du -s -B1 ${FOLDERNAME} | cut -f1) == 0 ]
then
    echo "Package with 0 bytes"

    # Delete local package
    rm -rf ${FOLDERNAME}
    echo "Package removed from local"
    
    echo "Deploy failed"
    exit 0
fi

echo "Fim"
exit 0

# Deploy zip package to Google Drive
echo "Uploading file to Google Drive"
GDRIVEFOLDERID="19VquqHrFtBdqzlV3gDtgxFTppGRx6MhM"
gdrive upload -r -p ${GDRIVEFOLDERID} ${FOLDERNAME}
echo "File uploaded"

# Delete local package
rm -rf ${FOLDERNAME}
echo "File removed from local"

# Commit deploy_history.json changes to master
git add .
git commit -m "Deploy - ${ENDCOMMITHASH}"
git push origin master
echo "Pushed to GitHub"

echo "Deploy successful"