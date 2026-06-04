# tap-demo-api — a Meltano POC

A complete, runnable Singer/Meltano proof-of-concept: a **custom REST tap**
built with the Meltano SDK, wired to a **loader**, demonstrating the full
`source → tap → stdout → pipe → stdin → target → destination` flow.

It illustrates the three patterns you actually need for a real API:

| Pattern | Where | What it shows |
|---|---|---|
| Full-table replication | `users` stream | Re-pull everything each run |
| Incremental replication | `posts` stream (`replication_key="id"`) | Bookmark + resume via STATE |
| Parent-child fan-out | `posts.parent_stream_type = UsersStream` | One request per parent, declaratively — replaces hand-rolled nested loops |

## The mental model

```
SOURCE API  →  [ tap-demo-api ]  →  stdout  →  | pipe |  →  stdin  →  [ target ]  →  DESTINATION
   HTTP            extract            JSON                              load          (files / DB)
```

- A **tap** only ever writes Singer messages (SCHEMA / RECORD / STATE) to **stdout**.
- A **target** only ever reads those messages from **stdin** and writes them somewhere.
- They never know about each other — any tap pairs with any target.
- **Logs go to stderr**, never stdout, so they don't corrupt the data stream.

## Project layout

```
meltano-poc/
├── meltano.yml              # orchestration: which taps + targets exist
├── pyproject.toml           # makes the tap pip-installable as a command
├── config.json              # standalone-run config for the tap
├── tap_demo_api/
│   ├── tap.py               # the Tap class: config schema, discovery, CLI
│   └── streams/
│       ├── base.py          # shared url_base, auth, pagination
│       └── __init__.py      # UsersStream, PostsStream (the concrete streams)
├── target_demo_jsonl.py     # a minimal ~30-line target (loader) for teaching
└── mock_api.py              # local stand-in for the source API (offline demo)
```

## Run it — three ways

### 1. The tap alone (see the raw stdout stream)

```bash
# discovery: generate the catalog
python3 -m tap_demo_api.tap --config config.json --discover > catalog.json

# sync: emit SCHEMA / RECORD / STATE messages to stdout
python3 -m tap_demo_api.tap --config config.json
```

### 2. The full pipe by hand (tap | target)

```bash
python3 mock_api.py &                       # start the demo source
python3 -m tap_demo_api.tap --config config.json \
  | python3 target_demo_jsonl.py output     # → writes output/users.jsonl, posts.jsonl
```

### 3. Via Meltano (the real orchestration)

```bash
pipx install meltano
meltano install                              # installs the tap + chosen target
                                             #   each in its OWN isolated venv
meltano run tap-demo-api target-jsonl        # wire this tap to this target
meltano run tap-demo-api target-duckdb       # same tap, different destination
```

## Why Meltano isolates each plugin

Building this POC surfaced a real-world gotcha: the old `target-jsonl`
pins `jsonschema==2.6.0`, while `singer-sdk` needs `>=4.18`. They cannot
share one Python environment. **Meltano installs every tap and target in
its own virtualenv precisely to prevent this** — so a target's stale
dependency can never break your tap. When running by hand, you'd create
separate venvs yourself (this repo does that for the target).

## Adapting it to YOUR API

1. Set `url_base` (via `api_url` config) to your API.
2. Add `authenticator` logic in `base.py` (bearer, API key header, OAuth).
3. For each endpoint, add a stream class: set `name`, `path`,
   `primary_keys`, `records_jsonpath`, and the `schema`.
4. For incremental endpoints, set `replication_key`.
5. For nested resources, set `parent_stream_type` + `get_child_context`.
6. Implement real pagination in `DemoApiPaginator.has_more`.

If your API is a plain paginated REST endpoint, consider the off-the-shelf
`tap-rest-api-msdk` — it's fully config-driven, zero Python. Write a custom
tap (like this one) only when the API has quirks the generic tap can't express.

## Troubleshooting

### `ModuleNotFoundError: No module named 'singer_sdk'`

You're running the tap from a Python env where `singer-sdk` isn't installed.
Two common causes:

- **Running the tap directly** (`python3 -m tap_demo_api.tap ...`) from your
  shell venv. Install the SDK there:
  ```bash
  uv pip install singer-sdk
  # or
  pip install singer-sdk
  ```
- **Forgetting that Meltano isolates plugins.** When you use `meltano run`,
  each tap/target lives in its own venv under `.meltano/extractors/...` and
  `.meltano/loaders/...`. You don't import `singer_sdk` from your project
  venv — Meltano invokes the plugin in its own env. If you haven't run
  `meltano install` yet, do so first.

Quick check which Python you're in:
```bash
which python
python -c "import sys; print(sys.executable)"
pip list | grep -i singer
```
