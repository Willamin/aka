require "file_utils"
require "yaml"

class Object
  def error!
    STDOUT.puts("aka: " + self)
    exit(0)
  end

  def success!
    STDERR.puts(self)
    exit(1)
  end
end

class String
  def to_bool
    case self.downcase
    when "true", "1", "yes" then true
    else                         false
    end
  end
end

module Aka
  VERSION             = {{ `shards version #{__DIR__}`.chomp.stringify }}
  ALIAS_HIDE_REMINDER = ENV["AKA_HIDE_REMINDER"]?.try(&.to_bool) || false

  class Alias
    getter invocation : String
    getter call : String

    def initialize(@invocation, @call); end

    def bash : String
      "alias #{@invocation}='#{@call}'"
    end

    def match?(i : String) : Bool
      i == @invocation
    end

    def to_s
      @call
    end

    def success!
      longest_line = Math.max(@call.lines.max_by(&.size).size, 6)

      STDERR.puts ("┌────────┐") unless ALIAS_HIDE_REMINDER

      STDERR.print("│ alias: └") unless ALIAS_HIDE_REMINDER
      STDERR.print("─" * (longest_line - 6)) unless ALIAS_HIDE_REMINDER
      STDERR.print("─┐") unless ALIAS_HIDE_REMINDER
      STDERR.puts unless ALIAS_HIDE_REMINDER

      @call.lines[0].tap do |call_line|
        STDERR.print("│ $ ") unless ALIAS_HIDE_REMINDER
        STDERR.print(call_line) unless ALIAS_HIDE_REMINDER
        STDERR.print(" " * (longest_line - call_line.size)) unless ALIAS_HIDE_REMINDER
        STDERR.print(" │") unless ALIAS_HIDE_REMINDER
        STDERR.puts unless ALIAS_HIDE_REMINDER
      end

      @call.lines[1..-1].each do |call_line|
        STDERR.print("│   ") unless ALIAS_HIDE_REMINDER
        STDERR.print(call_line) unless ALIAS_HIDE_REMINDER
        STDERR.print(" " * (longest_line - call_line.size)) unless ALIAS_HIDE_REMINDER
        STDERR.print(" │") unless ALIAS_HIDE_REMINDER
        STDERR.puts unless ALIAS_HIDE_REMINDER
      end

      STDERR.print("└─") unless ALIAS_HIDE_REMINDER
      STDERR.print("─" * (longest_line + 2)) unless ALIAS_HIDE_REMINDER
      STDERR.print("─┘") unless ALIAS_HIDE_REMINDER
      STDERR.puts unless ALIAS_HIDE_REMINDER
      STDERR.puts unless ALIAS_HIDE_REMINDER

      full_call = ([@call] + ARGV).join(" ")
      bash_args = ["-c", full_call]

      if STDIN.tty?
        bash_args = bash_args.unshift("-i")
      end

      Process.exec("/bin/bash", bash_args)
    end
  end

  class AliasList
    getter aliases = Array(Alias).new

    def self.from_yaml(content : String)
      self.new.tap do |a|
        YAML.parse(content).as_h.each do |invocation, call|
          a.aliases << Alias.new(invocation.as_s, call.as_s)
        end
      end
    rescue
      "bad config file. please fix".error!
    end

    def to_s(io : IO)
      io << @aliases.map(&.bash).join("\n")
    end

    def find?(invocation : String) : Alias?
      @aliases.select(&.match?(invocation)).last?
    end

    def each
      @aliases.each { |a| yield a }
    end

    def size
      @aliases.size
    end
  end
end

# setup
config_path = File.expand_path("~/.config/aka.yml")

unless File.exists?(config_path)
  "missing config file. please add #{config_path}".error!
end
content = File.read(config_path)
aliases = Aka::AliasList.from_yaml(content)

# business logic
if PROGRAM_NAME == "aka" || PROGRAM_NAME == "bin/aka"
  if ARGV.includes?("--link")
    issues = 0
    aliases.each do |a|
      Process.executable_path.try do |path|
        begin
          FileUtils.ln_s(path, File.expand_path("~/.config/aka/#{a.invocation}"))
        rescue e
          issues += 1
        end
      end
    end
    "linked #{aliases.size - issues} aliases".success!
  end

  if ARGV.includes?("--list")
    aliases.success!
  end

  input = ARGV[0]?.tap(&.try { ARGV.replace(ARGV[1..-1]) })
else
  input = File.basename(PROGRAM_NAME)
end

input.try { |i| aliases.find?(i).try(&.success!) }

"alias '#{input}' not found".error!
