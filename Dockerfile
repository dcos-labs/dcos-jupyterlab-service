# debian:9.3 - linux; amd64
# https://github.com/docker-library/repo-info/blob/master/repos/debian/tag-details.md#debian93---linux-amd64
FROM debian@sha256:02741df16aee1b81c4aaff4c48d75cc2c308bade918b22679df570c170feef7c

ARG AWS_JAVA_SDK_JAR_SHA1="650f07e69b071cbf41c32d4ea35fd6bbba8e6793"
ARG AWS_JAVA_SDK_URL="https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk"
ARG AWS_JAVA_SDK_VERSION="1.7.5"
ARG BUILD_DATE
ARG CODENAME="stretch"
ARG CONDA_DIR="/opt/conda"
ARG CONDA_ENV_YML="beakerx-root-conda-env.yml"
ARG CONDA_INSTALLER="Miniconda3-4.3.31-Linux-x86_64.sh"
ARG CONDA_MD5="7fe70b214bee1143e3e3f0467b71453c"
ARG CONDA_URL="https://repo.continuum.io/miniconda"
ARG DISTRO="debian"
ARG DCOS_COMMONS_URL="https://downloads.mesosphere.com/dcos-commons"
ARG DCOS_COMMONS_VERSION="0.40.3"
ARG DEBCONF_NONINTERACTIVE_SEEN="true"
ARG DEBIAN_FRONTEND="noninteractive"
ARG GPG_KEYSERVER="hkps://pgp.mit.edu"
ARG HADOOP_AWS_JAR_SHA1="cfb9d10d22cccdfcb98345c1861912aec86710c8"
ARG HADOOP_AWS_URL="https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws"
ARG HADOOP_AWS_VERSION="2.7.5"
ARG HADOOP_VERSION="2.7"
ARG HOME="/home/beakerx"
ARG JAVA_HOME="/opt/jdk"
ARG JAVA_URL="https://downloads.mesosphere.com/java"
ARG JAVA_VERSION="8u162"
ARG LIBMESOS_BUNDLE_SHA256="875f6500101c7b219feebe05bd8ca68ea98682f974ca7f8efc14cb52790977b0"
ARG LIBMESOS_BUNDLE_URL="https://downloads.mesosphere.com/libmesos-bundle"
ARG LIBMESOS_BUNDLE_VERSION="master-28f8827"
ARG MESOSPHERE_PREFIX="/opt/mesosphere"
ARG MESOS_JAR_SHA1="0cef8031567f2ef367e8b6424a94d518e76fb8dc"
ARG MESOS_MAVEN_URL="https://repository.apache.org/service/local/repositories/releases/content/org/apache/mesos/mesos"
ARG MESOS_PROTOBUF_JAR_SHA1="189ef74959049521be8f5a1c3de3921eb0117ffb"
ARG MESOS_VERSION="1.5.0"
ARG NB_GID="100"
ARG NB_UID="1000"
ARG NB_USER="beakerx"
ARG REPO="http://cdn-fastly.deb.debian.org"
ARG SPARK_DIST_URL="https://downloads.mesosphere.com/spark"
ARG SPARK_HOME="/opt/spark"
ARG SPARK_VERSION="2.2.1-2-beta"
ARG TINI_GPG_KEY="6380DC428747F6C393FEACA59A84159D7001A4E5"
ARG TINI_URL="https://github.com/krallin/tini/releases/download"
ARG TINI_VERSION="v0.16.1"
ARG VCS_REF
ARG VERSION

LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.name="BeakerX" \
      org.label-schema.description="BeakerX is a collection of kernels and extensions to the Jupyter interactive computing environment. It provides JVM support, interactive plots, tables, forms, publishing, and more." \
      org.label-schema.url="http://beakerx.com" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/vishnu2kmohan/beakerx-dcos-docker" \
      org.label-schema.version=$VERSION \
      org.label-schema.schema-version="1.0"

ENV BOOTSTRAP="${MESOSPHERE_PREFIX}/bin/bootstrap" \
    CODENAME=${CODENAME:-"stretch"} \
    CONDA_DIR=${CONDA_DIR:-"/opt/conda"} \
    DEBCONF_NONINTERACTIVE_SEEN=${DEBCONF_NONINTERACTIVE_SEEN:-"true"} \
    DEBIAN_FRONTEND=${DEBIAN_FRONTEND:-"noninteractive"} \
    DISTRO=${DISTRO:-"debian"} \
    GPG_KEYSERVER=${GPG_KEYSERVER:-"hkps://pgp.mit.edu"} \
    HOME="/home/$NB_USER" \
    JAVA_HOME=${JAVA_HOME:-"/opt/jdk"} \
    LANG="en_US.UTF-8" \
    LANGUAGE="en_US.UTF-8" \
    LC_ALL="en_US.UTF-8" \
    MESOSPHERE_PREFIX=${MESOSPHERE_PREFIX:-"/opt/mesosphere"} \
    MESOS_AUTHENTICATEE="com_mesosphere_dcos_ClassicRPCAuthenticatee" \
    MESOS_MODULES="{\"libraries\": [{\"file\": \"libdcos_security.so\", \"modules\": [{\"name\": \"com_mesosphere_dcos_ClassicRPCAuthenticatee\"}]}]}" \
    MESOS_NATIVE_LIBRARY="${MESOSPHERE_PREFIX}/libmesos-bundle/lib/libmesos.so" \
    MESOS_NATIVE_JAVA_LIBRARY="${MESOSPHERE_PREFIX}/libmesos-bundle/lib/libmesos.so" \
    NB_GID=${NB_GID:-"100"} \
    NB_UID=${NB_UID:-"1000"} \
    NB_USER=${NB_USER:-"beakerx"} \
    PATH="${JAVA_HOME}/bin:${SPARK_HOME}/bin:${CONDA_DIR}/bin:${MESOSPHERE_PREFIX}/bin:${PATH}" \
    SHELL="/bin/bash" \
    SPARK_HOME=${SPARK_HOME:-"/opt/spark"}

