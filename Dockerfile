FROM ubuntu:14.04
MAINTAINER stepanovmm@gmail.com

# To deal with the fact that lucid is EOL distro
RUN apt-get update -y && apt-get install -y --no-install-recommends software-properties-common python2.7
RUN apt-add-repository ppa:brightbox/ruby-ng
RUN apt-get update -y && apt-get install -y --no-install-recommends \
        bison  ruby2.3 ruby2.3-dev ruby-switch \
        build-essential \
        curl \
        doxygen \
        flex \
        gettext \
        git-core \
        libgdbm-dev \
        libncurses5-dev \
        libreadline6-dev \
        libssl-dev \
        libtool \
        libyaml-dev \
        make \
        pkg-config \
        openssl \
        realpath \
        vim \
        wget \
        zlib1g-dev \
	zlibc sqlite3 libsqlite3-dev libxml2 libxml2-dev libxslt1.1 libxslt1-dev \
    && apt-get clean

ENV WORKING_DIRECTORY /osquery/
RUN gem install --verbose fpm
COPY ./osquery /osquery/osquery
RUN chown nobody:nogroup -R /osquery

WORKDIR /osquery/osquery
# Give nobody passwordless sudo so that it can run brew-install commands
RUN echo "nobody ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/nobody
RUN chmod 0440 /etc/sudoers.d/nobody

RUN mkdir -p /usr/local/osquery/ && chown nobody:nogroup -R /usr/local/osquery/
RUN mkdir -p /.cache && chown nobody:nogroup -R /.cache
RUN mkdir -p /nonexistent && chown nobody:nogroup -R /nonexistent

# distro_main is a function called during `make deps` which goes and installs a few "requirements" using apt-get install
# A few of the packages didn't exist in the ubuntu.com/old-releases.ubuntu.com package archive (git and autopoint), however
# their functionalities are available through two other packages:
#  git is not available on the "old releases" apt repository, but git-core is, and it sufficient
#  autopoint is not available on the "old releases" apt repository, but it does come bundled up inside of an older gettext package
# The distro_main function call is optional, so we can skip it by setting this flag
ENV SKIP_DISTRO_MAIN=true
RUN apt-get -y install python-pip && apt-get install -y python-jinja2 && apt-get install -y python3-jinja2 
# Run as nobody for `make deps`, since it uses linuxbrew and forbids running as root
USER nobody
RUN chmod +x -R /osquery/osquery
RUN make deps
RUN make

RUN make packages

ENTRYPOINT ["/bin/bash"]
