KUBECTL='microk8s.kubectl'
SERVICES='backend-feed backend-user frontend reverseproxy'

## Create new K8s deployment
# Requires environment variables:
#  - DOCKER_USERNAME
#  - TAG
#  - KUBECTL
#  - SVC
function create_new_deployment {
    NEW_DEPLOY=${SVC}-${TAG}
    echo "======== CREATE K8S DEPLOYMENT ${NEW_DEPLOY} ========"
    envsubst < ./src/udacity-c3-deployment/k8s/${SVC}-deployment.yaml | ${KUBECTL} apply -f -
}

## Create or update K8s service
# Requires environment variables:
#  - TAG
#  - KUBECTL
#  - SVC
function create_or_update_service {
    echo "======== CREATE/UPDATE K8S SERVICE ${SVC} ========"
    envsubst < ./src/udacity-c3-deployment/k8s/${SVC}-service.yaml | ${KUBECTL} apply -f -
}

## Wait until K8s deployment is ready by checking MinimumReplicasAvailable condition
# Requires environment variables:
#  - NEW_DEPLOY
#  - KUBECTL
function wait_until_new_deployment_ready {
    echo "======== WAIT UNTIL K8S DEPLOYMENT ${DEPLOYMENT} READY ========"
    READY=$(${KUBECTL} get deploy ${NEW_DEPLOY} -o json | jq '.status.conditions[] | select(.reason == "MinimumReplicasAvailable") | .status' | tr -d '"')
    while [[ "$READY" != "True" ]]; do
        READY=$(${KUBECTL} get deploy ${NEW_DEPLOY} -o json | jq '.status.conditions[] | select(.reason == "MinimumReplicasAvailable") | .status' | tr -d '"')
        sleep 2
    done
}

## Find existing deployment for service
# Requires environment variables
#   - SVC
function find_old_deployment {
    echo "======== FIND OLD DEPLOYMENT FOR SERVICE ${SVC} ========"
    OLD_DEPLOY=$(${KUBECTL} get deploy --selector=app=${SVC} -o json | jq '.items[].metadata.name' | tr -d '"' | tail -n 1)
    [ -n "$OLD_DEPLOY" ] && echo "Found ${OLD_DEPLOY}"
}

## Delete existing deployment previously identified by find_old_deployment
# Requires environment variables
#   - KUBECTL
#   - OLD_DEPLOY
function delete_old_deployment {
    if [ -n "$OLD_DEPLOY" ] then
        echo "======== DELETE DEPLOYMENT ${OLD_DEPLOY} ========"
        ${KUBECTL} delete deploy ${OLD_DEPLOY}
    fi
}

cd ./udacity-cloud-developer-c3-project
git pull

for SVC in ${SERVICES}
do
    find_old_deployment

    create_new_deployment    
    wait_until_new_deployment_ready
    
    create_or_update_service
    delete_old_deployment
done

echo ">>>>>>>> DONE <<<<<<<<"