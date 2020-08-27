#!/usr/bin/env bash

# Create Secrets.plist file
if [ "$APPCENTER_BRANCH" == "master" ];
then
    defaults write $APPCENTER_SOURCE_DIRECTORY/Pock/Various/Secrets.plist AppCenter $APPCENTER_SECRET
fi
