#!/usr/bin/env bash
#=================================================
#	System Required: Debian/Ubuntu
#	Description: Install Nginx with Rtmp module
#	Version: v0.1
#	Author: APTX
#=================================================
sh_ver="0.1"
nginx_ver="1.18.0"
Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Tip="${Green_font_prefix}[注意]${Font_color_suffix}"
check_sys() {
  if [[ -f /etc/redhat-release ]]; then
    release="centos"
  elif grep -q -E -i "debian" /etc/issue; then
    release="debian"
  elif grep -q -E -i "ubuntu" /etc/issue; then
    release="ubuntu"
  elif grep -q -E -i "centos|red hat|redhat" /etc/issue; then
    release="centos"
  elif grep -q -E -i "debian" /proc/version; then
    release="debian"
  elif grep -q -E -i "ubuntu" /proc/version; then
    release="ubuntu"
  elif grep -q -E -i "centos|red hat|redhat" /proc/version; then
    release="centos"
  fi
  bit=$(uname -m)
}
install_nginx() {
  cd /tmp || mkdir /tmp
  wget "http://nginx.org/download/nginx-${nginx_ver}.tar.gz" -O "nginx.tar.gz"
  tar -xzf nginx.tar.gz
  cd nginx-${nginx_ver}/ || (
    echo "${Error} Nginx下载失败"
    exit 1
  )
  git clone https://github.com/winshining/nginx-http-flv-module.git
  apt build-dep nginx -y
  ./configure --prefix=/usr/local/nginx --with-http_stub_status_module --with-http_sub_module --with-http_v2_module --with-http_ssl_module --with-http_gzip_static_module --with-http_realip_module --add-module=./nginx-http-flv-module
  make && make install
  ln -s /usr/local/nginx/sbin/nginx /usr/sbin/nginx
  cat >"/lib/systemd/system/nginx.service" <<-EOF
[Unit]
Description=The NGINX HTTP and reverse proxy server
After=syslog.target network-online.target remote-fs.target nss-lookup.target
Wants=network-online.target

[Service]
Type=forking
PIDFile=/run/nginx.pid
ExecStartPre=/usr/local/nginx/sbin/nginx -t
ExecStart=/usr/local/nginx/sbin/nginx
ExecReload=/usr/local/nginx/sbin/nginx -s reload
ExecStop=/bin/kill -s QUIT $MAINPID
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF
}
config_nginx() {
  mkdir -p /data/wwwroot/default
  mkdir -p /data/wwwroot/public
  mkdir -p /data/wwwlogs
  cp /usr/local/nginx/html/* /data/wwwroot/default
  mkdir /usr/local/nginx/conf/vhost
  mkdir /usr/local/nginx/conf/ssl
  mv -f Nginx_Live/config/* /usr/local/nginx/conf/
  systemctl daemon-reload
  systemctl start nginx.service
  systemctl enable nginx.service
}

main() {
  echo -e "安装Nginx以及RTMP模块脚本 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}"
  check_sys
  if [[ ${release} == "centos" ]]; then
    echo -e "${Error} 本脚本只支援Debian/Ubuntu系统!"
    exit 1
  fi
  apt update && apt install wget curl build-essential git unzip -y
  curl -sL https://deb.nodesource.com/setup_14.x | bash # Install Node.js
  wget "https://github.com/CokeMine/Nginx_Live_DPlayer/archive/node.zip" -O nginx_live.zip
  unzip nginx_live.zip
  mv Nginx_Live_DPlayer-main Nginx_Live
  read -rp "${Info} 请输入你需要配置的域名:" domain
  install_nginx
  if ! nginx -V >/dev/null 2>&1; then
    echo -e "${Error} Nginx 安装失败！"
    exit 1
  fi
  config_nginx
  sed -i "s/yourdomain.com/${domain}/g" "/usr/local/nginx/conf/vhost/site_config.conf"
  systemctl restart nginx.service
  cd Nginx_Live/server || exit 1
  npm install
  npm run start &
  echo -e "${Info} Nginx_Live_DPlayer安装完成"
}
main
