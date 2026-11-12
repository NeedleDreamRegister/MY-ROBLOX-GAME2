"""Build the project-local skills explicitly requested on 2026-11-11.

Each row has a narrow trigger, a concrete action, and an observable check.
Existing skill directories are never overwritten.
"""

from pathlib import Path
import json


ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / ".agents" / "skills"


GROUPS = {
    "workflow": "Use the current task and available tools. Describe a recommendation when the runtime itself controls the requested behavior; never claim to change model routing, context compaction, or token billing.",
    "review": "Inspect the actual artifact and owning sources. Separate observed facts, inferred risks, and unverified assumptions. Run only checks that can resolve a concrete risk.",
    "engineering": "Inspect existing code, callers, and tests before changing an interface. Preserve working behavior and explain any impact on the other developer.",
    "roblox": "Read AGENTS.md and the affected source. Check changeable engine API details against current Roblox documentation or the connected Studio. The server owns rewards, mass, rights, and saves.",
    "sand": "Read GAME_DESIGN.md and the affected Luau modules. Preserve mass: collapse moves existing sand; dug or sold sand never reappears. Test the smallest relevant mountain first.",
    "game": "Read GAME_DESIGN.md and ROADMAP.md. Mark design ideas and balance numbers as proposals until player tests or measurements support them.",
    "art": "Read GAME_DESIGN.md and inspect the current scene or assets before proposing visual changes. Preserve clear gameplay feedback and mobile readability.",
    "ux": "Inspect the current interface and test the smallest relevant screen size. Keep player-facing copy and controls clear to a first-time player.",
    "project": "Read AGENTS.md, ROADMAP.md, and the actual work state. Keep code and Studio scene ownership explicit, and preserve the interface between A and B.",
    "research": "Use primary sources for technical claims. Attach a direct source to each changeable claim and state what remains unverified.",
    "marketing": "Use current platform rules and measured audience data where available. Treat hooks and forecasts as hypotheses; do not invent results or trends.",
    "personal": "Use the user's actual goals and constraints. Offer a practical, adjustable plan; for medical, exercise, nutrition, or sleep claims, verify current authoritative guidance first.",
}


