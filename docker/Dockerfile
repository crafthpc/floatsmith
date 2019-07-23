FROM ubuntu:18.04
LABEL name="FloatSmith"
LABEL maintainer="Mike Lam <lam2mo@jmu.edu>"
LABEL description="FloatSmith container"
LABEL architecture="x86_64"
LABEL version="1.0"

# update system software
RUN apt-get update -y

# install Rose dependencies and build it
RUN apt-get install -y git wget make automake libtool gcc g++ gdb \
                       libboost-all-dev flex bison ghostscript
COPY build_rose.sh /root/build_rose.sh
RUN chmod +x /root/build_rose.sh
RUN /root/build_rose.sh

# install FloatSmith and dependencies
RUN apt-get install -y ruby bc
RUN git clone https://github.com/crafthpc/floatsmith.git /opt/floatsmith

# set up paths for Rose/TypeForge
ENV ROSE_HOME       /opt/rose
ENV PATH            $ROSE_HOME/install/bin:$PATH
ENV LD_LIBRARY_PATH $ROSE_HOME/install/bin:$LD_LIBRARY_PATH

# set up paths for FloatSmith/CRAFT
ENV FLOATSMITH_HOME /opt/floatsmith
ENV PATH            $FLOATSMITH_HOME:$PATH
ENV PATH            $FLOATSMITH_HOME/scripts:$PATH
ENV PATH            $FLOATSMITH_HOME/tools/craft/scripts:$PATH

# install other tools
RUN /opt/floatsmith/floatsmith -h

# set up non-root user, using local user/group ID if present as arguments;
# if they're present, use the mount point /local as the user's home, otherwise
# use the demos folder
ARG USER_ID
ARG GROUP_ID
RUN if [ ${USER_ID:-0} -ne 0 ] && [ ${GROUP_ID:-0} -ne 0 ]; then \
    if getent group ${GROUP_ID} ; then groupdel $(getent group ${GROUP_ID} | cut -f 1 -d ':'); fi && \
    groupadd -g ${GROUP_ID} user && \
    useradd -l -u ${USER_ID} -g user user && \
    ln -s /local /home/user \
    ; else \
    groupadd user && \
    useradd -l -g user user && \
    ln -s /opt/floatsmith/demos /home/user \
; fi

# make work/demos folders owned by non-root user
RUN mkdir /local
RUN chown -R user:user /local
RUN chown -R user:user /opt/floatsmith/demos

# switch to non-root user and launch shell
WORKDIR /home/user
USER user
CMD ["/bin/bash"]
