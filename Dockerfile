FROM nvidia/cuda:8.0-cudnn7-devel-ubuntu16.04

ENV CAFFE_ROOT /opt/nvcaffe
WORKDIR ${CAFFE_ROOT}

MAINTAINER galois "yszheda@gmail.com"


# Install packages
RUN DEBIAN_FRONTEND=noninteractive apt-get update -qq \
&& DEBIAN_FRONTEND=noninteractive apt-get install -qq -y git python python-setuptools \
autoconf \
automake \
libtool \
curl \
make \
g++ \
unzip \
cmake \
protobuf-compiler \
libboost-all-dev \
libgflags-dev \
libgoogle-glog-dev \
libopenblas-dev \
libopencv-dev \
libhdf5-serial-dev \
liblmdb-dev \
# libprotobuf-dev \
libleveldb-dev \
libsnappy-dev \
libturbojpeg

RUN ln -s /usr/lib/x86_64-linux-gnu/libturbojpeg.so.0 /usr/lib/x86_64-linux-gnu/libturbojpeg.so


# Install pip
RUN easy_install pip

# Install easydict
RUN pip install easydict


# Download source code
RUN git clone https://github.com/NVIDIA/caffe ${CAFFE_ROOT}


# install python libs
RUN cd ${CAFFE_ROOT} && \
pip install -r ${CAFFE_ROOT}/python/requirements.txt -i https://pypi.mirrors.ustc.edu.cn/simple && \
pip install --upgrade six


# config cudnn
# RUN cp /usr/include/cudnn.h /usr/local/cuda/include/ && \
# cp /usr/lib/x86_64-linux-gnu/libcudnn* /usr/local/cuda/lib64/


# Build protobuf
RUN git clone --recursive https://github.com/google/protobuf /opt/protobuf && \
cd /opt/protobuf && git fetch && git checkout 3.4.x && \
./autogen.sh && ./configure && make -j40 && make install && ldconfig && \
cd /opt/ && rm -rf /opt/protobuf


# Install NCCL
RUN git clone https://github.com/NVIDIA/nccl.git /opt/nccl && \
cd /opt/nccl && make -j install && cd /opt/ && rm -rf /opt/nccl


# Make caffe
COPY Makefile.config ${CAFFE_ROOT}/
RUN cd ${CAFFE_ROOT} && \
make && make pycaffe


# Clean
RUN apt-get clean && \
rm -rf /var/lib/apt/lists/*


ENV PYCAFFE_ROOT $CAFFE_ROOT/python
ENV PYTHONPATH $PYCAFFE_ROOT:$PYTHONPATH
ENV PATH $CAFFE_ROOT/build/tools:$PYCAFFE_ROOT:$PATH
RUN echo "${CAFFE_ROOT}/build/lib" >> /etc/ld.so.conf.d/caffe.conf && ldconfig


WORKDIR /workspace
