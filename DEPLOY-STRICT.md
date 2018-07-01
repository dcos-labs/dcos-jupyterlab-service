# Jupyter Notebooks with the BeakerX JVM Kernels on Mesosphere DC/OS

## Setup Service Account for Jupyter

```bash
dcos security org service-accounts keypair jupyter-private-key.pem jupyter-public-key.pem

dcos security org service-accounts create -p jupyter-public-key.pem -d "Dev Jupyter Service Account" dev_jupyter
dcos security secrets create-sa-secret --strict jupyter-private-key.pem dev_jupyter dev/jupyter/serviceCredential
dcos security org users grant dev_jupyter dcos:mesos:master:task:user:nobody create --description "Allow dev_jupyter to launch tasks under the Linux user: nobody"
dcos security org users grant dev_jupyter dcos:mesos:master:framework:role:dev-jupyter create --description "Allow dev_jupyter to register with Mesos and consume resources from the dev-jupyter role"
dcos security org users grant dev_jupyter dcos:mesos:master:task:app_id:/dev/jupyter create --description "Allow dev_jupyter to create tasks under the /dev/jupyter namespace"
```

## (Optional) Setup Quota for Jupyter
```bash
tee dev-jupyter-quota.json <<- 'EOF'
{
 "role": "dev-jupyter",
 "guarantee": [
   {
     "name": "cpus",
     "type": "SCALAR",
     "scalar": { "value": 5.0 }
   },
   {
     "name": "mem",
     "type": "SCALAR",
     "scalar": { "value": 22525.0 }
   }
 ]
}
EOF

curl --cacert dcos-ca.crt -fsSL -X POST -H "Authorization: token=$(dcos config show core.dcos_acs_token)" -H "Content-Type: application/json" $(dcos config show core.dcos_url)/mesos/quota -d @dev-jupyter-quota.json
```

## Submit a test SparkPi Job
```bash
eval \
  spark-submit \
  ${SPARK_OPTS} \
  --verbose \
  --class org.apache.spark.examples.SparkPi \
  /opt/spark/examples/jars/spark-examples_2.11-2.2.1.jar 100
```

## Prepare MNIST Dataset with Yahoo's Tensorflow on Spark

### Clone the Yahoo TensorFlowOnSpark Github Repo
```bash
git clone https://github.com/yahoo/TensorFlowOnSpark
```

### Retrieve and extract raw MNIST Dataset

```bash
cd $MESOS_SANDBOX
curl -fsSL -O https://s3.amazonaws.com/vishnu-mohan/tensorflow/mnist/mnist.zip
unzip mnist.zip
```

### Prepare MNIST Dataset in CSV format and store on S3

#### Remove existing csv folder in S3 bucket (if present)
```bash
aws s3 rm --recursive s3://vishnu-mohan/tensorflow/mnist/csv 
```

#### Prepare MINST as CSV for S3
```bash
eval \
  spark-submit \
  ${SPARK_OPTS} \
  --verbose \
  $(pwd)/TensorFlowOnSpark/examples/mnist/mnist_data_setup.py \
    --output s3a://vishnu-mohan/tensorflow/mnist/csv \
    --format csv
```

#### List prepared CSV files on S3
```bash
aws s3 ls --recursive s3://vishnu-mohan/tensorflow/mnist/csv
```

### Prepare MNIST Dataset in CSV format and store on HDFS (under hdfs://user/${USER}/mnist/csv)

#### Remove existing folder (if present)
```bash
hdfs dfs -rm -R -skipTrash mnist/csv
```

#### Prepare MNIST as CSV for HDFS
```bash
eval \
  spark-submit \
  ${SPARK_OPTS} \
  --verbose \
  $(pwd)/TensorFlowOnSpark/examples/mnist/mnist_data_setup.py \
    --output mnist/csv \
    --format csv
```

#### List prepared CSV files on HDFS
```bash
hdfs dfs -ls -R mnist/csv
```

### Prepare MNIST Dataset in Tensorflow Record format and store on S3

#### Remove existing bucket (if present)
```bash
aws s3 rm --recursive s3://vishnu-mohan/tensorflow/mnist/tfr
```

#### Prepare MNIST as TFRecord for S3
```bash
eval \
  spark-submit \
  ${SPARK_OPTS} \
  --verbose \
  $(pwd)/TensorFlowOnSpark/examples/mnist/mnist_data_setup.py \
    --output s3a://vishnu-mohan/tensorflow/mnist/tfr \
    --format tfr
```

#### List prepared TFRecord files on S3
```bash
aws s3 ls --recursive s3://vishnu-mohan/tensorflow/mnist/tfr
```

