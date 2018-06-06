# Setup Service Account for BeakerX

```bash
dcos security org service-accounts keypair beakerx-private-key.pem beakerx-public-key.pem

dcos security org service-accounts create -p beakerx-public-key.pem -d "Dev BeakerX Service Account" dev_beakerx
dcos security secrets create-sa-secret --strict beakerx-private-key.pem dev_beakerx dev/beakerx/serviceCredential
dcos security org users grant dev_beakerx dcos:mesos:master:task:user:nobody create --description "Allow dev_beakerx to launch tasks under the Linux user: nobody"
dcos security org users grant dev_beakerx dcos:mesos:master:framework:role:dev-beakerx create --description "Allow dev_beakerx to register with Mesos and consume resources from the dev-beakerx role"
dcos security org users grant dev_beakerx dcos:mesos:master:task:app_id:/dev/beakerx create --description "Allow dev_beakerx to create tasks under the /dev/beakerx namespace"
```

# (Optional) Setup Quota for BeakerX
```bash
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
```

# Submit a SparkPi Job
```bash
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

# Prepare MNIST Dataset with Tensorflow on Spark

## Retrieve and extract raw MNIST Dataset

```bash
cd $MESOS_SANDBOX
curl -O https://s3.amazonaws.com/vishnu-mohan/tensorflow/mnist/mnist.zip
unzip mnist.zip
```

## Prepare MNIST Dataset in CSV format and store on S3

### Remove existing csv folder in S3 bucket (if present)
```bash
aws s3 rm --recursive s3://vishnu-mohan/tensorflow/mnist/csv 
```

### Prepare in CSV for S3
```bash
spark-submit \
  --verbose \
  --name MNIST-CSV-S3 \
  --master mesos://zk://zk-1.zk:2181,zk-2.zk:2181,zk-3.zk:2181,zk-4.zk:2181,zk-5.zk:2181/mesos \
  --conf spark.mesos.containerizer=mesos \
  --conf spark.mesos.principal=dev_beakerx \
  --conf spark.mesos.role=dev-beakerx \
  --conf spark.cores.max=4 \
  --conf spark.executor.cores=2 \
  --conf spark.mesos.executor.docker.image=vishnumohan/spark-dcos:tfos \
  --conf spark.executor.home=/opt/spark \
  --conf spark.mesos.driver.labels=DCOS_SPACE:/dev/beakerx \
  --conf spark.mesos.driverEnv.SPARK_MESOS_KRB5_CONF_BASE64=dmlzaG51Cg== \
  --conf spark.executorEnv.SPARK_MESOS_KRB5_CONF_BASE64=dmlzaG51Cg== \
  --conf spark.mesos.driver.secret.names=/dev/AWS_ACCESS_KEY_ID,/dev/AWS_SECRET_ACCESS_KEY \
  --conf spark.mesos.driver.secret.envkeys=AWS_ACCESS_KEY_ID,AWS_SECRET_ACCESS_KEY \
  --conf spark.eventLog.enabled=true \
  --conf spark.eventLog.dir=s3a://vishnu-mohan/spark/history \
  $(pwd)/TensorFlowOnSpark/examples/mnist/mnist_data_setup.py \
    --output s3a://vishnu-mohan/tensorflow/mnist/csv \
    --format csv
