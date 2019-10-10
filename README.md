# Complete simple guide to CD on GCP with CloudBuild

## Components in play
Cloud Repositories
Cloud Build
Container Registry
Cloud Run or GKE

## Setting Up The Environment

1. Setting up a Cloud Repository and initalizing a local git
  1. We will create a empty repository called *cloud_run_demo*
  ```gcloud source repos create cloud_run_demo```
  1. Now will initalize a git repo
  ```git init```
  1. Next step we will configure the remote Repositories for what we just built
  ```git config credential.helper gcloud.sh```
  1. Next we will add the remote repository
  ```git remote add google https://source.developers.google.com/p/[PROJECT_NAME]/r/cloud_run_demo```
  Where:
  *[PROJECT_NAME]* is the name of your GCP project.
1. Configure the Cloud Build
  1. We are going to create a blank file at the root of the repository called `cloudbuild.yaml`
  1. Inside the file we will add the following content:
  ```steps:
    # Build the container image
    - name: 'gcr.io/cloud-builders/docker'
    args: ['build', '-t', 'gcr.io/[PROJECT_ID]/[IMAGE]', '.']
    # Push the image to Container Registry
    - name: 'gcr.io/cloud-builders/docker'
    args: ['push', 'gcr.io/[PROJECT_ID]/[IMAGE]']
    # Deploy image to Cloud Run
    - name: 'gcr.io/cloud-builders/gcloud'
    args: ['beta', 'run', 'deploy', '[SERVICE_NAME]', '--image', 'gcr.io/[PROJECT_ID]/[IMAGE]', '--region', '[REGION]', '--platform', 'managed', '--allow-unauthenticated']
    images:
    - gcr.io/[PROJECT_ID]/[IMAGE]
  ```
1. Push code up
```git push google master```

## Creating Docker Image
Build docker container with:
```
docker build -t mysite .
```
Then we can test the site with:
```
docker run --name test-site -d -p 8080:8080 mysite
```
Kill the container with:
```
docker kill test-site
docker rm test-site
```

### Deploying to GKE

### Deploying to CloudRun
1. Setting up CloudRun
  1. Inside the cloud console set the project
  ```gcloud config set project PROJECT-ID```
  1. Now set the Cloud Run region (Using us-west1 here for example but this is flexible)
  ```gcloud config set run/region us-west1```
