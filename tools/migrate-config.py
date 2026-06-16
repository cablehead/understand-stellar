#!/usr/bin/env python3
"""Migrate a Stellar v1 (0.0.1-era) config to the 0.0.2 schema, in place.

The 0.0.2 binary rejects v1 configs. This applies the four known deltas so
`stellar gen` accepts the file. Idempotent: safe to run on an already-migrated
config.

    python3 tools/migrate-config.py path/to/stellar.config.json

Deltas (v1 -> 0.0.2):
  - general.viewport:  drop `baseFontSize`, add `baseFont: {mode: browserDefault}`
  - general.aspectRatio: drop base/scale/step keys (now driven by `named`)
  - colors.named:      add `prefix: "named"`
  - colors.charts:     add `qualitativeExport: true`, `divergingExport: [true]*N`
"""
import json
import sys


def migrate(cfg: dict) -> list[str]:
    changed = []

    vp = cfg.get("general", {}).get("viewport", {})
    if "baseFontSize" in vp:
        vp.pop("baseFontSize")
        changed.append("removed general.viewport.baseFontSize")
    if "baseFont" not in vp:
        vp["baseFont"] = {"mode": "browserDefault"}
        changed.append("added general.viewport.baseFont")

    ar = cfg.get("general", {}).get("aspectRatio", {})
    for k in ["baseMin", "baseMax", "negativeSteps", "positiveSteps",
              "scaleMin", "scaleMax"]:
        if k in ar:
            ar.pop(k)
            changed.append(f"removed general.aspectRatio.{k}")

    named = cfg.get("colors", {}).get("named", {})
    if "prefix" not in named:
        named["prefix"] = "named"
        changed.append("added colors.named.prefix")

    charts = cfg.get("colors", {}).get("charts", {})
    if charts and "qualitativeExport" not in charts:
        charts["qualitativeExport"] = True
        changed.append("added colors.charts.qualitativeExport")
    if charts and "divergingExport" not in charts:
        n = int(charts.get("divergingCount", 12))
        charts["divergingExport"] = [True] * n
        changed.append(f"added colors.charts.divergingExport ({n})")

    return changed


def main() -> int:
    if len(sys.argv) != 2:
        print(__doc__)
        return 2
    path = sys.argv[1]
    cfg = json.load(open(path))
    changed = migrate(cfg)
    if not changed:
        print(f"{path}: already 0.0.2 (no changes)")
        return 0
    json.dump(cfg, open(path, "w"), indent=2)
    print(f"{path}: migrated")
    for c in changed:
        print(f"  - {c}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
