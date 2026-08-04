#!/usr/bin/env python3
"""Discover and resolve projects under ~/Projects (internally: Forge).

The scanner owns only projects.generated.json. Humans own aliases.yaml.
Both .yaml files intentionally use the JSON subset of YAML so the tool stays
stdlib-only on a fresh macOS Python installation.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import unicodedata
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, Iterable, List, Optional, Set


SCHEMA = "forge-registry/v0"
DEFAULT_ROOT = Path.home() / "Projects"
DEFAULT_STATE_NAME = ".forge"
SEED_DIRECTORY = Path(__file__).resolve().parents[1] / "configs" / "forge"

EXCLUDED_DIRECTORIES = frozenset(
    {
        ".build",
        ".cache",
        ".git",
        ".next",
        ".turbo",
        ".worktrees",
        "Pods",
        "build",
        "dist",
        "node_modules",
        "runs",
        "target",
        "vendor",
    }
)
PROJECT_MARKERS = frozenset(
    {
        ".git",
        "AGENTS.md",
        "Cargo.toml",
        "Gemfile",
        "Makefile",
        "Package.swift",
        "README.md",
        "go.mod",
        "package.json",
        "pyproject.toml",
    }
)
DOC_CANDIDATES = ("AGENTS.md", "README.md", "docs", "research")
TASK_WORDS = frozenset(
    """
    an am arbeite arbeiten bei das den der die ein eine einen fuer fur für in
    mal mach mache machen meine mit offne öffne oeffne projekt prufe prüfe
    pruefe render starte starten task teste testen unseren weiter zu fix
    continue do for in open project render start task test the work
    """.split()
)


class ForgeError(RuntimeError):
    pass


def _read_json(path: Path) -> dict:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except OSError as error:
        raise ForgeError("cannot read {}: {}".format(path, error))
    except json.JSONDecodeError as error:
        raise ForgeError(
            "{} must use the JSON-compatible subset of YAML: {}".format(path, error)
        )
    if not isinstance(value, dict):
        raise ForgeError("{} must contain one object".format(path))
    return value


def _write_json_atomic(path: Path, value: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(".{}.tmp-{}".format(path.name, os.getpid()))
    temporary.write_text(
        json.dumps(value, ensure_ascii=False, indent=2, sort_keys=False) + "\n",
        encoding="utf-8",
    )
    temporary.replace(path)


def _has_project_marker(path: Path) -> bool:
    return any((path / marker).exists() for marker in PROJECT_MARKERS)


def _remote_for(path: Path) -> Optional[str]:
    try:
        result = subprocess.run(
            ["git", "-C", str(path), "remote", "get-url", "origin"],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            timeout=2,
            check=False,
        )
    except (OSError, subprocess.SubprocessError):
        return None
    value = result.stdout.strip()
    return value or None


def _docs_for(path: Path) -> List[str]:
    return [candidate for candidate in DOC_CANDIDATES if (path / candidate).exists()]


def discover_projects(root: Path) -> List[dict]:
    root = root.expanduser().resolve()
    if not root.is_dir():
        raise ForgeError("Forge root does not exist: {}".format(root))

    candidates: Dict[Path, Set[str]] = {}

    # Namespace children are intentional project candidates, including useful
    # non-Git directories such as a Remotion project or a multi-repo group.
    for namespace in sorted(
        path for path in root.iterdir() if path.is_dir() and not path.name.startswith(".")
    ):
        for child in sorted(
            path
            for path in namespace.iterdir()
            if path.is_dir() and path.name not in EXCLUDED_DIRECTORIES
        ):
            if _has_project_marker(child):
                candidates.setdefault(child, set()).add("namespace_child")

    # Nested repositories (for example Bikepark app/API) are first-class, but
    # dependency/build trees are pruned before traversal.
    for current, directories, files in os.walk(str(root)):
        has_git_marker = ".git" in directories or ".git" in files
        directories[:] = [
            name
            for name in directories
            if name not in EXCLUDED_DIRECTORIES
        ]
        path = Path(current)
        if has_git_marker and path != root:
            candidates.setdefault(path, set()).add("git_root")

    projects = []
    for path, discovery in sorted(candidates.items(), key=lambda item: str(item[0])):
        relative = path.relative_to(root).as_posix()
        projects.append(
            {
                "id": relative.replace("/", "--"),
                "name": path.name,
                "path": str(path),
                "relative_path": relative,
                "namespace": relative.split("/", 1)[0],
                "git": (path / ".git").exists(),
                "remote": _remote_for(path),
                "docs": _docs_for(path),
                "discovery": sorted(discovery),
            }
        )
    return projects


def _initialize_manual_state(state: Path, seed: Path) -> None:
    state.mkdir(parents=True, exist_ok=True)
    for name in ("territories.yaml", "aliases.yaml", "README.md"):
        source = seed / name
        destination = state / name
        if not source.is_file():
            raise ForgeError("missing Forge seed file: {}".format(source))
        if not destination.exists():
            shutil.copyfile(str(source), str(destination))


def _validate_territory_contract(state: Path, root: Path) -> dict:
    contract = _read_json(state / "territories.yaml")
    territories = contract.get("territories")
    if not isinstance(territories, list):
        raise ForgeError("territories.yaml requires a 'territories' array")
    matches = [
        territory
        for territory in territories
        if isinstance(territory, dict) and territory.get("id") == "forge"
    ]
    if len(matches) != 1:
        raise ForgeError("territories.yaml requires exactly one Forge territory")
    forge = matches[0]
    declared_root = forge.get("root")
    if not isinstance(declared_root, str):
        raise ForgeError("Forge territory requires a string root")
    resolved_declared_root = Path(declared_root).expanduser().resolve()
    if resolved_declared_root != root.resolve():
        raise ForgeError(
            "Forge root mismatch: runtime {} != contract {}".format(
                root.resolve(), resolved_declared_root
            )
        )
    if forge.get("mode") != "project_local":
        raise ForgeError("Forge territory mode must be 'project_local'")
    if forge.get("canonical_docs") != "in_place":
        raise ForgeError("Forge canonical_docs must be 'in_place'")
    return forge


def scan(root: Path, state: Path, seed: Path = SEED_DIRECTORY) -> dict:
    root = root.expanduser().resolve()
    state = state.expanduser().resolve()
    seed = seed.expanduser().resolve()
    _initialize_manual_state(state, seed)
    _validate_territory_contract(state, root)
    projects = discover_projects(root)
    result = {
        "schema": SCHEMA,
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "root": str(root),
        "excludes": sorted(EXCLUDED_DIRECTORIES),
        "projects": projects,
    }
    try:
        _write_json_atomic(state / "projects.generated.json", result)
    except OSError:
        # A sandboxed caller (e.g. `kosmos sync` inside a session workspace)
        # may not be allowed to refresh the cache. Resolving must still work
        # from the registry that already exists on disk, so a failed cache
        # write is only fatal when there is no registry at all.
        if not (state / "projects.generated.json").exists():
            raise
    return result


def normalize(value: str) -> str:
    decomposed = unicodedata.normalize("NFKD", value.lower())
    plain = "".join(character for character in decomposed if not unicodedata.combining(character))
    return " ".join(re.findall(r"[a-z0-9]+", plain))


def _project_phrase(query: str) -> str:
    return " ".join(token for token in normalize(query).split() if token not in TASK_WORDS)


def _name_forms(value: str) -> Set[str]:
    normalized = normalize(value)
    return {normalized, normalized.replace(" ", "")}


def _row_extends_phrase(row: dict, phrase: str) -> bool:
    prefix = phrase + " "
    return any(
        normalize(name).startswith(prefix)
        for name in row["names"]
        if isinstance(name, str)
    )


def _alias_target(root: Path, relative: str, label: str) -> Path:
    raw = Path(relative).expanduser()
    if raw.is_absolute():
        raise ForgeError("{} must be relative to Forge, got {}".format(label, relative))
    target = (root / raw).resolve()
    try:
        target.relative_to(root.resolve())
    except ValueError:
        raise ForgeError("{} escapes Forge root: {}".format(label, relative))
    return target


def _alias_rows(aliases: dict, root: Path) -> Iterable[dict]:
    groups = aliases.get("groups")
    if not isinstance(groups, dict):
        raise ForgeError("aliases.yaml requires a 'groups' object")
    for group_id, group in groups.items():
        if not isinstance(group, dict):
            raise ForgeError("alias group {!r} is not an object".format(group_id))
        default = group.get("default")
        names = group.get("aliases", [])
        if not isinstance(default, str) or not isinstance(names, list):
            raise ForgeError("alias group {!r} has invalid default/aliases".format(group_id))
        yield {
            "id": group_id,
            "path": str(_alias_target(root, default, "alias group {!r}".format(group_id))),
            "names": names,
            "source": "alias",
        }
        members = group.get("members", {})
        if not isinstance(members, dict):
            raise ForgeError("alias group {!r} has invalid members".format(group_id))
        for member_id, member in members.items():
            if not isinstance(member, dict):
                raise ForgeError("alias member {!r} is not an object".format(member_id))
            relative = member.get("path")
            member_names = member.get("aliases", [])
            if not isinstance(relative, str) or not isinstance(member_names, list):
                raise ForgeError("alias member {!r} has invalid path/aliases".format(member_id))
            yield {
                "id": "{}:{}".format(group_id, member_id),
                "path": str(
                    _alias_target(
                        root,
                        relative,
                        "alias member {!r}:{!r}".format(group_id, member_id),
                    )
                ),
                "names": member_names,
                "source": "alias",
            }


def _resolution_rows(state: Path) -> List[dict]:
    generated = _read_json(state / "projects.generated.json")
    aliases = _read_json(state / "aliases.yaml")
    root_value = generated.get("root")
    projects = generated.get("projects")
    if not isinstance(root_value, str) or not isinstance(projects, list):
        raise ForgeError("projects.generated.json has an invalid root/projects contract")
    root = Path(root_value).expanduser().resolve()
    _validate_territory_contract(state, root)
    rows = []
    for project in projects:
        if not isinstance(project, dict):
            continue
        path = project.get("path")
        name = project.get("name")
        project_id = project.get("id")
        relative = project.get("relative_path")
        if not all(isinstance(value, str) for value in (path, name, project_id, relative)):
            continue
        safe_path = _alias_target(
            root, relative, "generated project {!r}".format(project_id)
        )
        stored_path = Path(path).expanduser().resolve()
        if stored_path != safe_path:
            raise ForgeError(
                "generated project {!r} path mismatch: {} != {}".format(
                    project_id, stored_path, safe_path
                )
            )
        rows.append(
            {
                "id": project_id,
                "path": str(safe_path),
                "names": [name, name.replace("-", " ").replace("_", " "), relative],
                "source": "generated",
            }
        )
    rows.extend(_alias_rows(aliases, root))
    return rows


def resolve(query: str, state: Path) -> dict:
    phrase = _project_phrase(query)
    compact = phrase.replace(" ", "")
    if not phrase:
        return {"status": "not_found", "query": query, "phrase": phrase, "candidates": []}

    rows = _resolution_rows(state)
    exact: Dict[str, dict] = {}
    fuzzy: Dict[str, dict] = {}
    phrase_tokens = set(phrase.split())

    for row in rows:
        forms: Set[str] = set()
        for name in row["names"]:
            if isinstance(name, str):
                forms.update(_name_forms(name))
        if phrase in forms or compact in forms:
            exact[row["path"]] = row
            continue
        for form in forms:
            tokens = set(form.split())
            if phrase in form or form in phrase or (phrase_tokens and phrase_tokens <= tokens):
                fuzzy[row["path"]] = row
                break

    if len(exact) == 1:
        row = next(iter(exact.values()))
        related = {
            path: candidate
            for path, candidate in fuzzy.items()
            if path != row["path"] and _row_extends_phrase(candidate, phrase)
        }
        if row["source"] == "generated" and related:
            candidates = [row] + sorted(
                related.values(), key=lambda candidate: (candidate["path"], candidate["id"])
            )
            return {
                "status": "ambiguous",
                "query": query,
                "phrase": phrase,
                "candidates": candidates,
            }
        if not Path(row["path"]).exists():
            return {
                "status": "invalid_registry",
                "query": query,
                "phrase": phrase,
                "path": row["path"],
                "candidates": [row],
            }
        return {
            "status": "resolved",
            "query": query,
            "phrase": phrase,
            "path": row["path"],
            "id": row["id"],
            "source": row["source"],
            "candidates": [row],
        }
    if len(exact) > 1:
        candidates = sorted(exact.values(), key=lambda row: (row["path"], row["id"]))
        return {
            "status": "ambiguous",
            "query": query,
            "phrase": phrase,
            "candidates": candidates,
        }

    candidates = sorted(fuzzy.values(), key=lambda row: (row["path"], row["id"]))
    return {
        "status": "ambiguous" if len(candidates) > 1 else "not_found",
        "query": query,
        "phrase": phrase,
        "candidates": candidates,
    }


def doctor(root: Path, state: Path) -> dict:
    _validate_territory_contract(state, root.resolve())
    generated = _read_json(state / "projects.generated.json")
    aliases = _read_json(state / "aliases.yaml")
    _resolution_rows(state)
    rows = list(_alias_rows(aliases, root.resolve()))
    missing = sorted({row["path"] for row in rows if not Path(row["path"]).exists()})
    return {
        "status": "ok" if not missing else "warning",
        "projects": len(generated.get("projects", [])),
        "alias_targets": len(rows),
        "missing_alias_targets": missing,
    }


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=DEFAULT_ROOT)
    parser.add_argument("--state", type=Path)
    subparsers = parser.add_subparsers(dest="command", required=True)
    subparsers.add_parser("scan")
    resolve_parser = subparsers.add_parser("resolve")
    resolve_parser.add_argument("query")
    resolve_parser.add_argument("--no-refresh", action="store_true")
    subparsers.add_parser("list")
    subparsers.add_parser("doctor")
    return parser


def main(argv: Optional[List[str]] = None) -> int:
    arguments = _parser().parse_args(argv)
    root = arguments.root.expanduser().resolve()
    state = (
        arguments.state.expanduser().resolve()
        if arguments.state
        else root / DEFAULT_STATE_NAME
    )
    try:
        if arguments.command == "scan":
            result = scan(root, state)
        elif arguments.command == "resolve":
            if not arguments.no_refresh or not (state / "projects.generated.json").exists():
                scan(root, state)
            result = resolve(arguments.query, state)
        elif arguments.command == "list":
            if not (state / "projects.generated.json").exists():
                raise ForgeError("registry is missing; run 'forge.py scan' first")
            result = _read_json(state / "projects.generated.json")
        elif arguments.command == "doctor":
            if not (state / "projects.generated.json").exists():
                scan(root, state)
            result = doctor(root, state)
        else:
            raise ForgeError("unknown command: {}".format(arguments.command))
    except ForgeError as error:
        print(json.dumps({"status": "error", "error": str(error)}), file=sys.stderr)
        return 2
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
