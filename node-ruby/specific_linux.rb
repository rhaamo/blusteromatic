# Linux-specific variable and things
puts "Selected linux specific platform."
require "socket"

# Access to node config using @config

def get_blender_version
  opts = "--version"
  b = File.join(@config['blender_path'], @config['blender_bin'])
  version = `#{b} #{opts}`
  if !$?.success?
    puts "Error while calling '#{b} #{opts}'"
    exit 1
  end
  version = version.split("\n")
  blender_version = ""
  version.each do |line|
    if line =~ /^Blender /
      blender_version = line.gsub("Blender ", "")
      next
    end
    if line =~ /^\tbuild revision: /
      l = line.gsub("\tbuild revision: ", "r")
      blender_version += " #{l}"
    end
  end

  puts "Got blender version '#{blender_version}'"
  return blender_version
end

def get_blender_engines
  opts = "-E help -b"
  b = File.join(@config['blender_path'], @config['blender_bin'])
  engines = `#{b} #{opts}`
  if !$?.success?
    puts "Error while calling '#{b} #{opts}'"
    exit 1
  end
  engines = engines.split("\n")
  blender_engines = []
  engines.each do |line|
    if line =~ /^\t/
      blender_engines << line.strip
    end
  end

  puts "Got blender engines '#{blender_engines.join(',')}'"
  return blender_engines.join(',')
end

def get_hostname
  host_name = Socket::gethostname
  puts "Got hostname '#{host_name}'"
  return host_name
end

def get_uuid
  uuid = File.open("/var/lib/dbus/machine-id", "r").readline.strip
  puts "Got uuid '#{uuid}'"
  return uuid
end

def get_os
  return "linux"
end
