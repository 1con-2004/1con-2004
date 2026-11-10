#!/usr/bin/env bash
# 把 poster.html 渲染成 assets/hero.png（2x）
# 用法： ./render.sh
set -euo pipefail
cd "$(dirname "$0")"

CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
OUT="assets/hero.png"

# 先问 Chrome 内容实际有多高，避免截出大片空白
H=$("$CHROME" --headless --disable-gpu --no-sandbox --virtual-time-budget=8000 \
      --dump-dom poster.html 2>/dev/null | grep -oE '<title>[0-9]+</title>' | grep -oE '[0-9]+' | head -1)
H=${H:-1200}
echo "内容高度: ${H}px"

mkdir -p assets
"$CHROME" --headless --disable-gpu --no-sandbox --hide-scrollbars \
  --force-device-scale-factor=2 --virtual-time-budget=8000 \
  --screenshot="$OUT" --window-size=1200,"$H" poster.html 2>/dev/null

python3 - "$OUT" <<'PY'
import sys
from PIL import Image
p = sys.argv[1]
im = Image.open(p)
print(f"输出: {p}  {im.size[0]}x{im.size[1]}  {im.size[0]//2}x{im.size[1]//2} CSS px")
PY

# GitHub 的 camo 图片代理按 URL 缓存，相对路径不含内容哈希 → 改图后必须破缓存
# 这里自动把 README 里的 hero.png?v=N 递增一位
python3 - <<'PY'
import re, pathlib
p = pathlib.Path("README.md")
s = p.read_text(encoding="utf-8")
new = re.sub(r"(hero\.png)\?v=(\d+)", lambda m: f"{m.group(1)}?v={int(m.group(2))+1}", s)
if new != s:
    p.write_text(new, encoding="utf-8")
    print("README 图片版本号已自动 +1（破除 camo 缓存）")
else:
    print("README 图片版本号未变化")
PY
