## Create/update K8s services and deployments
# Requires environment variables:
#  - DOCKER_USERNAME
#  - TAG
# Requires tools:
#  - kubectl
function k8s_deploy {
    echo '======== DEPLOY K8S ========'
    envsubst < ./src/udacity-c3-deployment/k8s/backend-feed-deployment.yaml | kubectl apply -f -
    envsubst < ./src/udacity-c3-deployment/k8s/backend-user-deployment.yaml | kubectl apply -f -
    envsubst < ./src/udacity-c3-deployment/k8s/frontend-deployment.yaml | kubectl apply -f -
    envsubst < ./src/udacity-c3-deployment/k8s/reverseproxy-deployment.yaml | kubectl apply -f -
}

cd ./udacity-cloud-developer-c3-project
git pull
k8s_deploy