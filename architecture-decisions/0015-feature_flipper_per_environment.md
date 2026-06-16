# 15. Feature flipper status per environment

Date: 2026-06-16

## Status

Discussion

## Context

As a team working with users and our product owner, we want people to be able to clearly test features in development by knowing where features that are behind a feature flipper are already available.

## Decision

To facilitate testing, the feature flipper will always have the following status by default in the following environments:

- `staging`: feature flipper will be off by default; can be turned on manually if needed
- `production`: feature flipper will be off by default; can be turned on manually if needed, however generally features should be moved out from behind the feature flipper when they are ready to appear in production
- `QA`: feature flipper should be on all the time for a feature in active develoment, so that anyone including our PO and the Design team can review features on a regular basis
- `CI`: feature flipper will be off by default; can be turned on manually if needed, but CI references what is written in the code base and test suite, and should not need this

## Consequences

Features in development will be visible all the time in QA and therefore available for testing.
