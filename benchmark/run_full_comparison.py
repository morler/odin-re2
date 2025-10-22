#!/usr/bin/env python3
"""Run Odin and Rust comparison suites for functionality and performance."""

from __future__ import annotations

import argparse
import csv
import datetime as dt
import math
import subprocess
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Tuple

REPO_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_CASES = Path("benchmark/data/functionality_cases.txt")
DEFAULT_PERF_CASES = Path("benchmark/data/performance_scenarios.txt")
DEFAULT_RESULTS_DIR = Path("benchmark/results")


@dataclass
class CaseRecord:
    name: str
    should_compile: bool
    compile_ok: bool
    should_match: bool
    actual_match: bool
    verify_full_match: bool
    match_verified: bool
    compile_ns: int
    match_ns: int
    status: str
    notes: str


@dataclass
class PerfRecord:
    name: str
    pattern: str
    text_size: int
    iterations: int
    compile_ns: int
    match_total_ns: int
    match_avg_ns: int
    throughput_mb_s: float
    matched: bool
    status: str
    notes: str


@dataclass
class PerfComparisonRow:
    name: str
    text_size: int
    iterations: int
    odin_avg_ns: int
    rust_avg_ns: int
    odin_throughput: float
    rust_throughput: float
    throughput_ratio: float
    status_odin: str
    status_rust: str
    matched_odin: bool
    matched_rust: bool
    notes_odin: str
    notes_rust: str


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Run Odin vs Rust comparison suites and generate reports."
    )
    parser.add_argument(
        "--cases",
        type=Path,
        default=DEFAULT_CASES,
        help="Path to functionality test case definition file.",
    )
    parser.add_argument(
        "--perf-scenarios",
        type=Path,
        default=DEFAULT_PERF_CASES,
        help="Path to performance scenario definition file.",
    )
    parser.add_argument(
        "--results-dir",
        type=Path,
        default=DEFAULT_RESULTS_DIR,
        help="Directory where intermediate and final results will be written.",
    )
    parser.add_argument(
        "--odin-runner",
        type=Path,
        default=Path("benchmark/functional_compare.odin"),
        help="Odin functionality runner entrypoint (relative to repo root).",
    )
    parser.add_argument(
        "--perf-odin-runner",
        type=Path,
        default=Path("benchmark/performance_benchmark.odin"),
        help="Odin performance runner entrypoint (relative to repo root).",
    )
    parser.add_argument(
        "--skip-exec",
        action="store_true",
        help="Skip executing runners and only regenerate reports from existing TSV files.",
    )
    parser.add_argument(
        "--verbose",
        action="store_true",
        help="Print additional diagnostic information while running.",
    )
    return parser.parse_args()


def run_command(cmd: List[str], cwd: Path, verbose: bool) -> None:
    if verbose:
        print(f"[cmd] {' '.join(cmd)}")
    subprocess.run(cmd, cwd=cwd, check=True)


def str_to_bool(value: str) -> bool:
    return value.lower() in {"true", "1", "yes"}


def ensure_directory(path: Path) -> None:
    path.mkdir(parents=True, exist_ok=True)


def load_functionality_tsv(path: Path) -> Dict[str, CaseRecord]:
    records: Dict[str, CaseRecord] = {}
    with path.open("r", encoding="utf-8", newline="") as handle:
        reader = csv.DictReader(handle, delimiter="\t")
        for row in reader:
            record = CaseRecord(
                name=row["name"],
                should_compile=str_to_bool(row["should_compile"]),
                compile_ok=str_to_bool(row["compile_ok"]),
                should_match=str_to_bool(row["should_match"]),
                actual_match=str_to_bool(row["actual_match"]),
                verify_full_match=str_to_bool(row["verify_full_match"]),
                match_verified=str_to_bool(row["match_verified"]),
                compile_ns=int(row["compile_ns"]),
                match_ns=int(row["match_ns"]),
                status=row["status"],
                notes=row.get("notes", ""),
            )
            records[record.name] = record
    return records


def load_performance_tsv(path: Path) -> Dict[str, PerfRecord]:
    records: Dict[str, PerfRecord] = {}
    with path.open("r", encoding="utf-8", newline="") as handle:
        reader = csv.DictReader(handle, delimiter="\t")
        for row in reader:
            throughput = row.get("throughput_mb_s", "").strip()
            throughput_value = float(throughput) if throughput else 0.0
            record = PerfRecord(
                name=row["name"],
                pattern=row.get("pattern", ""),
                text_size=int(row["text_size"]),
                iterations=int(row["iterations"]),
                compile_ns=int(row["compile_ns"]),
                match_total_ns=int(row["match_total_ns"]),
                match_avg_ns=int(row["match_avg_ns"]),
                throughput_mb_s=throughput_value,
                matched=str_to_bool(row.get("matched", "false")),
                status=row["status"],
                notes=row.get("notes", ""),
            )
            records[record.name] = record
    return records


