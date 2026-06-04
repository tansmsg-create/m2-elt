"""tap-demo-api: a Singer tap built with the Meltano SDK.

Demonstrates the structure of a real custom REST tap:
  - a Tap class (config, validation, stream discovery)
  - a base RESTStream (shared auth, pagination, base URL)
  - concrete streams (one full-table, one incremental, one child stream)
"""
