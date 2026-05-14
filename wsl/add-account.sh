#!/bin/bash

# Usage: ./add-github-account.sh personal personal@email.com ~/personal
# Usage: ./add-github-account.sh work work@company.com ~/work

ACCOUNT=$1
EMAIL=$2
WORKDIR=$3

if [ -z "$ACCOUNT" ] || [ -z "$EMAIL" ] || [ -z "$WORKDIR" ]; then
    echo "Usage: $0 <account-name> <email> <work-directory>"
    exit 1
fi

# Create working directory
mkdir -p "$WORKDIR"
chmod 755 "$WORKDIR"

# Generate SSH key
echo "Generating SSH key for $EMAIL..."
ssh-keygen -t ed25519 -C "$EMAIL" -f ~/.ssh/id_$ACCOUNT

# Lock down SSH directory and keys
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_$ACCOUNT
chmod 644 ~/.ssh/id_$ACCOUNT.pub
chown $USER:$USER ~/.ssh/id_$ACCOUNT
chown $USER:$USER ~/.ssh/id_$ACCOUNT.pub

# Add to ssh-agent
eval $(ssh-agent -s)
ssh-add ~/.ssh/id_$ACCOUNT

# Add to ~/.ssh/config
echo "
Host github-$ACCOUNT
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_$ACCOUNT" >> ~/.ssh/config

# Lock down ssh config
chmod 600 ~/.ssh/config
chown $USER:$USER ~/.ssh/config

# Create gitconfig for this account
cat > ~/.gitconfig-$ACCOUNT <<EOF
[user]
    email = $EMAIL
EOF

# Lock down gitconfig
chmod 600 ~/.gitconfig-$ACCOUNT
chown $USER:$USER ~/.gitconfig-$ACCOUNT

# Add includeIf to main ~/.gitconfig if not already there
if ! grep -q "gitdir:$WORKDIR" ~/.gitconfig; then
    cat >> ~/.gitconfig <<EOF

[includeIf "gitdir:$WORKDIR/"]
    path = ~/.gitconfig-$ACCOUNT
EOF
fi

# Lock down main gitconfig
chmod 600 ~/.gitconfig
chown $USER:$USER ~/.gitconfig

echo ""
echo "Done! Add this public key to GitHub ($ACCOUNT):"
echo ""
cat ~/.ssh/id_$ACCOUNT.pub
echo ""
echo "Then test with: ssh -T git@github-$ACCOUNT"
