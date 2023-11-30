# TODO

## Evil mode
- [ ] it takes 2 keystrokes to go in NORMAL mode
- [ ] keychords in normal mode
- [x] cursor color change based on mode (and stay a block)

## General
- [ ] Ctrl-backspace delete all to the left 
- [ ] Dont depend on pywal, simply grab the first 16 colors somehow
- [ ] Kill existing rsh process when spawning a new one from rsh or probably we should kill any other shell idk the standard
- [ ] `cd rsh && ls` DONT work for some reason
- [ ] `2+2` should print automatically without even pressing RET (like node)
- [ ] Better prompt show git info and cool icons (like starship)
- [ ] Syntax highlighting for ruby & Commands red for non existing and green for existing
- [ ] make loops possible by writing a new line instead of immediate execution (like xonsh)
- [ ] Cool stuff like `p = pwd`
- [ ] aliases and functions should be in `~/.config/rsh/config.rb`
- [x] Ctrl-z should not kill the shell

## Functions
- [ ] while this file doesnt exist do
- [ ] while this file exist do
- [ ] for 10 do
- [ ] for 3 seconds do?
- [ ] for a do
- [ ] function to add permanent functions
- [ ] function to add permanent aliases 

## Done
- [x] Aliases
- [x] Functions
- [x] Keybinds like ctrl+l up arrow down arrow
- [x] Prompt color based on success or fail



# Old version
too high level
```ruby
require 'readline'
# History
HISTORY_FILE = File.expand_path('~/.config/rsh/history')
FileUtils.mkdir_p(File.dirname(HISTORY_FILE))
Readline::HISTORY.push(*File.readlines(HISTORY_FILE).map(&:chomp))

# Tab Completion
Readline.completion_proc = proc do |s|
  Dir["#{s}*"].grep(/^#{Regexp.escape(s)}/)
end

last_command_success = nil
# Main loop
begin
  puts "Welcome to the crystal shell - Type 'exit' to quit."

  Signal.trap("SIGINT") do
    last_command_success = true
    Readline.point = 0
    Readline.delete_text
    Readline.redisplay
    puts "\n"
    print "#{RESET_COLOR}❯ "
  end

  while input = Readline.readline("#{last_command_success.nil? ? '' : (last_command_success ? GREEN : RED)}❯ #{RESET_COLOR}", false)
    break if input.nil? || input == "exit"

    # Remove duplicates and add non-empty commands to history manually
    unless input.strip.empty?
      # Run the command and update the success status
      last_command_success = run_command(input, aliases, functions)
      Readline::HISTORY.pop if Readline::HISTORY.length > 0 && Readline::HISTORY[-1] == input
      Readline::HISTORY.push(input)
    end
  end
ensure
  # Save the history when exiting
  File.open(HISTORY_FILE, 'w') do |file|
    Readline::HISTORY.to_a.last(100).each { |cmd| file.puts(cmd) }
  end
end
```
