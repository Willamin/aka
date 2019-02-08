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

module Aka
  VERSION = {{ `shards version #{__DIR__}`.chomp.stringify }}

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

      STDERR.puts ("┌────────┐")

      STDERR.print("│ alias: └")
      STDERR.print("─" * (longest_line - 6))
      STDERR.print("─┐")
      STDERR.puts

      @call.lines[0].tap do |call_line|
        STDERR.print("│ $ ")
        STDERR.print(call_line)
        STDERR.print(" " * (longest_line - call_line.size))
        STDERR.print(" │")
        STDERR.puts
      end

      @call.lines[1..-1].each do |call_line|
        STDERR.print("│   ")
        STDERR.print(call_line)
        STDERR.print(" " * (longest_line - call_line.size))
        STDERR.print(" │")
        STDERR.puts
      end

      STDERR.print("└─")
      STDERR.print("─" * (longest_line + 2))
      STDERR.print("─┘")
      STDERR.puts
      STDERR.puts

      full_call = ([@call] + ARGV).join(" ")

      Process.exec("/bin/bash", ["-c", full_call])
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

  input = ARGV[0]?.tap( &.try { ARGV.replace(ARGV[1..-1]) })
else
  input = File.basename(PROGRAM_NAME)
end

input.try { |i| aliases.find?(i).try(&.success!) }

"alias '#{input}' not found".error!
