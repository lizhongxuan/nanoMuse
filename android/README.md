# Morde 手机原生客户端

本目录只交付 Morde 原生客户端。Android 默认 Gradle 工程只包含 `:morde`；iOS 只有 `Morde.xcodeproj`。原 nanoMuse/OpenMinis 源文件留作本地二开参考，不进入这两个应用目标，也不会启动原本地 Agent、Cloud 或 Hub。

功能：在应用内用 Morde 账号密码登录，服务端自动登记安装；Keystore/Keychain 只保存 Client 凭证，安装 ID 用作非秘密的同账号续期标识。客户端访问同一套 Host/Workspace/Conversation/Task/通知接口，并用一次性 Host ticket 打开受控 Gateway 画面。原生客户端不执行本地 Workspace 同步，也不领取桌面用户 Web 会话。

构建要求见 [BUILDING.md](BUILDING.md)。Android 和 iOS 原生包携带上游 GPL、NOTICE、第三方清单及 Morde 专项依赖清单；桌面包另带 `morde-sync` Go 依赖声明。`morde-sync` 采用 GPL-3.0-or-later，所有平台仍须完成签名和原生验收后才能作为正式发行。
