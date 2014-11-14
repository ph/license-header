# Copyright 2014 Pier-Hugues Pellerin
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
require 'optparse'
require 'tempfile'
require 'securerandom'

module LicenseHeader
  class TagLicense
    def initialize(options =  {})
      @dry_run = options[:dry_run]
      @license_content = options[:license_content] || LICENSE
      @extensions = options[:extension] || ['rb']
    end

    def whitelisted?(file)
      extension = File.basename(file).split('.').pop
      @extensions.include?(extension)
    end

    def has_copyright?(file)
      fd = File.open(file)
      line = fd.gets
      fd.close

      if line =~ license_check
        return true
      else
        return false
      end
    end

    def tempfile
      Tempfile.new(SecureRandom.hex(30))
    end

    def add_license(file)
      temp = tempfile
      File.open(temp, 'w+') do |fd|
        fd.write(@license_content)
        fd.write(File.read(file))
      end

      FileUtils.cp(temp.path, file)
      FileUtils.rm_rf(temp.path)
    end

    def license_check
      /#{@license_check ||= @license_content.split("\n").shift}$/
    end

    def tag_directory_recursively(directory)
      modified_files = []


      Dir[File.join(File.expand_path(directory), '**/*')].each do |f|
        if !File.directory?(f) && whitelisted?(f) && !has_copyright?(f)
          modified_files << f
          add_license(f) unless dry_run?
        end
      end

      modified_files
    end

    def dry_run?
      @dry_run
    end

    def self.run!
      options = { :target => '.' }

      options_parser = OptionParser.new do |opts|
        opts.banner = "Usager: license_header [options]"
        opts.separator ""
        opts.separator "Options:"

        opts.on("-t", "--target=val", String, "specify the target directory, default to current directory") do |v|
          options[:target] = v 
        end

        opts.on("-l", "--license=val", String, "specify the header to apply to the source code") do |v|
          options[:license_content] = File.read(v) if File.exist?(v)
        end

        opts.on("--extensions=[x,y,z]", Array, "rb,cs") do |v|
         options[:extensions] = v
        end

        opts.on("-d", "--dry-run", "List the files to changes") do |v|
          options[:dry_run] = v
        end

        opts.on_tail
      end
      
      begin
        options_parser.parse!

        if options[:license_content].nil?
          puts "Missing the license header file"
          puts options_parser
          exit
        else
          tag = TagLicense.new(options)
          modified = tag.tag_directory_recursively(options[:target])
          modified.each { |f| puts "Modified: #{f}" }
        end
      rescue OptionParser::InvalidOption
        puts "Invalid option"
        puts options_parser
      end
    end
  end
end
