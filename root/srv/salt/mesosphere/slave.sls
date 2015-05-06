include:
  - mesosphere

docker-repos:
  pkgrepo.managed:
    - humanname: Docker APT
    - name: deb https://get.docker.com/ubuntu docker main
    - file: /etc/apt/sources.list.d/docker.list
    - keyid: 36A1D7869245C8950F966E92D8576A8BA88D21E9
    - keyserver: keyserver.ubuntu.com
    - require_in:
      - pkg: lxc-docker

lxc-docker:
  pkg:
    - latest

docker:
  service.running: 
    - enable: True
    - require:
      - pkg: lxc-docker

zookeeper:
   service.dead:
     - enable: False

mesos-master:
   service.dead:
     - enable: False

marathon:
   service.dead: 
     - enable: False

mesos-slave:
   service.running: 
     - enable: True
     - require:
       - pkg: mesos-packages
     - watch:
       - file: /etc/mesos/zk
       - file: /etc/mesos-slave/containerizers
       - file: /etc/mesos-slave/executor_registration_timeout

/etc/mesos/zk:
  file.managed:
    - source: salt://mesos/zk.tmpl
    - mode: 644
    - template: jinja

/etc/mesos-slave/containerizers:
  file.managed:
    - contents: 'docker,mesos'
    - mode: 644
    - template: jinja
    - require:
      - pkg: mesos-packages

/etc/mesos-slave/executor_registration_timeout:
  file.managed:
    - contents: '10mins'
    - mode: 644
    - template: jinja
    - require:
      - pkg: mesos-packages
