#! /usr/bin/env bash
#
# Copyright (C) 2013-2014 Zhang Rui <bbcallen@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# This script is based on projects below
# https://github.com/yixia/FFmpeg-Android
# http://git.videolan.org/?p=vlc-ports/android.git;a=summary

#--------------------
echo "===================="
echo "[*] check env $1"
echo "===================="
set -e


#--------------------
# common defines
FF_ARCH=$1
FF_BUILD_ROOT=$2
FF_BUILD_OPT=$3

echo "FF_ARCH=$FF_ARCH"
echo "FF_BUILD_OPT=$FF_BUILD_OPT"
if [ -z "$FF_ARCH" ]; then
    echo "You must specific an architecture 'arm, armv7a, x86, ...'."
    echo ""
    exit 1
fi

if [ "$FF_BUILD_ROOT" = "" ] ;then
	FF_BUILD_ROOT=`pwd`
fi

FF_ANDROID_PLATFORM=android-9

FF_BUILD_NAME=
FF_SOURCE=
FF_CROSS_PREFIX=

#配置表
FF_CFG_FLAGS=
#附加依赖库
FF_EXTRA_CFLAGS=
FF_EXTRA_LDFLAGS=
FF_EXTRA_CXXLDFLAGS=""
FF_EXTRA_LIBS=

#模块列表
FF_MODULE_DIRS="compat libavcodec libavfilter libavformat libavutil libswresample libswscale"
FF_ASSEMBLER_SUB_DIRS=


#配置参数
if [ "$FF_ARCH" = "x86" ]; then
    FF_CFG_FLAGS="$FF_CFG_FLAGS --disable-asm"
else
    # Optimization options (experts only):
    FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-asm"
    FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-inline-asm"
fi

case "$FF_BUILD_OPT" in
    debug)
        FF_CFG_FLAGS="$FF_CFG_FLAGS --disable-optimizations"
        FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-debug"
        FF_CFG_FLAGS="$FF_CFG_FLAGS --disable-small"
        FF_CFG_FLAGS="$FF_CFG_FLAGS --disable-stripping"
    ;;
    *)
#       FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-optimizations"
        FF_CFG_FLAGS="$FF_CFG_FLAGS --disable-debug"
#       FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-small"
		FF_CFG_FLAGS="$FF_CFG_FLAGS --disable-optimizations"
		FF_CFG_FLAGS="$FF_CFG_FLAGS --disable-small"
    ;;
esac

#--------------------
echo ""
echo "--------------------"
echo "[*] make NDK standalone toolchain"
echo "--------------------"
. ./tools/do-detect-env.sh
FF_MAKE_TOOLCHAIN_FLAGS=$IJK_MAKE_TOOLCHAIN_FLAGS
FF_MAKE_FLAGS=$IJK_MAKE_FLAG
FF_GCC_VER=$IJK_GCC_VER
FF_GCC_64_VER=$IJK_GCC_64_VER


#----- armv7a begin -----
if [ "$FF_ARCH" = "armv7a" ]; then
    FF_BUILD_NAME=ffmpeg-armv7a
    FF_BUILD_NAME_OPENSSL=openssl-armv7a
    FF_BUILD_NAME_LIBSOXR=libsoxr-armv7a
    FF_SOURCE=$FF_BUILD_ROOT/$FF_BUILD_NAME

    FF_CROSS_PREFIX=arm-linux-androideabi
    FF_TOOLCHAIN_NAME=${FF_CROSS_PREFIX}-${FF_GCC_VER}

    FF_CFG_FLAGS="$FF_CFG_FLAGS --arch=arm --cpu=cortex-a8"
    FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-neon"
    FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-thumb"

    FF_EXTRA_CFLAGS="$FF_EXTRA_CFLAGS -march=armv7-a -mcpu=cortex-a8 -mfpu=vfpv3-d16 -mfloat-abi=softfp -mthumb"
    FF_EXTRA_LDFLAGS="$FF_EXTRA_LDFLAGS -Wl,--fix-cortex-a8"

    FF_ASSEMBLER_SUB_DIRS="arm"

