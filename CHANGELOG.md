# Release: [WIP]

## Major Features and Improvements

### Package Additions

* boost
* conda-pack
* gensim
* h2oai::h2o
* ibis-framework
* numexpr
* openblas
* plotly
* pyomo
* pyomo.extras
* pyomo.solvers
* rstudio
* spacy
* typing
* pygdf
* quilt[img,pytorch,torchvision]

### Package Bumps

* dask 0.19.2
* distributed 1.23.2
* mlflow 0.7.0
* pyarrow 0.10.0
* ray[rllib] 0.5.3
* setuptools 40.4.3
* tensorflow 1.11.0
* tensorflowonspark 1.3.4
* cuDNN 7.3.1.20-1+cuda9.0
* NCCL 2.3.5-2+cuda9.0
* lua-resty-openidc.lua [4560abe](https://github.com/zmartzone/lua-resty-openidc/commit/4560abe6870a05f4c00dec333226782861dc09ca)

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
* `OIDC_REDIRECT_URI` is now an absolute URI since [redirect_uri_path is deprecated](https://github.com/zmartzone/lua-resty-openidc/commit/0f2a68b82cf4849fc3efe4b25c389fc45377fc63)
* Rename `OIDC_AUTH_METHOD` to `OIDC_TOKEN_ENDPOINT_AUTH_METHOD` to disambiguate from the Introspection Endpoint Authentication method

