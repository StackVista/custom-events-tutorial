file { '/var/www/html':
  ensure => directory,
}

file { '/var/www':
  ensure => directory,
}

file { '/var/www/html/info.php':
  ensure => file,
  content => '<?php  phpinfo(); ?>'
}
