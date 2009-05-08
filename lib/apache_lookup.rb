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
    if @cache[ip_address].nil? || Time.parse(@cache[ip_address][:mtime]) < Time.now + EXPIRATION
      @cache[ip_address] = Hash.new
      @cache[ip_address][:url] = Resolv.getname ip_address
      @cache[ip_address][:mtime] = Time.now.to_s
    end
    @cache[ip_address][:url]
  end

  def self.run
    cache = 'file'
    ApacheLookup.new cache
  end
end
