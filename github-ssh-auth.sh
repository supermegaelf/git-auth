#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
NC='\033[0m'

# Status symbols
CHECK="✓"
CROSS="✗"
WARNING="!"
INFO="*"
ARROW="→"

SSH_DIR="/root/.ssh"
KEY_FILE="$SSH_DIR/github"
PUB_KEY_FILE="$KEY_FILE.pub"
CONFIG_FILE="$SSH_DIR/config"
KNOWN_HOSTS="$SSH_DIR/known_hosts"

echo -e "${PURPLE}========================${NC}"
echo -e "GITHUB SSH SETUP SCRIPT"
echo -e "${PURPLE}========================${NC}"
echo

User Information Required
=========================

echo -e "${CYAN}${INFO}${NC} Please provide your GitHub credentials"
echo -ne "${CYAN}Enter your GitHub username: ${NC}"
read GITHUB_USERNAME
echo -ne "${CYAN}Enter your email for GitHub: ${NC}"
read GITHUB_EMAIL

if [ -z "$GITHUB_USERNAME" ] || [ -z "$GITHUB_EMAIL" ]; then
    echo -e "${RED}${CROSS}${NC} Username and email are required."
    exit 1
fi

SSH Directory Setup
===================

echo -e "${CYAN}${INFO}${NC} Preparing SSH directory structure"
echo -e "${GRAY}  ${ARROW}${NC} Creating directory ${BLUE}$SSH_DIR${NC}"
mkdir -p "$SSH_DIR" > /dev/null 2>&1
chmod 700 "$SSH_DIR"
echo -e "${GREEN}${CHECK}${NC} SSH directory prepared successfully!"

SSH Key Generation
==================

if [ -f "$KEY_FILE" ] || [ -f "$PUB_KEY_FILE" ]; then
    echo -e "${YELLOW}${WARNING}${NC} GitHub SSH keys already exist."
    echo -ne "${CYAN}Do you want to overwrite them? (y/N): ${NC}"
    read OVERWRITE
    if [ "$OVERWRITE" != "y" ] && [ "$OVERWRITE" != "Y" ]; then
        echo -e "${GRAY}  ${ARROW}${NC} Keeping existing keys"
    else
        echo -e "${CYAN}${INFO}${NC} Removing existing keys"
        echo -e "${GRAY}  ${ARROW}${NC} Deleting ${BLUE}$KEY_FILE${NC}"
        echo -e "${GRAY}  ${ARROW}${NC} Deleting ${BLUE}$PUB_KEY_FILE${NC}"
        rm -f "$KEY_FILE" "$PUB_KEY_FILE"
        echo -e "${GREEN}${CHECK}${NC} Old keys removed!"
    fi
fi

if [ ! -f "$KEY_FILE" ]; then
    echo -e "${CYAN}${INFO}${NC} Generating new SSH key for GitHub"
    echo -e "${GRAY}  ${ARROW}${NC} Creating ed25519 key with email: ${BLUE}$GITHUB_EMAIL${NC}"
    ssh-keygen -t ed25519 -C "$GITHUB_EMAIL - GitHub SSH key" -f "$KEY_FILE" -N "" > /dev/null 2>&1
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}${CROSS}${NC} Failed to generate SSH key."
        exit 1
    fi
    
    chmod 600 "$KEY_FILE"
    chmod 644 "$PUB_KEY_FILE"
    echo -e "${GREEN}${CHECK}${NC} SSH key generated successfully!"
fi

echo
echo -e "${GREEN}─────────────────────────────────────────${NC}"
echo -e "${GREEN}${CHECK}${NC} Key generation completed successfully!"
echo -e "${GREEN}─────────────────────────────────────────${NC}"
echo

SSH Agent Configuration
=======================

echo -e "${CYAN}${INFO}${NC} Configuring SSH agent"
echo -e "${GRAY}  ${ARROW}${NC} Starting SSH agent"
eval "$(ssh-agent -s)" > /dev/null 2>&1
echo -e "${GRAY}  ${ARROW}${NC} Adding key to SSH agent"
ssh-add -v "$KEY_FILE" > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo -e "${RED}${CROSS}${NC} Failed to add key to SSH agent."
    exit 1
fi
echo -e "${GREEN}${CHECK}${NC} SSH agent configured successfully!"

SSH Configuration
=================

