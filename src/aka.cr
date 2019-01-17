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
      STDERR.puts ("┌────────┐")

      STDERR.print("│ alias: └")
      STDERR.print("─" * (@call.size - 6))
      STDERR.print("─┐")
      STDERR.puts

      STDERR.print("│ $ ")
      STDERR.print(@call)
      STDERR.print(" │")
      STDERR.puts

      STDERR.print("└─")
      STDERR.print("─" * (@call.size + 2))
      STDERR.print("─┘")
      STDERR.puts
      STDERR.puts

      Process.exec(@call.split[0], @call.split[1..-1])
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
  if ARGV.includes?("--setup")
    aliases.each do |a|
      Process.executable_path.try do |path|
        FileUtils.ln_s(path, File.expand_path("~/.config/aka/#{a.invocation}"))
      end
    end
  end

  if ARGV.includes?("--list")
    aliases.success!
  end

  input = ARGV[0]?
else
  input = File.basename(PROGRAM_NAME)
end

input.try { |i| aliases.find?(i).try(&.success!) }

"alias '#{input}' not found".error!
