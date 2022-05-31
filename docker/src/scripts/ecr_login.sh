echo "Install or Update aws cli"
if hash apk 2>/dev/null; then
    # Install with apk
    apk add --update \
        python \
        python-dev \
        py-pip \
        build-base \
        && pip install awscli --upgrade --user \
        && apk --purge -v del py-pip \
        && rm -rf /var/cache/apk/*
else
    sudo apt-get update
    sudo apt-get install -y unzip curl
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    sudo unzip awscliv2.zip
    ./aws/install
fi

AWS_DEFAULT_REGION=eu-west-1 AWS_ACCESS_KEY_ID=$DOCKER_USER AWS_SECRET_ACCESS_KEY=$DOCKER_PASS aws ecr get-login-password |
  docker login \
    --username AWS \
    --password-stdin \
    $DOCKER_REGISTRY