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

ANDROID_APP_UUID=TEMPLATE_UUID

while getopts b:d: option
do
case "${option}"
in
b) BUILD=${OPTARG};;
d) DEPLOY=${OPTARG};;
esac
done

if [[ "$BUILD" == "debug" ]]; then
    cd Android
    ./gradlew dotnetDebug
    cd ..
    mkdir -p output/Android
    cp Android/app/build/outputs/apk/debug/app-debug.apk output/Android
    if [[ "$DEPLOY" == "1" ]]; then
        adb shell am force-stop ${ANDROID_APP_UUID}
        adb install -r output/Android/app-debug.apk
        adb shell am start -n ${ANDROID_APP_UUID}/.MainActivity
    fi
elif [[ "$BUILD" == "release" ]]; then
    cd Android
    ./gradlew dotnetRelease
    cd ..
    mkdir -p output/Android
    cp Android/app/build/outputs/apk/release/app-release-unsigned.apk output/Android
fi



