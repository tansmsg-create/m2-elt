# p1_el / meltano — EL via Meltano (Singer) — comparison to dlt
**Module 1** · Owner: John / Bryan · **Status: alternative/comparison**

Loads the same Olist CSVs into the same bronze dataset (`raw_commerce`) as the dlt path
and the webapp — but config-driven via Meltano + Singer plugins. Demonstrates EL-tool
interchangeability behind one raw contract.

- **Extractor:** `tap-csv` (meltanolabs variant) — reads the 9 Olist CSVs.
- **Loader:** `target-bigquery` (z3z1ma variant) — writes to BigQuery.
- **Config:** project/dataset/location/credentials come from `.env` (via `${VAR}` in meltano.yml).

---

## Prerequisites
1. **All 9** Olist CSVs at `p1_el/data/` — `tap-csv` errors if *any* configured path is missing, since it reads all of them.
2. The SA key at `<repo-root>/secrets/dsai-project-496504-c8f5f0c328fc.json` (i.e. `../../secrets/` from here)
   (SA needs `bigquery.dataEditor` + `bigquery.jobUser`).
3. The `raw_commerce` dataset created:
   `bq mk --location=asia-southeast1 raw_commerce`
4. `uv` (used to install Meltano as an isolated tool).

---

## Setup & run (real)
```bash
# 1. install Meltano as an isolated tool — uv-native (recommended)
uv tool install meltano
#   alternatives:  pipx install meltano   OR   one-off: prefix commands with `uvx`

# 2. configure credentials via .env (Meltano reads .env in this folder automatically)
cd p1_el/meltano
cp .env.example .env          # already points at ../../secrets/ + project dsai-project-496504

# 3. install the plugins declared in meltano.yml
meltano install
#   (uvx variant, no install:  uvx meltano install)

# 4. (optional) sanity-check the tap reads the CSVs
meltano invoke tap-csv --discover | head

# 5. run the pipeline:  extract all 9 CSVs → load to BigQuery raw_commerce
meltano run tap-csv target-bigquery
#   (uvx variant:  uvx meltano run tap-csv target-bigquery)
```

