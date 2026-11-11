import argparse
import contextlib
import io
import importlib.util
import json
import os
from pathlib import Path
import sys
import tempfile
import unittest
from unittest import mock


SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "classic.py"
SPEC = importlib.util.spec_from_file_location("classic_runner", SCRIPT)
classic = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = classic
SPEC.loader.exec_module(classic)


class ProjectTests(unittest.TestCase):
    def config(self, **changes):
        value = {
            "schemaVersion": 1,
            "application": "Example",
            "runTarget": "powerpc",
            "testTarget": "powerpc-smoke",
            "testTimeoutSeconds": 30,
        }
        value.update(changes)
        return value

    def load(self, config):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        Path(temporary.name, classic.CONFIG_NAME).write_text(json.dumps(config))
        return classic.Project.load(temporary.name)

    def test_loads_schema_one(self):
        project = self.load(self.config())
        self.assertEqual(project.application, "Example")
        self.assertEqual(project.test_timeout, 30)

    def test_rejects_unknown_schema(self):
        with self.assertRaisesRegex(RuntimeError, "schemaVersion 1"):
            self.load(self.config(schemaVersion=2))

    def test_rejects_path_as_application(self):
        with self.assertRaisesRegex(RuntimeError, "file name"):
            self.load(self.config(application="build/Example"))

    def test_rejects_invalid_target(self):
        with self.assertRaisesRegex(RuntimeError, "Nix attribute"):
            self.load(self.config(testTarget="powerpc smoke"))

    def test_rejects_boolean_timeout(self):
        with self.assertRaisesRegex(RuntimeError, "positive integer"):
            self.load(self.config(testTimeoutSeconds=True))


class TapTests(unittest.TestCase):
    def test_accepts_complete_success(self):
        results = classic.validate_tap("TAP version 13\n1..2\nok 1 - first\nok 2 - second\n")
        self.assertEqual(len(results), 2)

    def test_rejects_failure(self):
        with self.assertRaisesRegex(RuntimeError, "not ok 1"):
            classic.validate_tap("TAP version 13\n1..1\nnot ok 1 - broken\n# details\n")

    def test_rejects_incomplete_plan(self):
        with self.assertRaisesRegex(RuntimeError, "1 of 2"):
            classic.validate_tap("1..2\nok 1 - only\n")


class EnvironmentTests(unittest.TestCase):
    def test_guest_environment_fallback(self):
        with mock.patch.dict(os.environ, {"CLASSIC_MAC_GUEST": "192.0.2.1"}):
            self.assertEqual(classic.selected_guest(argparse.Namespace(guest=None)), "192.0.2.1")


class LaunchTests(unittest.TestCase):
    def test_launch_uses_a_clean_working_directory(self):
        project = classic.Project(Path.cwd(), "Example", "powerpc", "powerpc-smoke", 30)
        for action, target in ((classic.run, "powerpc"), (classic.test, "powerpc-smoke")):
            with self.subTest(action=action.__name__), tempfile.TemporaryDirectory() as scratch:
                args = classic.parser().parse_args([action.__name__, "192.0.2.1"])
                log = Path(scratch, "cwd")
                fake_launcher = Path(scratch, "launch.py")
                fake_launcher.write_text(
                    "from pathlib import Path\n"
                    "import sys\n"
                    "Path(sys.argv[1]).write_text(str(Path.cwd()))\n"
                    "Path('out').write_text('guest output')\n"
                    "if sys.argv[2] == 'test':\n"
                    "    print('1..1\\nok 1 - window')\n"
                )
                command = [sys.executable, str(fake_launcher), str(log), action.__name__]
                stdout = io.StringIO()
                stderr = io.TextIOWrapper(io.BytesIO(), encoding="utf-8")
                with (
                    mock.patch.object(classic, "ensure_vm"),
                    mock.patch.object(classic, "wait_for_guest"),
                    mock.patch.object(classic, "launch_command", return_value=command) as launch,
                    contextlib.redirect_stdout(stdout),
                    contextlib.redirect_stderr(stderr),
                ):
                    self.assertEqual(action(project, args), 0)
                launch.assert_called_once_with(project, target, "192.0.2.1")
                work = Path(log.read_text())
                self.assertNotEqual(work, project.root)
                self.assertFalse(work.exists())


if __name__ == "__main__":
    unittest.main()