echo -e "${CYAN}${INFO}${NC} Creating SSH configuration"
echo -e "${GRAY}  ${ARROW}${NC} Writing to ${BLUE}$CONFIG_FILE${NC}"
cat <<EOF > "$CONFIG_FILE"
Host github.com
  HostName github.com
  User git
  IdentityFile $KEY_FILE
  IdentitiesOnly yes
EOF
chmod 600 "$CONFIG_FILE"
echo -e "${GRAY}  ${ARROW}${NC} Adding GitHub host key to ${BLUE}$KNOWN_HOSTS${NC}"
ssh-keyscan -H github.com >> "$KNOWN_HOSTS" 2>/dev/null
chmod 600 "$KNOWN_HOSTS"
echo -e "${GREEN}${CHECK}${NC} SSH configuration created!"

Git Configuration
=================

echo -e "${CYAN}${INFO}${NC} Configuring Git with your credentials"
echo -e "${GRAY}  ${ARROW}${NC} Setting username: ${BLUE}$GITHUB_USERNAME${NC}"
git config --global user.name "$GITHUB_USERNAME"
echo -e "${GRAY}  ${ARROW}${NC} Setting email: ${BLUE}$GITHUB_EMAIL${NC}"
git config --global user.email "$GITHUB_EMAIL"
echo -e "${GREEN}${CHECK}${NC} Git configuration completed!"

echo
echo -e "${GREEN}───────────────────────────────────────────────${NC}"
echo -e "${GREEN}${CHECK}${NC} System configuration completed successfully!"
echo -e "${GREEN}───────────────────────────────────────────────${NC}"
echo

echo -e "${WHITE}==============================================="
echo -e "IMPORTANT: Add this PUBLIC KEY to GitHub"
echo -e "===============================================${NC}"
echo
echo -e "${CYAN}${INFO}${NC} Go to: ${WHITE}https://github.com/settings/ssh/new${NC}"
echo -e "${CYAN}${INFO}${NC} Title: ${WHITE}$(hostname) - SSH Key${NC}"
echo
echo -e "${WHITE}PUBLIC KEY (copy everything below):${NC}"
echo -e "${BLUE}────────────────────────────────────────────────────────────────────────────────────────${NC}"
cat "$PUB_KEY_FILE"
echo -e "${BLUE}────────────────────────────────────────────────────────────────────────────────────────${NC}"
echo

echo -ne "${CYAN}After adding the public key to GitHub, press Enter to test the connection...${NC}"
read

Connection Test
===============

echo -e "${CYAN}${INFO}${NC} Testing connection to GitHub"
echo -e "${GRAY}  ${ARROW}${NC} Attempting SSH connection"
ssh -T git@github.com
CONNECTION_STATUS=$?

if [ $CONNECTION_STATUS -eq 1 ]; then
    echo
    echo -e "${PURPLE}=====================${NC}"
    echo -e "${GREEN}${CHECK} SETUP COMPLETED!"
    echo -e "${PURPLE}=====================${NC}"
    echo
    echo -e "${GREEN}${CHECK}${NC} GitHub SSH setup completed!"
    echo -e "${GREEN}${CHECK}${NC} Git is configured with username: ${WHITE}$GITHUB_USERNAME${NC}"
    echo -e "${GREEN}${CHECK}${NC} Git is configured with email: ${WHITE}$GITHUB_EMAIL${NC}"
    echo
    echo -e "${CYAN}${INFO}${NC} You can now use git commands with SSH authentication"
elif [ $CONNECTION_STATUS -eq 255 ]; then
    echo
    echo -e "${RED}${CROSS}${NC} Connection failed. Please check:"
    echo -e "${WHITE}• ${NC}Public key is correctly added to GitHub"
    echo -e "${WHITE}• ${NC}Internet connection is working"  
    echo -e "${WHITE}• ${NC}SSH key is valid"
else
    echo
    echo -e "${YELLOW}${WARNING}${NC} Unexpected response from GitHub"
    echo -e "${CYAN}${INFO}${NC} Please verify your setup manually with: ${WHITE}ssh -T git@github.com${NC}"
fi

echo
echo -e "${CYAN}${INFO}${NC} Your public key is saved in: ${BLUE}$PUB_KEY_FILE${NC}"
echo -e "${CYAN}${INFO}${NC} Your private key is saved in: ${BLUE}$KEY_FILE${NC}"
echo
echo -e "${GREEN}${CHECK}${NC} GitHub SSH setup script completed!"
echo
