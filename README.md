# Refactor Udagram App into Microservices and Deploy

[![Build Status](https://travis-ci.com/rmoritz/udacity-cloud-developer-c3-project.svg?branch=dev)](https://travis-ci.com/rmoritz/udacity-cloud-developer-c3-project)

This is my submission for the project assignment in course 3 of the Udacity
Cloud Developer Nanodegree. It is a modified version of the Udagram image
sharing web app, modified to run on a Kubernetes cluster.

The build & deploy steps have been optimized for a CI/CD tool (Travis-CI),
which does the following:

## CI/CD process

1. Perform some prerequisite tasks such as downloading and installing kubectl,
   and generating an SSH private key to connect to the production EC2 server.
2. Build Docker images for the components, namely:
  - web frontend
  - feed microservice
  - user microservice
  - reverse proxy 
3. Tag the images with the Travis-CI build ID, and push them to Docker Hub -
   see https://hub.docker.com/u/rmoeritz.
4. Login to the production EC2 server using SSH and create/update the
   Kubernetes deployments and services for the application components. This will
   cause a rolling update (A/B deployment) of all existing deployments.

## How to build and deploy locally

The build process is complicated, involving many steps. The automated build has
been optimized for Travis-CI, but the steps needed are described below if you
want to build and deploy the application locally.

### Prerequisites

 - node.js >= 13.0
 - docker >= 19.0
 - docker-compose >= 1.23
 - kubectl >= 1.17
 - a local kubernetes cluster of some sort (I use microk8s on my Laptop, but
   MicroKube should work too) corresponding to Kubernetes 1.17

### Build steps

1. Define the following environment variables:
  - `DOCKER_USERNAME` - set to your Docker Hub username
  - `TAG` - this will be used to tag the Docker images built
  
2. Next, run `docker-compose -f src/udacity-c3-deployment/docker-compose-build.yaml build --parallel`. This
   will create the following Docker images, where `$DOCKER_USERNAME` and `$TAG`
   will be replaced by the values defined in the respective environment
   variables:
   
  - $DOCKER_USERNAME/frontend:$TAG
  - $DOCKER_USERNAME/backend-feed:$TAG
  - $DOCKER_USERNAME/backend-user:$TAG
  - $DOCKER_USERNAME/reverseproxy:$TAG
  
3. You can now push the images to Docker Hub like so:
    
    docker login -u DOCKER_USERNAME -p DOCKER_PASSWORD
    docker push $DOCKER_USERNAME/frontend:$TAG
    docker push $DOCKER_USERNAME/backend-feed:$TAG
    docker push $DOCKER_USERNAME/backend-user:$TAG
    docker push $DOCKER_USERNAME/reverseproxy:$TAG
    
4. Next, you will need to edit the following files, entering your own details
   and secrets as appropriate:

  - src/udacity-c3-deployment/k8s/aws-secret.yaml
  - src/udacity-c3-deployment/k8s/env-secret.yaml
  - src/udacity-c3-deployment/k8s/env-configmap.yaml
  
5. After this, you are ready to deploy to Kubernetes. Create your local
   Kubernetes cluster and then execute the following to import the secrets and configmap

    kubectl apply -f src/udacity-c3-deployment/k8s/aws-secret.yaml
    kubectl apply -f src/udacity-c3-deployment/k8s/env-secret.yaml
    kubectl apply -f src/udacity-c3-deployment/k8s/env-configmap.yaml
    
6. Now you can create the K8s services and deployments. Since the yaml files
   contain references to the `DOCKER_USERNAME` and `TAG` environment variables,
   but kubectl doesn't support variable replacement within the yaml files
   themselves, we will use a tool called envsubst (available on Linux) to
   replace the references to the environment variables with their values. If
   you are running under Windows or Mac, you will need to find another way to
   do the same thing, e.g. sed or search & replace in a text editor.
   
    envsubst < ./src/udacity-c3-deployment/k8s/backend-feed-deployment.yaml | kubectl apply -f -
    envsubst < ./src/udacity-c3-deployment/k8s/backend-user-deployment.yaml | kubectl apply -f -
    envsubst < ./src/udacity-c3-deployment/k8s/frontend-deployment.yaml | kubectl apply -f -
    envsubst < ./src/udacity-c3-deployment/k8s/reverseproxy-deployment.yaml | kubectl apply -f -

7. If all went well you should see output similar to the following in response
   to `kubectl get services|deployments|pods` commands

    ubuntu@ip-172-31-39-131:~$ kubectl get services
    NAME           TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
    backend-feed   ClusterIP   10.152.183.37   <none>        8080/TCP   80m
    backend-user   ClusterIP   10.152.183.9    <none>        8080/TCP   80m
    frontend       ClusterIP   10.152.183.23   <none>        80/TCP     80m
    kubernetes     ClusterIP   10.152.183.1    <none>        443/TCP    82m
    reverseproxy   ClusterIP   10.152.183.98   <none>        8080/TCP   80m

    ubuntu@ip-172-31-39-131:~$ kubectl get deployments
    NAME           READY   UP-TO-DATE   AVAILABLE   AGE
    backend-feed   2/2     2            2           81m
    backend-user   2/2     2            2           81m
    frontend       2/2     2            2           81m
    reverseproxy   1/1     1            1           81m
    
    ubuntu@ip-172-31-39-131:~$ kubectl get pods
    NAME                            READY   STATUS    RESTARTS   AGE
    backend-feed-7bbf88ccf4-47772   1/1     Running   0          81m
    backend-feed-7bbf88ccf4-6ccpp   1/1     Running   0          81m
    backend-user-674b45b55d-2xfx9   1/1     Running   0          81m
    backend-user-674b45b55d-9fzdt   1/1     Running   0          81m
    frontend-6588b74c7-249h6        1/1     Running   0          81m
    frontend-6588b74c7-44pg6        1/1     Running   0          81m
    reverseproxy-5996578478-dm28r   1/1     Running   0          81m
    
8. Your application is now deployed, and you are almost ready to test the application. Open two command prompts and
   enter one of the following commands in each. This will make your application
   reachable from outside the Kubernetes cluster on your local machine.
   
    kubectl port-forward service/frontend 8100:80
    kubectl port-forward service/reverseproxy 8080:8080
    
9. You are done! Now you can test the application by opening a web browser and
   navigating to http://localhost:8100  :-)
