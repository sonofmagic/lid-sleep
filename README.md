# 合盖不睡（lid-sleep）

macOS 菜单栏工具：开关 `pmset disablesleep`，合盖后电脑继续运行，方便 EasyTier / SSH 远程控制。

- 菜单栏图标：杯子 = 合盖不睡，月亮 = 合盖会休眠
- 终端命令：`lid-sleep on|off|toggle|status`
- 免密范围只有两条：`pmset disablesleep 0` 和 `pmset disablesleep 1`

`caffeinate`、KeepingYouAwake 只能挡住空闲休眠，挡不住合盖休眠。这个工具改的是内核 `SleepDisabled` 标志。

## 要求

- macOS 14+，Apple Silicon
- 编译菜单栏 App 需要 `swiftc`（Xcode 或 Command Line Tools）
- 改电源设置需要管理员密码（只授权一次）

## 安装

```bash
git clone git@github.com:sonofmagic/lid-sleep.git
cd lid-sleep
./install.sh
lid-sleep install          # 一次性授权免密
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
```

电池供电时，`on` 默认拒绝，需加 `--force`。走电池合盖不睡会发热、耗电，不要把电脑放进包里。

退出菜单栏 App **不会**改休眠设置。

## 布局

```
bin/lid-sleep           # zsh CLI
src/LidSleepBar.swift   # 菜单栏 App
install.sh              # 安装到 ~/.local/bin 并编译 App
```

安装后：

- CLI：`~/.local/bin/lid-sleep`
- 源码副本：`~/.local/share/lid-sleep/LidSleepBar.swift`
- App：`~/Applications/合盖不睡.app`
