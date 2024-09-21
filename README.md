# aws-1password
AWS and 1 password integration; allows use of 1password and AWS sdk/cli. Allows
use of MFA seemlessly without having the headache of typing code from your OTP 
application.


# Create a onepassword entry for the credentials It contains the following fields
* access key id
* secret access key
* default region
* mfa id (if applicable)
* one-time-password (if applicable)

# Update the config file
Set the default region, etc. Your profiles, etc.

# Added Yubico support.
Edit the sh script for use with Yubico devices. The device will blink, touch it.

# Update credentials file to point to your vault and password entry.
 Example
   * credential_process = /Users/USER/.aws/cred-helper.sh "Personal" "AWS Access Key"
