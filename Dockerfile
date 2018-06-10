# debian:9.4 - linux; amd64
# https://github.com/docker-library/repo-info/blob/master/repos/debian/tag-details.md#debian94---linux-amd64
FROM debian@sha256:316ebb92ca66bb8ddc79249fb29872bece4be384cb61b5344fac4e84ca4ed2b2

ARG AWS_JAVA_SDK_JAR_SHA1="650f07e69b071cbf41c32d4ea35fd6bbba8e6793"
ARG AWS_JAVA_SDK_URL="https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk"
ARG AWS_JAVA_SDK_VERSION="1.7.5"
ARG BEAKERX_DCOS_VERSION="0.17.1-1.11.2"
ARG BUILD_DATE
ARG CODENAME="stretch"
ARG CONDA_DIR="/opt/conda"
ARG CONDA_ENV_YML="beakerx-root-conda-base-env.yml"
ARG CONDA_INSTALLER="Miniconda3-4.5.1-Linux-x86_64.sh"
ARG CONDA_MD5="0c28787e3126238df24c5d4858bd0744"
ARG CONDA_URL="https://repo.continuum.io/miniconda"
ARG DCOS_CLI_URL="https://downloads.dcos.io/binaries/cli/linux/x86-64"
ARG DCOS_CLI_VERSION="1.11"
ARG DCOS_COMMONS_URL="https://downloads.mesosphere.com/dcos-commons"
ARG DCOS_COMMONS_VERSION="0.42.1"
ARG DISTRO="debian"
ARG DEBCONF_NONINTERACTIVE_SEEN="true"
ARG DEBIAN_FRONTEND="noninteractive"
ARG GPG_KEYSERVER="hkps://zimmermann.mayfirst.org"
ARG HADOOP_AWS_JAR_SHA1="d997f4cf765ca360b69c8bbcaab8785e7c37a55d"
ARG HADOOP_AWS_URL="https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws"
ARG HADOOP_AWS_VERSION="2.7.6"
ARG HADOOP_HDFS_HOME="/opt/hadoop"
ARG HADOOP_MAJOR_VERSION="2.7"
ARG HADOOP_SHA256="f2327ea93f4bc5a5d7150dee8e0ede196d3a77ff8526a7dd05a48a09aae25669"
ARG HADOOP_URL="http://www-us.apache.org/dist/hadoop/common"
ARG HADOOP_VERSION="2.7.6"
ARG HOME="/home/beakerx"
ARG JAVA_HOME="/opt/jdk"
ARG JAVA_URL="https://downloads.mesosphere.com/java"
ARG JAVA_VERSION="8u172"
ARG LANG="en_US.UTF-8"
ARG LANGUAGE="en_US.UTF-8"
ARG LC_ALL="en_US.UTF-8"
ARG LIBMESOS_BUNDLE_SHA256="bd4a785393f0477da7f012bf9624aa7dd65aa243c94d38ffe94adaa10de30274"
ARG LIBMESOS_BUNDLE_URL="https://downloads.mesosphere.com/libmesos-bundle"
ARG LIBMESOS_BUNDLE_VERSION="1.11.0"
ARG MESOSPHERE_PREFIX="/opt/mesosphere"
ARG MESOS_JAR_SHA1="0cef8031567f2ef367e8b6424a94d518e76fb8dc"
ARG MESOS_MAVEN_URL="https://repo1.maven.org/maven2/org/apache/mesos/mesos"
ARG MESOS_PROTOBUF_JAR_SHA1="189ef74959049521be8f5a1c3de3921eb0117ffb"
ARG MESOS_VERSION="1.5.0"
ARG NB_GID="100"
ARG NB_UID="1000"
ARG NB_USER="beakerx"
ARG REPO="http://cdn-fastly.deb.debian.org"
ARG SPARK_DIST_URL="https://downloads.mesosphere.com/spark"
ARG SPARK_HOME="/opt/spark"
ARG SPARK_VERSION="2.2.1-2"
ARG TENSORFLOW_ECO_URL="https://s3.amazonaws.com/vishnu-mohan/tensorflow"
ARG TENSORFLOW_HADOOP_JAR_SHA256="6a0399f315d79ed5f12546a3cced0968067486268af5c8b12389ebac5449118c"
ARG TENSORFLOW_SPARK_JAR_SHA256="5b45a37b2b401528a51ef19247a304009d5c94cf210fb319c597bf331a798246"
ARG TENSORFLOW_JAR_SHA256="4b6a9d76ea853db41532275a3608d2d1b5abc1c16609cf8b9ebfffef7c3036fc"
ARG TENSORFLOW_JNI_SHA256="894d39d8e1d8d1329ea7153f8624657d27619c5db1d9535ab6b66296e3e6ee45"
ARG TENSORFLOW_SERVING_APT_URL="http://storage.googleapis.com/tensorflow-serving-apt"
ARG TENSORFLOW_SERVING_VERSION="1.5.0"
ARG TENSORFLOW_URL="https://storage.googleapis.com/tensorflow"
ARG TENSORFLOW_VARIANT="cpu"
ARG TENSORFLOW_VERSION="1.8.0"
ARG TINI_GPG_KEY="595E85A6B1B4779EA4DAAEC70B588DFF0527A9B7"
ARG TINI_URL="https://github.com/krallin/tini/releases/download"
ARG TINI_VERSION="v0.18.0"
ARG VCS_REF
ARG XGBOOST_JAVA_JAR_SHA256="4a6599ee3f1bd10d984e8b03747d5bc3cb637aeb791474178de2c285857bf69e"
ARG XGBOOST_SPARK_JAR_SHA256="cd31fb96b26fee197e126215949bc4f5c9a3cafd7ff157ab0037a63777c2935e"
ARG XGBOOST_URL="https://s3.amazonaws.com/vishnu-mohan/xgboost"
ARG XGBOOST_VERSION="0.71"

