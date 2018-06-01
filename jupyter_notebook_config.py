import errno
import os
import re
import stat
import subprocess


from jupyter_core.paths import jupyter_data_dir
from notebook.auth import passwd

# Setup the Notebook to listen on all interfaces on port 8888 by default
c.NotebookApp.ip = '*'  # noqa: F821
c.NotebookApp.port = 8888
c.NotebookApp.open_browser = False

# https://github.com/jupyter/notebook/issues/3130
c.FileContentsManager.delete_to_trash = False

# Configure Networking while running under Marathon:
if 'MARATHON_APP_ID' in os.environ:
    if 'PORT0' in os.environ:
        c.NotebookApp.port = int(os.environ['PORT0'])

    # Set the Access-Control-Allow-Origin header
    c.NotebookApp.allow_origin = '*'

    # Set Jupyter Notebook Server password to 'jupyter-<Marathon-App-Prefix>'
    # e.g., Marathon App ID '/foo/bar/app' maps to password: 'jupyter-foo-bar'
    MARATHON_APP_PREFIX = \
        '-'.join(os.environ['MARATHON_APP_ID'].split('/')[:-1])
    c.NotebookApp.password = passwd('jupyter{}'.format(MARATHON_APP_PREFIX))

    # Allow CORS and TLS from behind Marathon-LB/HAProxy
    # Trust X-Scheme/X-Forwarded-Proto and X-Real-Ip/X-Forwarded-For
    # Necessary if the proxy handles SSL
    if 'MARATHON_APP_LABEL_HAPROXY_GROUP' in os.environ:
        c.NotebookApp.trust_xheaders = True

    if 'MARATHON_APP_LABEL_HAPROXY_0_VHOST' in os.environ:
        c.NotebookApp.allow_origin = \
            'http://{}'.format(
                os.environ['MARATHON_APP_LABEL_HAPROXY_0_VHOST']
            )

    if 'MARATHON_APP_LABEL_HAPROXY_0_REDIRECT_TO_HTTPS' in os.environ:
        c.NotebookApp.allow_origin = \
            'https://{}'.format(
                os.environ['MARATHON_APP_LABEL_HAPROXY_0_VHOST']
            )

    # Set the Jupyter Notebook server base URL to the HAPROXY_PATH specified
    if 'MARATHON_APP_LABEL_HAPROXY_0_PATH' in os.environ:
        c.NotebookApp.base_url = \
            os.environ['MARATHON_APP_LABEL_HAPROXY_0_PATH']

    # Tidy up Mesos Env Vars that will interfere with Spark Drivers
    os.environ['MESOS_DIRECTORY'] = '/mnt/mesos/sandbox'
    try:
        for env in ['MESOS_EXECUTOR_ID',
                    'MESOS_FRAMEWORK_ID',
                    'MESOS_SLAVE_ID',
                    'MESOS_SLAVE_PID'
                    'MESOS_TASK_ID']:
            del os.environ[env]
    except KeyError:
        pass

    spark_conf_env_pattern = re.compile(r'^SPARK_CONF')

    spark_conf_envs = [env for env in os.environ if spark_conf_env_pattern.match(env)]

    spark_opts = []

    if os.environ.get('SPARK_MASTER_URL'):
        spark_opts.append('--master={}'.format(os.environ.get('SPARK_MASTER_URL')))

    if os.environ.get('SPARK_DEPLOY_MODE'):
        spark_opts.append('--deploy-mode={}'.format(os.environ.get('SPARK_DEPLOY_MODE')))

    if os.environ.get('SPARK_CLASS'):
        spark_opts.append('--class={}'.format(os.environ.get('SPARK_CLASS')))

    if os.environ.get('SPARK_APP_NAME'):
        spark_opts.append('--name={}'.format(os.environ.get('SPARK_APP_NAME')))

    if os.environ.get('SPARK_JARS'):
        spark_opts.append('--jars={}'.format(os.environ.get('SPARK_JARS')))

    if os.environ.get('SPARK_PACKAGES'):
        spark_opts.append('--packages={}'.format(os.environ.get('SPARK_PACKAGES')))

    if os.environ.get('SPARK_EXCLUDE_PACKAGES'):
        spark_opts.append('--exclude-packages={}'.format(os.environ.get('SPARK_EXCLUDE_PACKAGES')))

    if os.environ.get('SPARK_REPOSITORIES'):
        spark_opts.append('--repositories={}'.format(os.environ.get('SPARK_REPOSITORIES')))

    if os.environ.get('SPARK_PY_FILES'):
        spark_opts.append('--py-files={}'.format(os.environ.get('SPARK_PY_FILES')))

    if os.environ.get('SPARK_FILES'):
        spark_opts.append('--files={}'.format(os.environ.get('SPARK_FILES')))

    if os.environ.get('SPARK_PROPERTIES_FILE'):
        spark_opts.append('--properties-file={}'.format(os.environ.get('SPARK_PROPERTIES_FILE')))

    if os.environ.get('SPARK_DRIVER_CORES'):
        spark_opts.append('--driver-cores={}'.format(os.environ.get('SPARK_DRIVER_CORES')))

    if os.environ.get('SPARK_DRIVER_MEMORY'):
        spark_opts.append('--driver-memory={}'.format(os.environ.get('SPARK_DRIVER_MEMORY')))

    if os.environ.get('SPARK_DRIVER_JAVA_OPTIONS'):
        spark_opts.append('--driver-java-options={}'.format(os.environ.get('SPARK_DRIVER_JAVA_OPTIONS')))

    if os.environ.get('SPARK_DRIVER_LIBRARY_PATH'):
        spark_opts.append('--driver-library-path={}'.format(os.environ.get('SPARK_DRIVER_LIBRARY_PATH')))

    if os.environ.get('SPARK_DRIVER_CLASS_PATH'):
        spark_opts.append('--driver-class-path={}'.format(os.environ.get('SPARK_DRIVER_CLASS_PATH')))

    if os.environ.get('SPARK_TOTAL_EXECUTOR_CORES'):
        spark_opts.append('--total-executor-cores={}'.format(os.environ.get('SPARK_TOTAL_EXECUTOR_CORES')))

    if os.environ.get('SPARK_EXECUTOR_CORES'):
        spark_opts.append('--executor-cores={}'.format(os.environ.get('SPARK_EXECUTOR_CORES')))

    if os.environ.get('SPARK_EXECUTOR_MEMORY'):
        spark_opts.append('--executor-memory={}'.format(os.environ.get('SPARK_EXECUTOR_MEMORY')))

    if os.environ.get('SPARK_PROXY_USER'):
        spark_opts.append('--proxy-user={}'.format(os.environ.get('SPARK_PROXY_USER')))

    if os.environ.get('SPARK_SUPERVISE'):
        spark_opts.append('--supervise={}'.format(os.environ.get('SPARK_SUPERVISE')))

    if os.environ.get('SPARK_YARN_QUEUE'):
        spark_opts.append('--queue={}'.format(os.environ.get('SPARK_YARN_QUEUE')))

    if os.environ.get('SPARK_YARN_NUM_EXECUTORS'):
        spark_opts.append('--num-executors={}'.format(os.environ.get('SPARK_YARN_NUM_EXECUTORS')))

    if os.environ.get('SPARK_YARN_PRINCIPAL'):
        spark_opts.append('--principal={}'.format(os.environ.get('SPARK_YARN_PRINCIPAL')))

    if os.environ.get('SPARK_YARN_KEYTAB'):
        spark_opts.append('--keytab={}'.format(os.environ.get('SPARK_YARN_KEYTAB')))

    if os.environ.get('PORT_SPARKDRIVER'):
        spark_opts.append('--conf spark.driver.port={}'.format(os.environ.get('PORT_SPARKDRIVER')))

    if os.environ.get('PORT_SPARKBLOCKMANAGER'):
        spark_opts.append('--conf spark.driver.blockManager.port={}'.format(os.environ.get('PORT_SPARKBLOCKMANAGER')))

    if os.environ.get('PORT_SPARKUI'):
        spark_opts.append('--conf spark.ui.port={}'.format(os.environ.get('PORT_SPARKUI')))

    for env in spark_conf_envs:
        spark_opts.append('--conf {}'.format(os.environ.get(env)))

    os.environ['SPARK_OPTS'] = ' '.join(spark_opts)

    os.environ['PYSPARK_SUBMIT_ARGS'] = ' '.join(spark_opts.append('pyspark-shell'))
    os.environ['SPARKR_SUBMIT_ARGS'] = ' '.join(spark_opts.append('sparkr-shell'))

# Set a certificate if USE_HTTPS is set to any value
PEM_FILE = os.path.join(jupyter_data_dir(), 'notebook.pem')
if 'USE_HTTPS' in os.environ:
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

# Set a password if JUPYTER_PASSWORD is set
if 'JUPYTER_PASSWORD' in os.environ:
    c.NotebookApp.password = passwd(os.environ['JUPYTER_PASSWORD'])
    del os.environ['JUPYTER_PASSWORD']
