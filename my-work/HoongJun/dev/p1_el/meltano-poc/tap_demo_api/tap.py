"""The Tap class — the entrypoint Meltano (or the CLI) invokes.

Responsibilities (all handled by the SDK base class):
  - parse --config / --state / --catalog / --discover
  - validate config against config_jsonschema
  - emit the catalog on --discover
  - run discover_streams() and stream data on sync
"""

from __future__ import annotations

import singer_sdk.typing as th
from singer_sdk import Tap

from tap_demo_api.streams import PostsStream, UsersStream


class TapDemoApi(Tap):
    """tap-demo-api."""

    name = "tap-demo-api"

    # This schema validates the config file at startup. Missing required
    # keys or wrong types fail fast with a clear error — unlike the example
    # tap, which did no config validation at all.
    config_jsonschema = th.PropertiesList(
        th.Property(
            "api_url",
            th.StringType,
            required=True,
            default="https://jsonplaceholder.typicode.com",
            description="Base URL of the source API.",
        ),
        th.Property(
            "api_token",
            th.StringType,
            required=False,
            secret=True,  # masked in logs
            description="Optional bearer token. Omit for the public demo API.",
        ),
        th.Property(
            "start_date",
            th.DateTimeType,
            required=False,
            description="Earliest record timestamp to replicate (incremental).",
        ),
    ).to_dict()

    def discover_streams(self) -> list:
        """Return every stream this tap exposes."""
        return [
            UsersStream(self),
            PostsStream(self),
        ]


if __name__ == "__main__":
    TapDemoApi.cli()