elif [ "$FF_ARCH" = "armv5" ]; then
    FF_BUILD_NAME=ffmpeg-armv5
    FF_BUILD_NAME_OPENSSL=openssl-armv5
    FF_BUILD_NAME_LIBSOXR=libsoxr-armv5
    FF_SOURCE=$FF_BUILD_ROOT/$FF_BUILD_NAME

    FF_CROSS_PREFIX=arm-linux-androideabi
    FF_TOOLCHAIN_NAME=${FF_CROSS_PREFIX}-${FF_GCC_VER}

    FF_CFG_FLAGS="$FF_CFG_FLAGS --arch=arm"

    FF_EXTRA_CFLAGS="$FF_EXTRA_CFLAGS -march=armv5te -mtune=arm9tdmi -msoft-float"
    FF_EXTRA_LDFLAGS="$FF_EXTRA_LDFLAGS"

    FF_ASSEMBLER_SUB_DIRS="arm"

elif [ "$FF_ARCH" = "x86" ]; then
    FF_BUILD_NAME=ffmpeg-x86
    FF_BUILD_NAME_OPENSSL=openssl-x86
    FF_BUILD_NAME_LIBSOXR=libsoxr-x86
    FF_SOURCE=$FF_BUILD_ROOT/$FF_BUILD_NAME

    FF_CROSS_PREFIX=i686-linux-android
    FF_TOOLCHAIN_NAME=x86-${FF_GCC_VER}

    FF_CFG_FLAGS="$FF_CFG_FLAGS --arch=x86 --cpu=i686 --enable-yasm"

    FF_EXTRA_CFLAGS="$FF_EXTRA_CFLAGS -march=atom -msse3 -ffast-math -mfpmath=sse"
    FF_EXTRA_LDFLAGS="$FF_EXTRA_LDFLAGS"

    FF_ASSEMBLER_SUB_DIRS="x86"

elif [ "$FF_ARCH" = "x86_64" ]; then
    FF_ANDROID_PLATFORM=android-21

    FF_BUILD_NAME=ffmpeg-x86_64
    FF_BUILD_NAME_OPENSSL=openssl-x86_64
    FF_BUILD_NAME_LIBSOXR=libsoxr-x86_64
    FF_SOURCE=$FF_BUILD_ROOT/$FF_BUILD_NAME

    FF_CROSS_PREFIX=x86_64-linux-android
    FF_TOOLCHAIN_NAME=${FF_CROSS_PREFIX}-${FF_GCC_64_VER}

    FF_CFG_FLAGS="$FF_CFG_FLAGS --arch=x86_64 --enable-yasm"

    FF_EXTRA_CFLAGS="$FF_EXTRA_CFLAGS"
    FF_EXTRA_LDFLAGS="$FF_EXTRA_LDFLAGS"

    FF_ASSEMBLER_SUB_DIRS="x86"

elif [ "$FF_ARCH" = "arm64" ]; then
    FF_ANDROID_PLATFORM=android-21

    FF_BUILD_NAME=ffmpeg-arm64
    FF_BUILD_NAME_OPENSSL=openssl-arm64
    FF_BUILD_NAME_LIBSOXR=libsoxr-arm64
    FF_SOURCE=$FF_BUILD_ROOT/$FF_BUILD_NAME

    FF_CROSS_PREFIX=aarch64-linux-android
    FF_TOOLCHAIN_NAME=${FF_CROSS_PREFIX}-${FF_GCC_64_VER}

    FF_CFG_FLAGS="$FF_CFG_FLAGS --arch=aarch64 --enable-yasm"

    FF_EXTRA_CFLAGS="$FF_EXTRA_CFLAGS"
    FF_EXTRA_LDFLAGS="$FF_EXTRA_LDFLAGS"

    FF_ASSEMBLER_SUB_DIRS="aarch64 neon"

else
    echo "unknown architecture $FF_ARCH";
    exit 1
fi

echo ""
echo "--------------------"
echo "[*] check module"
echo "--------------------"
export COMMON_FF_CFG_FLAGS=$(./config/module.sh)

