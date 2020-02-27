require "test_helper"

class StateStoreTest < Minitest::Spec
  class CustomError < StandardError
  end

  class FileStore
    class << self
      FILE_NAME = 'tmp.marshal'.freeze

      def get(tag)
        read[tag]
      end

      def update(tag, state)
        states = read
        states[tag] = state
        write(states)
      end

      def prepare!
        # clear and set initial value
        write({})
      end

      def clear
        File.delete(FILE_NAME) rescue nil
      end

      private

        def write(obj)
          File.open(FILE_NAME, 'wb') { |file| Marshal.dump(obj, file) }
        end

        def read
          File.open(FILE_NAME, 'rb') { |file| Marshal.load(file) }
        end
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
