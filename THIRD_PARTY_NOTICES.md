# Third-party components

The MIT license in `LICENSE` covers this project's own code (`native/main.cpp`, `java/`, `module/`, `build.sh`). The module zip also contains or is derived from:

| Component | Files | License |
|---|---|---|
| [XiaomiPlayStoreFix](https://github.com/leapdragon/XiaomiPlayStoreFix) | Original Zygisk Cronet bypass logic | MIT License |
| [LSPlant](https://github.com/LSPosed/LSPlant) 6.4 (`lsplant-standalone`) | `native/third_party/liblsplant.so`, `lsplant.hpp`; embedded in `zygisk/arm64-v8a.so` | LGPL-3.0 — `native/third_party/LICENSE.lsplant` (supplements GPL-3.0, `LICENSE.GPL-3.0`) |
| [xz-embedded](https://tukaani.org/xz/embedded.html) | `native/third_party/xz/*` | Public Domain |
| [And64InlineHook](https://github.com/Rprop/And64InlineHook) | `native/third_party/And64InlineHook.{cpp,hpp}` | MIT, Copyright (c) 2018 Rprop — `native/third_party/LICENSE.And64InlineHook` |
| [Magisk](https://github.com/topjohnwu/Magisk) Zygisk API header | `native/third_party/zygisk.hpp` | ISC-style, Copyright (c) 2022-2023 John "topjohnwu" Wu |
| Magisk module installer | `META-INF/com/google/android/update-binary` in the zip (fetched at build time) | Magisk repository |
