class apache::mod::perl {
  include ::apache
  ::apache::mod { 'perl': }
  # Template uses no variables
  file { 'perl.conf':
    ensure  => file,
    mode    => $::apache::file_mode,
    path    => "${::apache::mod_dir}/perl.conf",
    content => template('apache/mod/perl.conf.erb'),
    require => Exec["mkdir ${::apache::mod_dir}"],
    before  => File[$::apache::mod_dir],
    notify  => Class['apache::service'],
  }
}
