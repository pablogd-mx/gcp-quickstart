## Mendix Tekton Pipelines

This project provides two helm charts.

1. **./helm/charts/pipeline** - provides 3 Tekton pipelines:
* build-pipeline - builds oci-image of mendix application based on provided git repository with mendix application.
* create-app-pipeline - creates MendixApp k8s Custom Resource.
* delete-app-pipeline - deletes MendixApp k8s Custom Resource.

2. **./helm/charts/triggers** - provides Tekton Trigger to work with pipelines from a previous chart.

## Setup

If you want to build all required images follow the steps defined [here](doc/BuildImagesMinikube.md).

### 1. Install Tekton
#### 1.1 Tekton itself (more details here - https://tekton.dev/docs/pipelines/install/):

#### Kubernetes
```
kubectl apply --filename https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml
```

*Optional*. Install Tekton Dashboard:
```
kubectl apply --filename https://storage.googleapis.com/tekton-releases/dashboard/latest/tekton-dashboard-release.yaml
```
To access it you can use `kubectl proxy` and this link - `http://localhost:8001/api/v1/namespaces/tekton-pipelines/services/tekton-dashboard:http/proxy/`

#### OpenShift

```
oc new-project tekton-pipelines
oc adm policy add-scc-to-user anyuid -z tekton-pipelines-controller
oc adm policy add-scc-to-user anyuid -z tekton-pipelines-webhook

oc apply --filename https://storage.googleapis.com/tekton-releases/pipeline/latest/release.notags.yaml
```
___
#### 1.2 Tekton triggers (allow us to trigger pipeline with curl):

#### Kubernetes
```
kubectl apply --filename https://storage.googleapis.com/tekton-releases/triggers/latest/release.yaml
kubectl apply --filename https://storage.googleapis.com/tekton-releases/triggers/latest/interceptors.yaml
```

#### Openshift
```
kubectl apply --filename https://storage.googleapis.com/tekton-releases/triggers/latest/release.yaml
kubectl apply --filename https://storage.googleapis.com/tekton-releases/triggers/latest/interceptors.yaml
```
Edit `tekton-triggers-controller` deployment:
1. Change `runAsUser:` to the valid OpenShift user (like `1001000000`).
2. Add the next line to the `args` section: `- '--el-security-context=false'`

Edit `tekton-triggers-core-interceptors` deployment:
1. Change `runAsUser:` to the valid OpenShift user (like `1001000000`).
2. Change `runAsGroup:` to the valid OpenShift group (like `1001000000`).

Edit `tekton-triggers-webhook` deployment:
1. Change `runAsUser:` to the valid OpenShift user (like `1001000000`).


### 2. Install pipelines
To install pipelines use the next command:
```
cd helm/charts

helm install -n $YOUR_NAMESPACE mx-tekton-pipeline ./pipeline/ -f ./pipeline/values.yaml \
    --set images.imagePushURL=$URL_TO_YOUR_REPO_WITHOUT_TAG

# for development (uses images from master branches)
helm install -n $YOUR_NAMESPACE mx-tekton-pipeline ./pipeline/ -f ./pipeline/values-dev.yaml \
    --set images.imagePushURL=$URL_TO_YOUR_REGISTRY
```

After that you need to install triggers:
```
# example of gitlabwebhook setup
# more details in triggers/values.yaml file
helm template mx-tekton-pipeline-trigger ./triggers -f triggers/values.yaml \
    --set name=gltest \
    --set gitlabwebhook.operatorNamespace=k8s \
    --set gitlabwebhook.mendixEnvironmentInernalName=app \
    --set gitlabwebhook.kubeConfigSecretName=none \
    --set gitlabwebhook.protocol=ssh \
    --set gitlabwebhook.constantsMode=auto | kubectl apply -f - -n $YOUR_NAMESPACE
    
  
# example of generic trigger
# more details in triggers/values.yaml file
helm template mx-tekton-pipeline-trigger ./triggers -f triggers/values.yaml \
    --set name=gltest-curl \
    --set triggerType=generic | kubectl apply -f - -n $YOUR_NAMESPACE

```