> **Why not `uv run meltano` / add it to pyproject?** Meltano has a large, tightly-pinned
> dependency tree that can conflict with the app's deps (dlt, flask, bigquery). Keep it
> isolated via `uv tool install` (uv's pipx equivalent) — same reasoning as using pipx.
On success, `bq ls raw_commerce` shows the same 9 tables the dlt/webapp paths produce.

---

## Simulate / demonstrate (no full install)
If you only need to *show* the approach for the comparison (slide / report) without
running the heavy install, present:
- this `meltano.yml` (the whole pipeline as declarative config), and
- the command `meltano run tap-csv target-bigquery`,
- noting it lands identical `raw_commerce.*` tables.

That's enough to make the "we evaluated dlt vs Meltano" point. The config IS the artifact.

---

## dlt vs Meltano (the comparison takeaway)
| | dlt (chosen for V1) | Meltano / Singer (this folder) |
|---|---|---|
| Style | Python library, embedded | Framework, declarative `meltano.yml` |
| Setup | `pip install dlt`, write a script | install Meltano, add plugins, configure |
| Olist fit | 9 CSVs in ~15 lines | `tap-csv` config per file |
| Connectors | dlt sources | huge Singer tap catalog (its strength) |
| Best when | custom/local sources, full control | a pre-built tap exists (SaaS/DB) |
| Output | `raw_commerce.*` | identical `raw_commerce.*` |

**Decision:** dlt for V1 (simpler for flat CSVs). Meltano reserved for sources where a
Singer tap already exists — and when orchestrated, it runs as a Dagster asset, not its
own scheduler.

---

## Reset & rerun (when a plugin install fails or you change config)

Meltano caches plugin venvs under `.meltano/`. After any config change — or a failed
install — clear it so the fix takes effect:

```bash
cd p1_el/meltano

# full reset: remove all installed plugin venvs + state (safe; it's gitignored runtime)
rm -rf .meltano

# reinstall plugins fresh
meltano install

# rerun
meltano run tap-csv target-bigquery
```

Lighter reset of a single plugin (no full wipe):
```bash
meltano install loader target-bigquery --clean
```

## Fixing the `pendulum==2.1.2` build error (Python 3.12)

If `meltano install` fails building `pendulum==2.1.2`, it's an old pin that doesn't build
on Python 3.12. The target pins `singer-sdk<0.23`, which *requires* pendulum 2.x — so you
**cannot** force pendulum 3.x (that makes deps unsatisfiable). The fix is to build the
plugin venvs with **Python 3.11**, where pendulum 2.x has working wheels.

`meltano.yml` already sets:
```yaml
python: python3.11
```
This was tested: with 3.11, `target-bigquery` and `tap-csv` install cleanly in seconds.

Make sure Python 3.11 is available so fix #1 works:
```bash
uv python install 3.11
uv python find 3.11        # copy the printed path
```
If `python3.11` isn't on your PATH, set the full path in meltano.yml, e.g.:
```yaml
python: /Users/you/.local/share/uv/python/cpython-3.11.../bin/python3.11
```
Then **reset and reinstall** (see above) — the broken venv must be cleared:
```bash
rm -rf .meltano && meltano install
```

## Fixing `ModuleNotFoundError: No module named 'pkg_resources'`

The `target-bigquery` plugin (via `fs`) imports `pkg_resources`, which lives in
`setuptools`. Two causes on modern Python:
1. uv-built venvs don't include setuptools by default.
2. setuptools **81+ removed `pkg_resources`**.

Fix (already applied in `meltano.yml`): pin an older setuptools into the loader venv:
```yaml
pip_url: git+https://github.com/z3z1ma/target-bigquery.git "setuptools<81"
```
Then reset + reinstall:
```bash
rm -rf .meltano && meltano install
```
A harmless `pkg_resources is deprecated` *warning* may still print — that's fine, not an error.

## Fixing `Invalid field name "..."` (BigQuery 400 on load)

If a load fails with `Invalid field name` on a column that looks valid (e.g.
`product_category_name`), the CSV header has a hidden **BOM** (byte-order mark) — an
invisible `\ufeff` stuck to the first column name, which BigQuery rejects.

Diagnose:
```bash
head -c 3 ../data/product_category_name_translation.csv | od -An -tx1
# 'ef bb bf' at the start = BOM present
```

Fix (already applied in `meltano.yml`): each file entry sets `encoding: utf-8-sig`,
which transparently strips a leading BOM:
```yaml
- entity: category_translation
  path: ../data/product_category_name_translation.csv
  encoding: utf-8-sig
  keys: [product_category_name]
```
Then reset + rerun:
```bash
rm -rf .meltano && meltano install
meltano run tap-csv target-bigquery
```

## Demo: a "good" load — live API source (what Meltano is actually for)

The Olist CSV load shows Meltano works, but a static file is the *wrong* job for it —
the webapp/dlt are faster there. To show Meltano doing what it's **built** for, this
project includes a live-API extractor: `tap-carbon-intensity` pulls real-time UK grid
carbon-intensity data over HTTP (no file to upload — the webapp can't do this).

It loads into a **separate `demo_streaming` dataset** so it never touches Olist bronze.

```bash
# create the demo dataset once
bq mk --location=asia-southeast1 demo_streaming

# install the demo plugins
meltano install extractor tap-carbon-intensity
meltano install loader target-bigquery-demo

# run: live API → BigQuery
meltano run tap-carbon-intensity target-bigquery-demo
```
Lands 3 streams (`entry`, `generationmix`, `region`) — ~8k live records — in
`demo_streaming`. Verify: `bq ls demo_streaming`.

**The point:** this is a live source pulled over HTTP with the same `meltano run`
pattern — the interoperability Singer is designed for. The webapp/dlt would each need a
custom API client to do this; Meltano just needs a tap name. *That's* Meltano's value,
not speed on flat CSVs.

## Troubleshooting
| Symptom | Fix |
|---|---|
| `meltano: command not found` | `uv tool install meltano`, restart shell (or use `uvx meltano ...`) |
| plugin install fails | check internet; the `pip_url` git installs need network |
| auth/403 on load | SA missing roles, or `credentials_path` wrong in meltano.yml |
| dataset not found | `bq mk --location=asia-southeast1 raw_commerce` |
| type errors on load | a tap-csv column inferred wrong — set types in the tap config or accept JSON columns (denormalized: false) |

## Notes
- `.meltano/` (runtime state + installed plugins) is gitignored — like a venv.
- Meltano isn't in p1_el's pyproject (installed separately via `uv tool`) so it doesn't
  bloat the main env. That's intentional.