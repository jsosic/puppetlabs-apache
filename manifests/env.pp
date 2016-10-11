# Class: apache::env
class apache::env (
  $template = undef,
  $path     = undef,
){

  # we had to hack this way, to avoid poluting params.pp
  if ( $template ) {
    $template_final = $template
  } elsif $::osfamily == 'RedHat' or $::operatingsystem == 'amazon' {
    $template_final = 'apache/rhel.sysconfig.erb'
  } elsif $::osfamily == 'Debian' {
    $template_finale = 'apache/debian.envars.erb'
  }

  if ( $path ) {
    $path_final = $path
  } elsif $::osfamily == 'RedHat' or $::operatingsystem == 'amazon' {
    $path_final = '/etc/sysconfig/httpd'
  } elsif $::osfamily == 'Debian' {
    $path_final = '/etc/apache2/envvars'
  }

  $maxopenfiles = $::apache::maxopenfiles
  $umask        = $::apache::umask

  file { '/etc/sysconfig/httpd':
    ensure  => file,
    path    => $path_final,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template($template_final),
    notify  => Service['httpd'],
    require => Package['httpd'],
  }
 
}
