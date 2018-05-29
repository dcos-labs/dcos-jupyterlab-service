```bash
dcos security org service-accounts keypair beakerx-private-key.pem beakerx-public-key.pem

dcos security org service-accounts create -p beakerx-public-key.pem -d "Dev BeakerX Service Account" dev_beakerx
dcos security org service-accounts show

dcos security secrets create-sa-secret --strict beakerx-private-key.pem dev_beakerx dev/beakerx/serviceCredential
dcos security secrets list /dev/beakerx

dcos security org users grant dev_beakerx dcos:mesos:master:task:user:nobody create --description "Allow dev_beakerx to launch tasks under the Linux user: nobody"
dcos security org users grant dev_beakerx dcos:mesos:master:framework:role:dev-beakerx create --description "Allow dev_beakerx to register with Mesos and consume resources from the dev-beakerx role"
dcos security org users grant dev_beakerx dcos:mesos:master:task:app_id:/dev/beakerx create --description "Allow dev_beakerx to create tasks under the /dev/beakerx namespace"

tee dev-beakerx-quota.json <<- 'EOF'
{
 "role": "dev-beakerx",
 "guarantee": [
   {
     "name": "cpus",
     "type": "SCALAR",
     "scalar": { "value": 4.4 }
   },
   {
     "name": "mem",
     "type": "SCALAR",
     "scalar": { "value": 9216.0 }
   }
 ]
}
EOF

curl --cacert dcos-ca.crt -fsSL -X POST -H "Authorization: token=$(dcos config show core.dcos_acs_token)" -H "Content-Type: application/json" $(dcos config show core.dcos_url)/mesos/quota -d @dev-beakerx-quota.json

spark-submit \
  --verbose \
  --name SparkPi-Client-2-2-1 \
  --master mesos://zk://zk-1.zk:2181,zk-2.zk:2181,zk-3.zk:2181,zk-4.zk:2181,zk-5.zk:2181/mesos \
  --conf spark.mesos.containerizer=mesos \
  --conf spark.mesos.principal=dev_beakerx \
  --conf spark.mesos.role=dev-beakerx \
  --conf spark.cores.max=4 \
  --conf spark.executor.cores=2 \
  --conf spark.mesos.executor.docker.image=vishnumohan/spark-dcos:tfos \
  --conf spark.executor.home=/opt/spark \
  --conf spark.mesos.driver.labels=DCOS_SPACE:/dev/beakerx \
  --conf spark.mesos.task.labels=DCOS_SPACE:/dev/beakerx \
  --conf spark.mesos.driverEnv.SPARK_MESOS_KRB5_CONF_BASE64=dmlzaG51Cg== \
  --conf spark.executorEnv.SPARK_MESOS_KRB5_CONF_BASE64=dmlzaG51Cg== \
  --conf spark.mesos.driver.secret.names=/dev/AWS_ACCESS_KEY_ID,/dev/AWS_SECRET_ACCESS_KEY \
  --conf spark.mesos.driver.secret.envkeys=AWS_ACCESS_KEY_ID,AWS_SECRET_ACCESS_KEY \
  --conf spark.mesos.executor.secret.names=/dev/AWS_ACCESS_KEY_ID,/dev/AWS_SECRET_ACCESS_KEY \
  --conf spark.mesos.executor.secret.envkeys=AWS_ACCESS_KEY_ID,AWS_SECRET_ACCESS_KEY \
  --conf spark.eventLog.enabled=true \
  --conf spark.eventLog.dir=s3a://vishnu-mohan/spark/history \
  --class org.apache.spark.examples.SparkPi \
  /opt/spark/examples/jars/spark-examples_2.11-2.2.1.jar 100
```
