{% for hostname, addrs in salt['mine.get']('*', 'network.ip_addrs', expr_form='glob').iteritems() %}
{{ hostname }}:
  host.present:
   - ip: {{ addrs[0] }}
{%- endfor %}
