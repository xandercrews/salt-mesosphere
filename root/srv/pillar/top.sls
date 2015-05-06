base:
  '*':
    - ssh_keys
  'mesos:master':
    - match: grain
    - ssh_keys
    - mesomaster
  'mesos:slave':
    - match: grain
    - ssh_keys
    - mesoslave
