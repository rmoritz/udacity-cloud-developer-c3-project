KUBECTL='microk8s.kubectl'
SERVICES='backend-feed backend-user frontend reverseproxy'

## Create K8s deployments
# Requires environment variables:
#  - DOCKER_USERNAME
#  - TAG
#  - KUBECTL
#  - DEPLOYMENT
#  - SVC
function create_k8s_deployment {
    echo "======== CREATE K8S DEPLOYMENT ${DEPLOYMENT} ========"
    envsubst < ./src/udacity-c3-deployment/k8s/${SVC}-deployment.yaml | ${KUBECTL} apply -f -
}

## Create/update K8s services
# Requires environment variables:
#  - TAG
#  - KUBECTL
#  - SVC
function create_or_update_k8s_service {
    echo "======== CREATE/UPDATE K8S SERVICE ${SVC} ========"
    envsubst < ./src/udacity-c3-deployment/k8s/${SVC}-service.yaml | ${KUBECTL} apply -f -
}

## Wait until K8s deployment is ready by checking MinimumReplicasAvailable condition
# Requires environment variables:
#  - DEPLOYMENT
#  - KUBECTL
function wait_until_k8s_deployment_ready {
    READY=$(${KUBECTL} get deploy ${DEPLOYMENT} -o json | jq '.status.conditions[] | select(.reason == "MinimumReplicasAvailable") | .status' | tr -d '"')
    while [[ "$READY" != "True" ]]; do
        READY=$(${KUBECTL} get deploy ${DEPLOYMENT} -o json | jq '.status.conditions[] | select(.reason == "MinimumReplicasAvailable") | .status' | tr -d '"')
        sleep 2
    done
}

cd ./udacity-cloud-developer-c3-project
git pull

for SVC in ${SERVICES}
do
    DEPLOYMENT=${SERVICE}-${TAG}
    
    create_k8s_deployment
    wait_until_k8s_deployment_ready
    create_or_update_k8s_service
done

echo ">>>>>>>> DONE <<<<<<<<"