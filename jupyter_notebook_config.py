import errno
import os
import re
import requests
import stat
import subprocess


from shutil import copyfile
from jupyter_core.paths import jupyter_data_dir
from notebook.auth import passwd

# Only (pre)set a password if we're *not* using OpenID Connect
if not (os.getenv('OIDC_DISCOVERY_URI') and
        os.getenv('OIDC_CLIENT_ID')):

    # Set Jupyter Notebook Server password to 'jupyter-<Marathon-App-Prefix>'
    # e.g., Marathon App ID '/foo/bar/app' maps to password: 'jupyter-foo-bar'
    if os.getenv('MARATHON_APP_ID'):
        MARATHON_APP_PREFIX = \
            '-'.join(os.getenv('MARATHON_APP_ID').split('/')[:-1])
        c.NotebookApp.password = passwd('jupyter{}'.format(MARATHON_APP_PREFIX))

    # Set a password if JUPYTER_PASSWORD (override) is set
    if os.getenv('JUPYTER_PASSWORD'):
        c.NotebookApp.password = passwd(os.getenv('JUPYTER_PASSWORD'))
        del(os.environ['JUPYTER_PASSWORD'])
else:
    # Disable Notebook authentication since we're authenticating using OpenID Connect
    c.NotebookApp.password = u''
    c.NotebookApp.token = u''

# Don't leak OpenID Connect configuration to the end-user
for env in ['OIDC_DISCOVERY_URI',
            'OIDC_REDIRECT_URI',
            'OIDC_CLIENT_ID',
            'OIDC_CLIENT_SECRET',
            'OIDC_EMAIL']:
    try:
        del(os.environ[env])
    except KeyError:
        pass

# Setup the Notebook to listen on localhost:8888 by default
c.NotebookApp.ip = '127.0.0.1'
c.NotebookApp.port = 8888
c.NotebookApp.open_browser = False

# https://github.com/jupyter/notebook/issues/3130
c.FileContentsManager.delete_to_trash = False

# Allow CORS and TLS from behind Nginx/Marathon-LB/HAProxy
# Trust X-Scheme/X-Forwarded-Proto and X-Real-Ip/X-Forwarded-For
# Necessary if the proxy handles SSL
c.NotebookApp.trust_xheaders = True

# Set the Access-Control-Allow-Origin header
c.NotebookApp.allow_origin = '*'

# If running under Apache Mesos:
if (os.getenv('MESOS_SANDBOX')):
    if os.getenv('MARATHON_APP_LABEL_HAPROXY_0_VHOST'):
        c.NotebookApp.allow_origin = \
            'http://{}'.format(os.getenv('MARATHON_APP_LABEL_HAPROXY_0_VHOST'))

    if os.getenv('MARATHON_APP_LABEL_HAPROXY_0_REDIRECT_TO_HTTPS'):
        c.NotebookApp.allow_origin = \
            'https://{}'.format(os.getenv('MARATHON_APP_LABEL_HAPROXY_0_VHOST'))

    # Set the Jupyter Notebook server base URL to the HAPROXY_PATH specified
    if os.getenv('MARATHON_APP_LABEL_HAPROXY_0_PATH'):
        c.NotebookApp.base_url = \
            os.getenv('MARATHON_APP_LABEL_HAPROXY_0_PATH')

    # Tidy up Mesos Env Vars that will interfere with Spark Drivers
    mesos_sandbox = os.getenv('MESOS_SANDBOX')
    os.environ['MESOS_DIRECTORY'] = mesos_sandbox
    try:
        for env in ['MESOS_EXECUTOR_ID',
                    'MESOS_FRAMEWORK_ID',
                    'MESOS_SLAVE_ID',
                    'MESOS_SLAVE_PID'
                    'MESOS_TASK_ID']:
            del os.environ[env]
    except KeyError:
        pass

    # Set the current working directory to ${MESOS_SANDBOX}
    os.chdir(mesos_sandbox)

    # Download configuration files
    JUPYTER_CONF_FILES = ['core-site.xml',
                          'hdfs-site.xml',
                          'hive-site.xml',
                          'yarn-site.xml',
                          'krb5.conf',
                          'jaas.conf']

    jupyter_conf_urls = os.getenv('JUPYTER_CONF_URLS')
    if jupyter_conf_urls:
        for url in jupyter_conf_urls.split(','):
            for file in JUPYTER_CONF_FILES:
                r = requests.get('{}/{}'.format(url, file), stream=True)
                if r.status_code != requests.status_codes.codes.ok:
                    continue
                with open(file, 'wb') as f:
                    for chunk in r.iter_content(chunk_size=1024):
                        if chunk:  # filter out keep-alive new chunks
                            f.write(chunk)

    # Copy ${MESOS_SANDBOX}/krb5.conf if it exists to /etc/krb5.conf
    if os.path.exists('krb5.conf'):
        copyfile('krb5.conf', '/etc/krb5.conf')

