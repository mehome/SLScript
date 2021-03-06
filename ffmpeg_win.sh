#!/bin/sh

#vs2015��������
export DEVENV="devenv.exe"
function makedir()
{
	p=$1
	if [ ! -d $p ]
	then
		mkdir $p
	fi
}

export ROOT=$(pwd)
makedir bin
export OUTPUT=$ROOT/bin

EXTERA=extra
echo '::'$EXTERA
makedir $EXTERA

echo "::download ffmepeg"
cd $EXTERA
WGET_NAME=ffmpeg-2.7.7
#ffmpeg-3.3.3

if [ ! -f ${WGET_NAME}.tar.gz ]
then
	echo
	wget https://ffmpeg.org/releases/${WGET_NAME}.tar.gz
	rm -r -f ${WGET_NAME}
fi
if [ ! -d ${WGET_NAME} ];then
	tar -xzf ${WGET_NAME}.tar.gz
fi

cd ${WGET_NAME}
SOURCE=$(pwd)
echo ${SOURCE}

echo "::configure ffmepeg"

EXTRA_PATH=../../bin
EXTRA_PATH_ABS=$(pwd)/../../bin
EXTRA_CFLAGS="-fPIC -DANDROID "
EXTRA_LDFLAGS=""
EXTRA_LIBS=""
EXTRA_CONFIGURE=""

ARCH=x86
# ARCH=x86_64

NOCROSS=1
CONFIGURE=1
BUILD=1

FF_ARCH=$1
if [ ! $FF_ARCH == '' ];then
	ARCH=$FF_ARCH
	echo 'ARCH:'$ARCH
fi

DEBUG=1
QUICK=1
OS="WINDOWS"
MSVC=false
PREFIX=

if [ $ARCH == "x86_64" ];then
	PREFIX=${ROOT}/bin/ffmpeg_64/
else
	PREFIX=${ROOT}/bin/ffmpeg/
fi

if [ $ARCH == "x86_64" ];then
	EXTRA_CONFIGURE="$EXTRA_CONFIGURE --arch=x86_64"
else
	EXTRA_CONFIGURE="$EXTRA_CONFIGURE --arch=i686"
fi
if [ $NOCROSS == 1 ];then
	EXTRA_CONFIGURE="$EXTRA_CONFIGURE"
	EXTRA_CONFIGURE="$EXTRA_CONFIGURE --toolchain=msvc"
	MSVC=true
elif [[ $(uname) == MINGW* ]];then
	echo $(uname)
	EXTRA_CFLAGS="$EXTRA_CFLAGS -I/mingw/include -I/include -I/usr/include -I/usr/local/include"
	EXTRA_LDFLAGS="$EXTRA_LDFLAGS -L/mingw/lib -L/lib -L/usr/lib -L/usr/local/lib"
	EXTRA_LDFLAGS="${EXTRA_LDFLAGS} -lmingwex -lmsvcrt -lgcc -lgcc_s"
	EXTRA_CONFIGURE="${EXTRA_CONFIGURE} --enable-cross-compile"
	EXTRA_CONFIGURE="$EXTRA_CONFIGURE --target-os=mingw32"
elif [[ $(uname) == CYGWIN* ]];then
	echo $(uname)
	EXTRA_CONFIGURE="${EXTRA_CONFIGURE} --enable-cross-compile"
	EXTRA_CONFIGURE="$EXTRA_CONFIGURE --target-os=cygwin"
	if [ $ARCH == "x86_64" ];then
		# EXTRA_CONFIGURE="$EXTRA_CONFIGURE --cross-prefix=/usr/x86_64-w64-mingw32/bin/"
		PATH=/usr/x86_64-w64-mingw32/bin/:$PATH
	else
		# EXTRA_CONFIGURE="$EXTRA_CONFIGURE --cross-prefix=/usr/i686-w64-mingw32/bin/"
		PATH=/usr/i686-w64-mingw32/bin/:$PATH
	fi
fi

PATH=$PATH:${EXTRA_PATH_ABS}

if [ $DEBUG == 1 ];then
	echo "DEBUG"
	EXTRA_CONFIGURE="${EXTRA_CONFIGURE} --enable-debug"
	EXTRA_CONFIGURE="${EXTRA_CONFIGURE} --disable-memalign-hack"
	EXTRA_CONFIGURE="${EXTRA_CONFIGURE} --disable-stripping"
	EXTRA_CONFIGURE="${EXTRA_CONFIGURE} --disable-asm"
	if [ $MSVC == true ];then
		EXTRA_CFLAGS="$EXTRA_CFLAGS -Zi -Od"
		EXTRA_CFLAGS="$EXTRA_CFLAGS -MDd"
		EXTRA_LDFLAGS="$EXTRA_LDFLAGS -DEBUG -VERBOSE"
		# EXTRA_CONFIGURE="${EXTRA_CONFIGURE} --disable-optimizations"
	else
		EXTRA_LDFLAGS="$EXTRA_LDFLAGS -lmsvcrt"
		EXTRA_CFLAGS="$EXTRA_CFLAGS -g -O0"
		EXTRA_LDFLAGS="$EXTRA_LDFLAGS -g -O0"
		EXTRA_CONFIGURE="${EXTRA_CONFIGURE} --disable-optimizations"
	fi
