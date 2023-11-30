#!/usr/bin/env ruby

require 'io/console'
require 'fileutils'


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


def read_pywal_colors
  wal_colors_file = File.expand_path('~/.cache/wal/colors')
  if File.exist?(wal_colors_file)
    colors = File.readlines(wal_colors_file).map(&:chomp)
    { background: colors[0], text: colors[7] }
  else
    { background: '#000000', text: '#FFFFFF' } # Default colors if file not found TODO
  end
end

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

TRUE_GREEN = "\e[38;2;0;255;0m"
TRUE_RED = "\e[38;2;255;0;0m"


BLACK   = "\e[30m"
RED     = "\e[31m"
GREEN   = "\e[32m"
YELLOW  = "\e[33m"
BLUE    = "\e[34m"
MAGENTA = "\e[35m"
CYAN    = "\e[36m"
WHITE   = "\e[37m"
RESET_COLOR = "\e[0m"

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
    true
  elsif command.strip.start_with?("cd ")
    dir = args[0] || ENV['HOME']
    begin
      Dir.chdir(dir)
      true
    rescue SystemCallError => e
      puts "Error changing directory: #{e}"
      false
    end
  elsif valid_system_command?(command)
    begin
      system(command)
    rescue Interrupt
      puts "\nCommand interrupted"
      false
    else
      true
    end
  else
    begin
      eval(command)
      true
    rescue SyntaxError, NameError => e
      puts "rsh: command not found: #{command}"
      false
    rescue Interrupt
      puts "\nRuby evaluation interrupted"
      false
    end
  end
end


# Constants and Setup
HISTORY_FILE = File.expand_path('~/.config/rsh/history')
FileUtils.mkdir_p(File.dirname(HISTORY_FILE))
history = File.readlines(HISTORY_FILE).map(&:chomp)
history_index = history.length

INSERT_MODE = :insert
NORMAL_MODE = :normal
current_mode = INSERT_MODE

# Custom input handling
def custom_readline(prompt, history, history_index)
  print prompt
  input = ''
  cursor_position = 0

  while char = STDIN.raw(&:getch)
    case char
    when "\r" # Enter key
      puts
      return input, history_index
    when "\u007F", "\b" # Backspace key
      if cursor_position > 0
        input.slice!(-1)
        cursor_position -= 1
        print "\b \b"
      end
    when "\e" # Escape sequence
      next_char = STDIN.getch
      if next_char == '['
        arrow_key = STDIN.getch
        case arrow_key
        when 'A' # Up arrow
          if history_index > 0
            history_index -= 1
            input = history[history_index]
            print "\r#{prompt}#{input}#{" " * [0, cursor_position - input.length].max}"
            cursor_position = input.length
          end
        when 'B' # Down arrow
          if history_index < history.length - 1
            history_index += 1
            input = history[history_index]
            print "\r#{prompt}#{input}#{" " * [0, cursor_position - input.length].max}"
            cursor_position = input.length
          end
        end
      else
        return :switch_mode, input, history_index
      end
    when "\u0003" # Ctrl+C
      exit 0
    when "\u000C" # Ctrl+L
      system("clear")
      print prompt + input
    else
      input << char
      cursor_position += 1
      print char
    end
  end
end

# Handling input in normal mode
def handle_normal_mode_input
  while char = STDIN.raw(&:getch)
    case char
    when "i"
      return :switch_mode
    when "h"  # Left
      print "\e[D"
    when "j"  # Down
      print "\e[B"
    when "k"  # Up
      print "\e[A"
    when "l"  # Right
      print "\e[C"
    end
  end
end





def extract_pywal_colors
  wal_colors_file = File.expand_path('~/.cache/wal/colors')
  colors = {}

  if File.exist?(wal_colors_file)
    wal_colors = File.readlines(wal_colors_file).map(&:chomp)
    colors.merge!(
      BLACK: wal_colors[0],
      RED: wal_colors[1],
      GREEN: wal_colors[2],
      YELLOW: wal_colors[3],
      BLUE: wal_colors[4],
      MAGENTA: wal_colors[5],
      CYAN: wal_colors[6],
      WHITE: wal_colors[7]
    )
  end
  colors
end

pywal = extract_pywal_colors

BLACK_WAL = pywal[:BLACK]
RED_WAL = pywal[:RED]
GREEN_WAL = pywal[:GREEN]
YELLOW_WAL = pywal[:YELLOW]
BLUE_WAL = pywal[:BLUE]
MAGENTA_WAL = pywal[:MAGENTA]
CYAN_WAL = pywal[:CYAN]
WHITE_WAL = pywal[:WHITE]



NORMAL_MODE_CURSOR_COLOR = BLUE_WAL
INSERT_MODE_CURSOR_COLOR = WHITE_WAL
# NORMAL_MODE_CURSOR_COLOR = "\e]12;red\a"   # It set the bg color ?
# INSERT_MODE_CURSOR_COLOR = "\e]12;green\a" # It set the bg color ?


# Main loop
begin
  puts "Welcome to the crystal shell - Type 'exit' to quit."
  last_command_success = true

  loop do
    if current_mode == INSERT_MODE
      # print INSERT_MODE_CURSOR_COLOR
      # print "\e]10;#{INSERT_MODE_CURSOR_COLOR}\a"  # Set text color
      print "\e]12;#{INSERT_MODE_CURSOR_COLOR}\a"  # Set cursor color


      prompt = "#{last_command_success ? GREEN : RED}❯ #{RESET_COLOR}"
      input, history_index = custom_readline(prompt, history, history_index)
      if input == :switch_mode
        current_mode = NORMAL_MODE
        next
      end
      break if input == "exit"

      unless input.strip.empty?
        last_command_success = run_command(input, aliases, functions)
        history.push(input) unless history.last == input
        history_index = history.length
      end
    else # NORMAL_MODE
      # print NORMAL_MODE_CURSOR_COLOR
      # print "\e]10;#{NORMAL_MODE_CURSOR_COLOR}\a"  # Set text color
      print "\e]12;#{NORMAL_MODE_CURSOR_COLOR}\a"  # Set cursor color


      action = handle_normal_mode_input
      current_mode = INSERT_MODE if action == :switch_mode
    end
  end
ensure
  # Save history when exiting
  File.open(HISTORY_FILE, 'w') { |file| history.each { |cmd| file.puts(cmd) } }
end