```

### List prepared CSV files on S3
```bash
aws s3 ls --recursive s3://vishnu-mohan/tensorflow/mnist/csv
```

## Prepare MNIST Dataset in CSV format and store on HDFS (under hdfs://user/${USER}/mnist/csv)

### Remove existing folder (if present)
```bash
hdfs dfs -rm -R -skipTrash mnist/csv
```

### Prepare in CSV for HDFS
```bash
spark-submit \
  --verbose \
  --name MNIST-CSV-HDFS \
  --master mesos://zk://zk-1.zk:2181,zk-2.zk:2181,zk-3.zk:2181,zk-4.zk:2181,zk-5.zk:2181/mesos \
  --conf spark.mesos.containerizer=mesos \
  --conf spark.mesos.principal=dev_beakerx \
  --conf spark.mesos.role=dev-beakerx \
  --conf spark.cores.max=4 \
  --conf spark.executor.cores=2 \
  --conf spark.mesos.executor.docker.image=vishnumohan/spark-dcos:tfos \
  --conf spark.executor.home=/opt/spark \
  --conf spark.mesos.driver.labels=DCOS_SPACE:/dev/beakerx \
  --conf spark.mesos.driverEnv.SPARK_MESOS_KRB5_CONF_BASE64=dmlzaG51Cg== \
  --conf spark.executorEnv.SPARK_MESOS_KRB5_CONF_BASE64=dmlzaG51Cg== \
  --conf spark.mesos.driver.secret.names=/dev/AWS_ACCESS_KEY_ID,/dev/AWS_SECRET_ACCESS_KEY \
  --conf spark.mesos.driver.secret.envkeys=AWS_ACCESS_KEY_ID,AWS_SECRET_ACCESS_KEY \
  --conf spark.eventLog.enabled=true \
  --conf spark.eventLog.dir=s3a://vishnu-mohan/spark/history \
  --conf spark.mesos.uris=http://api.devhdfs.marathon.l4lb.thisdcos.directory/v1/endpoints/hdfs-site.xml,http://api.devhdfs.marathon.l4lb.thisdcos.directory/v1/endpoints/core-site.xml \
  $(pwd)/TensorFlowOnSpark/examples/mnist/mnist_data_setup.py \
    --output mnist/csv \
    --format csv
```

### List prepared CSV files on HDFS
```bash
hdfs dfs -ls -R mnist/csv
```

## Prepare MNIST Dataset in Tensorflow Record format and store on S3

### Remove existing bucket (if present)
```bash
aws s3 rm --recursive s3://vishnu-mohan/tensorflow/mnist/tfr
```

### Prepare in TFRecord for S3
```bash
spark-submit \
  --verbose \
  --name MNIST-TFR-S3 \
  --master mesos://zk://zk-1.zk:2181,zk-2.zk:2181,zk-3.zk:2181,zk-4.zk:2181,zk-5.zk:2181/mesos \
  --conf spark.mesos.containerizer=mesos \
  --conf spark.mesos.principal=dev_beakerx \
  --conf spark.mesos.role=dev-beakerx \
  --conf spark.cores.max=4 \
  --conf spark.executor.cores=2 \
  --conf spark.mesos.executor.docker.image=vishnumohan/spark-dcos:tfos \
  --conf spark.executor.home=/opt/spark \
  --conf spark.mesos.driver.labels=DCOS_SPACE:/dev/beakerx \
  --conf spark.mesos.driverEnv.SPARK_MESOS_KRB5_CONF_BASE64=dmlzaG51Cg== \
  --conf spark.executorEnv.SPARK_MESOS_KRB5_CONF_BASE64=dmlzaG51Cg== \
  --conf spark.mesos.driver.secret.names=/dev/AWS_ACCESS_KEY_ID,/dev/AWS_SECRET_ACCESS_KEY \
  --conf spark.mesos.driver.secret.envkeys=AWS_ACCESS_KEY_ID,AWS_SECRET_ACCESS_KEY \
  --conf spark.eventLog.enabled=true \
  --conf spark.eventLog.dir=s3a://vishnu-mohan/spark/history \
  $(pwd)/TensorFlowOnSpark/examples/mnist/mnist_data_setup.py \
    --output s3a://vishnu-mohan/tensorflow/mnist/tfr \
    --format tfr
