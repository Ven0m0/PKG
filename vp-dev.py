#!/usr/bin/env python3
"""vp-dev - Development tool for Ven0m0's PKG repository"""

import sys
import json
import argparse
import subprocess
import shutil
import re
from pathlib import Path
import concurrent.futures

VERSION="1.0.0"

class C:
  R="\033[0;31m"
  G="\033[0;32m"
  B="\033[0;34m"
  Y="\033[1;33m"
  N="\033[0m"

def info(m: str)->None: print(f"{C.B}→{C.N} {m}")
def ok(m: str)->None: print(f"{C.G}✓{C.N} {m}")
def err(m: str)->None: print(f"{C.R}✗{C.N} {m}",file=sys.stderr)
def warn(m: str)->None: print(f"{C.Y}⚠{C.N} {m}")

class VpDev:
  __slots__=('root','pkg_json','git','skip_dirs')
  def __init__(self)->None:
    self.root=Path(__file__).parent
    self.pkg_json=self.root/"packages.json"
    self.git="/usr/bin/git"
    self.skip_dirs={'.git','.github','node_modules','__pycache__','.vscode','patches','docs'}

  def _git(self,args: list[str],cwd: Path|None=None,**kw)->subprocess.CompletedProcess:
    return subprocess.run([self.git]+args,cwd=cwd or self.root,**kw)

  def _parse_pkg(self,pb: Path)->dict[str,str|list[str]]|None:
    if not pb.exists(): return None
    try:
      r=subprocess.run(["bash","-c",f'source "{pb}" 2>/dev/null;echo "${{pkgname}}|${{pkgver}}|${{pkgrel}}|${{pkgdesc}}|${{url}}"'],capture_output=True,text=True,cwd=pb.parent,check=False)
      if r.returncode!=0: return None
      p=r.stdout.strip().split("|")
      if len(p)<4: return None
      r2=self._git(["ls-files"],capture_output=True,text=True,cwd=pb.parent,check=True)
      fs=[f for f in r2.stdout.strip().split("\n") if f and f!="PKGBUILD"]
      return {"name":p[0],"version":f"{p[1]}-{p[2]}","description":p[3],"url":p[4] if len(p)>4 else "","files":sorted(fs)}
    except Exception as e:
      err(f"Failed to parse {pb}: {e}")
      return None

  def _get_pkg_dirs(self)->list[Path]:
    """Get all package directories (dirs with PKGBUILD, excluding skip_dirs)"""
    dirs=[]
    for d in sorted(self.root.iterdir()):
      if d.is_dir() and d.name not in self.skip_dirs and (d/"PKGBUILD").exists():
        dirs.append(d)
    return dirs

  def new(self,nm: str)->int:
    d=self.root/nm
    if d.exists(): err(f"Package '{nm}' already exists!"); return 1
    info(f"Creating new package: {nm}")
    d.mkdir(parents=True)
    (d/"PKGBUILD").write_text(f"""# Maintainer: Ven0m0 <https://github.com/Ven0m0>

pkgname={nm}
pkgver=1.0.0
pkgrel=1
pkgdesc="Description of {nm}"
arch=('x86_64')
url="https://example.com"
license=('GPL')
depends=()
makedepends=()
source=()
sha256sums=()

package(){{
  :
}}
""")
    (d/"readme.md").write_text(f"""# {nm}

## Description

[Add description here]

## Optimizations

- [List optimizations]

## Installation
```bash
vp install {nm}
```

Or manual build:
```bash
cd {nm}
makepkg -si
```

## Notes

[Add any additional notes]
""")
    ok(f"Created package template at {d}")
    info("Edit the PKGBUILD and run 'vp-dev test' to build locally")
    return 0

  def test(self,nm: str|None)->int:
    dirs=[self.root/nm] if nm else ([Path.cwd()] if (Path.cwd()/"PKGBUILD").exists() else [])
    if not dirs: err("No PKGBUILD found in current directory"); return 1
    for d in dirs:
      if not d.exists(): err(f"Package directory not found: {d}"); continue
      info(f"Building package in {d}")
      if subprocess.run(["makepkg","-sf"],cwd=d,check=False).returncode==0:
        ok("Package built successfully")
        for pf in d.glob("*.pkg.tar.zst"): info(f"Built: {pf.name}")
      else: err("Build failed"); return 1
    return 0

  def _process_package(self, d: Path) -> dict[str, str | list[str]] | None:
    """Process a single package directory.

    This method is intended to be called from multiple threads (see ``update``).
    It only performs read-only access to instance attributes such as ``self.root``
    and ``self.git``; callers must not mutate these attributes after initialization
    to preserve thread safety.
    """
    try:
      pb = d / "PKGBUILD"
      pi = self._parse_pkg(pb)
      if pi:
        info(f"Found: {pi['name']} {pi['version']}")
        r = subprocess.run(["makepkg", "--printsrcinfo"], cwd=d, capture_output=True, text=True, check=False)
        if r.returncode == 0:
          (d / ".SRCINFO").write_text(r.stdout)
        else:
          warn(f"Failed to generate .SRCINFO for {d.name}")
        return pi
      else:
        warn(f"Failed to parse {d.name}/PKGBUILD")
        return None
    except Exception as e:
      err(f"Error processing package {d}: {e}")
      return None

  def update(self) -> int:
    info("Scanning for packages...")
    pkgs = []
    with concurrent.futures.ThreadPoolExecutor() as executor:
      results = list(executor.map(self._process_package, self._get_pkg_dirs()))
      pkgs = [p for p in results if p]

    # Get vp version
    vv="unknown"
    vp=self.root/"vp"
    if vp.exists():
      try:
        m=re.search(r'^VERSION="([^"]+)"',vp.read_text(),re.MULTILINE)
        if m: vv=m.group(1)
      except: pass
    
    if self.pkg_json.exists(): shutil.copy(self.pkg_json,self.pkg_json.with_suffix(".json.bak"))
    self.pkg_json.write_text(json.dumps({"packages":pkgs,"tools":{"vp":vv,"vp-dev":VERSION}},indent=2))
    ok(f"Updated packages.json with {len(pkgs)} packages")
    info(f"Tool versions: vp v{vv}, vp-dev v{VERSION}")
    return 0

  def publish(self)->int:
    info("Publishing repository...")
    if self.update()!=0: return 1
    try:
      self._git(["add","-A"],check=True)
      if self._git(["diff","--cached","--exit-code"],capture_output=True,check=False).returncode==0:
        info("No changes to publish")
        return 0
      self._git(["commit","-m","Update packages"],check=True)
      self._git(["push"],check=True)
      ok("Published successfully!")
      info("Changes will be live at https://ven0m0.github.io/PKG/ in a few minutes")
    except subprocess.CalledProcessError as e:
      err(f"Git operation failed: {e}")
      return 1
    return 0

  def check(self)->int:
    info("Checking all packages...")
    errs=0
    for d in self._get_pkg_dirs():
      pb=d/"PKGBUILD"
      pi=self._parse_pkg(pb)
      if not pi: err(f"{d.name}: Failed to parse PKGBUILD"); errs+=1; continue
      if not pi.get("name"): err(f"{d.name}: Missing pkgname"); errs+=1
      if not pi.get("version"): err(f"{d.name}: Missing version"); errs+=1
      if not pi.get("description"): warn(f"{d.name}: Missing description")
      if errs==0: ok(f"{d.name}: OK")
    if errs>0: err(f"Found {errs} errors"); return 1
    ok("All packages OK")
    return 0

  def clean(self)->int:
    info("Cleaning build artifacts...")
    pats=["*.pkg.tar.zst","*.pkg.tar.xz","*.log","pkg","src","*.bak"]
    c=0
    for d in self._get_pkg_dirs():
      for pat in pats:
        for it in d.glob(pat):
          (shutil.rmtree if it.is_dir() else it.unlink)(it)
          info(f"Removed {'directory' if it.is_dir() else 'file'}: {it}")
          c+=1
    ok(f"Cleaned {c} items")
    return 0

  def list(self)->int:
    for d in self._get_pkg_dirs():
      pb=d/"PKGBUILD"
      pi=self._parse_pkg(pb)
      print(f"{pi['name']:<30} {pi['version']:<20} {pi['description'][:60]}" if pi else f"{d.name:<30} {'PARSE ERROR':<20}")
    return 0

  def updpkgsums(self,nm: str)->int:
    d=self.root/nm
    if not d.exists(): err(f"Package '{nm}' not found!"); return 1
    pb=d/"PKGBUILD"
    if not pb.exists(): err(f"No PKGBUILD found in {nm}"); return 1
    info(f"Updating checksums for {nm}...")
    r=subprocess.run(["updpkgsums"],cwd=d,capture_output=True,text=True,check=False)
    if r.returncode==0:
      ok(f"Updated checksums for {nm}")
      info("Generating .SRCINFO...")
      r2=subprocess.run(["makepkg","--printsrcinfo"],cwd=d,capture_output=True,text=True,check=False)
      if r2.returncode==0: (d/".SRCINFO").write_text(r2.stdout); ok("Generated .SRCINFO")
      else: warn("Failed to generate .SRCINFO")
    else: err(f"Failed to update checksums: {r.stderr}"); return 1
    return 0

