require "test_helper"

class StateStoreTest < Minitest::Spec
  class CustomError < StandardError
  end

  class FileStore
    @file_name = 'tmp.marshal'

    def self.get(tag)
      with_file('rb') do |file|
        states = Marshal.load(file)
        states[tag]
      end
    end

    def self.update(tag, state)
      states = {}
      with_file('rb') do |file|
        states = Marshal.load(file)
      end

      states[tag] = state

      Marshal.dump(states, File.new(@file_name, 'wb')).close
    end

    def self.with_file(mode, &block)
      file = File.open(@file_name, mode)
      begin
        block.call(file)
      ensure
        file.close
      end
    end

    def self.prepare!
      # clear and set initial value
      Marshal.dump({}, File.new(@file_name, 'wb')).close
    end

    def self.clear
      File.delete(@file_name) rescue nil
    end
  end


  before :each do
    Rcb::StateStore::InMemory.clear
    FileStore.clear
    Rcb::Configurations.clear

    Rcb.configure('example.com') do |config|
      config.open_condition(max_failure_count: 1, window_msec: 1000)
      config.reset_timeout_msec 200
    end
  end

  def test_in_memory_state_store
    cb = Rcb.for('example.com')
    cb2 = Rcb.for('example.com')
    assert_equal cb.state, :close
    assert_equal cb2.state, :close

    Thread.new do
      assert_raises(CustomError) { cb.run! { raise CustomError } }
      assert_equal cb.state, :open
    end.run

    Thread.new do
      sleep 0.1
      assert_equal cb2.state, :open
    end.run

    sleep 1
    assert_equal cb.state, :half_open
    assert_equal cb2.state, :half_open
  end

  def test_file_store_multi_process
    FileStore.prepare!

    cb = Rcb.for('example.com', state_store: FileStore)
    cb2 = Rcb.for('example.com', state_store: FileStore)
    assert_equal cb.state, :close
    assert_equal cb2.state, :close

    # multi process

    Process.fork do
      assert_raises(CustomError) { cb.run! { raise CustomError } }
      assert_equal cb.state, :open
    end

    Process.fork do
      sleep 0.1
      assert_equal cb2.state, :open
    end

    Process.waitall

    sleep 1
    assert_equal cb.state, :half_open
    assert_equal cb2.state, :half_open
  end
end
