ARG UBI_IMAGE
ARG GO_IMAGE

FROM ${UBI_IMAGE} as ubi
FROM ${GO_IMAGE} as builder
# setup required packages
RUN set -x \
 && apk --no-cache add \
    file \
    gcc \
    git \
    linux-headers \
    make
# setup the build
ARG ARCH
ARG K3S_ROOT_VERSION
ADD https://github.com/rancher/k3s-root/releases/download/${K3S_ROOT_VERSION}/k3s-root-xtables-${ARCH}.tar /opt/xtables/k3s-root-xtables.tar
RUN tar xvf /opt/xtables/k3s-root-xtables.tar -C /opt/xtables
ARG TAG="v0.14.0"
ARG PKG="github.com/flannel-io/flannel"
ARG SRC="github.com/flannel-io/flannel"
RUN git clone --depth=1 https://${SRC}.git $GOPATH/src/${PKG}
WORKDIR $GOPATH/src/${PKG}
RUN git fetch --all --tags --prune
RUN git checkout tags/${TAG} -b ${TAG}
# build and assert statically linked executable(s)
ENV GO_LDFLAGS="-X ${PKG}/version.Version=${TAG}"
RUN go-build-static.sh -gcflags=-trimpath=${GOPATH}/src -o bin/flanneld .
RUN go-assert-static.sh bin/*
RUN go-assert-boring.sh bin/*
RUN install -s bin/* /usr/local/bin
RUN flanneld --version

FROM ubi
RUN yum install -y ca-certificates \
    strongswan net-tools which  && \
    rm -rf /var/cache/yum
COPY --from=builder /opt/xtables/bin/ /usr/sbin/
COPY --from=builder /usr/local/bin/ /opt/bin/
