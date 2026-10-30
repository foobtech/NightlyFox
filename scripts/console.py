#!/usr/bin/env python3
"""Render a terminal-looking SVG: build state + last lines of the build log."""
import argparse, html, re, time

ANSI = re.compile(r"\x1b\[[0-9;?]*[A-Za-z]")
STATES = {
    "starting":      ("STARTING", "#58a6ff", True),
    "bootstrapping": ("INSTALLING DEPENDENCIES", "#58a6ff", True),
    "compiling":     ("COMPILING", "#d29922", True),
    "packaging":     ("PACKAGING", "#a371f7", True),
    "success":       ("DONE", "#3fb950", False),
    "failure":       ("FAILED", "#f85149", False),
    "cancelled":     ("CANCELLED", "#8b949e", False),
}
LINES, WIDTH, COLS = 18, 900, 108

def dur(s):
    s = max(0, int(s)); h, r = divmod(s, 3600); m, sec = divmod(r, 60)
    return f"{h}h {m:02d}m {sec:02d}s" if h else f"{m}m {sec:02d}s"

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--state", required=True); ap.add_argument("--variant", default="?")
    ap.add_argument("--commit", default=""); ap.add_argument("--log", default="/dev/null")
    ap.add_argument("--start", type=int, default=0); ap.add_argument("--out", required=True)
    a = ap.parse_args()
    label, color, running = STATES.get(a.state, (a.state.upper(), "#8b949e", False))
    try:
        with open(a.log, errors="replace") as f:
            tail = f.read().splitlines()[-LINES:]
    except OSError:
        tail = []
    tail = [ANSI.sub("", l).replace("\t", "    ").rstrip() for l in tail]
    tail = [(l[:COLS - 1] + "…") if len(l) > COLS else l for l in tail]
    now = int(time.time())
    elapsed = dur(now - a.start) if a.start else "?"
    word = "elapsed" if running else "total"
    top = 34; h = top + 54 + LINES * 16 + 16
    out = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{WIDTH}" height="{h}" viewBox="0 0 {WIDTH} {h}" '
           f'font-family="ui-monospace,SFMono-Regular,Menlo,Consolas,monospace" font-size="12">',
           f'<rect width="{WIDTH}" height="{h}" rx="8" fill="#0d1117"/>',
           f'<rect width="{WIDTH}" height="{top}" rx="8" fill="#161b22"/><rect y="20" width="{WIDTH}" height="14" fill="#161b22"/>',
           '<circle cx="18" cy="17" r="5" fill="#f85149"/><circle cx="38" cy="17" r="5" fill="#d29922"/><circle cx="58" cy="17" r="5" fill="#3fb950"/>',
           f'<text x="{WIDTH//2}" y="21" fill="#8b949e" text-anchor="middle">nightlyfox@actions: {html.escape(a.variant)}</text>',
           f'<text x="16" y="{top+26}" font-size="14" font-weight="bold" fill="{color}" xml:space="preserve">● {label}</text>',
           f'<text x="16" y="{top+44}" fill="#8b949e" xml:space="preserve">commit {html.escape(a.commit or "-")}  ·  {word} {elapsed}  ·  updated {time.strftime("%Y-%m-%d %H:%M:%S", time.gmtime(now))} UTC</text>']
    y = top + 70
    for l in tail:
        out.append(f'<text x="16" y="{y}" fill="#c9d1d9" xml:space="preserve">{html.escape(l)}</text>'); y += 16
    if running:
        out.append(f'<text x="16" y="{y}" fill="#3fb950">█<animate attributeName="opacity" values="1;0;1" dur="1s" repeatCount="indefinite"/></text>')
    out.append("</svg>")
    with open(a.out, "w") as f:
        f.write("\n".join(out))

main()