LABEL maintainer="Vishnu Mohan <vishnu@mesosphere.com>" \
      org.label-schema.build-date="${BUILD_DATE}" \
      org.label-schema.name="BeakerX" \
      org.label-schema.description="BeakerX is a collection of kernels and extensions to the Jupyter interactive computing environment. It provides JVM support, interactive plots, tables, forms, publishing, and more." \
      org.label-schema.url="http://beakerx.com" \
      org.label-schema.vcs-ref="${VCS_REF}" \
      org.label-schema.vcs-url="https://github.com/vishnu2kmohan/beakerx-dcos-docker" \
      org.label-schema.version="${BEAKERX_DCOS_VERSION}" \
      org.label-schema.schema-version="1.0"

ENV BOOTSTRAP="${MESOSPHERE_PREFIX}/bin/bootstrap" \
    CODENAME=${CODENAME:-"stretch"} \
    CONDA_DIR=${CONDA_DIR:-"/opt/conda"} \
    DEBCONF_NONINTERACTIVE_SEEN=${DEBCONF_NONINTERACTIVE_SEEN:-"true"} \
    DEBIAN_FRONTEND=${DEBIAN_FRONTEND:-"noninteractive"} \
    DISTRO=${DISTRO:-"debian"} \
    GPG_KEYSERVER=${GPG_KEYSERVER:-"hkps://zimmermann.mayfirst.org"} \
    HADOOP_HDFS_HOME=${HADOOP_HDFS_HOME:-"/opt/hadoop"} \
    HOME="/home/$NB_USER" \
    JAVA_HOME=${JAVA_HOME:-"/opt/jdk"} \
    LANG=${LANG:-"en_US.UTF-8"} \
    LANGUAGE=${LANGUAGE:-"en_US.UTF-8"} \
    LC_ALL=${LC_ALL:-"en_US.UTF-8"} \
    MESOSPHERE_PREFIX=${MESOSPHERE_PREFIX:-"/opt/mesosphere"} \
    MESOS_AUTHENTICATEE="com_mesosphere_dcos_ClassicRPCAuthenticatee" \
    MESOS_HTTP_AUTHENTICATEE="com_mesosphere_dcos_http_Authenticatee" \
    MESOS_MODULES="{\"libraries\": [{\"file\": \"libdcos_security.so\", \"modules\": [{\"name\": \"com_mesosphere_dcos_ClassicRPCAuthenticatee\"}]}]}" \
    MESOS_NATIVE_LIBRARY="${MESOSPHERE_PREFIX}/libmesos-bundle/lib/libmesos.so" \
    MESOS_NATIVE_JAVA_LIBRARY="${MESOSPHERE_PREFIX}/libmesos-bundle/lib/libmesos.so" \
    NB_GID=${NB_GID:-"100"} \
    NB_UID=${NB_UID:-"1000"} \
    NB_USER=${NB_USER:-"beakerx"} \
    PATH="${JAVA_HOME}/bin:${SPARK_HOME}/bin:${HADOOP_HDFS_HOME}/bin:${CONDA_DIR}/bin:${MESOSPHERE_PREFIX}/bin:${PATH}" \
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
       dnsutils \
       ffmpeg \
       fonts-dejavu \
       fonts-liberation \
       git \
       gnupg \
       info \
       jq \
       kstart \
       less \
       lmodern \
       man \
       netcat \
       openssh-client \
       procps \
       psmisc \
       rsync \
       r-base \
       sudo \
       sssd \
       unzip \
       vim \
       wget \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && addgroup --gid 99 nobody \
    && usermod -u 99 -g 99 nobody \
    && echo "nobody:x:65534:65534:nobody:/nonexistent:/usr/sbin/nologin" >> /etc/passwd \
    && usermod -a -G users nobody

