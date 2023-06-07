FROM ubuntu:18.04 as build

# ENV DEBIAN_FRONTEND noninteractive

ARG PYTHON_VER=3.7.7
ARG CMAKE_VER=v3.14.6

RUN apt-get -qq update && apt-get install -y && apt-get install -y \
    git build-essential nasm zlib1g-dev sudo \
    libssl-dev libffi-dev libxrandr-dev libxcursor-dev libxinerama-dev libxi-dev 
    

#install cmake
WORKDIR /home/tmp/cmake
RUN git clone --branch "${CMAKE_VER}" --depth 1 https://github.com/Kitware/CMake/
WORKDIR /home/tmp/cmake/CMake
RUN ./bootstrap && make && sudo make install
RUN rm -rf "/home/tmp/cmake"

#install python
WORKDIR /home/tmp/python
ADD https://www.python.org/ftp/python/$PYTHON_VER/Python-$PYTHON_VER.tgz Python.tgz
RUN tar xzf Python.tgz
WORKDIR /home/tmp/python/Python-$PYTHON_VER
RUN ./configure --enable-shared --enable-optimizations
RUN make install
RUN rm -rf "/home/tmp/python"
RUN ln -s /usr/local/bin/python3 /usr/local/bin/python
# RUN ln -s /usr/bin/python3 /usr/bin/python
RUN ldconfig


# install USD
WORKDIR /usr/src/usd

# Configuration
ARG USD_RELEASE="v22.05b"
ARG USD_INSTALL="/usr/local/usd"
ENV PYTHONPATH="${PYTHONPATH}:${USD_INSTALL}/lib/python"
ENV PATH="${PATH}:${USD_INSTALL}/bin"

# Dependencies

# Build + install USD
RUN git clone --branch "${USD_RELEASE}" --depth 1 https://github.com/PixarAnimationStudios/USD.git /usr/src/usd


RUN python ./build_scripts/build_usd.py --no-examples --no-tutorials --no-imaging --no-usdview --no-draco "${USD_INSTALL}" && \
  rm -rf "${USD_REPO}" "${USD_INSTALL}/build" "${USD_INSTALL}/src"



FROM ubuntu:jammy

ARG PYTHON_VER=3.7.7

ENV DEBIAN_FRONTEND noninteractive

# install wget
RUN true \
    && apt-get update \
    && apt-get -y install wget \
    && apt-get clean \ 
    && rm -rf /var/lib/apt/lists/* \
    && true


#install python
RUN true \
    && apt-get update \
    && apt-get -y install build-essential libssl-dev zlib1g-dev\

    && mkdir -p /home/tmp/python \
    && cd /home/tmp/python \
    && wget -O Python.tgz https://www.python.org/ftp/python/$PYTHON_VER/Python-$PYTHON_VER.tgz  \
    && tar xzf Python.tgz \
    && cd Python-$PYTHON_VER \
    && ./configure --enable-shared --enable-optimizations \ 
    && make install \
    && ln -s /usr/local/bin/python3 /usr/local/bin/python \
    && ln -s /usr/local/bin/pip3 /usr/local/bin/pip \
    && rm -rf /home/tmp/python \
    && apt-get -y remove build-essential libssl-dev zlib1g-dev \ 	
    && apt autoremove -y \
    && apt-get clean \ 
    && rm -rf /var/lib/apt/lists/* \
    && ldconfig \
    && true

RUN python -m pip install --upgrade pip
RUN python -m pip install numpy

COPY usdzconvert /home/usdzconvert
RUN chmod 755 /home/usdzconvert/usdzconvert
COPY --from=build /usr/local/usd /usr/local/usd
ARG USD_INSTALL="/usr/local/usd"
ENV PYTHONPATH="${PYTHONPATH}:${USD_INSTALL}/lib/python"
ENV PATH="${PATH}:${USD_INSTALL}/bin"

ENTRYPOINT [ "/home/usdzconvert/usdzconvert" ]
