#!/bin/bash
# Usage:
# do-all.sh connected
# do-all.sh standalone
#
#
[[ -z "${1}" ]] && { echo 'Cluster type not specified. Please type connected or standalone' 1>&2 ; exit 1; }

echo "Creating Cluster in Azure GCP, grab a coffee this will take a while"
sleep 5
#Sets the Environment variables
. ./gcp/env-gke.sh
### Create a cluster
. ./gcp/create-gke-cluster.sh

echo "Installing NGINX controller"
sleep 2
### Install nginx
. ./install-nginx-ingress.sh
sleep 10

### Install Prometheus
. ./install-grafana-prometheus.sh
sleep 10

echo "Starting Mendix Installation, sit tight...almost there"
sleep 2
echo "Downloading MXPC tool"
sleep 1
wget -c https://cdn.mendix.com/mendix-for-private-cloud/mxpc-cli/mxpc-cli-${MXPC_VERSION}-${MXPC_OS}.tar.gz
tar -zxvf mxpc-cli*

if [ "${1}" == "connected" ];
then
  echo " Installing Operator in Connected Mode on namespace" $GKE_NS_Connected
  sleep 2

  ./mxpc-cli base-install --namespace $GKE_NS_Connected -i $CLUSTER_ID -s $CLUSTER_SECRET --clusterMode $1 --clusterType generic
   sleep 2
   echo "Configuring Namespace" $GKE_NS_Connected
  ./mxpc-cli apply-config -i $CLUSTER_ID -s $CLUSTER_SECRET -f  configure.yaml
#  ##Installing MendixDemoApp
#  echo "Installing Mendix app"
#  kubectl apply -f demo.yaml -n $AKS_NS_Connected

elif [ "${1}" == "standalone" ];
  then
  echo " Installing Operator in Standalone Mode on namespace" $GKE_NS_Standalone
  echo " Installing Operator in" $GKE_NS_Standalone
  ./mxpc-cli base-install --namespace $AKS_NS_Standalone --clusterMode standalone --clusterType generic
  sleep 2
  echo "Configuring Namespace" $GKE_NS_Standalone
  ./mxpc-cli apply-config -f artifacts/configure-standalone.yaml
  ##Installing MendixDemoApp
  echo "Installing Mendix app"
  kubectl apply -f artifacts/demo.yaml -n $GKE_NS_Standalone
  sleep 5

  echo "Installing Tekton"
  sleep 5
 . ./tekton/tekton_install.sh
else
  echo " Incorrect Cluster type. Please select Connected or Standalone"
fi
##Installing MendixDemoApp

#Installing Grafana
#. ./install-grafana-prometheus.sh
