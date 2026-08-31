# CheckMK Configuration for tigerdata

Notifications in checkmk are setup in two stages.  
First you must allow checkmk to periodically notify.  
Then you must send those notifications to slack throttling based on desired notification times.

## Periodic Notifications

### Staging

For staging periodic notifications are [turned on for every service](https://pulmonitor.princeton.edu/staging/check_mk/index.py?start_url=%2Fstaging%2Fcheck_mk%2Fwato.py%3Fmode%3Dedit_ruleset%26varname%3Dextra_service_conf%253Anotification_interval)

### Production

For production periodic notifications are [turned on for RDSS applications here](https://pulmonitor.princeton.edu/production/check_mk/index.py?start_url=%2Fproduction%2Fcheck_mk%2Fwato.py%3Ffolder%3D%26host%3D%26item%3DTm9uZQ%253D%253D%26mode%3Dedit_rule%26rule_folder%3Dletsencrypt%252Frdss%26rule_id%3D9b370f1a-7f8a-4b54-9e83-71f42eec6ea5%26ruleset_back_mode%3Drulesets%26service%3DTm9uZQ%253D%253D%26varname%3Dextra_service_conf%253Anotification_interval)

## Slack Alerts

Alerts are configured to delay notification based on the `Sending Conditions`.

- `Limit notifications by count to` delays the first notification
  - note that the first notification happens at time 0 and the 6th notification happens at minute 5.
- `Throttling of 'Periodic notifications'` indicates how often the notification should re-occur if the ssytem remains down.
  - note that the `Start with` number should match the limit above (aka 6) and the `send every` is how many minutes between notifications

### Staging

For staging we have two alerts:

- one that lets us know [when services come back up](https://pulmonitor.princeton.edu/staging/check_mk/index.py?start_url=%2Fstaging%2Fcheck_mk%2Fwato.py%3Fback_mode%3Dtest_notifications%26edit%3D10%26folder%3D%26mode%3Dnotification_rule_quick_setup%26user%3D)
- one that waits 5 minutes before [alerting when systems are down](https://pulmonitor.princeton.edu/staging/check_mk/index.py?start_url=%2Fstaging%2Fcheck_mk%2Fwato.py%3Fback_mode%3Dtest_notifications%26edit%3D9%26folder%3D%26mode%3Dnotification_rule_quick_setup%26user%3D)

### Production

For production we have two alerts:

- one that lets us know [when services come back up](https://pulmonitor.princeton.edu/production/check_mk/index.py?start_url=%2Fproduction%2Fcheck_mk%2Fwato.py%3Fback_mode%3Dtest_notifications%26edit%3D16%26folder%3D%26mode%3Dnotification_rule_quick_setup%26user%3D)
- one that waits 5 minutes before [alerting when systems are down](https://pulmonitor.princeton.edu/production/check_mk/index.py?start_url=%2Fproduction%2Fcheck_mk%2Fwato.py%3Fback_mode%3Dnotifications%26edit%3D4%26folder%3D%26mode%3Dnotification_rule_quick_setup%26user%3D)
