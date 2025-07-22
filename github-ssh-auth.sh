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
CONFIG_FILE="$SSH_DIR/config"
KNOWN_HOSTS="$SSH_DIR/known_hosts"

echo
echo -e "${PURPLE}========================${NC}"
echo -e "${WHITE}GITHUB SSH SETUP SCRIPT${NC}"
echo -e "${PURPLE}========================${NC}"

echo
echo -e "${GREEN}SSH Directory Setup${NC}"
echo -e "${GREEN}===================${NC}"
echo

echo -e "${CYAN}${INFO}${NC} Preparing SSH directory structure"
echo -e "${GRAY}  ${ARROW}${NC} Creating directory ${BLUE}$SSH_DIR${NC}"
mkdir -p "$SSH_DIR" > /dev/null 2>&1
chmod 700 "$SSH_DIR"
echo -e "${GREEN}${CHECK}${NC} SSH directory prepared successfully!"

echo
echo -e "${GREEN}SSH Key File Preparation${NC}"
echo -e "${GREEN}=========================${NC}"
echo

if [ -f "$KEY_FILE" ]; then
    echo -e "${GREEN}${CHECK}${NC} GitHub SSH key already exists at ${BLUE}$KEY_FILE${NC}"
    echo -e "${CYAN}${INFO}${NC} Using existing key file"
    
    echo -e "${GRAY}  ${ARROW}${NC} Verifying private key format"
    if ! grep -q "BEGIN.*PRIVATE KEY" "$KEY_FILE"; then
      echo -e "${RED}${CROSS}${NC} File does not contain a valid private key (expected 'BEGIN ... PRIVATE KEY')."
      echo -e "${CYAN}${INFO}${NC} Consider generating a new key with:"
      echo -e "${WHITE}ssh-keygen -t ed25519 -C 'your_email@example.com' -f $KEY_FILE${NC}"
      exit 1
    fi
    echo -e "${GREEN}${CHECK}${NC} Private key validated successfully!"
    echo
    echo -e "${CYAN}${WARNING}${NC} SSH key already exists. Please select option:"
    echo
    echo -e "${BLUE}1.${NC} Keep existing key"
    echo -e "${GREEN}2.${NC} Generate new key"
    echo
    echo -ne "${CYAN}Enter your choice (1 or 2): ${NC}"
    read CHOICE
    
    case $CHOICE in
        2)
            echo -e "${YELLOW}${WARNING}${NC} Generating new key will overwrite the existing one"
            echo -ne "${CYAN}Are you sure? (y/N): ${NC}"
            read CONFIRM
            if [ "$CONFIRM" = "y" ] || [ "$CONFIRM" = "Y" ]; then
                echo -e "${CYAN}${INFO}${NC} Removing existing key"
                echo -e "${GRAY}  ${ARROW}${NC} Deleting old key files"
                rm -f "$KEY_FILE" "$KEY_FILE.pub"

                echo -e "${CYAN}${INFO}${NC} Generating new SSH key"
                echo -ne "${CYAN}  Enter your email for the SSH key: ${NC}"
                read USER_EMAIL
                
                if [ -z "$USER_EMAIL" ]; then
                    echo -e "${RED}${CROSS}${NC} Email is required for SSH key generation."
                    exit 1
                fi
                
                echo -e "${GRAY}  ${ARROW}${NC} Generating ed25519 key with email: ${BLUE}$USER_EMAIL${NC}"
                ssh-keygen -t ed25519 -C "$USER_EMAIL" -f "$KEY_FILE" -N "" > /dev/null 2>&1
                
                if [ $? -ne 0 ]; then
                    echo -e "${RED}${CROSS}${NC} Failed to generate SSH key."
                    exit 1
                fi
                
                chmod 600 "$KEY_FILE"
                chmod 644 "$KEY_FILE.pub"
                echo -e "${GREEN}${CHECK}${NC} SSH key generated successfully!"
                echo
                echo -e "${WHITE}==============================================="
                echo -e "IMPORTANT: Add this PUBLIC KEY to GitHub"
                echo -e "===============================================${NC}"
                echo
                echo -e "${CYAN}${INFO}${NC} Go to: ${WHITE}https://github.com/settings/ssh/new${NC}"
                echo -e "${CYAN}${INFO}${NC} Title: ${WHITE}$(hostname) - SSH Key${NC}"
                echo
                echo -e "${WHITE}PUBLIC KEY (copy everything below):${NC}"
                echo -e "${BLUE}─────────────────────────────────────────────${NC}"
                cat "$KEY_FILE.pub"
                echo -e "${BLUE}─────────────────────────────────────────────${NC}"
                echo
                echo -ne "${CYAN}After adding the public key to GitHub, press Enter to continue...${NC}"
                read
            else
                echo -e "${CYAN}${INFO}${NC} Keeping existing key"
            fi
            ;;
        1|*)
            echo -e "${CYAN}${INFO}${NC} Keeping existing key"
            ;;
    esac
    
