#!/bin/bash
set -e

STAGE=""
DOCKER_IMAEG=""

KUBE_NAMESPACE=""
KUBE_DEPLOYMENT_NAME=""
KUBE_CONTAINER_NAME=""
KUBE_CONFIG_FILENAME=""

GIT_MAIN_BRANCH="main"
GIT_TAG_MESSAGE=""

git_remote_url=$(git remote get-url origin)
#repo_info=$(echo "$git_remote_url" | sed -nE 's#https://github.com/([^/]*)/([^/]*)\.git#\1/\2#p')
repo_info=$(echo "$git_remote_url" | sed -nE 's#git@github.com:([^/]*)/([^/]*)\.git#\1/\2#p')
repo_owner=$(echo "$repo_info" | cut -d '/' -f 1)
repo_name=$(echo "$repo_info" | cut -d '/' -f 2)

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

###### 코드 점검 완료! 현재 코드는 배포 가능한 코드 입니다.

# stage를 포함하려면 아래 코드를 사용(예 1.0.0-beta)
#last_tag=$(git tag --list | grep "$STAGE" | sort -rV | head -n 1)
last_tag=$(git tag --list | sort -rV | head -n 1)
third_number=$(echo "$last_tag" | grep -oP '\d+\.\d+.\K\d+')
new_third_number=$((third_number + 1))

# stage를 포함하려면 아래 코드를 사용(예 1.0.0-beta)
# new_version=$(echo "$last_tag" | sed "s/\(.*\)\.\([0-9]*\)\(-.*\)/\1.$new_third_number\3/")
new_version=$(echo "$last_tag" | sed "s/\(.*\)\.\([0-9]*\)/\1.$new_third_number/")

###### Git 태그 추가
git tag -a "$new_version" -m "$GIT_TAG_MESSAGE"
git push origin "$new_version"

json_data=$(printf '{
  "tag_name": "%s",
  "name": "%s",
  "body": "%s",
  "draft": false,
  "prerelease": false
}' "$new_version" "$new_version" "$GIT_TAG_MESSAGE")
curl -XPOST -H "Authorization: token $GITHUB_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$json_data" \
  "https://api.github.com/repos/$repo_owner/$repo_name/releases"

###### Git, GitHub에 태그 완료. 빌드 진행합니다.
#docker build -t $DOCKER_IMAEG:$new_tag .
#docker push $DOCKER_IMAEG:$new_tag

###### 빌드 완료! 배포 진행합니다.
#kubectl set image deployment/$KUBE_DEPLOYMENT_NAME $KUBE_CONTAINER_NAME=$DOCKER_IMAEG:$new_tag --kubeconfig $KUBE_CONFIG_FILENAME
#kubectl set env deployment/$KUBE_DEPLOYMENT_NAME -c $KUBE_CONTAINER_NAME APP_VERSION=$new_tag --kubeconfig $KUBE_CONFIG_FILENAME

echo "완료"
exit 0