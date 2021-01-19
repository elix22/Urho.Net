#!/bin/bash
# ********************************************************************
#
# newproject.sh
#
# This script generates a set of  project files.
# The new project will be based of the template project and 
# it will be generated with the name and location that is specified
# as input parameters.
#
# IMPORTANT: This script must be run from the root of the 
# source tree.
#
# ********************************************************************

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

echo
echo "1. Enter a name for the new project."
echo
echo "   This name will be given to the project"
echo "   executable and a folder with this name"
echo "   will be created to store all project files."
echo "   Ex. foobar"
echo
read -p "Project Name: " projName 
if [[ "$projName" == "" ]]; then
	echo
	echo "ERROR: No project name specified."
	echo
	exit -1;
fi
echo

projName="$(echo -e "${projName}" | tr -d '[:space:]')"
projectNameLower=$(echo ${projName} |  tr 'A-Z' 'a-z')
title=${projName}
className=${projName}


echo
echo "3. Enter a unique identifier for your project."
echo
echo "   This should be a human readable package name,"
echo "   containing at least two words separated by a"
echo "   period."
echo "   Ex. com.example.foobar"
echo
read -p "Unique ID: " uuid
if [[ "$uuid" == "" ]]; then
	echo
	echo "ERROR: No uuid specified."
	echo
	exit -1;
fi
echo

uuid=$(echo ${uuid} |  sed 's/'${projectNameLower}'//g' )
uuid=${uuid}.${projectNameLower}
uuid=$(echo "$uuid" | tr . /) 
for i in {1..10}
do
   uuid=`echo "$uuid" | sed 's_//_/_g'`
done
uuid=$(echo "$uuid" | tr / .) 

java_package_path=$(echo "$uuid" | tr . /) 
for i in {1..10}
do
   java_package_path=`echo "$java_package_path" | sed 's_//_/_g'`
done
java_package_path=`echo "java/$java_package_path"`


echo
echo "5. Enter the project path."
echo
echo "   This can be a relative path, absolute path,"
echo "   or empty for the current folder. Note that"
echo "   a project folder named $projName will also"
echo "   be created inside this folder."
echo "   Ex. ./samples"
echo
read -p "Path: " location
if [[ "$location" == "" ]]; then
	projPath=$projName
else
	projPath="$location/$projName"
fi
echo

# Verify Path and eliminate double '//'
projPath=`echo "$projPath" | sed 's_//_/_g'`
if [ -e $projPath ]; then
	echo
	echo "ERROR: Path '$projPath' already exists, aborting."
	echo
	exit -2
fi

# Make required source folder directories
mkdir -p "$projPath"


currPwd=`pwd`
projPath=`cd $projPath; pwd`
`cd $currPwd`


cp "-r" "template/Android" "$projPath"
mkdir "-p" "$projPath/Android/app/src/main/${java_package_path}"
mkdir "-p" "$projPath/Android/app/src/androidTest/${java_package_path}"
mkdir "-p" "$projPath/Android/app/src/test/${java_package_path}"

mv "$projPath/Android/app/src/main/MainActivity.kt" "$projPath/Android/app/src/main/${java_package_path}"
mv "$projPath/Android/app/src/main/UrhoStartActivity.kt" "$projPath/Android/app/src/main/${java_package_path}"
mv "$projPath/Android/app/src/androidTest/ExampleInstrumentedTest.kt" "$projPath/Android/app/src/androidTest/${java_package_path}"
mv "$projPath/Android/app/src/test/ExampleUnitTest.kt" "$projPath/Android/app/src/test/${java_package_path}"

aliassedinplace "s*TEMPLATE_UUID*$uuid*g" "$projPath/Android/app/src/main/AndroidManifest.xml"
aliassedinplace "s*TEMPLATE_UUID*$uuid*g" "$projPath/Android/app/build.gradle"
aliassedinplace "s*TEMPLATE_UUID*$uuid*g" "$projPath/Android/app/src/main/${java_package_path}/MainActivity.kt"
aliassedinplace "s*TEMPLATE_UUID*$uuid*g" "$projPath/Android/app/src/main/${java_package_path}/UrhoStartActivity.kt"

aliassedinplace "s*TEMPLATE_UUID*$uuid*g" "$projPath/Android/app/src/androidTest/${java_package_path}/ExampleInstrumentedTest.kt"
aliassedinplace "s*TEMPLATE_UUID*$uuid*g" "$projPath/Android/app/src/test/${java_package_path}/ExampleUnitTest.kt"

aliassedinplace "s*TEMPLATE_PROJECT_NAME*$projName*g" "$projPath/Android/settings.gradle"
aliassedinplace "s*TEMPLATE_PROJECT_NAME*$projName*g" "$projPath/Android/app/src/main/res/values/strings.xml"

cp "-r" "template/Assets" "$projPath"
cp "-r" "template/include" "$projPath"

cp "-r" "template/IOS" "$projPath"
aliassedinplace "s*TEMPLATE_PROJECT_NAME*$projName*g" "$projPath/IOS/CMakeLists.txt"
aliassedinplace "s*TEMPLATE_PROJECT_NAME*$projName*g" "$projPath/IOS/script/build_cli_ios.sh"
aliassedinplace "s*TEMPLATE_UUID*$uuid*g" "$projPath/IOS/script/build_cli_ios.sh"

currPwd=`pwd`
cd $projPath/IOS
mkdir bin
cd bin
ln -s  ../../Assets/* .
cd $currPwd

cp "-r" "template/libs" "$projPath"
cp "-r" "template/Source" "$projPath"
mv "$projPath/Source/template.cs" "$projPath/Source/${projName}.cs" 

aliassedinplace "s*TEMPLATE_PROJECT_NAME*$projName*g" "$projPath/Source/${projName}.cs"
aliassedinplace "s*TEMPLATE_CLASS_NAME*$className*g" "$projPath/Source/${projName}.cs"

aliassedinplace "s*TEMPLATE_PROJECT_NAME*$projName*g" "$projPath/Source/Sample.cs"


cp "template/Program.cs" "$projPath/Program.cs"
aliassedinplace "s*TEMPLATE_PROJECT_NAME*$projName*g" "$projPath/Program.cs"
aliassedinplace "s*TEMPLATE_CLASS_NAME*$className*g" "$projPath/Program.cs"

cp "template/template.csproj" "$projPath/$projName.csproj"

mkdir "-p" "$projPath/tools"
cp "-r" "tools/ReferenceAssemblyResolver" "$projPath/tools"

echo "Successful creation"
echo "Project name : '$projName'"
echo "Unique identifier : '$uuid'"
echo "Project path : '$projPath'"
#echo ${java_package_path}
