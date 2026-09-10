#!/bin/zsh
set -euo pipefail

root=${0:A:h}
bin_dir="$HOME/.local/bin"
share_dir="$HOME/.local/share/lid-sleep"

mkdir -p "$bin_dir" "$share_dir"
install -m 755 "$root/bin/lid-sleep" "$bin_dir/lid-sleep"
install -m 644 "$root/src/LidSleepBar.swift" "$share_dir/LidSleepBar.swift"

if [[ ":$PATH:" != *":$bin_dir:"* ]]; then
  print -r -- "提示：$bin_dir 不在 PATH 里。zsh 用户可在 ~/.zshrc 加上："
  print -r -- "  export PATH=\"\$HOME/.local/bin:\$PATH\""
fi

"$bin_dir/lid-sleep" make-app
print -r -- "接下来如需免密开关，运行：lid-sleep install"
print -r -- "然后打开：open \"\$HOME/Applications/合盖不睡.app\""
