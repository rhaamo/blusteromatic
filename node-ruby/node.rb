#!/usr/bin/env ruby
# encoding: utf-8
require 'rubygems'
require 'bundler/setup'
require 'pp'
Bundler.require
require "thread"
require 'net/http'
require 'json'
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



# ===================================
# Tread: HEARTBEAT
# ===================================
th_heartbeat = Thread.new do
  while true
    infos = @node_blendercfg
    infos['access_token'] = @config['api_token']
    infos = infos.to_json
    url = @config['api_heartbeat']
    req = Net::HTTP::Post.new(url, initheader = {'Content-Type' => 'application/json'})
    req.body = infos
    begin
      response = Net::HTTP.new(@config['api_host'], @config['api_port']).start { |http| http.request(req) }
    rescue Errno::ECONNREFUSED
      puts "[API][HEARTBEAT] could not connect to http://#{@config['api_host']}:#{@config['api_port']}"
      sleep 1
      next
    end

    puts "[API][HEARTBEAT] response : #{response.code} #{response.message} : #{response.body}"

    hb_resp = JSON.parse response.body

    semaphore.synchronize {
      @thread_node_state[:validated] = hb_resp["validated"]
      @thread_node_state[:paused] = false
      @thread_node_state[:id] = hb_resp["id"]
    }
    sleep 1
  end
end

# ===================================
# Tread: CPU
# ===================================
#th_job_cpu = Thread.new do
#  while true
#    st = nil
#    semaphore.synchronize {
#      st = validated
#    }
#    puts "CPU JOB: #{st}"
#    sleep 10
#  end
#end

# ===================================
# Tread: GPU
# ===================================
#th_job_gpu = Thread.new do
#  while true
#    st = nil
#    semaphore.synchronize {
#      st = validated
#    }
#    puts "GPU JOB: #{st}"
#    sleep 10
#  end
#end

# Start heartbeat thread
th_heartbeat.join
#th_job_cpu.join
#th_job_gpu.join
