require "test/unit"
require "apache_lookup"

# Mocking Resolv.getname
class Resolv
  alias :getname_orig :getname
  def self.getname ip
    ip.gsub('.', '') + '.com'
  end
end

# Add accessors so we can verify info in tests
class ApacheLookup
  attr_accessor :cache, :log_lines
end

class TestApacheLookup < Test::Unit::TestCase
  def setup
    @test_log = StringIO.new(File.read('./test/small_log.txt'))
    @test_line = '208.77.188.166 - - [29/Apr/2009:16:07:38 -0700] "GET / HTTP/1.1" 200 1342'
    cache = YAML.load_file('test/cache.yml')

    @apache = ApacheLookup.new cache
    # @test_log.each_line {|line| puts "#{@test_log.lineno}: #{line}"}
  end

  # resolve_ip and cache tests
  def test_pulls_from_cache_if_in_cache_and_not_expired
    actual = @apache.resolve_ip '1.1.1.1'

    assert_equal '1111.org', actual
  end

  def test_resolves_ip_if_not_in_cache
    actual = @apache.resolve_ip '1.1.1.2'

    assert_equal '1112.com', actual
  end

  def test_resolves_ip_if_expired
    actual = @apache.resolve_ip '1.1.1.3'

    assert_equal '1113.com', actual
  end

  def test_caches_ip_if_expired
    @apache.resolve_ip '1.1.1.4'
    actual = @apache.cache['1.1.1.4'][:url]

    assert_equal '1114.com', actual
  end

  def test_caches_ip_if_not_in_cache
    @apache.resolve_ip '1.1.1.5'
    actual = @apache.cache['1.1.1.5'][:url]

    assert_equal '1115.com', actual
  end

  def test_updates_mtime_when_cache_updated
    @apache.resolve_ip '1.1.1.3'
    actual = @apache.cache['1.1.1.3'][:mtime]

    assert_equal Time.now.to_s, actual
  end
  # End testing cache

  def test_parses_ip_and_replaces
    expected = '20877188166.com - - [29/Apr/2009:16:07:38 -0700] "GET / HTTP/1.1" 200 1342'
    actual = @apache.parse_line(@test_line)

    assert_equal expected, actual
  end

  def test_creates_array_from_log_lines
    expected = ['208.77.188.166 - - [29/Apr/2009:16:07:38 -0700] "GET / HTTP/1.1" 200 1342',
                '75.119.201.189 - - [29/Apr/2009:16:07:44 -0700] "GET /favicon.ico HTTP/1.1" 200 1406']

    @apache.read_log @test_log

    assert_equal expected, @apache.log_lines
  end

  def test_parses_log
    @apache.read_log @test_log
    @apache.parse_log

    expected = ['20877188166.com - - [29/Apr/2009:16:07:38 -0700] "GET / HTTP/1.1" 200 1342',
                '75119201189.com - - [29/Apr/2009:16:07:44 -0700] "GET /favicon.ico HTTP/1.1" 200 1406']

    assert_equal expected, @apache.log_lines
  end
end
