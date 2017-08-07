
SDK_VERSION="8.3"
MIN_IOS_VERSION="8.2"
#ARCHS="i386 x86_64 armv7 arm64"
ARCHS="armv7 arm64"
#LIB_NAMES="libevent.a libevent_core.a libevent_extra.a libevent_openssl.a libevent_pthreads.a"
LIB_NAMES="libx264.a"




cd "`dirname \"$0\"`"          # 进入本文件所有的目录
OUTPUT_DIR="`pwd`/myout"       # 设置输出目录
mkdir -p ${OUTPUT_DIR}/include
mkdir -p ${OUTPUT_DIR}/lib

XCODE_DEVELOPER=`xcode-select -print-path`
#XCODE_DEVELOPER="/Applications/Xcode.app/Contents/Developer"

# 本段for语句用于交叉编译第三方库
# 执行完成后，将在./myout/iPhoneOSxx-armvx/include和./myout/iPhoneOSxx-armvx/lib中生成头文件和库
ORIGINAL_PATH=$PATH
for ARCH in ${ARCHS}; do
  if [ "${ARCH}" == "i386" ] || [ "${ARCH}" == "x86_64" ]; then
    PLATFORM="iPhoneSimulator"
    EXTRA_CONFIG=""
  else
    PLATFORM="iPhoneOS"
    EXTRA_CONFIG="--host=arm-apple-darwin14"
  fi
  export PATH="${XCODE_DEVELOPER}/Toolchains/XcodeDefault.xctoolchain/usr/bin:${XCODE_DEVELOPER}/Platforms/${PLATFORM}.platform/Developer/usr/bin:${XCODE_DEVELOPER}/usr/bin:${ORIGINAL_PATH}"
  SYS_ROOT=${XCODE_DEVELOPER}/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}${SDK_VERSION}.sdk

  # 本段代码可能需要根据不同的第三方库进行调整
  # 对于x264，它是使用是的--cross-prefix+gcc、--cross-prefix+ar等（而不是使用Makefile的${CC}等），
  # 我们不设置--cross-prefix，于是它会从${PATH}中查找gcc、ar等
  # --extra-cflags和--extra-ldflags都需要设置-arch ${ARCH}，即以指定arch编译和链接（生成x264可执行文件）
  ./configure --enable-static --disable-asm --sysroot=${SYS_ROOT} \
    ${EXTRA_CONFIG} \
    --extra-cflags="-arch ${ARCH} -miphoneos-version-min=${MIN_IOS_VERSION}" \
    --extra-ldflags="-arch ${ARCH} -miphoneos-version-min=${MIN_IOS_VERSION}" \
    --prefix="${OUTPUT_DIR}/${PLATFORM}${SDK_VERSION}-${ARCH}"

  make
  make install
  make clean
done

echo "Build library..."

# 本段for语句将各个architectures的库合并为一个，保存到./myout/lib，同时将include拷贝到./myout/include
NEED_COPE_INCLUDE=true
for LIB_NAME in ${LIB_NAMES}; do
  LIB_FULLNAMES=""
  for ARCH in ${ARCHS}; do
    if [ "${ARCH}" == "i386" ] || [ "${ARCH}" == "x86_64" ]; then
      PLATFORM="iPhoneSimulator"
    else
      PLATFORM="iPhoneOS"
    fi
    CURRENT_LIB="${OUTPUT_DIR}/${PLATFORM}${SDK_VERSION}-${ARCH}/lib/${LIB_NAME}"
    if [ -e $CURRENT_LIB ]; then
      LIB_FULLNAMES="${LIB_FULLNAMES} ${CURRENT_LIB}"
    fi

    # copy一次include目录
    if ${NEED_COPE_INCLUDE}; then
      cp -R ${OUTPUT_DIR}/${PLATFORM}${SDK_VERSION}-${ARCH}/include/* ${OUTPUT_DIR}/include/
      if [ $? == "0" ]; then
        NEED_COPE_INCLUDE=false
      fi
    fi
  done
  # 将多个architectures的库合并为一个
  if [ -n "$LIB_FULLNAMES"  ]; then
    lipo -create $LIB_FULLNAMES -output "${OUTPUT_DIR}/lib/${LIB_NAME}"
  else
    echo "$LIB_NAME does not exist, skipping"
  fi
done

echo "Done."

