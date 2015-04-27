require 'light_mapper/version'

module LightMapper
  def mapping(mappings, opts = {})
    LightMapper.mapping(clone, mappings, opts)
  end

  def self.mapping(hash, mappings, opts = {})
    require_keys = opts[:require_keys] == true

    fetch_method = require_keys ? :fetch : :[]
    {}.tap do |h|
      mappings.each { |k, v| h[v] = hash.public_send(fetch_method, k) }
    end
  end
end
