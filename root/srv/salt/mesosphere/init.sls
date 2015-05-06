mesosphere-repos:
  pkgrepo.managed:
    - humanname: Mesosphere APT
    - name: deb http://repos.mesosphere.io/ubuntu trusty main
    - dist: trusty
    - file: /etc/apt/sources.list.d/mesosphere.list
    - keyid: E56151BF
    - keyserver: keyserver.ubuntu.com
    - require_in:
      - pkg: mesos-packages

mesos-packages:
  pkg.latest:
    - pkgs:
      - mesos
      - marathon
      - chronos
