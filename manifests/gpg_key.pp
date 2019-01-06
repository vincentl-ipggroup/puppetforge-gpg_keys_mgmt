# @summary: Define the GPG key based on the gpg_key Type
#
# Define the GPG key
########################################
# @param gpgdir PATH where to store the GPG key
# @param ensure Status of the GPG key
# @param keyname Name of the GPG key
# @param trustdb Name of the trustdb file
# @param key_type Type of GPG key
# @param trust_level Level of trust of the GPG public key
# @param key_data GPG armored key value
########################################
define gpg_keys_mgmt::gpg_key (
  String                                                                     $gpgdir,
  Enum['absent','present']                                                   $ensure      = present,
  String                                                                     $keyname     = $title,
  Optional[String]                                                           $trustdb     = 'trustdb.gpg',
  Optional[Enum['public','secure']]                                          $key_type    = 'public',
  Optional[Enum['unknown','undefined','never','marginal','full','ultimate']] $trust_level = 'ultimate',
  Optional[String]                                                           $key_data    = undef,
){

  gpg_key { $keyname:
    ensure      => $ensure,
    gpgdir      => $gpgdir,
    trustdb     => $trustdb,
    key_type    => $key_type,
    trust_level => $trust_level,
    key_data    => $key_data,
  }
}
