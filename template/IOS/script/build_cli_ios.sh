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

export URHO3D_HOME=$(pwd)
export MONO_PATH=../../libs/dotnet/bcl/ios
export URHO3D_DLL_PATH=../../libs/dotnet/urho/mobile/ios
export XCODE=$(xcode-select --print-path)
export CLANG=${XCODE}/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang
export AR=${XCODE}/Toolchains/XcodeDefault.xctoolchain/usr/bin/ar
export LIPO=${XCODE}/Toolchains/XcodeDefault.xctoolchain/usr/bin/lipo
export IOS_SDK_PATH=${XCODE}/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk
export MONO_IOS_AOT_CC_PATH=../aot-compilers/iphone-arm64
export MONO_IOS_AOT_CC=./${MONO_IOS_AOT_CC_PATH}/aarch64-apple-darwin-mono-sgen
export ASSETS_FOLDER_DOTNET_PATH=bin/Data/DotNet
export ASSETS_FOLDER_DOTNET_IOS_PATH=bin/Data/DotNet/ios
export C_SHARP_SOURCE_CODE='../../Program.cs  -recurse:'../../Source/*.cs''
export INTERMEDIATE_FOLDER=intermediate

export BUILD_DIR=build

export UUID='TEMPLATE_UUID'
export APP_NAME='TEMPLATE_PROJECT_NAME' 
export LOWER_APP_NAME=$(echo ${APP_NAME} |  tr 'A-Z' 'a-z')

shopt -s expand_aliases
alias aliassedinplace='sed -i ""'


warn() {
    printf >&2 "$SCRIPTNAME: $*\n"
}

iscmd() {
    command -v >&- "$@"
}

checkdeps() {
    local -i not_found
    for cmd; do
        iscmd "$cmd" || { 
            warn $"$cmd is not found"
            let not_found++
        }
    done
    (( not_found == 0 )) || {
        warn $"Install dependencies listed above  $SCRIPTNAME"
        exit 1
    }
}

aot_compile_file()
{
    if [ -f $3/$2.o ]; then
        if [ $1/$2 -nt $3/$2.o ]; then
            #echo "$1/$2 newer then $3/$2.o"
            cp $1/$2 ${ASSETS_FOLDER_DOTNET_IOS_PATH}
            ${MONO_IOS_AOT_CC}   --aot=asmonly,full,direct-icalls,direct-pinvoke,static,mtriple=arm64-ios,outfile=$3/$2.s  -O=gsharedvt $1/$2
            ${CLANG} -isysroot ${IOS_SDK_PATH} -Qunused-arguments -miphoneos-version-min=10.0  -arch arm64 -c -o $3/$2.o -x assembler $3/$2.s 
        fi
    else
        cp $1/$2 ${ASSETS_FOLDER_DOTNET_IOS_PATH}
        ${MONO_IOS_AOT_CC}   --aot=asmonly,full,direct-icalls,direct-pinvoke,static,mtriple=arm64-ios,outfile=$3/$2.s  -O=gsharedvt $1/$2
        ${CLANG} -isysroot ${IOS_SDK_PATH} -Qunused-arguments -miphoneos-version-min=10.0  -arch arm64 -c -o $3/$2.o -x assembler $3/$2.s 
    fi
}


copy_file()
{
    if [ -f $2 ]; then
        if [[ $1/$2 -nt $2 ]]; then cp $1/$2 $3; fi
    else 
        cp $1/$2 $3
    fi
    
}


check_ios_env_vars()
{
    if [ -f ${BUILD_DIR}/ios_env_vars.sh ]; then
        echo "ios_env_vars.sh exist"
         # setup the variables
        . ${BUILD_DIR}/ios_env_vars.sh
    else
        echo "Enter your development team."
        read -p "development team: " development_team
        if [[ "$development_team" == "" ]]; then
            echo
            echo "ERROR: No development team specified."
            echo
            exit -1;
        fi

        security find-identity -v -p codesigning

        echo "Enter your code sign identity. (press enter for default)"
        read -p "code sign identity: " code_sign_identity
        if [[ "$code_sign_identity" == "" ]]; then
            echo
            echo "No code sign identity specified , will choose default ."
            echo
        fi

        echo "Enter your provisioning profile. (press enter for default)"
        read -p "provisioning profile: " provisioning_profile
        if [[ "$provisioning_profile" == "" ]]; then
            echo
            echo "No provisioning profile specified , will choose default."
            echo
        fi

        mkdir -p ${BUILD_DIR}

        cp ./script/ios_env_vars.sh ${BUILD_DIR}
        aliassedinplace "s*T_DEVELOPMENT_TEAM*$development_team*g" "${BUILD_DIR}/ios_env_vars.sh"
        aliassedinplace "s*T_CODE_SIGN_IDENTITY*$code_sign_identity*g" "${BUILD_DIR}/ios_env_vars.sh"
        aliassedinplace "s*T_PROVISIONING_PROFILE_SPECIFIER*$provisioning_profile*g" "${BUILD_DIR}/ios_env_vars.sh"

        # setup the variables
        . ${BUILD_DIR}/ios_env_vars.sh

    fi
}


# check dependencies
checkdeps brew cmake xcodebuild ios-deploy codesign mcs

# check/set  ios environment variables
check_ios_env_vars

mkdir -p ${ASSETS_FOLDER_DOTNET_IOS_PATH}

# first run camke
./script/cmake_ios_dotnet.sh ${BUILD_DIR} -DDEVELOPMENT_TEAM=${DEVELOPMENT_TEAM} -DCODE_SIGN_IDENTITY=${CODE_SIGN_IDENTITY} -DPROVISIONING_PROFILE_SPECIFIER=${PROVISIONING_PROFILE_SPECIFIER}


mkdir -p ${BUILD_DIR}
cd ${BUILD_DIR}
mkdir ${INTERMEDIATE_FOLDER}


cp ../script/ios.entitlements .
aliassedinplace "s*T_DEVELOPER_ID*$DEVELOPMENT_TEAM*g" "ios.entitlements"
aliassedinplace "s*T_UUID*$UUID*g" "ios.entitlements"


copy_file ${URHO3D_DLL_PATH} UrhoDotNet.dll .


mcs  /target:exe /out:Game.dll /reference:UrhoDotNet.dll /platform:x64 ${C_SHARP_SOURCE_CODE}
mkdir -p ${ASSETS_FOLDER_DOTNET_PATH}
cp Game.dll ${ASSETS_FOLDER_DOTNET_PATH}


aot_compile_file ${MONO_PATH} mscorlib.dll ${INTERMEDIATE_FOLDER}
aot_compile_file ${MONO_PATH} System.Core.dll ${INTERMEDIATE_FOLDER}
aot_compile_file ${MONO_PATH} System.dll ${INTERMEDIATE_FOLDER}
aot_compile_file ${MONO_PATH} System.Xml.dll ${INTERMEDIATE_FOLDER}
aot_compile_file ${MONO_PATH} Mono.Security.dll ${INTERMEDIATE_FOLDER}
aot_compile_file ${MONO_PATH} System.Numerics.dll ${INTERMEDIATE_FOLDER}
aot_compile_file ${MONO_PATH}/Facades System.Runtime.dll ${INTERMEDIATE_FOLDER}
aot_compile_file ${MONO_PATH}/Facades System.Threading.Tasks.dll ${INTERMEDIATE_FOLDER}
aot_compile_file ${MONO_PATH}/Facades System.Linq.dll ${INTERMEDIATE_FOLDER}
aot_compile_file . UrhoDotNet.dll ${INTERMEDIATE_FOLDER}
aot_compile_file . Game.dll ${INTERMEDIATE_FOLDER}


${AR} cr lib-urho3d-mono-aot.a  ${INTERMEDIATE_FOLDER}/*.o

mv lib-urho3d-mono-aot.a ../../libs/ios


xcodebuild -project ../${BUILD_DIR}/${APP_NAME}.xcodeproj

ios-deploy --justlaunch --bundle ../${BUILD_DIR}/bin/${APP_NAME}.app