#echo $COMMON_FF_CFG_FLAGS
FF_CFG_FLAGS="$FF_CFG_FLAGS $COMMON_FF_CFG_FLAGS"

echo ""
echo "--------------------"
echo "[*] check extern module"
echo "--------------------"
#--------------------附加库
FF_DEP_OPENSSL_INC=$FF_BUILD_ROOT/build/$FF_BUILD_NAME_OPENSSL/output/include
FF_DEP_OPENSSL_LIB=$FF_BUILD_ROOT/build/$FF_BUILD_NAME_OPENSSL/output/lib
FF_DEP_LIBSOXR_INC=$FF_BUILD_ROOT/build/$FF_BUILD_NAME_LIBSOXR/output/include
FF_DEP_LIBSOXR_LIB=$FF_BUILD_ROOT/build/$FF_BUILD_NAME_LIBSOXR/output/lib

# with openssl
if [ -f "${FF_DEP_OPENSSL_LIB}/libssl.a" ]; then
    echo "OpenSSL detected"
# FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-nonfree"
    FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-openssl"

    FF_CFLAGS="$FF_CFLAGS -I${FF_DEP_OPENSSL_INC}"
    FF_EXTRA_LIBS="$FF_EXTRA_LIBS -L${FF_DEP_OPENSSL_LIB} -lssl -lcrypto"
fi

if [ -f "${FF_DEP_LIBSOXR_LIB}/libsoxr.a" ]; then
    echo "libsoxr detected"
    FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-libsoxr"

    FF_CFLAGS="$FF_CFLAGS -I${FF_DEP_LIBSOXR_INC}"
    FF_EXTRA_LIBS="$FF_EXTRA_LIBS -L${FF_DEP_LIBSOXR_LIB} -lsoxr"
fi

