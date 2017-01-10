#!/bin/bash
# Author: Reza Motevallizadeh
# Email: rezamt@gmail.com
# Ref: https://support.3scale.net/docs/deployment-options/nginx-self-managed-setup

# Define your environment variables here
# 3scale Admin Domain name
THREESCALE_ADMIN_DOMAIN="demoland-admin.3scale.net"
# 3scale Provider Key (check your account setting)
THREESCALE_PROVIDER_KEY="e1da08a73143ecbe4e9dc9451fdf688c"
# 3scale nginx installation path
THREESCALE_NGINX_PATH="/usr/local/openresty/nginx/conf/"
# 3scale service id (check your account setting)
THREESCALE_SERVICE_ID="2445581733842"

echo "Step 1: Install the dependencies"

sudo add-apt-repository "deb http://archive.ubuntu.com/ubuntu $(lsb_release -sc) main universe"
sudo apt-get update
sudo apt-get install -y libreadline-dev libncurses5-dev libpcre3-dev libssl-dev perl make
sudo apt-get install -y gcc

sudo apt install -y git
sudo apt install -y npm
sudo apt install -y nodejs-legacy
sudo apt install -y awscli

# for OAuth package and installation
sudo apt -y build-dep nginx
sudo apt -y install tcl

# Downloading nginx service configuration file
wget -O /tmp/nginx https://gist.githubusercontent.com/vdel26/8805927/raw/249f907e465e98ac099437025218a15e55a34b4c/nginx

echo "Step 2: Compile and install NGINX"
wget http://openresty.org/download/ngx_openresty-1.9.7.2.tar.gz
tar xzvf ngx_openresty-1.9.7.2.tar.gz
cd ngx_openresty-1.9.7.2
sudo ./configure --with-luajit --with-http_iconv_module -j2
sudo make
sudo make install


echo "Step 3: Download your API gateway configuration from 3scale"
cd ~
git clone https://github.com/vdel26/download-3scale-config.git
cd download-3scale-config/
sudo npm -g install

cat << END >> ~/.config.json
{
  "domain":  "$THREESCALE_ADMIN_DOMAIN",
  "providerKey": "$THREESCALE_PROVIDER_KEY",
  "nginxPath":  "$THREESCALE_NGINX_PATH"
}
END

sudo download-3scale-config

# Copy Lua files to their destination
sudo mv /usr/local/openresty/nginx/conf/authorized_callback.lua  /usr/local/openresty/nginx/authorized_callback.lua 
sudo mv /usr/local/openresty/nginx/conf/get_token.lua /usr/local/openresty/nginx/get_token.lua
sudo mv /usr/local/openresty/nginx/conf/authorize.lua  /usr/local/openresty/nginx/authorize.lua
sudo mv /usr/local/openresty/nginx/conf/threescale_utils.lua  /usr/local/openresty/lualib/threescale_utils.lua

# echo "Step 4: Running NGINX"
# sudo /usr/local/openresty/nginx/sbin/nginx -p /usr/local/openresty/nginx/ -c /usr/local/openresty/nginx/conf/nginx_$THREESCALE_SERVICE_ID.conf

echo "Step 4: Nginx Service Configuration"
sed -i 's/CONF=$PREFIX\/conf\/$NAME\.conf/CONF=$PREFIX\/conf\/nginx_'"$THREESCALE_SERVICE_ID"'\.conf/g' /tmp/nginx
sudo cp /tmp/nginx /etc/init.d/nginx
sudo chmod +x /etc/init.d/nginx
sudo update-rc.d nginx defaults
sudo service nginx stop
sudo service nginx start

echo "Step 5: Installing Redis (Storing Nonce and Authorization Codes - Access tokens lives on 3Scale API Management Platform) "
wget https://codeload.github.com/antirez/redis/tar.gz/4.0-rc2 -O /tmp/redis-4.0-rc2.tar.gz
tar -zxvf /tmp/redis-4.0-rc2.tar.gz
cd redis-4.0-rc2
make
make install

sudo REDIS_PORT=6379 \
    REDIS_CONFIG_FILE=/etc/redis/6379.conf \
    REDIS_LOG_FILE=/var/log/redis_6379.log \
    REDIS_DATA_DIR=/var/lib/redis/6379 \
    REDIS_EXECUTABLE=/usr/local/bin/redis-server
    REDIS_EXECUTABLE=`command -v redis-server` ~/redis-4.0-rc2/utils/install_server.sh






