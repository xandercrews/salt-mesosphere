stop_marathon:
  salt.function:
    - order: 1
    - tgt: 'mesos:master'
    - tgt_type: grain
    - name: state.single
    - arg:
      - service.dead
      - marathon

stop_mesos-master:
  salt.function:
    - order: 2
    - tgt: 'mesos:master'
    - tgt_type: grain
    - name: state.single
    - arg:
      - service.dead
      - mesos-master

stop_zookeeper:
  salt.function:
    - order: 3
    - tgt: 'mesos:master'
    - tgt_type: grain
    - name: state.single
    - arg:
      - service.dead
      - zookeeper

clear_zoo_logs:
  salt.function:
    - order: 4
    - tgt: 'mesos:master'
    - tgt_type: grain
    - name: cmd.run
    - arg:
      - 'rm -rf /var/lib/zookeeper/version-* /var/lib/mesos/replicated_log/*'

reapply_highstate:
  salt.state:
    - order: 5
    - tgt: 'mesos:master'
    - tgt_type: grain
    - highstate: True
