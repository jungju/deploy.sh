#!/bin/bash
set -e

function deploy_k8s {
    ###### 빌드 완료! 배포 진행합니다.
    if [ ! -z "$KUBE_CONFIG_FILENAME" ]; then
        echo "Kubernetes $KUBE_DEPLOYMENT_NAME 배포 시작. image:$DOCKER_IMAEG:$1 "
        kubectl set image deployment/$KUBE_DEPLOYMENT_NAME $KUBE_CONTAINER_NAME=$DOCKER_IMAEG:$$1 --kubeconfig $KUBE_CONFIG_FILENAME
        #kubectl set env deployment/$KUBE_DEPLOYMENT_NAME -c $KUBE_CONTAINER_NAME APP_VERSION=$$1 --kubeconfig $KUBE_CONFIG_FILENAME
        echo "Kubernetes 배포 완료."
    fi
}

GIT_MAIN_BRANCH=${GIT_MAIN_BRANCH:-main}
VERSION_TARGET=${VERSION_TARGET:-patch}
KUBE_CONTAINER_NAME=${KUBE_CONTAINER_NAME:-container-0}

# 필요 환경 변수
# DOCKER_IMAEG
# KUBE_NAMESPACE
# KUBE_DEPLOYMENT_NAME
# KUBE_CONTAINER_NAME
# KUBE_CONFIG_FILENAME
# GIT_MAIN_BRANCH
# GIT_TAG_MESSAGE
# VERSION_TARGET
# FORCE_DEPLOY

last_commit=$(git log -1 --pretty=format:%s)
GIT_TAG_MESSAGE=${GIT_TAG_MESSAGE:-$last_commit}

git_remote_url=$(git remote get-url origin)

# https protocol 일 경우
#repo_info=$(echo "$git_remote_url" | sed -nE 's#https://github.com/([^/]*)/([^/]*)\.git#\1/\2#p')
repo_info=$(echo "$git_remote_url" | sed -nE 's#git@github.com:([^/]*)/([^/]*)\.git#\1/\2#p')
repo_owner=$(echo "$repo_info" | cut -d '/' -f 1)
repo_name=$(echo "$repo_info" | cut -d '/' -f 2)

if [ "$FORCE_DEPLOY" != "true" ]; then
    # 로컬 변경 사항 확인
    git_status=$(git status --porcelain)

    # 변경 사항이 있는 경우 종료 코드 1 반환
    if [ ! -z "$git_status" ]; then
        echo "로컬 변경 사항이 있습니다. 커밋 또는 스테이지 해제 후 다시 시도하세요."
        exit 1
    fi

    # 로컬 main 브랜치와 원격 main 브랜치 간의 차이점 확인
    git fetch
    diff_output=$(git diff $GIT_MAIN_BRANCH origin/main)
    if [ -z "$diff_output" ]; then
        echo "메인 브런치와 로컬 브런치가 동일합니다. 계속 진행합니다..."
    else
        echo "메인 브런치와 로컬 브런치가 다릅니다."
        exit 1
    fi
fi

###### 코드 점검 완료! 현재 코드는 배포 가능한 코드 입니다.

last_tag=$(git tag --list | sort -rV | head -n 1)
if [ ! -z "$ONLY_DEPLOY" ]; then
    deploy_k8s $last_tag
    exit 0
fi 

new_tag='v0.0.1'
if [ ! -z "$last_tag" ]; then
    # 문자열을 '.' 기준으로 분리하여 배열에 저장
    only_version="${last_tag#v}"
    IFS='.' read -r -a array <<< "$only_version"

    if [ "$VERSION_TARGET" = "patch" ]; then
        # patch 버전 증가
        # ...
        array[2]=$((${array[2]} + 1))
    elif [ "$VERSION_TARGET" = "minor" ]; then
        # minor 버전 증가
        # ...
        array[1]=$((${array[1]} + 1))
        array[2]=0
    elif [ "$VERSION_TARGET" = "major" ]; then
        # major 버전 증가
        # ...
        array[0]=$((${array[0]} + 1))
        array[1]=0
        array[2]=0
    else
        # 잘못된 값이 들어온 경우
        echo "Invalid version target."
        exit 1
    fi

    # 새로운 버전 문자열 생성
    new_tag="v${array[0]}.${array[1]}.${array[2]}"
fi
echo "$last_tag -> $new_tag"

###### Git 태그 추가
git tag -a "$new_tag" -m "$GIT_TAG_MESSAGE"
git push origin "$new_tag"

if [ ! -z "$GITHUB_TOKEN" ]; then
    json_data=$(printf '{
    "tag_name": "%s",
    "name": "%s",
    "body": "%s",
    "draft": false,
    "prerelease": false
    }' "$new_tag" "$new_tag" "$GIT_TAG_MESSAGE")
    curl -XPOST -H "Authorization: token $GITHUB_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$json_data" \
    "https://api.github.com/repos/$repo_owner/$repo_name/releases"
fi

###### Git, GitHub에 태그 완료. 빌드 진행합니다.
if [ ! -z "$DOCKER_IMAEG" ]; then
    docker build -t $DOCKER_IMAEG:$new_tag .
    docker push $DOCKER_IMAEG:$new_tag
fi

deploy_k8s $new_tag

echo "완료"