# Calls to Mediaflux Made during ProjectMediaflux.create!

```mermaid
sequenceDiagram
  title Rails App To MediaFlux on ProjectMediaflux.create

  RailsApp->>Mediaflux: tigerdata.project.create(request)
  Mediaflux->>RailsApp: mediaflux id
  RailsApp->>Mediaflux: tigerdata.project.user.add(data user list)

```
