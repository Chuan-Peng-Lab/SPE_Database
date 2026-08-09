#!/usr/bin/env python3
"""Migrate SPE Database experiment JSONs from flat `table` to v2 hierarchical schema.

v1 (flat):  {"exp1": {"table": {<23 flat keys>}, "detail": ""}}
v2 (hier):  {"exp1": {"schema_version": "2", "collected_date": "...",
                      "Physical_Environment": {...}, "Experimental_Design": {...},
                      "Block_Structure": {...}, "Trial_Structure": {...},
                      "Stimulus_Properties": {...}, "detail": ""}}

The five components follow the task-standardization framework in
AboutFolderMetadata.md. All 23 flat keys map deterministically (no data loss);
"Conditions" is extracted from the "per condition:" breakdown in "Trial Number"
when present, else "/".

Usage:  python3 2_Code/migrate_exp_json_to_v2.py [path/to/1_Data]
Run once; review the summary + spot-check diffs before committing.
"""
import json, os, re, sys

MAPPING = {
    "Location":                    ("Physical_Environment", "Location"),
    "Setting":                     ("Physical_Environment", "Setting"),
    "Equipment for presenting":    ("Physical_Environment", "Equipment.Presenting"),
    "Monitor properties":          ("Physical_Environment", "Equipment.Monitor"),
    "Software for experiment":     ("Physical_Environment", "Equipment.Software"),
    "Viewing distance":            ("Physical_Environment", "Viewing_distance"),
    "Block number":                ("Block_Structure", "Block_number"),
    "Number of practice trials":   ("Block_Structure", "Practice_trials"),
    "Trial Number":                ("Block_Structure", "Trial_number"),
    "Fixation presentation duration": ("Trial_Structure", "Fixation_duration"),
    "Stimulus presentation duration": ("Trial_Structure", "Stimulus_duration"),
    "Shape-label interval":        ("Trial_Structure", "SOA"),
    "Stimulus order":              ("Trial_Structure", "Stimulus_order"),
    "Response deadline":           ("Trial_Structure", "Response_deadline"),
    "ITI":                         ("Trial_Structure", "ITI"),
    "Feedback duration":           ("Trial_Structure", "Feedback_duration"),
    "Modality":                    ("Stimulus_Properties", "Modality"),
    "Fixation size":               ("Stimulus_Properties", "Fixation"),
    "Shape size":                  ("Stimulus_Properties", "Shape"),
    "Label size":                  ("Stimulus_Properties", "Label"),
    "Stimulus color":              ("Stimulus_Properties", "Colors.Stimulus"),
    "Background color":            ("Stimulus_Properties", "Colors.Background"),
}
COMPONENTS = ["Physical_Environment", "Experimental_Design",
              "Block_Structure", "Trial_Structure", "Stimulus_Properties"]
COND_RE = re.compile(r"per condition[s]?\s*:\s*([^;)\]]+)", re.IGNORECASE)


def set_path(obj, dotted, value):
    parts = dotted.split(".")
    for p in parts[:-1]:
        obj = obj.setdefault(p, {})
    obj[parts[-1]] = value


def extract_conditions(trial_number):
    m = COND_RE.search(trial_number or "")
    if not m:
        return "/"
    conds = ", ".join(s.strip() for s in m.group(1).split(",") if s.strip())
    return conds or "/"


def migrate(exp_obj):
    table = exp_obj.pop("table", {})
    v2 = {"schema_version": "2"}
    if "Collected Date" in table:
        v2["Collected_date"] = table.pop("Collected Date")
    for comp in COMPONENTS:
        v2[comp] = {}
    for flat_key, value in table.items():
        if flat_key not in MAPPING:
            raise KeyError(f"Unmapped flat key: {flat_key!r}")
        comp, path = MAPPING[flat_key]
        set_path(v2[comp], path, value)
    v2["Experimental_Design"]["Conditions"] = extract_conditions(
        v2["Block_Structure"].get("Trial_number", ""))
    v2["detail"] = exp_obj.get("detail", "")
    for k, v in exp_obj.items():
        if k not in ("table", "detail"):
            v2[k] = v
    return v2


def main():
    data_dir = sys.argv[1] if len(sys.argv) > 1 else "1_Data"
    exp_re = re.compile(r"_Exp[0-9]+(\.[0-9]+)?$")
    files, migrated = [], []
    for root, dirs, fs in os.walk(data_dir):
        for f in sorted(fs):
            if f.startswith("._") or not f.endswith(".json"):
                continue
            if exp_re.search(f[:-5]):
                files.append(os.path.join(root, f))
    for p in sorted(files):
        with open(p, encoding="utf-8") as fh:
            doc = json.load(fh)
        for exp_key, exp_obj in doc.items():
            if isinstance(exp_obj, dict) and "table" in exp_obj:
                doc[exp_key] = migrate(exp_obj)
        with open(p, "w", encoding="utf-8") as fh:
            json.dump(doc, fh, ensure_ascii=False, indent=2)
            fh.write("\n")
        migrated.append(p)
    print(f"Migrated {len(migrated)} exp JSON files (v1 flat table -> v2 hierarchical).")
    n = 0
    for p in migrated:
        doc = json.load(open(p, encoding="utf-8"))
        for ek, eo in doc.items():
            c = eo.get("Experimental_Design", {}).get("Conditions", "/")
            if c != "/":
                n += 1
                print(f"  conditions extracted: {p} [{ek}] -> {c}")
    print(f"  ({n} file(s) with extracted Conditions)")


if __name__ == "__main__":
    main()
