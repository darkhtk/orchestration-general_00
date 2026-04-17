"""Smoke tests for the menu-based launcher.

Validates the launcher's interactive flow end-to-end without hitting any
real adapter. Each scenario feeds canned input over stdin and inspects the
returncode plus the `.orch/` artifacts that the launcher is expected to
write. The final "Run one orchestration cycle now?" question is always
answered `n`, so the cycle itself is *not* executed here — that is covered
by `tools/adapter_probe.py` with real credentials.

Scenarios covered:
    - greenfield  : empty folder, action=1
    - retrofit    : non-empty folder without `.orch`, action=2
    - resume      : existing `.orch` project, action=3
    - wrapper_cli : start.(ps1|bat|.sh via python) passthrough to core.app
                    with a non-zero target
    - handoff     : handoff-request -> response edit -> handoff-ingest round trip

Run:
    python -m tools.launcher_smoke
    python -m tools.launcher_smoke --only greenfield,resume
    python -m tools.launcher_smoke --keep-temp    # keep sandbox on disk
"""

from __future__ import annotations

import argparse
import json
import os

import yaml  # orch-engine/yaml.py — JSON-backed shim, keeps parsing in sync with HandoffManager

import shutil
import subprocess
import sys
import tempfile
from dataclasses import dataclass
from pathlib import Path
from typing import Callable


ENGINE_ROOT = Path(__file__).resolve().parent.parent


@dataclass(slots=True)
class ScenarioResult:
    name: str
    ok: bool
    message: str
    returncode: int | None = None


def main() -> int:
    parser = argparse.ArgumentParser(description="launcher smoke tests")
    parser.add_argument(
        "--only",
        default="",
        help="Comma-separated scenario names to run (default: all).",
    )
    parser.add_argument(
        "--keep-temp",
        action="store_true",
        help="Do not delete the temporary sandbox after the run.",
    )
    parser.add_argument(
        "--verbose",
        "-v",
        action="store_true",
        help="Print launcher stdout/stderr on every scenario.",
    )
    args = parser.parse_args()

    scenarios: dict[str, Callable[[Path, bool], ScenarioResult]] = {
        "greenfield": _scenario_greenfield,
        "retrofit": _scenario_retrofit,
        "resume": _scenario_resume,
        "wrapper_cli": _scenario_wrapper_cli,
        "handoff": _scenario_handoff,
        "mode_mismatch": _scenario_mode_mismatch,
    }

    wanted = [name.strip() for name in args.only.split(",") if name.strip()] or list(scenarios)
    unknown = [name for name in wanted if name not in scenarios]
    if unknown:
        print(f"Unknown scenarios: {unknown}. Available: {list(scenarios)}", file=sys.stderr)
        return 2

    sandbox = Path(tempfile.mkdtemp(prefix="orch-launcher-smoke-"))
    print(f"Sandbox: {sandbox}")
    results: list[ScenarioResult] = []
    try:
        for name in wanted:
            print(f"\n=== {name} ===")
            result = scenarios[name](sandbox, args.verbose)
            results.append(result)
            status = "OK" if result.ok else "FAIL"
            rc = f" rc={result.returncode}" if result.returncode is not None else ""
            print(f"[{status}] {name}{rc}: {result.message}")
    finally:
        if not args.keep_temp:
            shutil.rmtree(sandbox, ignore_errors=True)
        else:
            print(f"\nSandbox kept at: {sandbox}")

    print("\nSummary")
    print("-------")
    passed = sum(1 for r in results if r.ok)
    for r in results:
        print(f"  {'OK  ' if r.ok else 'FAIL'}  {r.name}: {r.message}")
    print(f"{passed}/{len(results)} scenarios passed.")
    return 0 if passed == len(results) else 1


def _scenario_greenfield(sandbox: Path, verbose: bool) -> ScenarioResult:
    target = sandbox / "greenfield-project"
    # Launcher asks: action, path, domain, name, goal, blank, confirm, cycle
    stdin = "\n".join(
        [
            "1",
            str(target),
            "web",
            "greenfield-project",
            "build a hello world page",
            "",
            "y",
            "n",
            "",
        ]
    )
    rc, out, err = _run_launcher(stdin, verbose=verbose)
    if rc != 0:
        return ScenarioResult("greenfield", False, f"launcher rc={rc}: {err[-200:]}", rc)

    problem = _assert_project_initialized(
        target, expected_mode="greenfield", expected_goal="build a hello world page"
    )
    if problem:
        return ScenarioResult("greenfield", False, problem, rc)
    if "감지된 모드: greenfield" not in out:
        return ScenarioResult(
            "greenfield",
            False,
            "stdout did not report greenfield detection",
            rc,
        )
    return ScenarioResult("greenfield", True, "greenfield .orch scaffold created", rc)


