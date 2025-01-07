# 1. Record architecture decisions

Date: 2024-02-19

## Status

Discussion

## Context

The initial workflow for projects requested in this application and created in MediaFlux will be manual, triggered by an email sent to MediaFlux admins by this application. We need to be able to look up active projects that have been initialized manually. There is not an automatic way to get this information from MediaFlux with this current workflow.

## Decision

We will rely on MediaFlux project IDs stored in this application to know when a project has been created in MediaFlux. When a project is created in MediaFlux, a MediaFlux admin will enter the project ID from MediaFlux into the TigerData application frontend. Entering this project ID into the TigerData application will also change the status of the project in this application from "pending" to "active."

## Consequences

This is a manual process that relies on human intervention to keep things in sync. There is not an automatic way to ensure that all projects created in MediaFlux have their representation in the TigerData application.
