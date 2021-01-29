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
#
if [[ "$OSTYPE" == "darwin"* ]]; then
    if [ -f ~/.bash_profile ]; then
        echo "sourcing .bash_profile "
        . ~/.bash_profile
    fi
    if [ ! -n "$URHONET_HOME_ROOT" ]; then
        echo  "ERROR !!  URHONET_HOME_ROOT path not set , set it by going to the Urho.Net folder installation and invoking set_urhonet_home.sh "
        exit -1
    else
        echo "URHONET_HOME_ROOT=${URHONET_HOME_ROOT}"
        if [ ! -d IOS ] ; then 
            echo "copying IOS folder"

            . script/project_vars.sh
            cp -R ${URHONET_HOME_ROOT}/template/IOS .

            sed -i ""  "s*TEMPLATE_PROJECT_NAME*$PROJECT_NAME*g" "IOS/CMakeLists.txt"
            sed -i ""  "s*TEMPLATE_PROJECT_NAME*$PROJECT_NAME*g" "IOS/script/build_cli_ios.sh"
            sed -i ""  "s*TEMPLATE_UUID*$PROJECT_UUID*g" "IOS/script/build_cli_ios.sh"

            currPwd=`pwd`
            cd IOS
            mkdir bin
            cd bin
            ln -s  ../../Assets/* .
            cd $currPwd
        fi  
    fi
    cd IOS
    ./script/build_cli_ios.sh "$@"
    cd ..
else
	echo  "not an Apple platform , can't run"
	exit -1
fi