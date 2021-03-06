#! /bin/bash
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

FF_BUILD_NAME=
FF_SOURCE=
FF_CROSS_PREFIX=
FF_DEP_OPENSSL_INC=
FF_DEP_OPENSSL_LIB=

FF_DEP_LIBSOXR_INC=
FF_DEP_LIBSOXR_LIB=

FF_CFG_FLAGS=

FF_EXTRA_CFLAGS=
FF_EXTRA_LDFLAGS=
FF_DEP_LIBS=

FF_MODULE_DIRS="compat libavcodec libavfilter libavformat libavutil libswresample libswscale"
FF_ASSEMBLER_SUB_DIRS=


#--------------------
echo ""
echo "--------------------"
echo "[*] make NDK standalone toolchain"
echo "--------------------"
. ./tools/do-detect-env-win.sh

FF_MAKE_FLAGS=$IJK_MAKE_FLAG
FF_GCC_VER=$IJK_GCC_VER
FF_GCC_64_VER=$IJK_GCC_64_VER

if [ "$FF_ARCH" = "x86" ]; then
    FF_BUILD_NAME=ffmpeg-x86
    FF_BUILD_NAME_OPENSSL=openssl-x86
    FF_BUILD_NAME_LIBSOXR=libsoxr-x86
    FF_SOURCE=$FF_BUILD_ROOT/$FF_BUILD_NAME
	
    FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-yasm"

    FF_EXTRA_CFLAGS="$FF_EXTRA_CFLAGS"

    FF_EXTRA_LDFLAGS="$FF_EXTRA_LDFLAGS -lmsvcrt"

    FF_ASSEMBLER_SUB_DIRS="x86"

elif [ "$FF_ARCH" = "x86_64" ]; then
    FF_ANDROID_PLATFORM=android-21

    FF_BUILD_NAME=ffmpeg-x86_64
    FF_BUILD_NAME_OPENSSL=openssl-x86_64
    FF_BUILD_NAME_LIBSOXR=libsoxr-x86_64
    FF_SOURCE=$FF_BUILD_ROOT/$FF_BUILD_NAME

    FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-yasm"

    FF_EXTRA_CFLAGS="$FF_EXTRA_CFLAGS"
    FF_EXTRA_LDFLAGS="$FF_EXTRA_LDFLAGS -lmsvcrt"

    FF_ASSEMBLER_SUB_DIRS="x86"
fi

if [ ! -d $FF_SOURCE ]; then
    echo ""
    echo "!! ERROR"
    echo "!! Can not find FFmpeg directory for $FF_BUILD_NAME"
    echo "!! Run 'sh init-android.sh' first"
    echo ""
    exit 1
fi

FF_PREFIX=$FF_BUILD_ROOT/build/$FF_BUILD_NAME/output
FF_DEP_OPENSSL_INC=$FF_BUILD_ROOT/build/$FF_BUILD_NAME_OPENSSL/output/include
FF_DEP_OPENSSL_LIB=$FF_BUILD_ROOT/build/$FF_BUILD_NAME_OPENSSL/output/lib
FF_DEP_LIBSOXR_INC=$FF_BUILD_ROOT/build/$FF_BUILD_NAME_LIBSOXR/output/include
FF_DEP_LIBSOXR_LIB=$FF_BUILD_ROOT/build/$FF_BUILD_NAME_LIBSOXR/output/lib


mkdir -p $FF_PREFIX

#--------------------
echo ""
echo "--------------------"
echo "[*] check ffmpeg env"
echo "--------------------"

FF_CFLAGS="-std=c99 \
    -DANDROID -DNDEBUG"	
	
#FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-cross-compile"
FF_CFG_FLAGS="$FF_CFG_FLAGS --toolchain=msvc"
FF_CFG_FLAGS="$FF_CFG_FLAGS --disable-htmlpages --disable-manpages --disable-txtpages --disable-podpages --disable-doc "
# cause av_strlcpy crash with gcc4.7, gcc4.8
# -fmodulo-sched -fmodulo-sched-allow-regmoves

# --enable-thumb is OK
#FF_CFLAGS="$FF_CFLAGS -mthumb"

# not necessary
#FF_CFLAGS="$FF_CFLAGS -finline-limit=300"

export COMMON_FF_CFG_FLAGS=
#. ./config/module.sh
COMMON_FF_CFG_FLAGS=`./config/module.sh`

#--------------------
# with openssl
if [ -f "${FF_DEP_OPENSSL_LIB}/libssl.a" ]; then
    echo "OpenSSL detected"
# FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-nonfree"
    FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-openssl"

    FF_CFLAGS="$FF_CFLAGS -I${FF_DEP_OPENSSL_INC}"
    FF_DEP_LIBS="$FF_DEP_LIBS -L${FF_DEP_OPENSSL_LIB} -lssl -lcrypto"
fi

if [ -f "${FF_DEP_LIBSOXR_LIB}/libsoxr.a" ]; then
    echo "libsoxr detected"
    FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-libsoxr"

    FF_CFLAGS="$FF_CFLAGS -I${FF_DEP_LIBSOXR_INC}"
    FF_DEP_LIBS="$FF_DEP_LIBS -L${FF_DEP_LIBSOXR_LIB} -lsoxr"
fi

FF_CFG_FLAGS="$FF_CFG_FLAGS $COMMON_FF_CFG_FLAGS"

