#!/bin/bash
# Build the GooglePlayStoreCrashFix Zygisk module zip.
set -euo pipefail
cd "$(dirname "$0")"

SDK=${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/Android/Sdk}}
JAVA_HOME=${JAVA_HOME:-$HOME/Android/jdk-17}

# Locate NDK
if [ -n "${ANDROID_NDK_HOME:-}" ] && [ -d "${ANDROID_NDK_HOME:-}" ]; then
    NDK="$ANDROID_NDK_HOME"
elif [ -n "${ANDROID_NDK_LATEST_HOME:-}" ] && [ -d "${ANDROID_NDK_LATEST_HOME:-}" ]; then
    NDK="$ANDROID_NDK_LATEST_HOME"
elif [ -d "$SDK/ndk" ]; then
    NDK=$(ls -d "$SDK"/ndk/* 2>/dev/null | sort -V | tail -1)
else
    echo "Error: Android NDK not found. Set ANDROID_NDK_HOME or install NDK in \$ANDROID_HOME/ndk." >&2
    exit 1
fi

# Locate build-tools
BT=$(ls -d "$SDK"/build-tools/* 2>/dev/null | sort -V | tail -1)
if [ -z "$BT" ]; then
    echo "Error: Android build-tools not found in $SDK/build-tools." >&2
    exit 1
fi

# Locate android.jar (platform 35 preferred, fallback to highest available)
if [ -f "$SDK/platforms/android-35/android.jar" ]; then
    ANDROID_JAR="$SDK/platforms/android-35/android.jar"
else
    ANDROID_JAR=$(ls -d "$SDK"/platforms/android-*/android.jar 2>/dev/null | sort -V | tail -1)
fi

if [ -z "$ANDROID_JAR" ]; then
    echo "Error: android.jar not found." >&2
    exit 1
fi

# Locate compilers
NDK_BIN="$NDK/toolchains/llvm/prebuilt/linux-x86_64/bin"
CC="$NDK_BIN/clang --target=aarch64-linux-android31"
CXX="$NDK_BIN/clang++ --target=aarch64-linux-android31"

OUT=build
rm -rf "$OUT" && mkdir -p "$OUT/classes" "$OUT/dex" "$OUT/zip/zygisk" "$OUT/obj"

echo "Compiling Java hooks..."
"$JAVA_HOME/bin/javac" --release 11 -cp "$ANDROID_JAR" -d "$OUT/classes" java/xiaomiplaystorefix/*.java
"$BT/d8" --release --min-api 31 --lib "$ANDROID_JAR" --output "$OUT/dex" $(find "$OUT/classes" -name '*.class')

echo "Compiling xz-embedded C objects..."
$CC -c -O2 -fPIC -DXZ_USE_CRC32 -I native/third_party/xz native/third_party/xz/xz_crc32.c -o "$OUT/obj/xz_crc32.o"
$CC -c -O2 -fPIC -DXZ_USE_CRC32 -I native/third_party/xz native/third_party/xz/xz_dec_stream.c -o "$OUT/obj/xz_dec_stream.o"
$CC -c -O2 -fPIC -DXZ_USE_CRC32 -I native/third_party/xz native/third_party/xz/xz_dec_lzma2.c -o "$OUT/obj/xz_dec_lzma2.o"
$CC -c -O2 -fPIC -DXZ_USE_CRC32 -I native/third_party/xz native/third_party/xz/xz_dec_bcj.c -o "$OUT/obj/xz_dec_bcj.o"

echo "Compiling native Zygisk library (C++)..."
$CXX -std=c++20 -O2 -fPIC -shared -fvisibility=hidden -fno-exceptions \
    -static-libstdc++ -Wl,--gc-sections -Wl,-z,max-page-size=16384 -s \
    -DXZ_USE_CRC32 \
    -I native/third_party/xz \
    -DLSPLANT_SO_PATH="\"$PWD/native/third_party/liblsplant.so\"" \
    -DCLASSES_DEX_PATH="\"$PWD/$OUT/dex/classes.dex\"" \
    native/main.cpp \
    native/third_party/And64InlineHook.cpp \
    "$OUT/obj/xz_crc32.o" \
    "$OUT/obj/xz_dec_stream.o" \
    "$OUT/obj/xz_dec_lzma2.o" \
    "$OUT/obj/xz_dec_bcj.o" \
    -llog -o "$OUT/zip/zygisk/arm64-v8a.so"

echo "Packaging module zip..."
cp module/module.prop module/customize.sh LICENSE THIRD_PARTY_NOTICES.md "$OUT/zip/"
mkdir -p "$OUT/zip/licenses"
cp native/third_party/LICENSE.* "$OUT/zip/licenses/"
mkdir -p "$OUT/zip/META-INF/com/google/android"
curl -fsSL -o "$OUT/zip/META-INF/com/google/android/update-binary" \
    https://raw.githubusercontent.com/topjohnwu/Magisk/master/scripts/module_installer.sh
echo "#MAGISK" > "$OUT/zip/META-INF/com/google/android/updater-script"

VER=$(sed -n 's/^version=//p' module/module.prop)
(cd "$OUT/zip" && rm -f "../GooglePlayStoreCrashFix-$VER.zip" && zip -qr9 "../GooglePlayStoreCrashFix-$VER.zip" .)
echo "Successfully built $OUT/GooglePlayStoreCrashFix-$VER.zip"
