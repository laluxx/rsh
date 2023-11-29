#!/usr/bin/env ruby

require 'io/console'
require 'fileutils'
require 'readline'

aliases = {
  "p" => "puts Dir.pwd",
  "bat" => "cat",
  "ll" => "exa -la",
  "ls" => "lsd",
  "fucking" => "sudo",
  "install" => "pacman -S",
  "get" => "sudo pacman -S",
  # more aliases...
}

functions = {
  "sum" => ->(args) { args.map(&:to_i).sum },

  "cat" => lambda do |args|
    filename = args[0]
    if filename.nil?
      "Error: No file specified"
    else
      expanded_filename = File.expand_path(filename)
      if !File.exist?(expanded_filename)
        "File not found: #{filename}"
      else
        pywal_colors = read_pywal_colors
        background_color = pywal_colors[:background]
        text_color = pywal_colors[:text]

        File.readlines(expanded_filename).each do |line|
          highlighted_line = line.gsub(/#([A-Fa-f0-9]{6})/) do |color_code|
            if color_code.downcase == text_color.downcase
              # If text color matches the color code, use background color for text
              "\e[38;2;#{background_color[1..2].to_i(16)};#{background_color[3..4].to_i(16)};#{background_color[5..6].to_i(16)};48;2;#{color_code[1..2].to_i(16)};#{color_code[3..4].to_i(16)};#{color_code[5..6].to_i(16)}m#{color_code}\e[0m"
            else
              "\e[48;2;#{color_code[1..2].to_i(16)};#{color_code[3..4].to_i(16)};#{color_code[5..6].to_i(16)}m#{color_code}\e[0m"
            end
          end
          puts highlighted_line
        end
        nil  # Return nil to avoid printing anything extra
      end
    end
  end
  # More functions...
}

def read_pywal_colors
  wal_colors_file = File.expand_path('~/.cache/wal/colors')
  if File.exist?(wal_colors_file)
    colors = File.readlines(wal_colors_file).map(&:chomp)
    { background: colors[0], text: colors[7] }
  else
    { background: '#000000', text: '#FFFFFF' } # Default colors if file not found TODO
  end
end


def substitute_aliases(command, aliases)
  command.split.map { |word| aliases.fetch(word, word) }.join(" ")
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
    puts functions[command_name].call(args)
  elsif command.strip.start_with?("cd ")
    dir = args[0] || ENV['HOME']
    begin
      Dir.chdir(dir)
    rescue SystemCallError => e
      puts "Error changing directory: #{e}"
    end
  elsif valid_system_command?(command)
    begin
      system(command)
    rescue Interrupt
      puts "\nCommand interrupted"
    end
  else
    begin
      eval(command)
    rescue SyntaxError, NameError => e
      puts "rsh: command not found: #{command}"
    rescue Interrupt
      puts "\nRuby evaluation interrupted"
    end
  end
end

# History file handling
HISTORY_FILE = File.expand_path('~/.config/rsh/history')
FileUtils.mkdir_p(File.dirname(HISTORY_FILE))
Readline::HISTORY.push(*File.readlines(HISTORY_FILE).map(&:chomp))

# Tab Completion (optional)
Readline.completion_proc = proc do |s|
  Dir["#{s}*"].grep(/^#{Regexp.escape(s)}/)
end

# Main loop
begin
  puts "Welcome to the crystal shell - Type 'exit' to quit."

  Signal.trap("SIGINT") do
    # Clear the current input buffer
    Readline.point = 0
    Readline.delete_text
    Readline.redisplay

    # Move to a new line and show the prompt
    puts "\n"
    print "❯ "
  end

  while input = Readline.readline("❯ ", false)  # Set 'false' to not add to history automatically
    break if input.nil? || input == "exit"

    # Remove duplicates and add non-empty commands to history manually
    unless input.strip.empty?
      run_command(input, aliases, functions)
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
