# 构建 Morde 手机客户端

## Android

准备 JDK 17 或更新版本、Android SDK Platform 35，然后在仓库的 `android/src/android` 执行：

```sh
./gradlew :morde:assembleDebug
```

APK 位于 `morde/build/outputs/apk/debug/`。仅运行 `assembleDebug` 不需要设备；`installDebug` 才需要可运行的 Android 设备或模拟器。Gradle 默认工程名为 `Morde`，仅包含 `:morde`；构建不依赖原 `app` 的 iSH、proot、rclone 或本地 Agent。原生包将上游 GPL/NOTICE/第三方清单和 Morde Android 依赖清单放在 `assets/legal/`。

## iOS

准备完整 Xcode 和 iPhone 开发签名。在仓库的 `android` 目录执行：

```sh
xcodebuild -project src/ios/Morde.xcodeproj -scheme Morde \
  -configuration Debug -destination 'generic/platform=iOS' \
  CODE_SIGNING_ALLOWED=NO build
```

不签名构建无需开发团队；真机安装需在 Xcode 打开 `src/ios/Morde.xcodeproj` 并设置开发团队。该目标编译 `Morde/` 下的 Morde Swift 源文件，并将 GPL/NOTICE/第三方清单放入应用包；不链接原 Minis Agent 及其第三方本地运行时。

## 验收

将服务地址设为受信任的 HTTPS Morde Portal，在应用内输入账号密码登录即可自动授权安装。依次验证：跨端同一 Conversation/Task、超时重试幂等、任务审批版本冲突、SSE 中断恢复、通知、Host Gateway 票据、切后台回来、撤销凭证后的 401 清理。真机、签名和真实 Host 验证通过前，不把原生包视为可发行版本。
