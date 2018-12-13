#! /bin/bash

if [ -f "deploy_history.json" ]
then
    JSON=$(cat deploy_history.json | jq ".")

    STARTCOMMITHASH=$(echo ${JSON} | jq ".deploys[0].endCommitHash")
    ENDCOMMITHASH=$(echo $(git rev-parse HEAD))

    # Check if there are new commits
    if [ ${STARTCOMMITHASH} == '"'${ENDCOMMITHASH}'"' ]
    then
        echo 'There are no changes. Not deployed.'
        
        exit 0
    fi

    DATETIME=$(date +"%Y%m%d%H%M")

    NEWITEM=[{"dateTime":${DATETIME},"startCommitHash":${STARTCOMMITHASH},"endCommitHash":'"'${ENDCOMMITHASH}'"'}]

    echo $JSON | jq ".deploys |= ${NEWITEM} + ." > deploy_history.json
else
    PROJECTNAME=$(basename `pwd`)

    read -p "Project name: " -i ${PROJECTNAME} PROJECTNAME

    STARTCOMMITHASH=$(git rev-list --max-parents=0 HEAD)
    ENDCOMMITHASH=$(git rev-parse HEAD)
    DATETIME=$(date +"%Y%m%d%H%M")

    JSON={"projectName":'"'${PROJECTNAME}'"',"deploys":[{"dateTime":${DATETIME},"startCommitHash":'"'${STARTCOMMITHASH}'"',"endCommitHash":'"'${ENDCOMMITHASH}'"'}]}

    jq -n ${JSON} > deploy_history.json
fi