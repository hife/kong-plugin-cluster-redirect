#!/bin/bash
#
# Cleanup commands
#

KONG="localhost:8001"
SERVICE="europe_service"
CLUSTER0="europe_cluster"
CLUSTER1="italy_cluster"

# 1. Delete Route of the service with path = /local
# TODO: dynamically extract id for route
# curl -i -X DELETE --url http://$KONG/routes/{id}

# 2. Delete Service
curl -i -X DELETE --url http://$KONG/services/$SERVICE/

# 3. Delete Target servers
curl -X DELETE --url http://$KONG/upstreams/$CLUSTER0/targets
curl -X DELETE --url http://$KONG/upstreams/$CLUSTER1/targets

# 4. Delete Upstream names
curl -i -X DELETE --url http://$KONG/upstreams/$CLUSTER0
curl -i -X DELETE --url http://$KONG/upstreams/$CLUSTER1

# 5. Delete plugin configuration on the service
# TODO: dynamically extract uuid for plugin 
# curl -i -X DELETE http://localhost:8001/plugins/{uuid}

