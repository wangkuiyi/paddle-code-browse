# Run Paddle Docker Container and SSH into It.

It is true that we can run Paddle in a Docker container by simply typing

```
docker run -it paddledev/paddle:cpu-latest /bin/bash
```

but it is usually a pain to use bash inside a container, for example,
if we run bash inside container, we'd have to
[type Ctrl-P twice](http://stackoverflow.com/questions/20828657/docker-change-ctrlp-to-something-else)
before getting the previous command line.

An easy solution to this is to run both Paddle and OpenSSH server
inside a container, and we SSH into the container from the host
machine, as described in
[Paddle's document](http://www.paddlepaddle.org/doc/build/docker_install.html#remote-access).

This repo slightly simplifies the described method by providing a
`run.sh` script which builds the Docker image of Paddle and OpenSSH
server, runs the container and SSH into the container.

<!--  LocalWords:  paddledev Ctrl OpenSSH repo
 -->
