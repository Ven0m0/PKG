import unittest
from unittest.mock import patch, MagicMock, call
import importlib.util
import sys
import os

# Dynamically import profiler.py as instructed by repository memory
script_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'profiler.py'))
spec = importlib.util.spec_from_file_location("profiler", script_path)
profiler = importlib.util.module_from_spec(spec)
sys.modules["profiler"] = profiler
spec.loader.exec_module(profiler)

class TestProfiler(unittest.TestCase):
    @patch('profiler.webdriver.Chrome')
    def test_setup_driver(self, mock_chrome):
        mock_driver = MagicMock()
        mock_chrome.return_value = mock_driver

        driver = profiler.setup_driver()

        mock_chrome.assert_called_once()

        call_args = mock_chrome.call_args
        options = call_args.kwargs.get('options')

        self.assertIsNotNone(options)
        self.assertEqual(options.binary_location, 'out/Release/chrome')

        expected_arguments = [
            "--headless",
            "--no-sandbox",
            "--disable-gpu",
            "--window-size=1920,1080",
            "--disable-dev-shm-usage"
        ]

        for arg in expected_arguments:
            self.assertIn(arg, options.arguments)

        self.assertEqual(driver, mock_driver)

    @patch('profiler.WebDriverWait')
    @patch('profiler.sleep')
    def test_run_speedometer_default(self, mock_sleep, mock_wait):
        mock_driver = MagicMock()
        mock_wait_instance = MagicMock()
        mock_wait.return_value = mock_wait_instance
        mock_start_button = MagicMock()
        mock_wait_instance.until.return_value = mock_start_button

        profiler.run_speedometer(mock_driver)

        mock_driver.get.assert_called_once_with('https://browserbench.org/Speedometer2.0/')
        mock_driver.save_screenshot.assert_called_once_with('speedometer_2.0_start.png')
        mock_wait.assert_called_once_with(mock_driver, 10)
        mock_start_button.click.assert_called_once()
        mock_sleep.assert_called_once_with(60)

    @patch('profiler.WebDriverWait')
    @patch('profiler.sleep')
    def test_run_speedometer_invalid_version(self, mock_sleep, mock_wait):
        mock_driver = MagicMock()

        profiler.run_speedometer(mock_driver, version='3.0')

        mock_driver.get.assert_called_once_with('https://browserbench.org/Speedometer2.0/')
        mock_driver.save_screenshot.assert_called_once_with('speedometer_2.0_start.png')

    @patch('profiler.WebDriverWait')
    @patch('profiler.sleep')
    def test_run_jetstream(self, mock_sleep, mock_wait):
        mock_driver = MagicMock()
        mock_wait_instance = MagicMock()
        mock_wait.return_value = mock_wait_instance
        mock_start_button = MagicMock()
        mock_wait_instance.until.return_value = mock_start_button

        profiler.run_jetstream(mock_driver)

        mock_driver.get.assert_called_once_with('https://browserbench.org/JetStream/')
        mock_driver.save_screenshot.assert_called_once_with('jetstream_start.png')
        mock_wait.assert_called_once_with(mock_driver, 30)
        mock_start_button.click.assert_called_once()
        mock_sleep.assert_called_once_with(60)

    @patch('profiler.WebDriverWait')
    @patch('profiler.sleep')
    def test_run_motionmark(self, mock_sleep, mock_wait):
        mock_driver = MagicMock()
        mock_wait_instance = MagicMock()
        mock_wait.return_value = mock_wait_instance
        mock_start_button = MagicMock()
        mock_wait_instance.until.return_value = mock_start_button

        profiler.run_motionmark(mock_driver)

        mock_driver.get.assert_called_once_with('https://browserbench.org/MotionMark1.3/')
        mock_driver.save_screenshot.assert_called_once_with('motionmark_start.png')
        mock_wait.assert_called_once_with(mock_driver, 30)
        mock_start_button.click.assert_called_once()
        mock_sleep.assert_called_once_with(60)

    @patch('profiler.WebDriverWait')
    @patch('profiler.sleep')
    def test_run_basemark(self, mock_sleep, mock_wait):
        mock_driver = MagicMock()
        mock_wait_instance = MagicMock()
        mock_wait.return_value = mock_wait_instance
        mock_start_button = MagicMock()
        mock_wait_instance.until.return_value = mock_start_button

        profiler.run_basemark(mock_driver)

        mock_driver.get.assert_called_once_with('https://web.basemark.com/run/')
        mock_driver.save_screenshot.assert_called_once_with('basemark_start.png')
        mock_wait.assert_called_once_with(mock_driver, 30)
        mock_start_button.click.assert_called_once()
        mock_sleep.assert_called_once_with(60)

    @patch('profiler.setup_driver')
    @patch('profiler.run_speedometer')
    @patch('profiler.run_jetstream')
    @patch('profiler.run_motionmark')
    @patch('profiler.run_basemark')
    def test_main(self, mock_basemark, mock_motionmark, mock_jetstream, mock_speedometer, mock_setup):
        mock_driver = MagicMock()
        mock_setup.return_value = mock_driver

        profiler.main()

        mock_setup.assert_called_once()
        mock_speedometer.assert_has_calls([call(mock_driver, '2.0'), call(mock_driver, '2.1')])
        mock_jetstream.assert_called_once_with(mock_driver)
        mock_motionmark.assert_called_once_with(mock_driver)
        mock_basemark.assert_called_once_with(mock_driver)
        mock_driver.quit.assert_called_once()

    @patch('profiler.setup_driver')
    @patch('profiler.run_speedometer')
    def test_main_exception(self, mock_speedometer, mock_setup):
        mock_driver = MagicMock()
        mock_setup.return_value = mock_driver
        mock_speedometer.side_effect = Exception("Test Error")

        with self.assertRaises(Exception):
            profiler.main()

        mock_driver.quit.assert_called_once()

if __name__ == '__main__':
    unittest.main()
