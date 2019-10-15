default['dnf-automatic']['conf'].tap do |conf|
  conf['commands']['upgrade_type'] = 'default'
  conf['commands']['random_sleep'] = 0
  conf['commands']['download_updates'] = 'yes'
  conf['commands']['apply_updates'] = 'yes'
  conf['emitters']['emit_via'] = 'stdio'
  conf['email']['email_from'] = 'root@example.com'
  conf['email']['email_to'] = 'root'
  conf['email']['email_host'] = 'localhost'
  conf['command_email']['email_from'] = 'root@example.com'
  conf['command_email']['email_to'] = 'root'
  conf['base']['debuglevel'] = 1
end