```

### List prepared TFRecord files on S3
```bash
aws s3 ls --recursive s3://vishnu-mohan/tensorflow/mnist/tfr
```

## Prepare MNIST Dataset in Tensorflow Record format and store on HDFS (under hdfs://user/${USER}/mnist/tfr)

### Remove existing directory (if present)
```
hdfs dfs -rm -R -skipTrash mnist/tfr
```

### Prepare TFRecords for HDFS
```bash
spark-submit \
  --verbose \
  --name MNIST-TFR-HDFS \
  --master mesos://zk://zk-1.zk:2181,zk-2.zk:2181,zk-3.zk:2181,zk-4.zk:2181,zk-5.zk:2181/mesos \
  --conf spark.mesos.containerizer=mesos \
  --conf spark.mesos.principal=dev_beakerx \
  --conf spark.mesos.role=dev-beakerx \
  --conf spark.cores.max=4 \
  --conf spark.executor.cores=2 \
  --conf spark.mesos.executor.docker.image=vishnumohan/spark-dcos:tfos \
  --conf spark.executor.home=/opt/spark \
  --conf spark.mesos.driver.labels=DCOS_SPACE:/dev/beakerx \
  --conf spark.mesos.driverEnv.SPARK_MESOS_KRB5_CONF_BASE64=dmlzaG51Cg== \
  --conf spark.executorEnv.SPARK_MESOS_KRB5_CONF_BASE64=dmlzaG51Cg== \
  --conf spark.mesos.driver.secret.names=/dev/AWS_ACCESS_KEY_ID,/dev/AWS_SECRET_ACCESS_KEY \
  --conf spark.mesos.driver.secret.envkeys=AWS_ACCESS_KEY_ID,AWS_SECRET_ACCESS_KEY \
  --conf spark.eventLog.enabled=true \
  --conf spark.eventLog.dir=s3a://vishnu-mohan/spark/history \
  --conf spark.mesos.uris=https://s3.amazonaws.com/vishnu-mohan/tensorflow/mnist/mnist.zip,http://api.devhdfs.marathon.l4lb.thisdcos.directory/v1/endpoints/hdfs-site.xml,http://api.devhdfs.marathon.l4lb.thisdcos.directory/v1/endpoints/core-site.xml \
  $(pwd)/TensorFlowOnSpark/examples/mnist/mnist_data_setup.py \
    --output mnist/tfr \
    --format tfr
```

### List prepared TFRecord files on HDFS
```bash
hdfs dfs -ls -R mnist/tfr
```

# Train MNIST with Tensorflow on Spark

## Train MNIST from S3 in CSV format and store model in S3

### Remove existing csv folder in S3 bucket (if present)
```bash
aws s3 rm --recursive s3://vishnu-mohan/tensorflow/mnist/mnist_csv_model
```

### Train
```bash
spark-submit \
  --verbose \
  --name MNIST-Train-CSV-S3 \
  --master mesos://zk://zk-1.zk:2181,zk-2.zk:2181,zk-3.zk:2181,zk-4.zk:2181,zk-5.zk:2181/mesos \
  --conf spark.mesos.containerizer=mesos \
  --conf spark.mesos.principal=dev_beakerx \
  --conf spark.mesos.role=dev-beakerx \
  --conf spark.cores.max=10 \
  --conf spark.executor.cores=2 \
  --conf spark.mesos.executor.docker.image=vishnumohan/spark-dcos:tfos \
  --conf spark.executor.home=/opt/spark \
  --conf spark.mesos.driver.labels=DCOS_SPACE:/dev/beakerx \
  --conf spark.mesos.driverEnv.SPARK_MESOS_KRB5_CONF_BASE64=dmlzaG51Cg== \
  --conf spark.executorEnv.SPARK_MESOS_KRB5_CONF_BASE64=dmlzaG51Cg== \
  --conf spark.mesos.driver.secret.names=/dev/AWS_ACCESS_KEY_ID,/dev/AWS_SECRET_ACCESS_KEY \
  --conf spark.mesos.driver.secret.envkeys=AWS_ACCESS_KEY_ID,AWS_SECRET_ACCESS_KEY \
  --conf spark.eventLog.enabled=true \
  --conf spark.eventLog.dir=s3a://vishnu-mohan/spark/history \
  --py-files $(pwd)/TensorFlowOnSpark/examples/mnist/spark/mnist_dist.py \
  $(pwd)/TensorFlowOnSpark/examples/mnist/spark/mnist_spark.py \
    --cluster_size 5 \
    --images s3a://vishnu-mohan/tensorflow/mnist/csv/train/images \
    --labels s3a://vishnu-mohan/tensorflow/mnist/csv/train/labels \
    --format csv \
    --mode train \
    --model s3a://vishnu-mohan/tensorflow/mnist/mnist_csv_model
