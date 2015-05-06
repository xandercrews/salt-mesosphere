#!/usr/bin/python2

import re
import string
import random
import pprint

import os
import sys

import logging
log = logging.getLogger(__file__)
log.setLevel(logging.DEBUG)

sh = logging.StreamHandler()
sh.setLevel(logging.DEBUG)

fmt = logging.Formatter('%(asctime)s %(name)s %(levelname)s %(message)s')
sh.setFormatter(fmt)

log.addHandler(sh)

import yaml
import distutils.spawn

import salt.client
import salt.runner

import fcntl
from contextlib import contextmanager

import glob

def load_config_d(path):
    all_configs = {}
    for p in glob.glob(path):
        with open(p) as fh:
            d = yaml.load(fh)
            all_configs = dict(all_configs.items() + d.items())
    return all_configs



local = salt.client.LocalClient()

opts = salt.config.master_config('/etc/salt/master')

runner = salt.runner.RunnerClient(opts)

log.debug(pprint.pformat(opts, indent=2))

SLAVEYAML = '/srv/cloudmap/mesosphere/slaves'
SLAVEIMG = 'sl_ubuntu_mesoslave_small'

RESOURCE_THRESHOLD = 0.7

SLAVE_LIMIT = 20
SCALE_STEP = 4


@contextmanager
def flocked(fd):
    """ Locks FD before entering the context, always releasing the lock. """
    try:
        log.debug('acquiring lock for scaling process')
        fcntl.flock(fd, fcntl.LOCK_EX)
        yield
    finally:
        log.debug('releasing lock for scaling process')
        fcntl.flock(fd, fcntl.LOCK_UN)

def active_master_stats():
    stats = local.cmd('mesos:master', 'mesostat.get_cluster_stats', [], expr_form='grain')
    for node,v in stats.iteritems():
        if v.get('master/elected'):
            return node, v

def slave_list():
    slaves = []

    # under management
    nodes = runner.cmd('manage.status', [False])
    for s in nodes.values():
        for n in s:
            if n.startswith('mesoslave-'):
                slaves.append(n)

    # in cloud map
    with open(SLAVEYAML, 'r') as fh:
        d = yaml.load(fh)
    if not d:
        return slaves
    return list(set(d.get(SLAVEIMG, []) + slaves))

def scale_up(slaves):
    new_slaves = []

    for i in xrange(1, SLAVE_LIMIT + 1):
        newslave = 'mesoslave-%s' % randomstr()
	while newslave in slaves:
            newslave = 'mesoslave-%s' % randomstr()
        new_slaves.append(newslave)
        if len(new_slaves) >= SCALE_STEP:
            break

    natural_pat = re.compile(r'([0-9]+|.)')

    d = {
        SLAVEIMG: sorted(slaves + new_slaves, key=lambda s: map(lambda m: int(m) if m.isdigit() else m, natural_pat.findall(s)))
    }

    with open(SLAVEYAML, 'w') as fh:
        print >>fh, yaml.dump(d)
    
def do_scale():
    # get stats from active master
    mastername, stats = active_master_stats()
    log.info('active master: %s' % mastername)
    log.debug('active master stats:\n%s', pprint.pformat(stats, indent=2))

    if not stats:
        raise Exception('no active master stats')

    # get list of slaves
    slaves = slave_list()
    log.info('slave list: %s' % slaves)

    if len(slaves) == stats.get('master/slaves_connected'):
        # consider scaling up if there are not enough idle resources
        if stats.get('master/slaves_connected') == 0:
	    log.info('no slaves, scaling up')
            scale_up(slaves)
        else:
            for res in ('mem', 'disk', 'cpus'):
                usage_percent = stats.get('master/%s_percent' % res)
                log.debug('%s usage: %s'% (res, usage_percent))
                if usage_percent > RESOURCE_THRESHOLD:
                    log.info('%s utilization too high, scaling up' % res)
                    scale_up(slaves)
    else:
        log.info('slave list does not match number of running slaves, cannot continue')

    # apply map
    log.info('applying slave map')
    
    # cloudclient.action(fun='map_run', cloudmap=SLAVEYAML)
    saltcloud = distutils.spawn.find_executable('salt-cloud')
    if os.system('%s -m %s -P -y' % (saltcloud, SLAVEYAML)) != 0:
        log.error('cloud map apply failed')

def randomstr(k=8):
    return ''.join(random.sample(string.ascii_lowercase, k))

with open('/var/run/scaler.lock', 'w') as f:
    with flocked(f):
        log.info('starting scale evaluation')
        do_scale()

# vim: set ts=4 sw=4 expandtab:
