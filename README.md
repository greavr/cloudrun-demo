# Complete simple guide to CD on Cloud Run with CloudBuild

## Components in play
* Cloud Repositories
* Cloud Build
* Container Registry
* Cloud Run
---
## Setting Up The Environment

### Download the template site
Here we are going to download the template html site and move it into a sub folder called *Code* and then remove the existing git config to start fresh:
```
git clone https://github.com/greavr/html-template.git
cd html-template
rm -rf .git/
mkdir Code
mv * Code/
```
After we have done this we can look in the `Code/` folder at the raw HTML.<br />
**Feel free to rename and personalize a few things.**

### Setting up a Cloud Repository and initalizing a local git
In this step we will create a GCP Cloud Repository and setup a local git repo around the template we downloaded above.
1. First we enable the Source Repo API<br />
```gcloud services enable sourcerepo.googleapis.com```
1. We will create a empty repository called ***cloud_run_demo***<br />
```gcloud source repos create cloud_run_demo```
1. Now will initalize a git repo<br />
```git init```
1. Next step we will configure the remote Repositories for what we just built<br />
```git config credential.helper gcloud.sh```
1. Next we will add the remote repository<br />
```git remote add google https://source.developers.google.com/p/[PROJECT_NAME]/r/cloud_run_demo```<br />
Where:<br />
**[PROJECT_NAME]** is the name of your GCP project.

### Configuring Cloud Run
In this stage we will enable Cloud Run, and configure the default region going forward.
1. First we enable the Cloud Run API:<br />
```gcloud services enable run.googleapis.com```
1. Setting up Cloud Run
  1. Now set the Cloud Run region (Using us-west1 here for example but this is flexible)<br />
  ```gcloud config set run/region us-central1```

### Build our Dockerfile
In this stage we will build a sample container which will run our static site.
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
1. We can test running this image by using the following commands localy: <br />
    `docker build -t mysite . && docker run --name test-site -d -p 8080:8080 mysite`
1. Then we can browse the site using [localhost:8080](http://localhost:8080)
1. After we are happy the container works we kill the container with: <br />
`docker kill test-site && docker rm test-site`

### Configuring Cloud Build
In this stage we are going to build a sample Cloudbuild config file to turn our code into a container and deploy it on Cloud Run.
1. First we enable the Cloud Build API:<br />
```gcloud services enable cloudbuild.googleapis.com```
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
    Inside this file we need to replace the following values:<br />
    * `[PROJECT_ID]` - Your project name<br />
    * `[IMAGE]` - Name of our container, for this purpose call it `mysite-public`<br />
    * `[SERVICE_NAME]` - For demo sake we will call this `public-site`
        
### Configure Build
This stage we tell Cloud Build to listen to our Source Repository, and enabled the Cloud Build Service account to modify Cloud Run.
1. This step needs to be configured inside the console sadly
1. Open the console and goto Cloud Build / Triggers page [console.cloud.google.com/cloud-build/triggers](https://console.cloud.google.com/cloud-build/triggers)
1. Along the top select **+ CREATE TRIGGER**
1. Select **cloud_run_demo**
1. Under ***Build configuration*** select ***Cloud Build configuration file (yaml or json)***
1. Press **Create trigger**
1. After this is complete we need to go configure the Cloud Build service account to be able to talk to Cloud Run. To do this inside the Console goto Cloud Build Settings ([console.cloud.google.com/cloud-build/settings](https://console.cloud.google.com/cloud-build/settings))
    1. Inside here next to ***Cloud Run*** Change the Status to ***ENABLED***
    1. When prompted for Enabling extended permissions, say **Agree**
This creates a trigger which listens for any push to the repo on any branch, and then looks for a `cloudbuild.yaml` file in the repository root. It then uses that `cloudbuild.yaml` file to work out what it needs to do next.
---
### Checklist
Lets double check steps taken so far

- [ ]  Cloned the template site and removed the existing git config
- [ ]  Moved the template site into a sub folder called `Code`
- [ ]  Personalized a dummy site based on a template
- [ ]  Create a empty Cloud Repository and configured a local repository *but not pushed yet*
- [ ]  Enables Cloud Run service and configured it to default to the us-central1 region
- [ ]  Created a Dockerfile to build a container with our code running on nginx 
- [ ]  Created a Cloud Build yaml file
- [ ]  Configured Cloud Build to monitor the Cloud Repository
- [ ]  Configured the Cloud Build service account permissions to modify Cloud Run

---
### Deploy using pipeline

What we now need to do is send our code down the pipeline and check it out. To do that all we need to do is push code to the repository and go from there.
Run the following command:
```
git add -A .
git commit -m "Inital commit & Pipeline test"
git push google master
```

We can then check out build status in the console: [console.cloud.google.com/cloud-build/builds](https://console.cloud.google.com/cloud-build/builds)
    
Finally we can check the status of our Cloud Run Service with: <br />
`gcloud beta run services list --platform managed`<br />
We can get the specifics about our service with <br />
`gcloud beta run services describe public-site --platform managed`