def compare_functionality_records(
    odin_records: Dict[str, CaseRecord],
    rust_records: Dict[str, CaseRecord],
) -> Tuple[List[Tuple[CaseRecord, CaseRecord]], List[str]]:
    mismatches: List[Tuple[CaseRecord, CaseRecord]] = []
    missing: List[str] = []

    all_keys = set(odin_records.keys()) | set(rust_records.keys())
    for key in sorted(all_keys):
        odin = odin_records.get(key)
        rust = rust_records.get(key)
        if odin is None or rust is None:
            missing.append(key)
            continue

        if not records_align(odin, rust):
            mismatches.append((odin, rust))

    return mismatches, missing


def records_align(odin: CaseRecord, rust: CaseRecord) -> bool:
    if odin.status != rust.status:
        return False
    if odin.compile_ok != rust.compile_ok:
        return False
    if odin.actual_match != rust.actual_match:
        return False
    if odin.verify_full_match and rust.verify_full_match:
        if odin.match_verified != rust.match_verified:
            return False
    return True


def write_functionality_report(
    output_path: Path,
    odin_records: Dict[str, CaseRecord],
    rust_records: Dict[str, CaseRecord],
    mismatches: List[Tuple[CaseRecord, CaseRecord]],
    missing: List[str],
) -> None:
    timestamp = dt.datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    odin_pass = sum(1 for item in odin_records.values() if item.status == "PASS")
    rust_pass = sum(1 for item in rust_records.values() if item.status == "PASS")
    total = len(set(odin_records.keys()) | set(rust_records.keys()))
    both_pass = sum(
        1
        for name in odin_records
        if name in rust_records
        and odin_records[name].status == "PASS"
        and rust_records[name].status == "PASS"
    )

    lines: List[str] = []
    lines.append("# Odin RE2 vs Rust regex – Functionality Comparison")
    lines.append("")
    lines.append(f"_Generated on {timestamp}_")
    lines.append("")
    lines.append("## Summary")
    lines.append(f"- Total cases: **{total}**")
    lines.append(f"- Odin passes: **{odin_pass}**")
    lines.append(f"- Rust passes: **{rust_pass}**")
    lines.append(f"- Both pass: **{both_pass}**")
    lines.append(f"- Mismatches: **{len(mismatches)}**")
    if missing:
        lines.append(f"- Missing cases: **{len(missing)}** (`{', '.join(missing)}`)")
    lines.append("")

    lines.append("## Detailed Mismatches")
    lines.append("")
    if mismatches:
        lines.append(
            "| Case | Odin Status | Rust Status | Odin Match | Rust Match | Notes |"
        )
        lines.append("|------|-------------|-------------|------------|------------|-------|")
        for odin, rust in mismatches:
            lines.append(
                "| {name} | {ostatus} | {rstatus} | {omatch} | {rmatch} | Odin: {onote} / Rust: {rnote} |".format(
                    name=odin.name,
                    ostatus=odin.status,
                    rstatus=rust.status,
                    omatch=str(odin.actual_match),
                    rmatch=str(rust.actual_match),
                    onote=escape_pipe(odin.notes or "-"),
                    rnote=escape_pipe(rust.notes or "-"),
                )
            )
    else:
        lines.append("All test cases aligned between Odin and Rust for functionality.")

    lines.append("")
    lines.append("## Data Artifacts")
    lines.append(
        "- `functional_odin.tsv` – raw Odin results\n"
        "- `functional_rust.tsv` – raw Rust results"
    )
    lines.append("")
    lines.append("> These TSV files use tab delimiters and UTF-8 encoding.")

    output_path.write_text("\n".join(lines), encoding="utf-8")


