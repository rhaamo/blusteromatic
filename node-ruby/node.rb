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


def api_call(type, url, data)
  if type == 'post'
    req = Net::HTTP::Post.new(url, initheader = {'Content-Type' => 'application/json'})
  elsif type == 'get'
    req = Net::HTTP::Get.new(url, initheader = {'Content-Type' => 'application/json'})
  end
  req.body = data.to_json
  begin
    response = Net::HTTP.new(@config['api_host'], @config['api_port']).start { |http| http.request(req) }
    return {:code => response.code, :message => response.message, :body => JSON.parse(response.body)}
  rescue Errno::ECONNREFUSED
    puts "[#{url}] could not connect to http://#{@config['api_host']}:#{@config['api_port']}"
    return nil
  end
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

    puts "[#{@config['api_heartbeat']}] response : #{hb_resp[:code]} #{hb_resp[:message]} : #{hb_resp[:body]}"

    semaphore.synchronize {
      @thread_node_state[:validated] = hb_resp[:body]["validated"]
      @thread_node_state[:paused] = false
      @thread_node_state[:id] = hb_resp[:body]["id"]
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
    if !validated or paused
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

    puts "[#{@config['api_get_job']}] response : #{cpu_resp[:code]} #{cpu_resp[:message]} : #{cpu_resp[:body]}"

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

    puts "[#{@config['api_get_job']}] response : #{gpu_resp[:code]} #{gpu_resp[:message]} : #{gpu_resp[:body]}"

    sleep 10
  end
end

# Start heartbeat thread
th_heartbeat.join
th_job_cpu.join
th_job_gpu.join
