# Mediaflux in CI
Part of our automated test suite run directly against mediaflux, which requires there to be a docker image of mediaflux that CircleCI can pull from. Temporarily, this is at https://hub.docker.com/repository/docker/eosadler/mediaflux_dev/general, which is in a team member's personal dockerhub. This is not how we want to run things, but it was a temporary workaround so we could run CI. 

## Upgrading mediaflux in CI
1. Follow the instructions in [local_development.md](local_development.md) to get the most recent client (assume that's `4` here.)
2. Tag the new image: `docker image tag princeton_dev_image:4 eosadler/mediaflux_dev:4`
3. docker push eosadler/mediaflux_dev:4
4. Update `.circleci/config.yml` to point to the most recent tag version.