#GKE components
export PROJECT_ID= TODO # example quickstart-gke-mx4pc
export GKE_ARTIFACTS_REGISTRY=mendix-test ##documentation here https://cloud.google.com/artifact-registry
export GKE_REGION=TODO #full list available here: https://cloud.google.com/compute/docs/regions-zones#available
export GKE_CLUSTER_NAME= TODO

#Connected Mode
export CLUSTER_ID=f2d74384-fed8-4cf0-b00b-90ed1e7d3eff
export CLUSTER_SECRET=ID65Wj1qA5SAbxXG
export GKE_NS_Connected=quickstart-connected

#Standalone Mode
export GKE_NS_Standalone=quickstart-standalone

#Tekton
export PATH_TO_HELM=$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P) #Current working directory
export URL_TO_YOUR_REPO_WITHOUT_TAG=pablok8sreg.azurecr.io
export SOME_UNIQUE_NAME=gke-tkn
export TEKTON_NAMESPACE=tekton-pipelines

#MXPC
export MXPC_VERSION=2.5.1
export MXPC_OS=macos-amd64

