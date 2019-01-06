# @summary This Class is the core of the module
#
########################################
# @param pkg_name Define the package managed by the module
# @param pkg_ensure Define the status of the package
# @param gpg_keys Type to manage the related gpg key
# @param tmp_dir Temporary folder to manage the keys
########################################
class gpg_keys_mgmt (
  String                                                        $pkg_name   = gnupg2,
  Enum['present','absent','purged','held','installed','latest'] $pkg_ensure = installed,
  String                                                        $tmp_dir    = '/tmp',
  Optional[array]                                               $gpg_keys   = undef,
){

  contain gpg_keys_mgmt::install

  #case $gpg_keys_mgmt::pkg_ensure {
  #  'absent', 'purged': {
  #      Class['gpg_keys_mgmt::install']
  #  }
  #  default: {
  #      Class['gpg_keys_mgmt::install']
  #  }
  #}

  Class['gpg_keys_mgmt::install']
  -> create_resources ( 'gpg_keys_mgmt::gpg_key', $gpg_keys)
}
