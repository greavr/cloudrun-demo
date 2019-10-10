# Complete simple guide to CD on Cloud Run with CloudBuild

## Components in play
Cloud Repositories
Cloud Build
Container Registry
Cloud Run

## Setting Up The Environment

#### Setting up a Cloud Repository and initalizing a local git
1. We will create a empty repository called ***cloud_run_demo***
```gcloud source repos create cloud_run_demo```
1. Now will initalize a git repo
```git init```
1. Next step we will configure the remote Repositories for what we just built
```git config credential.helper gcloud.sh```
1. Next we will add the remote repository
```git remote add google https://source.developers.google.com/p/[PROJECT_NAME]/r/cloud_run_demo```
Where:
**[PROJECT_NAME]** is the name of your GCP project.

### Deploying to CloudRun
1. Setting up CloudRun
  1. Now set the Cloud Run region (Using us-west1 here for example but this is flexible)
  ```gcloud config set run/region us-central1```

#### Build our Dockerfile
1. Create a blank file called `Dockerfile`
1. Add the following:
      ```
      FROM nginx:alpine
      LABEL maintainer="Rgreaves@google.com"
      COPY Code/ /usr/share/nginx/html
      RUN sed -i 's/80\;/8080\;/g' /etc/nginx/conf.d/default.conf
      EXPOSE 8080
      ```
1. Lets walk through each line:
    * `FROM nginx:alpine` - Our base image, in this case just Nginx running ontop of the alpine OS
   * `LABEL maintainer="Rgreaves@google.com"` - Using Labels in Dockerfiles organizes information cleanly inside the container and provides a point of contact for future issues
    * `COPY Code/ /usr/share/nginx/html` - Lets add in our code to the nginx root folder. 
    * `RUN sed -i 's/80\;/8080\;/g' /etc/nginx/conf.d/default.conf` - Cloud Run assumes the pod is accesible on port 8080, by default nginx is set to port 80, this fixes this
    * `EXPOSE 8080` - This lets other users know what port to listen too and ensure the container is open on the port we need
1. We can test running this image by using the following commands localy: 
    `docker build -t mysite . && docker run --name test-site -d -p 8080:8080 mysite`
1. Then we can browse the site using [localhost:8080](http://localhost:8080)
1. After we are happy the container works we kill the container with: 
`docker kill test-site && docker rm test-site`

#### Configure the Cloud Build
1. We are going to create a blank file at the root of the repository called `cloudbuild.yaml`
1. Inside the file we will add the following content:
    ```
    steps:
    # Build the container image
    - name: 'gcr.io/cloud-builders/docker'
    args: ['build', '-t', 'gcr.io/[PROJECT_ID]/[IMAGE]', '.']
    # Push the image to Container Registry
    - name: 'gcr.io/cloud-builders/docker'
    args: ['push', 'gcr.io/[PROJECT_ID]/[IMAGE]']
    # Deploy image to Cloud Run
    - name: 'gcr.io/cloud-builders/gcloud'
    args: ['beta', 'run', 'deploy', '[SERVICE_NAME]', '--image', 'gcr.io/[PROJECT_ID]/[IMAGE]', '--region', 'us-central1', '--platform', 'managed', '--allow-unauthenticated']
    images:
    - gcr.io/[PROJECT_ID]/[IMAGE]
    ```
    Inside this file we need to replace the following values:
        * `[PROJECT_ID]` - Your project name
        * `[IMAGE]` - Name of our container, for this purpose call it `mysite-public`
        * `[SERVICE_NAME]` - For demo sake we will call this `Public Site`
        
### Configure Build Trigger
1. This step needs to be configured inside the console sadly
1. Open the console and goto Cloud Build / Triggers page [console.cloud.google.com/cloud-build/triggers](https://console.cloud.google.com/cloud-build/triggers)
1. Along the top select **+ CREATE TRIGGER**
1. Select **cloud_run_demo**
1. Under ***Build configuration*** select ***Cloud Build configuration file (yaml or json)***
1. Press **Create trigger**
This creates a trigger which listens for any push to the repo on any branch, and then looks for a `cloudbuild.yaml` file in the repository root. It then uses that `cloudbuild.yaml` file to work out what it needs to do next.
 
### Deploy using pipeline

So far we have:
1. Create a empty GCP Source Repository and configured a local repository *but not pushed yet*
1. Enables Cloud Run service and configured it to default to the us-central1 region
1. Created a Dockerfile to build a container with our code running on nginx 
1. Created a Cloud Build yaml file which goes through the following steps:
    1. Create a container based on our dockerfile
    1. Push the container to our GCP repository
    1. Push the container to a Cloud Run service and open it to the world
    2. 
What we now need to do is send our code down the pipeline and check it out. To do that all we need to do is push code to the repository and go from there.
Back on our local machine we are going to run the following command:
```
git add -A .
git commit -m "Inital commit & Pipeline test"
git push google master
```

We can then check out build status in the console: [console.cloud.google.com/cloud-build/builds](https://console.cloud.google.com/cloud-build/builds)
    
Finally we can check the status of our Cloud Run Service with: `gcloud beta run services list --platform managed`