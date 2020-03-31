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
    ssh -i ./deploy_key ${PROD_HOST} -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -oSendEnv=DOCKER_USERNAME -oSendEnv=TAG < ./scripts/deploy.sh
}
