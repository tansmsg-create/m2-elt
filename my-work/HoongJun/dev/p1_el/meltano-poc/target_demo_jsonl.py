"""target-demo-jsonl: a minimal Singer target (loader), ~30 lines.

A target is just a program that READS stdin and writes somewhere.
This one reads the tap's Singer messages line by line and appends each
RECORD to <stream>.jsonl. It shows there is no magic: stdin in, files out.

Usage (the pipe):
    python3 -m tap_demo_api.tap --config config.json | python3 target_demo_jsonl.py output/
"""
import json
import sys
from pathlib import Path


def main() -> None:
    out_dir = Path(sys.argv[1] if len(sys.argv) > 1 else "output")
    out_dir.mkdir(parents=True, exist_ok=True)

    schemas: dict[str, dict] = {}
    counts: dict[str, int] = {}

    # Read the pipe one line at a time — this IS consuming stdin.
    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        msg = json.loads(line)
        mtype = msg.get("type")

        if mtype == "SCHEMA":
            schemas[msg["stream"]] = msg["schema"]  # remember the contract

        elif mtype == "RECORD":
            stream = msg["stream"]
            target_file = out_dir / f"{stream}.jsonl"
            with target_file.open("a") as f:
                f.write(json.dumps(msg["record"]) + "\n")
            counts[stream] = counts.get(stream, 0) + 1

        elif mtype == "STATE":
            # A real target flushes here and echoes STATE to its own stdout
            # so the orchestrator can persist the bookmark. We just note it.
            pass

        # Unknown message types (e.g. ACTIVATE_VERSION) are simply ignored —
        # a forward-compatible target tolerates messages it doesn't use.

    for stream, n in counts.items():
        sys.stderr.write(f"loaded {n:>3} records -> {out_dir / (stream + '.jsonl')}\n")


if __name__ == "__main__":
    main()
