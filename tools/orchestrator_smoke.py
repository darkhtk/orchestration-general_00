"""Orchestrator role regression (scripted, no live LLM).

`cycle_e2e_smoke` already exercises the auto-derive path where
ScriptedAdapter converts each verifier `result` into an orchestrator
decision. These scenarios cover the paths that matter specifically
for the LLM orchestrator contract (Phase 3 transition, 2026-04-20):

  1. override_iterate_despite_high_scores — verifier 1.00/1.00 pass
     but orchestrator judges `needs_iteration` because the master
     objective is not yet satisfied. Proves score threshold is no
     longer the deciding factor.

  2. override_blocked_despite_pass — verifier pass scores but
     orchestrator returns `blocked`. Proves orchestrator can hard-stop
     independently of verifier results.

  3. unknown_decision_blocks_cycle — orchestrator returns an enum value
     that is not in {complete_cycle, needs_iteration, blocked}. Cycle
     must fail with rc=2 and session.state=blocked (no rule-based
     fallback, per project philosophy §3-4).

  4. orchestrator_sees_full_reviews — orchestrator's invocation.context
     must include both verifier reviews + score history so the LLM has
     enough grounding to judge. Contract test.
"""

from __future__ import annotations

import argparse
import shutil
import sys
import tempfile
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Callable

ENGINE_ROOT = Path(__file__).resolve().parent.parent
if str(ENGINE_ROOT) not in sys.path:
    sys.path.insert(0, str(ENGINE_ROOT))

from core import app  # noqa: E402
from tools.cycle_e2e_smoke import (  # noqa: E402
    ScenarioResult,
    _init_project,
    _install_scripted_adapters,
    _read_session,
    _run_cycle,
)


def _scenario_override_iterate_despite_high_scores(sandbox: Path) -> ScenarioResult:
    target = sandbox / "override-iterate"
    _init_project(target)
    adapters = _install_scripted_adapters(
        [
            {
                "functional": 1.00,
                "human": 1.00,
                "result": "pass",
                # Orchestrator disagrees with the verifiers despite perfect scores.
                "orchestrator_decision": "needs_iteration",
                "orchestrator_next_state": "iterating",
                "orchestrator_reason": "Scores perfect but objective not yet satisfied.",
                "orchestrator_unresolved": ["responsive layout missing", "copy placeholder"],
                "orchestrator_recommendation": "Next cycle: add responsive CSS + real copy.",
            }
        ]
    )
    rc = _run_cycle(target)
    if rc != 0:
        return ScenarioResult(
            "override_iterate_despite_high_scores", False, f"cycle rc={rc}"
        )
    session = _read_session(target)
    if session.get("state") != "iterating":
        return ScenarioResult(
            "override_iterate_despite_high_scores",
            False,
            f"state={session.get('state')} != iterating",
        )
    if session.get("last_decision") != "needs_iteration":
        return ScenarioResult(
            "override_iterate_despite_high_scores",
            False,
            f"decision={session.get('last_decision')} != needs_iteration",
        )
    history = session.get("score_history") or []
    if not history or float(history[-1].get("functional_score", 0.0)) < 0.99:
        return ScenarioResult(
            "override_iterate_despite_high_scores",
            False,
            f"score_history did not record 1.00 functional: {history}",
        )
    return ScenarioResult(
        "override_iterate_despite_high_scores",
        True,
        "orchestrator chose needs_iteration despite 1.00/1.00 verifier pass",
    )


def _scenario_override_blocked_despite_pass(sandbox: Path) -> ScenarioResult:
    target = sandbox / "override-blocked"
    _init_project(target)
    _install_scripted_adapters(
        [
            {
                "functional": 0.95,
                "human": 0.95,
                "result": "pass",
                "orchestrator_decision": "blocked",
                "orchestrator_next_state": "blocked",
                "orchestrator_reason": "Objective requires external resource the engine cannot provide.",
                "orchestrator_unresolved": ["needs human decision on API key"],
                "orchestrator_recommendation": "Pause and ask user for API credentials.",
            }
        ]
    )
    rc = _run_cycle(target)
    if rc != 0:
        return ScenarioResult(
            "override_blocked_despite_pass", False, f"cycle rc={rc}"
        )
    session = _read_session(target)
    if session.get("state") != "blocked":
        return ScenarioResult(
            "override_blocked_despite_pass",
            False,
            f"state={session.get('state')} != blocked",
        )
    if session.get("last_decision") != "blocked":
        return ScenarioResult(
            "override_blocked_despite_pass",
            False,
            f"decision={session.get('last_decision')} != blocked",
        )
    return ScenarioResult(
        "override_blocked_despite_pass",
        True,
        "orchestrator chose blocked despite verifier pass scores",
    )


