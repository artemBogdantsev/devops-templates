# Monitoring Kubernetes Clusters with Grafana
This part will describe in detail how setup and run the monitoring systems.

## Prometheus and Grafana
[Click to deploy](https://github.com/GoogleCloudPlatform/click-to-deploy/blob/master/k8s/prometheus/README.md) from GCP Marketplace 

## Configuration tips
The monitoring tools have to be added to the service mesh and exposed via Istio Ingress Gateway. 
The Istio installation has the detailed information [here](../istio/README.md). 

After Istio is configured and the monitoring tools are installed, you have to add only Istio VirtualService to route 
domain traffic from Istio toi the exact monitoring tool endpoint.

```kubectl apply -f monitoring-vs.yml```

## Dashboards as a Code
Grafonnet provides an easy and maintainable way of writing `Grafana` dashboards. Instead of generating JSON files and 
maintaining them, you can easily create your own dashboards using the many helpers grafonnet-lib offers you, thanks to 
the data templating language `Jsonnet`.

### Grafonnet

1. Prerequisites
    Install Jsonnet, which is available on Homebrew: 

    ```
    brew install jsonnet
    ```

2. Install Grafonnet
    Simplest way to install Grafonnet is to clone the repository:

    ```
    git clone https://github.com/grafana/grafonnet-lib.git
    ```

    **Note:** Make a symlink if you cloned to different folder


#### Usage
*The Simplest Approach:*
Your current directory would look something like this:     

```     
▸ tree -L 1 .
.
├── dashboard.jsonnet
└── grafonnet-lib

1 directory, 1 file
```

You've cloned Grafonnet and you've create a file called, dashboard.jsonnet. That file might look something like this:

```
local grafana = import 'grafonnet/grafana.libsonnet';

grafana.dashboard.new('Empty Dashboard')
```     

From here, you can run the following command to generate your dashboard:
     
```
jsonnet -J grafonnet-lib dashboard.jsonnet
```
    
Next you need to actually create the dashboard on Grafana. One option is to paste the dashboard JSON on the Grafana UI.
     
A less tedious approach would be to use Grafana's dashboard API. For example, you could create and execute this script in our example directory:     

```bash
#!/usr/bin/env bash

JSONNET_PATH=grafonnet-lib \
jsonnet dashboard.jsonnet > dashboard.json

payload="{\"dashboard\": $(jq . dashboard.json), \"overwrite\": true}"

curl -X POST $BASIC_AUTH \
-H 'Content-Type: application/json' \
-d "${payload}" \
"http://admin:PASSWORD@localhost:3000/api/dashboards/db"
```