#
# Cookbook Name:: php52
# Recipe:: default
#
# The MIT License (MIT)
# 
# Copyright (c) 2015 Hisashi KOMINE
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

# Setup apache2
include_recipe 'apache2'

[
  'gcc',
  'autoconf',
  'httpd-devel',
  'libxml2-devel',
  'openssl-devel',
  'libcurl-devel',
  'mysql-devel',
  'libpng-devel',
].each do |p|
  package p do
  end
end

# Download & extract source
remote_file '/usr/local/src/php-5.2.17.tar.gz' do
  source 'http://museum.php.net/php5/php-5.2.17.tar.gz'
  action :create_if_missing
end
execute 'php52-extract-source' do
  cwd '/usr/local/src'
  command 'tar zxf php-5.2.17.tar.gz'
  only_if {
    File.exists?('/usr/local/src/php-5.2.17.tar.gz') &&
    !File.directory?('/usr/local/src/php-5.2.17')
  }
end

# configure
configure_options = [
  '--with-config-file-path=/etc',
  '--with-config-file-scan-dir=/etc/php.d',
  '--with-libdir=lib64',
  '--with-apxs2=/usr/sbin/apxs',
  '--with-openssl',
  '--with-curl',
  '--enable-mbstring',
  '--enable-zend-multibyte',
  '--with-mysql',
  '--with-mysqli',
  '--with-pdo-mysql',
  '--with-pear',
  '--with-gd',
]
execute 'php52-configure' do
  cwd '/usr/local/src/php-5.2.17'
  command "./configure #{configure_options.join(' ')}"
  only_if {
    File.directory?('/usr/local/src/php-5.2.17') &&
    !File.exists?('/usr/local/src/php-5.2.17/Makefile')
  }
end

# make, make install
execute 'php52-make-install' do
  cwd '/usr/local/src/php-5.2.17'
  command <<-EOC
    make && make install
    mv /etc/httpd/conf/httpd.conf.bak /etc/httpd/conf/httpd.conf
  EOC
  only_if {
    File.exists?('/usr/local/src/php-5.2.17/Makefile') &&
    !File.exists?('/usr/local/src/php-5.2.17/sapi/cli/php')
  }
end

# Setup /etc/php.ini
template '/etc/php.ini' do
  source 'php.ini.erb'
  variables ini: node['php52']['ini']
end

# Setup /etc/httpd/conf.d/php.conf
template '/etc/httpd/conf.d/php.conf' do
  source 'apache.php.conf.erb'
  notifies :reload, 'service[httpd]'
end

# Create php log directory
directory '/var/log/php' do
end
