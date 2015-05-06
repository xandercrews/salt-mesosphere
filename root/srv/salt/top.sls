base:
  '*': 
    - ssh_keys
    - all_hosts
  'mesos:master':
    - match: grain
    - mesosphere.master
  'mesos:slave':
    - match: grain
    - mesosphere.slave
