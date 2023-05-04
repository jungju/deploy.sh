# deploy.sh

Write a brief description of your project here.

## Deployment Instructions

To deploy this project, use the `deploy.sh` script. This script will create a Git tag and a GitHub release, build a Docker image, and deploy it to a Kubernetes cluster.

Before running the script, make sure to set the following environment variables:

```bash
DOCKER_IMAGE="/jungju/go"
KUBE_NAMESPACE=""
KUBE_DEPLOYMENT_NAME=""
KUBE_CONTAINER_NAME=""
KUBE_CONFIG_FILENAME=""
GIT_MAIN_BRANCH="main"
GIT_TAG_MESSAGE=""
GITHUB_TOKEN=""
GITHUB_REPO_OWNER=""
GITHUB_REPO_NAME=""
```

Replace the values with the appropriate settings for your project and environment.

Once the environment variables are set, you can run the deploy.sh script:

```
./deploy.sh
```

The script will check if the local source is identical to the GitHub main branch. If they are identical, it will update the version in the latest tag, create a new Git tag and GitHub release, build the Docker image, and deploy it to the Kubernetes cluster.