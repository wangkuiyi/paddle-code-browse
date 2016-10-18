realpath() {
    [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
}

DIR=$(dirname $(realpath $0))
PADDLE=$(realpath $DIR/../paddle)

if [[ ! -d $PADDLE ]]; then
    printf "Clone paddle ... "
    git clone https://github.com/baidu/Paddle $PADDLE > /dev/null 2>&1 || { echo "Failed"; exit -1; }
else
    printf "Update paddle ... "
    cd $PADDLE
    git pull > /dev/null 2>&1 || { echo "Failed"; exit -1; }
fi
echo "Done"

printf "Linking paddle ... "
ln -sf $PADDLE $DIR/paddle
echo "Done"

if docker images --format '{{.Repository}}' | grep '^paddle_ssh$' > /dev/null; then
    echo "Use the existing Docker image paddle_ssh."
else
    printf "Building paddle_ssh Docker image ... "
    cd $DIR
    docker build -t paddle_ssh . || { echo "Failed"; exit -1; }
    echo "Done"
fi

printf "Starting paddle and sshd container ... "
docker rm -f paddle_ssh > /dev/null 2>&1
docker run -d --name paddle_ssh -p 8022:22 -v $PADDLE:/paddle paddle_ssh
echo "Done"

ssh -p 8022 root@localhost
