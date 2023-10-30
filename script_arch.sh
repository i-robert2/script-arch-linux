#!/bin/bash

# It allows job control
set -m

# It evaluates every command before execution
# set -mxeo pipefail

# It allows to call functions from functions_arch.sh
source ./functions_arch.sh

clear
echo "Welcome, cadet!
If this is a new computer and you want the quickest arch-linux setup,
I recommend using the express installation (non-customizable).
If not, choose the customizable installation options!

1) Non-customizable automatic installation 
2) Customizable automatic installation 

"


read -p "Press 1 or 2 to choose: " install_option
export install_option


if [[ "$install_option" == "1" ]]
then 
    # This is the script for the express installation (non-customizable) 
    express_install_arch
elif [[ "$install_option" == "2" ]]
then
    # This is the script for the custom installation 
    custom_install_arch
else 
    exit 
fi