```

### List Model files trained from CSV on S3
```bash
aws s3 ls --recursive s3://vishnu-mohan/tensorflow/mnist/mnist_csv_model
```

## Train MNIST from S3 in TFRecord format and store model in S3

### Remove existing csv folder in S3 bucket (if present)
```bash
aws s3 rm --recursive s3://vishnu-mohan/tensorflow/mnist/mnist_tfr_model
```

### Train MNIST
```bash
spark-submit \
  --verbose \
  --name MNIST-Train-TFR-S3 \
  --master mesos://zk://zk-1.zk:2181,zk-2.zk:2181,zk-3.zk:2181,zk-4.zk:2181,zk-5.zk:2181/mesos \
  --conf spark.mesos.containerizer=mesos \
  --conf spark.mesos.principal=dev_beakerx \
  --conf spark.mesos.role=dev-beakerx \
  --conf spark.scheduler.minRegisteredResourcesRatio=1.0 \
  --conf spark.cores.max=5 \
  --conf spark.executor.cores=1 \
  --conf spark.executor.memory=4g \
  --conf spark.mesos.executor.docker.image=vishnumohan/spark-dcos:tfos \
  --conf spark.executor.home=/opt/spark \
  --conf spark.mesos.driver.labels=DCOS_SPACE:/dev/beakerx \
  --conf spark.mesos.driverEnv.SPARK_MESOS_KRB5_CONF_BASE64=dmlzaG51Cg== \
  --conf spark.executorEnv.SPARK_MESOS_KRB5_CONF_BASE64=dmlzaG51Cg== \
  --conf spark.executorEnv.KRB5_CONFIG=${MESOS_SANDBOX}/krb5.conf \
  --conf spark.executorEnv.JAVA_HOME=${JAVA_HOME} \
  --conf spark.executorEnv.HADOOP_HDFS_HOME=${HADOOP_HDFS_HOME} \
  --conf spark.executorEnv.LD_LIBRARY_PATH=${LD_LIBRARY_PATH} \
  --conf spark.executorEnv.CLASSPATH=${MESOS_SANDBOX}:$(${HADOOP_HDFS_HOME}/bin/hadoop classpath --glob):${CLASSPATH} \
  --conf spark.executorEnv.HADOOP_OPTS="-Djava.library.path=${HADOOP_HDFS_HOME}/lib/native -Djava.security.krb5.conf=${MESOS_SANDBOX}/krb5.conf" \
  --conf spark.mesos.driver.secret.names=/dev/AWS_ACCESS_KEY_ID,/dev/AWS_SECRET_ACCESS_KEY \
  --conf spark.mesos.driver.secret.envkeys=AWS_ACCESS_KEY_ID,AWS_SECRET_ACCESS_KEY \
  --conf spark.mesos.uris=http://api.devhdfs.marathon.l4lb.thisdcos.directory/v1/endpoints/hdfs-site.xml,http://api.devhdfs.marathon.l4lb.thisdcos.directory/v1/endpoints/core-site.xml \
  --conf spark.eventLog.enabled=true \
  --conf spark.eventLog.dir=s3a://vishnu-mohan/spark/history \
  --conf spark.driver.port=${PORT_SPARKDRIVER} \
  --conf spark.driver.blockManager.port=${PORT_SPARKBLOCKMANAGER} \
  --conf spark.ui.port=${PORT_SPARKUI} \
  --py-files $(pwd)/TensorFlowOnSpark/examples/mnist/spark/mnist_dist.py \
  $(pwd)/TensorFlowOnSpark/examples/mnist/spark/mnist_spark.py \
  --cluster_size 5 \
  --images s3a://vishnu-mohan/tensorflow/mnist/tfr/train/images \
  --labels s3a://vishnu-mohan/tensorflow/mnist/tfr/train/labels \
  --format tfr \
  --mode train \
  --model s3a://vishnu-mohan/tensorflow/mnist/mnist_tfr_model
