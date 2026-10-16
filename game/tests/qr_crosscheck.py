"""Compare QrEncoder output with the Python `qrcode` package (same version, level M, mask, byte mode)."""
import json, sys
import qrcode
from qrcode.util import QRData, MODE_8BIT_BYTE
cases = json.load(open(sys.argv[1]))
bad = 0
for c in cases:
    q = qrcode.QRCode(version=c["version"], error_correction=qrcode.constants.ERROR_CORRECT_M, mask_pattern=c["mask"], border=0)
    q.add_data(QRData(c["data"].encode(), mode=MODE_8BIT_BYTE))
    q.make(fit=False)
    ref = ["".join("1" if v else "0" for v in row) for row in q.get_matrix()]
    ok = ref == c["rows"]
    bad += not ok
    print(("ok  " if ok else "FAIL"), "v%d mask%d len%d" % (c["version"], c["mask"], len(c["data"])))
print("RESULT:", "PASS" if bad == 0 else "FAIL (%d)" % bad)
sys.exit(1 if bad else 0)
