1. Check that the service is up before you begin this process by visiting [CheckMK](https://pulmonitor.princeton.edu/production/check_mk/login.py?_origtarget=index.py%3Fstart_url%3D%252Fproduction%252Fcheck_mk%252Fview.py%253Fview_name%253Dallhosts) and confirming to see if the application is up by visiting https://tigerdata-prod.princeton.edu/.

2. Make sure that you have the latest code and that the code can be run locally.

3. Communicate with the following channels to let folks know that an upgrade to our tigerdata production machines are taking place:

- rdss-team
- Operations
- tiger-data
- TD Library Slack channel

4. We will rebuild the machine using the [Replace-Rebuild VM Workflow](https://ansible-tower.princeton.edu/#/templates/workflow_job_template/104/details)

- Replace-Rebuild VM instructions are here: https://github.com/pulibrary/pul-it-handbook/blob/main/services/replace_rebuild_vm.md

5. Once the workflow has completed, the tigerdata-playbook must be run (limiting to ONE HOST AT A TIME)

`ansible-playbook playbooks/tigerdata.yml --limit=tigerdata-prod1.princeton.edu -e runtime_env=production`

6. Run the "1 Cap Deploy" playbook in ansible-tower limiting to that same host.
