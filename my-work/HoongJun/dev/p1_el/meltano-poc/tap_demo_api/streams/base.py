"""Base stream class shared by every stream in this tap.

Everything common across endpoints lives here:
  - the API base URL (pulled from config)
  - the pagination strategy
  - optional bearer-token auth

Concrete streams subclass this and only declare what is unique to them:
  their `name`, `path`, `primary_keys`, `schema`, and (if incremental)
  their `replication_key`.
"""

from __future__ import annotations

import typing as t

from singer_sdk.authenticators import (
    APIAuthenticatorBase,
    BearerTokenAuthenticator,
)
from singer_sdk.pagination import BasePageNumberPaginator
from singer_sdk.streams import RESTStream


class DemoApiPaginator(BasePageNumberPaginator):
    """Page-number pagination.

    JSONPlaceholder doesn't actually paginate, so this paginator stops
    after the first page. For a real API you'd inspect the response
    (e.g. a `next` link, a total-pages header, or an empty page) and
    return False from `has_more` when there's nothing left.
    """

    def has_more(self, response) -> bool:  # noqa: ANN001
        # Real example: keep going while the page came back full.
        # records = response.json()
        # return isinstance(records, list) and len(records) > 0
        return False  # single-page demo source


class DemoApiStream(RESTStream):
    """Base class — all demo streams inherit URL, auth, and pagination."""

    # Pull the base URL from tap config so it's environment-driven,
    # never hardcoded (cf. the hardcoded date window in tap-carbon-intensity).
    @property
    def url_base(self) -> str:
        return self.config["api_url"]

    # Where the records live inside the response body.
    # "$[*]" means "the response is a bare JSON array of records".
    records_jsonpath = "$[*]"

    @property
    def authenticator(self) -> APIAuthenticatorBase:
        """Attach a bearer token only if one is configured.

        The demo source needs no auth, so this returns a no-op
        authenticator unless you set `api_token` in config — showing how
        optional auth is wired without breaking the request when absent.
        """
        token = self.config.get("api_token")
        if token:
            return BearerTokenAuthenticator.create_for_stream(self, token=token)
        return APIAuthenticatorBase(stream=self)  # no-op: adds nothing

    def get_new_paginator(self) -> DemoApiPaginator:
        return DemoApiPaginator(start_value=1)

    @property
    def http_headers(self) -> dict:
        headers = {"User-Agent": "tap-demo-api/0.1 (QAI Lab POC)"}
        return headers
