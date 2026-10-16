"""Decode QR images with an independent reader (zxing-cpp) and compare with the expected payload.
usage: python tests/qr_decode_check.py <expected-payload> <image> [<image> ...]"""
import sys
import zxingcpp
from PIL import Image
expected = sys.argv[1]
bad = 0
for path in sys.argv[2:]:
    img = Image.open(path).convert("RGB")
    found = [r.text for r in zxingcpp.read_barcodes(img)]
    small = [r.text for r in zxingcpp.read_barcodes(img.resize((img.width // 4, img.height // 4)))]  # phone-sized
    ok = expected in found and expected in small
    bad += not ok
    print(("ok  " if ok else "FAIL"), path.split("/")[-1], "| full:", "match" if expected in found else found, "| 1/4 size:", "match" if expected in small else small)
print("RESULT:", "PASS" if bad == 0 else "FAIL (%d)" % bad)
sys.exit(1 if bad else 0)