def compare_performance_records(
    odin_records: Dict[str, PerfRecord],
    rust_records: Dict[str, PerfRecord],
) -> Tuple[List[PerfComparisonRow], List[PerfComparisonRow], List[str]]:
    rows: List[PerfComparisonRow] = []
    mismatches: List[PerfComparisonRow] = []
    missing: List[str] = []

    all_keys = set(odin_records.keys()) | set(rust_records.keys())
    for key in sorted(all_keys):
        odin = odin_records.get(key)
        rust = rust_records.get(key)
        if odin is None or rust is None:
            missing.append(key)
            continue

        ratio = (
            odin.throughput_mb_s / rust.throughput_mb_s
            if rust.throughput_mb_s > 0
            else (float("inf") if odin.throughput_mb_s > 0 else 0.0)
        )

        row = PerfComparisonRow(
            name=key,
            text_size=max(odin.text_size, rust.text_size),
            iterations=max(odin.iterations, rust.iterations),
            odin_avg_ns=odin.match_avg_ns,
            rust_avg_ns=rust.match_avg_ns,
            odin_throughput=odin.throughput_mb_s,
            rust_throughput=rust.throughput_mb_s,
            throughput_ratio=ratio,
            status_odin=odin.status,
            status_rust=rust.status,
            matched_odin=odin.matched,
            matched_rust=rust.matched,
            notes_odin=odin.notes,
            notes_rust=rust.notes,
        )
        rows.append(row)

        if odin.status != rust.status or odin.matched != rust.matched:
            mismatches.append(row)

    return rows, mismatches, missing


def write_performance_report(
    output_path: Path,
    rows: List[PerfComparisonRow],
    mismatches: List[PerfComparisonRow],
    missing: List[str],
) -> None:
    timestamp = dt.datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    total = len(rows)
    odin_avg = average([row.odin_throughput for row in rows])
    rust_avg = average([row.rust_throughput for row in rows])
    ratio_values = [
        row.throughput_ratio for row in rows if math.isfinite(row.throughput_ratio)
    ]
    ratio_avg = average(ratio_values) if ratio_values else 0.0
    odin_faster = sum(1 for row in rows if row.throughput_ratio > 1.0)
    rust_faster = sum(1 for row in rows if 0.0 < row.throughput_ratio < 1.0)

    lines: List[str] = []
    lines.append("# Odin RE2 vs Rust regex – Performance Comparison")
    lines.append("")
    lines.append(f"_Generated on {timestamp}_")
    lines.append("")
    lines.append("## Summary")
    lines.append(f"- Total scenarios: **{total}**")
    lines.append(f"- Odin avg throughput: **{odin_avg:.2f} MB/s**")
    lines.append(f"- Rust avg throughput: **{rust_avg:.2f} MB/s**")
    lines.append(f"- Avg throughput ratio (Odin/Rust): **{ratio_avg:.2f}**")
    lines.append(f"- Odin faster on: **{odin_faster}** scenarios")
    lines.append(f"- Rust faster on: **{rust_faster}** scenarios")
    lines.append(f"- Mismatches: **{len(mismatches)}**")
    if missing:
        lines.append(f"- Missing scenarios: **{len(missing)}** (`{', '.join(missing)}`)")
    lines.append("")

    lines.append("## Status Mismatches")
    lines.append("")
    if mismatches:
        lines.append("| Scenario | Odin Status | Rust Status | Notes |")
        lines.append("|----------|-------------|-------------|-------|")
        for row in mismatches:
            lines.append(
                "| {name} | {ostatus} | {rstatus} | Odin: {onote} / Rust: {rnote} |".format(
                    name=row.name,
                    ostatus=row.status_odin,
                    rstatus=row.status_rust,
                    onote=escape_pipe(row.notes_odin or "-"),
                    rnote=escape_pipe(row.notes_rust or "-"),
                )
            )
    else:
        lines.append("No status differences detected between Odin and Rust.")

    lines.append("")
    lines.append("## Detailed Results")
    lines.append("")
    lines.append(
        "| Scenario | Text Size | Iterations | Odin Avg ns | Rust Avg ns | Odin MB/s | Rust MB/s | Ratio (O/R) | Status (O/R) | Notes |"
    )
    lines.append(
        "|----------|-----------|------------|--------------|--------------|-----------|-----------|--------------|---------------|-------|"
    )
    for row in rows:
        lines.append(
            "| {name} | {size} | {iters} | {o_ns} | {r_ns} | {o_mb:.2f} | {r_mb:.2f} | {ratio} | {ostatus}/{rstatus} | Odin: {onote} / Rust: {rnote} |".format(
                name=row.name,
                size=row.text_size,
                iters=row.iterations,
                o_ns=row.odin_avg_ns,
                r_ns=row.rust_avg_ns,
                o_mb=row.odin_throughput,
                r_mb=row.rust_throughput,
                ratio=format_ratio(row.throughput_ratio),
                ostatus=row.status_odin,
                rstatus=row.status_rust,
                onote=escape_pipe(row.notes_odin or "-"),
                rnote=escape_pipe(row.notes_rust or "-"),
            )
        )

    lines.append("")
    lines.append("## Data Artifacts")
    lines.append(
        "- `performance_odin.tsv` – raw Odin results\n"
        "- `performance_rust.tsv` – raw Rust results"
    )
    lines.append("")
    lines.append("> These TSV files use tab delimiters and UTF-8 encoding.")

    output_path.write_text("\n".join(lines), encoding="utf-8")


