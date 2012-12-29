#!/usr/bin/env ruby
# encoding: utf-8
require 'rubygems'
require 'bundler/setup'
require 'pp'
Bundler.require
require "thread"
require 'net/http'
require 'json'
require 'fileutils'
require 'digest/md5'
require 'pty'
require 'rest_client'
VERSION=0.1

Thread.abort_on_exception = true
semaphore = Mutex.new

case RUBY_PLATFORM
  when /win32/
    require './specific_win'
  when /linux/
    require './specific_linux'
  when /osx/
    require './specific_osx'
  else
  puts "Unsupported platform: #{RUBY_PLATFORM}, please contact maintainer."
  exit 1
end

# Config
begin
  @config = YAML.load_file('config.yml')
rescue Errno::ENOENT
  puts "Please create a config.yml file."
  exit 1
end

@node_blendercfg = {}
@node_blendercfg['version'] = get_blender_version
@node_blendercfg['engines'] = get_blender_engines
@node_blendercfg['os'] = get_os
@node_blendercfg['hostname'] = get_hostname
@node_blendercfg['uuid'] = get_uuid
@node_blendercfg['compute'] = @config['compute']

@thread_node_state = {:validated => false, :paused => false} # set default values


def api_call(type, url, data)
  if type == 'post'
    req = RestClient.post "#{@config['api_url']}#{url}", data, :content_type => :json, :accept => :json
  elsif type == 'get'
    req = RestClient.get "#{@config['api_url']}#{url}", {:params => data, :accept => :json}
  end
  return JSON.parse(req)
end

def get_file(md5, filename, local_dir, url, data)

  if File.file? File.join(local_dir, filename)
    # File exist, check MD5
    c_md5 = Digest::MD5.hexdigest(File.open(File.join(local_dir, filename), 'r').read)
    return true if c_md5 == md5
  end

  Net::HTTP.new(@config['api_host'], @config['api_port']).start { |http|
    resp = http.get(url)
    open(File.join(local_dir, filename), "wb") { |file| file.write(resp.body) }
  }
  return true
end


# ===================================
# Tread: HEARTBEAT
# ===================================
th_heartbeat = Thread.new do
  while true
    infos = @node_blendercfg
    infos['access_token'] = @config['api_token']
    hb_resp = api_call('post', @config['api_heartbeat'], infos)

    if !hb_resp
      sleep 1
      next
    end

    #puts "[#{@config['api_heartbeat']}] response : #{hb_resp}"

    semaphore.synchronize {
      @thread_node_state[:validated] = hb_resp["validated"]
      @thread_node_state[:paused] = hb_resp["paused"]
      @thread_node_state[:id] = hb_resp["id"]
    }
    sleep 1
  end
end

# ===================================
# Tread: CPU
# ===================================
th_job_cpu = Thread.new do
  while true
    validated, paused = nil
    semaphore.synchronize {
      validated = @thread_node_state[:validated]
      paused = @thread_node_state[:paused]
    }
    if (validated != 1) or (paused != 0)
      puts "CPU: Node in pause or not validated."
      sleep 10
      next
    end

    infos = {:uuid => @node_blendercfg['uuid'], :compute => "CPU", :access_token => @config['api_token']}
    cpu_resp = api_call('get', @config['api_get_job'], infos)

    if !cpu_resp
      sleep 10
      next
    end

    puts "[#{@config['api_get_job']}] response : #{cpu_resp}"

    if cpu_resp["error"]
      puts "[Jobs error] : #{cpu_resp['error']}"
      sleep 10
      next
    end

    # filename, local_dir, url, data
    md5 = cpu_resp["md5"]
    filename = cpu_resp["filename"]
    local_dir = File.join(@config["local_dl_dir"], cpu_resp["id"].to_s, "/")
    url = cpu_resp["dot_blend"]["url"]
    data = {}

    FileUtils.mkdir_p(local_dir)
    dl_file = get_file(md5, filename, local_dir, url, data)

    puts "[get file] got file #{filename}"

    # Now start the render.
    # 1. blender config and command line
    render_filename = File.join(local_dir, filename)
    cfg = "#{cpu_resp['render_engine']}_#{cpu_resp['compute']}.py"
    cfg_path = File.join(@config['configs'], '/', cfg)
    framing = "-s #{cpu_resp['render_frame_start']} -e #{cpu_resp['render_frame_stop']}"
    cmd = "-E #{cpu_resp['render_engine']} -b #{render_filename} -o #{@config['local_render_dir']}#{cpu_resp['id']}_ -P #{cfg_path} -F PNG #{framing} -a"
    # 2. start blender
    puts "Will start blender with #{cmd}"
    FileUtils.mkdir_p(@config['local_render_dir'])
    b = File.join(@config['blender_path'], '/', @config['blender_bin'])

    # 3. do the magics!
    console_log = ""
    tstp_s = Time.now
    begin
      PTY.spawn("#{b} #{cmd}") do |stdin, stdout, pid|
        begin
          stdin.each { |line|
            console_log += line
            elapsed = line.split("|")[3]
            elapsed = elapsed.strip if elapsed

            if Time.now - tstp_s > 1
              tstp_s = Time.now
              puts elapsed
              infos = {:uuid => @node_blendercfg['uuid'], :job_id => cpu_resp['id'], :console_log => console_log, :job_status => elapsed, :node_status => 'rendering', :access_token => @config['api_token']}
              l_resp = api_call('post', @config['api_update_job'], infos)
            end

          }
        rescue Errno::EIO
          puts "Errno::EIO error, no more output"
        end
      end
    rescue PTY::ChildExited
      puts "Blender exited!"
    end

    # 4. Here we send the final result to the dispatcher : console_log and resulted image / anim

    sleep 10
  end
end

# ===================================
# Tread: GPU
# ===================================
th_job_gpu = Thread.new do
  while true
    validated, paused = nil
    semaphore.synchronize {
      validated = @thread_node_state[:validated]
      paused = @thread_node_state[:paused]
    }
    if !validated or paused
      puts "GPU: Node in pause or not validated."
      sleep 10
      next
    end

    infos = {:uuid => @node_blendercfg['uuid'], :compute => "GPU", :access_token => @config['api_token']}
    gpu_resp = api_call('get', @config['api_get_job'], infos)

    if !gpu_resp
      sleep 10
      next
    end

    puts "[#{@config['api_get_job']}] response : #{gpu_resp[:code]} #{gpu_resp[:message]} : #{gpu_resp}"

    sleep 10
  end
end

# Start heartbeat thread
th_heartbeat.join
th_job_cpu.join
th_job_gpu.join
