#! /bin/bash

# Check if current branch is master
if [ $(git name-rev --name-only HEAD) != "master" ]
then
    echo "You are not in master branch"

    exit 0
fi

if [ -f "deploy_history.json" ]
then
    LASTDEPLOYDATETIME=$(cat deploy_history.json | jq ".deploys[0].dateTime")
    # TODO: Manipular a data para Y-m-d H:M
    # LASTDEPLOYDATETIME=$(date -d ${JSON} +"%Y%m%d%H%M")

    echo "Last deploy ${LASTDEPLOYDATETIME}"

    PROJECTNAME=$(cat deploy_history.json | jq ".projectName")
    # Remove first and last quotes
    PROJECTNAME=${PROJECTNAME:1:-1}

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

    DATETIME=$(date +"%Y%m%d%H%M")

    NEWITEM=[{"dateTime":${DATETIME},"startCommitHash":'"'${STARTCOMMITHASH}'"',"endCommitHash":'"'${ENDCOMMITHASH}'"'}]

    echo $JSON | jq ".deploys |= ${NEWITEM} + ." > deploy_history.json
else
    echo "Running first deploy"

    PROJECTNAME=$(basename `pwd`)

    # User input for project name
    read -e -p "Project name: " -i ${PROJECTNAME} PROJECTNAME

    STARTCOMMITHASH=$(git rev-list --max-parents=0 HEAD)
    ENDCOMMITHASH=$(git rev-parse HEAD)
    DATETIME=$(date +"%Y%m%d%H%M")

    JSON={"projectName":'"'${PROJECTNAME}'"',"deploys":[{"dateTime":${DATETIME},"startCommitHash":'"'${STARTCOMMITHASH}'"',"endCommitHash":'"'${ENDCOMMITHASH}'"'}]}

    jq -n ${JSON} > deploy_history.json
fi

# Commit deploy_history.json changes to master
git add .
git commit -m "Deploy - ${ENDCOMMITHASH}"

# Create zip package
ZIPFILENAME="${PROJECTNAME}-${DATETIME}.zip"
git archive --output=${ZIPFILENAME} HEAD $(git diff --name-only --diff-filter=ACMRT ${STARTCOMMITHASH} HEAD)

# Deploy zip package to Google Drive
GDRIVEFOLDERID="19VquqHrFtBdqzlV3gDtgxFTppGRx6MhM"
gdrive upload -r -p ${GDRIVEFOLDERID} ${ZIPFILENAME}

echo "Deployed"