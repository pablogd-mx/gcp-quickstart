#!/usr/bin/env bash
set -x
#Setting up the Region/Zone

gcloud config set compute/zone $GKE_Region

#Setting up the right Project

gcloud config set project $PROJECT_ID

#Setting up the Region/Zone

gcloud container clusters create GKE_CLUSTER_NAME
