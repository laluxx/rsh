#!/usr/bin/env ruby

# TODO
# 2+2 should print automatically without even pressing RET (like node)
# Better prompt show git info and cool icons (like starship)
# Keybinds like ctrl+l up arrow down arrow
# Syntax highlighting for ruby && Commands red for non existing and green for existing
# make loops possible by writing a new line instead of immediate execution
# Cool stuff like p = pwd
# aliases and functions should be in ~/.config/rsh/config.rb
# Aliases DONE
# Functions DONE


aliases = {
  "p" => "puts Dir.pwd",
  "ll" => "exa -la",  # Maybe check for dependencies and fall back to ls exa is not installed
  "ls" => "lsd",  # Same here
  "fucking" => "sudo",
  "install" => "pacman -S",
  "get" => "sudo pacman -S",
  # more aliases...
}

functions = {
  "pacman" => ->(args) { args.map(&:to_i).sum },

  "divide" => lambda do |args|
    return "Error: Needs two arguments" if args.length != 2
    numerator = args[0].to_f
    denominator = args[1].to_f
    return "Error: Division by zero" if denominator == 0
    result = numerator / denominator
    result
  end,
  # More functions here...
}

def substitute_aliases(command, aliases)
  command_words = command.split
  substituted_command = command_words.map do |word|
    aliases.key?(word) ? aliases[word] : word
  end
  substituted_command.join(" ")
end

def valid_system_command?(command)
  return false if command.strip.start_with?("cd ")
  system_command = command.split.first
  system("command -v #{system_command} >/dev/null 2>&1")
end

def run_command(command, aliases, functions)
  command = substitute_aliases(command, aliases)
  command_name, *args = command.split

  if functions.key?(command_name)
    # Execute user-defined function with arguments
    puts functions[command_name].call(args)
  elsif command.strip.start_with?("cd ")
    # Handling 'cd' command
    dir = command.split[1] || ENV['HOME']
    begin
      Dir.chdir(dir)
    rescue SystemCallError => e
      puts "Error changing directory: #{e}"
    end
  elsif valid_system_command?(command)
    # Execute valid system command
    system(command)
  else
    # Evaluate as Ruby code if not a system command
    begin
      eval(command)
    rescue SyntaxError, NameError => e
      puts "rsh: command not found: #{command}"
    end
  end
end

puts "Welcome to the crystal clear shell - Type 'exit' to quit."
loop do
  print "❯ "
  input = gets.chomp

  break if input == "exit"

  run_command(input, aliases, functions)
end
