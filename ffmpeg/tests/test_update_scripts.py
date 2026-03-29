import unittest
from unittest.mock import patch, MagicMock
import subprocess
import sys
import os

# Add the directory containing update_scripts.py to sys.path and import it if available
try:
    sys.path.append(os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'patches', 'svt-av1-essential', 'util'))
    from update_scripts import run_command, get_git_default_branch
except ModuleNotFoundError:
    raise unittest.SkipTest("update_scripts.py not available; skipping update_scripts tests")
class TestUpdateScripts(unittest.TestCase):
    @patch('subprocess.run')
    def test_run_command_success(self, mock_run):
        # Mock successful execution
        mock_result = MagicMock()
        mock_result.stdout = "  success output  \n"
        mock_run.return_value = mock_result

        result = run_command(['echo', 'test'])

        self.assertEqual(result, "success output")
        mock_run.assert_called_once_with(
            ['echo', 'test'],
            cwd=None,
            capture_output=True,
            text=True,
            check=True
        )

    @patch('subprocess.run')
    def test_run_command_error(self, mock_run):
        # Mock CalledProcessError
        mock_run.side_effect = subprocess.CalledProcessError(
            returncode=1,
            cmd=['false']
        )

        # We expect it to return None and print an error message
        with patch('builtins.print') as mock_print:
            result = run_command(['false'])
            self.assertIsNone(result)
            mock_print.assert_called()

    @patch('update_scripts.run_command')
    def test_get_git_default_branch_success(self, mock_run_command):
        # Mock git remote show output
        mock_run_command.return_value = """* remote origin
  Fetch URL: https://github.com/example/repo.git
  Push  URL: https://github.com/example/repo.git
  HEAD branch: main
  Remote branches:
    main tracked
  Local branch configured for 'git pull':
    main merges with remote main
  Local ref configured for 'git push':
    main pushes to main (up to date)
"""
        result = get_git_default_branch('https://github.com/example/repo.git')
        self.assertEqual(result, "main")
        mock_run_command.assert_called_once_with(
            ['git', 'remote', 'show', 'https://github.com/example/repo.git']
        )

    @patch('update_scripts.run_command')
    def test_get_git_default_branch_not_found(self, mock_run_command):
        # Mock output without HEAD branch
        mock_run_command.return_value = "some other output"
        result = get_git_default_branch('https://github.com/example/repo.git')
        self.assertIsNone(result)

    @patch('update_scripts.run_command')
    def test_get_git_default_branch_exception(self, mock_run_command):
        # Mock exception in run_command (though run_command itself catches subprocess errors)
        mock_run_command.side_effect = Exception("Unexpected error")
        with patch('builtins.print') as mock_print:
            result = get_git_default_branch('https://github.com/example/repo.git')
            self.assertIsNone(result)
            mock_print.assert_called()

if __name__ == '__main__':
    unittest.main()
