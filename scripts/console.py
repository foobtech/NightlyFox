#!/usr/bin/env python3
"""Render a clean status card (light/dark aware): build state, facts, and the last log lines."""
import argparse, html, re, time

ANSI = re.compile(r"\x1b\[[0-9;?]*[A-Za-z]")
STATES = {
    "starting":      ("STARTING", "#388bfd", True),
    "bootstrapping": ("INSTALLING DEPENDENCIES", "#388bfd", True),
    "compiling":     ("COMPILING", "#bf8700", True),
    "packaging":     ("PACKAGING", "#8250df", True),
    "success":       ("DONE", "#2da44e", False),
    "failure":       ("FAILED", "#cf222e", False),
    "cancelled":     ("CANCELLED", "#6e7781", False),
}
LINES, W, COLS = 10, 860, 112

def dur(s):
    s = max(0, int(s)); h, r = divmod(s, 3600); m, sec = divmod(r, 60)
    return f"{h}h {m:02d}m {sec:02d}s" if h else f"{m}m {sec:02d}s"

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--state", required=True); ap.add_argument("--label", default="")
    ap.add_argument("--variant", default="?"); ap.add_argument("--commit", default="")
    ap.add_argument("--log", default="/dev/null"); ap.add_argument("--start", type=int, default=0)
    ap.add_argument("--out", required=True)
    a = ap.parse_args()
    label_txt = a.label or a.variant
    word, color, running = STATES.get(a.state, (a.state.upper(), "#6e7781", False))
    try:
        with open(a.log, errors="replace") as f:
            tail = [l for l in f.read().splitlines() if l.strip()][-LINES:]
    except OSError:
        tail = []
    tail = [ANSI.sub("", l).replace("\t", "    ").rstrip() for l in tail]
    tail = [(l[:COLS - 1] + "…") if len(l) > COLS else l for l in tail]
    now = int(time.time())
    elapsed = dur(now - a.start) if a.start else "?"
    facts = (f"commit {a.commit or '-'}   ·   {'elapsed' if running else 'total'} {elapsed}"
             f"   ·   updated {time.strftime('%Y-%m-%d %H:%M UTC', time.gmtime(now))}")
    pw = int(26 + 7.6 * len(word)); px = W - 24 - pw
    box_h = LINES * 15 + 18; H = 108 + box_h + 20
    o = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">',
         '<style>'
         '.bg{fill:#fff;stroke:#d0d7de}.t{fill:#1f2328}.m{fill:#656d76}.lb{fill:#f6f8fa}.lg{fill:#24292f}.dv{stroke:#d8dee4}.tr{fill:#eaeef2}'
         '@media (prefers-color-scheme:dark){.bg{fill:#0d1117;stroke:#30363d}.t{fill:#e6edf3}.m{fill:#8b949e}.lb{fill:#161b22}.lg{fill:#c9d1d9}.dv{stroke:#30363d}.tr{fill:#21262d}}'
         '.s{font-family:-apple-system,"Segoe UI",Helvetica,Arial,sans-serif}'
         '.c{font-family:ui-monospace,SFMono-Regular,Menlo,Consolas,monospace}'
         '</style>',
         f'<defs><clipPath id="cp"><rect x="0.5" y="0.5" width="{W-1}" height="{H-1}" rx="10"/></clipPath></defs>',
         f'<rect class="bg" x="0.5" y="0.5" width="{W-1}" height="{H-1}" rx="10"/>',
         f'<g clip-path="url(#cp)"><rect class="tr" width="{W}" height="4"/>']
    if running:
        o.append(f'<rect y="0" width="180" height="4" fill="{color}"><animate attributeName="x" from="-180" to="{W}" dur="1.8s" repeatCount="indefinite"/></rect>')
    else:
        o.append(f'<rect y="0" width="{W}" height="4" fill="{color}"/>')
    o += ['</g>',
          f'<text class="s t" x="24" y="38" font-size="17" font-weight="600">{html.escape(label_txt)}</text>',
          f'<rect x="{px}" y="21" width="{pw}" height="24" rx="12" fill="{color}"/>',
          f'<text class="s" x="{px + pw/2}" y="37" font-size="11" font-weight="700" fill="#fff" text-anchor="middle" letter-spacing="0.5">{word}</text>',
          f'<text class="s m" x="24" y="64" font-size="12" xml:space="preserve">{html.escape(facts)}</text>',
          f'<line class="dv" x1="24" y1="78" x2="{W-24}" y2="78"/>',
          '<text class="s m" x="24" y="98" font-size="10" font-weight="600" letter-spacing="1">LATEST OUTPUT</text>',
          f'<rect class="lb" x="20" y="106" width="{W-40}" height="{box_h}" rx="6"/>']
    y = 106 + 20
    for l in tail:
        o.append(f'<text class="c lg" x="32" y="{y}" font-size="11" xml:space="preserve">{html.escape(l)}</text>'); y += 15
    o.append("</svg>")
    with open(a.out, "w") as f:
        f.write("\n".join(o))

main()