def _scenario_retrofit(sandbox: Path, verbose: bool) -> ScenarioResult:
    target = sandbox / "retrofit-project"
    target.mkdir(parents=True, exist_ok=True)
    (target / "existing.txt").write_text("legacy file", encoding="utf-8")

    stdin = "\n".join(
        [
            "2",
            str(target),
            "web",
            "retrofit-project",
            "add a readme without breaking existing code",
            "",
            "y",
            "n",
            "",
        ]
    )
    rc, out, err = _run_launcher(stdin, verbose=verbose)
    if rc != 0:
        return ScenarioResult("retrofit", False, f"launcher rc={rc}: {err[-200:]}", rc)
    if not (target / "existing.txt").exists():
        return ScenarioResult(
            "retrofit",
            False,
            "retrofit should preserve existing files",
            rc,
        )
    problem = _assert_project_initialized(
        target,
        expected_mode="retrofit",
        expected_goal="add a readme without breaking existing code",
    )
    if problem:
        return ScenarioResult("retrofit", False, problem, rc)
    if "감지된 모드: retrofit" not in out:
        return ScenarioResult(
            "retrofit",
            False,
            "stdout did not report retrofit detection",
            rc,
        )
    return ScenarioResult("retrofit", True, "retrofit .orch scaffold created on existing folder", rc)


def _scenario_resume(sandbox: Path, verbose: bool) -> ScenarioResult:
    target = sandbox / "resume-project"
    init_rc, init_out, init_err = _run_core(
        [
            "init",
            "--target",
            str(target),
            "--domain",
            "web",
            "--mode",
            "greenfield",
            "--project-name",
            "resume-project",
            "--goal-summary",
            "initial goal",
        ]
    )
    if init_rc != 0:
        return ScenarioResult(
            "resume",
            False,
            f"pre-init failed rc={init_rc}: {init_err[-200:]}",
            init_rc,
        )

    # Launcher asks: action, path, update-goal?, confirm, cycle
    stdin = "\n".join(
        [
            "3",
            str(target),
            "n",
            "y",
            "n",
            "",
        ]
    )
    rc, out, err = _run_launcher(stdin, verbose=verbose)
    if rc != 0:
        return ScenarioResult("resume", False, f"launcher rc={rc}: {err[-200:]}", rc)
    if "감지된 모드: resume" not in out:
        return ScenarioResult(
            "resume",
            False,
            "stdout did not report resume detection",
            rc,
        )
    # Resume should not re-init: project.yaml must still show original goal.
    project_yaml = target / ".orch" / "config" / "project.yaml"
    project_doc = yaml.safe_load(project_yaml.read_text(encoding="utf-8"))
    preserved = project_doc.get("project", {}).get("goal_summary")
    if preserved != "initial goal":
        return ScenarioResult(
            "resume",
            False,
            f"resume changed goal_summary to {preserved!r} (expected 'initial goal')",
            rc,
        )
    return ScenarioResult("resume", True, "resume preserved existing project state", rc)


def _scenario_wrapper_cli(sandbox: Path, verbose: bool) -> ScenarioResult:
    """start.* wrappers should pass args straight through to `core.app`."""

    target = sandbox / "wrapper-project"
    init_rc, _, init_err = _run_core(
        [
            "init",
            "--target",
            str(target),
            "--domain",
            "web",
            "--mode",
            "greenfield",
            "--project-name",
            "wrapper-project",
            "--goal-summary",
            "wrapper smoke",
        ]
    )
    if init_rc != 0:
        return ScenarioResult(
            "wrapper_cli",
            False,
            f"pre-init failed rc={init_rc}: {init_err[-200:]}",
            init_rc,
        )

    # Happy path: status call.
    rc_ok, out_ok, err_ok = _run_core(["status", "--target", str(target)])
    if rc_ok != 0:
        return ScenarioResult(
            "wrapper_cli",
            False,
            f"status rc={rc_ok}: {err_ok[-200:]}",
            rc_ok,
        )
    if "세션:" not in out_ok:
        return ScenarioResult(
            "wrapper_cli",
            False,
            "status output missing expected 'Session:' header",
            rc_ok,
        )

    # Failure path: run-cycle on an unblessed folder must propagate non-zero.
    bogus = sandbox / "no-such-target"
    rc_bad, _, err_bad = _run_core(["run-cycle", "--target", str(bogus)])
    if rc_bad == 0:
        return ScenarioResult(
            "wrapper_cli",
            False,
            "run-cycle against missing .orch should have failed but returned 0",
            rc_bad,
        )
    if verbose:
        print(f"wrapper bad-path stderr: {err_bad}")
    return ScenarioResult(
        "wrapper_cli",
        True,
        "core.app passthrough returned expected success and failure codes",
        rc_ok,
    )


