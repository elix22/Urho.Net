if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "$OSTYPE"
        if [  ~/.bashrc ]; then
            echo ".bashrc exist"
        else
            echo ".bashrc does not exist , creating"
            touch ~/.bashrc
        fi
        echo "export URHONET_HOME_ROOT=\"$(pwd)\"" >> ~/.bashrc
        . ~/.bashrc
        echo "registered environment variable URHONET_HOME_ROOT=${URHONET_HOME_ROOT}"
elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "$OSTYPE"
        if [  ~/.bash_profile ]; then
            echo ".bash_profile exist"
        else
            echo ".bash_profile does not exist , creating"
            touch ~/.bash_profile
        fi
        echo "export URHONET_HOME_ROOT=\"$(pwd)\"" >> ~/.bash_profile
        . ~/.bash_profile
        echo "registered environment variable URHONET_HOME_ROOT=${URHONET_HOME_ROOT}"
elif [[ "$OSTYPE" == "cygwin" ]]; then
        echo "$OSTYPE"
        setx URHONET_HOME_ROOT $(pwd)
        echo "export URHONET_HOME_ROOT=\"$(pwd)\"" >> ~/.bashrc
elif [[ "$OSTYPE" == "msys" ]]; then
        echo "$OSTYPE"
        setx URHONET_HOME_ROOT $(pwd)
        echo "export URHONET_HOME_ROOT=\"$(pwd)\"" >> ~/.bashrc
        echo "registered environment variable URHONET_HOME_ROOT=$(pwd)"
elif [[ "$OSTYPE" == "freebsd"* ]]; then
        echo "$OSTYPE"
        if [  ~/.bashrc ]; then
            echo ".bashrc exist"
        else
            echo ".bashrc does not exist , creating"
            touch ~/.bashrc
        fi
        echo "export URHONET_HOME_ROOT=\"$(pwd)\"" >> ~/.bashrc
        . ~/.bashrc
        echo "registered environment variable URHONET_HOME_ROOT=${URHONET_HOME_ROOT}"
else
       echo "$OSTYPE"
fi

read -p "getk: " getk