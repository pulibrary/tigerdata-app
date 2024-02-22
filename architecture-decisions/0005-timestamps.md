# 5. Timestamps

Date: 2024-02-22

## Status

Decided

## Context

We want to ensure that all timestamps are recorded and displayed in the same time zone and in iso8601 format. 

## Decision

Time zones should be displayed using the America/New York zone, NOT EST, because EST will change depending on the time of year. Additionally, the [ruby `Time` class](https://ruby-doc.org/3.3.0/Time.html) should be preferred over the `DateTime` class because the `Time` class covers concepts of Daylight Savings time. 

Parsing a date stamp from MediaFlux:
```
Time.zone.parse(@last_modified_mf).in_time_zone("America/New_York").iso8601
```

Recording the current time:
```
Time.current.in_time_zone("America/New_York").iso8601
```