#!/bin/bash

#====================
# GITHUB SSH MANAGER
#====================

# Color constants
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly GRAY='\033[0;90m'
readonly NC='\033[0m'

# Status symbols
readonly CHECK="✓"
readonly CROSS="✗"
readonly WARNING="!"
readonly INFO="*"
readonly ARROW="→"

# Configuration
SSH_DIR="/root/.ssh"
KEY_FILE="$SSH_DIR/github"
CONFIG_FILE="$SSH_DIR/config"
KNOWN_HOSTS="$SSH_DIR/known_hosts"

#======================
# VALIDATION FUNCTIONS
#======================

validate_private_key() {
    if ! grep -q "BEGIN.*PRIVATE KEY" "$KEY_FILE"; then
        echo -e "${RED}${CROSS}${NC} File does not contain a valid private key (expected 'BEGIN ... PRIVATE KEY')."
        echo
        echo -e "${CYAN}${INFO}${NC} Consider generating a new key with:"
        echo -e "${WHITE}ssh-keygen -t ed25519 -C 'your_email@example.com' -f $KEY_FILE${NC}"
        exit 1
    fi
}

#================
# MAIN FUNCTIONS
#================

setup_ssh_directory() {
    echo
    echo -e "${GREEN}SSH Directory Setup${NC}"
    echo -e "${GREEN}===================${NC}"
    echo

    echo -e "${CYAN}${INFO}${NC} Preparing SSH directory structure"
    echo -e "${GRAY}  ${ARROW}${NC} Creating directory ${BLUE}$SSH_DIR${NC}"
    echo -e "${GRAY}  ${ARROW}${NC} Setting directory permissions (700)"
    mkdir -p "$SSH_DIR" > /dev/null 2>&1
    chmod 700 "$SSH_DIR"
    echo -e "${GREEN}${CHECK}${NC} SSH directory prepared successfully!"
}

handle_existing_key() {
    echo -e "${GREEN}${CHECK}${NC} GitHub SSH key already exists at ${BLUE}$KEY_FILE${NC}"
    echo

    echo -e "${CYAN}${INFO}${NC} Validating existing key file"
    echo -e "${GRAY}  ${ARROW}${NC} Verifying private key format"
    echo -e "${GRAY}  ${ARROW}${NC} Checking file permissions"
    validate_private_key
    echo -e "${GREEN}${CHECK}${NC} Private key validated successfully!"
    echo

    echo -e "${YELLOW}${WARNING} ${CYAN}SSH key already exists. Please select option:${NC}"
    echo
    echo -e "${BLUE}1.${NC} Keep existing key"
    echo -e "${GREEN}2.${NC} Generate new key"
    echo
    echo -ne "${CYAN}Enter your choice (1 or 2): ${NC}"
    read CHOICE
    
    case $CHOICE in
        2)
            echo
            echo -ne "${YELLOW}Are you sure? (y/N): ${NC}"
            read CONFIRM
            if [ "$CONFIRM" = "y" ] || [ "$CONFIRM" = "Y" ]; then
                remove_existing_key
                generate_new_key
            else
                echo
                echo -e "${CYAN}${INFO}${NC} Keeping existing key"
                echo -e "${GREEN}${CHECK}${NC} Existing key will be used!"
            fi
            ;;
        1|*)
            echo
            echo -e "${CYAN}${INFO}${NC} Keeping existing key"
            echo -e "${GREEN}${CHECK}${NC} Existing key will be used!"
            ;;
    esac
}

remove_existing_key() {
    echo
    echo -e "${CYAN}${INFO}${NC} Removing existing key files"
    echo -e "${GRAY}  ${ARROW}${NC} Deleting private key file"
    echo -e "${GRAY}  ${ARROW}${NC} Deleting public key file"
    rm -f "$KEY_FILE" "$KEY_FILE.pub"
    echo -e "${GREEN}${CHECK}${NC} Old key files deleted successfully!"
}

generate_new_key() {
    echo
    echo -e "${CYAN}${INFO}${NC} Generating new SSH key"
    echo
    echo -ne "${CYAN}Enter your email for the SSH key: ${NC}"
    read USER_EMAIL
    
    if [ -z "$USER_EMAIL" ]; then
        echo -e "${RED}${CROSS}${NC} Email is required for SSH key generation."
        exit 1
    fi
    
    echo
    echo -e "${CYAN}${INFO}${NC} Creating SSH key with email: ${BLUE}$USER_EMAIL${NC}"
    echo -e "${GRAY}  ${ARROW}${NC} Generating ed25519 key pair"
    echo -e "${GRAY}  ${ARROW}${NC} Setting file permissions"
    echo -e "${GRAY}  ${ARROW}${NC} Creating key files"
    ssh-keygen -t ed25519 -C "$USER_EMAIL" -f "$KEY_FILE" -N "" > /dev/null 2>&1
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}${CROSS}${NC} Failed to generate SSH key."
        exit 1
    fi
    
    chmod 600 "$KEY_FILE"
    chmod 644 "$KEY_FILE.pub"
    echo -e "${GREEN}${CHECK}${NC} SSH key generated successfully!"
    
    display_public_key
}