### 3. Run pipeline

#### 3.1 Kube Config file

If your operator is in the other cluster you need to provide access to that cluster (otherwise you can skip this step).
To achieve that, cluster admin should create Secret that contains kube/config file.

a) If you don't have required kube/config file, 
then you can generate it by **switching kube context to the cluster with operator** and run the next command:
```
export KUBE_CONFIG_B64=$(./kube-conf-gen.sh $OPERATORS_NAMESPACE $SECRET_NAME_FOR_SERVICE_ACCOUNT $CLUSTER_ADDRESS | base64)
```
Example: 
`export KUBE_CONFIG_B64=$(./kube-conf-gen.sh anton-test mendix-operator-token-75fnh https://34.90.61.17 | base64)`

After that, go to step 3.1.1

b) If you already have required file then:

```
export KUBE_CONFIG_B64=$(cat $path_to_kube_config_file | base64)
```

After that, go to step 3.1.1

3.1.1 Execute next command on a **cluster with installed Tekton**:
```
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: kube-conf-secret
type: Opaque
data:
  kubeconf: $KUBE_CONFIG_B64
EOF
```

#### 3.2 Git access
****
If you have a private repo you need create secret and link that secret 
to the `tekton-triggers-mx-sa` service account. More details here - https://github.com/tektoncd/pipeline/blob/main/docs/auth.md#configuring-basic-auth-authentication-for-git

#### 3.3 Registry push access

If you have a private registry, you need to follow these instructions to provide access to the registry - https://github.com/tektoncd/pipeline/blob/main/docs/auth.md#configuring-authentication-for-docker.

If you are passing docker config.json, take into account that "credStore" values is not supported in Tekton (https://github.com/tektoncd/pipeline/issues/4107).  

#### 3.4 Expose event-listener (http server to run pipeline) service

You can expose it with kube port forwarding:
```
kubectl port-forward service/el-mx-pipeline-listener-gltest 8080
```

#### 3.4 Run pipeline with the curl

Curl example to build and deploy the new version of Mendix application for "generic" trigger type:
```
curl -X POST \
  http://localhost:8080 \
  -H 'Content-Type: application/json' \
  -H 'Event: build' \
  -d '{
    "repo": {
        "url": "https://github.com/walkline/mxapp.git",
        "branch": "main"
    },
    "namespace":"myns",
    "env-internal-name":"envname",
    "kube-secret-name":"kube-conf-secret",
    "constants-mode": "auto",
    "scheduled-events-mode": "auto"
}'
```

Curl example to create mendix app k8s custom resource:
```
curl -X POST \
  http://localhost:8080 \
  -H 'Content-Type: application/json' \
  -H 'Event: create-app' \
  -d '{
    "namespace":"myns",
    "env-internal-name":"envname",
    "dtap-mode": "D",
    "storage-plan-name":"file-plan-name",
    "database-plan-name": "db-plan-name"
}'
```

Curl example to delete mendix app k8s custom resource:
```
curl -X POST \
  http://localhost:8080 \
  -H 'Content-Type: application/json' \
  -H 'Event: delete-app' \
  -d '{
    "namespace":"myns",
    "env-internal-name":"envname"
}'
```

Curl example to configure mendix app k8s custom resource:
```
curl -X POST \
  http://localhost:8080 \
  -H 'Content-Type: application/json' \
  -H 'Event: configure-app' \
  -d '{
    "namespace":"myns",
    "env-internal-name":"envname",
    "source-url":"https://example.com/url-to-mda/or/oci-image",
    "replicas":5,
    "dtap-mode": "D",
    "set-constants":"{\"key\":\"value\"}",
    "add-constants":"{\"key\":\"value\"}",
    "remove-constants":"[\"key\"]",
    "set-env-vars":"{\"key\":\"value\"}",
    "add-env-vars":"{\"key\":\"value\"}",
    "remove-env-vars":"[\"key\"]"
}'
```