```

### List Model files trained from TFRecords on S3
```bash
aws s3 ls --recursive s3://vishnu-mohan/tensorflow/mnist/mnist_tfr_model
```

## Train MNIST from CSV on HDFS and store the model on HDFS (under hdfs://user/${USER}/mnist/mnist_csv_model)

### Remove existing folder (if present)
```bash
hdfs dfs -rm -R -skipTrash user/${USER}/mnist/mnist_csv_model
```

### Train MNIST
```bash
spark-submit \
  --verbose \
  --name MNIST-Train-CSV-HDFS \
  --master mesos://zk://zk-1.zk:2181,zk-2.zk:2181,zk-3.zk:2181,zk-4.zk:2181,zk-5.zk:2181/mesos \
  --conf spark.mesos.containerizer=mesos \
  --conf spark.mesos.principal=dev_beakerx \
  --conf spark.mesos.role=dev-beakerx \
  --conf spark.scheduler.minRegisteredResourcesRatio=1.0 \
  --conf spark.cores.max=5 \
  --conf spark.executor.cores=1 \
  --conf spark.executor.memory=4g \
  --conf spark.mesos.executor.docker.image=vishnumohan/spark-dcos:tfos \
  --conf spark.executor.home=/opt/spark \
  --conf spark.mesos.driver.labels=DCOS_SPACE:/dev/beakerx \
  --conf spark.mesos.driverEnv.SPARK_MESOS_KRB5_CONF_BASE64=dmlzaG51Cg== \
  --conf spark.executorEnv.SPARK_MESOS_KRB5_CONF_BASE64=dmlzaG51Cg== \
  --conf spark.executorEnv.KRB5_CONFIG=${MESOS_SANDBOX}/krb5.conf \
  --conf spark.executorEnv.JAVA_HOME=${JAVA_HOME} \
  --conf spark.executorEnv.HADOOP_HDFS_HOME=${HADOOP_HDFS_HOME} \
  --conf spark.executorEnv.LD_LIBRARY_PATH=${LD_LIBRARY_PATH} \
  --conf spark.executorEnv.CLASSPATH=${MESOS_SANDBOX}:$(${HADOOP_HDFS_HOME}/bin/hadoop classpath --glob):${CLASSPATH} \
  --conf spark.executorEnv.HADOOP_OPTS="-Djava.library.path=${HADOOP_HDFS_HOME}/lib/native -Djava.security.krb5.conf=${MESOS_SANDBOX}/krb5.conf" \
  --conf spark.mesos.driver.secret.names=/dev/AWS_ACCESS_KEY_ID,/dev/AWS_SECRET_ACCESS_KEY \
  --conf spark.mesos.driver.secret.envkeys=AWS_ACCESS_KEY_ID,AWS_SECRET_ACCESS_KEY \
  --conf spark.mesos.uris=http://api.devhdfs.marathon.l4lb.thisdcos.directory/v1/endpoints/hdfs-site.xml,http://api.devhdfs.marathon.l4lb.thisdcos.directory/v1/endpoints/core-site.xml \
  --conf spark.eventLog.enabled=true \
  --conf spark.eventLog.dir=s3a://vishnu-mohan/spark/history \
  --conf spark.driver.port=${PORT_SPARKDRIVER} \
  --conf spark.driver.blockManager.port=${PORT_SPARKBLOCKMANAGER} \
  --conf spark.ui.port=${PORT_SPARKUI} \
  --py-files $(pwd)/TensorFlowOnSpark/examples/mnist/spark/mnist_dist.py \
  $(pwd)/TensorFlowOnSpark/examples/mnist/spark/mnist_spark.py \
  --cluster_size 5 \
  --images mnist/csv/train/images \
  --labels mnist/csv/train/labels \
  --format csv \
  --mode train \
  --model mnist/mnist_csv_model
