# 17. Entra ID Registrations and Secrets Management

Date: 2026-10-15

## Status

Discussion

## Context

We need an agreed upon method for handling Entra ID application registrations and secrets for local Mediaflux development in Docker, and each higher-level environment for Mediaflux.

## Decision

We will have one application registration and one client secret for each of the following environments:

- tigerdata-mediaflux-staging
- tigerdata-mediaflux-qa
- tigerdata-mediaflux-production
- tigerdata-mediaflux-ci

Local development will share a client secret in Docker, using ansible-vault so that secrets are not hard-coded into images.

## Consequences

Secrets will need to be rotated on a regular basis manually. Secrets are good for 6 months currently; we should develop a manual part of our process to rotate them out regularly using ansible-vault so that they do not break unexpectedly.
