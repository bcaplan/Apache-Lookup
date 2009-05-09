require 'resolv'
require 'thread'
require 'yaml'
require 'time'

class ApacheLookup
  VERSION = '1.0.0'
  EXPIRATION = 1000000
  CACHE_PATH = 'cache.yml'
  IP_REGEX = /^((\d{1,3}\.){3}\d{1,3})\s/

  def initialize cache, path, thread_limit = 20
    @cache = cache
    @file = File.new(path)
    @thread_limit = thread_limit.to_i
    @log_lines = Array.new
    @queue = Queue.new
    @thread_pool = Array.new
  end

  def resolve_ip ip_address
    if @cache[ip_address].nil? || Time.parse(@cache[ip_address][:mtime]) < Time.now - EXPIRATION
      @cache[ip_address] = Hash.new
      @cache[ip_address][:url] = Resolv.getname ip_address
      @cache[ip_address][:mtime] = Time.now.to_s
    end
    @cache[ip_address][:url]
  end

  def read_log log = @file
    log.each_line do |line|
      puts line
      @log_lines << line.chomp
    end
  end

  def parse_line line
    line =~ IP_REGEX
    line.gsub!($1, resolve_ip($1))
  end
  
  def parse_log number_of_threads = @thread_limit
    @log_lines.each do |line|
      @queue << line
    end

    number_of_threads.times {
      @thread_pool << Thread.new do
        until @queue.empty?
          parse_line @queue.pop
        end
      end
    }
    
    @thread_pool.each { |t| t.join }
    @log_lines.each { |line| puts line }
  end

  def self.run threads, path
    cache = YAML.load_file CACHE_PATH
    @apache = ApacheLookup.new cache, path, threads
    @apache.read_log
    @apache.parse_log
  end
end

ApacheLookup.run(ARGV[0], ARGV[1])if $0 == __FILE__