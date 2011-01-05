Before do
  @aruba_io_wait_seconds = 2
  @fake_home = Dir::Tmpname.create('keyrack') { }
  Dir.mkdir(@fake_home)
  @old_home = ENV['HOME']
  ENV['HOME'] = @fake_home
end

After do
  ENV['HOME'] = @old_home
  FileUtils.rm_rf(@fake_home)
end

When /I run keyrack interactively/ do
  @out, @in, @pid = PTY.spawn("bundle exec ruby -Ilib bin/keyrack")
end

Then /the output should contain "([^"]+)"/ do |expected|
  if @slept
    @slept = false
  else
    sleep 1
  end
  @output = @out.read_nonblock(255)
  @output.should include(expected)
end

Then %r{the output should match /([^/]+)/} do |expected|
  # This won't work for escaped backslashes
  if @slept
    @slept = false
  else
    sleep 1
  end
  @output = @out.read_nonblock(255)
  @output.should match(Regexp.new(expected))
end

Then /the output should also contain "([^"]+)"/ do |expected|
  @output.should include(expected)
end

When /I type "([^"]+)"/ do |text|
  @in.puts(text)
end

When /I wait a few seconds/ do
  sleep 5
  @slept = true
end

Then /my clipboard should contain "([^"]+)"/ do |expected|
  sleep 1
  result = %x{xclip -selection clipboard -o}.chomp
  result.should == expected
end
