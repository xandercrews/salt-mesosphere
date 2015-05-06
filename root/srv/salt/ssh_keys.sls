{% for key in pillar['ssh_keys'] %}

ssh_key_{{loop.index}}:
  ssh_auth.present:
    - user: {{ key['user'] }}
      source: {{ key['source'] }}

{% endfor %}
