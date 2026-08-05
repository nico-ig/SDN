FROM ubuntu:24.04

# Avoid user interaction during installation
#ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update
RUN apt-get install -y git vim cmake sudo

# Make sudo available
RUN useradd -m p4user
RUN echo "p4user ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Change user and change to user home
USER p4user
WORKDIR /home/p4user

# Create workdir
#RUN mkdir ~/workdir

# Install BMv2 and P4 depencencies
RUN git clone https://github.com/p4lang/tutorials
WORKDIR /home/p4user/src
RUN /bin/bash -c "export USER=p4user && ../tutorials/vm-ubuntu-24.04/install.sh |& tee log.txt"

# Verify the installation, abort if failed
RUN simple_switch --version

# Clone and build ns3 with p4sim
WORKDIR /home/p4user/workdir
RUN git clone https://github.com/nsnam/ns-3-dev-git.git ns3.39
WORKDIR ns3.39
RUN git checkout ns-3.39

WORKDIR contrib
RUN git clone https://github.com/HapCommSys/p4sim.git
WORKDIR p4sim
RUN sudo ./set_pkg_config_env.sh
WORKDIR /home/p4user/workdir/ns3.39
RUN ./ns3 configure --enable-tests --enable-examples
RUN ./ns3 build

WORKDIR /home/p4user
ENV P4SIM_DIR="/home/p4user/workdir/ns3.39/contrib/p4sim"
RUN echo 'export P4SIM_DIR="/home/p4user/workdir/ns3.39/contrib/p4sim"' >> /home/p4user/.bashrc

CMD ["tail", "-f", "/dev/null"]
