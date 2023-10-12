# 2. Use Shibboleth for authentication

Date: 2023-10-12

## Status

Discussion

## Context

Users must be able to sign into the TigerData Rails application in such a way that they are also securely authenticated to MediaFlux, and actions that they then take in MediaFlux are accurately tied to their user.  Theoretically, this could be accomplished by minting an authentication token in MediaFlux based on the value of a SAML 2.0 cookie created by the Shibboleth session when a user logs into the Rails application via CAS tied to a Shibboleth service that runs on the MediaFlux server.  For the sake of security, the Shibboleth service should run on the MediaFlux server.  Our Rails application will interact with Shibboleth for authentication using CAS.  Note that the work to tie a session cookie to a MediaFlux token is theoretical and needs to be tested to confirm whether or not it will work for tying the user in Rails to a MediaFlux session.

## Decision

We will use Shibboleth for authentication.  Shibboleth will run on the MediaFlux server.  

## Consequences

Shibboleth will be maintained by teams external to RDSS (Research Computing, and the IAM Group in OIT).  Once Shibboleth is set up, experimentation will need to take place to determine whether or not it allows our application to create session tokens in MediaFlux tied to the authenticated user.  The IAM Group in OIT has stated that they are moving toward a non-Shibboleth authentication strategy in the medium term, so eventually we will need to replace Shibboleth, even if it works for MediaFlux sessions.  We will likely need to plan for a spike on the new technology (Azure) before Shibboleth is no longer supported.
