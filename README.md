Kong Plugin - Cluster Redirect
==============================

Custom plugin that will send request to a different upstream when it matches
header and value. Requests that match route `/local` will be proxied to Upstream
`europe_cluster`, except requests that contain the header `X-Country=Italy` which 
should be proxied to `italy_cluster`. 
 
Multiple header names and values can be a configurable rule that is matched, 
for example `X-Country=Italy, X-Regione=Abruzzo` will go to upstream `italy_cluster`, 
but just `X-Country=Italy` without header `X-Regione` still goes to `europe_cluster`

