include:
  - mesosphere

mesos-slave:
   service.dead:
     - enable: False

clear_log:
   cmd.run:
     - names:
       - 'rm -rf /var/lib/zookeeper/version-* /var/lib/mesos/replicated_log/*'
     - prereq: 
       - file: /etc/mesos-master/quorum
       - file: /etc/zookeeper/conf/zoo.cfg
       - file: /etc/zookeeper/conf/myid

zookeeper:
   service.running: 
     - enable: True
     - require: 
       - pkg: mesos-packages
     - watch:
       - file: /etc/mesos-master/quorum
       - file: /etc/zookeeper/conf/zoo.cfg
       - file: /etc/zookeeper/conf/myid
       - cmd: clear_log

mesos-master:
   service.running: 
     - enable: True
     - require: 
       - service: zookeeper
     - watch:
       - service: zookeeper
       - file: /etc/mesos/zk
       - file: /etc/mesos-master/hostname

marathon:
   service.running: 
     - enable: True
     - require: 
       - service: mesos-master
       - service: zookeeper
     - watch:
       - service: mesos-master
       - service: zookeeper
       - file: /etc/marathon/conf/hostname

/etc/zookeeper/conf/zoo.cfg:
  file.managed:
    - source: salt://zookeeper/conf/zoo.cfg.tmpl
    - mode: 644
    - template: jinja

/etc/zookeeper/conf/myid:
  file.managed:
    - source: salt://zookeeper/conf/myid.tmpl
    - mode: 644
    - template: jinja

/etc/mesos/zk:
  file.managed:
    - source: salt://mesos/zk.tmpl
    - mode: 644
    - template: jinja

/etc/mesos-master/quorum:
  file.managed:
    - source: salt://mesos-master/quorum.tmpl
    - mode: 644
    - template: jinja

/etc/mesos-master/hostname:
  file.managed:
    - source: salt://mesos-master/hostname.tmpl
    - mode: 644
    - template: jinja

/etc/marathon/conf/hostname:
  file.managed:
    - source: salt://marathon/conf/hostname.tmpl
    - mode: 644
    - template: jinja
    - makedirs: True
