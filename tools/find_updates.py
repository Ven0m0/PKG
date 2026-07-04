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
class SearchResult(AdditionalPropertiesMixin):
    resultcount: Optional[int] = None
    type: Optional[str] = None
    version: Optional[int] = None
    results: Optional[List["PackageBasic"]] = None
    additional_properties: Dict[str, Any] = attr.ib(init=False, factory=dict)

    def to_dict(self) -> Dict[str, Any]:
        resultcount = self.resultcount
        type = self.type
        version = self.version
        results: Optional[List[Dict[str, Any]]] = None
        if self.results is not None:
            results = [results_item_data.to_dict() for results_item_data in self.results]
        field_dict: Dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if resultcount is not None:
            field_dict["resultcount"] = resultcount
        if type is not None:
            field_dict["type"] = type
        if version is not None:
            field_dict["version"] = version
        if results is not None:
            field_dict["results"] = results
        return field_dict

    @classmethod
    def from_dict(
        cls: Type["SearchResult"], src_dict: Dict[str, Any]
    ) -> "SearchResult":
        d = src_dict.copy()
        resultcount = d.pop("resultcount", None)
        type = d.pop("type", None)
        version = d.pop("version", None)
        results = []
        _results = d.pop("results", None)
        for results_item_data in _results or []:
            results_item = PackageBasic.from_dict(results_item_data)
            results.append(results_item)
        search_result = cls(
            resultcount=resultcount,
            type=type,
            version=version,
            results=results,
        )
        search_result.additional_properties = d
        return search_result


@attr.s(auto_attribs=True)
class PackageDetailed(AdditionalPropertiesMixin):
    id: Optional[int] = None
    name: Optional[str] = None
    description: Optional[str] = None
    package_base_id: Optional[int] = None
    package_base: Optional[str] = None
    maintainer: Optional[str] = None
    num_votes: Optional[int] = None
    popularity: Optional[float] = None
    first_submitted: Optional[int] = None
    last_modified: Optional[int] = None
    out_of_date: Optional[str] = None
    version: Optional[str] = None
    url_path: Optional[str] = None
    url: Optional[str] = None
    submitter: Optional[str] = None
    license_: Optional[List[str]] = None
    depends: Optional[List[str]] = None
    make_depends: Optional[List[str]] = None
    opt_depends: Optional[List[str]] = None
    check_depends: Optional[List[str]] = None
    provides: Optional[List[str]] = None
    conflicts: Optional[List[str]] = None
    replaces: Optional[List[str]] = None
    groups: Optional[List[str]] = None
    keywords: Optional[List[str]] = None
    co_maintainers: Optional[List[str]] = None
    additional_properties: Dict[str, Any] = attr.ib(init=False, factory=dict)

    def to_dict(self) -> Dict[str, Any]:
        id = self.id
        name = self.name
        description = self.description
        package_base_id = self.package_base_id
        package_base = self.package_base
        maintainer = self.maintainer
        num_votes = self.num_votes
        popularity = self.popularity
        first_submitted = self.first_submitted
        last_modified = self.last_modified
        out_of_date = self.out_of_date
        version = self.version
        url_path = self.url_path
        url = self.url
        submitter = self.submitter
        license_: Optional[List[str]] = None
        if self.license_ is not None:
            license_ = self.license_
        depends: Optional[List[str]] = None
        if self.depends is not None:
            depends = self.depends
        make_depends: Optional[List[str]] = None
        if self.make_depends is not None:
            make_depends = self.make_depends
        opt_depends: Optional[List[str]] = None
        if self.opt_depends is not None:
            opt_depends = self.opt_depends
        check_depends: Optional[List[str]] = None
        if self.check_depends is not None:
            check_depends = self.check_depends
        provides: Optional[List[str]] = None
        if self.provides is not None:
            provides = self.provides
        conflicts: Optional[List[str]] = None
        if self.conflicts is not None:
            conflicts = self.conflicts
        replaces: Optional[List[str]] = None
        if self.replaces is not None:
            replaces = self.replaces
        groups: Optional[List[str]] = None
        if self.groups is not None:
            groups = self.groups
        keywords: Optional[List[str]] = None
        if self.keywords is not None:
            keywords = self.keywords
        co_maintainers: Optional[List[str]] = None
        if self.co_maintainers is not None:
            co_maintainers = self.co_maintainers
        field_dict: Dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if id is not None:
            field_dict["ID"] = id
        if name is not None:
            field_dict["Name"] = name
        if description is not None:
            field_dict["Description"] = description
        if package_base_id is not None:
            field_dict["PackageBaseID"] = package_base_id
        if package_base is not None:
            field_dict["PackageBase"] = package_base
        if maintainer is not None:
            field_dict["Maintainer"] = maintainer
        if num_votes is not None:
            field_dict["NumVotes"] = num_votes
        if popularity is not None:
            field_dict["Popularity"] = popularity
        if first_submitted is not None:
            field_dict["FirstSubmitted"] = first_submitted
        if last_modified is not None:
            field_dict["LastModified"] = last_modified
        if out_of_date is not None:
            field_dict["OutOfDate"] = out_of_date
        if version is not None:
            field_dict["Version"] = version
        if url_path is not None:
            field_dict["URLPath"] = url_path
        if url is not None:
            field_dict["URL"] = url
        if submitter is not None:
            field_dict["Submitter"] = submitter
        if license_ is not None:
            field_dict["License"] = license_
        if depends is not None:
            field_dict["Depends"] = depends
        if make_depends is not None:
            field_dict["MakeDepends"] = make_depends
        if opt_depends is not None:
            field_dict["OptDepends"] = opt_depends
        if check_depends is not None:
            field_dict["CheckDepends"] = check_depends
        if provides is not None:
            field_dict["Provides"] = provides
        if conflicts is not None:
            field_dict["Conflicts"] = conflicts
        if replaces is not None:
            field_dict["Replaces"] = replaces
        if groups is not None:
            field_dict["Groups"] = groups
        if keywords is not None:
            field_dict["Keywords"] = keywords
        if co_maintainers is not None:
            field_dict["CoMaintainers"] = co_maintainers
        return field_dict

    @classmethod
    def from_dict(
        cls: Type["PackageDetailed"], src_dict: Dict[str, Any]
    ) -> "PackageDetailed":
        d = src_dict.copy()
        id = d.pop("ID", None)
        name = d.pop("Name", None)
        description = d.pop("Description", None)
        package_base_id = d.pop("PackageBaseID", None)
        package_base = d.pop("PackageBase", None)
        maintainer = d.pop("Maintainer", None)
        num_votes = d.pop("NumVotes", None)
        popularity = d.pop("Popularity", None)
        first_submitted = d.pop("FirstSubmitted", None)
        last_modified = d.pop("LastModified", None)
        out_of_date = d.pop("OutOfDate", None)
        version = d.pop("Version", None)
        url_path = d.pop("URLPath", None)
        url = d.pop("URL", None)
        submitter = d.pop("Submitter", None)
        license_: Optional[List[str]] = d.pop("License", None)
        depends: Optional[List[str]] = d.pop("Depends", None)
        make_depends: Optional[List[str]] = d.pop("MakeDepends", None)
        opt_depends: Optional[List[str]] = d.pop("OptDepends", None)
        check_depends: Optional[List[str]] = d.pop("CheckDepends", None)
        provides: Optional[List[str]] = d.pop("Provides", None)
        conflicts: Optional[List[str]] = d.pop("Conflicts", None)
        replaces: Optional[List[str]] = d.pop("Replaces", None)
        groups: Optional[List[str]] = d.pop("Groups", None)
        keywords: Optional[List[str]] = d.pop("Keywords", None)
        co_maintainers: Optional[List[str]] = d.pop("CoMaintainers", None)
        package_detailed = cls(
            id=id,
            name=name,
            description=description,
            package_base_id=package_base_id,
            package_base=package_base,
            maintainer=maintainer,
            num_votes=num_votes,
            popularity=popularity,
            first_submitted=first_submitted,
            last_modified=last_modified,
            out_of_date=out_of_date,
            version=version,
            url_path=url_path,
            url=url,
            submitter=submitter,
            license_=license_,
            depends=depends,
            make_depends=make_depends,
            opt_depends=opt_depends,
            check_depends=check_depends,
            provides=provides,
            conflicts=conflicts,
            replaces=replaces,
            groups=groups,
            keywords=keywords,
            co_maintainers=co_maintainers,
        )
        package_detailed.additional_properties = d
        return package_detailed


