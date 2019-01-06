# @summary This class manages the package installation
# 
# All variables are managed from the Class gpg_key_mgmt
########################################
class gpg_keys_mgmt::install {

  package { $gpg_keys_mgmt::pkg_name:
    ensure => $gpg_keys_mgmt::pkg_ensure,
  }

}
