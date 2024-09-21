#!/bin/bash

# Lets make sure only the user has any r/w permissions
umask 077

# cred-helper 2.1 - Less API calls t 1PASSWORD and used jq to massage data, caching based off token expiration and increased speed.
#
# Usage in credential file
# cred-helper.sh <vault> <secret id in vault>
#
# Example:
#
# [default]
# credential_process = /Users/dennis/.aws/cred-helper.sh "Personal" "AWS Access Key"

vault="$1"
secret_id="$2"

timenow=$(date +"%Y-%m-%dT%H:%M:%S%z")

# For multiple profiles, we want unique cache files.
cache_file=$(echo .cache-${secret_id// /_})

getcreds() {
# Let's get our key and mfa serial from the Vault

  ONE_PASSWORD=`op item get --vault $vault "$secret_id"  --format json | jq '.fields | map({(.label):.}) | add  \
     | {Version:1, AccessKeyId:."access key id".value, SecretAccessKey:."secret access key".value, SerialNumber:."mfa id".value, OtpToken:."one-time password".totp}'`

# Exporting key and secret in order to get a SESSION Token via AWS-CLI

  export AWS_ACCESS_KEY_ID=$(echo $ONE_PASSWORD | jq -r .AccessKeyId)
  export AWS_SECRET_ACCESS_KEY=$(echo $ONE_PASSWORD | jq -r .SecretAccessKey)

# We'll need these, but not required to be exported.

  SERIAL_NUMBER=$(echo $ONE_PASSWORD | jq -r .SerialNumber)
  TOKEN_PIN=$(echo $ONE_PASSWORD | jq -r .OtpToken)

  AWS_CREDS=`aws sts get-session-token --serial-number $SERIAL_NUMBER --token-code $TOKEN_PIN | \
      jq '. | add | {Version:1, AccessKeyId:.AccessKeyId,SecretAccessKey:.SecretAccessKey,SessionToken:.SessionToken,Expiration:.Expiration}'`

# Return the Authentication credits for AWS
  echo $AWS_CREDS > $HOME/.aws/$cache_file
  echo $AWS_CREDS
}

# Check to see if we have a cred cache

if [ -n "$GEODESIC_SHELL" ]; then
      HOME="/localhost"
fi
  
if [ -f $HOME/.aws/$cache_file ]
then
   #If we do have a cache, check token expiration
   timecache=$(jq -r .Expiration $HOME/.aws/$cache_file)
  
   if [[ $timenow > $timecache ]]
   then
     # Token expired
     getcreds
   else
    # Use the cache
     echo "$(<$HOME/.aws/$cache_file)"
   fi
else
  # No cached creds, lets fetch them.
  getcreds
fi
