from __future__ import annotations

import unittest
from unittest.mock import patch

from scripts.deploy import render_deploy


class RenderDeployTests(unittest.TestCase):
    @patch("scripts.deploy.render_deploy.time.sleep")
    @patch("scripts.deploy.render_deploy._request_json")
    def test_deploy_waits_until_live(
        self, request_json: unittest.mock.Mock, _sleep: unittest.mock.Mock
    ) -> None:
        request_json.side_effect = [
            {"id": "dep-123", "status": "created"},
            {"id": "dep-123", "status": "build_in_progress"},
            {"id": "dep-123", "status": "live"},
        ]

        deploy_id = render_deploy.deploy(
            "srv-123",
            "a" * 40,
            "secret-token",
            timeout_seconds=120,
        )

        self.assertEqual(deploy_id, "dep-123")
        self.assertEqual(request_json.call_count, 3)

    @patch("scripts.deploy.render_deploy.time.sleep")
    @patch("scripts.deploy.render_deploy._request_json")
    def test_deploy_stops_on_failure(
        self, request_json: unittest.mock.Mock, _sleep: unittest.mock.Mock
    ) -> None:
        request_json.side_effect = [
            {"id": "dep-123", "status": "created"},
            {"id": "dep-123", "status": "pre_deploy_failed"},
        ]

        with self.assertRaisesRegex(render_deploy.RenderApiError, "pre_deploy_failed"):
            render_deploy.deploy(
                "srv-123",
                "a" * 40,
                "secret-token",
                timeout_seconds=120,
            )


if __name__ == "__main__":
    unittest.main()
