#!/usr/bin/env python3
"""Report locally tracked packages that are out of date vs. Arch repos and the AUR."""

from __future__ import annotations

from typing import Any

import attr
import requests

AUR_URL = "https://aur.archlinux.org/rpc/v5"
AUR_REQUEST_TIMEOUT = 10

LOCAL_REPOS = {"custom", "loathk-public", "loathk-personal"}
ARCH_REPOS = {"core", "extra", "community", "multilib"}

_RED = "\033[31m"
_GREEN = "\033[32m"
_RESET = "\033[0m"


def _serialize(value: Any) -> Any:
    """Recursively convert nested models to plain dicts for ``to_dict``."""
    if isinstance(value, list):
        return [_serialize(v) for v in value]
    return value.to_dict() if hasattr(value, "to_dict") else value


class _AurModel:
    """Base for AUR RPC models, driven by two class attributes on subclasses:

    ``_FIELDS`` maps each attrs field name to its JSON key (Pascal/camelCase),
    and ``_NESTED`` maps list-of-model field names to their element class. This
    replaces the per-field ``to_dict``/``from_dict`` boilerplate the JSON schema
    would otherwise require.
    """

    _FIELDS: dict[str, str] = {}
    _NESTED: dict[str, type] = {}
    additional_properties: dict[str, Any]

    @property
    def additional_keys(self) -> list[str]:
        return list(self.additional_properties.keys())

    def __getitem__(self, key: str) -> Any:
        return self.additional_properties[key]

    def __setitem__(self, key: str, value: Any) -> None:
        self.additional_properties[key] = value

    def __delitem__(self, key: str) -> None:
        del self.additional_properties[key]

    def __contains__(self, key: str) -> bool:
        return key in self.additional_properties

    def to_dict(self) -> dict[str, Any]:
        out: dict[str, Any] = dict(self.additional_properties)
        for attr_name, json_key in self._FIELDS.items():
            value = getattr(self, attr_name)
            if value is not None:
                out[json_key] = _serialize(value)
        return out

    @classmethod
    def from_dict(cls, src_dict: dict[str, Any]):
        data = dict(src_dict)
        kwargs: dict[str, Any] = {}
        for attr_name, json_key in cls._FIELDS.items():
            raw = data.pop(json_key, None)
            nested = cls._NESTED.get(attr_name)
            if nested is not None:
                kwargs[attr_name] = [nested.from_dict(item) for item in (raw or [])]
            else:
                kwargs[attr_name] = raw
        obj = cls(**kwargs)
        obj.additional_properties = data
        return obj


@attr.s(auto_attribs=True)
class PackageBasic(_AurModel):
    id: int | None = None
    name: str | None = None
    description: str | None = None
    package_base_id: int | None = None
    package_base: str | None = None
    maintainer: str | None = None
    num_votes: int | None = None
    popularity: float | None = None
    first_submitted: int | None = None
    last_modified: int | None = None
    out_of_date: str | None = None
    version: str | None = None
    url_path: str | None = None
    url: str | None = None
    additional_properties: dict[str, Any] = attr.ib(init=False, factory=dict)

    _FIELDS = {
        "id": "ID",
        "name": "Name",
        "description": "Description",
        "package_base_id": "PackageBaseID",
        "package_base": "PackageBase",
        "maintainer": "Maintainer",
        "num_votes": "NumVotes",
        "popularity": "Popularity",
        "first_submitted": "FirstSubmitted",
        "last_modified": "LastModified",
        "out_of_date": "OutOfDate",
        "version": "Version",
        "url_path": "URLPath",
        "url": "URL",
    }


@attr.s(auto_attribs=True)
class PackageDetailed(_AurModel):
    id: int | None = None
    name: str | None = None
    description: str | None = None
    package_base_id: int | None = None
    package_base: str | None = None
    maintainer: str | None = None
    num_votes: int | None = None
    popularity: float | None = None
    first_submitted: int | None = None
    last_modified: int | None = None
    out_of_date: str | None = None
    version: str | None = None
    url_path: str | None = None
    url: str | None = None
    submitter: str | None = None
    license_: list[str] | None = None
    depends: list[str] | None = None
    make_depends: list[str] | None = None
    opt_depends: list[str] | None = None
    check_depends: list[str] | None = None
    provides: list[str] | None = None
    conflicts: list[str] | None = None
    replaces: list[str] | None = None
    groups: list[str] | None = None
    keywords: list[str] | None = None
    co_maintainers: list[str] | None = None
    additional_properties: dict[str, Any] = attr.ib(init=False, factory=dict)

    _FIELDS = {
        **PackageBasic._FIELDS,
        "submitter": "Submitter",
        "license_": "License",
        "depends": "Depends",
        "make_depends": "MakeDepends",
        "opt_depends": "OptDepends",
        "check_depends": "CheckDepends",
        "provides": "Provides",
        "conflicts": "Conflicts",
        "replaces": "Replaces",
        "groups": "Groups",
        "keywords": "Keywords",
        "co_maintainers": "CoMaintainers",
    }


