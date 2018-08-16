""" Integration test (i.e. run against a real DC/OS cluster) for dcos-jupyterlab-service

Note: this tests expects a DC/OS JupyterLab Service to already be provisioned and reachable under a vHost.

At a minimum, the following syntax should be provided:
    python tests --vhost your-virtual-host-without-leading-https://-and-trailing-slash


Example:
    python tests --vhost fabianbaie-tf494c-pub-agt-elb-732556684.us-west-2.elb.amazonaws.com
"""

import ast
import logging
import os
import platform
import requests
from selenium import webdriver, common
import time
from tornado.httpclient import HTTPClient
import zipfile


logging.basicConfig(level=logging.DEBUG)

# List from https://chromedriver.storage.googleapis.com/index.html?
CHROMEDRIVER_SYSTEMS = dict(
    Linux='chromedriver_linux64.zip',
    Darwin='chromedriver_mac64.zip',
    Windows='chromedriver_win32.zip'
)

def test_download_chromedriver():
    """
    Test: Test that downloads and provides most recent Chromedrivers.

    Note: This is needed to run selenium tests.
    """
    log = logging.getLogger('test_download_chromedriver')
    system = platform.system()
    if system not in CHROMEDRIVER_SYSTEMS:
        log.error('Unsupported platform %s' % system)
        return

    r = requests.get('https://chromedriver.storage.googleapis.com/LATEST_RELEASE')
    latest_chromedriver = r.text
    log.debug(latest_chromedriver)
    response = HTTPClient().fetch('https://chromedriver.storage.googleapis.com/'+latest_chromedriver+'/'+CHROMEDRIVER_SYSTEMS[system])
    fid = zipfile.ZipFile(response.buffer)
    current_path = os.path.dirname(__file__)
    fid.extractall(current_path)
    fid.close()
    # todo: https://github.com/jupyterlab/jupyterlab/blob/c8b319a3600f0225ae7931433a8c40638a6538da/jupyterlab/selenium_check.py#L137-L139
    path_to_chromedriver = current_path + "/chromedriver"
    # Making file executable
    os.chmod(path_to_chromedriver, 0o775)
    assert os.path.exists(path_to_chromedriver) == True

def elb_online_check(url, timeout):
    """
    Function that checks if vhost provided is available

    :param url: full vhost, e.g. elb address including https:// and leading /
    :param timeout: default set to 5 seconds
    :return: true for elb reachable, false for all other cases.
    """
    log = logging.getLogger('elb_online_check')
    try:
        req = requests.get(url, timeout=timeout)
        req.raise_for_status()
        return True
    except requests.HTTPError as e:
        log.debug("Checking internet connection failed, status code {0}.".format(
        e.response.status_code))
        return True
    except requests.ConnectionError:
        log.debug("No internet connection available.")
    return False

def test_elb_available(request):
    """
    Test: Test for availability of ELB

    Note: As a first step to make sure the DC/OS cluster was provisioned and selenium tests can be run
    """
    vhost = 'http://'+ast.literal_eval(request.config.getoption('vhost'))[0]
    elb_response = elb_online_check(vhost, 5)
    assert elb_response == True

def test_marathon_lb_available(request):
    """
    Test: Test Marathon-LB to see if it is correctly installed
    """
    vhost = 'http://'+ast.literal_eval(request.config.getoption('vhost'))[0]+'/intentionally_left_blank'
    req = requests.get(vhost)
    req.status_code
    assert req.status_code == 503

def test_jupyterlab_available(request):
    """
    Test: Checking availability of the DC/OS JupyterLab Service endpoint
    """
    vhost = 'https://'+ast.literal_eval(request.config.getoption('vhost'))[0]+'/jupyterlab-notebook'
    import urllib3
    urllib3.disable_warnings()
    req = requests.get(vhost, verify=False)
    req.status_code
    assert req.status_code == 200

def test_jupyterlab_wrong_login(request):
    """
    Test: Trying on purpose to log in with wrong password
    """
    log = logging.getLogger('test_jupyterlab_wrong_login')
    vhost = 'https://'+ast.literal_eval(request.config.getoption('vhost'))[0]+'/jupyterlab-notebook'
    current_path = os.path.dirname(__file__)
    abs_path_to_chromedriver = os.path.abspath(current_path)+"/chromedriver"
    log.debug(abs_path_to_chromedriver)
    driver = webdriver.Chrome(executable_path=abs_path_to_chromedriver)
    driver.get(vhost)
    driver.implicitly_wait(10)
    driver.find_element_by_css_selector('#password_input').send_keys("thisshouldnotwork")
    driver.find_element_by_css_selector("#login_submit").click()
    assert driver.find_element_by_css_selector('#ipython-main-app > div:nth-child(2) > div').text == "Invalid credentials"

def test_jupyterlab_correct_login(request):
    """
    Test: Trying to login with an password that is expected to work
    """
    log = logging.getLogger('test_jupyterlab_correct_login')
    vhost = 'https://'+ast.literal_eval(request.config.getoption('vhost'))[0]+'/jupyterlab-notebook'
    current_path = os.path.dirname(__file__)
    abs_path_to_chromedriver = os.path.abspath(current_path)+"/chromedriver"
    log.debug(abs_path_to_chromedriver)
    driver = webdriver.Chrome(executable_path=abs_path_to_chromedriver)
    driver.get(vhost)
    driver.implicitly_wait(10)
    driver.find_element_by_css_selector('#password_input').send_keys("thefuture")
    driver.find_element_by_css_selector("#login_submit").click()
    assert driver.find_element_by_css_selector('#jp-main-dock-panel > div.p-Widget.p-TabBar.p-DockPanel-tabBar.jp-Activity > ul > li > div.p-TabBar-tabLabel').text == "Launcher"

def test_jupyterlab_launch_terminal(request):
    """
    Test: Launching a terminal and see if it comes up
    """
    log = logging.getLogger('test_jupyterlab_launch_terminal')
    vhost = 'https://' + ast.literal_eval(request.config.getoption('vhost'))[0] + '/jupyterlab-notebook'
    current_path = os.path.dirname(__file__)
    abs_path_to_chromedriver = os.path.abspath(current_path) + "/chromedriver"
    log.debug(abs_path_to_chromedriver)
    driver = webdriver.Chrome(executable_path=abs_path_to_chromedriver)
    driver.get(vhost)
    driver.implicitly_wait(10)
    driver.find_element_by_css_selector('#password_input').send_keys("thefuture")
    driver.find_element_by_css_selector("#login_submit").click()
    driver.implicitly_wait(10)
    elements = driver.find_elements_by_xpath("//*[@class='jp-LauncherCard-label']")
    # Workaround that expects stale condition when terminal is actually launched.
    try:
        for i in range(len(elements)):
            # Select the card you want to launch, e.g. "Python 3" or "Terminal"
            if elements[i].text == "Terminal":
                driver.execute_script("arguments[0].scrollIntoView();", elements[i])
                driver.execute_script("arguments[0].click();", elements[i])
                driver.implicitly_wait(10)
                started_terminals = driver.find_elements_by_xpath('//*[@id="jp-running-sessions"]/div[2]/div[2]')
                # Needed as element is not showing in UI right after
                time.sleep(10)
                terminal_name = driver.execute_script("var val = document.getElementsByClassName('jp-RunningSessions-itemLabel')[0].textContent; return val;", started_terminals[0])
                log.debug(terminal_name)
                assert terminal_name == "terminals/1"
    except common.exceptions.StaleElementReferenceException as e:
        log.debug("Stale condition {0}.".format(e.msg))
        pass
