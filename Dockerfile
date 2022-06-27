FROM ubuntu:18.04

# ENV DEBIAN_FRONTEND noninteractive

ARG PYTHON_VER=3.7.7
ARG CMAKE_VER=v3.14.6

RUN apt-get -qq update && apt-get install -y && apt-get install -y \
    git build-essential nasm zlib1g-dev sudo \
    libssl-dev libffi-dev libxrandr-dev libxcursor-dev libxinerama-dev libxi-dev 
    
# RUN apt-get -qq install -y python3

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

# Fix linking error 
# RUN grep -qxF 'set(CMAKE_POSITION_INDEPENDENT_CODE ON)' CMakeLists.txt || echo 'set(CMAKE_POSITION_INDEPENDENT_CODE ON)' >> CMakeLists.txt

# RUN python ./build_scripts/build_usd.py --build-monolithic --verbose --prefer-safety-over-speed --no-examples --no-tutorials --no-imaging --no-usdview --draco "${USD_INSTALL}" && \
#   rm -rf "${USD_REPO}" "${USD_INSTALL}/build" "${USD_INSTALL}/src"

RUN python ./build_scripts/build_usd.py --no-examples --no-tutorials --no-imaging --no-usdview --no-draco "${USD_INSTALL}" && \
  rm -rf "${USD_REPO}" "${USD_INSTALL}/build" "${USD_INSTALL}/src"

RUN python -m pip install numpy

COPY usdzconvert /home/usdzconvert
ENTRYPOINT [ "/home/usdzconvert/usdzconvert" ]

# Share the volume that we have built to
# VOLUME ["/usr/local/usd"]