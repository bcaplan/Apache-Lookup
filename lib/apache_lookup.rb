require 'resolv'
require 'thread'
require 'yaml'
require 'time'
require 'timeout'
require 'fileutils'

class ApacheLookup
  VERSION = '1.0.0'
  EXPIRATION = 1000000
  DEFAULT_THREADS = 10
  TIMEOUT = 0.5
  CACHE_PATH = 'cache.yml'
  IP_REGEX = /^((\d{1,3}\.){3}\d{1,3})\s/

  def initialize cache, path, thread_limit = DEFAULT_THREADS
    @cache = cache
    @path = path
    @file = File.new(path)
    @thread_limit = thread_limit.to_i
    @log_lines = Array.new
    @queue = Queue.new
    @count = 0
  end

  def resolve_ip ip_address
    if @cache[ip_address].nil? || @cache[ip_address][:mtime].nil? || Time.parse(@cache[ip_address][:mtime]) < Time.now - EXPIRATION
      @cache[ip_address] = Hash.new

      begin
        timeout(TIMEOUT) do
          @cache[ip_address][:url] = Resolv.getname ip_address
        end
      rescue Resolv::ResolvError, Resolv::ResolvTimeout, Timeout::Error
        @cache[ip_address][:url] = ip_address
      end

      @cache[ip_address][:mtime] = Time.now.to_s

    end
    @cache[ip_address][:url]
  end

  def read_log log = @file
    log.each_line do |line|
      @log_lines << line.chomp
    end
  end

  def parse_line line
    @count += 1
    print "\rProcessed: #{@count}"
    STDOUT.flush
    line =~ IP_REGEX
    # puts $1.to_s.inspect
    begin
      line.gsub!($1, resolve_ip($1))
    rescue TypeError
      return if $1.nil?
      sleep 0.1
      line.gsub!($1, resolve_ip($1))
    end
  end

  def parse_log number_of_threads = @thread_limit
    @log_lines.each do |line|
      @queue << line
    end

    thread_pool = Array.new

    number_of_threads.times {
      thread_pool << Thread.new do
        until @queue.empty?
          parse_line @queue.pop
        end
      end
    }

    thread_pool.each { |t| t.join }
  end
  
  def write_file log = @path, data = @log_lines
    File.open(log, 'w') do |file|
      file.truncate(0)

      data.each do |line|
        file.puts line
      end
      file.close
    end
  end

  def write_cache
    open(CACHE_PATH, 'w') { |f| YAML.dump(@cache, f) }
  end

  def self.run threads, path
    unless File.exist? CACHE_PATH
      FileUtils.touch CACHE_PATH
      open(CACHE_PATH, 'w') { |f| YAML.dump({'127.0.0.1' => {:url => 'localhost', :mtime => Time.now} }, f) }
    end
    cache = YAML.load_file CACHE_PATH
    @apache = ApacheLookup.new cache, path, threads
    @apache.read_log
    @apache.parse_log
    # @apache.write_file
    @apache.write_cache
  end
end



ApacheLookup.run(ARGV[0], ARGV[1])if $0 == __FILE__