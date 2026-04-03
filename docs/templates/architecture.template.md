# Architecture

## Overview

- What kind of project is this?
- What are the major runtime systems?
- What are the most important architectural boundaries?

## Main Systems

List the key systems and their responsibilities.

| System | Responsibility | Important Files/Dirs |
|--------|----------------|----------------------|
| Example: Combat | Resolves attacks, damage, status effects | `Assets/Scripts/Combat/` |

## Data Flow

Describe the high-level flow of data and control.

- Input enters through:
- State is owned by:
- UI reads from:
- Persistence writes through:

## Lifecycle / Entry Points

- Main entry point:
- Starting scene or boot path:
- Important initialization order:

## Integration Boundaries

List external systems or sensitive boundaries.

- Save/load
- Networking
- Plugin APIs
- Engine-specific tooling
- Build pipeline

## Do Not Break

List fragile areas or invariants agents should preserve.

- Example: Save version migration must remain backward compatible
- Example: Inventory IDs must stay stable across sessions

## Notes

Add anything that helps an agent understand how to change the project safely.
