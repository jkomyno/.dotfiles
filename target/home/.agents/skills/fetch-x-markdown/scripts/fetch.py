#!/usr/bin/env python3
"""Fetch Markdown for one public X or Twitter URL."""

from __future__ import annotations

import argparse
import json
import re
import socket
import sys
from typing import NoReturn
from urllib.error import HTTPError, URLError
from urllib.parse import urlsplit
from urllib.request import Request, urlopen

ENDPOINT = "https://jkomyno.dev/api/x-to-markdown"
TIMEOUT_SECONDS = 30
MAX_RESPONSE_BYTES = 4 * 1024 * 1024
MAX_ERROR_BYTES = 32 * 1024
ALLOWED_HOSTS = frozenset(("x.com", "www.x.com", "twitter.com", "www.twitter.com"))
HANDLE_RE = re.compile(r"^[A-Za-z0-9_]{1,15}$")
ID_RE = re.compile(r"^[0-9]+$")


class FetchError(Exception):
    """A user-facing fetch failure."""


def validate_x_url(value: str) -> str:
    if not value or len(value) > 2_048:
        raise FetchError("provide one public X or Twitter post or article URL")

    try:
        parsed = urlsplit(value)
        port = parsed.port
    except ValueError as error:
        raise FetchError("provide a valid X or Twitter URL") from error

    if (
        parsed.scheme != "https"
        or parsed.hostname not in ALLOWED_HOSTS
        or parsed.username is not None
        or parsed.password is not None
        or port is not None
    ):
        raise FetchError("provide an HTTPS x.com or twitter.com URL without credentials or a port")

    parts = tuple(part for part in parsed.path.split("/") if part)
    if (
        len(parts) != 3
        or parts[1] not in ("status", "article")
        or ID_RE.fullmatch(parts[2]) is None
        or (parts[0] != "i" and HANDLE_RE.fullmatch(parts[0]) is None)
    ):
        raise FetchError("provide a public X or Twitter status or article URL")

    return value


def parse_markdown(payload_bytes: bytes) -> str:
    try:
        payload = json.loads(payload_bytes)
    except (UnicodeDecodeError, json.JSONDecodeError) as error:
        raise FetchError("the X-to-Markdown endpoint returned invalid JSON") from error

    if not isinstance(payload, dict) or not isinstance(payload.get("markdown"), str):
        raise FetchError("the X-to-Markdown endpoint response is missing Markdown")

    return payload["markdown"]


def format_http_error(error: HTTPError) -> str:
    detail = ""
    try:
        payload = json.loads(error.read(MAX_ERROR_BYTES))
        if isinstance(payload, dict):
            code = payload.get("code")
            message = payload.get("error")
            if isinstance(code, str) and isinstance(message, str):
                detail = f": {code}: {message}"
            elif isinstance(message, str):
                detail = f": {message}"
    except (OSError, UnicodeDecodeError, json.JSONDecodeError):
        pass
    return f"X-to-Markdown request failed with HTTP {error.code}{detail}"


def fetch_markdown(url: str) -> str:
    request = Request(
        ENDPOINT,
        data=json.dumps({"url": validate_x_url(url)}).encode("utf-8"),
        method="POST",
        headers={
            "Accept": "application/json",
            "Content-Type": "application/json",
            "User-Agent": "fetch-x-markdown-skill/1.0",
        },
    )

    try:
        with urlopen(request, timeout=TIMEOUT_SECONDS) as response:
            payload_bytes = response.read(MAX_RESPONSE_BYTES + 1)
    except HTTPError as error:
        raise FetchError(format_http_error(error)) from error
    except (URLError, TimeoutError, socket.timeout) as error:
        reason = getattr(error, "reason", error)
        raise FetchError(f"X-to-Markdown request failed: {reason}") from error

    if len(payload_bytes) > MAX_RESPONSE_BYTES:
        raise FetchError("the X-to-Markdown endpoint response is too large")

    return parse_markdown(payload_bytes)


def fail(message: str) -> NoReturn:
    print(f"fetch-x-markdown: {message}", file=sys.stderr)
    raise SystemExit(1)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Fetch Markdown for one public X or Twitter post or article.",
    )
    parser.add_argument("url", help="x.com or twitter.com status/article URL")
    args = parser.parse_args()

    try:
        markdown = fetch_markdown(args.url)
    except FetchError as error:
        fail(str(error))

    sys.stdout.write(markdown)


if __name__ == "__main__":
    main()