# name | when to use | task-specific action | observable check
ROWS = r"""
workflow:
token-optimizer|estimating or reducing task token use|Trim repeated context and request only the files needed for the next decision|Check that constraints and essential evidence remain in the answer
context-compressor|preparing a compact context summary|Capture decisions, open risks, exact file paths, and next action in a handoff|Check that a fresh session can resume without the full transcript
smart-model-router|choosing a model for a new task|Recommend a model based on complexity, latency, and available access|State that model selection is a user or runtime action unless a routing tool exists
minimal-code-editor|making a small code change|Edit the smallest owning unit and inspect affected callers|Review the diff for unrelated edits
output-minimizer|the user requests a short report|Lead with result, evidence, unknowns, and next action only|Check that no consequential limitation was omitted
session-handoff|preparing another session to continue|Record current state, paths, pending decisions, and verification commands|Verify links and redact secrets
task-batcher|several independent read-only checks are needed|Batch independent searches and reads; keep dependent edits sequential|Confirm that every result was inspected
fact-checker|checking factual statements in a draft|Map each important claim to its owning source|Flag unsupported or stale claims
review:
independent-reviewer|requesting an independent code or design review|Give the reviewer the artifact and requirements without the proposed answer when delegation is authorized|Recheck each finding against source
hallucination-detector|auditing an answer for invented details|Compare names, paths, numbers, and test claims with artifacts|Remove or label every unsupported assertion
confidence-calibrator|reporting uncertain conclusions|Separate observed, inferred, and unknown facts|Tie confidence to evidence and counterexamples
logic-validator|checking rules or state transitions|Write invariants and trace edge cases through the actual implementation|Find a counterexample or explain why tested cases hold
source-verifier|validating cited technical claims|Open the primary page or source line that supports each claim|Reject citations that only discuss adjacent topics
assumption-auditor|a plan depends on unstated assumptions|List assumptions that would change the choice or implementation|Verify high-impact assumptions before committing
math-double-check|calculations affect balance or implementation|Recompute units and boundary cases independently|Show one reproducible calculation or test
evidence-first|summarizing completed work|State observed artifacts and test output before conclusions|Distinguish tests run from tests proposed
adversarial-review|stress-testing an important design|Try exploit, failure, concurrency, and recovery cases|Record surviving risks and practical mitigations
engineering:
senior-engineer|reviewing a consequential implementation choice|Compare maintenance, failure modes, and smallest workable path|Document the decision and its evidence
clean-code|simplifying hard-to-read code|Improve names and structure around the actual behavior|Run meaningful existing tests and review the diff
modular-architecture|placing behavior across modules|Define a small interface and keep ownership of state explicit|Check callers need no hidden ordering or mutable globals
algorithm-optimizer|improving an algorithmic hotspot|Measure the current hotspot before changing complexity|Compare the same workload after the change
api-design-expert|designing a module or remote API|Specify inputs, outputs, invariants, errors, and authority|Exercise invalid and duplicate calls
dependency-manager|adding or updating a dependency|Check license, maintenance, version, and transitive cost|Verify a clean install or load
refactoring-expert|changing code structure without intended behavior change|Identify behavioral invariants and edit one seam at a time|Compare old and new behavior with meaningful tests
legacy-code-reader|understanding an unfamiliar code path|Trace entry point, state mutations, callers, and side effects|Provide a file-linked map with uncertainties
root-cause-debugger|diagnosing a repeatable bug|Reproduce, trace the first wrong state, then change the owner|Retest the reproduction and a nearby regression case
regression-guard|protecting a fixed bug|Add the smallest meaningful test that fails on the old behavior|Run it against the fix
performance-profiler|finding a Roblox or Luau performance bottleneck|Measure on representative device and workload before optimizing|Compare timings and memory with identical conditions
memory-leak-hunter|investigating growing memory use|Track event connections, instances, tasks, and caches across repeated cycles|Show whether counts return to baseline
crash-investigator|investigating a crash or hard failure|Collect logs, reproduction, and the last successful operation|Retest the same sequence after a focused fix
dependency-conflict-checker|two packages or plugins appear incompatible|Compare version requirements, globals, and load order|Test the minimal conflicting combination
release-validation|checking a build before release|Verify install, critical flow, migration, and rollback path|Report exactly which environments were tested
roblox:
roblox-luau-expert|writing or reviewing Roblox Luau|Check syntax, types, script context, and current API usage|Run in Studio or state that Studio was unavailable
roblox-system-architect|changing Roblox service boundaries|Map client, server, shared modules, remotes, and state owners|Confirm authoritative writes stay on the server
roblox-api-verifier|using an uncertain Roblox API|Read the current Creator Hub or API reference and inspect feature availability|Cite the member and test it in Studio when possible
roblox-data-saver|changing player or terrain persistence|Trace load, lock, migration, save, retry, and shutdown paths|Test rejoin, failure visibility, and no duplicate rewards
roblox-networking|changing RemoteEvent or RemoteFunction flows|Specify request schema, validation, rate limits, and response behavior|Test malformed, repeated, and unauthorized requests
roblox-anti-exploit|reviewing exploitable player actions|Treat client data as intent; validate rights, distance, mass, and rewards on server|Attempt forged and replayed requests
roblox-ui-programmer|building a Roblox HUD or menu|Place each GuiObject and LocalScript in the Explorer tree and handle respawn|Test desktop and phone layouts
roblox-physics-engineer|changing collisions or sand movement|State ownership, constraints, and determinism of movement|Test tunneling, overlap, and multiplayer replication
roblox-performance-auditor|auditing Roblox runtime cost|Profile frame, server step, instance count, and network bytes|Record device, player count, and workload
roblox-studio-automation|using Studio tools or generated installers|Inspect connected Studio state before mutation and target exact DataModel paths|Read back changed objects and run a focused Play test
sand:
sand-terrain-generator|generating a diggable test mountain|Compare grid, Terrain, and hybrid geometry for the requested size|Count initial mass and inspect top and side digging
sand-digging-engine|changing the excavation rule|Define server-validated target, volume, and resulting cell state|Test one dig, repeated dig, and simultaneous digs
sand-chunk-manager|splitting sand into chunks|Define chunk ownership and neighbor updates across borders|Dig at a chunk edge and verify mass and replication
sand-performance-optimizer|optimizing the sand simulation|Profile mutation, rendering, save size, and replication separately|Compare identical mountain sizes before and after
digging-feel-designer|improving feedback during digging|Tune anticipation, hit, yield, and recovery from player observation|Test whether the player understands a successful dig
excavation-tools|adding a shovel or later equipment|Define range, rate, cost, and server-side validation per tool|Test switching tools and denied actions
digging-progression|changing excavation unlocks|Map each unlock to a new action or meaningful efficiency gain|Play the first upgrade path and note pacing
terrain-save-system|changing saved mountain shape|Define stable coordinates, schema version, and mass accounting|Round-trip a damaged mountain and reload twice
hidden-treasure-generator|placing finds inside sand|Define deterministic placement and ownership through collapse|Test a find that moves, is dug, and survives rejoin
mobile-digging-controls|changing touch excavation|Use explicit touch target and avoid camera gesture conflicts|Test a real tap, drag, and UI overlap on phone
game:
game-design-director|choosing a new Dig the Mountain mechanic|Compare it with the agreed design and current roadmap stage|Write a small testable proposal and success signal
fun-factor-auditor|judging whether digging is enjoyable|Observe repeated digging and identify waits, confusion, and satisfying moments|Use player behavior and quotes instead of intuition alone
retention-designer|designing reasons to return|Tie return goals to discoveries, progression, or social play|Check that rewards do not require misleading pressure
first-five-minutes|improving the new-player opening|Trace spawn, first dig, first sale, and first goal|Watch a new player complete it without explanation
reward-loop-designer|changing dig-sell-upgrade rewards|Map action, feedback, reward, and next goal|Check rewards cannot duplicate or inflate unexpectedly
progression-balancer|tuning tool or backpack progression|Model earned sand and upgrade costs over real play sessions|Compare median and edge-case time to upgrade
game-economy-simulator|simulating currency flow|Model sources, sinks, caps, and player cohorts|Run sensitivity cases and label unmeasured inputs
game-onboarding|adding guidance or tutorial steps|Teach only the next available action in context|Test comprehension with a new player
social-gameplay-designer|changing visits or co-op|Specify owner consent, helper rewards, and grief protection|Test two clients and a race for one cell
game-analytics-interpreter|interpreting play metrics|Define event meaning and data quality before reading trends|Separate measured behavior from causes inferred
art:
roblox-art-director|setting Dig the Mountain visual direction|Define a small style set for sand, equipment, and world landmarks|Compare new assets side by side in Studio
environment-designer|changing plot surroundings|Place navigation, stations, and landmarks around core digging|Test orientation from spawn and camera angles
lighting-master|changing Roblox Lighting|Tune exposure, contrast, and atmosphere for sand visibility|Check day or night and lower-end device rendering
particle-effects-designer|adding dig or collapse particles|Tie emission to server-confirmed events and limit count|Check readability and frame cost on phone
sound-feedback-designer|adding action sounds|Map sounds to dig, yield, sale, and error states|Check timing, loudness, and repeated-action fatigue
visual-feedback-master|clarifying game state visually|Show target, confirmed result, inventory, and errors consistently|Check a player can distinguish pending from confirmed actions
asset-consistency-checker|reviewing models or UI assets|Compare scale, palette, materials, naming, and performance budget|Flag outliers with exact asset paths
premium-ui-designer|polishing a Roblox interface|Establish clear hierarchy, spacing, and state feedback|Test narrow phone and desktop at actual scale
ux:
ux-researcher|investigating player confusion|Observe representative players on a defined task|Record behavior separately from interpretation
design-system-builder|creating reusable Roblox UI rules|Specify tokens for spacing, type, color, components, and states|Apply them to two screens and test consistency
typography-expert|choosing HUD text hierarchy|Set readable sizes and contrast for phones and desktop|Test truncation and localization expansion
color-palette-expert|choosing gameplay colors|Assign color by function and ensure contrast in sand scenes|Check colorblind and low-brightness legibility
responsive-design|adapting UI across screens|Use Roblox scaling and constraints based on content priority|Test phone aspect ratio and desktop
animation-ui-designer|adding UI motion|Use motion to show state changes without delaying actions|Test repeated use and reduced-motion preference when available
poster-designer|creating promotional game art|Define headline, focal action, and crop-safe layout|Preview thumbnail and full-size crops
presentation-director|explaining a game or technical decision in slides|Build one point per slide with clear evidence|Check factual claims and visual consistency
screenshot-to-interface|implementing a UI from a reference screenshot|Identify layout, scale, type, and states before recreating it|Compare side-by-side at matching resolution
project:
project-manager|tracking Dig the Mountain work|Update the roadmap from verified artifacts and open blockers|Keep next step small and assigned
task-decomposer|breaking a feature into implementation steps|Order work by dependency and one observable result per step|Check each step can be tested independently
multi-agent-coordinator|the user explicitly asks for parallel agent work|Split independent tasks and define shared files and merge points|Review combined results for conflicts
two-developer-workflow|coordinating A and B changes|State who owns script, scene object, and shared interface|Check neither side edits the same script concurrently
git-workflow-master|introducing or using repository history|Inspect current Git state and choose reversible commits|Check diff and branch before commit
merge-conflict-resolver|resolving a real merge conflict|Read both sides and intended behavior before editing markers|Run affected checks and inspect final diff
project-memory-manager|the user explicitly asks to remember or correct project knowledge|Write the requested note in the authorized memory location|Check it reflects the user's wording and current facts
progress-tracker|reporting project progress|Compare roadmap criteria with observed files and Studio tests|Label blocked and unverified items
deadline-planner|planning work to a real deadline|Work backward from dependencies, test time, and review time|Identify critical path and buffer
change-impact-analyzer|changing a shared module or data contract|Trace producers, consumers, migration, and second-developer work|List affected paths and compatibility checks
research:
deep-researcher|investigating a complex technical or market question|Define subquestions and gather primary evidence for each|Show unresolved contradictions
web-source-triangulator|sources disagree on a current fact|Compare independent primary sources and dates|Explain which claim is supported and why
github-code-hunter|finding public implementation examples|Search maintained repositories for the relevant pattern|Inspect license and adaptation cost
open-source-evaluator|considering an external dependency or skill|Check license, activity, issue quality, and compatibility|Record adoption risks and alternatives
documentation-navigator|finding an API answer in official docs|Locate exact class, method, version, and example|Link the owning page, not a search result
competitor-analyzer|comparing Roblox games or content|Define comparison criteria and inspect current examples|Separate observed features from estimates
trend-discovery|looking for current Roblox or social trends|Check recent primary platform signals and dates|Avoid declaring a trend from one example
research-summarizer|condensing a research set|Keep claims, sources, dates, and uncertainties|Verify summary against original sources
claim-source-mapper|auditing a report's citations|Create a claim-to-source map for consequential statements|Mark unsupported claims
technology-scout|evaluating a new tool for the project|Test a small representative workflow and compatibility|Record cost, limitations, and exit path
marketing:
tiktok-strategist|planning TikTok posts for the game|Match content ideas to audience, platform format, and game footage|Define a measurable experiment
viral-hook-generator|drafting short-video openings|Write several specific hooks tied to real game moments|Test clarity in the first seconds without false promises
short-form-storytelling|structuring short game videos|Arrange setup, surprise, payoff, and call to action|Check the clip works without explanatory text
video-editor-planner|planning edits from supplied footage|Mark selects, pacing, captions, and audio cues|Check every shot exists in the footage
social-analytics|interpreting social post performance|Compare reach, hold, completion, and engagement by cohort|Avoid causal claims from a single post
content-calendar|scheduling promotional content|Map themes and asset availability to a realistic cadence|Check production effort and dates
caption-writer|writing social captions|Lead with a concrete game moment and one clear action|Check platform length and factual accuracy
thumbnail-designer|designing a video thumbnail|Use one focal action and legible text at small size|Preview at actual feed size
trend-adapter|adapting a current format to game footage|Confirm the trend is current and appropriate to the game|Preserve original game identity and rights
roblox-marketing|planning discovery for a Roblox experience|Align game icon, title, description, and first-session experience|Measure click-to-play and early retention where available
personal:
daily-planner|planning the user's day|Prioritize a small set of tasks and realistic time blocks|Check constraints and leave buffer
habit-builder|establishing a repeatable habit|Choose a cue, minimal action, and tracking method|Review adherence without treating one miss as failure
anti-burnout-planner|adjusting an overloaded work plan|Identify workload, recovery, and controllable commitments|Agree on a sustainable next week
sleep-schedule-coach|planning a sleep routine|Use consistent timing and the user's real obligations|Flag persistent sleep problems for professional evaluation
fitness-program-designer|designing an exercise routine|Match training to baseline, equipment, and recovery|Track progression and pain or injury signals
nutrition-analyzer|reviewing eating patterns|Estimate intake only from provided data and state uncertainty|Avoid diagnosis or invented precision
training-progress-tracker|tracking exercise progress|Compare the same measures over time|Separate normal variation from sustained change
decision-making-coach|choosing among consequential options|List criteria, tradeoffs, reversibility, and missing facts|Explain why the preferred option fits the user's priorities
goal-prioritizer|choosing which goals to pursue now|Rank goals by value, urgency, and available capacity|Keep a visible list of deferred goals
weekly-review|reviewing the last week|Compare planned work, actual outcomes, energy, and blockers|Choose one adjustment for the next week
"""


