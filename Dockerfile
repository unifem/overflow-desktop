# Builds a Docker image for NASA Overflow 2.2 in a Desktop environment
# with Ubuntu and LXDE in both serial and parallel. The resulting image
# will be committed into a private repository.

FROM compdatasci/petsc-desktop as intermediate

ARG OVF_REPO
ARG PEG_REPO
ARG CGT_REPO
ARG PLT_REPO

USER root
WORKDIR /tmp

# checkout repositories
RUN git clone --depth=1 ${OVF_REPO} apps/overflow 2> /dev/null && \
    git clone --depth=1 ${PEG_REPO} apps/pegasus5 2> /dev/null && \
    git clone --depth=1 ${CGT_REPO} apps/chimera2 2> /dev/null && \
    git clone --depth=1 ${PLT_REPO} apps/plot3d4 2> /dev/null && \
    perl -e 's/https:\/\/[\w:\.]+@([\w\.]+)\//git\@$1:/' -p -i \
        apps/*/.git/config

FROM compdatasci/petsc-desktop
LABEL maintainer "Xiangmin Jiao <xmjiao@gmail.com>"

USER root
WORKDIR /tmp

ARG TCLTK_VERSION=8.5

# Install system packages required by Chimera
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        libtcl${TCLTK_VERSION} \
        libtk${TCLTK_VERSION} \
        tcl${TCLTK_VERSION}-dev \
        tk${TCLTK_VERSION}-dev \
        libgl1-mesa-dev \
        libglu1-mesa \
        libglu1-mesa-dev \
        libxi-dev \
        freeglut3 freeglut3-dev \
        libxmu-dev \
        python-dev \
        python-numpy \
        python-matplotlib \
        python-mpi4py \
        \
        swig \
        time \
        grace \
        gnuplot \
        python3-dev \
        python3-numpy \
        python3-matplotlib \
        python3-mpi4py && \
    apt-get clean && \
    apt-get autoremove && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV TCLDIR_INC=/usr/include/tcl${TCLTK_VERSION} \
    TKDIR_INC=/usr/include/tk${TCLTK_VERSION} \
    X11DIR_INC=/usr/include \
    TCLDIR_SO=/usr/lib/x86_64-linux-gnu \
    TKDIR_SO=/usr/lib/x86_64-linux-gnu \
    X11DIR_SO=/usr/lib/x86_64-linux-gnu \
    TCL_LIBRARY=/usr/share/tcltk/tcl${TCLTK_VERSION} \
    TK_LIBRARY=/usr/share/tcltk/tk${TCLTK_VERSION} \
    PYTHON_INC=/usr/include/python2.7 \
    \
    MPI_ROOT=/usr/lib/x86_64-linux-gnu/openmpi \
    PYTHON_INCLUDE=/usr/include/python2.7 \
    NUMPY_INCLUDE=/usr/include/python2.7/numpy \
    PYTHON3_INCLUDE=/usr/include/python3.6 \
    NUMPY3_INCLUDE=/usr/include/python3.6/numpy \
    TIME=/usr/bin/time

WORKDIR $DOCKER_HOME
COPY --from=intermediate /tmp/apps .
RUN chown -R $DOCKER_USER:$DOCKER_GROUP $DOCKER_HOME

USER $DOCKER_USER

ARG MAKE_SUF=_sp
ARG BIN_SUF=

# Obtain overflow and compile it with MPI
# https://overflow.larc.nasa.gov/files/2016/02/Chapter_2.pdf
RUN cd overflow && \
    ./makeall$MAKE_SUF gfortran F90FLAGS=-O3 CFLAGS=-O3  && \
    \
    echo "export PATH=$DOCKER_HOME/overflow/bin$BIN_SUF:\$PATH:." >> \
        $DOCKER_HOME/.zshrc

# Obtain pagasus5 and compile it with MPI
# https://www.nas.nasa.gov/publications/software/docs/pegasus5/s
RUN cd $DOCKER_HOME && \
    cd pegasus5 && \
    ./configure --with-mpif90 && \
    make && \
    make CMD=install && \
    \
    echo "export PATH=$DOCKER_HOME/bin:\$PATH" >> \
        $DOCKER_HOME/.zshrc

# Obtain chimera2 and compile it
# https://www.nas.nasa.gov/publications/software/docs/chimera/index.html
RUN cd $DOCKER_HOME && \
    cd chimera2 && \
    ./configure --with-fort=gfortran --with-cc=gcc && \
    make && \
    make CMD=install && \
    make clean && \
    \
    echo "export PATH=$DOCKER_HOME/chimera2/bin$MAKE_SUF:\$PATH" >> \
        $DOCKER_HOME/.zshrc

# Obtain plot3d and compile it; Do not enable CGNS
RUN cd $DOCKER_HOME && \
    cd plot3d4 && \
    ./configure && \
    make && \
    make clean && \
    \
    echo "export PATH=$DOCKER_HOME/plot3d4/bin:\$PATH" >> \
        $DOCKER_HOME/.zshrc

USER root
