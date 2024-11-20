#!/usr/bin/env ruby

require 'fileutils'
require 'net/http'
require 'uri'
require 'optparse'
require 'yaml'
require 'logger'

class RubyManager
  CONFIG_PATH = File.expand_path('~/.myruby/config.yml')
  DEFAULT_CONFIG = { 'install_dir' => '~/.myruby/versions', 'shim_dir' => '~/.myruby/shims' }

  def initialize
    @config = load_config
    @install_dir = File.expand_path(@config['install_dir'])
    @shim_dir = File.expand_path(@config['shim_dir'])
    @log_dir = File.expand_path('~/.myruby/logs')
    FileUtils.mkdir_p(@install_dir)
    FileUtils.mkdir_p(@shim_dir)
    FileUtils.mkdir_p(@log_dir) # Ensure the log directory exists
    @logger = Logger.new(File.join(@log_dir, 'manager.log'), 'daily')
    check_and_install_dependencies
  end

  def install(version)
    puts "Installing Ruby #{version}..."
    download_ruby(version)
    compile_ruby(version)
    create_shims(version)
    puts "Ruby #{version} installed successfully."
  end

  def list
    puts "Installed Ruby versions:"
    installed_versions.each do |version|
      active = current_version == version ? '*' : ' '
      puts "  #{active} #{version}"
    end
  end

  def switch(version)
    if installed_versions.include?(version)
      File.write(current_version_file, version)
      puts "Switched to Ruby #{version}"
    else
      puts "Ruby #{version} is not installed."
    end
  end

  def uninstall(version)
    if installed_versions.include?(version)
      FileUtils.rm_rf(File.join(@install_dir, version))
      puts "Uninstalled Ruby #{version}"
    else
      puts "Ruby #{version} is not installed."
    end
  end

  def upgrade
    puts "Checking for the latest Ruby version..."
    latest_version = fetch_latest_ruby_version
    puts "Latest version is #{latest_version}."
    install(latest_version)
  end

  def switch_to_ruby_version_file
    if File.exist?('.ruby-version')
      version = File.read('.ruby-version').strip
      switch(version)
    else
      puts "No .ruby-version file found in the current directory."
    end
  end

  def update_manager
    puts "Updating Ruby Manager..."
    url = "https://raw.githubusercontent.com/your_repo/ruby_manager/main/ruby_manager.rb"
    safe_system("curl -o #{__FILE__} #{url}")
    puts "Ruby Manager updated successfully."
  end

  private

  def check_and_install_dependencies
    os = detect_os
    dependencies = %w[make gcc g++ libssl-dev libreadline-dev zlib1g-dev]
    missing_dependencies = dependencies.reject { |dep| system("#{package_check_command(os)} #{dep} > /dev/null 2>&1") }

    unless missing_dependencies.empty?
      puts "Missing dependencies: #{missing_dependencies.join(', ')}"
      install_command = package_install_command(os)
      puts "Installing dependencies..."
      safe_system("#{install_command} #{missing_dependencies.join(' ')}")
    end
    puts "All dependencies are installed."
  end

  def detect_os
    if RUBY_PLATFORM.include?('linux')
      :linux
    elsif RUBY_PLATFORM.include?('darwin')
      :macos
    else
      :unsupported
    end
  end

  def package_check_command(os)
    case os
    when :linux then 'dpkg -s'
    when :macos then 'brew list'
    else raise "Unsupported OS: #{os}"
    end
  end

  def package_install_command(os)
    case os
    when :linux then 'sudo apt-get install -y'
    when :macos then 'brew install'
    else raise "Unsupported OS: #{os}"
    end
  end

  def load_config
    if File.exist?(CONFIG_PATH)
      YAML.load_file(CONFIG_PATH)
    else
      File.write(CONFIG_PATH, DEFAULT_CONFIG.to_yaml)
      DEFAULT_CONFIG
    end
  end

  def download_ruby(version)
    url = "https://cache.ruby-lang.org/pub/ruby/#{version[0..2]}/ruby-#{version}.tar.gz"
    dest = "ruby-#{version}.tar.gz"

    uri = URI(url)
    Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
      request = Net::HTTP::Get.new(uri)
      http.request(request) do |response|
        File.open(dest, 'wb') do |file|
          response.read_body { |chunk| file.write(chunk) }
        end
      end
    end

    puts "Downloaded Ruby #{version}."
  end

  def compile_ruby(version)
    tar_file = "ruby-#{version}.tar.gz"
    safe_system("tar -xzf #{tar_file}")
    Dir.chdir("ruby-#{version}") do
      safe_system("./configure --prefix=#{File.join(@install_dir, version)}")
      safe_system("make")
      safe_system("make install")
    end
    FileUtils.rm_rf("ruby-#{version}")
    File.delete(tar_file)
  end

  def create_shims(version)
    %w[ruby gem irb rake].each do |cmd|
      shim_path = File.join(@shim_dir, cmd)
      File.write(shim_path, <<~SHIM)
        #!/bin/bash
        exec #{File.join(@install_dir, version, 'bin', cmd)} "$@"
      SHIM
      FileUtils.chmod('+x', shim_path)
    end
    puts "Shims created for Ruby #{version}."
  end

  def installed_versions
    Dir.children(@install_dir)
  end

  def current_version
    File.exist?(current_version_file) ? File.read(current_version_file).strip : nil
  end

  def current_version_file
    File.expand_path('~/.myruby/current_version')
  end

  def fetch_latest_ruby_version
    uri = URI("https://cache.ruby-lang.org/pub/ruby/index.txt")
    response = Net::HTTP.get(uri)
    response.scan(/ruby-(\d+\.\d+\.\d+)/).flatten.last
  end

  def safe_system(command)
    success = system(command)
    raise "Command failed: #{command}" unless success
  end
end

if __FILE__ == $PROGRAM_NAME
  options = {}
  OptionParser.new do |opts|
    opts.banner = "Usage: ruby_manager.rb [command] [options]"

    opts.on("--install VERSION", "Install a specific Ruby version") do |v|
      options[:command] = :install
      options[:version] = v
    end

    opts.on("--list", "List installed Ruby versions") do
      options[:command] = :list
    end

    opts.on("--switch VERSION", "Switch to a specific Ruby version") do |v|
      options[:command] = :switch
      options[:version] = v
    end

    opts.on("--uninstall VERSION", "Uninstall a specific Ruby version") do |v|
      options[:command] = :uninstall
      options[:version] = v
    end

    opts.on("--upgrade", "Upgrade to the latest Ruby version") do
      options[:command] = :upgrade
    end

    opts.on("--update-manager", "Update Ruby Manager to the latest version") do
      options[:command] = :update_manager
    end
  end.parse!

  manager = RubyManager.new

  case options[:command]
  when :install
    manager.install(options[:version])
  when :list
    manager.list
  when :switch
    manager.switch(options[:version])
  when :uninstall
    manager.uninstall(options[:version])
  when :upgrade
    manager.upgrade
  when :update_manager
    manager.update_manager
  else
    puts "Invalid command. Use --help for options."
  end
end