RUN echo "deb ${REPO}/${DISTRO} ${CODENAME} main" \
         >> /etc/apt/sources.list \
    echo "deb ${REPO}/${DISTRO}-security ${CODENAME}/updates main" \
         >> /etc/apt/sources.list \
    && apt-get update -yq --fix-missing \
    && apt-get install -yq --no-install-recommends locales \
    && echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
    && locale-gen \
    && apt-get install -yq --no-install-recommends apt-utils \
    && apt-get -yq dist-upgrade \
    && apt-get install -yq --no-install-recommends \
       bash-completion \
       bzip2 \
       ca-certificates \
       curl \
       dirmngr \
       fonts-dejavu \
       fonts-liberation \
       git \
       gnupg \
       jq \
       less \
       libav-tools \
       lmodern \
       openssh-client \
       procps \
       rsync \
       r-base \
       sudo \
       unzip \
       vim \
       wget \
    && apt-get clean \
    && rm -rf /var/apt/lists/* \
    && usermod -u 99 nobody \
    && addgroup --gid 99 nobody \
    && usermod -g nobody nobody \
    && echo nobody:x:65534:65534:nobody:/nonexistent:/usr/sbin/nologin >> /etc/passwd

COPY fix-permissions "/usr/local/bin/"

RUN cd /tmp \
    && apt-key adv --keyserver "$GPG_KEYSERVER" --recv-keys "$TINI_GPG_KEY" \
    && curl --retry 3 -fsSL "$TINI_URL/$TINI_VERSION/tini" -o /usr/bin/tini \
    && curl --retry 3 -fsSL -O "$TINI_URL/$TINI_VERSION/tini.asc" \
    && export GNUPGHOME="$(mktemp -d)" \
    && gpg --keyserver "$GPG_KEYSERVER" --recv-keys "$TINI_GPG_KEY" \
    && gpg --batch --verify tini.asc /usr/bin/tini \
    && rm -rf "$GNUPGHOME" tini.asc \
    && chmod +x /usr/bin/tini \
    && mkdir -p "${JAVA_HOME}" "${SPARK_HOME}" "${MESOSPHERE_PREFIX}/bin" "${CONDA_DIR}" \
    && curl --retry 3 -fsSL -O "${LIBMESOS_BUNDLE_URL}/libmesos-bundle-${LIBMESOS_BUNDLE_VERSION}.tar.gz" \
    && echo "${LIBMESOS_BUNDLE_SHA256}" "libmesos-bundle-${LIBMESOS_BUNDLE_VERSION}.tar.gz" | sha256sum -c - \
    && tar xf "libmesos-bundle-${LIBMESOS_BUNDLE_VERSION}.tar.gz" -C "${MESOSPHERE_PREFIX}" \
    && rm "libmesos-bundle-${LIBMESOS_BUNDLE_VERSION}.tar.gz" \
    && cd "${MESOSPHERE_PREFIX}/libmesos-bundle/lib" \
    && curl --retry 3 -fsSL -O "${MESOS_MAVEN_URL}/${MESOS_VERSION}/mesos-${MESOS_VERSION}.jar" \
    && echo "${MESOS_JAR_SHA1} mesos-${MESOS_VERSION}.jar" | sha1sum -c - \
    && curl --retry 3 -fsSL -O "${MESOS_MAVEN_URL}/${MESOS_VERSION}/mesos-${MESOS_VERSION}-shaded-protobuf.jar" \
    && echo "${MESOS_PROTOBUF_JAR_SHA1} mesos-${MESOS_VERSION}-shaded-protobuf.jar" | sha1sum -c - \
    && cd /tmp \
    && curl --retry 3 -fsSL -O "${DCOS_COMMONS_URL}/artifacts/${DCOS_COMMONS_VERSION}/bootstrap.zip" \
    && unzip "bootstrap.zip" -d "${MESOSPHERE_PREFIX}/bin/" \
    && curl --retry 3 -fsSL -O "${JAVA_URL}/server-jre-${JAVA_VERSION}-linux-x64.tar.gz" \
    && tar xf "server-jre-${JAVA_VERSION}-linux-x64.tar.gz" -C "${JAVA_HOME}" --strip-components=1 \
    && curl --retry 3 -fsSL -O "${SPARK_DIST_URL}/assets/spark-${SPARK_VERSION}-bin-${HADOOP_VERSION}.tgz" \
    && tar xf "spark-${SPARK_VERSION}-bin-${HADOOP_VERSION}.tgz" -C "${SPARK_HOME}" --strip-components=1 \
    && cd "${SPARK_HOME}/jars" \
    && curl --retry 3 -fsSL -O "${AWS_JAVA_SDK_URL}/${AWS_JAVA_SDK_VERSION}/aws-java-sdk-${AWS_JAVA_SDK_VERSION}.jar" \
    && echo "${AWS_JAVA_SDK_JAR_SHA1} aws-java-sdk-${AWS_JAVA_SDK_VERSION}.jar" | sha1sum -c - \
    && curl --retry 3 -fsSL -O "${HADOOP_AWS_URL}/${HADOOP_AWS_VERSION}/hadoop-aws-${HADOOP_AWS_VERSION}.jar" \
    && echo "${HADOOP_AWS_JAR_SHA1} hadoop-aws-${HADOOP_AWS_VERSION}.jar" | sha1sum -c - \
    && rm -rf /tmp/* \
    && useradd -m -N -u "$NB_UID" -g "$NB_GID" -s /bin/bash "$NB_USER" \
    && chown $NB_UID:$NB_GID $CONDA_DIR \
    && fix-permissions $MESOSPHERE_PREFIX \
    && fix-permissions $CONDA_DIR \
    && fix-permissions $HOME

COPY --chown="1000:100" "${CONDA_ENV_YML}" "${CONDA_DIR}/"

USER $NB_UID

RUN mkdir -p "$HOME/.jupyter" "$HOME/.sparkmagic" "$HOME/bin" "$HOME/work" \
    && cd /tmp \
    && curl --retry 3 -fsSL -O "$CONDA_URL/$CONDA_INSTALLER" \
    && echo "$CONDA_MD5  $CONDA_INSTALLER" | md5sum -c - \
    && bash "./$CONDA_INSTALLER" -u -b -p "$CONDA_DIR" \
    && rm -f "$CONDA_INSTALLER" \
    && $CONDA_DIR/bin/conda config --system --prepend channels conda-forge \
    && $CONDA_DIR/bin/conda config --system --set auto_update_conda false \
    && $CONDA_DIR/bin/conda config --system --set show_channel_urls true \
    && $CONDA_DIR/bin/conda update --json --all -yq \
    && $CONDA_DIR/bin/conda env update --json -q -f "${CONDA_DIR}/${CONDA_ENV_YML}" \
    && $CONDA_DIR/bin/jupyter labextension install @jupyter-widgets/jupyterlab-manager \
    && $CONDA_DIR/bin/jupyter labextension install @jupyterlab/hub-extension \
    && $CONDA_DIR/bin/jupyter labextension install @jupyterlab/geojson-extension \
    && $CONDA_DIR/bin/jupyter labextension install @jupyterlab/github \
    && $CONDA_DIR/bin/jupyter labextension install jupyterlab_bokeh \
    && $CONDA_DIR/bin/jupyter labextension install beakerx-jupyterlab \
    && $CONDA_DIR/bin/conda update --json --all -yq \
    && $CONDA_DIR/bin/npm cache clean \
    && rm -rf $CONDA_DIR/share/jupyter/lab/staging \
    && rm -rf $HOME/.cache/yarn $HOME/.node-gyp \
    && $CONDA_DIR/bin/conda clean --json -tipsy \
    && fix-permissions $CONDA_DIR \
    && fix-permissions $HOME

COPY --chown="1000:100" profile "$HOME/.profile"
COPY --chown="1000:100" bash_profile "$HOME/.bash_profile"
COPY --chown="1000:100" bashrc "$HOME/.bashrc"
COPY --chown="1000:100" dircolors "$HOME/.dircolors"
COPY --chown="1000:100" jupyter_notebook_config.py "${HOME}/.jupyter/"

USER root

EXPOSE 8888

ENTRYPOINT ["tini", "--"]

CMD ["start-notebook.sh"]

COPY start.sh /usr/local/bin/
COPY start-notebook.sh /usr/local/bin/
COPY start-singleuser.sh /usr/local/bin/
COPY jupyter_notebook_config.py /etc/jupyter/
COPY conf/ "${SPARK_HOME}/conf/"
COPY krb5.conf.mustache /etc/

RUN fix-permissions /etc/jupyter/ \
    && chmod -R ugo+rw "${SPARK_HOME}/conf" \
    && cp "${CONDA_DIR}/share/examples/krb5/krb5.conf" /etc \
    && chmod ugo+rw /etc/krb5.conf

ENV LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${MESOSPHERE_PREFIX}/libmesos-bundle/lib"

WORKDIR "$HOME"

USER $NB_UID
