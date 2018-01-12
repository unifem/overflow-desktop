# Builds a Docker image for NASA Overflow 2.2 in a Desktop environment
# with Ubuntu and LXDE in both serial and parallel. The resulting image
# will be committed into a private repository.
#
# Authors:
# Xiangmin Jiao <xmjiao@gmail.com>

FROM x11vnc/docker-desktop
LABEL maintainer "Xiangmin Jiao <xmjiao@gmail.com>"

ARG GIT_REPO

USER $DOCKER_USER
WORKDIR $DOCKER_HOME

RUN git clone ${GIT_REPO} overflow && \
    cd overflow && \
    perl -e 's/https:\/\/[\w:\.]+@([\w\.]+)\//git\@$1:/' -p -i .git/config && \
    ./makeall gfortran && \
    \
    echo "export PATH=$DOCKER_HOME/overflow/bin:\$PATH:." >> \
        $DOCKER_HOME/.profile

USER root
