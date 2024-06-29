#!/bin/bash

# Enable debug mode if DEBUG variable is set
[[ -n $DEBUG ]] && set -x


# Check if a PHP version parameter is provided
if [ $# -ne 1 ]; then
  echo "Usage: $0 <php_version>"
  echo "Example: $0 7.2"
  exit 1
fi

# Set PRINT_EVERYTHING based on the second argument
[[ $# -eq 2 && "$2" == "--print-everything" ]] && print_everything=true || print_everything=false

red='\033[0;31m'
green='\033[0;32m'
reset='\033[0m'

php_version="$1"
php_version_formatted="${php_version:0:1}${php_version:2:1}"

# Function to display a spinner animation
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while ps -p $pid > /dev/null; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Remove PHP version for clean installation
remove_php() {
  echo -e "${green}Checking if PHP is installed using paru...${reset}"
  
  # Check if PHP is installed and remove it if necessary
  if ! command -v php"$php_version_formatted" &>/dev/null; then
    echo -e "${green}PHP not installed, no need to remove it.${reset}"
  else 
    echo -e "${green}Removing previously installed PHP...${reset}"
    paru -Rns php"$php_version_formatted" --noconfirm
  fi
  
  echo -e "${green}PHP removed successfully.${reset}"
}

remove_dependencies() {
  echo -e "${green}Checking if still have PHP dependencies installed using paru...${reset}"
 
  # Clean up unused dependencies
  echo -e "${green}Cleaning up unused PHP dependencies starting with php$php_version_formatted-...${reset}"
  paru -Qsq "^php$php_version_formatted-" | paru -Rns -
  
  echo -e "${green}PHP dependencies removed successfully.${reset}"
}

# Function to check and install PHP versions using paru
install_php() {
  # Check if PHP version is installed
  if ! command -v php"$php_version_formatted" &>/dev/null; then
    echo -e "${red}PHP $php_version_formatted is not installed.${reset}"
    echo -e "${green}Installing PHP $php_version_formatted using paru ...${reset}"

    # Attempt to install PHP version using paru
    if paru -S php"$php_version_formatted" --noconfirm  2>&1; then
      echo -e "${green}PHP $php_version_formatted installed successfully.${reset}"
    else
      echo -e "${red}Failed to install PHP $php_version_formatted.${reset}"
      echo "Error: Failed to install PHP $php_version_formatted using paru." >&2
      exit 1
    fi
  fi
}


install_php_pgsql() {
  # Check if php-pgsql extension is installed
  if ! php -m | grep -q '^pgsql$'; then
    echo -e "${red}php-pgsql extension is not installed.${reset}"
    sleep 1
    echo -e "${green}Installing php-pgsql using paru ...${reset}"

    # Attempt to install php-pgsql using paru
    if paru -S php"$php_version_formatted"-pgsql --noconfirm 2>&1; then
      echo -e "${green}php-pgsql installed successfully.${reset}"
    else
      echo -e "${red}Failed to install php-pgsql.${reset}"
      sleep 1
      echo "Error: Failed to install php-pgsql using paru." >&2
      exit 1
    fi
  fi
}

# Function to activate PHP version
activate_php() {
  local php_version="$1"

  # Adjust PHP version format if necessary (e.g., 72 instead of 7.2)
  local php_version_formatted="${php_version:0:1}${php_version:2:1}"

  echo -e "${green}Activating php $php_version_formatted at location /usr/bin/php$php_version_formatted ...${reset}"
  rm -f "$HOME/bin/php" "$HOME/bin/phpize"
  ln -sf "/usr/bin/php$php_version_formatted" "$HOME/bin/php"
  ln -sf "/usr/bin/phpize$php_version_formatted" "$HOME/bin/phpize"
  alias php="/usr/bin/php$php_version_formatted"

  # Export PHP version to current shell session
  export PATH="/usr/bin:$HOME/bin:$PATH"  # Ensure /usr/bin is included

  # Check if the symbolic links were created successfully
  if [ $? -eq 0 ]; then
    echo "PHP $php_version_formatted activated successfully."
    /usr/bin/php -v  # Use the absolute path to php executable
  else
    echo -e "${red}Error creating symbolic links.${reset}"
  fi
}




#spinner $$ &
#spinner $spinner_pid1 &
remove_php "$1"
#kill $spinner_pid1 > /dev/null 2>&1

#spinner $$ &
#spinner $spinner_pid1 &
remove_dependencies "$1"
#kill $spinner_pid1 > /dev/null 2>&1

#spinner $$ &
#spinner $spinner_pid1 &
install_php "$1"
#kill $spinner_pid1 > /dev/null 2>&1

#spinner $$ &
#spinner $spinner_pid1 &
install_php_pgsql "$1"
#kill $spinner_pid1 > /dev/null 2>&1

#spinner $$ &
#spinner $spinner_pid1 &
activate_php "$1"
#kill $spinner_pid1 > /dev/null 2>&1

echo -e "Operation completed."

# Additional information
/usr/bin/php -v  # Use the absolute path to php executable
lsb_release -cd
getconf LONG_BIT
lsb_release -a
paru -Qi "php$1" "php$1-pgsql"  # Check PHP and php-pgsql package information using paru