# Build up ${SPARK_OPTS} for Apache Toree and to conveniently reuse with spark-submit:
# eval spark-submit ${SPARK_OPTS} <...>
spark_opts = []

if os.getenv('SPARK_MASTER_URL'):
    spark_opts.append('--master={}'.format(os.getenv('SPARK_MASTER_URL')))

if os.getenv('SPARK_DEPLOY_MODE'):
    spark_opts.append('--deploy-mode={}'.format(os.getenv('SPARK_DEPLOY_MODE')))

if os.getenv('SPARK_CLASS'):
    spark_opts.append('--class={}'.format(os.getenv('SPARK_CLASS')))

if os.getenv('SPARK_APP_NAME'):
    spark_opts.append('--name={}'.format(os.getenv('SPARK_APP_NAME')))

if os.getenv('SPARK_JARS'):
    spark_opts.append('--jars={}'.format(os.getenv('SPARK_JARS')))

if os.getenv('SPARK_PACKAGES'):
    spark_opts.append('--packages={}'.format(os.getenv('SPARK_PACKAGES')))

if os.getenv('SPARK_EXCLUDE_PACKAGES'):
    spark_opts.append('--exclude-packages={}'.format(os.getenv('SPARK_EXCLUDE_PACKAGES')))

if os.getenv('SPARK_REPOSITORIES'):
    spark_opts.append('--repositories={}'.format(os.getenv('SPARK_REPOSITORIES')))

if os.getenv('SPARK_PY_FILES'):
    spark_opts.append('--py-files={}'.format(os.getenv('SPARK_PY_FILES')))

# Forward Kerberos Credentials Cache (File) onto Spark Executors (for TensorFlowOnSpark)?
if os.getenv('ENABLE_SPARK_KERBEROS_TICKET_FORWARDING'):
    if os.getenv('SPARK_FILES'):
        spark_opts.append('--files {},{}'.format(
            os.getenv('KRB5CCNAME'), os.getenv('SPARK_FILES')))
    else:
        spark_opts.append('--files {}'.format(os.getenv('KRB5CCNAME')))
    spark_opts.append('--conf spark.executorEnv.KRB5CCNAME={}/krb5cc_{}'.format(
        os.getenv('MESOS_SANDBOX'), os.getuid()))

if os.getenv('SPARK_PROPERTIES_FILE'):
    spark_opts.append('--properties-file={}'.format(os.getenv('SPARK_PROPERTIES_FILE')))

if os.getenv('SPARK_DRIVER_CORES'):
    spark_opts.append('--driver-cores={}'.format(os.getenv('SPARK_DRIVER_CORES')))

if os.getenv('SPARK_DRIVER_MEMORY'):
    spark_opts.append('--driver-memory={}'.format(os.getenv('SPARK_DRIVER_MEMORY')))

if os.getenv('SPARK_DRIVER_JAVA_OPTIONS'):
    spark_opts.append('--driver-java-options={}'.format(os.getenv('SPARK_DRIVER_JAVA_OPTIONS')))

if os.getenv('SPARK_DRIVER_LIBRARY_PATH'):
    spark_opts.append('--driver-library-path={}'.format(os.getenv('SPARK_DRIVER_LIBRARY_PATH')))

if os.getenv('SPARK_DRIVER_CLASS_PATH'):
    spark_opts.append('--driver-class-path={}'.format(os.getenv('SPARK_DRIVER_CLASS_PATH')))

if os.getenv('SPARK_TOTAL_EXECUTOR_CORES'):
    spark_opts.append('--total-executor-cores={}'.format(os.getenv('SPARK_TOTAL_EXECUTOR_CORES')))

if os.getenv('SPARK_EXECUTOR_CORES'):
    spark_opts.append('--executor-cores={}'.format(os.getenv('SPARK_EXECUTOR_CORES')))

if os.getenv('SPARK_EXECUTOR_MEMORY'):
    spark_opts.append('--executor-memory={}'.format(os.getenv('SPARK_EXECUTOR_MEMORY')))

if os.getenv('SPARK_PROXY_USER'):
    spark_opts.append('--proxy-user={}'.format(os.getenv('SPARK_PROXY_USER')))

if os.getenv('SPARK_SUPERVISE'):
    spark_opts.append('--supervise={}'.format(os.getenv('SPARK_SUPERVISE')))

