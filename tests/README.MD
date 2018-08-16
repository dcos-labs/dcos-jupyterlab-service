## Basic Testing Demo
This is intended as an example for integration tests.

It includes tests for:

* Checking ELB availability
* Checking Marathon-LB availability
* Checking Login
* Checking JupyterLab functionality

There is a multiverse of modifications and tests that can be run this way. E.g. testing different service verions, where
TensorBoard is enabled and test endpoints or even run entire Jupyter Notebooks from our notebook repos and see if demos
are broken or not.

## How to run

You can run it locally to test your current developed DC/OS JupyterLab Service or - and this is more the idea behind
this exercise - this is being ran as an integration tests for all new releases.

### Locally

Simply by pointing to your current ELB vHost:

Example:
```bash
python tests --vhost fabianbaie-tf494c-pub-agt-elb-732556684.us-west-2.elb.amazonaws.com
```

### As Integrationtest

In the `test` stage this can be simply run by providing the vhost in a `ENV_VARIABLE`. (After a DC/OS Cluster was fully
deployed, Marathon-LB and JupyterLab services installed - with e.g. a testpw differing from the default)

Section in Jenkinsfile:

```bash
  stage 'Test'
  echo "Test DC/OS JupyterLab Service"
  python tests --vhost $DCOS_VHOST
```