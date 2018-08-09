def gitCommit() {
    sh "git rev-parse HEAD > GIT_COMMIT"
def gitCommit = readFile('GIT_COMMIT').trim()
    sh "rm -f GIT_COMMIT"
    return gitCommit
}

node('mesos-ubuntu') {
    // Checkout source code from Git
    stage 'Checkout'
    checkout scm

    // Build Docker image
   stage 'Build JupyterLab docker image.'
   echo "Build jupyterlab docker image"

  stage 'Build Docker image '
  echo "Build jupyterlab docker image"

  stage 'Test'
  echo "Build jupyterlab docker image"
}
