# 15. Data Security Backfill

Date: 2026-09-10

## Status

Discussion

## Context

Legacy projects will need a default value backfilled into Mediaflux once the new metadata field is rolled out. RC will be in charge of populating this field.

## Decision

We will not backfill legacy projects immediately, as the doc type counts this as optional (min-occurs=0), but backfilling will eventually be needed. We do want to back fill the security level at some point, however we do not currently have a default value. TigerData (TD) leadership will communicate out to our data sponsors that we're going to set their level to 1 unless they opt for it to be level 0.  There is a TD leadership level conversation here on if the security level is an attestation or if it's a less formal attribute for these projects.  If the former, then we need to figure out how to get sponsor approval.

## Consequences

Legacy projects will display a hyphen or emdash temporarily, until a formal decision is made on setting security levels on behalf of data sponsors.
