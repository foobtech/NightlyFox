#!/usr/bin/env python3
"""Works out the build matrix (platforms x brandings) and writes it to GITHUB_OUTPUT."""
import json, os

platforms = json.load(open("platforms.json"))
brandings = json.load(open("brandings.json"))
notes = []

def pick(spec, table, what):
    spec = (spec or "").strip().lower()
    if not spec:
        names = [k for k, v in table.items() if v.get("default")]
    elif spec == "all":
        names = list(table)
    else:
        names = [s for s in spec.replace(" ", ",").split(",") if s]
    out = []
    for n in names:
        if n not in table:
            notes.append(f"Unknown {what} `{n}` ignored.")
        else:
            out.append(n)
    return out

plats, brs = [], []
for p in pick(os.environ.get("SEL_PLATFORMS"), platforms, "platform"):
    if platforms[p].get("supported"):
        plats.append(p)
    else:
        notes.append(f"Platform `{p}` skipped: not supported yet ({platforms[p].get('note', '')}).")
for b in pick(os.environ.get("SEL_BRANDINGS"), brandings, "branding"):
    need = brandings[b].get("needs_dir")
    if need and not os.path.isdir(need):
        notes.append(f"Branding `{b}` skipped: `{need}` not found. Run the 'Fetch FireDoge branding' workflow once.")
    else:
        brs.append(b)

include = [{"platform": p, "branding": b, "runner": platforms[p]["runner"], "arch": platforms[p]["arch"]}
           for p in plats for b in brs]
print(f"{len(include)} build(s):", ", ".join(f"{i['platform']}/{i['branding']}" for i in include) or "none")
for n in notes:
    print("NOTE:", n)

with open(os.environ["GITHUB_OUTPUT"], "a") as f:
    f.write("matrix=" + json.dumps({"include": include}) + "\n")
    f.write(f"count={len(include)}\n")
with open(os.environ.get("GITHUB_STEP_SUMMARY", os.devnull), "a") as f:
    f.write(f"### Build plan\n{len(include)} build(s)\n\n" + "".join(f"- {n}\n" for n in notes))