COPY fix-permissions /usr/local/bin/

RUN cd /tmp \
    && apt-key adv --keyserver "${GPG_KEYSERVER}" --recv-keys "${TINI_GPG_KEY}" \
    && curl --retry 3 -fsSL "${TINI_URL}/${TINI_VERSION}/tini" -o /usr/bin/tini \
    && curl --retry 3 -fsSL -O "${TINI_URL}/${TINI_VERSION}/tini.asc" \
    && export GNUPGHOME="$(mktemp -d)" \
    && gpg --keyserver "${GPG_KEYSERVER}" --recv-keys "${TINI_GPG_KEY}" \
    && gpg --batch --verify tini.asc /usr/bin/tini \
    && rm -rf "${GNUPGHOME}" tini.asc \
    && chmod +x /usr/bin/tini \
    && mkdir -p "${CONDA_DIR}" "${HADOOP_HDFS_HOME}" "${JAVA_HOME}" "${MESOSPHERE_PREFIX}/bin" "${SPARK_HOME}" \
    && curl --retry 3 -fsSL -O "${LIBMESOS_BUNDLE_URL}/libmesos-bundle-${LIBMESOS_BUNDLE_VERSION}.tar.gz" \
    && echo "${LIBMESOS_BUNDLE_SHA256}" "libmesos-bundle-${LIBMESOS_BUNDLE_VERSION}.tar.gz" | sha256sum -c - \
    && tar xf "libmesos-bundle-${LIBMESOS_BUNDLE_VERSION}.tar.gz" -C "${MESOSPHERE_PREFIX}" \
    && cd "${MESOSPHERE_PREFIX}/libmesos-bundle/lib" \
    && curl --retry 3 -fsSL -O "${MESOS_MAVEN_URL}/${MESOS_VERSION}/mesos-${MESOS_VERSION}.jar" \
    && echo "${MESOS_JAR_SHA1} mesos-${MESOS_VERSION}.jar" | sha1sum -c - \
    && curl --retry 3 -fsSL -O "${MESOS_MAVEN_URL}/${MESOS_VERSION}/mesos-${MESOS_VERSION}-shaded-protobuf.jar" \
    && echo "${MESOS_PROTOBUF_JAR_SHA1} mesos-${MESOS_VERSION}-shaded-protobuf.jar" | sha1sum -c - \
    && cd /tmp \
    && curl --retry 3 -fsSL -O "${DCOS_COMMONS_URL}/artifacts/${DCOS_COMMONS_VERSION}/bootstrap.zip" \
    && unzip "bootstrap.zip" -d "${MESOSPHERE_PREFIX}/bin/" \
    && curl --retry 3 -fsSL "${DCOS_CLI_URL}/dcos-${DCOS_CLI_VERSION}/dcos" -o ${MESOSPHERE_PREFIX}/bin/dcos \
    && chmod +x ${MESOSPHERE_PREFIX}/bin/dcos \
    && curl --retry 3 -fsSL -O "${JAVA_URL}/server-jre-${JAVA_VERSION}-linux-x64.tar.gz" \
    && tar xf "server-jre-${JAVA_VERSION}-linux-x64.tar.gz" -C "${JAVA_HOME}" --strip-components=1 \
    && curl --retry 3 -fsSL -O "${HADOOP_URL}/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz" \
    && echo "${HADOOP_SHA256}" "hadoop-${HADOOP_VERSION}.tar.gz" | sha256sum -c - \
    && tar xf "hadoop-${HADOOP_VERSION}.tar.gz" -C "${HADOOP_HDFS_HOME}" --strip-components=1 \
    && curl --retry 3 -fsSL -O "${SPARK_DIST_URL}/assets/spark-${SPARK_VERSION}-bin-${HADOOP_MAJOR_VERSION}.tgz" \
    && tar xf "spark-${SPARK_VERSION}-bin-${HADOOP_MAJOR_VERSION}.tgz" -C "${SPARK_HOME}" --strip-components=1 \
    && cd "${SPARK_HOME}/jars" \
    && curl --retry 3 -fsSL -O "${AWS_JAVA_SDK_URL}/${AWS_JAVA_SDK_VERSION}/aws-java-sdk-${AWS_JAVA_SDK_VERSION}.jar" \
    && echo "${AWS_JAVA_SDK_JAR_SHA1} aws-java-sdk-${AWS_JAVA_SDK_VERSION}.jar" | sha1sum -c - \
    && curl --retry 3 -fsSL -O "${HADOOP_AWS_URL}/${HADOOP_AWS_VERSION}/hadoop-aws-${HADOOP_AWS_VERSION}.jar" \
    && echo "${HADOOP_AWS_JAR_SHA1} hadoop-aws-${HADOOP_AWS_VERSION}.jar" | sha1sum -c - \
    && curl --retry 3 -fsSL -O "${XGBOOST_URL}/${XGBOOST_VERSION}/xgboost4j-${XGBOOST_VERSION}.jar" \
    && echo "${XGBOOST_JAVA_JAR_SHA256}" "xgboost4j-${XGBOOST_VERSION}.jar" | sha256sum -c - \
    && curl --retry 3 -fsSL -O "${XGBOOST_URL}/${XGBOOST_VERSION}/xgboost4j-spark-${XGBOOST_VERSION}.jar" \
    && echo "${XGBOOST_SPARK_JAR_SHA256}" "xgboost4j-spark-${XGBOOST_VERSION}.jar" | sha256sum -c - \
    && curl --retry 3 -fsSL -O "${TENSORFLOW_URL}/libtensorflow/libtensorflow-${TENSORFLOW_VERSION}.jar" \
    && echo "${TENSORFLOW_JAR_SHA256}" "libtensorflow-${TENSORFLOW_VERSION}.jar" | sha256sum -c - \
    && curl --retry 3 -fsSL -O "${TENSORFLOW_ECO_URL}/${TENSORFLOW_VERSION}/tensorflow-hadoop-${TENSORFLOW_VERSION}.jar" \
    && echo "${TENSORFLOW_HADOOP_JAR_SHA256}" "tensorflow-hadoop-${TENSORFLOW_VERSION}.jar" | sha256sum -c - \
    && curl --retry 3 -fsSL -O "${TENSORFLOW_ECO_URL}/${TENSORFLOW_VERSION}/spark-tensorflow-connector_2.11-${TENSORFLOW_VERSION}.jar" \
    && echo "${TENSORFLOW_SPARK_JAR_SHA256}" "spark-tensorflow-connector_2.11-${TENSORFLOW_VERSION}.jar" | sha256sum -c - \
    && cd /tmp \
    && curl --retry 3 -fsSL -O "${TENSORFLOW_URL}/libtensorflow/libtensorflow_jni-${TENSORFLOW_VARIANT}-linux-x86_64-${TENSORFLOW_VERSION}.tar.gz" \
    && echo "${TENSORFLOW_JNI_SHA256}" "libtensorflow_jni-${TENSORFLOW_VARIANT}-linux-x86_64-${TENSORFLOW_VERSION}.tar.gz" | sha256sum -c - \
    && tar xf "libtensorflow_jni-${TENSORFLOW_VARIANT}-linux-x86_64-${TENSORFLOW_VERSION}.tar.gz" "./libtensorflow_jni.so" \
    && mv "libtensorflow_jni.so" "/usr/lib" \
    && rm -rf /tmp/* \
    && groupadd wheel -g 11 \
    && echo "auth required pam_wheel.so use_uid" >> /etc/pam.d/su \
    && useradd -m -N -u "${NB_UID}" -g "${NB_GID}" -s /bin/bash "${NB_USER}" \
    && usermod -a -G 99,65534 "${NB_USER}" \
    && chown "${NB_UID}:${NB_GID}" "${CONDA_DIR}" \
    && chmod g+w /etc/passwd \
    && fix-permissions "${CONDA_DIR}" \
    && fix-permissions "${HOME}"

RUN echo "deb [arch=amd64] ${TENSORFLOW_SERVING_APT_URL} stable tensorflow-model-server tensorflow-model-server-universal" > /etc/apt/sources.list.d/tensorflow-serving.list \
    && curl --retry 3 -fsSL ${TENSORFLOW_SERVING_APT_URL}/tensorflow-serving.release.pub.gpg | apt-key add - \
    && apt-get update \
    && TENSORFLOW_SERVING_DEB="$(mktemp)" \
    && curl --retry 3 -fsSL "${TENSORFLOW_SERVING_APT_URL}/pool/tensorflow-model-server-${TENSORFLOW_SERVING_VERSION}/t/tensorflow-model-server/tensorflow-model-server_${TENSORFLOW_SERVING_VERSION}_all.deb" -o "${TENSORFLOW_SERVING_DEB}"\
    && dpkg -i "${TENSORFLOW_SERVING_DEB}" \
    && rm -f "${TENSORFLOW_SERVING_DEB}" \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY --chown="1000:100" "${CONDA_ENV_YML}" "${CONDA_DIR}/"

USER $NB_UID

RUN cd /tmp \
    && curl --retry 3 -fsSL -O "${CONDA_URL}/${CONDA_INSTALLER}" \
    && echo "${CONDA_MD5}  ${CONDA_INSTALLER}" | md5sum -c - \
    && bash "./${CONDA_INSTALLER}" -u -b -p "${CONDA_DIR}" \
    && ${CONDA_DIR}/bin/conda config --system --prepend channels conda-forge \
    && ${CONDA_DIR}/bin/conda config --system --set auto_update_conda false \
    && ${CONDA_DIR}/bin/conda config --system --set show_channel_urls true \
    && ${CONDA_DIR}/bin/conda update --json --all -yq \
    && ${CONDA_DIR}/bin/pip install --upgrade pip \
    && ${CONDA_DIR}/bin/conda env update --json -q -f "${CONDA_DIR}/${CONDA_ENV_YML}" \
    && ${CONDA_DIR}/bin/jupyter toree install --sys-prefix --interpreters=Scala,PySpark,SparkR,SQL \
    && ${CONDA_DIR}/bin/jupyter labextension install @jupyter-widgets/jupyterlab-manager \
    && ${CONDA_DIR}/bin/jupyter labextension install @jupyterlab/hub-extension \
    && ${CONDA_DIR}/bin/jupyter labextension install @jupyterlab/geojson-extension \
    && ${CONDA_DIR}/bin/jupyter labextension install @jupyterlab/github \
    && ${CONDA_DIR}/bin/jupyter labextension install jupyterlab_bokeh \
    && ${CONDA_DIR}/bin/jupyter labextension install beakerx-jupyterlab@0.19.0 \
    && ${CONDA_DIR}/bin/conda remove --force --json -yq openjdk \
    && ${CONDA_DIR}/bin/npm cache clean --force \
    && rm -rf "${CONDA_DIR}/share/jupyter/lab/staging" \
    && rm -rf "${HOME}/.cache/pip" "${HOME}/.cache/yarn" "${HOME}/.node-gyp" \
    && ${CONDA_DIR}/bin/conda clean --json -tipsy \
    && for dir in .conda/envs .jupyter .local/share/jupyter/runtime .sparkmagic bin work; \
       do mkdir -p "${HOME}/${dir}"; done \
    && fix-permissions "${CONDA_DIR}" \
    && fix-permissions "${HOME}" \
    && rm -rf /tmp/*

COPY --chown="1000:100" profile "${HOME}/.profile"
COPY --chown="1000:100" bash_profile "${HOME}/.bash_profile"
COPY --chown="1000:100" bashrc "${HOME}/.bashrc"
COPY --chown="1000:100" dircolors "${HOME}/.dircolors"
COPY --chown="1000:100" jupyter_notebook_config.py "${HOME}/.jupyter/"

USER root
EXPOSE 8888
ENTRYPOINT ["tini", "-g", "--"]
CMD ["start-notebook.sh"]

COPY start.sh /usr/local/bin/
COPY start-notebook.sh /usr/local/bin/
COPY start-singleuser.sh /usr/local/bin/
COPY jupyter_notebook_config.py /etc/jupyter/
COPY conf/ "${SPARK_HOME}/conf/"
COPY krb5.conf.mustache /etc/

RUN mkdir -p /usr/local/bin/start-notebook.d \
    && fix-permissions /etc/jupyter/ \
    && chmod -R ugo+rw "${SPARK_HOME}/conf" \
    && cp "${CONDA_DIR}/share/examples/krb5/krb5.conf" /etc \
    && chmod ugo+rw /etc/krb5.conf \
    && mv /usr/lib/x86_64-linux-gnu/libcurl.so.4.4.0 /usr/lib/x86_64-linux-gnu/libcurl.so.4.4.0.bak \
    && cp "${MESOSPHERE_PREFIX}/libmesos-bundle/lib/libcurl.so.4" /usr/lib/x86_64-linux-gnu/libcurl.so.4.4.0

ENV PYTHONPATH="${SPARK_HOME}/python:${SPARK_HOME}/python/lib/py4j-0.10.4-src.zip:${PYTHONPATH}" \
    LD_LIBRARY_PATH="/usr/lib/x86_64-linux-gnu:${MESOSPHERE_PREFIX}/libmesos-bundle/lib:${JAVA_HOME}/jre/lib/amd64/server"
WORKDIR "${HOME}"
USER "${NB_UID}"
