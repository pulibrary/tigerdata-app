# Nomad for CI

## Why

We utilize Nomad to run our circle ci jobs so that mediaflux can run within the network and have access to LDAP to enable login. Circle CI runs the entire job on our Nomad runners.

## Nomad setup

Our nomad runners are built by running the ansible playbook to create a base image and then deployed to nomad to have up to 6 CI jobs running at the same time.
To add additional information like environment variables to the nomad runner:

1. Update variables available to the nomad environment by changing `groupvars/production.yml`
   ```
   nomad_vars:
     tigerdata:
       <your addintional vars here>
   ```
1. Update the nomad environment script by changing `nomad/tigerdata/deploy/production.hcl`.
   ```
   ...
   {{- with nomadVar "nomad/jobs/tigerdata" -}}
   << your var here in the format of {{.var-name-from-groupvar}} >>
   ...
   {{- end -}}
   ...
   ```
   **Note** the dot `.` in from of the environment name
1. Run the playbook
   ```
   ansible-playbook playbooks/tigerdata_ci_deployer.yml
   ```
1. Deploy new runners
   This replaces the ones that are currently running with new ones that have your information available in the environment
   ```
   cd nomad && BRANCH=main ./bin/deploy tigerdata production
   ```

### Troubleshooting

If your environment var shows up empty make sure that you have run the playbook. Just running the deploy will put the vars in the environment, but they will have no value.

## Viewing Nomad

The nomad console can be viewed at https://nomad.lib.princeton.edu/ui/jobs/

### Variables

You can see the environment variables on the variables tab
<img width="1208" height="143" alt="Screenshot 2026-09-24 at 4 23 51 PM" src="https://github.com/user-attachments/assets/a93d7366-afc9-46bf-952b-db403deb5dd3" />

### Running jobs

To figure out which job is running your CI job look at the CPU and memory and try to see one that is active. If there are multiple Circle CI jobs running it is hard to tell which nomad runner is running your job.
<img width="864" height="695" alt="Screenshot 2026-09-24 at 4 24 10 PM" src="https://github.com/user-attachments/assets/af947725-bf70-43fb-94dc-25854c7e5967" />
