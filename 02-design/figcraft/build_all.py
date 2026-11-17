#!/usr/bin/env python3
"""Build every Riayati screen set into ONE FigCraft document (light + dark rows for each set).

Sets: Auth (6), App (4), App / calendar + assistant (6).  Requires FigCraft with --control 7979.
Usage: python build_all.py             (everything, then saves riayati-app.figcraft)
       python build_all.py cal         (rebuild only the calendar + assistant rows after a full build)
"""
import glob
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import build_auth as A  # noqa: E402
import build_app as B  # noqa: E402
import build_cal as C  # noqa: E402

import build_reports as R  # noqa: E402

SETS = [("Auth", A.SCREENS), ("App", B.APP_SCREENS), ("App", C.CAL_SCREENS), ("App", R.REPORT_SCREENS)]


def main(only=None):
    if not A.fc.is_running():
        sys.exit("FigCraft is not running on 7979. Start: figcraft.exe --control 7979")
    for f in sorted(glob.glob(os.path.join(A.FONT_DIR, "*", "otf", "*.otf"))):
        A.ex("text.loadFont", path=f.replace("\\", "/"))
    page = A.ex("page.list")[0]["id"]
    A.ex("page.select", id=page)
    A.ex("page.setBackground", id=page, color="#E9EDE5")
    mine = [i for i in A.ex("node.find", type="FRAME", limit=2000)["ids"]
            if A.ex("node.get", id=i).get("name", "").startswith(("Auth /", "App /", "__probe"))]
    if mine:
        A.ex("edit.delete", ids=mine)
    A.setup_variables()
    os.makedirs(A.OUT, exist_ok=True)
    made, row = [], 0
    for idx, (group, screens) in enumerate(SETS):
        for mode in ("Light", "Dark"):
            B.build(group, screens, row, mode, made)
            row += 1
    A.fc.ex("file.saveAs", path=os.path.join(os.path.dirname(__file__), "riayati-app.figcraft"))
    print("saved; frames built:", len(made))


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else None)
