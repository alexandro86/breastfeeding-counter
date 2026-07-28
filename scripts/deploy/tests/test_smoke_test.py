from __future__ import annotations

import unittest
from unittest.mock import patch

from scripts.deploy import smoke_test


class SmokeTestTests(unittest.TestCase):
    @patch("scripts.deploy.smoke_test._get")
    @patch("scripts.deploy.smoke_test._get_json")
    def test_run_accepts_expected_deployment(
        self,
        get_json: unittest.mock.Mock,
        get: unittest.mock.Mock,
    ) -> None:
        get_json.side_effect = [
            {
                "status": "ok",
                "service": "breastfeeding-counter-api",
                "version": "a" * 40,
            },
            {"status": "ok", "database": "ready"},
        ]
        get.return_value = (b"<!doctype html><html></html>", "text/html")

        smoke_test.run(
            "https://api.example.com/api/v1",
            "https://app.example.com",
            "a" * 40,
        )

    @patch("scripts.deploy.smoke_test._get_json")
    def test_run_rejects_unexpected_commit(self, get_json: unittest.mock.Mock) -> None:
        get_json.return_value = {
            "status": "ok",
            "service": "breastfeeding-counter-api",
            "version": "b" * 40,
        }

        with self.assertRaisesRegex(smoke_test.SmokeTestError, "commit esperado"):
            smoke_test.run(
                "https://api.example.com/api/v1",
                "https://app.example.com",
                "a" * 40,
            )

    def test_run_requires_https(self) -> None:
        with self.assertRaisesRegex(smoke_test.SmokeTestError, "HTTPS"):
            smoke_test.run(
                "http://api.example.com/api/v1",
                "https://app.example.com",
                "a" * 40,
            )


if __name__ == "__main__":
    unittest.main()
