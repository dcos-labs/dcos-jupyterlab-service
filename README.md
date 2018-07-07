# dcos-jupyter-service

JupyterLab Notebook Docker Image tailored for [Mesosphere DC/OS](https://dcos.io)

Docker images built with the `Dockerfile` herein will enable support for:
* [Apache Spark](https://spark.apache.org)
Apache Spark™ is a unified analytics engine for large-scale data processing.
* [BeakerX](http://beakerx.com)
BeakerX is a collection of kernels and extensions to the Jupyter interactive computing environment. It provides JVM support, Spark cluster support, polyglot programming, interactive plots, tables, forms, publishing, and more.
* [Dask](https://dask.readthedocs.io)
Dask is a flexible parallel computing library for analytic computing.
* [Distributed](https://distributed.readthedocs.io)
Dask.distributed is a lightweight library for distributed computing in Python. It extends both the concurrent.futures and dask APIs to moderate sized clusters.
* [JupyterLab](https://jupyterlab.readthedocs.io)
JupyterLab is the next-generation web-based user interface for [Project Jupyter](https://jupyter.org).
* [PyTorch](https://pytorch.org)
Tensors and Dynamic neural networks in Python with strong GPU acceleration. PyTorch is a deep learning framework for fast, flexible experimentation.
* [Ray](https://ray.readthedocs.io)
Ray is a flexible, high-performance distributed execution framework.
  * Ray Tune: Hyperparameter Optimization Framework
  * Ray RLlib: Scalable Reinforcement Learning
* [Tensorflow](https://www.tensorflow.org)
TensorFlow™ is an open source software library for high performance numerical computation.
* [TensorFlowOnSpark](https://github.com/yahoo/TensorFlowOnSpark)
TensorFlowOnSpark brings TensorFlow programs onto Apache Spark clusters.
* [XGBoost](https://xgboost.ai)
Scalable, Portable and Distributed Gradient Boosting (GBDT, GBRT or GBM) Library, for Python, R, Java, Scala, C++ and more.

Also includes support for:
* OpenID Connect Authentication and Authorization based on email address or User Principal Name (UPN) (for Windows Integrated Authentication and AD FS 4.0 with Windows Server 2016)
* HDFS connectivity
* S3 connectivity
* GPUs with the `<image>:<tag>-gpu` Docker Image variant built from `Dockerfile-cuDNN`

Pre-built JupyterLab Docker Images for Mesosphere DC/OS: https://hub.docker.com/r/dcoslabs/dcos-jupyter/tags/

Related Docker Images:
* Machine Learning Worker on Mesosphere DC/OS: https://hub.docker.com/r/dcoslabs/dcos-ml-worker/tags/
* Apache Spark (with GPU support) on Mesosphere DC/OS: https://hub.docker.com/r/dcoslabs/dcos-spark/tags/

Built `FROM:` [debian:jessie](https://hub.docker.com/r/library/debian) with [Miniconda3](https://repo.continuum.io/miniconda/)

Made possible by and/or for:
* [Mesosphere DC/OS](https://dcos.io)
* [Mesosphere DC/OS Enterprise](https://mesosphere.com/product)
* [Conda](https://conda.io)
* [Anaconda](https://www.anaconda.com)
* [Debian](https://www.debian.org)
