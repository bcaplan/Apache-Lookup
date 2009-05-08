require 'resolv'
require 'yaml'
require 'time'

class ApacheLookup
  VERSION = '1.0.0'
  EXPIRATION = 1000000
  
  attr_accessor :cache
  
  def initialize cache
    @cache = cache
  end
  
  def resolve_ip ip_address
    unless @cache[ip_address] && Time.parse(@cache[ip_address][:mtime]) < Time.now + EXPIRATION
      @cache[ip_address][:url] = Resolv.getname ip_address
      @cache[ip_address][:mtime] = Time.now
    else
      @cache[ip_address]
    end
  end
end
