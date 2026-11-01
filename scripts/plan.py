#!/usr/bin/env python3
"""Works out the build matrix (platforms x brandings) and writes it to GITHUB_OUTPUT."""
import json, os, re

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

ob = (os.environ.get("SEL_ONBOARDING") or "off").strip().lower()
modes = ["off", "on"] if ob in ("both", "all") else (["on"] if ob == "on" else ["off"])
if ob not in ("off", "on", "both", "all"):
    notes.append(f"Unknown onboarding setting `{ob}`, using `off`.")
APPLIES = {"linux": ["deb", "flatpak"], "windows": ["installer"]}
DEFAULT = {"linux": ["deb"], "windows": ["installer"]}
pk = (os.environ.get("SEL_PACKAGES") or "").strip().lower()
want = [x for x in re.split(r"[ ,]+", pk) if x]
for x in want:
    if x not in ("default", "none", "all") and not any(x in v for v in APPLIES.values()):
        notes.append(f"Unknown package type `{x}` ignored.")
def packages_for(osname):
    if not want or "default" in want: return DEFAULT.get(osname, [])
    if "none" in want: return []
    if "all" in want: return APPLIES.get(osname, [])
    return [x for x in APPLIES.get(osname, []) if x in want]
include = [{"platform": p, "branding": b, "onboarding": m,
            "packages": ",".join(packages_for(platforms[p]["os"])),
            "flavor": b + ("-onboarding" if m == "on" else ""),
            "runner": platforms[p]["runner"], "arch": platforms[p]["arch"], "os": platforms[p]["os"]}
           for p in plats for b in brs for m in modes]
print(f"{len(include)} build(s):", ", ".join(f"{i['platform']}/{i['flavor']}" for i in include) or "none")
for n in notes:
    print("NOTE:", n)

with open(os.environ["GITHUB_OUTPUT"], "a") as f:
    f.write("matrix=" + json.dumps({"include": include}) + "\n")
    f.write(f"count={len(include)}\n")
with open(os.environ.get("GITHUB_STEP_SUMMARY", os.devnull), "a") as f:
    f.write(f"### Build plan\n{len(include)} build(s)\n\n" + "".join(f"- {n}\n" for n in notes))
