from __future__ import annotations

import importlib.util
import json
import tempfile
import unittest
from pathlib import Path


MODULE_PATH = Path(__file__).resolve().parents[1] / "scripts" / "forge.py"
SPEC = importlib.util.spec_from_file_location("forge", MODULE_PATH)
forge = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(forge)


class ForgeRegistryTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name) / "Projects"
        self.state = self.root / ".forge"
        self.seed = Path(self.temp.name) / "seed"
        self.root.mkdir()
        self.seed.mkdir()
        (self.seed / "territories.yaml").write_text(
            json.dumps(
                {
                    "schema": "forge-territories/v0",
                    "territories": [
                        {
                            "id": "forge",
                            "root": str(self.root),
                            "mode": "project_local",
                            "canonical_docs": "in_place",
                        }
                    ],
                }
            )
        )
        (self.seed / "aliases.yaml").write_text(
            json.dumps(
                {
                    "schema": "forge-aliases/v0",
                    "groups": {
                        "bikepark": {
                            "aliases": ["bikepark", "bpts"],
                            "default": "work/bikepark",
                            "members": {
                                "api": {
                                    "aliases": ["bikepark api", "bikepark backend"],
                                    "path": "work/bikepark/api",
                                },
                                "app": {
                                    "aliases": ["bikepark app", "bikepark frontend"],
                                    "path": "work/bikepark/app",
                                },
                            },
                        }
                    },
                }
            )
        )
        (self.seed / "README.md").write_text("fixture")

    def tearDown(self) -> None:
        self.temp.cleanup()

    def make_project(self, relative: str, markers: tuple[str, ...] = ("README.md",)) -> Path:
        path = self.root / relative
        path.mkdir(parents=True)
        for marker in markers:
            marker_path = path / marker
            if marker == ".git":
                marker_path.mkdir()
            else:
                marker_path.write_text("fixture")
        return path.resolve()

    def test_discovery_includes_marker_projects_and_nested_git_roots(self) -> None:
        group = self.make_project("work/bikepark", ("README.md",))
        api = self.make_project("work/bikepark/api", (".git", "go.mod"))
        rows = forge.discover_projects(self.root)
        paths = {Path(row["path"]) for row in rows}
        self.assertIn(group, paths)
        self.assertIn(api, paths)

    def test_discovery_excludes_generated_dependency_repositories(self) -> None:
        real = self.make_project("work/notes-cli", (".git", "Package.swift"))
        checkout = self.make_project(
            "work/notes-cli/.build/checkouts/GRDB.swift", (".git", "Package.swift")
        )
        rows = forge.discover_projects(self.root)
        paths = {Path(row["path"]) for row in rows}
        self.assertIn(real, paths)
        self.assertNotIn(checkout, paths)

    def test_scan_initializes_manual_files_once_and_refreshes_generated_only(self) -> None:
        self.make_project("work/fathom", (".git", "README.md"))
        forge.scan(self.root, self.state, self.seed)
        aliases = self.state / "aliases.yaml"
        payload = json.loads(aliases.read_text())
        payload["groups"]["bikepark"]["aliases"].append("my bike project")
        aliases.write_text(json.dumps(payload))

        self.make_project("work/new-project", ("pyproject.toml",))
        forge.scan(self.root, self.state, self.seed)

        self.assertIn("my bike project", json.loads(aliases.read_text())["groups"]["bikepark"]["aliases"])
        generated = json.loads((self.state / "projects.generated.json").read_text())
        self.assertIn(
            str((self.root / "work/new-project").resolve()),
            {row["path"] for row in generated["projects"]},
        )

    def test_resolve_handles_clear_task_phrases(self) -> None:
        self.make_project("work/bikepark", ("README.md",))
        api = self.make_project("work/bikepark/api", (".git", "go.mod"))
        self.make_project("work/bikepark/app", (".git", "package.json"))
        brain = self.make_project("work/brain", (".git", "README.md"))
        forge.scan(self.root, self.state, self.seed)

        result = forge.resolve("Arbeite an der Bikepark API", self.state)
        self.assertEqual("resolved", result["status"])
        self.assertEqual(str(api), result["path"])
        german = forge.resolve("Öffne das Brain Projekt", self.state)
        self.assertEqual("resolved", german["status"])
        self.assertEqual(str(brain), german["path"])
        group = forge.resolve("Starte einen Task für Bikepark", self.state)
        self.assertEqual("resolved", group["status"])
        self.assertEqual(str((self.root / "work/bikepark").resolve()), group["path"])

    def test_resolve_refuses_unknown_qualifier_and_broad_name(self) -> None:
        self.make_project("work/bikepark", ("README.md",))
        self.make_project("work/bikepark/api", (".git", "go.mod"))
        self.make_project("work/bikepark/app", (".git", "package.json"))
        forge.scan(self.root, self.state, self.seed)

        unknown = forge.resolve("Öffne Bikepark payments xyz", self.state)
        broad = forge.resolve("Öffne die Website", self.state)
        self.assertNotEqual("resolved", unknown["status"])
        self.assertNotEqual("resolved", broad["status"])

    def test_resolve_refuses_ambiguous_generated_project_name(self) -> None:
        self.make_project("work/timo-pankau", (".git", "README.md"))
        self.make_project("work/timo-pankau-astro", (".git", "README.md"))
        forge.scan(self.root, self.state, self.seed)

        result = forge.resolve("Mach bei Timo weiter", self.state)
        self.assertEqual("ambiguous", result["status"])
        self.assertGreaterEqual(len(result["candidates"]), 2)

    def test_generated_exact_name_does_not_hide_related_ambiguity(self) -> None:
        self.make_project("work/ehrax.dev", (".git", "README.md"))
        threejs = self.make_project("work/ehrax.dev-threejs", (".git", "README.md"))
        forge.scan(self.root, self.state, self.seed)

        result = forge.resolve("Mach bei Ehrax dev weiter", self.state)
        self.assertEqual("ambiguous", result["status"])
        self.assertGreaterEqual(len(result["candidates"]), 2)
        specific = forge.resolve("Mach bei Ehrax dev ThreeJS weiter", self.state)
        self.assertEqual("resolved", specific["status"])
        self.assertEqual(str(threejs), specific["path"])

    def test_alias_target_cannot_escape_forge_root(self) -> None:
        self.make_project("work/bikepark", ("README.md",))
        outside = Path(self.temp.name) / "outside"
        outside.mkdir()
        aliases = json.loads((self.seed / "aliases.yaml").read_text())
        aliases["groups"]["escape"] = {
            "aliases": ["escape"],
            "default": "../outside",
            "members": {},
        }
        (self.seed / "aliases.yaml").write_text(json.dumps(aliases))
        forge.scan(self.root, self.state, self.seed)

        with self.assertRaises(forge.ForgeError):
            forge.resolve("escape", self.state)

    def test_territory_contract_must_match_runtime_root(self) -> None:
        contract = json.loads((self.seed / "territories.yaml").read_text())
        contract["territories"][0]["root"] = str(Path(self.temp.name) / "other")
        (self.seed / "territories.yaml").write_text(json.dumps(contract))
        self.make_project("work/fathom", (".git", "README.md"))

        with self.assertRaises(forge.ForgeError):
            forge.scan(self.root, self.state, self.seed)

    def test_generated_project_path_must_match_safe_relative_path(self) -> None:
        self.make_project("work/fathom", (".git", "README.md"))
        outside = Path(self.temp.name) / "outside"
        outside.mkdir()
        forge.scan(self.root, self.state, self.seed)

        generated_path = self.state / "projects.generated.json"
        generated = json.loads(generated_path.read_text())
        generated["projects"][0]["path"] = str(outside.resolve())
        generated_path.write_text(json.dumps(generated))

        with self.assertRaises(forge.ForgeError):
            forge.resolve("fathom", self.state)


if __name__ == "__main__":
    unittest.main()
