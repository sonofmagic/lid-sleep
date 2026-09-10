# 合盖不睡（lid-sleep）

macOS 菜单栏工具：开关 `pmset disablesleep`，合盖后电脑继续运行，方便 EasyTier / SSH 远程控制。

[![CI](https://github.com/sonofmagic/lid-sleep/actions/workflows/ci.yml/badge.svg)](https://github.com/sonofmagic/lid-sleep/actions/workflows/ci.yml)

- 菜单栏图标：杯子 = 合盖不睡，月亮 = 合盖会休眠
- 终端命令：`lid-sleep on|off|toggle|status`
- 免密范围只有两条：`pmset disablesleep 0` 和 `pmset disablesleep 1`
- 许可证：[MIT](LICENSE)

`caffeinate`、KeepingYouAwake 只能挡住空闲休眠，挡不住合盖休眠。这个工具改的是内核 `SleepDisabled` 标志。

## 要求

- macOS 14+
- 编译菜单栏 App 需要 `swiftc`（Xcode 或 Command Line Tools）
- 改电源设置需要管理员密码（只授权一次）

## 用 Homebrew 安装（推荐）

```bash
brew tap sonofmagic/lid-sleep
brew trust --tap sonofmagic/lid-sleep
brew install lid-sleep
lid-sleep make-app
open ~/Applications/合盖不睡.app
lid-sleep install    # 可选：免密开关，会写 /etc/sudoers.d/lid-sleep
```

Homebrew 安装 **不会** 自动改 sudoers，也不会把 App 写到 `/Applications`。菜单栏 App 由 `lid-sleep make-app` 编译到 `~/Applications`。

## 从源码安装

```bash
git clone https://github.com/sonofmagic/lid-sleep.git
cd lid-sleep
./install.sh
lid-sleep install
open ~/Applications/合盖不睡.app
```

菜单栏里可勾选「登录时打开」。

## 命令

```bash
lid-sleep status    # 查看
lid-sleep on        # 开启合盖不睡
lid-sleep off       # 恢复合盖休眠
lid-sleep toggle    # 切换
lid-sleep install   # 写入 /etc/sudoers.d/lid-sleep
lid-sleep uninstall # 撤销免密
lid-sleep make-app  # 重新编译菜单栏 App
lid-sleep --version
```

电池供电时，`on` 默认拒绝，需加 `--force`。走电池合盖不睡会发热、耗电，不要把电脑放进包里。

退出菜单栏 App **不会**改休眠设置。

## 布局

```
bin/lid-sleep           # zsh CLI
src/LidSleepBar.swift   # 菜单栏 App
install.sh              # 安装到 ~/.local/bin 并编译 App
```

菜单栏 App 会把 CLI 打进 `Contents/Resources/lid-sleep`，不依赖 `~/.local/bin`。

## 进入官方 Homebrew 还差什么

当前走的是第三方 tap `sonofmagic/lid-sleep`。官方 `homebrew/core` / `homebrew/cask` 还需要：

1. 仓库公开、MIT、稳定 tag（已做）
2. 仓库满 30 天
3. 有真实用户：约 75 star（自己提交约 225）
4. 若走 **cask**：加入 Apple Developer Program，用 Developer ID 签名并公证 GitHub Release 里的 `.app`
5. 安装过程不能自动写 `/etc/sudoers.d`（已经遵守）
6. 主产物若是 `.app`，应提交到 `homebrew/cask`，而不是 `homebrew/core`

未公证的 zip 只适合自己测试，不能进官方 cask。
