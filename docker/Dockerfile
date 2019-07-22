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
ENV PATH            $FLOATSMITH_HOME/scripts:$PATH
ENV PATH            $FLOATSMITH_HOME/tools/craft/scripts:$PATH

# install other tools
RUN /opt/floatsmith/floatsmith -h

# run shell in demo folder
WORKDIR /opt/floatsmith/demos
CMD ["/bin/bash"]

