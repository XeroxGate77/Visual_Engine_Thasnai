"""Builds C.D. Studio (studio.html) by embedding CD.md into studio.template.html.
CD.md stays the single source of truth; run this after every edit of CD.md.
    python3 cd-kit/build_studio.py
"""
from pathlib import Path

here = Path(__file__).parent
kit = (here / "CD.md").read_text(encoding="utf-8")
assert "</script" not in kit.lower(), "CD.md must not contain </script>"
tpl = (here / "studio.template.html").read_text(encoding="utf-8")
assert tpl.count("/*KIT*/") == 1
out = tpl.replace("/*KIT*/", "\n" + kit)
(here / "studio.html").write_text(out, encoding="utf-8")
print("studio.html built:", len(out), "bytes")
