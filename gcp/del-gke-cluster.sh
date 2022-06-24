#!/usr/bin/env bash
. ./env-gke.sh
## To avoid incurring charges to your Google Cloud account for the resources used,
# delete the Cloud project with the resources.

#Delete the application's Service by running
kubectl delete service $SERVICE_NAME

#Delete
gcloud artifacts repositories delete $GKE_ARTIFACTS_REGISTRY
#Delete the application's Service by running

gcloud container clusters delete $GKE_CLUSTER_NAME
