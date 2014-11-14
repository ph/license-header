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
require 'spec_helper'
require 'license_header/tag_license'
require 'fileutils'
require 'stud/temporary'

describe LicenseHeader::TagLicense do
  let(:current_license) { File.read(__FILE__).split("\n").slice(0, 14).join("\n") }
  let(:file_with_copyright) { File.join(File.dirname(__FILE__), 'fixtures/file_with_copyright.rb') }
  let(:unmatched_file) { File.join(File.dirname(__FILE__), 'fixtures/unmatched.md') }

  subject { LicenseHeader::TagLicense.new(:dry_run => true, :license_content => current_license) }

  context '#tagged?' do
    it "return false if the file doesn't content the copyright header" do
      Stud::Temporary.file do |f|
        expect(subject.has_copyright?(f)).to eq(false)
      end
    end

    it 'return true if the file has the copyright header' do
      expect(subject.has_copyright?(file_with_copyright)).to eq(true)
    end
  end

  it "should return tagged file" do
    tmp_file = temporary_file('code.rb', 'w')
    files = [tmp_file, file_with_copyright]

    expect(Dir).to receive(:[]).with(File.expand_path('spec/**/*')).and_return(files)
    expect(subject.tag_directory_recursively("spec")).to eq([tmp_file])

    FileUtils.rm_rf(tmp_file)
  end

  it "should add the license at the beginning of the file" do
    tmp = Stud::Temporary.file

    File.open(tmp, 'w+') do |f|
      f.write('LGTM')
    end

    subject.add_license(tmp)
    content = File.read(tmp)
    splitted = content.split("\n")

    expect(splitted.first).to match(/^# Copyright/)
    expect(splitted.last).to match('LGTM')

    FileUtils.rm_rf(tmp.path)

  end
end

def temporary_file(suffix, *args)
  root = ENV["TMP"] || ENV["TMPDIR"] || ENV["TEMP"] || "/tmp"
  path = File.join(root, "#{SecureRandom.hex(30)}-#{suffix}")
  File.open(path, *args) {}
  path
end
