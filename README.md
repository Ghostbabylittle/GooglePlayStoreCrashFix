# Google Play Store Crash Fix (Android 15)

A lightweight Zygisk module designed to fix Google Play Store crashes, download pending/stuck issues, and high CPU usage on **Android 15** (tested on Xiaomi 15 Ultra / 15 Pro running HyperOS 2 / MIUI).

Supports **KernelSU**, **APatch**, and **Magisk**. No standalone Xposed/LSPosed app or framework required.

---

## The Problem
On Android 14 and 15, system apps can route network requests through the built-in Cronet library provided by the Tethering APEX (`/apex/com.android.tethering/lib64/libmainlinecronet.*.so`).

On certain device ROMs (especially Xiaomi HyperOS / MIUI builds), the ROM's bundled Cronet version encounters file descriptor ownership issues (`fdsan`) when handling network connections:

```text
Abort message: 'fdsan: attempted to close file descriptor 0, expected to be unowned, actually owned by FILE* ...'
  #03 /apex/com.android.tethering/lib64/libmainlinecronet.*.so
```

Because the Tethering APEX is signed by the ROM manufacturer, Google Play system updates cannot replace it. When Google Play Store attempts to use this system Cronet instance, it crashes randomly during browsing or app downloading.

---

## How This Fix Works
Inside Google Play Store (`com.android.vending`) processes only:
1. **Disabled Cronet Provider:** Intercepts `android.net.http.HttpEngine.Builder#build()` and disables `HttpEngineNativeProvider`.
2. **Fallback to OkHttp:** Forces Google Play Store to use its reliable internal OkHttp fallback stack.
3. **Android 15 Support:** Fully adapted for Android 15 ART runtime (supporting `.gnu_debugdata` symbol discovery and Android 15 JIT code cache changes).
4. **Zero System Alterations:** Does not touch or modify the `/system` partition. All hooks are injected strictly in-memory inside the Play Store process. Other apps remain completely untouched.

---

## Prerequisites
- **KernelSU** (with Zygisk module installed, e.g. Zygisk Next), **APatch** (with Zygisk Next), or **Magisk** (with Zygisk enabled in Settings).

---

## Installation
1. Download the latest `GooglePlayStoreCrashFix-*.zip` from [Releases](../../releases).
2. Open your root manager (KernelSU / APatch / Magisk).
3. Go to **Modules** → **Install from storage** and select the downloaded zip.
4. Reboot your device.

### Verification
Run `adb logcat -s XiaomiPlayStoreFix` while launching Google Play Store:
```text
XiaomiPlayStoreFix: pre-specialize: lsplant ready
XiaomiPlayStoreFix: Phase1: HttpEngine.Builder#build blocked (1)
XiaomiPlayStoreFix: hooks installed
XiaomiPlayStoreFix: Phase2: HttpEngineNativeProvider disabled (2 checks, 0 builders)
```

---

## Building from Source

### Requirements
- Linux or macOS (or WSL on Windows)
- JDK 17
- Android SDK (API 35, Build-Tools 35.0.0+)
- Android NDK (r27+)

### Build Command
```bash
export ANDROID_HOME=/path/to/android-sdk
export JAVA_HOME=/path/to/jdk-17
./build.sh
```
The compiled module zip will be generated in `build/GooglePlayStoreCrashFix-<version>.zip`.

---

## Credits
- [SongXiaoXi/VendingCronetOff](https://github.com/SongXiaoXi/VendingCronetOff) for the original Cronet bypass discovery.
- [leapdragon/XiaomiPlayStoreFix](https://github.com/leapdragon/XiaomiPlayStoreFix) for the original standalone Zygisk implementation.
- [LSPlant](https://github.com/LSPosed/LSPlant) for the runtime ART hooking engine.
- [And64InlineHook](https://github.com/Rprop/And64InlineHook) for ARM64 inline hooking.
- [xz-embedded](https://tukaani.org/xz/embedded.html) for embedded ELF debug symbol decompression.

---

## License
This project is licensed under the [MIT License](LICENSE). See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for third-party component licenses.
