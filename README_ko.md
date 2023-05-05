# deploy.sh
- A: CICD 너무 귀찮아! 관리도 어려워! 그냥 로컬에서 빌드하고 배포하면 안되나?
- B: 음 그건 너무 옛날 방식이고 옳은 방법이 아냐?
- deploy.sh: 그건 고정관념! 안전하게 로컬에서 빌드하고 배포 할 수 있습니다!

## 개발 개요
소프트웨어가 마이크로서비스로 발전하면서 점점 많아지고 있습니다. 그리고 전부 CICD 설정을 해야 하지만 쉽지 않습니다. DevOps팀이 있어서 CICD를 해결 해줄 수도 있겠지만 대부분 그렇지 않습니다. 있어도 복잡할 수 있습니다. 그래서 만들었습니다. 젠킨스도 CICD 툴도 필요 없이 안전한 코드를 로컬에서 배포합니다.

누구나 deploy.sh를 가지고 자신의 소스에 맞게 사용할 수 있습니다.

## 기능
- 로컬 소스와 GitHub Repository의 메인브런치와 동일해야  진행합니다.
- Git의 태그를 읽어 자동으로 버전을 업데이트 합니다. v1.0.0 -> v1.0.1
- 만들어진 Git 태그를 이용해 GitHub Release를 만들어 줍니다.
- Docker를 Build하고 Push합니다.
- Kubernetes에 배포합니다.

### 코드로 축약 설명
```
git status --porcelain #로컬 소스 변경중인지 확인
git diff $GIT_MAIN_BRANCH origin/main #메인브런치와 다른지 비교
git tag --list | sort -rV | head -n 1 #마지막 Git 태그 가져오기
# Git Tag를 버전 업데이트. v1.0.0 -> v1.0.1
git tag -a v1.0.1 # 새로운 Git 태그 생성
docker build repo/app:v1.0.1 . # 새로운 태그명으로 빌드
docker push repo/app:v1.0.1 # 새로운 태그명으로 Docker Push
# 새로운 태그명으로 GitHub Release 생성
kubectl set image deployment/app container-0=repo/app:v1.0.1 # 앱배포
```

## 입력 설명
- STAGE: alpha, beta 등 Version 포함 가능합니다. (v1.0.0-beta)
- DOCKER_IMAEG: Docker Image 주소
- KUBE_NAMESPACE: Kubenetes Namespace
- KUBE_DEPLOYMENT_NAME: Kubenetes deployment이름
- KUBE_CONTAINER_NAME: Kubenetes deployment의 container이름
- KUBE_CONFIG_FILENAME: kubeconfig 파일위치
- GIT_MAIN_BRANCH: master 또는 main
- GIT_TAG_MESSAGE: Tag 및 Release 메세지

## TODO
- [ ] 알림 기능
- [ ] Major 버전 업데이트 