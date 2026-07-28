#!/usr/bin/env python3
"""Deploy an immutable Git commit to Render and wait for completion."""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
import time
from typing import Any
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

API_BASE_URL = "https://api.render.com/v1"
SUCCESS_STATUSES = {"live"}
FAILURE_STATUSES = {
    "build_failed",
    "canceled",
    "deactivated",
    "pre_deploy_failed",
    "timed_out",
    "update_failed",
}
SHA_PATTERN = re.compile(r"^[0-9a-f]{40}$")
SERVICE_ID_PATTERN = re.compile(r"^srv-[A-Za-z0-9]+$")


class RenderApiError(RuntimeError):
    """Raised when Render rejects an API request."""


def _request_json(
    method: str,
    path: str,
    token: str,
    body: dict[str, Any] | None = None,
    attempts: int = 5,
) -> dict[str, Any]:
    encoded_body = json.dumps(body).encode("utf-8") if body is not None else None
    request = Request(
        f"{API_BASE_URL}{path}",
        data=encoded_body,
        method=method,
        headers={
            "Accept": "application/json",
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
        },
    )

    for attempt in range(attempts):
        try:
            with urlopen(request, timeout=30) as response:
                payload = json.load(response)
                if not isinstance(payload, dict):
                    raise RenderApiError("Render devolvió una respuesta JSON inesperada.")
                return payload
        except HTTPError as error:
            retryable = error.code == 429 or error.code >= 500
            if retryable and attempt < attempts - 1:
                time.sleep(min(2**attempt, 15))
                continue
            raise RenderApiError(
                f"Render rechazó la solicitud con estado HTTP {error.code}."
            ) from error
        except (URLError, TimeoutError) as error:
            if attempt < attempts - 1:
                time.sleep(min(2**attempt, 15))
                continue
            raise RenderApiError("No se pudo contactar la API de Render.") from error

    raise RenderApiError("Se agotaron los reintentos contra Render.")


def deploy(service_id: str, commit_sha: str, token: str, timeout_seconds: int) -> str:
    response = _request_json(
        "POST",
        f"/services/{service_id}/deploys",
        token,
        {"commitId": commit_sha, "clearCache": "do_not_clear"},
    )
    deploy_id = response.get("id")
    if not isinstance(deploy_id, str) or not deploy_id:
        raise RenderApiError("Render no devolvió el identificador del despliegue.")

    print(f"Despliegue Render iniciado: {deploy_id}")
    deadline = time.monotonic() + timeout_seconds
    previous_status: str | None = None

    while time.monotonic() < deadline:
        details = _request_json(
            "GET",
            f"/services/{service_id}/deploys/{deploy_id}",
            token,
        )
        status = details.get("status")
        if not isinstance(status, str):
            raise RenderApiError("Render no devolvió un estado de despliegue válido.")

        if status != previous_status:
            print(f"Estado Render: {status}")
            previous_status = status

        if status in SUCCESS_STATUSES:
            return deploy_id
        if status in FAILURE_STATUSES:
            raise RenderApiError(f"El despliegue de Render terminó con estado {status}.")

        time.sleep(15)

    raise RenderApiError(
        f"El despliegue de Render excedió el límite de {timeout_seconds} segundos."
    )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--service-id", required=True)
    parser.add_argument("--commit-sha", required=True)
    parser.add_argument("--timeout-seconds", type=int, default=1800)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    token = os.getenv("RENDER_API_KEY", "")

    if not token:
        print("Falta RENDER_API_KEY.", file=sys.stderr)
        return 2
    if not SERVICE_ID_PATTERN.fullmatch(args.service_id):
        print("RENDER_SERVICE_ID no tiene un formato válido.", file=sys.stderr)
        return 2
    if not SHA_PATTERN.fullmatch(args.commit_sha):
        print("El SHA debe contener exactamente 40 caracteres hexadecimales.", file=sys.stderr)
        return 2
    if args.timeout_seconds < 60:
        print("El timeout debe ser de al menos 60 segundos.", file=sys.stderr)
        return 2

    try:
        deploy(args.service_id, args.commit_sha, token, args.timeout_seconds)
    except RenderApiError as error:
        print(str(error), file=sys.stderr)
        return 1

    print(f"Render sirve correctamente el commit {args.commit_sha}.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
