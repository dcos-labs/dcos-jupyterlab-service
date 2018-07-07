# dcos-jupyter-service

JupyterLab Notebook Docker Image tailored for [Mesosphere DC/OS](https://dcos.io)

Docker images built with the `Dockerfile` herein will enable support for:
* [JupyterLab](https://jupyterlab.readthedocs.io)
* [BeakerX](http://beakerx.com)
BeakerX is a collection of kernels and extensions to the Jupyter interactive computing environment. It provides JVM support, Spark cluster support, polyglot programming, interactive plots, tables, forms, publishing, and more.
* [Tensorflow](https://www.tensorflow.org)
* [Apache Spark](https://spark.apache.org)
* [TensorFlowOnSpark](https://github.com/yahoo/TensorFlowOnSpark)
* [Ray](https://ray.readthedocs.io)
Ray is a flexible, high-performance distributed execution framework.
Ray Tune: Hyperparameter Optimization Framework
Ray RLlib: Scalable Reinforcement Learning
* [Dask](https://dask.readthedocs.io)
Dask is a flexible parallel computing library for analytic computing.
* [Distributed](https://distributed.readthedocs.io)
Dask.distributed is a lightweight library for distributed computing in Python. It extends both the concurrent.futures and dask APIs to moderate sized clusters.
* [XGBoost](https://xgboost.ai)
Scalable, Portable and Distributed Gradient Boosting (GBDT, GBRT or GBM) Library, for Python, R, Java, Scala, C++ and more. Runs on single machine, Hadoop, Spark, Flink and DataFlow

Also includes support for:
* OpenID Connect Authentication and Authorization based on email address or User Principal Name (UPN) (for Windows Integrated Authentication and AD FS 4.0 with Windows Server 2016)
* HDFS connectivity
* S3 connectivity
* GPUs with the `<image>:<tag>-gpu` Docker Image variant built from `Dockerfile-cuDNN`

Pre-built JupyterLab Docker Images for Mesosphere DC/OS: https://hub.docker.com/r/dcoslabs/dcos-jupyter/tags/

Related Docker Images:
- Machine Learning Worker on Mesosphere DC/OS https://hub.docker.com/r/dcoslabs/dcos-ml-worker/tags/
- Apache Spark (with GPU support) on Mesosphere DC/OS: https://hub.docker.com/r/dcoslabs/dcos-spark/tags/

Built `FROM:` [debian:jessie](https://hub.docker.com/r/library/debian) with [Miniconda3](https://repo.continuum.io/miniconda/)

Made possible by and/or for:
- [Mesosphere DC/OS](https://dcos.io)
- [Mesosphere DC/OS Enterprise](https://mesosphere.com/product)
- [Conda](https://conda.io)
- [Anaconda](https://www.anaconda.com)
- [Debian](https://www.debian.org)
