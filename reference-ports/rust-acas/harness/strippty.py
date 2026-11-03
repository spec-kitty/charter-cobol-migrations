import re, sys
raw = open(sys.argv[1],'rb').read()
txt = re.sub(rb"\x1b\[[0-9;?]*[A-Za-z@]", b" ", raw)
txt = re.sub(rb"\x1b[B()=>][0-9A-Za-z]?", b" ", txt)
txt = re.sub(rb"[ \x00]+", b" ", txt)
s = txt.decode("utf-8","replace")
print("len:", len(s))
for anchor in ["SYS002","ACAS System Menu","Sales Ledger","Term-Id","Posting","Invoice","Batch","Extract","SL002","SL121","SL122"]:
    i = s.find(anchor)
    print(f"{anchor:22s}: @{i}" if i>=0 else f"{anchor:22s}: none")
print("---- last 1200 ----")
print(s[-1200:])
