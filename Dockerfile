FROM centos:centos7

MAINTAINER fsadiq1@jhu.edu

ENV RUBY_DIR /ruby
ENV RUBY_VERSION 2.3.6
ENV RUBY_INSTALL $RUBY_DIR/$RUBY_VERSION

RUN yum -y update && \
    yum -y install epel-release && \
    yum -y update && \
    yum install -y \
        bzip2 \
        curl \
        gcc \
        gcc-c++ \
        gdbm-devel \
        git \
        gpg \
        libffi-devel \
        libxml-devel \
        libyaml-devel \
        make \
        mysql-devel \
        ncurses-devel \
        openssl-devel \
        patch \
        readline-devel \
        sqlite-devel \
        tar \
        wget \
        which \
        zlib-devel 

RUN cd /usr/src && \
    git clone https://github.com/sstephenson/ruby-build.git && \
    ./ruby-build/install.sh && \
    mkdir -p $RUBY_INSTALL 
RUN /usr/local/bin/ruby-build $RUBY_VERSION $RUBY_INSTALL && \
    rm -rf /usr/src/ruby-build

ENV NODE_VERSION 5.6.0

RUN wget https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.gz -O /tmp/node-v${NODE_VERSION}-linux-x64.tar.gz && \
  tar --strip-components 1 -xzvf /tmp/node-v* -C /usr/local

ENV PATH $RUBY_INSTALL/bin:$PATH

RUN gem install bundler

# build app 
ENV APP_DIR /opt
ENV INTERNAL_PORT 3000

WORKDIR $APP_DIR
RUN bundle config --global silence_root_warning 1
    
ADD . $APP_DIR
RUN bundle install
#ADD marc_display $APP_DIR/marc_display
#ADD Gemfile $APP_DIR/Gemfile
#ADD Gemfile $APP_DIRGemfile
#ADD Gemfile.lock $APP_DIR/Gemfile.lock
#RUN bundle install

EXPOSE $INTERNAL_PORT

# docker build --rm -t local/c5catalyst .
# docker run -ti -v $PWD:/opt/app -p 3000:3000 local/c5catalyst
