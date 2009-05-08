require "test/unit"
require "apache_lookup"

class TestApacheLookup < Test::Unit::TestCase
  def setup
    @test_log = StringIO.new(File.read('./test/test_log.txt'))
    cache = YAML.load_file('test/cache.yml')
    
    # Aliasing Resolv.getname in the test to return predictable result from any ip
    Resolv.class_eval('alias :getname_orig :getname')
    def Resolv.getname ip
      ip.gsub('.', '') + '.com'
    end
    
    @apache = ApacheLookup.new cache
    # @test_log.each_line {|line| puts "#{@test_log.lineno}: #{line}"}
  end
  
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
  
  # def test_finds_and_stores_ips_and_lines
  #   expected = { '208.77.188.166' => [0, 4, 7], '75.119.201.189' => []}
  #   actual = ApacheLookup.gather @test_log
  #   
  #   
  #   assert_equal expected, actual
  # end
end
