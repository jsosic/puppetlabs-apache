# Definition: apache::vhostsimple
#
# This class installs Apache Virtual Hosts
#
# Parameters:
# - The $port to configure the host on
# - The $docroot provides the DocumentationRoot variable
# - The $serveradmin will specify an email address for Apache that it will
#   display when it renders one of it's error pages
# - The $ssl option is set true or false to enable SSL for this Virtual Host
# - The $template option specifies whether to use the default template or
#   override
# - The $priority of the site
# - The $servername is the primary name of the virtual host
# - The $serveraliases of the site
# - The $options for the given vhost
# - The $override for the given vhost (array of AllowOverride arguments)
# - The $vhost_name for name based virtualhosting, defaulting to *
# - The $logroot specifies the location of the virtual hosts logfiles, default
#   to /var/log/<apache log location>/
# - The $ensure specifies if vhost file is present or absent.
#
# Actions:
# - Install Apache Virtual Hosts
#
# Requires:
# - The apache class
#
# Sample Usage:
#  apache::vhost { 'site.name.fqdn':
#    priority => '20',
#    port => '80',
#    docroot => '/path/to/docroot',
#  }
#
define apache::vhostsimple(
    $docroot,
    $ensure               = present,
    $ip_based             = false,
    $add_listen           = true,
    $ip                   = undef,
    $port                 = undef,
    $docroot_owner        = 'root',
    $docroot_group        = $::apache::params::root_group,
    $docroot_mode         = undef,
    $serveradmin          = undef,
    $directoryindex       = false,
    $ssl                  = false,
    $ssl_cert             = $::apache::default_ssl_cert,
    $ssl_key              = $::apache::default_ssl_key,
    $ssl_chain            = $::apache::default_ssl_chain,
    $ssl_ca               = $::apache::default_ssl_ca,
    $ssl_crl_path         = $::apache::default_ssl_crl_path,
    $ssl_crl              = $::apache::default_ssl_crl,
    $ssl_certs_dir        = $::apache::params::ssl_certs_dir,
    $ssl_protocol         = undef,
    $ssl_cipher           = undef,
    $ssl_honorcipherorder = undef,
    $ssl_verify_client    = undef,
    $ssl_verify_depth     = undef,
    $ssl_options          = undef,
    $ssl_proxyengine      = false,
    $template             = '',
    $priority             = 'vhost',
    $servername           = $name,
    $serveraliases        = [],
    $redirect_ssl         = false,
    $options              = ['Indexes','FollowSymLinks','MultiViews'],
    $override             = ['none'],
    $vhost_name           = '*',
    $logroot              = $::apache::logroot,
    $ensure               = 'present',
    $configure_firewall   = true,
  ) {

  $apache_name = $::apache::params::apache_name
  validate_re($ensure, '^(present|absent)$', "${ensure} is not supported for ensure. Allowed values are 'present' and 'absent'.")
  if $ssl == true { include ::apache::mod::ssl }


  # This ensures that the docroot exists
  # But enables it to be specified across multiple vhost resources
  if ! defined(File[$docroot]) {
    file { $docroot:
      ensure => directory,
      owner  => $docroot_owner,
      group  => $docroot_group,
    }
  }

  # Same as above, but for logroot
  if ! defined(File[$logroot]) {
    file { $logroot:
      ensure => directory,
    }
  }

  file { "${priority}-${name}.conf":
    ensure  => $ensure,
    path    => "${::apache::vhost_dir}/${priority}-${name}.conf",
    content => template($template),
    owner   => 'root',
    group   => $::apache::params::root_group,
    mode    => '0644',
    require => [
      Package['httpd'],
      File[$docroot],
      File[$logroot],
    ],
    notify  => Service['httpd'],
  }
  if $::osfamily == 'Debian' {
    $vhost_enable_dir = $::apache::vhost_enable_dir
    $vhost_symlink_ensure = $ensure ? {
      present => link,
      default => $ensure,
    }
    file{ "${priority}-${name}.conf symlink":
      ensure  => $vhost_symlink_ensure,
      path    => "${vhost_enable_dir}/${priority}-${name}.conf",
      target  => "${::apache::vhost_dir}/${priority}-${name}.conf",
      owner   => 'root',
      group   => $::apache::params::root_group,
      mode    => '0644',
      require => File["${priority}-${name}.conf"],
      notify  => Service['httpd'],
    }
  }

  if $ip {
    if $port {
      $listen_addr_port = "${ip}:${port}"
      $nvh_addr_port = "${ip}:${port}"
    } else {
      $nvh_addr_port = $ip
      if ! $servername and ! $ip_based {
        fail("Apache::Vhost[${name}]: must pass 'ip' and/or 'port' parameters for name-based vhosts")
      }
    }
  } else {
    if $port {
      $listen_addr_port = $port
      $nvh_addr_port = "${vhost_name}:${port}"
    } else {
      $nvh_addr_port = $name
      if ! $servername {
        fail("Apache::Vhost[${name}]: must pass 'ip' and/or 'port' parameters, and/or 'servername' parameter")
      }
    }
  }
  if $add_listen {
    if $ip and defined(Apache::Listen[$port]) {
      fail("Apache::Vhost[${name}]: Mixing IP and non-IP Listen directives is not possible; check the add_listen parameter of the apache::vhost define to disable this")
    }
    if ! defined(Apache::Listen[$listen_addr_port]) and $listen_addr_port and $ensure == 'present' {
      ::apache::listen { $listen_addr_port: }
    }
  }
  if ! $ip_based {
    if ! defined(Apache::Namevirtualhost[$nvh_addr_port]) {
# and $ensure == 'present' and $apache_version < 2.4 {
      ::apache::namevirtualhost { $nvh_addr_port: }
    }
  }


}
