# Builds a Docker image for NASA Overflow 2.2 in a Desktop environment
# with Ubuntu and LXDE in both serial and parallel. The resulting image
# will be committed into a private repository.
#
# Authors:
# Xiangmin Jiao <xmjiao@gmail.com>

FROM compdatasci/petsc-desktop
LABEL maintainer "Xiangmin Jiao <xmjiao@gmail.com>"

ARG GIT_REPO

USER $DOCKER_USER
WORKDIR $DOCKER_HOME

# Obtain overflow and compile it with MPI
RUN mkdir -p $DOCKER_HOME/project && \
    cd $DOCKER_HOME/project && \
    git clone ${GIT_REPO} overflow 2> /dev/null && \
    cd overflow && \
    perl -e 's/https:\/\/[\w:\.]+@([\w\.]+)\//git\@$1:/' -p -i .git/config && \
    MPI_ROOT=/usr/lib/x86_64-linux-gnu/openmpi ./makeall gfortran && \
    \
    echo "export PATH=$DOCKER_HOME/overflow/bin:\$PATH:." >> \
        $DOCKER_HOME/.profile

# Obtain pagasus5 and compile it with MPI
RUN cd $DOCKER_HOME/project && \
    git clone ${PEG_REPO} pegasus5 2> /dev/null && \
    cd pegasus5 && \
    perl -e 's/https:\/\/[\w:\.]+@([\w\.]+)\//git\@$1:/' -p -i .git/config && \
    ./configure --with-mpif90 && \
    make && \
    make CMD=install && \
    \
    echo "export PATH=$DOCKER_HOME/bin:\$PATH:." >> \
        $DOCKER_HOME/.profile

USER root
