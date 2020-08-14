FROM jenkins/jnlp-slave:alpine
USER root

ENV HELM_VERSION 3.3.0
ENV JENKINS_MASTER http://localhost:8080
ENV JENKINS_SLAVE_NAME helm3-node
ENV JENKINS_SLAVE_SECRET ""
ENV YAMLLINT_VERSION 1.24.2

RUN apk add --no-cache \
        curl \
        wget \
        gawk \
        make \
        py3-pip \
    && set -eux; \
        \
        apkArch="$(apk --print-arch)"; \
        case "$apkArch" in \
            x86_64) dockerArch='amd64' ;; \
            armhf) dockerArch='arm' ;; \
            aarch64) dockerArch='arm64' ;; \
            ppc64le) dockerArch='ppc64le' ;; \
            s390x) dockerArch='s390x' ;; \
            *) echo >&2 "error: unsupported architecture ($apkArch)"; exit 1 ;;\
        esac; \
        if ! wget -O helm3.tgz "https://get.helm.sh/helm-v${HELM_VERSION}-linux-${dockerArch}.tar.gz"; then \
            echo >&2 "error: failed to download 'helm-v${HELM_VERSION}' from 'https://get.helm.sh/' for '${dockerArch}'"; \
            exit 1; \
        fi; \
        \
        tar --extract \
            --file helm3.tgz \
            --strip-components 1 \
            --directory /usr/local/bin/ \
        ; \
        rm helm3.tgz; \
        helm version; \
        pip3 install yamllint=="${YAMLLINT_VERSION}";

USER jenkins
RUN helm plugin install https://github.com/chartmuseum/helm-push \
    && helm plugin install --version master https://github.com/sonatype-nexus-community/helm-nexus-push.git