@attr.s(auto_attribs=True)
class InfoResult(AdditionalPropertiesMixin):
    resultcount: Optional[int] = None
    type: Optional[str] = None
    version: Optional[int] = None
    results: Optional[List["PackageDetailed"]] = None
    additional_properties: Dict[str, Any] = attr.ib(init=False, factory=dict)

    def to_dict(self) -> Dict[str, Any]:
        resultcount = self.resultcount
        type = self.type
        version = self.version
        results: Optional[List[Dict[str, Any]]] = None
        if self.results is not None:
            results = [results_item_data.to_dict() for results_item_data in self.results]
        field_dict: Dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if resultcount is not None:
            field_dict["resultcount"] = resultcount
        if type is not None:
            field_dict["type"] = type
        if version is not None:
            field_dict["version"] = version
        if results is not None:
            field_dict["results"] = results
        return field_dict

    @classmethod
    def from_dict(cls: Type["InfoResult"], src_dict: Dict[str, Any]) -> "InfoResult":
        d = src_dict.copy()
        resultcount = d.pop("resultcount", None)
        type = d.pop("type", None)
        version = d.pop("version", None)
        results = []
        _results = d.pop("results", None)
        for results_item_data in _results or []:
            results_item = PackageDetailed.from_dict(results_item_data)
            results.append(results_item)
        info_result = cls(
            resultcount=resultcount,
            type=type,
            version=version,
            results=results,
        )
        info_result.additional_properties = d
        return info_result


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

        aur_results = info_multiple([lp.name for lp in aur_candidates]).results or []
        aur_map = {ap.name: ap for ap in aur_results}

        for lp in aur_candidates:
            ap = aur_map.get(lp.name)
            if ap is None:
                print("{:20s} {}".format(f"non - {ldb.name}", lp.name))
            elif ap.version and pyalpm.vercmp(lp.version, ap.version) < 0:
                print_package_update("aur", ldb.name, lp.name, ap.version, lp.version)

        print("")


if __name__ == "__main__":
    main()
