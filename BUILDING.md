# Building Notational Velocity on modern macOS

Last verified target: **macOS 26 (Tahoe), Xcode 16+**. The same instructions
should work on any macOS from Big Sur (11) onwards.

## Prerequisites

1. **Full Xcode** — Command Line Tools alone are not enough; the build links
   against AppKit / Quartz / PDFKit and uses Interface Builder resources from
   the project, both of which require a full Xcode install. Install from the
   App Store, then accept the license:

   ```sh
   sudo xcodebuild -license accept
   sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
   ```

2. **OpenSSL via Homebrew** — `NotationPrefs` / the password code pulls in
   OpenSSL headers. The project searches both Intel and Apple Silicon brew
   prefixes:

   ```sh
   brew install openssl@3
   ```

   The project already references `/usr/local/opt/openssl/include` and
   `/opt/homebrew/opt/openssl/include` — either install layout works.

## Build

Open `Notation.xcodeproj` in Xcode and build the `Notation` target, or from
the command line:

```sh
xcodebuild -project Notation.xcodeproj -target Notation \
           -configuration Deployment build
```

The built `Notational Velocity.app` lands in
`build/Deployment/Notational Velocity.app` (or `~/Applications` on `install`).

## Architecture: x86_64 only

The current build excludes `arm64` (`EXCLUDED_ARCHS[sdk=macosx*] = arm64`),
so the resulting binary is x86_64-only. On Apple Silicon it runs under
Rosetta 2. The reason: two bundled third-party frameworks ship without an
`arm64` slice:

```
$ file Sparkle.framework/Versions/A/Sparkle
... universal binary with 3 architectures: [ppc] [i386] [x86_64]

$ file AutoHyperlinks.framework/Versions/A/AutoHyperlinks
... universal binary with 3 architectures: [ppc_7400] [i386] [x86_64]
```

An `arm64` build would compile but fail at link time against these
frameworks.

## Optional: native Apple Silicon build

If you want a native `arm64` (or universal) build:

1. Replace `Sparkle.framework` with a modern build. Sparkle 1.27.x is the
   final 1.x release with an `arm64` slice and a compatible API; Sparkle 2.x
   has a different API and would require source changes.
   See https://github.com/sparkle-project/Sparkle/releases.

2. Replace `AutoHyperlinks.framework` with an `arm64`-capable build, or
   rebuild it from source. The original Adium project hosts current sources
   (https://hg.adium.im/adium/file/tip/Frameworks/Auto%20Hyperlinks%20Framework)
   though the framework can also be removed if the auto-hyperlinking feature
   is not needed.

3. After replacing both frameworks, in `Notation.xcodeproj/project.pbxproj`
   delete the six `"EXCLUDED_ARCHS[sdk=macosx*]" = arm64;` lines (or change
   them to an empty value).

4. Rebuild. `lipo -archs` on the resulting binary should now list both
   `x86_64` and `arm64`.

## What changed from the stock checkout

The original tree was last touched in 2021 and would not build on Xcode 16:

| Change | File(s) | Why |
|---|---|---|
| Cast `methodForSelector:` result to the real function-pointer type | `GlobalPrefs.m` | Modern clang refuses implicit `IMP` → typed-pointer conversion. |
| Store `IMP` directly and cast at call site | `LinkingEditor.h`, `LinkingEditor.m` | Same reason. The casts at the assignment site were also wrong-typed. |
| Drop `-whatsloaded` linker flag | `Notation.xcodeproj/project.pbxproj` | Removed from `ld64`; build fails outright. |
| Deployment target `10.5 / 10.9` → `10.13` | `Notation.xcodeproj/project.pbxproj` | 10.13 is the floor Xcode 16 still supports. |
| Drop `SDKROOT[arch=x86_64] = macosx10.5` | `Notation.xcodeproj/project.pbxproj` | The 10.5 SDK no longer ships. |
| `EXCLUDED_ARCHS[sdk=macosx*] = arm64` | `Notation.xcodeproj/project.pbxproj` | Bundled frameworks have no `arm64` slice (see above). |
| `LastUpgradeCheck = 1130 → 1620` | `Notation.xcodeproj/project.pbxproj` | Silences the Xcode "upgrade project settings" prompt. |

These changes correspond to the upstream open PR
[#399 "Maintenance - compile on macOs"](https://github.com/scrod/nv/pull/399),
with one deliberate divergence: PR #399 sets `EXCLUDED_ARCHS = x86_64`
(arm64-only), which cannot link against the bundled frameworks. This tree
sets `EXCLUDED_ARCHS = arm64` instead so the build links out of the box.
