require 'io/console'
require 'readline'

class User
  attr_accessor :stdin, :stdout

  def initialize(stdin, stdout)
    self.stdin = stdin
    self.stdout = stdout
  end

  def heading(text)
    stdout.puts "----- #{text} -----"
  end

  def press_any_key(message=nil)
    puts message if message
    get_key
  end

  def get_key
    key = stdin.getch
    return key unless key == ?\C-c # allow interrupts
    Process.kill 'INT', Process.pid
  end

  def gets
    Readline.input = stdin
    Readline.readline '> ', true
  end

  def puts(*messages)
    stdout.puts(*messages)
  end

  def error(message)
    stdout.puts "!!!!! #{message} !!!!!"
  end

  def ask(prompt)
    stdout.print "#{prompt} (y/n) "
    answer = get_key.downcase
    if answer != 'y' && answer != 'n'
      stdout.puts "\nUnexpected input: #{answer.inspect}, was expecting \"y\" or \"n\""
      ask prompt
    else
      stdout.puts answer
      answer == 'y'
    end
  end
end

if $PROGRAM_NAME == __FILE__
  u = User.new $stdin, $stdout
  u.heading 'press a key'
  u.press_any_key
  u.ask 'do or do not?'
  u.heading 'okay'
  p u.gets
  require "pry"
  binding().pry
end