@attr.s(auto_attribs=True)
class SearchResult(_AurModel):
    resultcount: int | None = None
    type: str | None = None
    version: int | None = None
    results: list[PackageBasic] | None = None
    additional_properties: dict[str, Any] = attr.ib(init=False, factory=dict)

    _FIELDS = {
        "resultcount": "resultcount",
        "type": "type",
        "version": "version",
        "results": "results",
    }
    _NESTED = {"results": PackageBasic}


@attr.s(auto_attribs=True)
class InfoResult(_AurModel):
    resultcount: int | None = None
    type: str | None = None
    version: int | None = None
    results: list[PackageDetailed] | None = None
    additional_properties: dict[str, Any] = attr.ib(init=False, factory=dict)

    _FIELDS = {
        "resultcount": "resultcount",
        "type": "type",
        "version": "version",
        "results": "results",
    }
    _NESTED = {"results": PackageDetailed}


def search_single(name: str) -> SearchResult:
    response = requests.get(
        f"{AUR_URL}/search/{name}?by=name", timeout=AUR_REQUEST_TIMEOUT
    )
    response.raise_for_status()
    return SearchResult.from_dict(response.json())


def info_multiple(names: list[str]) -> InfoResult:
    response = requests.get(
        f"{AUR_URL}/info", params={"arg[]": names}, timeout=AUR_REQUEST_TIMEOUT
    )
    response.raise_for_status()
    return InfoResult.from_dict(response.json())


def print_package_update(
    remote_db: str,
    local_db: str,
    package_name: str,
    remote_version: str,
    local_version: str,
) -> None:
    print(
        "{:20s} {:28s} {} -> {}".format(
            f"{remote_db} - {local_db}",
            package_name,
            _RED + local_version + _RESET,
            _GREEN + remote_version + _RESET,
        )
    )


def main() -> None:
    import pyalpm
    import pycman.config as config

    handle = config.init_with_config("/etc/pacman.conf")
    syncdbs = handle.get_syncdbs()
    arch_dbs = [db for db in syncdbs if db.name in ARCH_REPOS]
    local_dbs = [db for db in syncdbs if db.name in LOCAL_REPOS]

    # Pre-compute an Arch package map to avoid N+1 lookups inside the loop.
    # Maps package name -> (package_object, db_name).
    arch_pkg_map: dict[str, tuple[Any, str]] = {}
    for adb in arch_dbs:
        for ap in adb.pkgcache:
            arch_pkg_map.setdefault(ap.name, (ap, adb.name))

    for ldb in local_dbs:
        local_packages = sorted(ldb.search(""), key=lambda p: p.name)
        found_in_arch: set[str] = set()

        for lp in local_packages:
            res = arch_pkg_map.get(lp.name)
            if res:
                ap, adb_name = res
                found_in_arch.add(lp.name)
                # vercmp: left < right -> -1 (local older than repo)
                if pyalpm.vercmp(lp.version, ap.version) < 0:
                    print_package_update(
                        adb_name, ldb.name, lp.name, ap.version, lp.version
                    )

        aur_candidates = [lp for lp in local_packages if lp.name not in found_in_arch]
        if not aur_candidates:
            print("")
            continue

        aur_map = {
            ap.name: ap
            for ap in info_multiple([lp.name for lp in aur_candidates]).results
        }

        for lp in aur_candidates:
            ap = aur_map.get(lp.name)
            if ap is None:
                print("{:20s} {}".format(f"non - {ldb.name}", lp.name))
            elif pyalpm.vercmp(lp.version, ap.version) < 0:
                print_package_update("aur", ldb.name, lp.name, ap.version, lp.version)

        print("")


if __name__ == "__main__":
    main()