def parse_rows():
    group = None
    for raw in ROWS.splitlines():
        line = raw.strip()
        if not line:
            continue
        if line.endswith(":"):
            group = line[:-1]
            if group not in GROUPS:
                raise ValueError(f"Unknown group: {group}")
            continue
        parts = line.split("|")
        if len(parts) != 4 or not group:
            raise ValueError(f"Bad row: {line}")
        yield group, *parts


def main():
    DEST.mkdir(parents=True, exist_ok=True)
    created = []
    skipped = []
    seen = set()
    for group, name, trigger, action, check in parse_rows():
        if name in seen:
            raise ValueError(f"Duplicate skill: {name}")
        seen.add(name)
        folder = DEST / name
        if folder.exists():
            skipped.append(name)
            continue
        folder.mkdir()
        description = f"Use when {trigger}. {action}."
        content = (
            "---\n"
            f"name: {name}\n"
            f"description: {json.dumps(description, ensure_ascii=False)}\n"
            "---\n\n"
            f"# {name}\n\n"
            f"{GROUPS[group]}\n\n"
            f"- Task: {action}.\n"
            f"- Check: {check}.\n"
            "- Report the result, evidence, what remains unknown, and the next small step.\n"
        )
        (folder / "SKILL.md").write_text(content, encoding="utf-8")
        created.append(name)
    print(f"created={len(created)} skipped={len(skipped)} total={len(seen)}")
    if skipped:
        print("skipped existing:", ", ".join(skipped))


if __name__ == "__main__":
    main()
