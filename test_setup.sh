#!/bin/bash
#
# Commands to configure Upstreams, Targets, Service, Route.
# Commands to configure plugin to be ready to play with it

KONG="localhost:8001"
SERVICE="europe_service"
CLUSTER0="europe_cluster"
CLUSTER0_URL="http://$CLUSTER0:80/bin/a10f2738-6456-4bae-b5a9-f6c5e0463a66/view"

TARGET0="requestloggerbin.herokuapp.com:80"
CLUSTER1="italy_cluster"
TARGET1="mockbin.org:80"

# 1. Create Upstreams
curl -i -X POST --url http://$KONG/upstreams/ --data "name=$CLUSTER0"
curl -i -X POST --url http://$KONG/upstreams/ --data "name=$CLUSTER1"

# 2. Add Target servers to the Upstreams
curl -X POST --url http://$KONG/upstreams/$CLUSTER0/targets --data "target=$TARGET0"
curl -X POST --url http://$KONG/upstreams/$CLUSTER1/targets --data "target=$TARGET1"

# 3. Create Service using the Upstream
curl -i -X POST --url http://$KONG/services/ --data "name=$SERVICE" --data "url=$CLUSTER0_URL"

# 4. Add Route to the service with path = /local
curl -i -X POST --url http://$KONG/services/$SERVICE/routes --data 'paths[]=/local'

# 5. Enable plugin
curl -i -X POST http://$KONG/services/$SERVICE/plugins --data 'name=cluster-redirect' --data "config.redirect=$CLUSTER1"

### Mockbin endpoints
# Europe cluster: https://requestloggerbin.herokuapp.com/bin/a10f2738-6456-4bae-b5a9-f6c5e0463a66/view
#{
#  "status": 200,
#  "statusText": "OK",
#  "httpVersion": "HTTP/1.1",
#  "headers": [],
#  "cookies": [],
#  "content": {
#    "mimeType": "text/plain",
#    "text": "This is europe_cluster",
#    "size": 0
#  },
#  "redirectURL": "",
#  "bodySize": 0,
#  "headersSize": 0
#}

# Italy cluster: https://requestloggerbin.herokuapp.com/bin/1de8245c-64c2-41b9-b51a-875df29837bc/view
#{
#  "status": 200,
#  "statusText": "OK",
#  "httpVersion": "HTTP/1.1",
#  "headers": [],
#  "cookies": [],
#  "content": {
#    "mimeType": "text/plain",
#    "text": "This is italy_cluster",
#    "size": 0
#  },
#  "redirectURL": "",
#  "bodySize": 0,
#  "headersSize": 0
#}

