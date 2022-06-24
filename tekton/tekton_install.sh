#!/bin/bash
# Tekton
. ././gcp/env-gke.sh
echo " Creating Tekton Pipeline folder"
#PATH_TO_HELM=$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
#echo $PATH_TO_HELM
PATH_TO_HELM=$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P) #Current working directory
URL_TO_YOUR_REPO_WITHOUT_TAG= TODO
#export YOUR_NAMESPACE=quickstart-aks #Use StandaloneNS
#export YOUR_NAMESPACE_WITH_PIPELINES=quickstart-aks
SOME_UNIQUE_NAME=gke-tkn
TEKTON_NAMESPACE=tekton-pipelines
AKS_NS_Standalone=quickstart-standalone

echo "Creating a new Namespace: tekton-pipelines"
kubectl create ns $TEKTON_NAMESPACE
sleep 2

echo "Installing Tekton"
echo "kubectl apply --filename https://storage.googleapis.com/tekton-releases/pipeline/previous/v0.26.0/release.notags.yaml"
kubectl apply --filename https://storage.googleapis.com/tekton-releases/pipeline/previous/v0.26.0/release.notags.yaml
sleep 5
echo " Tekton Triggers installation - tekton-triggers.yaml and interceptors.yaml"
# Tekton triggers
kubectl apply --filename https://storage.googleapis.com/tekton-releases/pipeline/previous/v0.26.0/release.yaml
kubectl apply --filename https://storage.googleapis.com/tekton-releases/triggers/previous/v0.15.0/release.yaml
kubectl apply --filename https://storage.googleapis.com/tekton-releases/triggers/previous/v0.15.0/interceptors.yaml


sleep 10

echo " Installing Tekton Dashboard"
kubectl apply --filename https://storage.googleapis.com/tekton-releases/dashboard/latest/tekton-dashboard-release.yaml

echo " Installing mx-tekton-pipeline via HELM charts "
wget -c https://cdn.mendix.com/mendix-for-private-cloud/tekton-pipelines/standalone-cicd/standalone-cicd-v1.0.0.zip

unzip standalone-cicd-v1.0.0.zip && cd helm/charts
helm install -n $AKS_NS_Standalone mx-tekton-pipeline ./pipeline/ \
  -f ./pipeline/values.yaml \
  --set images.imagePushURL=$URL_TO_YOUR_REPO_WITHOUT_TAG
sleep 10
echo " Installing Generic Triggers"

#cd $PATH_TO_HELM && cd helm/charts
helm template mx-tekton-pipeline-trigger ./triggers -f triggers/values.yaml \
    --set name=$SOME_UNIQUE_NAME \
    --set pipelineName=build-pipeline \
    --set triggerType=generic | kubectl apply -f - -n $AKS_NS_Standalone

sleep 10
echo "Applying Port Forward to port 9097"
kubectl --namespace $TEKTON_NAMESPACE port-forward svc/tekton-dashboard 9097:9097 &


echo "Forwarding Tekton Listener to port 8080"
LISTENER=$(kubectl get pods -A | awk '{print $2}' | grep el-mx-pipeline)
kubectl --namespace $TEKTON_NAMESPACE port-forward svc/${LISTENER} 8080:8080