else
	EXTRA_CONFIGURE="${EXTRA_CONFIGURE} --disable-debug"
	EXTRA_CONFIGURE="${EXTRA_CONFIGURE} --enable-optimizations"
	EXTRA_CONFIGURE="${EXTRA_CONFIGURE} --enable-stripping"
	EXTRA_CONFIGURE="${EXTRA_CONFIGURE} --enable-asm"
	EXTRA_CONFIGURE="${EXTRA_CONFIGURE} --enable-small"
fi
if [ $QUICK == 1 ];then
	EXTRA_CONFIGURE="${EXTRA_CONFIGURE} --disable-ffmpeg"
	EXTRA_CONFIGURE="${EXTRA_CONFIGURE} --disable-ffplay"
	EXTRA_CONFIGURE="${EXTRA_CONFIGURE} --disable-ffprobe"
	EXTRA_CONFIGURE="${EXTRA_CONFIGURE} --disable-ffserver"
	EXTRA_CONFIGURE="${EXTRA_CONFIGURE} --disable-doc"
	EXTRA_CONFIGURE="${EXTRA_CONFIGURE} --disable-symver"
fi

EXTRA_CONFIGURE="${EXTRA_CONFIGURE} --disable-memalign-hack"

if [ ${OS} == "WINDOWS" ];then
	EXTRA_CONFIGURE="${EXTRA_CONFIGURE} --enable-d3d11va"
	EXTRA_CONFIGURE="${EXTRA_CONFIGURE} --enable-dxva2"
fi

# EXTRA_CONFIGURE="${EXTRA_CONFIGURE} --enable-libopenjpeg"
EXTRA_CONFIGURE="${EXTRA_CONFIGURE} --enable-libx264"
EXTRA_CONFIGURE="${EXTRA_CONFIGURE} --enable-libopenh264"

EXTRA_CONFIGURE="${EXTRA_CONFIGURE} --enable-decoder=png"
#EXTRA_CONFIGURE="${EXTRA_CONFIGURE} --enable-decoder=libopenjpeg"
EXTRA_CONFIGURE="${EXTRA_CONFIGURE} --enable-decoder=h264"
#EXTRA_CONFIGURE="${EXTRA_CONFIGURE} --enable-decoder=libx264"
#EXTRA_CONFIGURE="${EXTRA_CONFIGURE} --enable-decoder=libx264rgb"
EXTRA_CONFIGURE="${EXTRA_CONFIGURE} --enable-encoder=libx264"
EXTRA_CONFIGURE="${EXTRA_CONFIGURE} --enable-encoder=libx264rgb"
EXTRA_CONFIGURE="${EXTRA_CONFIGURE} --enable-encoder=libopenh264"

LIBJPEG=
LIBJPEG_ABS=
if [ $ARCH == "x86_64" ];then
	LIBJPEG=${EXTRA_PATH}/libjpeg/x64
	LIBJPEG_ABS=${EXTRA_PATH_ABS}/libjpeg/x64
else
	LIBJPEG=${EXTRA_PATH}/libjpeg
	LIBJPEG_ABS=${EXTRA_PATH_ABS}/libjpeg
fi
EXTRA_CFLAGS="${EXTRA_CFLAGS} -I${EXTRA_PATH}/libjpeg/include"
EXTRA_LDFLAGS="${EXTRA_LDFLAGS} -L${LIBJPEG}/Release"
if [ $MSVC == true ];then
	EXTRA_LDFLAGS="${EXTRA_LDFLAGS} -libpath:${LIBJPEG_ABS}/Release"
fi


OPENJPEG=
OPENJPEG_ABS=
if [ $ARCH == "x86_64" ];then
	OPENJPEG=${EXTRA_PATH}/openjpeg_x64
	OPENJPEG_ABS=${EXTRA_PATH_ABS}/openjpeg_x64
else
	OPENJPEG=${EXTRA_PATH}/openjpeg_x86
	OPENJPEG_ABS=${EXTRA_PATH_ABS}/openjpeg_x86
fi
EXTRA_LDFLAGS="${EXTRA_LDFLAGS} -L${OPENJPEG}/lib"
if [ $MSVC == true ];then
	EXTRA_LDFLAGS="${EXTRA_LDFLAGS} -libpath:${OPENJPEG}/lib"
