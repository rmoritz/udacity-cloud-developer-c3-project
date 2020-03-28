## Download and intall kubectl
# Requires tools:
#  - curl
function download_and_install_kubectl {
    echo '======== INSTALL KUBECTL ========'
    curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
    chmod +x ./kubectl
    sudo mv ./kubectl /usr/local/bin/kubectl  
}

## Generate SSH private key
# Requires tools:
#  - openssl
#  - ssh-agent
#  - ssh-add
function generate_ssh_pk {
    echo '======== GENERATE SSH PK ========'
    openssl aes-256-cbc -K $encrypted_dfdcfd5172af_key -iv $encrypted_dfdcfd5172af_iv -in deploy_key.enc -out ./deploy_key -d
    chmod 600 ./deploy_key
    eval "$(ssh-agent -s)"
    ssh-add ./deploy_key
}

## Delete all K8s deployments and services
# Requires tools:
#  - kubectl
function k8s_clean {
    echo '======== CLEAN-UP K8s ========'
    kubectl delete deployments $(kubectl get deployments | tail -n +2 | cut -d ' ' -f 1)
    kubectl delete services $(kubectl get services | tail -n +2 | cut -d ' ' -f 1)
}

## Build, tag and push Docker images to Docker Hub
# Requires environment variables:
#  - DOCKER_USERNAME
#  - DOCKER_PASSWORD
#  - TAG
# Requires tools:
#  - docker
#  - docker-compose
function build_and_push_docker_images {
    echo '======== BUILD & PUSH DOCKER IMAGES ========'
    docker-compose -f ./src/udacity-c3-deployment/docker/docker-compose-build.yaml build --parallel
    echo ${DOCKER_PASSWORD} | docker login -u ${DOCKER_USERNAME} --password-stdin
    docker push ${DOCKER_USERNAME}/udacity-restapi-feed:${TAG}
    docker push ${DOCKER_USERNAME}/udacity-restapi-user:${TAG}
    docker push ${DOCKER_USERNAME}/udacity-frontend:${TAG}
    docker push ${DOCKER_USERNAME}/reverseproxy:${TAG}
}

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

## Login to prod host using SSH and deploy
# Requires environment variables:
#  - DOCKER_USERNAME
#  - TAG 
#  - PROD_HOST
# Requires tools:
#  - ssh
# Depends on:
#  - k8s_deploy
function k8s_deploy_on_prod_host {
    echo '======== LOGIN SSH PROD HOST ========'
    ssh -i ./deploy_key ${PROD_HOST} -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -oSendEnv=DOCKER_USERNAME -oSendEnv=TAG << EOF
 cd ./udacity-cloud-developer-c3-project
 git pull
 source ./scripts/build-deploy-functions.sh
 k8s_deploy
EOF    
}