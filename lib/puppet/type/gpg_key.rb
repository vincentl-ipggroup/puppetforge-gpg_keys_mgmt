# @summary Define the type gpg_key
Puppet::Type.newtype(:gpg_key) do
  @doc = 'GPG Key type'

  ensurable

  newparam(:title, namevar: true) do
    desc 'GPG Key Name'
  end

  newproperty(:gpgdir) do
    desc 'PATH of the GPG key'
    isrequired
    validate do |value|
      unless value =~ %r{/^\/((\w+\-?\w*)(\/)?)+}
        raise ArgumentError, '%s is not a valid PATH' % value
      end
    end
  end

  newproperty(:trustdb) do
    desc 'Define the name of the trust DB (default trustdb.gpg)'
    defaultto 'trustdb.gpg'
    validate do |value|
      unless value =~ %r{^\w+(\w*\-*)+\.(\w+)}
        raise ArgumentError, '%s is not a valid filename for the trust DB' % value
      end
    end
  end

  newparam(:key_type) do
    desc 'Type of your Key.'
    newvalues(:public, :secure)
    defaultto 'public'
  end

  newparam(:trust_level) do
    desc 'Level of trust of your Key.'
    newvalues(:unknown, :undefined, :never, :marginal, :full, :ultimate)
    defaultto 'ultimate'
  end

  newparam(:key_data) do
    desc 'Content of the Key'
    newvalues(%r{.+})
  end
end
