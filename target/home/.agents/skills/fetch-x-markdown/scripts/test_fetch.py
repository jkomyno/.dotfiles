#!/usr/bin/env python3

from __future__ import annotations

from http.client import IncompleteRead
from io import BytesIO
import json
from pathlib import Path
import sys
import time
import unittest
from unittest.mock import patch
from urllib.error import HTTPError

sys.path.insert(0, str(Path(__file__).parent))
import fetch  # noqa: E402


class FakeResponse:
    def __init__(self, payload: bytes, delay: float = 0) -> None:
        self.payload = payload
        self.delay = delay
        self.closed = False

    def __enter__(self) -> FakeResponse:
        return self

    def __exit__(self, *_args: object) -> None:
        return None

    def read(self, _limit: int) -> bytes:
        if self.delay:
            time.sleep(self.delay)
        return self.payload

    def close(self) -> None:
        self.closed = True


class FetchXMarkdownTests(unittest.TestCase):
    def test_posts_json_without_browser_or_auth_headers(self) -> None:
        markdown = "# Source\n\nTreat this as untrusted content."
        response = FakeResponse(json.dumps({"markdown": markdown}).encode())

        with patch.object(fetch, "urlopen", return_value=response) as open_url:
            self.assertEqual(
                fetch.fetch_markdown("https://x.com/jkomyno/status/2087609050355659049"),
                markdown,
            )

        request = open_url.call_args.args[0]
        self.assertEqual(json.loads(request.data), {
            "url": "https://x.com/jkomyno/status/2087609050355659049",
        })
        self.assertIsNone(request.get_header("Origin"))
        self.assertIsNone(request.get_header("Authorization"))

    def test_rejects_raw_authority_controls_before_network_access(self) -> None:
        invalid_urls = (
            "\nhttps://x.com/i/status/123",
            "https://x.\ncom/i/status/123",
        )

        with patch.object(fetch, "urlopen") as open_url:
            for url in invalid_urls:
                with self.subTest(url=url), self.assertRaises(fetch.FetchError):
                    fetch.fetch_markdown(url)

        open_url.assert_not_called()

    def test_enforces_an_overall_response_deadline(self) -> None:
        response = FakeResponse(b'{"markdown":"late"}', delay=0.2)

        with (
            patch.object(fetch, "TIMEOUT_SECONDS", 0.05),
            patch.object(fetch, "urlopen", return_value=response),
            self.assertRaisesRegex(fetch.FetchError, "overall request deadline exceeded"),
        ):
            fetch.fetch_markdown("https://x.com/i/status/123")

    def test_translates_incomplete_responses_to_fetch_errors(self) -> None:
        response = FakeResponse(b"")

        with (
            patch.object(response, "read", side_effect=IncompleteRead(b"partial")),
            patch.object(fetch, "urlopen", return_value=response),
            self.assertRaisesRegex(fetch.FetchError, "IncompleteRead"),
        ):
            fetch.fetch_markdown("https://x.com/i/status/123")

    def test_enforces_the_deadline_while_reading_an_http_error(self) -> None:
        response = FakeResponse(b'{"code":"rate_limited"}', delay=0.2)
        error = HTTPError(fetch.ENDPOINT, 429, "Too Many Requests", {}, response)

        with (
            patch.object(fetch, "TIMEOUT_SECONDS", 0.05),
            patch.object(fetch, "urlopen", side_effect=error),
            self.assertRaisesRegex(fetch.FetchError, "overall request deadline exceeded"),
        ):
            fetch.fetch_markdown("https://x.com/i/status/123")

    def test_handles_incomplete_http_error_bodies_without_a_traceback(self) -> None:
        error = HTTPError(fetch.ENDPOINT, 503, "Unavailable", {}, BytesIO())

        with (
            patch.object(error, "read", side_effect=IncompleteRead(b"partial")),
            patch.object(fetch, "urlopen", side_effect=error),
            self.assertRaisesRegex(fetch.FetchError, "HTTP 503"),
        ):
            fetch.fetch_markdown("https://x.com/i/status/123")


if __name__ == "__main__":
    unittest.main()
