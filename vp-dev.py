#!/usr/bin/env python3
"""vp-dev - Development tool for Ven0m0's PKG repository"""

import sys
import json
import argparse
import subprocess
import shutil
import re
from pathlib import Path

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