fi
EXTRA_CFLAGS="${EXTRA_CFLAGS} -I${OPENJPEG}/include/openjpeg-2.2"
PKG_CONFIG_PATH="${PKG_CONFIG_PATH}:${OPENJPEG_ABS}/lib/pkgconfig"
if [ ${OS} == 'WINDOWS' ];then
	# cp -f ${OPENJPEG}/lib/openjp2.lib ${OPENJPEG}/lib/openjpeg.lib
	cp -f ${OPENJPEG}/lib/libopenjp2.a ${OPENJPEG}/lib/openjpeg.lib
	PATH=$PATH:${OPENJPEG}/bin/
	EXTRA_CFLAGS="${EXTRA_CFLAGS} -D_WIN32 -DOPJ_EXPORTS"
	EXTRA_LDFLAGS="${EXTRA_LDFLAGS} -D_WIN32 -DOPJ_EXPORTS"
fi

X264=${EXTRA_PATH}/x264
X264_ABS=${EXTRA_PATH_ABS}/x264
if [ $ARCH == "x86_64" ];then
	X264=${EXTRA_PATH}/x264_64
	X264_ABS=${EXTRA_PATH_ABS}/x264_64
else
	X264=${EXTRA_PATH}/x264
	X264_ABS=${EXTRA_PATH_ABS}/x264
fi
EXTRA_CFLAGS="${EXTRA_CFLAGS} -I${X264}/include"
EXTRA_LDFLAGS="${EXTRA_LDFLAGS} -L${X264}/lib -L${X264_ABS}/lib"
PKG_CONFIG_PATH="${PKG_CONFIG_PATH}:${X264_ABS}/lib/pkgconfig"
PKG_CONFIG_PATH="${PKG_CONFIG_PATH}:${X264}/lib/pkgconfig"
if [ $MSVC == true ];then
	EXTRA_LDFLAGS="${EXTRA_LDFLAGS} -libpath:${X264}/lib"
fi
if [ ${OS} == 'WINDOWS' ];then
	cp -f "${X264}/lib/libx264.a" "${X264}/lib/x264.lib"
	cp -f "${X264}/lib/libx264.dll.a" "${X264}/lib/x264.dll.lib"
	cp -f "${X264}/lib/libx264.dll.a" "${X264}/lib/x264.lib"
	PATH=$PATH:${X264}/bin/
fi

OPENH264=
OPENH264_ABS=
if [ $ARCH == "x86_64" ];then
	OPENH264=${EXTRA_PATH}/openh264_64
	OPENH264_ABS=${EXTRA_PATH_ABS}/openh264_64
else
	OPENH264=${EXTRA_PATH}/openh264_32
	OPENH264_ABS=${EXTRA_PATH_ABS}/openh264_32
fi
EXTRA_CFLAGS="${EXTRA_CFLAGS} -I${OPENH264}/include"
EXTRA_LDFLAGS="${EXTRA_LDFLAGS} -L${OPENH264}/lib -L${OPENH264_ABS}/lib"
PKG_CONFIG_PATH="${PKG_CONFIG_PATH}:${OPENH264_ABS}/lib/pkgconfig"
PKG_CONFIG_PATH="${PKG_CONFIG_PATH}:${OPENH264}/lib/pkgconfig"
if [ $MSVC == true ];then
	EXTRA_LDFLAGS="${EXTRA_LDFLAGS} -libpath:${OPENH264}/lib"
fi
if [ ${OS} == 'WINDOWS' ];then
	PATH=$PATH:${OPENH264}/bin/
fi

if [ ${OS} == 'WINDOWS' ];then
	EXTRA_CONFIGURE="${EXTRA_CONFIGURE} --enable-w32threads"
fi

if [ $ARCH == "x86_64" ];then
	EXTRA_CONFIGURE="$EXTRA_CONFIGURE --arch=x86_64 --host-os=win64"
fi

#C compiler test failed.
#remove cygwin's link.exe

if [ $CONFIGURE == 1 ];then
	export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH
	echo "::configure"
	if [ ! -f ../../bin/$WGET_NAME.txt ];then
		./configure --help > ../../bin/$WGET_NAME.txt
	fi
	./configure \
	--enable-gpl \
	--enable-nonfree \
	--disable-yasm \
	${EXTRA_CONFIGURE} \
	--extra-cflags="${EXTRA_CFLAGS}" \
	--extra-ldflags="${EXTRA_LDFLAGS}" \
	--extra-libs="${EXTRA_LIBS}" \
	--enable-shared \
	--enable-static \
	--logfile=${EXTRA_PATH}/ffmpeg_config.log \
	--prefix=${PREFIX}
fi

if [ $BUILD == 1 ];then
	echo "::make"
	make clean
	make -j4

	echo "::make install"
	make install
	echo "::make clean"
	# make clean
fi
