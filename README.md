# deploy.sh
- A: CICD is such a hassle! It's hard to manage too! Can't I just build and deploy from my local machine?
- B: Well, that's an old-fashioned and not exactly the right way to do it?
- deploy.sh: That's a misconception! You can safely build and deploy from your local machine!

## Development Overview
As software evolves into microservices, their numbers are growing. Each one needs to be set up with CICD, but it's not easy. Some may have a DevOps team to handle CICD, but most don't. Even if there is, it can be complicated. That's why we created this. Deploy your safe code locally without needing Jenkins or any CICD tools.

Anyone can use deploy.sh and adapt it to their own source.

## Features
- The local source must match the main branch of the GitHub Repository.
- It reads Git tags and automatically updates the version. (v1.0.0 -> v1.0.1)
- It creates a GitHub Release using the created Git tag.
- It builds and pushes Docker.
- It deploys to Kubernetes.

### Code Explanation in Brief
```
git status --porcelain #check for local source changes
git diff $GIT_MAIN_BRANCH origin/main #compare with the main branch
git tag --list | sort -rV | head -n 1 #get the last Git tag
# Update Git Tag version. v1.0.0 -> v1.0.1
git tag -a v1.0.1 # create new Git tag
docker build repo/app:v1.0.1 . # build with new tag name
docker push repo/app:v1.0.1 # push Docker with new tag name
# create GitHub Release with new tag name
kubectl set image deployment/app container-0=repo/app:v1.0.1 # deploy the app
```

## Input Description
- DOCKER_IMAGE: Docker Image address
- KUBE_NAMESPACE: Kubernetes Namespace
- KUBE_DEPLOYMENT_NAME: Kubernetes deployment name
- KUBE_CONTAINER_NAME: Kubernetes deployment container name
- KUBE_CONFIG_FILENAME: kubeconfig file location
- GIT_MAIN_BRANCH: master or main
- GIT_TAG_MESSAGE: Tag and Release message
- VERSION_TARGET: patch, minor, major

## Reference to Makefile
```
# If the local git status is the same as the remote, update to the patch version and deploy.
deploy:
	./deploy.sh # 

# If the local git status is the same as the remote, update to the major version and deploy.
deploy-major:
	VERSION_TARGET=major ./deploy.sh

# If the local git status is the same as the remote, update to the minor version and deploy.
deploy-minor:
	VERSION_TARGET=minor ./deploy.sh

# If the local git status is the same as the remote, deploy directly to K8s.
deploy-only-k8s:
	ONLY_DEPLOY=true ./deploy.sh

# Ignore the local git status and update to the patch version and deploy.
deploy-force:
	FORCE_DEPLOY=true ./deploy.sh # Deploy without checking Git
```

## TODO
- [ ] Notification feature
- [x] Major version update