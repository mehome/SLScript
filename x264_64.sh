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

echo "::download x264"
cd $EXTERA
git clone --depth 1 http://git.videolan.org/git/x264.git

cd x264
SOURCE=$(pwd)
cp -f $ROOT/patch/x264/extras/avisynth_c.h ./extras/avisynth_c.h

CONFIGRE=
if [[ $(uname) == MINGW* ]];then
  CONFIGRE="${CONFIGRE} --host=x86_64-w64-mingw32"
elif [[ $(uname) == CYGWIN* ]];then
	CONFIGRE="${CONFIGRE} --host=x86_64-w64-mingw32"
	CONFIGRE="${CONFIGRE} --cross-prefix=/usr/x86_64-w64-mingw32/bin/"
	CONFIGRE="${CONFIGRE} --sysroot=/usr/x86_64-w64-mingw32/sys-root/"
fi

echo "::configure"
./configure --help > ../../bin/x264.txt
./configure \
--enable-shared \
--enable-static \
--disable-asm \
--disable-pthread \
--enable-win32thread \
--extra-cflags="-Os -fpic" \
--extra-ldflags="-fpic" \
${CONFIGRE} \
--prefix=${ROOT}/bin/x264_64/

echo "::make"
make clean
make -j4

echo "::make install"
make install
echo "::make clean"
make clean