#--------------------
# Standard options:
FF_CFG_FLAGS="$FF_CFG_FLAGS --prefix=$FF_PREFIX"

# Advanced options (experts only):
FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-pic"
# FF_CFG_FLAGS="$FF_CFG_FLAGS --disable-symver"

if [ "$FF_ARCH" = "x86" ]; then
    FF_CFG_FLAGS="$FF_CFG_FLAGS --disable-asm"
elif [ "$FF_ARCH" = "x86_64" ]; then
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
    ;;
    *)
        FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-optimizations"
        FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-debug"
        FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-small"
    ;;
esac

#--------------------
echo ""
echo "--------------------"
echo "[*] configurate ffmpeg"
echo "--------------------"
cd $FF_SOURCE

if [ -f "./config.h" ]; then
    echo 'reuse configure'
else
    #which $CC
	./configure --help > ../configure.txt
    ./configure $FF_CFG_FLAGS \
        --extra-cflags="$FF_CFLAGS $FF_EXTRA_CFLAGS" \
        --extra-ldflags="$FF_DEP_LIBS $FF_EXTRA_LDFLAGS"
    make clean
fi

#--------------------
echo ""
echo "--------------------"
echo "[*] compile ffmpeg"
echo "--------------------"
cp config.* $FF_PREFIX
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

CC=gcc
CXX=g++
AS=gcc
LD=gcc

FF_MERGE_O_A=1
FF_C_OBJ_FILES=
FF_ASM_OBJ_FILES=
FF_C_MERGE_FILES=
for MODULE_DIR in $FF_MODULE_DIRS
do
    C_OBJ_FILES="$MODULE_DIR/*.o"
    if ls $C_OBJ_FILES 1> /dev/null 2>&1; then
		echo "link $MODULE_DIR/*.o"
		FF_C_OBJ_FILES="$FF_C_OBJ_FILES $C_OBJ_FILES"
		
		# if [ $FF_MERGE_O_A == 1 ]; then
			# $AR rcs $FF_PREFIX/lib${MODULE_DIR}.a $C_OBJ_FILES
			# FF_C_MERGE_FILES="$FF_C_MERGE_FILES lib${MODULE_DIR}.a"
		# else
			# $LD -r $C_OBJ_FILES -o $FF_PREFIX/lib${MODULE_DIR}.o
			# FF_C_MERGE_FILES="$FF_C_MERGE_FILES $FF_PREFIX/lib${MODULE_DIR}.o"
		# fi
    fi
	
    for ASM_SUB_DIR in $FF_ASSEMBLER_SUB_DIRS
    do
        ASM_OBJ_FILES="$MODULE_DIR/$ASM_SUB_DIR/*.o"
        if ls $ASM_OBJ_FILES 1> /dev/null 2>&1; then
			echo "link $MODULE_DIR/$ASM_SUB_DIR/*.o"
			FF_ASM_OBJ_FILES="$FF_ASM_OBJ_FILES $ASM_OBJ_FILES"
			
			# if [ $FF_MERGE_O_A == 1 ]; then
				# $AR rcs $FF_PREFIX/lib${MODULE_DIR}_${ASM_SUB_DIR}.a $ASM_OBJ_FILES
				# FF_C_MERGE_FILES="$FF_C_MERGE_FILES lib${MODULE_DIR}_${ASM_SUB_DIR}.a"
			# else
				# $LD -r $ASM_OBJ_FILES -o $FF_PREFIX/lib${MODULE_DIR}_${ASM_SUB_DIR}.o
				# FF_C_MERGE_FILES="$FF_C_MERGE_FILES $FF_PREFIX/lib${MODULE_DIR}_${ASM_SUB_DIR}.o"
			# fi
        fi
    done
done

# CURRETN_PATH=$(pwd)
# cd $FF_PREFIX
# FF_C_MERGE_COMMAND=
# if [ $FF_MERGE_O_A == 1 ]; then
	# FF_C_MERGE_COMMAND="-Wl,--whole-archive $FF_C_MERGE_FILES -Wl,--no-whole-archive"
# else
	# FF_C_MERGE_COMMAND="$FF_C_MERGE_FILES"
# fi

# $CC -lm -lz -shared --sysroot=$FF_SYSROOT -Wl,--no-undefined -Wl,-z,noexecstack $FF_EXTRA_LDFLAGS \
    # -Wl,-soname,libijkffmpeg.so \
	# $FF_C_MERGE_COMMAND \
    # $FF_DEP_LIBS \
	# -fvisibility=hidden \
	# -fvisibility-inlines-hidden \
	# -rdynamic \
	# -O3 \
	# -Wl,-s	\
	# -Wl,-E \
    # -o $FF_PREFIX/libijkffmpeg.so
	
# if [ $FF_MERGE_O_A == 1 ]; then
	# rm -f $FF_PREFIX/*.a
# else
	# rm -f $FF_PREFIX/*.o
# fi

# cd $CURRETN_PATH

$CC -shared -Wl,--no-undefined $FF_EXTRA_LDFLAGS \
   -Wl,-soname,libijkffmpeg.so \
   $FF_C_OBJ_FILES \
   $FF_ASM_OBJ_FILES \
   $FF_DEP_LIBS \
   -o $FF_PREFIX/libijkffmpeg.so
	
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
ln -s $FF_PREFIX/libijkffmpeg.so $FF_PREFIX/shared/lib/libijkffmpeg.so
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
