#!/bin/bash

# Usage ./kube-conf-gen.sh ( namespace ) ( service account token name ) (server)

# your server name goes here
server=$3
# the name of the secret containing the service account token goes here
name=$2

ca=$(kubectl get -n $1 secret/$name -o jsonpath='{.data.ca\.crt}')
token=$(kubectl get -n $1 secret/$name -o jsonpath='{.data.token}' | base64 --decode)
namespace=$(kubectl get -n $1 secret/$name -o jsonpath='{.data.namespace}' | base64 --decode)

echo "apiVersion: v1
kind: Config
clusters:
- name: default-cluster
  cluster:
    certificate-authority-data: ${ca}
    server: ${server}
contexts:
- name: default-context
  context:
    cluster: default-cluster
    namespace: default
    user: default-user
current-context: default-context
users:
- name: default-user
  user:
    token: ${token}
"