def _scenario_unknown_decision_blocks_cycle(sandbox: Path) -> ScenarioResult:
    target = sandbox / "unknown-decision"
    _init_project(target)
    _install_scripted_adapters(
        [
            {
                "functional": 0.95,
                "human": 0.95,
                "result": "pass",
                # Invalid enum — not in {complete_cycle, needs_iteration, blocked}
                "orchestrator_decision": "obliterate",
                "orchestrator_next_state": "iterating",
                "orchestrator_reason": "intentionally invalid for test",
            }
        ]
    )
    rc = _run_cycle(target)
    # The cycle must NOT succeed. _run_orchestrator raises
    # AdapterExecutionError on unknown decision; run_cycle catches it and
    # returns rc=2 after marking the session blocked via
    # _finalize_adapter_failure.
    if rc != 2:
        return ScenarioResult(
            "unknown_decision_blocks_cycle",
            False,
            f"expected rc=2 on invalid decision, got rc={rc}",
        )
    session = _read_session(target)
    if session.get("state") != "blocked":
        return ScenarioResult(
            "unknown_decision_blocks_cycle",
            False,
            f"state={session.get('state')} != blocked",
        )
    return ScenarioResult(
        "unknown_decision_blocks_cycle",
        True,
        "unknown orchestrator decision raised AdapterExecutionError and blocked the cycle",
    )


def _scenario_orchestrator_sees_full_reviews(sandbox: Path) -> ScenarioResult:
    target = sandbox / "ctx-check"
    _init_project(target)
    adapters = _install_scripted_adapters(
        [
            {
                "functional": 0.85,
                "human": 0.80,
                "result": "needs_iteration",
            },
            {
                "functional": 0.95,
                "human": 0.92,
                "result": "pass",
            },
        ]
    )
    # Run two cycles so score_history has an entry when the second
    # orchestrator call runs.
    rc1 = _run_cycle(target)
    if rc1 != 0:
        return ScenarioResult(
            "orchestrator_sees_full_reviews", False, f"cycle1 rc={rc1}"
        )
    rc2 = _run_cycle(target)
    if rc2 != 0:
        return ScenarioResult(
            "orchestrator_sees_full_reviews", False, f"cycle2 rc={rc2}"
        )

    orch_adapter = adapters["orchestrator"]
    if len(orch_adapter.invocations) != 2:
        return ScenarioResult(
            "orchestrator_sees_full_reviews",
            False,
            f"expected 2 orchestrator invocations, got {len(orch_adapter.invocations)}",
        )
    ctx2 = orch_adapter.invocations[1].context or {}
    required_keys = {
        "cycle",
        "previous_state",
        "active_task",
        "functional_review",
        "human_review",
        "score_history",
    }
    missing = [k for k in required_keys if k not in ctx2]
    if missing:
        return ScenarioResult(
            "orchestrator_sees_full_reviews",
            False,
            f"orchestrator context missing keys: {missing}",
        )
    fr = ctx2.get("functional_review") or {}
    hr = ctx2.get("human_review") or {}
    if "result" not in fr or "score" not in fr:
        return ScenarioResult(
            "orchestrator_sees_full_reviews",
            False,
            f"functional_review shape incomplete: {fr!r}",
        )
    if "result" not in hr or "score" not in hr:
        return ScenarioResult(
            "orchestrator_sees_full_reviews",
            False,
            f"human_review shape incomplete: {hr!r}",
        )
    history = ctx2.get("score_history") or []
    if not history:
        return ScenarioResult(
            "orchestrator_sees_full_reviews",
            False,
            "score_history was empty on second orchestrator call",
        )
    return ScenarioResult(
        "orchestrator_sees_full_reviews",
        True,
        "orchestrator received functional_review + human_review + score_history",
    )


