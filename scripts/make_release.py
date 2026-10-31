#!/usr/bin/env python3
"""Builds release notes (timings + commit list) and the update feeds (update-*.xml)."""
import argparse, glob, hashlib, json, os, subprocess
from datetime import datetime, timezone

def t(e): return datetime.fromtimestamp(int(e), timezone.utc).strftime("%Y-%m-%d %H:%M:%S")
def dur(s):
    s = max(0, int(s)); h, r = divmod(s, 3600); m, sec = divmod(r, 60)
    return f"{h}h {m:02d}m {sec:02d}s" if h else f"{m}m {sec:02d}s"

def gh_json_lines(args):
    try:
        r = subprocess.run(["gh", "api"] + args, capture_output=True, text=True)
    except OSError:
        return None
    if r.returncode:
        return None
    rows = []
    for line in r.stdout.splitlines():
        try: rows.append(json.loads(line))
        except ValueError: pass
    return rows

JQ = '{sha: .sha, msg: (.commit.message | split("\\n")[0]), author: .commit.author.name} | tojson'

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--tag", required=True); ap.add_argument("--out", required=True)
    ap.add_argument("--meta", required=True); ap.add_argument("--notes", required=True)
    a = ap.parse_args()
    env = os.environ
    repo, up, branch = env["GITHUB_REPOSITORY"], env["UPSTREAM_REPO"], env["UPSTREAM_BRANCH"]
    sha, short, prev = env["SHA"], env["SHORT"], env.get("PREV", "")

    infos = [json.load(open(p)) for p in sorted(glob.glob(os.path.join(a.meta, "info-*.json")))]

    # ---- update feeds (one per variant that produced a MAR) ----
    for i in infos:
        if not i.get("mar"): continue
        path = os.path.join(a.out, i["mar"])
        data = open(path, "rb").read()
        url = f"https://github.com/{repo}/releases/download/{a.tag}/{i['mar']}"
        xml = (f'<?xml version="1.0"?>\n<updates>\n'
               f'  <update type="minor" displayVersion="{i["version"]}" appVersion="{i["version"]}" '
               f'platformVersion="{i["version"]}" buildID="{i["build_id"]}" '
               f'detailsURL="https://github.com/{repo}/releases/tag/{a.tag}">\n'
               f'    <patch type="complete" URL="{url}" hashFunction="sha512" '
               f'hashValue="{hashlib.sha512(data).hexdigest()}" size="{len(data)}"/>\n'
               f'  </update>\n</updates>\n')
        open(os.path.join(a.out, f"update-{i['branding']}-{i['platform']}.xml"), "w").write(xml)

    # ---- commits ----
    if prev:
        rows = gh_json_lines(["--paginate", f"repos/{up}/compare/{prev}...{sha}?per_page=100", "--jq", ".commits[] | " + JQ])
        title = f"Commits since the previous build"
        link = f"https://github.com/{up}/compare/{prev}...{sha}"
    else:
        rows = gh_json_lines([f"repos/{up}/commits?sha={branch}&per_page=30", "--jq", ".[] | " + JQ])
        title = "Latest commits (first build, no previous build to compare against)"
        link = f"https://github.com/{up}/commits/{sha}"

    md = [f"## NightlyFox build of upstream [`{short}`](https://github.com/{up}/commit/{sha})", ""]
    if infos:
        md += [f"Version `{infos[0]['version']}`  ·  upstream branch `{branch}`", ""]
    md += ["### Build times (UTC)", "",
           "| Platform | Branding | Job started | Compile started | Compile finished | Compile time | Total job time |",
           "|---|---|---|---|---|---|---|"]
    for i in sorted(infos, key=lambda x: (x["platform"], x["branding"])):
        md.append(f"| {i['platform']} | {i['branding']} | {t(i['started'])} | {t(i['compile_start'])} | {t(i['compile_end'])} | "
                  f"**{dur(i['compile_end'] - i['compile_start'])}** | {dur(i['finished'] - i['started'])} |")
    md.append("")
    if rows is None:
        md += [f"### {title}", "", f"Couldn't fetch the list. See the [full comparison]({link}).", ""]
    else:
        cap = 400
        md += [f"### {title} ({len(rows)})", "", f"[View on GitHub]({link})", ""]
        for r in rows[:cap]:
            msg = r["msg"].replace("|", "\\|")
            md.append(f"- [`{r['sha'][:10]}`](https://github.com/{up}/commit/{r['sha']}) {msg} — {r['author']}")
        if len(rows) > cap:
            md.append(f"- …and {len(rows) - cap} more (see link above)")
        md.append("")
    md += ["---", "Unofficial build, not made by or endorsed by Mozilla.", "",
           f"<!-- upstream-sha: {sha} -->"]
    open(a.notes, "w").write("\n".join(md))

main()
