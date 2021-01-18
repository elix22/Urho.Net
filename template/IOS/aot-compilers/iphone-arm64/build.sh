#!/usr/bin/env bash
export MONO_PATH=../../../libs/dotnet/bcl/ios
export URHO3D_DLL_PATH=../../../libs/dotnet/urho/mobile/ios
export XCODE=$(xcode-select --print-path)
export CLANG=${XCODE}/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang
export AR=${XCODE}/Toolchains/XcodeDefault.xctoolchain/usr/bin/ar
export LIPO=${XCODE}/Toolchains/XcodeDefault.xctoolchain/usr/bin/lipo
export IOS_SDK_PATH=${XCODE}/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk

cp ${URHO3D_DLL_PATH}/UrhoDotNet.dll .

./aarch64-apple-darwin-mono-sgen   --aot=asmonly,full,direct-icalls,direct-pinvoke,static,mtriple=arm64-ios,outfile=mscorlib.dll.s  -O=gsharedvt ${MONO_PATH}/mscorlib.dll
./aarch64-apple-darwin-mono-sgen   --aot=asmonly,full,direct-icalls,direct-pinvoke,static,mtriple=arm64-ios,outfile=System.Core.dll.s  -O=gsharedvt ${MONO_PATH}/System.Core.dll
./aarch64-apple-darwin-mono-sgen   --aot=asmonly,full,direct-icalls,direct-pinvoke,static,mtriple=arm64-ios,outfile=System.dll.s  -O=gsharedvt ${MONO_PATH}/System.dll
./aarch64-apple-darwin-mono-sgen   --aot=asmonly,full,direct-icalls,direct-pinvoke,static,mtriple=arm64-ios,outfile=System.Xml.dll.s  -O=gsharedvt ${MONO_PATH}/System.Xml.dll
./aarch64-apple-darwin-mono-sgen   --aot=asmonly,full,direct-icalls,direct-pinvoke,static,mtriple=arm64-ios,outfile=Mono.Security.s  -O=gsharedvt ${MONO_PATH}/Mono.Security.dll
./aarch64-apple-darwin-mono-sgen   --aot=asmonly,full,direct-icalls,direct-pinvoke,static,mtriple=arm64-ios,outfile=System.Numerics.dll.s  -O=gsharedvt ${MONO_PATH}/System.Numerics.dll

./aarch64-apple-darwin-mono-sgen   --aot=asmonly,full,direct-icalls,direct-pinvoke,static,mtriple=arm64-ios,outfile=System.Runtime.dll.s  -O=gsharedvt ${MONO_PATH}/Facades/System.Runtime.dll
./aarch64-apple-darwin-mono-sgen   --aot=asmonly,full,direct-icalls,direct-pinvoke,static,mtriple=arm64-ios,outfile=System.Threading.Tasks.dll.s  -O=gsharedvt ${MONO_PATH}/Facades/System.Threading.Tasks.dll
./aarch64-apple-darwin-mono-sgen   --aot=asmonly,full,direct-icalls,direct-pinvoke,static,mtriple=arm64-ios,outfile=System.Linq.s  -O=gsharedvt ${MONO_PATH}/Facades/System.Linq.dll


./aarch64-apple-darwin-mono-sgen   --aot=asmonly,full,direct-icalls,direct-pinvoke,static,mtriple=arm64-ios,outfile=UrhoDotNet.dll.s  -O=gsharedvt ./UrhoDotNet.dll
./aarch64-apple-darwin-mono-sgen   --aot=asmonly,full,direct-icalls,direct-pinvoke,static,mtriple=arm64-ios,outfile=Game.dll.s  -O=gsharedvt ./Game.dll

#for i in ./*.dll; do ./aarch64-apple-darwin-mono-sgen   --aot=asmonly,full,direct-icalls,direct-pinvoke,static,mtriple=arm64-ios,outfile=$i.s  -O=gsharedvt  $i; done
#for i in ./*.exe; do ./aarch64-apple-darwin-mono-sgen   --aot=asmonly,full,direct-icalls,direct-pinvoke,static,mtriple=arm64-ios,outfile=$i.s   -O=gsharedvt  $i; done

for i in ./*.s; do ${CLANG} -isysroot ${IOS_SDK_PATH} -Qunused-arguments -miphoneos-version-min=10.0  -arch arm64 -c -o $i.o -x assembler $i ; done

#rm lib-urho3d-mono-aot.a 
 
${AR} cr lib-urho3d-mono-aot.a  *.o

mv lib-urho3d-mono-aot.a ../../../libs/ios

rm *.s
rm *.o