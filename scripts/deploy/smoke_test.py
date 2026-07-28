#!/usr/bin/env python3
"""Read-only smoke tests for a deployed frontend and API."""

from __future__ import annotations

import argparse
import json
import re
import sys
import time
from typing import Any
from urllib.error import HTTPError, URLError
from urllib.parse import urljoin, urlparse
from urllib.request import Request, urlopen

SHA_PATTERN = re.compile(r"^[0-9a-f]{40}$")


class SmokeTestError(RuntimeError):
    """Raised when a smoke test does not pass."""


def _validate_https_url(value: str, name: str) -> str:
    parsed = urlparse(value)
    if parsed.scheme != "https" or not parsed.netloc or parsed.username or parsed.password:
        raise SmokeTestError(f"{name} debe ser una URL HTTPS pública sin credenciales.")
    return value.rstrip("/") + "/"


def _get(url: str, accept: str) -> tuple[bytes, str]:
    request = Request(
        url,
        method="GET",
        headers={"Accept": accept, "User-Agent": "breastfeeding-counter-smoke-test"},
    )
    try:
        with urlopen(request, timeout=20) as response:
            return response.read(), response.headers.get_content_type()
    except HTTPError as error:
        raise SmokeTestError(f"{url} respondió HTTP {error.code}.") from error
    except (URLError, TimeoutError) as error:
        raise SmokeTestError(f"No se pudo contactar {url}.") from error


def _get_json(url: str) -> dict[str, Any]:
    body, content_type = _get(url, "application/json")
    if content_type != "application/json":
        raise SmokeTestError(f"{url} no devolvió application/json.")
    try:
        payload = json.loads(body)
    except json.JSONDecodeError as error:
        raise SmokeTestError(f"{url} devolvió JSON inválido.") from error
    if not isinstance(payload, dict):
        raise SmokeTestError(f"{url} devolvió una estructura JSON inesperada.")
    return payload


def run(api_base_url: str, frontend_url: str, expected_commit: str) -> None:
    api = _validate_https_url(api_base_url, "API_BASE_URL")
    frontend = _validate_https_url(frontend_url, "FRONTEND_URL")

    live = _get_json(urljoin(api, "health/live"))
    if live.get("status") != "ok" or live.get("service") != "breastfeeding-counter-api":
        raise SmokeTestError("Liveness devolvió valores inesperados.")
    if live.get("version") != expected_commit:
        raise SmokeTestError(
            f"La API sirve {live.get('version')!r}, no el commit esperado {expected_commit}."
        )

    ready = _get_json(urljoin(api, "health/ready"))
    if ready != {"status": "ok", "database": "ready"}:
        raise SmokeTestError("Readiness no confirmó la conexión a PostgreSQL.")

    body, content_type = _get(frontend, "text/html")
    if content_type != "text/html" or b"<html" not in body.lower():
        raise SmokeTestError("El frontend no devolvió un documento HTML.")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--api-base-url", required=True)
    parser.add_argument("--frontend-url", required=True)
    parser.add_argument("--expected-commit", required=True)
    parser.add_argument("--attempts", type=int, default=10)
    parser.add_argument("--interval-seconds", type=int, default=15)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if not SHA_PATTERN.fullmatch(args.expected_commit):
        print("El commit esperado debe ser un SHA hexadecimal completo.", file=sys.stderr)
        return 2
    if args.attempts < 1 or args.interval_seconds < 1:
        print("Los reintentos y el intervalo deben ser positivos.", file=sys.stderr)
        return 2

    for attempt in range(1, args.attempts + 1):
        try:
            run(args.api_base_url, args.frontend_url, args.expected_commit)
            print(f"Smoke tests correctos para {args.expected_commit}.")
            return 0
        except SmokeTestError as error:
            if attempt == args.attempts:
                print(str(error), file=sys.stderr)
                return 1
            print(f"Intento {attempt}/{args.attempts} pendiente: {error}")
            time.sleep(args.interval_seconds)

    return 1


if __name__ == "__main__":
    raise SystemExit(main())