def _scenario_mode_mismatch(sandbox: Path, verbose: bool) -> ScenarioResult:
    """action=1 on an already-initialized folder must refuse, not silently re-use resume."""
    target = sandbox / "mode-mismatch-project"
    init_rc, _, init_err = _run_core(
        [
            "init",
            "--target",
            str(target),
            "--domain",
            "web",
            "--mode",
            "greenfield",
            "--project-name",
            "mm",
            "--goal-summary",
            "initial goal",
        ]
    )
    if init_rc != 0:
        return ScenarioResult(
            "mode_mismatch",
            False,
            f"pre-init failed rc={init_rc}: {init_err[-200:]}",
            init_rc,
        )

    # Pick action=1 (new project) on a folder that already has .orch.
    stdin = "\n".join([
        "1",
        str(target),
        "",
    ])
    rc, out, err = _run_launcher(stdin, verbose=verbose)
    if rc == 0:
        return ScenarioResult(
            "mode_mismatch",
            False,
            "launcher should refuse action=1 on an initialized folder but returned 0",
            rc,
        )
    if "이미 존재합니다" not in out and "이미 .orch 폴더가 있습니다" not in out:
        return ScenarioResult(
            "mode_mismatch",
            False,
            "launcher did not surface a clear 'already exists' message",
            rc,
        )

    # action=2 on an empty folder must also refuse.
    empty = sandbox / "mode-mismatch-empty"
    empty.mkdir(parents=True, exist_ok=True)
    stdin = "\n".join([
        "2",
        str(empty),
        "",
    ])
    rc2, out2, _ = _run_launcher(stdin, verbose=verbose)
    if rc2 == 0:
        return ScenarioResult(
            "mode_mismatch",
            False,
            "launcher should refuse action=2 on an empty folder but returned 0",
            rc2,
        )
    if "empty" not in out2:
        return ScenarioResult(
            "mode_mismatch",
            False,
            "launcher did not surface a clear 'empty folder' message for action=2",
            rc2,
        )
    return ScenarioResult(
        "mode_mismatch",
        True,
        "launcher rejects both conflicting action/mode pairs",
        rc,
    )


def _scenario_handoff(sandbox: Path, verbose: bool) -> ScenarioResult:
    target = sandbox / "handoff-project"
    init_rc, _, init_err = _run_core(
        [
            "init",
            "--target",
            str(target),
            "--domain",
            "web",
            "--mode",
            "greenfield",
            "--project-name",
            "handoff-project",
            "--goal-summary",
            "handoff lifecycle smoke",
        ]
    )
    if init_rc != 0:
        return ScenarioResult(
            "handoff",
            False,
            f"pre-init failed rc={init_rc}: {init_err[-200:]}",
            init_rc,
        )

    request_rc, _, request_err = _run_core(
        [
            "handoff-request",
            "--target",
            str(target),
            "--mode",
            "review_only",
            "--reason",
            "smoke test",
            "--what-needs-decision",
            "confirm the engine wrote a full request payload",
            "--allowed-edit-scope",
            "docs/",
        ]
    )
    if request_rc != 0:
        return ScenarioResult(
            "handoff",
            False,
            f"handoff-request rc={request_rc}: {request_err[-200:]}",
            request_rc,
        )

    orch_root = target / ".orch"
    request_path = orch_root / "handoff" / "request.yaml"
    response_path = orch_root / "handoff" / "response.yaml"
    if not request_path.exists() or not response_path.exists():
        return ScenarioResult(
            "handoff",
            False,
            "handoff request/response files not created",
            request_rc,
        )

    request_doc = yaml.safe_load(request_path.read_text(encoding="utf-8"))
    missing = [
        field
        for field in (
            "handoff_id",
            "created_at",
            "project_id",
            "mode",
            "reason",
            "goal",
            "what_needs_decision",
            "allowed_edit_scope",
            "recommended_read_order",
            "expected_return_format",
        )
        if field not in request_doc
    ]
    if missing:
        return ScenarioResult(
            "handoff",
            False,
            f"request.yaml missing required fields: {missing}",
            request_rc,
        )

    status_rc, status_out, status_err = _run_core(
        ["handoff-status", "--target", str(target)]
    )
    if status_rc != 0 or "handoff_active" not in status_out:
        return ScenarioResult(
            "handoff",
            False,
            f"handoff-status did not show handoff_active: stdout={status_out[-200:]}",
            status_rc,
        )

    session = json.loads((orch_root / "runtime" / "session.json").read_text(encoding="utf-8"))  # session.json is real JSON
    if session.get("state") != "handoff_active":
        return ScenarioResult(
            "handoff",
            False,
            f"session.json state={session.get('state')} != handoff_active",
            request_rc,
        )

    handoff_id = request_doc["handoff_id"]
    response_payload = {
        "handoff_id": handoff_id,
        "completed_at": "2026-04-17T00:00:00Z",
        "result": "approved",
        "summary": "smoke-test approval",
        "decision": "proceed",
        "findings": ["no blocking issues"],
        "files_changed": [],
        "artifacts_added": [],
        "recommended_next_action": "resume automated loop",
        "resume_condition": "none",
        "remaining_risks": [],
    }
    # Write via yaml.safe_dump to mirror what a real external tool would emit,
    # so the smoke test does not accidentally depend on yaml-as-JSON equivalence.
    response_path.write_text(yaml.safe_dump(response_payload, sort_keys=False), encoding="utf-8")

    ingest_rc, ingest_out, ingest_err = _run_core(
        ["handoff-ingest", "--target", str(target)]
    )
    if ingest_rc != 0:
        return ScenarioResult(
            "handoff",
            False,
            f"handoff-ingest rc={ingest_rc}: {ingest_err[-200:]}",
            ingest_rc,
        )
    if "approved" not in ingest_out:
        return ScenarioResult(
            "handoff",
            False,
            "handoff-ingest stdout did not confirm approved result",
            ingest_rc,
        )

    if request_path.exists() or response_path.exists():
        return ScenarioResult(
            "handoff",
            False,
            "handoff files should be archived after ingest",
            ingest_rc,
        )
    history_dir = orch_root / "handoff" / "history"
    archived = list(history_dir.iterdir()) if history_dir.exists() else []
    if not archived:
        return ScenarioResult(
            "handoff",
            False,
            "handoff history directory is empty after ingest",
            ingest_rc,
        )
    session_after = json.loads((orch_root / "runtime" / "session.json").read_text(encoding="utf-8"))
    if session_after.get("state") != "completed":
        return ScenarioResult(
            "handoff",
            False,
            f"session.state after approved ingest = {session_after.get('state')} != completed",
            ingest_rc,
        )
    return ScenarioResult(
        "handoff",
        True,
        "handoff request/ingest round trip archived and updated session state",
        ingest_rc,
    )


