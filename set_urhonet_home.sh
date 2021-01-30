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

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "$OSTYPE"
        if [ -f  ~/.bashrc ]; then
            echo ".bashrc exist"
        else
            echo ".bashrc does not exist , creating"
            touch ~/.bashrc
        fi
        echo "export URHONET_HOME_ROOT=\"$(pwd)\"" >> ~/.bashrc
        . ~/.bashrc
        echo "registered environment variable URHONET_HOME_ROOT"
elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "$OSTYPE"
        if [ -f  ~/.bash_profile ]; then
            echo ".bash_profile exist"
        else
            echo ".bash_profile does not exist , creating"
            touch ~/.bash_profile
        fi
        echo "export URHONET_HOME_ROOT=\"$(pwd)\"" >> ~/.bash_profile
        . ~/.bash_profile
        echo "registered environment variable URHONET_HOME_ROOT"
elif [[ "$OSTYPE" == "cygwin" ]]; then
        echo "$OSTYPE"
        setx URHONET_HOME_ROOT $(pwd)
        echo "export URHONET_HOME_ROOT=\"$(pwd)\"" >> ~/.bashrc
elif [[ "$OSTYPE" == "msys" ]]; then
        echo "$OSTYPE"
        setx URHONET_HOME_ROOT $(pwd)
        echo "export URHONET_HOME_ROOT=\"$(pwd)\"" >> ~/.bashrc
        echo "registered environment variable URHONET_HOME_ROOT"
elif [[ "$OSTYPE" == "freebsd"* ]]; then
        echo "$OSTYPE"
        if [ -f  ~/.bashrc ]; then
            echo ".bashrc exist"
        else
            echo ".bashrc does not exist , creating"
            touch ~/.bashrc
        fi
        echo "export URHONET_HOME_ROOT=\"$(pwd)\"" >> ~/.bashrc
        . ~/.bashrc
       echo "registered environment variable URHONET_HOME_ROOT"
else
       echo "$OSTYPE"
fi

if [[ "$OSTYPE" != "msys" ]]; then
    echo 
    echo 
    echo "close this terminal and open a new terminal to start Urho.Net development "
fi

#read -p "" getk