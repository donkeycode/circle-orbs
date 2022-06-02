cat <<EOF >  ~/project/.circleci/push_images.sh
#!/bin/bash
source ~/project/.circleci/determine_env.sh

images=(${IMAGES})

for image in "\${images[@]}"
do
    docker pull ${DOCKER_REGISTRY}\${image}:\$CIRCLE_SHA1
    if [ \$? -ne 0 ]; then
        echo "ERROR DOCKER PULL \${image}"
        exit 1
    fi

    docker image tag ${DOCKER_REGISTRY}\${image}:\$CIRCLE_SHA1 \${ECR_BASE}/\${image}:\$BUILD_ENV
    if [ \$? -ne 0 ]; then
        echo "ERROR DOCKER IMAGE TAG \${image}"
        exit 1
    fi

    docker push ${DOCKER_REGISTRY}\${image}:\$BUILD_ENV
    if [ \$? -ne 0 ]; then
        echo "ERROR DOCKER PUSH \${image}"
        exit 1
    fi

done
EOF