def _scenario_orchestrator_feedback_reaches_planner(sandbox: Path) -> ScenarioResult:
    """Phase 3.5 contract: orchestrator's judgment (reason + unresolved_items
    + recommended_next_action) must flow to the next iterating planner via
    previous_reviews.orchestrator. This closes the feedback loop that was
    left open when iteration_hint was removed in Phase 3.
    """
    target = sandbox / "feedback-reaches-planner"
    _init_project(target)
    adapters = _install_scripted_adapters(
        [
            {
                "functional": 0.85,
                "human": 0.80,
                "result": "needs_iteration",
                "orchestrator_decision": "needs_iteration",
                "orchestrator_next_state": "iterating",
                "orchestrator_reason": "objective still underbuilt — missing CSS",
                "orchestrator_unresolved": [
                    "responsive layout missing",
                    "WCAG AA contrast unverified",
                ],
                "orchestrator_recommendation": "Next cycle should add CSS covering mobile-first breakpoints.",
            },
            {
                "functional": 0.95,
                "human": 0.92,
                "result": "pass",
            },
        ]
    )
    rc1 = _run_cycle(target)
    if rc1 != 0:
        return ScenarioResult(
            "orchestrator_feedback_reaches_planner", False, f"cycle1 rc={rc1}"
        )
    rc2 = _run_cycle(target)
    if rc2 != 0:
        return ScenarioResult(
            "orchestrator_feedback_reaches_planner", False, f"cycle2 rc={rc2}"
        )
    planner_adapter = adapters["planner"]
    if len(planner_adapter.invocations) < 2:
        return ScenarioResult(
            "orchestrator_feedback_reaches_planner",
            False,
            f"expected >=2 planner invocations, got {len(planner_adapter.invocations)}",
        )
    ctx = planner_adapter.invocations[1].context or {}
    prior = ctx.get("previous_reviews") or {}
    if not isinstance(prior, dict):
        return ScenarioResult(
            "orchestrator_feedback_reaches_planner",
            False,
            f"previous_reviews not a dict: {prior!r}",
        )
    block = prior.get("orchestrator")
    if not isinstance(block, dict):
        return ScenarioResult(
            "orchestrator_feedback_reaches_planner",
            False,
            f"previous_reviews.orchestrator missing: {prior!r}",
        )
    if block.get("decision") != "needs_iteration":
        return ScenarioResult(
            "orchestrator_feedback_reaches_planner",
            False,
            f"orchestrator.decision={block.get('decision')} != needs_iteration",
        )
    if "responsive layout missing" not in (block.get("unresolved_items") or []):
        return ScenarioResult(
            "orchestrator_feedback_reaches_planner",
            False,
            f"orchestrator.unresolved_items missing: {block.get('unresolved_items')}",
        )
    if "mobile-first" not in (block.get("recommended_next_action") or ""):
        return ScenarioResult(
            "orchestrator_feedback_reaches_planner",
            False,
            f"orchestrator.recommended_next_action missing: {block.get('recommended_next_action')}",
        )
    # And: once cycle2 completes successfully, orchestrator_latest must be
    # cleared so subsequent work does not inherit stale reasoning.
    import json as _json
    latest_path = target / ".orch" / "reviews" / "orchestrator_latest.json"
    if latest_path.exists():
        stored = _json.loads(latest_path.read_text(encoding="utf-8"))
        if stored.get("decision"):
            return ScenarioResult(
                "orchestrator_feedback_reaches_planner",
                False,
                f"orchestrator_latest.json not cleared after complete_cycle: {stored!r}",
            )
    return ScenarioResult(
        "orchestrator_feedback_reaches_planner",
        True,
        "orchestrator reason + unresolved + recommendation reached planner; cleared on complete",
    )


SCENARIOS: dict[str, Callable[[Path], ScenarioResult]] = {
    "override_iterate_despite_high_scores": _scenario_override_iterate_despite_high_scores,
    "override_blocked_despite_pass": _scenario_override_blocked_despite_pass,
    "unknown_decision_blocks_cycle": _scenario_unknown_decision_blocks_cycle,
    "orchestrator_sees_full_reviews": _scenario_orchestrator_sees_full_reviews,
    "orchestrator_feedback_reaches_planner": _scenario_orchestrator_feedback_reaches_planner,
}


def main() -> int:
    parser = argparse.ArgumentParser(description="Orchestrator role smoke")
    parser.add_argument("--only", default="", help="Comma-separated scenario names")
    parser.add_argument("--keep-temp", action="store_true")
    args = parser.parse_args()

    original_build_adapter = app._build_adapter
    wanted = [name.strip() for name in args.only.split(",") if name.strip()] or list(SCENARIOS)
    unknown = [name for name in wanted if name not in SCENARIOS]
    if unknown:
        print(f"Unknown scenarios: {unknown}")
        return 2

    sandbox = Path(tempfile.mkdtemp(prefix="orch-orchestrator-smoke-"))
    print(f"Sandbox: {sandbox}")
    results: list[ScenarioResult] = []
    try:
        for name in wanted:
            print(f"\n=== {name} ===")
            try:
                result = SCENARIOS[name](sandbox)
            except Exception as exc:  # noqa: BLE001
                result = ScenarioResult(name, False, f"scenario raised: {exc!r}")
            results.append(result)
            status = "OK" if result.ok else "FAIL"
            print(f"[{status}] {name}: {result.message}")
            app._build_adapter = original_build_adapter  # type: ignore[assignment]
    finally:
        if not args.keep_temp:
            shutil.rmtree(sandbox, ignore_errors=True)

    print("\nSummary")
    print("-------")
    for result in results:
        status = "OK  " if result.ok else "FAIL"
        print(f"  {status}  {result.name}: {result.message}")
    passed = sum(1 for r in results if r.ok)
    total = len(results)
    print(f"{passed}/{total} scenarios passed.")
    return 0 if passed == total else 1


if __name__ == "__main__":
    raise SystemExit(main())