else
    echo -e "${CYAN}${INFO}${NC} No existing SSH key found, generating new key"
    echo -ne "${CYAN}  Enter your email for the SSH key: ${NC}"
    read USER_EMAIL
    
    if [ -z "$USER_EMAIL" ]; then
        echo -e "${RED}${CROSS}${NC} Email is required for SSH key generation."
        exit 1
    fi
    
    echo -e "${GRAY}  ${ARROW}${NC} Generating ed25519 key with email: ${BLUE}$USER_EMAIL${NC}"
    ssh-keygen -t ed25519 -C "$USER_EMAIL" -f "$KEY_FILE" -N "" > /dev/null 2>&1
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}${CROSS}${NC} Failed to generate SSH key."
        exit 1
    fi
    
    chmod 600 "$KEY_FILE"
    chmod 644 "$KEY_FILE.pub"
    echo -e "${GREEN}${CHECK}${NC} SSH key generated successfully!"
    echo
    echo -e "${WHITE}=========================${NC}"
    echo -e "${WHITE}Add PUBLIC KEY to GitHub${NC}"
    echo -e "${WHITE}=========================${NC}"
    echo
    echo -e "${CYAN}${INFO}${NC} Go to: ${WHITE}https://github.com/settings/ssh/new${NC}"
    echo
    echo -e "${YELLOW}PUBLIC KEY:${NC}"
    cat "$KEY_FILE.pub"
    echo
    echo -ne "${CYAN}After adding the public key to GitHub, press Enter to continue...${NC}"
    read
fi

echo
echo -e "${GREEN}──────────────────────────────────────────${NC}"
echo -e "${GREEN}${CHECK}${NC} Key preparation completed successfully!"
echo -e "${GREEN}──────────────────────────────────────────${NC}"
echo

echo -e "${GREEN}SSH Agent Configuration${NC}"
echo -e "${GREEN}=======================${NC}"
echo

echo -e "${CYAN}${INFO}${NC} Configuring SSH agent"
echo -e "${GRAY}  ${ARROW}${NC} Starting SSH agent"
eval "$(ssh-agent -s)" > /dev/null 2>&1
echo -e "${GRAY}  ${ARROW}${NC} Adding key to SSH agent"
ssh-add -v "$KEY_FILE" > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo -e "${RED}${CROSS}${NC} Failed to add key to SSH agent. The key may be invalid or corrupted."
  echo -e "${CYAN}${INFO}${NC} Consider generating a new key with:"
  echo -e "${WHITE}ssh-keygen -t ed25519 -C 'your_email@example.com' -f $KEY_FILE${NC}"
  exit 1
fi
echo -e "${GREEN}${CHECK}${NC} SSH agent configured successfully!"

echo
echo -e "${GREEN}SSH Configuration${NC}"
echo -e "${GREEN}=================${NC}"
echo

echo -e "${CYAN}${INFO}${NC} Creating SSH configuration"
echo -e "${GRAY}  ${ARROW}${NC} Writing to ${BLUE}$CONFIG_FILE${NC}"
cat <<EOF > "$CONFIG_FILE"
Host github.com
  HostName github.com
  User git
  IdentityFile $KEY_FILE
EOF
chmod 600 "$CONFIG_FILE"
echo -e "${GRAY}  ${ARROW}${NC} Adding GitHub host key to ${BLUE}$KNOWN_HOSTS${NC}"
ssh-keyscan -H github.com >> "$KNOWN_HOSTS" 2>/dev/null
chmod 600 "$KNOWN_HOSTS"
echo -e "${GREEN}${CHECK}${NC} SSH configuration created!"

echo
echo -e "${GREEN}Connection Test${NC}"
echo -e "${GREEN}===============${NC}"
echo

echo -e "${CYAN}${INFO}${NC} Testing connection to GitHub"
echo -e "${GRAY}  ${ARROW}${NC} Attempting SSH connection"
ssh -T git@github.com > /dev/null 2>&1
if [ $? -eq 1 ]; then
  echo -e "${GREEN}${CHECK}${NC} Connection to GitHub established!"
  echo
  echo -e "${GREEN}===========================================${NC}"
  echo -e "${GREEN}${CHECK}${NC} GitHub SSH setup completed successfully!"
  echo -e "${GREEN}===========================================${NC}"
  echo
  echo -e "${CYAN}Useful Commands:${NC}"
  echo -e "${WHITE}• Test connection: ssh -T git@github.com${NC}"
  echo -e "${WHITE}• View public key: cat ~/.ssh/github.pub${NC}"
  echo
else
  echo
  echo -e "${RED}${CROSS}${NC} Failed to connect to GitHub."
  echo -e "${CYAN}${INFO}${NC} Ensure the public key is added at:"
  echo -e "${WHITE}https://github.com/settings/keys${NC}"
  echo
  exit 1
fi
