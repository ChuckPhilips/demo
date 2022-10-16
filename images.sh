#! /bin/bash

echo "Updating infrastructure !!!"
AWS_REGION="us-east-2"
AWS_ECR_REPOSITORY="ecr-simplehttp"
FILTER_TAG="latest"

IMAGES_EXIST=$(aws ecr list-images --repository-name "${AWS_ECR_REPOSITORY}" --region "${AWS_REGION}" | jq '.imageIds | length')

if [[ ${IMAGES_EXIST} -gt 0 ]]; then
  echo "buildImage=false" >> /tmp/GITHUB_ENV

  images=$(aws ecr describe-images --repository-name "${AWS_ECR_REPOSITORY}" --image-ids imageTag="${FILTER_TAG}" --region "${AWS_REGION}")
  tag=$(echo "$images" | jq '.imageDetails[].imageTags[]' | tr -d '"' | grep -v "$FILTER_TAG" | head -n1)
  
  if [[ $(echo $tag | wc -l) -gt 0 ]]
  then
	  echo "Latest tag is: $tag"
  else 
	  echo "Latest tag does not exits, exiting..."
	  exit 1
  fi
  
  echo "LATEST_TAG=${tag}" >> /tmp/GITHUB_ENV
else
  echo "There are no images!!"
  echo "buildImage=true" >> /tmp/GITHUB_ENV
fi

cat /tmp/GITHUB_ENV
