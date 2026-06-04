"""Concrete stream definitions.

Three patterns are demonstrated:

1. UsersStream     - full-table replication (re-pull everything each run)
2. PostsStream     - incremental replication via a replication_key bookmark
3. (parent-child)  - PostsStream is linked to UsersStream so the SDK can
                     pass each user's id down into the posts request,
                     mirroring the region -> entry -> generationmix
                     fan-out you saw in tap-carbon-intensity, but handled
                     declaratively instead of by hand-rolled recursion.
"""

from __future__ import annotations

import singer_sdk.typing as th

from tap_demo_api.streams.base import DemoApiStream


class UsersStream(DemoApiStream):
    """All users. Full-table replication."""

    name = "users"
    path = "/users"
    primary_keys = ("id",)
    replication_key = None  # full table: no bookmark

    # The schema IS the contract emitted as the SCHEMA message.
    # In a SQL tap this would be auto-discovered from the DB; for a
    # REST tap you declare it explicitly.
    schema = th.PropertiesList(
        th.Property("id", th.IntegerType, required=True),
        th.Property("name", th.StringType),
        th.Property("username", th.StringType),
        th.Property("email", th.StringType),
        th.Property("phone", th.StringType),
        th.Property("website", th.StringType),
        th.Property(
            "address",
            th.ObjectType(
                th.Property("street", th.StringType),
                th.Property("suite", th.StringType),
                th.Property("city", th.StringType),
                th.Property("zipcode", th.StringType),
            ),
        ),
        th.Property(
            "company",
            th.ObjectType(
                th.Property("name", th.StringType),
                th.Property("catchPhrase", th.StringType),
            ),
        ),
    ).to_dict()

    def get_child_context(self, record: dict, context: dict | None) -> dict:
        """Hand each user's id down to child streams (PostsStream)."""
        return {"user_id": record["id"]}


class PostsStream(DemoApiStream):
    """Posts belonging to users. Incremental replication.

    `parent_stream_type = UsersStream` makes this a CHILD stream: the SDK
    runs it once per parent record, injecting the parent context
    (`user_id`) into the request path. That replaces manual nested loops.
    """

    name = "posts"
    parent_stream_type = UsersStream
    path = "/users/{user_id}/posts"  # {user_id} filled from parent context
    primary_keys = ("id",)
    replication_key = "id"  # incremental: bookmark on this field

    schema = th.PropertiesList(
        th.Property("id", th.IntegerType, required=True),
        th.Property("userId", th.IntegerType),
        th.Property("title", th.StringType),
        th.Property("body", th.StringType),
    ).to_dict()
