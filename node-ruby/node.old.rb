#!/usr/bin/env ruby
# encoding: utf-8
require 'rubygems'
require 'bundler/setup'
require 'pp'
Bundler.require
require "forever"
require 'net/http'
require 'json'
VERSION=0.1

Forever.run do
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

  @last_heartbeat_response = {}

def report_status_to_master
  infos = @node_blendercfg
  infos['access_token'] = @config['api_token']
  infos = infos.to_json
  url = @config['api_heartbeat']
  req = Net::HTTP::Post.new(url, initheader = {'Content-Type' => 'application/json'})
  req.body = infos
  response = Net::HTTP.new(@config['api_host'], @config['api_port']).start { |http| http.request(req) }

  puts "API HEARTBEAT response : #{response.code} #{response.message} : #{response.body}"

  hb_resp = JSON.parse response.body
  @last_heartbeat_response[:validated] = hb_resp["validated"]
  @last_heartbeat_response[:id] = hb_resp["id"]
end


  dir File.expand_path('../', __FILE__) # Default is ../../__FILE__
  every 1.seconds do
    report_status_to_master
  end
end
