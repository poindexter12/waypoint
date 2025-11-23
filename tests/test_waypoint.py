#!/usr/bin/env python3
"""
Waypoint Test Suite

Tests the Makefile-based installation system for all modules.
Validates installation, uninstallation, checking, and fixing operations
in both symlink and copy modes.
"""

import os
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


class Colors:
    """ANSI color codes for terminal output."""
    BLUE = '\033[0;34m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[0;33m'
    RED = '\033[0;31m'
    NC = '\033[0m'


class WaypointTestCase(unittest.TestCase):
    """Base test case with common setup and utilities."""

    @classmethod
    def setUpClass(cls):
        """Set up test environment."""
        cls.repo_root = Path(__file__).parent.parent.resolve()
        cls.test_base_dir = Path(tempfile.gettempdir()) / 'waypoint-tests'
        cls.modules = ['working-tree']

    def setUp(self):
        """Create fresh test directory for each test."""
        # Clean up any previous test runs
        if self.test_base_dir.exists():
            shutil.rmtree(self.test_base_dir)
        self.test_base_dir.mkdir(parents=True)

        # Create a unique test directory for this test
        self.test_dir = self.test_base_dir / f'test-{self.id().split(".")[-1]}'
        self.test_dir.mkdir()

    def tearDown(self):
        """Clean up test directory after each test."""
        if self.test_dir.exists():
            shutil.rmtree(self.test_dir)

    @classmethod
    def tearDownClass(cls):
        """Final cleanup of test base directory."""
        if cls.test_base_dir.exists():
            shutil.rmtree(cls.test_base_dir)

    def run_make(self, target, module=None, **kwargs):
        """
        Run make command with given target and options.

        Args:
            target: Make target to run (e.g., 'install', 'check')
            module: Optional module name for module-specific operations
            **kwargs: Additional arguments like CLAUDE_DIR, MODE

        Returns:
            CompletedProcess with stdout, stderr, returncode
        """
        cmd = ['make', target]

        # Add module name if specified
        if module:
            cmd.append(module)

        # Add keyword arguments as make variables
        for key, value in kwargs.items():
            cmd.append(f'{key}={value}')

        result = subprocess.run(
            cmd,
            cwd=self.repo_root,
            capture_output=True,
            text=True
        )

        return result

    def assert_file_exists(self, path, msg=None):
        """Assert that a file exists."""
        self.assertTrue(Path(path).exists(), msg or f"File does not exist: {path}")

    def assert_file_not_exists(self, path, msg=None):
        """Assert that a file does not exist."""
        self.assertFalse(Path(path).exists(), msg or f"File should not exist: {path}")

    def assert_is_symlink(self, path, msg=None):
        """Assert that a path is a symbolic link."""
        self.assertTrue(Path(path).is_symlink(), msg or f"Path is not a symlink: {path}")

    def assert_is_not_symlink(self, path, msg=None):
        """Assert that a path is not a symbolic link."""
        self.assertFalse(Path(path).is_symlink(), msg or f"Path should not be a symlink: {path}")


class TestHelp(WaypointTestCase):
    """Test help and informational commands."""

    def test_help_command(self):
        """Test that 'make help' runs successfully."""
        result = self.run_make('help')
        self.assertEqual(result.returncode, 0, "make help should succeed")
        self.assertIn('Waypoint', result.stdout, "Help should contain project name")
        self.assertIn('install', result.stdout, "Help should list install target")

    def test_list_command(self):
        """Test that 'make list' shows what would be installed."""
        result = self.run_make('list', CLAUDE_DIR=str(self.test_dir))
        self.assertEqual(result.returncode, 0, "make list should succeed")
        self.assertIn('working-tree', result.stdout, "List should show working-tree module")
        self.assertIn('manager.md', result.stdout, "List should show agent files")
        self.assertIn('new.md', result.stdout, "List should show command files")


