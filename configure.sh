#!/usr/bin/env bash

# Copyright (c) 2020-2021 Eli Aloni a.k.a elix22.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

#This script will create an folder called '.urhonet_config' in the home folder
#It will create configuration files in that folder , to allow  proper functionality for Urho.Net
#Each time that the Urho.Net folder is moved to a different folder , this script must be called .

#Find out which OS we're on. 
unamestr=$(uname)

# Switch-on alias expansion within the script 
shopt -s expand_aliases

#Alias the sed in-place command for OSX and Linux - incompatibilities between BSD and Linux sed args
if [[ "$unamestr" == "Darwin" ]]; then
	alias aliassedinplace='sed -i ""'
else
	#For Linux, notice no space after the '-i' 
	alias aliassedinplace='sed -i""'
fi

currPwd=`pwd`

URHONET_CONFIG_FOLDER=.urhonet_config
HOME=~

rm -rf  ~/${URHONET_CONFIG_FOLDER}

mkdir -p  ~/${URHONET_CONFIG_FOLDER}
cp template/script/UrhoNetHome.config ~/${URHONET_CONFIG_FOLDER}/

if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
	currWinPwd=$(cygpath -m ${currPwd})
	aliassedinplace "s*TEMPLATE_URHONET_HOME*$currWinPwd*g" "$HOME/${URHONET_CONFIG_FOLDER}/UrhoNetHome.config"
else
	aliassedinplace "s*TEMPLATE_URHONET_HOME*$currPwd*g" "$HOME/${URHONET_CONFIG_FOLDER}/UrhoNetHome.config"
fi

if [ -f ~/${URHONET_CONFIG_FOLDER}/urhonethome ]; then
    rm -f ~/${URHONET_CONFIG_FOLDER}/urhonethome
fi

touch ~/${URHONET_CONFIG_FOLDER}/urhonethome
echo $currPwd >> ~/${URHONET_CONFIG_FOLDER}/urhonethome

if [[ -f ~/.urhonet_config/urhonethome  &&  -f ~/.urhonet_config/UrhoNetHome.config ]]; then
	echo ""
	echo "Urho.Net configured!"
	echo ""
	URHONET_HOME=$(cat ~/.urhonet_config/urhonethome)
	URHONET_HOME_XML=$(cat ~/.urhonet_config/UrhoNetHome.config)
	echo "cat ${HOME}/.urhonet_config/urhonethome"
	echo "${URHONET_HOME}"
	echo ""
	echo "cat ${HOME}/.urhonet_config/UrhoNetHome.config"
	echo "${URHONET_HOME_XML}"
	echo ""
else
	echo "Urho.Net configuration failure!"
fi

read -p "getk: " getk