# 5. Practical limits for free text and repeatable fields

Date: 2024-02-26

## Status

Discussion

## Context

We need to set some practical limits for project metadata fields, not only for initial testing purposes, but also for the sustainability of inter-operating systems at scale. It is, of course, impossible to allow infinite text to be input into free-text fields (such as "Description") or infinite repetition of fields with cardinality of 0-n (such as "Data User") or 1-n (such as "Affiliated Department"). There is guidance from DataCite on practical limits of some fields (such as [contributors, which can handle 8 - 10 thousand repetitions](https://support.datacite.org/docs/datacite-metadata-schema-v44-recommended-and-optional-properties#7-contributor)), but DataCite does not specify limits for every field, and we need to have our own limits for our own infrastructure anyway.

To begin, we want limits that we expect to meet the needs of most users and that we feel comfortable testing at scale. If we change the limits, from a user perspective, it is much worse to decrease them than to increase them. From a technical perspective, it makes more sense to try to improve infrastructure to increase metadata capacity than it does to scramble to limit metadata due to performance issues.

For free-text fields, we do not expect entries to need to be more than a paragraph, so 1000 characters should suffice. For repeatable fields, we expect the high needs would be in the dozens, so 100 repetitions should suffice. These numbers also make the math easy for worst-case estimations.

See the [discussion notes](https://docs.google.com/document/d/14SjoKlTI7AWNVNjgBOa28jDnhClTnaMnEgN5EBocR9o/edit#heading=h.tdx4rp4eldc0) from the Feature Refinement meeting on December 6, 2023.

## Decision

- For any free-text field, we will limit the String value to 1000 characters
- For any repeatable field (cardinality of 0-n or 1-n), we will limit the repetitions to 100 per project

## Consequences

As the Standard Metadata Schema matures, it may or may not reflect these practical limits. Wherever the Schema differs from these decided limits, including fields with no specified limits, we will use these limits in our development--unless and until a new ADR overrides this one. The implementation of these limits in software may vary, case by case, depending on the relevant user stories and UI design criteria.