FROM ubuntu:18.04
LABEL name="FloatSmith"
LABEL maintainer="Mike Lam <lam2mo@jmu.edu>"
LABEL description="FloatSmith container"
LABEL architecture="x86_64"
LABEL version="1.0"

# set up paths for Rose/TypeForge
ENV ROSE_HOME       /opt/rose
ENV PATH            $ROSE_HOME/install/bin:$PATH
ENV LD_LIBRARY_PATH $ROSE_HOME/install/bin:$LD_LIBRARY_PATH

# set up paths for FloatSmith/CRAFT
ENV FLOATSMITH_HOME /opt/floatsmith
ENV PATH            $FLOATSMITH_HOME:$PATH
ENV PATH            $FLOATSMITH_HOME/scripts:$PATH
ENV PATH            $FLOATSMITH_HOME/tools/craft/scripts:$PATH

# update system software and install dependencies + Rose build script
RUN apt-get update -y
RUN apt-get install -y git wget make automake libtool gcc g++ gdb \
                       libboost-all-dev flex bison ghostscript ruby bc
COPY build_rose.sh /opt/build_rose.sh
RUN chmod +x /opt/build_rose.sh

# set up non-root user, using local user/group ID if present as arguments;
ARG USER_ID
ARG GROUP_ID
RUN if [ ${USER_ID:-0} -ne 0 ] && [ ${GROUP_ID:-0} -ne 0 ]; then \
    if getent group ${GROUP_ID} ; then groupdel $(getent group ${GROUP_ID} | cut -f 1 -d ':'); fi && \
    groupadd -g ${GROUP_ID} user && \
    useradd -l -u ${USER_ID} -g user user \
    ; else \
    groupadd user && \
    useradd -l -g user user \
; fi

# make work folders owned by non-root user and switch to that user
RUN mkdir /local
RUN chown -R user:user /local
RUN chown -R user:user /opt
USER user

# download, build, and install Rose
RUN /opt/build_rose.sh

# install FloatSmith and dependencies
RUN git clone https://github.com/crafthpc/floatsmith.git /opt/floatsmith
RUN /opt/floatsmith/floatsmith -h

# if local user/group ID is present, use the mount point /local as the user's
# home, otherwise use the demos folder
USER root
RUN rm -rf /home/user
RUN if [ ${USER_ID:-0} -ne 0 ] && [ ${GROUP_ID:-0} -ne 0 ]; then \
    ln -s /local /home/user \
    ; else \
    ln -s /opt/floatsmith/demos /home/user \
; fi

# change to user's home folder and launch shell
USER user
WORKDIR /home/user
CMD ["/bin/bash"]