```

### List Model files trained from CSV on HDFS
```bash
hdfs dfs -ls -R mnist/mnist_csv_model
```

## Train MNIST from TFRecord on HDFS and store the model on HDFS (under hdfs://user/${USER}/mnist/mnist_tfr_model)

### Remove existing folder (if present)
```bash
hdfs dfs -rm -R -skipTrash user/${USER}/mnist/mnist_tfr_model
```

### Train MNIST TFRecord for HDFS (under hdfs://user/${USER}/mnist/tfr)
```bash
spark-submit \
  --verbose \
  --name MNIST-Train-CSV-HDFS \
  --master mesos://zk://zk-1.zk:2181,zk-2.zk:2181,zk-3.zk:2181,zk-4.zk:2181,zk-5.zk:2181/mesos \
  --conf spark.mesos.containerizer=mesos \
  --conf spark.mesos.principal=dev_beakerx \
  --conf spark.mesos.role=dev-beakerx \
  --conf spark.scheduler.minRegisteredResourcesRatio=1.0 \
  --conf spark.cores.max=5 \
  --conf spark.executor.cores=1 \
  --conf spark.executor.memory=4g \
  --conf spark.mesos.executor.docker.image=vishnumohan/spark-dcos:tfos \
  --conf spark.executor.home=/opt/spark \
  --conf spark.mesos.driver.labels=DCOS_SPACE:/dev/beakerx \
  --conf spark.mesos.driverEnv.SPARK_MESOS_KRB5_CONF_BASE64=dmlzaG51Cg== \
  --conf spark.executorEnv.SPARK_MESOS_KRB5_CONF_BASE64=dmlzaG51Cg== \
  --conf spark.executorEnv.KRB5_CONFIG=${MESOS_SANDBOX}/krb5.conf \
  --conf spark.executorEnv.JAVA_HOME=${JAVA_HOME} \
  --conf spark.executorEnv.HADOOP_HDFS_HOME=${HADOOP_HDFS_HOME} \
  --conf spark.executorEnv.LD_LIBRARY_PATH=${LD_LIBRARY_PATH} \
  --conf spark.executorEnv.CLASSPATH=${MESOS_SANDBOX}:$(${HADOOP_HDFS_HOME}/bin/hadoop classpath --glob):${CLASSPATH} \
  --conf spark.executorEnv.HADOOP_OPTS="-Djava.library.path=${HADOOP_HDFS_HOME}/lib/native -Djava.security.krb5.conf=${MESOS_SANDBOX}/krb5.conf" \
  --conf spark.mesos.driver.secret.names=/dev/AWS_ACCESS_KEY_ID,/dev/AWS_SECRET_ACCESS_KEY \
  --conf spark.mesos.driver.secret.envkeys=AWS_ACCESS_KEY_ID,AWS_SECRET_ACCESS_KEY \
  --conf spark.mesos.uris=http://api.devhdfs.marathon.l4lb.thisdcos.directory/v1/endpoints/hdfs-site.xml,http://api.devhdfs.marathon.l4lb.thisdcos.directory/v1/endpoints/core-site.xml \
  --conf spark.eventLog.enabled=true \
  --conf spark.eventLog.dir=s3a://vishnu-mohan/spark/history \
  --conf spark.driver.port=${PORT_SPARKDRIVER} \
  --conf spark.driver.blockManager.port=${PORT_SPARKBLOCKMANAGER} \
  --conf spark.ui.port=${PORT_SPARKUI} \
  --py-files $(pwd)/TensorFlowOnSpark/examples/mnist/spark/mnist_dist.py \
  $(pwd)/TensorFlowOnSpark/examples/mnist/spark/mnist_spark.py \
  --cluster_size 5 \
  --images mnist/tfr/train/images \
  --labels mnist/tfr/train/labels \
  --format tfr \
  --mode train \
  --model mnist/mnist_tfr_model
```

### List model files trained from TFRecords on HDFS
```bash
hdfs dfs -ls -R mnist/mnist_tfr_model
```
