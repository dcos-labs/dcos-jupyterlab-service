# Release: 1.3.0-0.35.2

## Major Features and Improvements

### Package Additions

* boost
* conda-pack
* gensim
* h2oai::h2o
* ibis-framework
* nbdime
* nbserverproxy
* numexpr
* openblas
* plotly
* pyomo
* pyomo.extras
* pyomo.solvers
* r-caret
* r-devtools
* r-forecast
* r-nycflights13
* r-plotly
* r-randomforest
* r-sqlite
* r-shiny
* r-sparklyr
* r-tidyverse
* s3cmd
* typing
* pygdf
* quilt[img,pytorch,torchvision]

### Package Bumps

* dask 0.19.4
* distributed 1.23.3
* jupyterlab 0.35.2
* mlflow 0.7.0
* pyarrow 0.11.0
* ray[rllib] 0.5.3
* setuptools 40.4.3
* tensorflow 1.11.0
* tensorflowonspark 1.3.4
* toree 0.3.0-incubating-rc1

### Jupyter Extensions Additions

* [@jupyterlab/celltags](https://github.com/jupyterlab/jupyterlab-celltags)
* [dask-labextension](https://github.com/dask/dask-labextension)
* [jupyterlab/git](https://github.com/jupyterlab/jupyterlab-git)
* [jupyterlab-drawio](https://github.com/QuantStack/jupyterlab-drawio)
* [jupyterlab_iframe](jupyterlab_iframe)
* [nbdime-jupyterlab](https://github.com/jupyter/nbdime)
* [nbserverproxy](https://github.com/jupyterhub/nbserverproxy)
* [qgrid](https://github.com/quantopian/qgrid)

### NVIDIA Library Bumps

* cuDNN 7.3.1.20-1+cuda9.0
* NCCL 2.3.5-2+cuda9.0

### Miscellaneous Bumps

* zmartzone/lua-resty-openidc [8dfd8c7](https://github.com/zmartzone/lua-resty-openidc/commit/8dfd8c790cfd5af3af0b8a0cdf705baf568ef3ae)

### OpenID Connect

* Added support for specifying:
  * Authorization Parameters
  * Redirect After Logout URI
  * Redirect After Logout With ID Token Hint (default: `true`)
  * Refresh Session Interval (default: `3300` seconds)
  * Whether to renew Access Token on Expiry (default: `true`)

## Breaking Changes

### Configuration

* [Moved `start_spark_history_server` into spark config section](https://github.com/dcos-labs/dcos-jupyterlab-service/pull/4)
* The `OIDC_REDIRECT_URI` environment variable must now be specified as an absolute URI since [redirect_uri_path is deprecated](https://github.com/zmartzone/lua-resty-openidc/commit/0f2a68b82cf4849fc3efe4b25c389fc45377fc63)
* Rename the `OIDC_AUTH_METHOD` environment variable to `OIDC_TOKEN_ENDPOINT_AUTH_METHOD` to disambiguate from the Introspection Endpoint Authentication method

### Features

* Apache Toree, as of [0.3.0-incubating-rc1](https://github.com/apache/incubator-toree/releases/tag/v0.3.0-incubating-rc1) has [removed support for PySpark and SparkR](https://github.com/apache/incubator-toree/commit/276165ae2ac136a59d208058a031caf769bb312e), only the Scala and SQL interpreters will remain available. The [vanilla PySpark and SparkR kernels, however retain their ability to launch pre-configured Spark Jobs](https://github.com/dcos-labs/dcos-jupyterlab-service/blob/master/jupyter_notebook_config.py#L231-L232)
