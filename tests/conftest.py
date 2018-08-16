""" Parser File needed to make flags work with pytest """

def pytest_addoption(parser):
    parser.addoption('--vhost', action='store', help='vHost Address of public node (e.g. ELB DNS)')

def pytest_configure(config):
    args = config.getoption('vhost')