FF_DEP_LIBSTAGEFRIGHT=false
# with libstagefright
if [ ${FF_DEP_LIBSTAGEFRIGHT} == true ]; then
    ANDROID_SOURCE=$(pwd)/../android-source
    ANDROID_LIBS=$(pwd)/../android-libs
    ANDROID_STD=$ANDROID_NDK/sources/cxx-stl/gnu-libstdc++/4.9/
    echo "Fetching Android system headers"
    if [ ! -d $ANDROID_SOURCE/frameworks/base ]; then
        git clone --depth=1 --branch gingerbread-release https://github.com/CyanogenMod/android_frameworks_base.git $ANDROID_SOURCE/frameworks/base
        git clone --depth=1 --branch gingerbread-release https://github.com/CyanogenMod/android_system_core.git $ANDROID_SOURCE/system/core
    fi
    if [ ! -d $ANDROID_LIBS ];then
        unzip ./update-cm-7.0.3-N1-signed.zip system/lib/* -d../
        mv ../system/lib $ANDROID_LIBS
        rmdir ../system
    fi

    echo "libstagefright detected"
    if [ "$FF_ARCH" == "armv7a" ]; then
        ABI="armeabi-v7a"
    elif [ "$FF_ARCH" == "arm64" ]; then
        ABI="arm64-v8a"
    elif [ "$FF_ARCH" == "armv5" ]; then
        ABI="armeabi"
    else
        ABI=$FF_ARCH
    fi
    FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-libstagefright-h264 --enable-decoder=libstagefright_h264"

    FF_EXTRA_CFLAGS="-I$ANDROID_SOURCE/frameworks/base/include -I$ANDROID_SOURCE/system/core/include"
    FF_EXTRA_CFLAGS="$FF_EXTRA_CFLAGS -I$ANDROID_SOURCE/frameworks/base/media/libstagefright"
    FF_EXTRA_CFLAGS="$FF_EXTRA_CFLAGS -I$ANDROID_SOURCE/frameworks/base/include/media/stagefright/openmax"
    FF_EXTRA_CFLAGS="$FF_EXTRA_CFLAGS -I$ANDROID_STD/include -I$ANDROID_STD/libs/$ABI/include"
    #用于修正代码在高版本可用
    FF_EXTRA_CFLAGS="$FF_EXTRA_CFLAGS -fPIC -DHAVE_PTHREADS"

    FF_EXTRA_LDFLAGS="$FF_EXTRA_LDFLAGS -L$ANDROID_LIBS -Wl,-rpath-link,$ANDROID_LIBS -L$ANDROID_STD/libs/$ABI"
    #链接到库使得Android能正确加载
    FF_EXTRA_LDFLAGS="$FF_EXTRA_LDFLAGS -lstagefright -lmedia -lstdc++ -lutils -lbinder -lgnustl_static -ldl"
    FF_EXTRA_LDFLAGS="$FF_EXTRA_LDFLAGS -fuse-ld=bfd"

    FF_EXTRA_CXXLDFLAGS="$FF_EXTRA_CXXLDFLAGS -Wno-multichar -fno-exceptions -fno-rtti -DHAVE_PTHREADS"

    cp -P ${ANDROID_SOURCE}/frameworks/base/media/libstagefright/MediaBufferGroup.cpp $FF_SOURCE/libavcodec/
    cp -P ${ANDROID_SOURCE}/frameworks/base/include/media/stagefright/MediaBufferGroup.h $FF_SOURCE/libavcodec/
fi

if [ ! -d $FF_SOURCE ]; then
    echo ""
    echo "!! ERROR"
    echo "!! Can not find FFmpeg directory for $FF_BUILD_NAME"
    echo "!! Run 'sh init-android.sh' first"
    echo ""
    exit 1
fi

FF_TOOLCHAIN_PATH=$FF_BUILD_ROOT/build/$FF_BUILD_NAME/toolchain
FF_MAKE_TOOLCHAIN_FLAGS="$FF_MAKE_TOOLCHAIN_FLAGS --install-dir=$FF_TOOLCHAIN_PATH"

FF_SYSROOT=$FF_TOOLCHAIN_PATH/sysroot
FF_PREFIX=$FF_BUILD_ROOT/build/$FF_BUILD_NAME/output

case "$UNAME_S" in
    CYGWIN_NT-*)
        FF_SYSROOT="$(cygpath -am $FF_SYSROOT)"
        FF_PREFIX="$(cygpath -am $FF_PREFIX)"
    ;;
esac

rm -r -f $FF_PREFIX
mkdir -p $FF_PREFIX
# mkdir -p $FF_SYSROOT


FF_TOOLCHAIN_TOUCH="$FF_TOOLCHAIN_PATH/touch"
if [ ! -f "$FF_TOOLCHAIN_TOUCH" ]; then
    $ANDROID_NDK/build/tools/make-standalone-toolchain.sh \
        $FF_MAKE_TOOLCHAIN_FLAGS \
        --platform=$FF_ANDROID_PLATFORM \
        --toolchain=$FF_TOOLCHAIN_NAME
    touch $FF_TOOLCHAIN_TOUCH;
fi


#--------------------
echo ""
echo "--------------------"
echo "[*] check ffmpeg env"
echo "--------------------"
export PATH=$FF_TOOLCHAIN_PATH/bin/:$PATH
#export CC="ccache ${FF_CROSS_PREFIX}-gcc"
export CC="${FF_CROSS_PREFIX}-gcc"
#export CXX="${FF_CROSS_PREFIX}-g++"
export LD=${FF_CROSS_PREFIX}-ld
export AR=${FF_CROSS_PREFIX}-ar
export STRIP=${FF_CROSS_PREFIX}-strip

FF_CFLAGS="$FF_CFLAGS -Wall -pipe \
    -std=c99 \
    -ffast-math \
    -Wno-psabi -Wa,--noexecstack \
    -DANDROID"

case "$FF_BUILD_OPT" in
    debug)
        FF_CFLAGS="$FF_CFLAGS -DDEBUG"
    ;;
    *)
        FF_CFLAGS="$FF_CFLAGS -O1 -DNDEBUG \
        -fstrict-aliasing -Werror=strict-aliasing"
    ;;
esac

# cause av_strlcpy crash with gcc4.7, gcc4.8
# -fmodulo-sched -fmodulo-sched-allow-regmoves

# --enable-thumb is OK
#FF_CFLAGS="$FF_CFLAGS -mthumb"

# not necessary
#FF_CFLAGS="$FF_CFLAGS -finline-limit=300"


#--------------------
echo ""
echo "--------------------"
echo "[*] check ffmpeg config"
echo "--------------------"

#--------------------
# Standard options:
FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-shared"
FF_CFG_FLAGS="$FF_CFG_FLAGS --prefix=$FF_PREFIX"

# Advanced options (experts only):
FF_CFG_FLAGS="$FF_CFG_FLAGS --cross-prefix=${FF_CROSS_PREFIX}-"
FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-cross-compile"
FF_CFG_FLAGS="$FF_CFG_FLAGS --target-os=android"
FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-pic"
# FF_CFG_FLAGS="$FF_CFG_FLAGS --disable-symver"

#--------------------
echo ""
echo "--------------------"
echo "[*] configurate ffmpeg"
echo "--------------------"
cd $FF_SOURCE
echo $FF_CFG_FLAGS
if [ -f "./config.h" ]; then
    echo 'reuse configure'
fi
    which $CC
    ./configure --help > ../configure.txt
    ./configure $FF_CFG_FLAGS \
        --extra-cflags="$FF_CFLAGS $FF_EXTRA_CFLAGS" \
        --extra-ldflags="$FF_EXTRA_LIBS $FF_EXTRA_LDFLAGS" \
		--extra-cxxflags="$FF_EXTRA_CXXLDFLAGS"
    make clean
#fi

#--------------------
echo ""
echo "--------------------"
echo "[*] compile ffmpeg"
echo "--------------------"
cp config.* $FF_PREFIX
make clean
make $FF_MAKE_FLAGS > /dev/null
make install
mkdir -p $FF_PREFIX/include/libffmpeg
cp -f config.h $FF_PREFIX/include/libffmpeg/config.h

#--------------------
echo ""
echo "--------------------"
echo "[*] link ffmpeg"
echo "--------------------"
echo $FF_EXTRA_LDFLAGS


echo ""
echo "--------------------"
echo "[*] link ffmpeg object"
echo "--------------------"
FF_MERGE_O_A="no"  #OBJ A
FF_C_OBJ_FILES=
FF_ASM_OBJ_FILES=
FF_C_MERGE_FILES=
for MODULE_DIR in $FF_MODULE_DIRS
do
    C_OBJ_FILES="$MODULE_DIR/*.o"
    if ls $C_OBJ_FILES 1> /dev/null 2>&1; then
		echo "link $MODULE_DIR/*.o"
		FF_C_OBJ_FILES="$FF_C_OBJ_FILES $C_OBJ_FILES"
		
		if [ $FF_MERGE_O_A == "OBJ" ]; then
			$AR rcs $FF_PREFIX/lib${MODULE_DIR}.a $C_OBJ_FILES
			FF_C_MERGE_FILES="$FF_C_MERGE_FILES lib${MODULE_DIR}.a"
		elif [ $FF_MERGE_O_A == "A" ]; then
			$LD -r $C_OBJ_FILES -o $FF_PREFIX/lib${MODULE_DIR}.o
			FF_C_MERGE_FILES="$FF_C_MERGE_FILES $FF_PREFIX/lib${MODULE_DIR}.o"
		fi
    fi
	
    for ASM_SUB_DIR in $FF_ASSEMBLER_SUB_DIRS
    do
        ASM_OBJ_FILES="$MODULE_DIR/$ASM_SUB_DIR/*.o"
        if ls $ASM_OBJ_FILES 1> /dev/null 2>&1; then
			echo "link $MODULE_DIR/$ASM_SUB_DIR/*.o"
			FF_ASM_OBJ_FILES="$FF_ASM_OBJ_FILES $ASM_OBJ_FILES"
			
			if [ $FF_MERGE_O_A == "OBJ" ]; then
				$AR rcs $FF_PREFIX/lib${MODULE_DIR}_${ASM_SUB_DIR}.a $ASM_OBJ_FILES
				FF_C_MERGE_FILES="$FF_C_MERGE_FILES lib${MODULE_DIR}_${ASM_SUB_DIR}.a"
			elif [ $FF_MERGE_O_A == "A" ]; then
				$LD -r $ASM_OBJ_FILES -o $FF_PREFIX/lib${MODULE_DIR}_${ASM_SUB_DIR}.o
				FF_C_MERGE_FILES="$FF_C_MERGE_FILES $FF_PREFIX/lib${MODULE_DIR}_${ASM_SUB_DIR}.o"
			fi
        fi
    done
done


echo ""
echo "--------------------"
echo "[*] link ffmpeg so"
echo "--------------------"
# CURRETN_PATH=$(pwd)
# cd $FF_PREFIX
# FF_C_MERGE_COMMAND=
# if [ $FF_MERGE_O_A == 1 ]; then
# 	FF_C_MERGE_COMMAND="-Wl,--whole-archive $FF_C_MERGE_FILES -Wl,--no-whole-archive"
# else
# 	FF_C_MERGE_COMMAND="$FF_C_MERGE_FILES"
# fi

# $CC -lm -lz -shared --sysroot=$FF_SYSROOT -Wl,--no-undefined -Wl,-z,noexecstack \
#     -Wl,-soname,libevoffmpeg.so \
# 	$FF_C_MERGE_COMMAND \
#   $FF_CFLAGS \
#   $FF_EXTRA_CFLAGS \
#   $FF_EXTRA_LDFLAGS \
#   $FF_EXTRA_CXXLDFLAGS \
#   $FF_EXTRA_LIBS \
# 	-fvisibility=hidden \
# 	-fvisibility-inlines-hidden \
# 	-rdynamic \
# 	-O3 \
# 	-Wl,-s	\
# 	-Wl,-E \
#     -o $FF_PREFIX/libevoffmpeg.so
	
# rm -f $FF_PREFIX/*.a
# rm -f $FF_PREFIX/*.o

# cd $CURRETN_PATH

$CC -Xlinker -zmuldefs -lm -lz -fPIC -shared --sysroot=$FF_SYSROOT \
   -Wl,--no-undefined -Wl,-z,noexecstack \
   -Wl,-soname,libevoffmpeg.so \
   $FF_C_OBJ_FILES \
   $FF_ASM_OBJ_FILES \
   $FF_CFLAGS \
   $FF_EXTRA_CFLAGS \
   $FF_EXTRA_LDFLAGS \
   $FF_EXTRA_CXXLDFLAGS \
   $FF_EXTRA_LIBS \
   -o $FF_PREFIX/libevoffmpeg.so

echo ""
echo "--------------------"
echo "[*] link ffmpeg resource"
echo "--------------------"
   
mysedi() {
    f=$1
    exp=$2
    n=`basename $f`
    cp $f /tmp/$n
    sed $exp /tmp/$n > $f
    rm /tmp/$n
}

echo ""
echo "--------------------"
echo "[*] create files for shared ffmpeg"
echo "--------------------"
rm -rf $FF_PREFIX/shared
mkdir -p $FF_PREFIX/shared/lib/pkgconfig
ln -s $FF_PREFIX/include $FF_PREFIX/shared/include
ln -s $FF_PREFIX/libevoffmpeg.so $FF_PREFIX/shared/lib/libevoffmpeg.so
cp $FF_PREFIX/lib/pkgconfig/*.pc $FF_PREFIX/shared/lib/pkgconfig
for f in $FF_PREFIX/lib/pkgconfig/*.pc; do
    # in case empty dir
    if [ ! -f $f ]; then
        continue
    fi
    cp $f $FF_PREFIX/shared/lib/pkgconfig
    f=$FF_PREFIX/shared/lib/pkgconfig/`basename $f`
    # OSX sed doesn't have in-place(-i)
    mysedi $f 's/\/output/\/output\/shared/g'
    mysedi $f 's/-lavcodec/-lijkffmpeg/g'
    mysedi $f 's/-lavfilter/-lijkffmpeg/g'
    mysedi $f 's/-lavformat/-lijkffmpeg/g'
    mysedi $f 's/-lavutil/-lijkffmpeg/g'
    mysedi $f 's/-lswresample/-lijkffmpeg/g'
    mysedi $f 's/-lswscale/-lijkffmpeg/g'
done
