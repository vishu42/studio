#!/bin/bash

# list of port-forwards
kubectl -n app port-forward svc/bookinfo-gateway-istio 8080:80 & echo "svc/bookinfo-gateway-istio running on http://localhost:8080" &
kubectl -n kubernetes-dashboard port-forward svc/kubernetes-dashboard-kong-proxy 8443:443 & echo "svc/kubernetes-dashboard-kong-proxy is running on https://localhost:8443" &
kubectl -n monitoring port-forward svc/kube-prometheus-grafana 9595:80 & echo "svc/kube-prometheus-grafana is running on http://localhost:9595" &

# wait so script doesn't exit
wait
