require 'helper'
require 'pty'
require 'stringio'

class TestInteractiveConsole < Test::Unit::TestCase
  def setup
    @keyrack_dir = Dir::Tmpname.create('keyrack') { }
    Dir.mkdir(@keyrack_dir)
    @all_data = ""
  end

  def teardown
    FileUtils.rm_rf(@keyrack_dir)
    if @pid
      begin
        Process.kill("TERM", @pid)
      rescue Errno::ESRCH
      end
    end
  end

  def assert_output_matches(pattern, sentinel = "\r\n", timeout = 1, debug = false)
    assert_match pattern, get_output(sentinel, timeout, debug)
  end

  def assert_output_equals(expected, timeout = 1, debug = false)
    assert_equal expected, get_output(expected, timeout, debug)
  end

  def get_output(sentinel = "\r\n", timeout = 1, debug = false)
    output = ""
    until output.end_with?(sentinel)
      begin
        data = @out.read_nonblock(1)
        output << data
        if debug
          $stderr.print(data)
          $stderr.flush
        end
        @all_data << data
      rescue Errno::EIO
        flunk "Command terminated prematurely."
      rescue IO::WaitReadable
        if IO.select([@out], [], [], timeout).nil?
          flunk "Output timed out."
        else
          retry
        end
      end
    end
    output
  end
  alias :eat_output :get_output

  def run_keyrack
    @out, @in, @pid = PTY.spawn(%{bundle exec ruby -Ilib bin/keyrack -d "#{@keyrack_dir}"})
  end

  def send_input(string, hidden = false)
    @in.puts(string)

    # Eat the echo
    chomp = hidden ? "\r\n\r\n" : "\r\n"
    get_output(string + chomp)
  end

  def clipboard
    Clipboard.paste
  end

  test "keyrack session" do
    run_keyrack

    assert_output_matches /first time/
    assert_output_equals "New passphrase: "
    send_input "secret", true

    assert_output_equals "Confirm passphrase: "
    send_input "secret", true

    menu = get_output("? ")
    assert_match /Choose storage type:/, menu
    assert_match /filesystem/, menu
    assert_match /ssh/, menu
    send_input "filesystem"

    menu = get_output("? ")
    assert_match /Keyrack Main Menu/, menu
    assert_match /Mode: copy/, menu
    assert_match "[n]ew", menu
    send_input "n"

    assert_output_equals "Label: "
    send_input "Foo"
    assert_output_equals "Username: "
    send_input "dude"
    assert_output_equals "Generate password? [ync] "
    send_input "n"
    assert_output_equals "Password: "
    send_input "secret", true
    assert_output_equals "Password (again): "
    send_input "secret", true

    menu = get_output("? ")
    assert_match "1. Foo [dude]", menu
    send_input "1"
    assert_equal "secret", clipboard

    menu = get_output("? ")
    assert_match "[g]roup", menu
    send_input "g"
    assert_output_equals "Group: "
    send_input "Stuff"

    menu = get_output("? ")
    assert_match "Stuff", menu.lines.first
    assert_match "[g]roup", menu
    send_input "g"
    assert_output_equals "Group: "
    send_input "More Stuff"

    menu = get_output("? ")
    assert_match "More Stuff", menu.lines.first
    assert_match "[u]p", menu
    send_input "u"

    menu = get_output("? ")
    assert_match "Stuff", menu.lines.first
    assert_match "[t]op", menu
    send_input "t"

    menu = get_output("? ")
    assert_match "Keyrack Main Menu", menu.lines.first
    assert_match "[s]ave", menu
    send_input "s"
    assert_output_equals "Keyrack password: "
    send_input "secret"

    menu = get_output("? ", 10)
    assert_match "[q]uit", menu
    send_input "q"

    Process.waitpid(@pid)
  end

  test "entering in wrong password" do
    run_keyrack

    assert_output_matches /first time/
    assert_output_equals "New passphrase: "
    send_input "secret", true

    assert_output_equals "Confirm passphrase: "
    send_input "secret", true

    menu = get_output("? ")
    assert_match /Choose storage type:/, menu
    assert_match /filesystem/, menu
    assert_match /ssh/, menu
    send_input "filesystem"

    menu = get_output("? ")
    assert_match /Keyrack Main Menu/, menu
    assert_match /Mode: copy/, menu
    assert_match "[n]ew", menu
    send_input "n"

    assert_output_equals "Label: "
    send_input "Foo"
    assert_output_equals "Username: "
    send_input "dude"
    assert_output_equals "Generate password? [ync] "
    send_input "n"
    assert_output_equals "Password: "
    send_input "secret", true
    assert_output_equals "Password (again): "
    send_input "secret", true

    menu = get_output("? ")
    assert_match /Keyrack Main Menu/, menu
    assert_match /Mode: copy/, menu
    assert_match "[s]ave", menu
    send_input "s"

    assert_output_equals "Keyrack password: "
    send_input "secret", true

    menu = get_output("? ", 10)
    assert_match "[q]uit", menu
    send_input "q"

    Process.waitpid(@pid)

    run_keyrack

    assert_output_equals "Keyrack password: "
    send_input "wrong", true
    assert_output_equals "Invalid password.", 10

    Process.waitpid(@pid)
  end
end