def main()->int:
  p=argparse.ArgumentParser(description="vp-dev - PKG repository development tool")
  sp=p.add_subparsers(dest="cmd",help="Commands")
  sp.add_parser("new",help="Create new package from template").add_argument("pkg",help="Package name")
  sp.add_parser("test",help="Build package locally").add_argument("pkg",nargs="?",help="Package name (optional)")
  sp.add_parser("update",help="Update packages.json from PKGBUILDs")
  sp.add_parser("publish",help="Update, commit and push changes")
  sp.add_parser("check",help="Validate all PKGBUILDs")
  sp.add_parser("clean",help="Remove all build artifacts")
  sp.add_parser("list",help="List all packages")
  sp.add_parser("updpkgsums",help="Update checksums in PKGBUILD").add_argument("pkg",help="Package name")
  a=p.parse_args()
  if not a.cmd: p.print_help(); return 1
  vd=VpDev()
  return {"new":lambda:vd.new(a.pkg),"test":lambda:vd.test(a.pkg if hasattr(a,'pkg') else None),"update":vd.update,"publish":vd.publish,"check":vd.check,"clean":vd.clean,"list":vd.list,"updpkgsums":lambda:vd.updpkgsums(a.pkg)}.get(a.cmd,lambda:1)()

if __name__=="__main__": sys.exit(main())