if os.getenv('SPARK_YARN_QUEUE'):
    spark_opts.append('--queue={}'.format(os.getenv('SPARK_YARN_QUEUE')))

if os.getenv('SPARK_YARN_NUM_EXECUTORS'):
    spark_opts.append('--num-executors={}'.format(os.getenv('SPARK_YARN_NUM_EXECUTORS')))

if os.getenv('SPARK_YARN_PRINCIPAL'):
    spark_opts.append('--principal={}'.format(os.getenv('SPARK_YARN_PRINCIPAL')))

if os.getenv('SPARK_YARN_KEYTAB'):
    spark_opts.append('--keytab={}'.format(os.getenv('SPARK_YARN_KEYTAB')))

if os.getenv('PORT_SPARKDRIVER'):
    spark_opts.append('--conf spark.driver.port={}'.format(os.getenv('PORT_SPARKDRIVER')))

if os.getenv('PORT_SPARKBLOCKMANAGER'):
    spark_opts.append('--conf spark.driver.blockManager.port={}'.format(os.getenv('PORT_SPARKBLOCKMANAGER')))

if os.getenv('PORT_SPARKUI'):
    spark_opts.append('--conf spark.ui.port={}'.format(os.getenv('PORT_SPARKUI')))

# Set Spark Executor Environment Variables for TensorFlowOnSpark
spark_opts.append('--conf spark.executorEnv.CLASSPATH={}'.format(os.getenv('CLASSPATH')))
spark_opts.append('--conf spark.executorEnv.LD_LIBRARY_PATH={}'.format(os.getenv('LD_LIBRARY_PATH')))

# Accumulate Spark --conf properties specified in SPARK_CONF_<> env vars
spark_conf_env_pattern = re.compile(r'^SPARK_CONF')
spark_conf_envs = [env for env in os.environ if spark_conf_env_pattern.match(env)]

for env in spark_conf_envs:
    spark_opts.append('--conf {}'.format(os.getenv(env)))

os.environ['SPARK_OPTS'] = ' '.join(spark_opts)
os.environ['PYSPARK_SUBMIT_ARGS'] = ' '.join(spark_opts + ['pyspark-shell'])
os.environ['SPARKR_SUBMIT_ARGS'] = ' '.join(spark_opts + ['sparkr-shell'])

if os.getenv('ENABLE_SPARK_MONITOR'):
    from conda.cli.main_info import get_info_dict
    conda_site_packages = os.path.dirname(get_info_dict()['conda_location'])
    spark_driver_extraclasspath = os.path.join(conda_site_packages, 'sparkmonitor/listener.jar')
    spark_monitor_conf = [
        '--conf spark.driver.extraClassPath={}'.format(spark_driver_extraclasspath),
        '--conf spark.extraListeners=sparkmonitor.listener.JupyterSparkMonitorListener'
    ]
    os.environ['PYSPARK_SUBMIT_ARGS'] = ' '.join(
        spark_opts + spark_monitor_conf + ['pyspark-shell']
    )

# Ray Redis (Head Node) Address
os.environ['RAY_REDIS_ADDRESS'] = '{}:{}'.format(
    os.getenv('MESOS_CONTAINER_IP'),
    os.getenv('PORT_RAYREDIS', '6379'))

# Dask Scheduler Address
os.environ['DASK_SCHEDULER_ADDRESS'] = '{}:{}'.format(
    os.getenv('MESOS_CONTAINER_IP'),
    os.getenv('PORT_DASKSCHEDULER', '8786'))

# Set a certificate if USE_HTTPS is set to any value
PEM_FILE = os.path.join(jupyter_data_dir(), 'notebook.pem')
if os.getenv('USE_HTTPS'):
    if not os.path.isfile(PEM_FILE):
        # Ensure PEM_FILE directory exists
        DIR_NAME = os.path.dirname(PEM_FILE)
        try:
            os.makedirs(DIR_NAME)
        except OSError as exc:  # Python >2.5
            if exc.errno == errno.EEXIST and os.path.isdir(DIR_NAME):
                pass
            else:
                raise
        # Generate a certificate if one doesn't exist on disk
        subprocess.check_call(['openssl', 'req', '-new', '-newkey', 'rsa:2048',
                               '-days', '365', '-nodes', '-x509', '-subj',
                               '/C=XX/ST=XX/L=XX/O=generated/CN=generated',
                               '-keyout', PEM_FILE, '-out', PEM_FILE])
        # Restrict access to PEM_FILE
        os.chmod(PEM_FILE, stat.S_IRUSR | stat.S_IWUSR)
    c.NotebookApp.certfile = PEM_FILE