class TestSymlinkInstallation(WaypointTestCase):
    """Test symlink mode installation (default)."""

    def test_install_all_modules(self):
        """Test installing all modules in symlink mode."""
        result = self.run_make('install', CLAUDE_DIR=str(self.test_dir))
        self.assertEqual(result.returncode, 0, "Installation should succeed")

        # Check agents directory
        agents_dir = self.test_dir / 'agents' / 'working-tree'
        self.assert_file_exists(agents_dir, "Agents directory should be created")

        # Check agent file
        manager = agents_dir / 'manager.md'
        self.assert_file_exists(manager, "Agent file should exist")
        self.assert_is_symlink(manager, "Agent file should be a symlink")

        # Check commands directory
        commands_dir = self.test_dir / 'commands' / 'working-tree'
        self.assert_file_exists(commands_dir, "Commands directory should be created")

        # Check command files
        for cmd in ['new.md', 'status.md', 'list.md', 'destroy.md', 'adopt.md']:
            cmd_file = commands_dir / cmd
            self.assert_file_exists(cmd_file, f"Command {cmd} should exist")
            self.assert_is_symlink(cmd_file, f"Command {cmd} should be a symlink")

    def test_install_specific_module(self):
        """Test installing a specific module."""
        result = self.run_make('install', module='working-tree', CLAUDE_DIR=str(self.test_dir))
        self.assertEqual(result.returncode, 0, "Module-specific installation should succeed")

        # Verify installation
        self.assert_file_exists(
            self.test_dir / 'agents' / 'working-tree' / 'manager.md',
            "Module should be installed"
        )

    def test_symlink_targets_correct(self):
        """Test that symlinks point to the correct source files."""
        self.run_make('install', CLAUDE_DIR=str(self.test_dir))

        # Check agent symlink target
        manager = self.test_dir / 'agents' / 'working-tree' / 'manager.md'
        expected_target = self.repo_root / 'working-tree' / 'agents' / 'manager.md'
        actual_target = Path(os.readlink(manager))
        self.assertEqual(
            actual_target,
            expected_target,
            f"Symlink should point to {expected_target}"
        )


class TestCopyInstallation(WaypointTestCase):
    """Test copy mode installation."""

    def test_install_copy_mode(self):
        """Test installing with MODE=copy."""
        result = self.run_make('install', CLAUDE_DIR=str(self.test_dir), MODE='copy')
        self.assertEqual(result.returncode, 0, "Copy mode installation should succeed")

        # Check that files exist but are not symlinks
        manager = self.test_dir / 'agents' / 'working-tree' / 'manager.md'
        self.assert_file_exists(manager, "Agent file should exist")
        self.assert_is_not_symlink(manager, "Agent file should NOT be a symlink in copy mode")

        # Check command files
        new_cmd = self.test_dir / 'commands' / 'working-tree' / 'new.md'
        self.assert_file_exists(new_cmd, "Command file should exist")
        self.assert_is_not_symlink(new_cmd, "Command file should NOT be a symlink in copy mode")

    def test_copy_mode_file_contents(self):
        """Test that copied files have the same content as source."""
        self.run_make('install', CLAUDE_DIR=str(self.test_dir), MODE='copy')

        # Compare file contents
        src_file = self.repo_root / 'working-tree' / 'agents' / 'manager.md'
        dst_file = self.test_dir / 'agents' / 'working-tree' / 'manager.md'

        with open(src_file, 'r') as f:
            src_content = f.read()
        with open(dst_file, 'r') as f:
            dst_content = f.read()

        self.assertEqual(src_content, dst_content, "Copied file should have same content as source")


class TestCheck(WaypointTestCase):
    """Test the check command."""

    def test_check_valid_installation(self):
        """Test check on a valid installation."""
        # Install first
        self.run_make('install', CLAUDE_DIR=str(self.test_dir))

        # Run check
        result = self.run_make('check', CLAUDE_DIR=str(self.test_dir))
        self.assertEqual(result.returncode, 0, "Check should succeed on valid installation")
        self.assertIn('✓', result.stdout, "Check should show success markers")
        self.assertNotIn('✗', result.stdout, "Check should not show failure markers")

    def test_check_missing_installation(self):
        """Test check on a missing installation."""
        result = self.run_make('check', CLAUDE_DIR=str(self.test_dir))
        self.assertIn('✗', result.stdout, "Check should show failure markers for missing files")

    def test_check_broken_symlink(self):
        """Test check detects broken symlinks."""
        # Install first
        self.run_make('install', CLAUDE_DIR=str(self.test_dir))

        # Break a symlink by removing the target
        manager = self.test_dir / 'agents' / 'working-tree' / 'manager.md'
        manager.unlink()
        manager.symlink_to('/nonexistent/file.md')

        # Run check
        result = self.run_make('check', CLAUDE_DIR=str(self.test_dir))
        self.assertIn('✗', result.stdout, "Check should detect broken symlink")