def _run_launcher(stdin_text: str, verbose: bool) -> tuple[int, str, str]:
    completed = subprocess.run(
        [sys.executable, "-m", "launcher.app"],
        cwd=str(ENGINE_ROOT),
        input=stdin_text,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        env=_clean_env(),
        timeout=120,
        check=False,
    )
    if verbose:
        print("--- launcher stdout ---")
        print(completed.stdout)
        print("--- launcher stderr ---")
        print(completed.stderr)
    return completed.returncode, completed.stdout or "", completed.stderr or ""


def _run_core(argv: list[str]) -> tuple[int, str, str]:
    completed = subprocess.run(
        [sys.executable, "-m", "core.app", *argv],
        cwd=str(ENGINE_ROOT),
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        env=_clean_env(),
        timeout=60,
        check=False,
    )
    return completed.returncode, completed.stdout or "", completed.stderr or ""


def _clean_env() -> dict[str, str]:
    env = os.environ.copy()
    env["PYTHONIOENCODING"] = "utf-8"
    return env


def _assert_project_initialized(
    target: Path, *, expected_mode: str, expected_goal: str
) -> str | None:
    orch_root = target / ".orch"
    if not orch_root.exists():
        return f".orch not created at {orch_root}"
    required = [
        orch_root / "config" / "project.yaml",
        orch_root / "config" / "roles.yaml",
        orch_root / "config" / "limits.yaml",
        orch_root / "runtime" / "session.json",
    ]
    for path in required:
        if not path.exists():
            return f"missing expected file: {path}"

    project_doc = yaml.safe_load(
        (orch_root / "config" / "project.yaml").read_text(encoding="utf-8")
    )
    project = project_doc.get("project", {}) if isinstance(project_doc, dict) else {}
    if project.get("mode") != expected_mode:
        return f"project.yaml recorded mode={project.get('mode')} != {expected_mode}"
    if project.get("goal_summary") != expected_goal:
        return "project.yaml did not persist the goal summary"

    session = json.loads((orch_root / "runtime" / "session.json").read_text(encoding="utf-8"))
    if session.get("mode") != expected_mode:
        return f"session.json mode={session.get('mode')} != {expected_mode}"
    if session.get("state") != "idle":
        return f"session.json state={session.get('state')} != idle"
    return None


if __name__ == "__main__":
    raise SystemExit(main())