create_new_key() {
    echo -e "${CYAN}${INFO}${NC} No existing SSH key found, generating new key"
    echo
    echo -ne "${CYAN}Enter your email for the SSH key: ${NC}"
    read USER_EMAIL
    
    if [ -z "$USER_EMAIL" ]; then
        echo -e "${RED}${CROSS}${NC} Email is required for SSH key generation."
        exit 1
    fi
    
    echo
    echo -e "${CYAN}${INFO}${NC} Creating SSH key with email: ${BLUE}$USER_EMAIL${NC}"
    echo -e "${GRAY}  ${ARROW}${NC} Generating ed25519 key pair"
    echo -e "${GRAY}  ${ARROW}${NC} Setting file permissions"
    echo -e "${GRAY}  ${ARROW}${NC} Creating key files"
    ssh-keygen -t ed25519 -C "$USER_EMAIL" -f "$KEY_FILE" -N "" > /dev/null 2>&1
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}${CROSS}${NC} Failed to generate SSH key."
        exit 1
    fi
    
    chmod 600 "$KEY_FILE"
    chmod 644 "$KEY_FILE.pub"
    echo -e "${GREEN}${CHECK}${NC} SSH key generated successfully!"
    
    display_public_key
}

display_public_key() {
    echo
    echo -e "${YELLOW}1. Follow link:${NC} https://github.com/settings/ssh/new"
    echo -e "${YELLOW}2. Copy PUBLIC KEY below and insert it:${NC}"
    cat "$KEY_FILE.pub"
    echo
    echo -ne "${YELLOW}3. Press Enter to continue...${NC}"
    read
}

setup_ssh_key() {
    echo
    echo -e "${GREEN}SSH Key File Preparation${NC}"
    echo -e "${GREEN}========================${NC}"
    echo

    if [ -f "$KEY_FILE" ]; then
        handle_existing_key
    else
        create_new_key
    fi
}

configure_ssh_agent() {
    echo
    echo -e "${GREEN}SSH Agent Configuration${NC}"
    echo -e "${GREEN}=======================${NC}"
    echo

    echo -e "${CYAN}${INFO}${NC} Configuring SSH agent"
    echo -e "${GRAY}  ${ARROW}${NC} Starting SSH agent service"
    echo -e "${GRAY}  ${ARROW}${NC} Adding private key to agent"
    echo -e "${GRAY}  ${ARROW}${NC} Verifying key registration"
    eval "$(ssh-agent -s)" > /dev/null 2>&1
    ssh-add -v "$KEY_FILE" > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo -e "${RED}${CROSS}${NC} Failed to add key to SSH agent. The key may be invalid or corrupted."
        echo
        echo -e "${CYAN}${INFO}${NC} Consider generating a new key with:"
        echo -e "${WHITE}ssh-keygen -t ed25519 -C 'your_email@example.com' -f $KEY_FILE${NC}"
        exit 1
    fi
    echo -e "${GREEN}${CHECK}${NC} SSH agent configured successfully!"
}

create_ssh_config() {
    echo
    echo -e "${GREEN}SSH Configuration${NC}"
    echo -e "${GREEN}=================${NC}"
    echo

    echo -e "${CYAN}${INFO}${NC} Creating SSH configuration files"
    echo -e "${GRAY}  ${ARROW}${NC} Writing to ${BLUE}$CONFIG_FILE${NC}"
    echo -e "${GRAY}  ${ARROW}${NC} Adding GitHub host configuration"
    echo -e "${GRAY}  ${ARROW}${NC} Setting configuration permissions"
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
    echo -e "${GREEN}${CHECK}${NC} SSH configuration created successfully!"
}

test_github_connection() {
    echo
    echo -e "${GREEN}Connection Test${NC}"
    echo -e "${GREEN}===============${NC}"
    echo

    echo -e "${CYAN}${INFO}${NC} Testing connection to GitHub"
    echo -e "${GRAY}  ${ARROW}${NC} Attempting SSH connection"
    echo -e "${GRAY}  ${ARROW}${NC} Verifying authentication"
    echo -e "${GRAY}  ${ARROW}${NC} Checking host key verification"
    ssh -T git@github.com > /dev/null 2>&1
    if [ $? -eq 1 ]; then
        echo -e "${GREEN}${CHECK}${NC} Connection to GitHub established successfully!"
        show_completion_message
    else
        echo -e "${RED}${CROSS}${NC} Failed to connect to GitHub"
        echo
        echo -e "${YELLOW}${WARNING} Ensure the public key is added at:${NC} ${WHITE}https://github.com/settings/keys${NC}"
        echo
        exit 1
    fi
}

show_completion_message() {
    echo
    echo -e "${PURPLE}=========================${NC}"
    echo -e "${GREEN}${CHECK}${NC} Installation complete!"
    echo -e "${PURPLE}=========================${NC}"
    echo
    echo -e "${CYAN}Useful Commands:${NC}"
    echo -e "${WHITE}• Test connection: ssh -T git@github.com${NC}"
    echo -e "${WHITE}• View public key: cat ~/.ssh/github.pub${NC}"
}

#==================
# MAIN ENTRY POINT
#==================

main() {
    echo
    echo -e "${PURPLE}===================${NC}"
    echo -e "${WHITE}GITHUB SSH MANAGER${NC}"
    echo -e "${PURPLE}===================${NC}"

    setup_ssh_directory
    setup_ssh_key
    configure_ssh_agent
    create_ssh_config
    test_github_connection
    echo
}

# Execute main function
main