class TestUninstall(WaypointTestCase):
    """Test the uninstall command."""

    def test_uninstall_removes_all_files(self):
        """Test that uninstall removes all installed files."""
        # Install first
        self.run_make('install', CLAUDE_DIR=str(self.test_dir))

        # Verify installation
        self.assert_file_exists(self.test_dir / 'agents' / 'working-tree')

        # Uninstall
        result = self.run_make('uninstall', CLAUDE_DIR=str(self.test_dir))
        self.assertEqual(result.returncode, 0, "Uninstall should succeed")

        # Verify removal
        self.assert_file_not_exists(
            self.test_dir / 'agents' / 'working-tree',
            "Module directory should be removed"
        )
        self.assert_file_not_exists(
            self.test_dir / 'commands' / 'working-tree',
            "Module directory should be removed"
        )

    def test_uninstall_specific_module(self):
        """Test uninstalling a specific module."""
        # Install
        self.run_make('install', CLAUDE_DIR=str(self.test_dir))

        # Uninstall specific module
        result = self.run_make('uninstall', module='working-tree', CLAUDE_DIR=str(self.test_dir))
        self.assertEqual(result.returncode, 0, "Module-specific uninstall should succeed")

        # Verify removal
        self.assert_file_not_exists(
            self.test_dir / 'agents' / 'working-tree',
            "Module should be removed"
        )

    def test_uninstall_idempotent(self):
        """Test that uninstall can be run multiple times safely."""
        self.run_make('install', CLAUDE_DIR=str(self.test_dir))

        # First uninstall
        result1 = self.run_make('uninstall', CLAUDE_DIR=str(self.test_dir))
        self.assertEqual(result1.returncode, 0, "First uninstall should succeed")

        # Second uninstall (nothing to remove)
        result2 = self.run_make('uninstall', CLAUDE_DIR=str(self.test_dir))
        self.assertEqual(result2.returncode, 0, "Second uninstall should succeed")


class TestFix(WaypointTestCase):
    """Test the fix command."""

    def test_fix_repairs_missing_files(self):
        """Test that fix repairs missing files."""
        # Install first
        self.run_make('install', CLAUDE_DIR=str(self.test_dir))

        # Remove a file
        manager = self.test_dir / 'agents' / 'working-tree' / 'manager.md'
        manager.unlink()

        # Verify it's missing
        self.assert_file_not_exists(manager)

        # Run fix
        result = self.run_make('fix', CLAUDE_DIR=str(self.test_dir))
        self.assertEqual(result.returncode, 0, "Fix should succeed")

        # Verify file is restored
        self.assert_file_exists(manager, "Fix should restore missing file")

    def test_fix_repairs_broken_symlinks(self):
        """Test that fix repairs broken symlinks."""
        # Install first
        self.run_make('install', CLAUDE_DIR=str(self.test_dir))

        # Break a symlink
        manager = self.test_dir / 'agents' / 'working-tree' / 'manager.md'
        manager.unlink()
        manager.symlink_to('/nonexistent/file.md')

        # Run fix
        result = self.run_make('fix', CLAUDE_DIR=str(self.test_dir))
        self.assertEqual(result.returncode, 0, "Fix should succeed")

        # Verify symlink is correct now
        expected_target = self.repo_root / 'working-tree' / 'agents' / 'manager.md'
        actual_target = Path(os.readlink(manager))
        self.assertEqual(actual_target, expected_target, "Fix should repair symlink target")


class TestClean(WaypointTestCase):
    """Test the clean command."""

    def test_clean_command(self):
        """Test that clean command runs successfully."""
        result = self.run_make('clean')
        self.assertEqual(result.returncode, 0, "Clean should succeed")


def run_tests(verbosity=2):
    """Run all tests with specified verbosity."""
    loader = unittest.TestLoader()
    suite = loader.loadTestsFromModule(sys.modules[__name__])
    runner = unittest.TextTestRunner(verbosity=verbosity)
    result = runner.run(suite)
    return result.wasSuccessful()


def main():
    """Main entry point for test suite."""
    print(f"{Colors.BLUE}{'=' * 70}{Colors.NC}")
    print(f"{Colors.BLUE}Waypoint Test Suite{Colors.NC}")
    print(f"{Colors.BLUE}{'=' * 70}{Colors.NC}\n")

    success = run_tests()

    print(f"\n{Colors.BLUE}{'=' * 70}{Colors.NC}")
    if success:
        print(f"{Colors.GREEN}✓ All tests passed{Colors.NC}")
        sys.exit(0)
    else:
        print(f"{Colors.RED}✗ Some tests failed{Colors.NC}")
        sys.exit(1)


if __name__ == '__main__':
    main()
