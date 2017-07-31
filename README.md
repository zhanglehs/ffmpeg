libaacplus编译：
./configure --prefix=/f/ffmpeg_build/libaacplus-master/vs_out

libx264编译：
./configure --enable-static --enable-shared --prefix=vs_out

ffmpeg编译：
./configure --prefix=./vs2013_out --toolchain=msvc --enable-libaacplus --extra-cflags="-I../libaacplus-master/vs_out/include -I../x264-snapshot-20170706-2245-stable/vs_out/include" --enable-libx264 --disable-encoders --enable-encoder=libaacplus --enable-encoder=libx264 --disable-decoders --enable-decoder=aac --enable-decoder=h264 --enable-gpl --enable-nonfree