### Prepare MNIST Dataset in Tensorflow Record format and store on HDFS (under hdfs://user/${USER}/mnist/tfr)

#### Remove existing directory (if present)
```
hdfs dfs -rm -R -skipTrash mnist/tfr
```

#### Prepare MNIST as TFRecords for HDFS
```bash
eval \
  spark-submit \
  ${SPARK_OPTS} \
  --verbose \
  $(pwd)/TensorFlowOnSpark/examples/mnist/mnist_data_setup.py \
    --output mnist/tfr \
    --format tfr
```

#### List prepared TFRecord files on HDFS
```bash
hdfs dfs -ls -R mnist/tfr
```

## Train MNIST with Tensorflow on Spark

### Train MNIST from S3 in CSV format and store model in S3

#### Remove existing CSV model folder in S3 bucket (if present)
```bash
aws s3 rm --recursive s3://vishnu-mohan/tensorflow/mnist/mnist_csv_model
```

#### Train
```bash
eval \
  spark-submit \
  ${SPARK_OPTS} \
  --verbose \
  --py-files $(pwd)/TensorFlowOnSpark/examples/mnist/spark/mnist_dist.py \
  $(pwd)/TensorFlowOnSpark/examples/mnist/spark/mnist_spark.py \
    --cluster_size 5 \
    --images s3a://vishnu-mohan/tensorflow/mnist/csv/train/images \
    --labels s3a://vishnu-mohan/tensorflow/mnist/csv/train/labels \
    --format csv \
    --mode train \
    --model s3://vishnu-mohan/tensorflow/mnist/mnist_csv_model
```

#### List Model files trained from CSV on S3
```bash
aws s3 ls --recursive s3://vishnu-mohan/tensorflow/mnist/mnist_csv_model
```

### Train MNIST from S3 in TFRecord format and store model in S3

#### Remove existing TFR model folder in S3 bucket (if present)
```bash
aws s3 rm --recursive s3://vishnu-mohan/tensorflow/mnist/mnist_tfr_model
```

#### Train MNIST
```bash
eval \
  spark-submit \
  ${SPARK_OPTS} \
  --verbose \
  --py-files $(pwd)/TensorFlowOnSpark/examples/mnist/spark/mnist_dist.py \
  $(pwd)/TensorFlowOnSpark/examples/mnist/spark/mnist_spark.py \
  --cluster_size 5 \
  --images s3a://vishnu-mohan/tensorflow/mnist/tfr/train \
  --format tfr \
  --mode train \
  --model s3://vishnu-mohan/tensorflow/mnist/mnist_tfr_model
```

#### List Model files trained from TFRecords on S3
```bash
aws s3 ls --recursive s3://vishnu-mohan/tensorflow/mnist/mnist_tfr_model
```

### Train MNIST from CSV on HDFS and store the model on HDFS (under hdfs://user/${USER}/mnist/mnist_csv_model)

#### Remove existing CSV model folder on HDFS (if present)
```bash
hdfs dfs -rm -R -skipTrash mnist/mnist_csv_model
```

#### Train MNIST
```bash
eval \
  spark-submit \
  ${SPARK_OPTS} \
  --verbose \
  --py-files $(pwd)/TensorFlowOnSpark/examples/mnist/spark/mnist_dist.py \
  $(pwd)/TensorFlowOnSpark/examples/mnist/spark/mnist_spark.py \
  --cluster_size 5 \
  --images mnist/csv/train/images \
  --labels mnist/csv/train/labels \
  --format csv \
  --mode train \
  --model mnist/mnist_csv_model
```

#### List Model files trained from CSV on HDFS
```bash
hdfs dfs -ls -R mnist/mnist_csv_model
```

### Train MNIST from TFRecords on HDFS and store the model on HDFS (under hdfs://user/${USER}/mnist/mnist_tfr_model)

#### Remove existing TFR model folder on HDFS (if present)
```bash
hdfs dfs -rm -R -skipTrash mnist/mnist_tfr_model
```

#### Train MNIST TFRecord for HDFS (under hdfs://user/${USER}/mnist/tfr)
```bash
eval \
  spark-submit \
  ${SPARK_OPTS} \
  --verbose \
  --py-files $(pwd)/TensorFlowOnSpark/examples/mnist/spark/mnist_dist.py \
  $(pwd)/TensorFlowOnSpark/examples/mnist/spark/mnist_spark.py \
  --cluster_size 5 \
  --images mnist/tfr/train \
  --format tfr \
  --mode train \
  --model mnist/mnist_tfr_model
```

#### List model files trained from TFRecords on HDFS
```bash
hdfs dfs -ls -R mnist/mnist_tfr_model
```
