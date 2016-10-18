FROM paddledev/paddle:cpu-latest

MAINTAINER Yi Wang <yi.wang.2005@gmail.com>

RUN apt-get update
RUN apt-get install -y openssh-server emacs24-nox
RUN mkdir /var/run/sshd
RUN echo 'root:root' | chpasswd

RUN sed -ri 's/^PermitRootLogin\s+.*/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config

EXPOSE 22

CMD    ["/usr/sbin/sshd", "-D"]
