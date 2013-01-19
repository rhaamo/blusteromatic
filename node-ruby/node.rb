#!/usr/bin/env ruby
# encoding: utf-8
ENV['BUNDLE_GEMFILE'] = File.expand_path('../Gemfile', __FILE__)
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
require 'forever'

Forever.run do
  dir File.expand_path('../', __FILE__) # Default is ../../__FILE__

  on_error do |e|
    puts "ERROR !"
    puts e
  end

  every 60.seconds do

    Thread.abort_on_exception = true
    semaphore = Mutex.new

    trap("SIGINT") { end_of_the_world }

    case RUBY_PLATFORM
    when /win32/
      require File.expand_path('../specific_win', __FILE__)
    when /linux/
      require File.expand_path('../specific_linux', __FILE__)
    when /osx/
      require File.expand_path('../specific_osx', __FILE__)
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

    @thread_node_state = {:validated => false, :paused => false, :pid_cpu => nil, :pid_gpu => nil} # set default values

    def end_of_the_world
      puts "Catched ctrl c"
      puts "PID CPU: #{@thread_node_state[:pid_cpu]} ; PID GPU: #{@thread_node_state[:pid_gpu]}"
      @thread_node_state[:stop_now] = true
      Process.kill("SIGTERM", @thread_node_state[:pid_cpu]) if @thread_node_state[:pid_cpu]
      Process.kill("SIGTERM", @thread_node_state[:pid_gpu]) if @thread_node_state[:pid_gpu]

      puts "Sending job state"

      if @thread_node_state[:cpu_job_infos]
        infos_cpu = {
          :uuid => @node_blendercfg['uuid'],
          :job_id => @thread_node_state[:cpu_job_infos][:job_id],
          #:console_log => console_log,
          :access_token => @config['api_token'],
          :error => "Catched SIGINT"
        }
        cpu_error_job_resp = api_call('post', @config['api_error_job'], infos_cpu)
      end
      if @thread_node_state[:gpu_job_infos]
        infos_gpu = {
          :uuid => @node_blendercfg['uuid'],
          :job_id => @thread_node_state[:gpu_job_infos][:job_id],
          #:console_log => console_log,
          :access_token => @config['api_token'],
          :error => "Catched SIGINT"
        }
        gpu_error_job_resp = api_call('post', @config['api_error_job'], infos_gpu)
      end

      puts "Exiting"

      exit
    end

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

        infos = {
          :uuid => @node_blendercfg['uuid'],
          :compute => "CPU",
          :access_token => @config['api_token']
        }
        cpu_resp = api_call('get', @config['api_get_job'], infos)

        if !cpu_resp
          sleep 10
          next
        end

        puts "[CPU][#{@config['api_get_job']}] response : #{cpu_resp}"

        if cpu_resp["error"]
          puts "[CPU][Jobs error] : #{cpu_resp['error']}"
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

        puts "[CPU][get file] got file #{filename}"

        # Now start the render.
        # 1. blender config and command line
        render_filename = File.join(local_dir, filename)
        cfg = "#{cpu_resp['render_engine']}_#{cpu_resp['compute']}.py"
        cfg_path = File.join(@config['configs'], '/', cfg)
        framing = "-s #{cpu_resp['render_frame_start']} -e #{cpu_resp['render_frame_stop']}"
        # output name like "render_CYCLES_CPU_0-0_id4_"
        output_render_name = "render_#{cpu_resp['render_engine']}_#{cpu_resp['compute']}_#{cpu_resp['render_frame_start']}-#{cpu_resp['render_frame_stop']}_id#{cpu_resp['id']}_"
        cmd = "-E #{cpu_resp['render_engine']} -b #{render_filename} -o #{@config['local_render_dir']}#{output_render_name} -P #{cfg_path} -F PNG #{framing} -a"
        # 2. start blender
        puts "CPU Will start blender with #{cmd}"
        FileUtils.mkdir_p(@config['local_render_dir'])
        b = File.join(@config['blender_path'], '/', @config['blender_bin'])

        semaphore.synchronize{
          @thread_node_state[:cpu_job_infos] = {:job_id => cpu_resp['id']}
        }

        # 3. do the magics!
        console_log = ""
        tstp_s = Time.now
        begin
          PTY.spawn("#{b} #{cmd}") do |stdin, stdout, pid|
            begin
              semaphore.synchronize {
                @thread_node_state[:pid_cpu] = pid
              }

              stdin.each { |line|
                console_log += line
                elapsed = line.split("|")[3] || "rendering"
                elapsed = elapsed.strip if elapsed

                if Time.now - tstp_s > 1
                  tstp_s = Time.now
                  infos = {
                    :uuid => @node_blendercfg['uuid'],
                    :job_id => cpu_resp['id'],
                    :console_log => console_log,
                    :job_status => elapsed,
                    :node_status => 'rendering',
                    :access_token => @config['api_token']
                  }
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

        is_stopped = false
        semaphore.synchronize {
          puts "Exiting CPU thread." if @thread_node_state[:stop_now]
          is_stopped = @thread_node_state[:stop_now]
        }
        break if is_stopped

        # 4. Here we send the final result to the dispatcher : console_log and resulted image / anim
        # Render file is last line of log "^Saved: (.*) Time: (.*)$"
        log_saved, log_time = nil
        console_log.split("\n").each do |line|
          if line.start_with? "Saved: "
            m = line.match("^Saved: (.*) Time: (.*)$")
            log_saved = m[1]
            log_time = m[2]
          end
        end

        puts "CPU Job finished in #{log_time}"
        infos = {
          :uuid => @node_blendercfg['uuid'],
          :job_id => cpu_resp['id'],
          :console_log => console_log,
          :output_file => File.new(log_saved, "rb"),
          :filename => File.basename(log_saved),
          :access_token => @config['api_token'],
          :render_time => log_time
        }
        finish_job_resp = api_call('post', @config['api_finish_job'], infos)

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
        if (validated != 1) or (paused != 0)
          puts "GPU: Node in pause or not validated."
          sleep 10
          next
        end

        infos = {
          :uuid => @node_blendercfg['uuid'],
          :compute => "GPU",
          :access_token => @config['api_token']
        }
        gpu_resp = api_call('get', @config['api_get_job'], infos)

        if !gpu_resp
          sleep 10
          next
        end

        puts "[GPU][#{@config['api_get_job']}] response : #{gpu_resp}"

        if gpu_resp["error"]
          puts "[GPU][Jobs error] : #{gpu_resp['error']}"
          sleep 10
          next
        end

        # filename, local_dir, url, data
        md5 = gpu_resp["md5"]
        filename = gpu_resp["filename"]
        local_dir = File.join(@config["local_dl_dir"], gpu_resp["id"].to_s, "/")
        url = gpu_resp["dot_blend"]["url"]
        data = {}

        FileUtils.mkdir_p(local_dir)
        dl_file = get_file(md5, filename, local_dir, url, data)

        puts "[GPU][get file] got file #{filename}"

        # Now start the render.
        # 1. blender config and command line
        render_filename = File.join(local_dir, filename)
        cfg = "#{gpu_resp['render_engine']}_#{gpu_resp['compute']}.py"
        cfg_path = File.join(@config['configs'], '/', cfg)
        framing = "-s #{gpu_resp['render_frame_start']} -e #{gpu_resp['render_frame_stop']}"
        # output name like "render_CYCLES_GPU_0-0_id4_"
        output_render_name = "render_#{gpu_resp['render_engine']}_#{gpu_resp['compute']}_#{gpu_resp['render_frame_start']}-#{gpu_resp['render_frame_stop']}_id#{gpu_resp['id']}_"
        cmd = "-E #{gpu_resp['render_engine']} -b #{render_filename} -o #{@config['local_render_dir']}#{output_render_name} -P #{cfg_path} -F PNG #{framing} -a"
        # 2. start blender
        puts "GPU Will start blender with #{cmd}"
        FileUtils.mkdir_p(@config['local_render_dir'])
        b = File.join(@config['blender_path'], '/', @config['blender_bin'])

        semaphore.synchronize{
          @thread_node_state[:gpu_job_infos] = {:job_id => gpu_resp['id']}
        }

        # 3. do the magics!
        console_log = ""
        tstp_s = Time.now
        begin
          PTY.spawn("#{b} #{cmd}") do |stdin, stdout, pid|
            begin

              semaphore.synchronize {
                @thread_node_state[:pid_gpu] = pid
              }

              stdin.each { |line|
                console_log += line
                elapsed = line.split("|")[3] || "rendering"
                elapsed = elapsed.strip if elapsed

                if Time.now - tstp_s > 1
                  tstp_s = Time.now
                  infos = {
                    :uuid => @node_blendercfg['uuid'],
                    :job_id => gpu_resp['id'],
                    :console_log => console_log,
                    :job_status => elapsed,
                    :node_status => 'rendering',
                    :access_token => @config['api_token']
                  }
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

        is_stopped = false
        semaphore.synchronize {
          puts "Exiting GPU thread." if @thread_node_state[:stop_now]
          is_stopped = @thread_node_state[:stop_now]
        }
        break if is_stopped

        # 4. Here we send the final result to the dispatcher : console_log and resulted image / anim
        # Render file is last line of log "^Saved: (.*) Time: (.*)$"
        log_saved, log_time = nil
        console_log.split("\n").each do |line|
          if line.start_with? "Saved: "
            m = line.match("^Saved: (.*) Time: (.*)$")
            log_saved = m[1]
            log_time = m[2]
          end
        end

        puts "GPU Job finished in #{log_time}"
        infos = {
          :uuid => @node_blendercfg['uuid'],
          :job_id => gpu_resp['id'],
          :console_log => console_log,
          :output_file => File.new(log_saved, "rb"),
          :filename => File.basename(log_saved),
          :access_token => @config['api_token'],
          :render_time => log_time
        }
        finish_job_resp = api_call('post', @config['api_finish_job'], infos)

        sleep 10
      end
    end

    # Start heartbeat thread
    th_heartbeat.join
    th_job_cpu.join
    th_job_gpu.join

  end
end