def escape_pipe(value: str) -> str:
    return value.replace("|", "\\|")


def average(values: List[float]) -> float:
    filtered = [v for v in values if v > 0]
    if not filtered:
        return 0.0
    return sum(filtered) / len(filtered)


def format_ratio(value: float) -> str:
    if math.isnan(value):
        return "n/a"
    if math.isinf(value):
        return "inf"
    return f"{value:.2f}"


def main() -> None:
    args = parse_args()

    cases_path = (REPO_ROOT / args.cases).resolve()
    perf_cases_path = (REPO_ROOT / args.perf_scenarios).resolve()
    results_dir = (REPO_ROOT / args.results_dir).resolve()
    ensure_directory(results_dir)
    bin_dir = results_dir / "bin"
    ensure_directory(bin_dir)

    timestamp_suffix = dt.datetime.now().strftime("%Y%m%d%H%M%S")

    func_odin_output = results_dir / "functional_odin.tsv"
    func_rust_output = results_dir / "functional_rust.tsv"
    perf_odin_output = results_dir / "performance_odin.tsv"
    perf_rust_output = results_dir / "performance_rust.tsv"
    func_bin = bin_dir / f"functional_odin_{timestamp_suffix}.exe"
    perf_bin = bin_dir / f"performance_odin_{timestamp_suffix}.exe"

    if not args.skip_exec:
        func_runner = (REPO_ROOT / args.odin_runner).resolve()
        perf_runner = (REPO_ROOT / args.perf_odin_runner).resolve()

        if func_bin.exists():
            try:
                func_bin.unlink()
            except OSError:
                pass
        run_command(
            [
                "odin",
                "run",
                str(func_runner),
                "-file",
                f"-out:{func_bin}",
                "--",
                "-cases",
                str(cases_path),
                "-output",
                str(func_odin_output),
            ],
            cwd=REPO_ROOT,
            verbose=args.verbose,
        )

        if perf_bin.exists():
            try:
                perf_bin.unlink()
            except OSError:
                pass
        run_command(
            [
                "odin",
                "run",
                str(perf_runner),
                "-file",
                f"-out:{perf_bin}",
                "--",
                "-scenarios",
                str(perf_cases_path),
                "-output",
                str(perf_odin_output),
            ],
            cwd=REPO_ROOT,
            verbose=args.verbose,
        )

        run_command(
            [
                "cargo",
                "run",
                "--quiet",
                "--release",
                "--",
                "--mode",
                "functionality",
                "--cases",
                str(cases_path),
                "--output",
                str(func_rust_output),
            ],
            cwd=(REPO_ROOT / "benchmark"),
            verbose=args.verbose,
        )

        run_command(
            [
                "cargo",
                "run",
                "--quiet",
                "--release",
                "--",
                "--mode",
                "performance",
                "--cases",
                str(perf_cases_path),
                "--output",
                str(perf_rust_output),
            ],
            cwd=(REPO_ROOT / "benchmark"),
            verbose=args.verbose,
        )

    odin_func_records = load_functionality_tsv(func_odin_output)
    rust_func_records = load_functionality_tsv(func_rust_output)
    func_mismatches, func_missing = compare_functionality_records(
        odin_func_records, rust_func_records
    )
    func_report = results_dir / "functionality_comparison.md"
    write_functionality_report(
        func_report, odin_func_records, rust_func_records, func_mismatches, func_missing
    )

    odin_perf_records = load_performance_tsv(perf_odin_output)
    rust_perf_records = load_performance_tsv(perf_rust_output)
    perf_rows, perf_mismatches, perf_missing = compare_performance_records(
        odin_perf_records, rust_perf_records
    )
    perf_report = results_dir / "performance_comparison.md"
    write_performance_report(perf_report, perf_rows, perf_mismatches, perf_missing)

    print("Functionality comparison complete.")
    print(f"- Odin results: {func_odin_output}")
    print(f"- Rust results: {func_rust_output}")
    print(f"- Report: {func_report}")
    if func_mismatches:
        names = ", ".join(record.name for record, _ in func_mismatches)
        print(f"Functionality mismatches: {names}")

    print("Performance comparison complete.")
    print(f"- Odin results: {perf_odin_output}")
    print(f"- Rust results: {perf_rust_output}")
    print(f"- Report: {perf_report}")
    if perf_mismatches:
        names = ", ".join(row.name for row in perf_mismatches)
        print(f"Performance mismatches: {names}")


if __name__ == "__main__":
    main()
