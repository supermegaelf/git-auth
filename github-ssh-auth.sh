#!/bin/bash

SSH_DIR="/root/.ssh"
KEY_FILE="$SSH_DIR/github"
CONFIG_FILE="$SSH_DIR/config"
KNOWN_HOSTS="$SSH_DIR/known_hosts"

echo "Creating directory $SSH_DIR..."
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

echo "Creating file for GitHub private key ($KEY_FILE)..."
touch "$KEY_FILE"
chmod 600 "$KEY_FILE"

echo "Opening $KEY_FILE in nano. Paste your GitHub private SSH key, save (Ctrl+O, Enter), and exit (Ctrl+X)..."
nano "$KEY_FILE"

if [ ! -s "$KEY_FILE" ]; then
  echo "Error: Key file is empty. Please paste the key and save the file."
  exit 1
fi

if ! grep -q "BEGIN.*PRIVATE KEY" "$KEY_FILE"; then
  echo "Error: File does not contain a valid private key (expected 'BEGIN ... PRIVATE KEY')."
  exit 1
fi

echo "Starting SSH agent..."
eval "$(ssh-agent -s)"
echo "Adding key to SSH agent..."
ssh-add -v "$KEY_FILE"
if [ $? -ne 0 ]; then
  echo "Error: Failed to add key to SSH agent. The key may be invalid or corrupted."
  echo "Consider generating a new key with: ssh-keygen -t ed25519 -C 'your_email@example.com' -f $KEY_FILE"
  exit 1
fi

echo "Creating SSH configuration ($CONFIG_FILE)..."
cat <<EOF > "$CONFIG_FILE"
Host github.com
  HostName github.com
  User git
  IdentityFile $KEY_FILE
EOF
chmod 600 "$CONFIG_FILE"
echo "SSH configuration created."

echo "Adding GitHub host key to $KNOWN_HOSTS..."
ssh-keyscan -H github.com >> "$KNOWN_HOSTS"
chmod 600 "$KNOWN_HOSTS"

echo "Testing connection to GitHub..."
ssh -T git@github.com
if [ $? -eq 1 ]; then
  echo "Success: Connection to GitHub established!"
else
  echo "Error: Failed to connect to GitHub. Ensure the public key is added at https://github.com/settings/keys."
  exit 1
fi

echo "GitHub SSH setup completed!"
