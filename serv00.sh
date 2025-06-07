#!/bin/bash
re="\033[0m"
red="\033[1;91m"
green="\e[1;32m"
yellow="\e[1;33m"
purple="\e[1;35m"
red() { echo -e "\e[1;91m$1\033[0m"; }
green() { echo -e "\e[1;32m$1\033[0m"; }
yellow() { echo -e "\e[1;33m$1\033[0m"; }
purple() { echo -e "\e[1;35m$1\033[0m"; }
reading() { read -p "$(red "$1")" "$2"; }
USERNAME=$(whoami | tr '[:upper:]' '[:lower:]')
snb=$(hostname | cut -d. -f1)
nb=$(hostname | cut -d '.' -f 1 | tr -d 's')
HOSTNAME=$(hostname)
hona=$(hostname | cut -d. -f2)
if [ "$hona" = "serv00" ]; then
address="serv00.net"
keep_path="${HOME}/domains/${snb}.${USERNAME}.serv00.net/public_nodejs"
[ -d "$keep_path" ] || mkdir -p "$keep_path"
else
address="useruno.com"
fi
WORKDIR="${HOME}/domains/${USERNAME}.${address}/logs"
devil www add ${USERNAME}.${address} php > /dev/null 2>&1
FILE_PATH="${HOME}/domains/${USERNAME}.${address}/public_html"
[ -d "$FILE_PATH" ] || mkdir -p "$FILE_PATH"
[ -d "$WORKDIR" ] || (mkdir -p "$WORKDIR" && chmod 777 "$WORKDIR")
devil binexec on >/dev/null 2>&1
curl -sk "http://${snb}.${USERNAME}.${hona}.net/up" > /dev/null 2>&1

read_ip() {
cat ip.txt
reading "请输入上面三个IP中的任意一个 (建议默认回车自动选择可用IP): " IP
if [[ -z "$IP" ]]; then
IP=$(grep -m 1 "可用" ip.txt | awk -F ':' '{print $1}')
if [ -z "$IP" ]; then
IP=$(okip)
if [ -z "$IP" ]; then
IP=$(head -n 1 ip.txt | awk -F ':' '{print $1}')
fi
fi
fi
echo "$IP" > $WORKDIR/ipone.txt
IP=$(<$WORKDIR/ipone.txt)
green "你选择的IP为: $IP"
}

read_uuid() {
reading "请输入统一的uuid密码 (建议回车默认随机): " UUID
if [[ -z "$UUID" ]]; then
UUID=$(uuidgen -r)
fi
echo "$UUID" > $WORKDIR/UUID.txt
UUID=$(<$WORKDIR/UUID.txt)
green "你的uuid为: $UUID"
}

read_reym() {
yellow "方式一：(推荐)使用Serv00/Hostuno自带域名，不支持proxyip功能：输入回车"
yellow "方式二：使用CF域名(blog.cloudflare.com)，支持proxyip+非标端口反代ip功能：输入s"
yellow "方式三：支持其他域名，注意要符合reality域名规则：输入域名"
reading "请输入reality域名 【请选择 回车 或者 s 或者 输入域名】: " reym
if [[ -z "$reym" ]]; then
reym=$USERNAME.${address}
elif [[ "$reym" == "s" || "$reym" == "S" ]]; then
reym=blog.cloudflare.com
fi
echo "$reym" > $WORKDIR/reym.txt
reym=$(<$WORKDIR/reym.txt)
green "你的reality域名为: $reym"
}

resallport(){
portlist=$(devil port list | grep -E '^[0-9]+[[:space:]]+[a-zA-Z]+' | sed 's/^[[:space:]]*//')
if [[ -z "$portlist" ]]; then
yellow "无端口"
else
while read -r line; do
port=$(echo "$line" | awk '{print $1}')
port_type=$(echo "$line" | awk '{print $2}')
yellow "删除端口 $port ($port_type)"
devil port del "$port_type" "$port"
done <<< "$portlist"
fi
check_port
if [[ -e $WORKDIR/config.json ]]; then
hyp=$(jq -r '.inbounds[0].listen_port' $WORKDIR/config.json)
vlp=$(jq -r '.inbounds[3].listen_port' $WORKDIR/config.json)
vmp=$(jq -r '.inbounds[4].listen_port' $WORKDIR/config.json)
purple "检测到Serv00/Hostuno-sb-yg脚本已安装，执行端口替换，请稍等……"
sed -i '' "12s/$hyp/$hy2_port/g" $WORKDIR/config.json
sed -i '' "33s/$hyp/$hy2_port/g" $WORKDIR/config.json
sed -i '' "54s/$hyp/$hy2_port/g" $WORKDIR/config.json
sed -i '' "75s/$vlp/$vless_port/g" $WORKDIR/config.json
sed -i '' "102s/$vmp/$vmess_port/g" $WORKDIR/config.json
if [ "$hona" = "serv00" ]; then
sed -i '' -e "17s|'$vlp'|'$vless_port'|" serv00keep.sh
sed -i '' -e "18s|'$vmp'|'$vmess_port'|" serv00keep.sh
sed -i '' -e "19s|'$hyp'|'$hy2_port'|" serv00keep.sh
fi
resservsb
green "端口替换完成！"
ps aux | grep '[r]un -c con' > /dev/null && green "主进程启动成功，单节点用户修改下客户端三协议端口" || yellow "Sing-box主进程启动失败"
if [ -f "$WORKDIR/boot.log" ]; then
ps aux | grep '[t]unnel --u' > /dev/null && green "Argo临时隧道已启动，临时域名可能已变更" || yellow "Argo临时隧道启动失败"
else
ps aux | grep '[t]unnel --n' > /dev/null && green "Argo固定隧道已启动" || yellow "Argo固定隧道启动失败，请先在CF更改隧道端口：$vmess_port，再重启下Argo隧道"
fi
cd $WORKDIR
showchangelist
cd
fi
}

check_port () {
port_list=$(devil port list)
tcp_ports=$(echo "$port_list" | grep -c "tcp")
udp_ports=$(echo "$port_list" | grep -c "udp")
if [[ $tcp_ports -ne 2 || $udp_ports -ne 1 ]]; then
    red "端口数量不符合要求，正在调整..."

    if [[ $tcp_ports -gt 2 ]]; then
        tcp_to_delete=$((tcp_ports - 2))
        echo "$port_list" | awk '/tcp/ {print $1, $2}' | head -n $tcp_to_delete | while read port type; do
            devil port del $type $port
            green "已删除TCP端口: $port"
        done
    fi
    if [[ $udp_ports -gt 1 ]]; then
        udp_to_delete=$((udp_ports - 1))
        echo "$port_list" | awk '/udp/ {print $1, $2}' | head -n $udp_to_delete | while read port type; do
            devil port del $type $port
            green "已删除UDP端口: $port"
        done
    fi
    if [[ $tcp_ports -lt 2 ]]; then
        tcp_ports_to_add=$((2 - tcp_ports))
        tcp_ports_added=0
        while [[ $tcp_ports_added -lt $tcp_ports_to_add ]]; do
            tcp_port=$(shuf -i 10000-65535 -n 1) 
            result=$(devil port add tcp $tcp_port 2>&1)
            if [[ $result == *"succesfully"* ]]; then
                green "已添加TCP端口: $tcp_port"
                if [[ $tcp_ports_added -eq 0 ]]; then
                    tcp_port1=$tcp_port
                else
                    tcp_port2=$tcp_port
                fi
                tcp_ports_added=$((tcp_ports_added + 1))
            else
                yellow "端口 $tcp_port 不可用，尝试其他端口..."
            fi
        done
    fi
    if [[ $udp_ports -lt 1 ]]; then
        while true; do
            udp_port=$(shuf -i 10000-65535 -n 1) 
            result=$(devil port add udp $udp_port 2>&1)
            if [[ $result == *"succesfully"* ]]; then
                green "已添加UDP端口: $udp_port"
                break
            else
                yellow "端口 $udp_port 不可用，尝试其他端口..."
            fi
        done
    fi
    #green "端口已调整完成,将断开ssh连接,请重新连接shh重新执行脚本"
    #devil binexec on >/dev/null 2>&1
    #kill -9 $(ps -o ppid= -p $$) >/dev/null 2>&1
    sleep 3
    port_list=$(devil port list)
    tcp_ports=$(echo "$port_list" | grep -c "tcp")
    udp_ports=$(echo "$port_list" | grep -c "udp")
    tcp_ports=$(echo "$port_list" | awk '/tcp/ {print $1}')
    tcp_port1=$(echo "$tcp_ports" | sed -n '1p')
    tcp_port2=$(echo "$tcp_ports" | sed -n '2p')
    udp_port=$(echo "$port_list" | awk '/udp/ {print $1}')
    purple "当前TCP端口: $tcp_port1 和 $tcp_port2"
    purple "当前UDP端口: $udp_port"
else
    tcp_ports=$(echo "$port_list" | awk '/tcp/ {print $1}')
    tcp_port1=$(echo "$tcp_ports" | sed -n '1p')
    tcp_port2=$(echo "$tcp_ports" | sed -n '2p')
    udp_port=$(echo "$port_list" | awk '/udp/ {print $1}')
    purple "当前TCP端口: $tcp_port1 和 $tcp_port2"
    purple "当前UDP端口: $udp_port"
fi
export vless_port=$tcp_port1
export vmess_port=$tcp_port2
export hy2_port=$udp_port
green "你的vless-reality端口: $vless_port"
green "你的vmess-ws端口(设置Argo固定域名端口): $vmess_port"
green "你的hysteria2端口: $hy2_port"
}

install_singbox() {
if [[ -e $WORKDIR/list.txt ]]; then
yellow "已安装sing-box，请先选择2卸载，再执行安装" && exit
fi
sleep 2
        cd $WORKDIR
	echo
	read_ip
 	echo
        read_reym
	echo
	read_uuid
        echo
        check_port
	echo
        sleep 2
        argo_configure
	echo
        download_and_run_singbox
	cd
        fastrun
	green "创建快捷方式：sb"
	echo
        if [ "$hona" = "serv00" ]; then
	servkeep
        fi
        cd $WORKDIR
        echo
        get_links
	cd
        purple "************************************************************"
        purple "Serv00/Hostuno-sb-yg脚本安装结束"
	purple "退出SSH"
	purple "请再次连接SSH，查看主菜单，请输入快捷方式：sb"
	purple "************************************************************"
        sleep 2
        kill -9 $(ps -o ppid= -p $$) >/dev/null 2>&1
}

uninstall_singbox() {
  reading "\n确定要卸载吗？【y/n】: " choice
    case "$choice" in
       [Yy])
	  bash -c 'ps aux | grep $(whoami) | grep -v "sshd\|bash\|grep" | awk "{print \$2}" | xargs -r kill -9 >/dev/null 2>&1' >/dev/null 2>&1
          rm -rf bin domains serv00keep.sh webport.sh
	  devil www list | awk 'NR > 1 && NF {print $1}' | xargs -I {} devil www del {} > /dev/null 2>&1
	  sed -i '' '/export PATH="\$HOME\/bin:\$PATH"/d' ~/.bashrc
          source ~/.bashrc
          purple "************************************************************"
          purple "Serv00/Hostuno-sb-yg卸载完成！"
          purple "欢迎继续使用脚本：bash <(curl -Ls https://raw.githubusercontent.com/yonggekkk/sing-box-yg/main/serv00.sh)"
          purple "************************************************************"
          ;;
        [Nn]) exit 0 ;;
    	*) red "无效的选择，请输入y或n" && menu ;;
    esac
}

kill_all_tasks() {
reading "\n注意！！！清理所有进程并清空所有安装内容，将退出ssh连接，确定继续清理吗？【y/n】: " choice
  case "$choice" in
    [Yy]) 
    bash -c 'ps aux | grep $(whoami) | grep -v "sshd\|bash\|grep" | awk "{print \$2}" | xargs -r kill -9 >/dev/null 2>&1' >/dev/null 2>&1
    devil www list | awk 'NR > 1 && NF {print $1}' | xargs -I {} devil www del {} > /dev/null 2>&1
    sed -i '' '/export PATH="\$HOME\/bin:\$PATH"/d' ~/.bashrc
    source ~/.bashrc
    purple "************************************************************"
    purple "Serv00/Hostuno-sb-yg清理重置完成！"
    purple "欢迎继续使用脚本：bash <(curl -Ls https://raw.githubusercontent.com/yonggekkk/sing-box-yg/main/serv00.sh)"
    purple "************************************************************"
    find ~ -type f -exec chmod 644 {} \; 2>/dev/null
    find ~ -type d -exec chmod 755 {} \; 2>/dev/null
    find ~ -type f -exec rm -f {} \; 2>/dev/null
    find ~ -type d -empty -exec rmdir {} \; 2>/dev/null
    find ~ -exec rm -rf {} \; 2>/dev/null
    killall -9 -u $(whoami)
    ;;
    *) menu ;;
  esac
}

argo_configure() {
  while true; do
    yellow "方式一：(推荐)无需域名的Argo临时隧道：输入回车"
    yellow "方式二：需要域名的Argo固定隧道(需要CF设置提取Token)：输入g"
    reading "【请选择 g 或者 回车】: " argo_choice
    if [[ "$argo_choice" != "g" && "$argo_choice" != "G" && -n "$argo_choice" ]]; then
        red "无效的选择，请输入 g 或回车"
        continue
    fi
    if [[ "$argo_choice" == "g" || "$argo_choice" == "G" ]]; then
        reading "请输入argo固定隧道域名: " ARGO_DOMAIN
	echo "$ARGO_DOMAIN" | tee ARGO_DOMAIN.log ARGO_DOMAIN_show.log > /dev/null
        green "你的argo固定隧道域名为: $ARGO_DOMAIN"
        reading "请输入argo固定隧道密钥（当你粘贴Token时，必须以ey开头）: " ARGO_AUTH
	echo "$ARGO_AUTH" | tee ARGO_AUTH.log ARGO_AUTH_show.log > /dev/null
        green "你的argo固定隧道密钥为: $ARGO_AUTH"
	rm -rf boot.log
    else
        green "使用Argo临时隧道"
	rm -rf ARGO_AUTH.log ARGO_DOMAIN.log
    fi
    break
done
}

download_and_run_singbox() {
if [ ! -s sb.txt ] && [ ! -s ag.txt ]; then
DOWNLOAD_DIR="." && mkdir -p "$DOWNLOAD_DIR" && FILE_INFO=()
FILE_INFO=("https://github.com/yonggekkk/Cloudflare_vless_trojan/releases/download/serv00/sb web" "https://github.com/yonggekkk/Cloudflare_vless_trojan/releases/download/serv00/server bot")
declare -A FILE_MAP
generate_random_name() {
    local chars=abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890
    local name=""
    for i in {1..6}; do
        name="$name${chars:RANDOM%${#chars}:1}"
    done
    echo "$name"
}

download_with_fallback() {
    local URL=$1
    local NEW_FILENAME=$2

    curl -L -sS --max-time 2 -o "$NEW_FILENAME" "$URL" &
    CURL_PID=$!
    CURL_START_SIZE=$(stat -c%s "$NEW_FILENAME" 2>/dev/null || echo 0)
    
    sleep 1
    CURL_CURRENT_SIZE=$(stat -c%s "$NEW_FILENAME" 2>/dev/null || echo 0)
    
    if [ "$CURL_CURRENT_SIZE" -le "$CURL_START_SIZE" ]; then
        kill $CURL_PID 2>/dev/null
        wait $CURL_PID 2>/dev/null
        wget -q -O "$NEW_FILENAME" "$URL"
        echo -e "\e[1;32mDownloading $NEW_FILENAME by wget\e[0m"
    else
        wait $CURL_PID
        echo -e "\e[1;32mDownloading $NEW_FILENAME by curl\e[0m"
    fi
}

for entry in "${FILE_INFO[@]}"; do
    URL=$(echo "$entry" | cut -d ' ' -f 1)
    RANDOM_NAME=$(generate_random_name)
    NEW_FILENAME="$DOWNLOAD_DIR/$RANDOM_NAME"
    
    if [ -e "$NEW_FILENAME" ]; then
        echo -e "\e[1;32m$NEW_FILENAME already exists, Skipping download\e[0m"
    else
        download_with_fallback "$URL" "$NEW_FILENAME"
    fi
    
    chmod +x "$NEW_FILENAME"
    FILE_MAP[$(echo "$entry" | cut -d ' ' -f 2)]="$NEW_FILENAME"
done
wait
fi

if [ ! -e private_key.txt ]; then
output=$(./"$(basename ${FILE_MAP[web]})" generate reality-keypair)
private_key=$(echo "${output}" | awk '/PrivateKey:/ {print $2}')
public_key=$(echo "${output}" | awk '/PublicKey:/ {print $2}')
echo "${private_key}" > private_key.txt
echo "${public_key}" > public_key.txt
fi
private_key=$(<private_key.txt)
public_key=$(<public_key.txt)
openssl ecparam -genkey -name prime256v1 -out "private.key"
openssl req -new -x509 -days 3650 -key "private.key" -out "cert.pem" -subj "/CN=$USERNAME.${address}"
  cat > config.json << EOF
{
  "log": {
    "disabled": true,
    "level": "info",
    "timestamp": true
  },
    "inbounds": [
    {
       "tag": "hysteria-in1",
       "type": "hysteria2",
       "listen": "$(dig @8.8.8.8 +time=5 +short "web$nb.${hona}.com" | sort -u)",
       "listen_port": $hy2_port,
       "users": [
         {
             "password": "$UUID"
         }
     ],
     "masquerade": "https://www.bing.com",
     "ignore_client_bandwidth":false,
     "tls": {
         "enabled": true,
         "alpn": [
             "h3"
         ],
         "certificate_path": "cert.pem",
         "key_path": "private.key"
        }
    },
        {
       "tag": "hysteria-in2",
       "type": "hysteria2",
       "listen": "$(dig @8.8.8.8 +time=5 +short "$HOSTNAME" | sort -u)",
       "listen_port": $hy2_port,
       "users": [
         {
             "password": "$UUID"
         }
     ],
     "masquerade": "https://www.bing.com",
     "ignore_client_bandwidth":false,
     "tls": {
         "enabled": true,
         "alpn": [
             "h3"
         ],
         "certificate_path": "cert.pem",
         "key_path": "private.key"
        }
    },
        {
       "tag": "hysteria-in3",
       "type": "hysteria2",
       "listen": "$(dig @8.8.8.8 +time=5 +short "cache$nb.${hona}.com" | sort -u)",
       "listen_port": $hy2_port,
       "users": [
         {
             "password": "$UUID"
         }
     ],
     "masquerade": "https://www.bing.com",
     "ignore_client_bandwidth":false,
     "tls": {
         "enabled": true,
         "alpn": [
             "h3"
         ],
         "certificate_path": "cert.pem",
         "key_path": "private.key"
        }
    },
    {
        "tag": "vless-reality-vesion",
        "type": "vless",
        "listen": "::",
        "listen_port": $vless_port,
        "users": [
            {
              "uuid": "$UUID",
              "flow": "xtls-rprx-vision"
            }
        ],
        "tls": {
            "enabled": true,
            "server_name": "$reym",
            "reality": {
                "enabled": true,
                "handshake": {
                    "server": "$reym",
                    "server_port": 443
                },
                "private_key": "$private_key",
                "short_id": [
                  ""
                ]
            }
        }
    },
{
      "tag": "vmess-ws-in",
      "type": "vmess",
      "listen": "::",
      "listen_port": $vmess_port,
      "users": [
      {
        "uuid": "$UUID"
      }
    ],
    "transport": {
      "type": "ws",
      "path": "$UUID-vm",
      "early_data_header_name": "Sec-WebSocket-Protocol"
      }
    }
 ],
     "outbounds": [
     {
        "type": "wireguard",
        "tag": "wg",
        "server": "162.159.192.200",
        "server_port": 4500,
        "local_address": [
                "172.16.0.2/32",
                "2606:4700:110:8f77:1ca9:f086:846c:5f9e/128"
        ],
        "private_key": "wIxszdR2nMdA7a2Ul3XQcniSfSZqdqjPb6w6opvf5AU=",
        "peer_public_key": "bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=",
        "reserved": [
            126,
            246,
            173
        ]
    },
    {
      "type": "direct",
      "tag": "direct"
    }
  ],
   "route": {
       "rule_set": [
      {
        "tag": "google-gemini",
        "type": "remote",
        "format": "binary",
        "url": "https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/sing/geo/geosite/google-gemini.srs",
        "download_detour": "direct"
      }
    ],
EOF
if [[ "$nb" =~ 14|15 ]]; then
cat >> config.json <<EOF 
    "rules": [
    {
     "domain": [
     "jnn-pa.googleapis.com"
      ],
     "outbound": "wg"
     },
     {
     "rule_set":[
     "google-gemini"
     ],
     "outbound": "wg"
    }
    ],
    "final": "direct"
    }  
}
EOF
else
  cat >> config.json <<EOF
    "final": "direct"
    }  
}
EOF
fi

if ! ps aux | grep '[r]un -c con' > /dev/null; then
ps aux | grep '[r]un -c con' | awk '{print $2}' | xargs -r kill -9 > /dev/null 2>&1
if [ -e "$(basename "${FILE_MAP[web]}")" ]; then
   echo "$(basename "${FILE_MAP[web]}")" > sb.txt
   sbb=$(cat sb.txt)   
    nohup ./"$sbb" run -c config.json >/dev/null 2>&1 &
    sleep 5
if pgrep -x "$sbb" > /dev/null; then
    green "$sbb 主进程已启动"
else
    red "$sbb 主进程未启动, 重启中..."
    pkill -x "$sbb"
    nohup ./"$sbb" run -c config.json >/dev/null 2>&1 &
    sleep 2
    purple "$sbb 主进程已重启"
fi
else
    sbb=$(cat sb.txt)   
    nohup ./"$sbb" run -c config.json >/dev/null 2>&1 &
    sleep 5
if pgrep -x "$sbb" > /dev/null; then
    green "$sbb 主进程已启动"
else
    red "$sbb 主进程未启动, 重启中..."
    pkill -x "$sbb"
    nohup ./"$sbb" run -c config.json >/dev/null 2>&1 &
    sleep 2
    purple "$sbb 主进程已重启"
fi
fi
else
green "主进程已启动"
fi
cfgo() {
rm -rf boot.log
if [ -e "$(basename "${FILE_MAP[bot]}")" ]; then
   echo "$(basename "${FILE_MAP[bot]}")" > ag.txt
   agg=$(cat ag.txt)
    if [[ $ARGO_AUTH =~ ^[A-Z0-9a-z=]{120,250}$ ]]; then
      #args="tunnel --edge-ip-version auto --no-autoupdate --protocol http2 run --token ${ARGO_AUTH}"
      args="tunnel --no-autoupdate run --token ${ARGO_AUTH}"
    else
     #args="tunnel --edge-ip-version auto --no-autoupdate --protocol http2 --logfile boot.log --loglevel info --url http://localhost:$vmess_port"
     args="tunnel --url http://localhost:$vmess_port --no-autoupdate --logfile boot.log --loglevel info"
    fi
    nohup ./"$agg" $args >/dev/null 2>&1 &
    sleep 10
if pgrep -x "$agg" > /dev/null; then
    green "$agg Arog进程已启动"
else
    red "$agg Argo进程未启动, 重启中..."
    pkill -x "$agg"
    nohup ./"$agg" "${args}" >/dev/null 2>&1 &
    sleep 5
    purple "$agg Argo进程已重启"
fi
else
   agg=$(cat ag.txt)
    if [[ $ARGO_AUTH =~ ^[A-Z0-9a-z=]{120,250}$ ]]; then
      #args="tunnel --edge-ip-version auto --no-autoupdate --protocol http2 run --token ${ARGO_AUTH}"
      args="tunnel --no-autoupdate run --token ${ARGO_AUTH}"
    else
     #args="tunnel --edge-ip-version auto --no-autoupdate --protocol http2 --logfile boot.log --loglevel info --url http://localhost:$vmess_port"
     args="tunnel --url http://localhost:$vmess_port --no-autoupdate --logfile boot.log --loglevel info"
    fi
    pkill -x "$agg"
    nohup ./"$agg" $args >/dev/null 2>&1 &
    sleep 10
if pgrep -x "$agg" > /dev/null; then
    green "$agg Arog进程已启动"
else
    red "$agg Argo进程未启动, 重启中..."
    pkill -x "$agg"
    nohup ./"$agg" "${args}" >/dev/null 2>&1 &
    sleep 5
    purple "$agg Argo进程已重启"
fi
fi
}

if [ -f "$WORKDIR/boot.log" ]; then
argosl=$(cat "$WORKDIR/boot.log" 2>/dev/null | grep -a trycloudflare.com | awk 'NR==2{print}' | awk -F// '{print $2}' | awk '{print $1}')
checkhttp=$(curl -o /dev/null -s -w "%{http_code}\n" "https://$argosl")
else
argogd=$(cat $WORKDIR/ARGO_DOMAIN.log 2>/dev/null)
checkhttp=$(curl --max-time 2 -o /dev/null -s -w "%{http_code}\n" "https://$argogd")
fi
if ([ -z "$ARGO_DOMAIN" ] && ! ps aux | grep '[t]unnel --u' > /dev/null) || [ "$checkhttp" -ne 404 ]; then
ps aux | grep '[t]unnel --u' | awk '{print $2}' | xargs -r kill -9 > /dev/null 2>&1
cfgo
elif ([ -n "$ARGO_DOMAIN" ] && ! ps aux | grep '[t]unnel --n' > /dev/null) || [ "$checkhttp" -ne 404 ]; then
ps aux | grep '[t]unnel --n' | awk '{print $2}' | xargs -r kill -9 > /dev/null 2>&1
cfgo
else
green "Arog进程已启动"
fi
sleep 2
if ! pgrep -x "$(cat sb.txt)" > /dev/null; then
red "主进程未启动，根据以下情况一一排查"
yellow "1、选择8重置端口，自动生成随机可用端口（重要）"
yellow "2、选择9重置"
yellow "3、当前Serv00/Hostuno服务器炸了？等会再试"
red "4、以上都试了，哥直接躺平，交给进程保活，过会再来看"
sleep 6
fi
}

get_argodomain() {
  if [[ -n $ARGO_AUTH ]]; then
    echo "$ARGO_DOMAIN"
  else
    local retry=0
    local max_retries=6
    local argodomain=""
    while [[ $retry -lt $max_retries ]]; do
    ((retry++)) 
    argodomain=$(cat boot.log 2>/dev/null | grep -a trycloudflare.com | awk 'NR==2{print}' | awk -F// '{print $2}' | awk '{print $1}')
      if [[ -n $argodomain ]]; then
        break
      fi
      sleep 2
    done  
    if [ -z ${argodomain} ]; then
    argodomain="Argo临时域名暂时获取失败，Argo节点暂不可用(保活过程中会自动恢复)，其他节点依旧可用"
    fi
    echo "$argodomain"
  fi
}

get_links(){
argodomain=$(get_argodomain)
echo -e "\e[1;32mArgo域名：\e[1;35m${argodomain}\e[0m\n"
a=$(dig @8.8.8.8 +time=5 +short "web$nb.${hona}.com" | sort -u)
b=$(dig @8.8.8.8 +time=5 +short "$HOSTNAME" | sort -u)
c=$(dig @8.8.8.8 +time=5 +short "cache$nb.${hona}.com" | sort -u)
if [[ "$IP" == "$a" ]]; then
CIP1=$b; CIP2=$c
elif [[ "$IP" == "$b" ]]; then
CIP1=$a; CIP2=$c
elif [[ "$IP" == "$c" ]]; then
CIP1=$a; CIP2=$b
else
red "执行出错，请卸载脚本再重装一次"
fi
vl_link="vless://$UUID@$IP:$vless_port?encryption=none&flow=xtls-rprx-vision&security=reality&sni=$reym&fp=chrome&pbk=$public_key&type=tcp&headerType=none#$snb-reality-$USERNAME"
echo "$vl_link" > jh.txt
vmws_link="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"$snb-vmess-ws-$USERNAME\", \"add\": \"$IP\", \"port\": \"$vmess_port\", \"id\": \"$UUID\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"\", \"path\": \"/$UUID-vm?ed=2048\", \"tls\": \"\", \"sni\": \"\", \"alpn\": \"\", \"fp\": \"\"}" | base64 -w0)"
echo "$vmws_link" >> jh.txt
vmatls_link="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"$snb-vmess-ws-tls-argo-$USERNAME\", \"add\": \"www.visa.com.hk\", \"port\": \"8443\", \"id\": \"$UUID\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argodomain\", \"path\": \"/$UUID-vm?ed=2048\", \"tls\": \"tls\", \"sni\": \"$argodomain\", \"alpn\": \"\", \"fp\": \"\"}" | base64 -w0)"
echo "$vmatls_link" >> jh.txt
vma_link="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"$snb-vmess-ws-argo-$USERNAME\", \"add\": \"www.visa.com.hk\", \"port\": \"8880\", \"id\": \"$UUID\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argodomain\", \"path\": \"/$UUID-vm?ed=2048\", \"tls\": \"\"}" | base64 -w0)"
echo "$vma_link" >> jh.txt
hy2_link="hysteria2://$UUID@$IP:$hy2_port?security=tls&sni=www.bing.com&alpn=h3&insecure=1#$snb-hy2-$USERNAME"
echo "$hy2_link" >> jh.txt
vl_link1="vless://$UUID@$CIP1:$vless_port?encryption=none&flow=xtls-rprx-vision&security=reality&sni=$reym&fp=chrome&pbk=$public_key&type=tcp&headerType=none#$snb-reality-$USERNAME-$CIP1"
echo "$vl_link1" >> jh.txt
vmws_link1="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"$snb-vmess-ws-$USERNAME-$CIP1\", \"add\": \"$CIP1\", \"port\": \"$vmess_port\", \"id\": \"$UUID\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"\", \"path\": \"/$UUID-vm?ed=2048\", \"tls\": \"\", \"sni\": \"\", \"alpn\": \"\", \"fp\": \"\"}" | base64 -w0)"
echo "$vmws_link1" >> jh.txt
hy2_link1="hysteria2://$UUID@$CIP1:$hy2_port?security=tls&sni=www.bing.com&alpn=h3&insecure=1#$snb-hy2-$USERNAME-$CIP1"
echo "$hy2_link1" >> jh.txt
vl_link2="vless://$UUID@$CIP2:$vless_port?encryption=none&flow=xtls-rprx-vision&security=reality&sni=$reym&fp=chrome&pbk=$public_key&type=tcp&headerType=none#$snb-reality-$USERNAME-$CIP2"
echo "$vl_link2" >> jh.txt
vmws_link2="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"$snb-vmess-ws-$USERNAME-$CIP2\", \"add\": \"$CIP2\", \"port\": \"$vmess_port\", \"id\": \"$UUID\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"\", \"path\": \"/$UUID-vm?ed=2048\", \"tls\": \"\", \"sni\": \"\", \"alpn\": \"\", \"fp\": \"\"}" | base64 -w0)"
echo "$vmws_link2" >> jh.txt
hy2_link2="hysteria2://$UUID@$CIP2:$hy2_port?security=tls&sni=www.bing.com&alpn=h3&insecure=1#$snb-hy2-$USERNAME-$CIP2"
echo "$hy2_link2" >> jh.txt

argosl=$(cat "$WORKDIR/boot.log" 2>/dev/null | grep -a trycloudflare.com | awk 'NR==2{print}' | awk -F// '{print $2}' | awk '{print $1}')
checkhttp1=$(curl -o /dev/null -s -w "%{http_code}\n" "https://$argosl")
argogd=$(cat $WORKDIR/ARGO_DOMAIN.log 2>/dev/null)
checkhttp2=$(curl --max-time 2 -o /dev/null -s -w "%{http_code}\n" "https://$argogd")
if [[ "$checkhttp1" == 404 ]] || [[ "$checkhttp2" == 404 ]]; then
vmatls_link1="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"$snb-vmess-ws-tls-argo-$USERNAME-443\", \"add\": \"104.16.0.0\", \"port\": \"443\", \"id\": \"$UUID\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argodomain\", \"path\": \"/$UUID-vm?ed=2048\", \"tls\": \"tls\", \"sni\": \"$argodomain\", \"alpn\": \"\", \"fp\": \"\"}" | base64 -w0)"
echo "$vmatls_link1" >> jh.txt
vmatls_link2="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"$snb-vmess-ws-tls-argo-$USERNAME-2053\", \"add\": \"104.17.0.0\", \"port\": \"2053\", \"id\": \"$UUID\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argodomain\", \"path\": \"/$UUID-vm?ed=2048\", \"tls\": \"tls\", \"sni\": \"$argodomain\", \"alpn\": \"\", \"fp\": \"\"}" | base64 -w0)"
echo "$vmatls_link2" >> jh.txt
vmatls_link3="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"$snb-vmess-ws-tls-argo-$USERNAME-2083\", \"add\": \"104.18.0.0\", \"port\": \"2083\", \"id\": \"$UUID\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argodomain\", \"path\": \"/$UUID-vm?ed=2048\", \"tls\": \"tls\", \"sni\": \"$argodomain\", \"alpn\": \"\", \"fp\": \"\"}" | base64 -w0)"
echo "$vmatls_link3" >> jh.txt
vmatls_link4="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"$snb-vmess-ws-tls-argo-$USERNAME-2087\", \"add\": \"104.19.0.0\", \"port\": \"2087\", \"id\": \"$UUID\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argodomain\", \"path\": \"/$UUID-vm?ed=2048\", \"tls\": \"tls\", \"sni\": \"$argodomain\", \"alpn\": \"\", \"fp\": \"\"}" | base64 -w0)"
echo "$vmatls_link4" >> jh.txt
vmatls_link5="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"$snb-vmess-ws-tls-argo-$USERNAME-2096\", \"add\": \"104.20.0.0\", \"port\": \"2096\", \"id\": \"$UUID\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argodomain\", \"path\": \"/$UUID-vm?ed=2048\", \"tls\": \"tls\", \"sni\": \"$argodomain\", \"alpn\": \"\", \"fp\": \"\"}" | base64 -w0)"
echo "$vmatls_link5" >> jh.txt
vma_link6="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"$snb-vmess-ws-argo-$USERNAME-80\", \"add\": \"104.21.0.0\", \"port\": \"80\", \"id\": \"$UUID\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argodomain\", \"path\": \"/$UUID-vm?ed=2048\", \"tls\": \"\"}" | base64 -w0)"
echo "$vma_link6" >> jh.txt
vma_link7="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"$snb-vmess-ws-argo-$USERNAME-8080\", \"add\": \"104.22.0.0\", \"port\": \"8080\", \"id\": \"$UUID\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argodomain\", \"path\": \"/$UUID-vm?ed=2048\", \"tls\": \"\"}" | base64 -w0)"
echo "$vma_link7" >> jh.txt
vma_link8="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"$snb-vmess-ws-argo-$USERNAME-2052\", \"add\": \"104.24.0.0\", \"port\": \"2052\", \"id\": \"$UUID\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argodomain\", \"path\": \"/$UUID-vm?ed=2048\", \"tls\": \"\"}" | base64 -w0)"
echo "$vma_link8" >> jh.txt
vma_link9="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"$snb-vmess-ws-argo-$USERNAME-2082\", \"add\": \"104.25.0.0\", \"port\": \"2082\", \"id\": \"$UUID\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argodomain\", \"path\": \"/$UUID-vm?ed=2048\", \"tls\": \"\"}" | base64 -w0)"
echo "$vma_link9" >> jh.txt
vma_link10="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"$snb-vmess-ws-argo-$USERNAME-2086\", \"add\": \"104.26.0.0\", \"port\": \"2086\", \"id\": \"$UUID\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argodomain\", \"path\": \"/$UUID-vm?ed=2048\", \"tls\": \"\"}" | base64 -w0)"
echo "$vma_link10" >> jh.txt
vma_link11="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"$snb-vmess-ws-argo-$USERNAME-2095\", \"add\": \"104.27.0.0\", \"port\": \"2095\", \"id\": \"$UUID\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argodomain\", \"path\": \"/$UUID-vm?ed=2048\", \"tls\": \"\"}" | base64 -w0)"
echo "$vma_link11" >> jh.txt
fi
v2sub=$(cat jh.txt)
echo "$v2sub" > ${FILE_PATH}/${UUID}_v2sub.txt
baseurl=$(base64 -w 0 < jh.txt)

cat > sing_box.json <<EOF
{
  "log": {
    "disabled": false,
    "level": "info",
    "timestamp": true
  },
  "experimental": {
    "clash_api": {
      "external_controller": "127.0.0.1:9090",
      "external_ui": "ui",
      "external_ui_download_url": "",
      "external_ui_download_detour": "",
      "secret": "",
      "default_mode": "Rule"
       },
      "cache_file": {
            "enabled": true,
            "path": "cache.db",
            "store_fakeip": true
        }
    },
    "dns": {
        "servers": [
            {
                "tag": "proxydns",
                "address": "tls://8.8.8.8/dns-query",
                "detour": "select"
            },
            {
                "tag": "localdns",
                "address": "h3://223.5.5.5/dns-query",
                "detour": "direct"
            },
            {
                "tag": "dns_fakeip",
                "address": "fakeip"
            }
        ],
        "rules": [
            {
                "outbound": "any",
                "server": "localdns",
                "disable_cache": true
            },
            {
                "clash_mode": "Global",
                "server": "proxydns"
            },
            {
                "clash_mode": "Direct",
                "server": "localdns"
            },
            {
                "rule_set": "geosite-cn",
                "server": "localdns"
            },
            {
                 "rule_set": "geosite-geolocation-!cn",
                 "server": "proxydns"
            },
             {
                "rule_set": "geosite-geolocation-!cn",         
                "query_type": [
                    "A",
                    "AAAA"
                ],
                "server": "dns_fakeip"
            }
          ],
           "fakeip": {
           "enabled": true,
           "inet4_range": "198.18.0.0/15",
           "inet6_range": "fc00::/18"
         },
          "independent_cache": true,
          "final": "proxydns"
        },
      "inbounds": [
    {
      "type": "tun",
           "tag": "tun-in",
	  "address": [
      "172.19.0.1/30",
	  "fd00::1/126"
      ],
      "auto_route": true,
      "strict_route": true,
      "sniff": true,
      "sniff_override_destination": true,
      "domain_strategy": "prefer_ipv4"
    }
  ],
  "outbounds": [
    {
      "tag": "select",
      "type": "selector",
      "default": "auto",
      "outbounds": [
        "auto",
        "vless-$snb-$USERNAME",
        "vmess-$snb-$USERNAME",
        "hy2-$snb-$USERNAME",
"vmess-tls-argo-$snb-$USERNAME",
"vmess-argo-$snb-$USERNAME"
      ]
    },
    {
      "type": "vless",
      "tag": "vless-$snb-$USERNAME",
      "server": "$IP",
      "server_port": $vless_port,
      "uuid": "$UUID",
      "packet_encoding": "xudp",
      "flow": "xtls-rprx-vision",
      "tls": {
        "enabled": true,
        "server_name": "$reym",
        "utls": {
          "enabled": true,
          "fingerprint": "chrome"
        },
      "reality": {
          "enabled": true,
          "public_key": "$public_key",
          "short_id": ""
        }
      }
    },
{
            "server": "$IP",
            "server_port": $vmess_port,
            "tag": "vmess-$snb-$USERNAME",
            "tls": {
                "enabled": false,
                "server_name": "www.bing.com",
                "insecure": false,
                "utls": {
                    "enabled": true,
                    "fingerprint": "chrome"
                }
            },
            "packet_encoding": "packetaddr",
            "transport": {
                "headers": {
                    "Host": [
                        "www.bing.com"
                    ]
                },
                "path": "/$UUID-vm",
                "type": "ws"
            },
            "type": "vmess",
            "security": "auto",
            "uuid": "$UUID"
        },

    {
        "type": "hysteria2",
        "tag": "hy2-$snb-$USERNAME",
        "server": "$IP",
        "server_port": $hy2_port,
        "password": "$UUID",
        "tls": {
            "enabled": true,
            "server_name": "www.bing.com",
            "insecure": true,
            "alpn": [
                "h3"
            ]
        }
    },
{
            "server": "www.visa.com.hk",
            "server_port": 8443,
            "tag": "vmess-tls-argo-$snb-$USERNAME",
            "tls": {
                "enabled": true,
                "server_name": "$argodomain",
                "insecure": false,
                "utls": {
                    "enabled": true,
                    "fingerprint": "chrome"
                }
            },
            "packet_encoding": "packetaddr",
            "transport": {
                "headers": {
                    "Host": [
                        "$argodomain"
                    ]
                },
                "path": "/$UUID-vm",
                "type": "ws"
            },
            "type": "vmess",
            "security": "auto",
            "uuid": "$UUID"
        },
{
            "server": "www.visa.com.hk",
            "server_port": 8880,
            "tag": "vmess-argo-$snb-$USERNAME",
            "tls": {
                "enabled": false,
                "server_name": "$argodomain",
                "insecure": false,
                "utls": {
                    "enabled": true,
                    "fingerprint": "chrome"
                }
            },
            "packet_encoding": "packetaddr",
            "transport": {
                "headers": {
                    "Host": [
                        "$argodomain"
                    ]
                },
                "path": "/$UUID-vm",
                "type": "ws"
            },
            "type": "vmess",
            "security": "auto",
            "uuid": "$UUID"
        },
    {
      "tag": "direct",
      "type": "direct"
    },
    {
      "tag": "auto",
      "type": "urltest",
      "outbounds": [
        "vless-$snb-$USERNAME",
        "vmess-$snb-$USERNAME",
        "hy2-$snb-$USERNAME",
        "vmess-tls-argo-$snb-$USERNAME",
        "vmess-argo-$snb-$USERNAME"
      ],
      "url": "https://www.gstatic.com/generate_204",
      "interval": "1m",
      "tolerance": 50,
      "interrupt_exist_connections": false
    }
  ],
  "route": {
      "rule_set": [
            {
                "tag": "geosite-geolocation-!cn",
                "type": "remote",
                "format": "binary",
                "url": "https://cdn.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo/geosite/geolocation-!cn.srs",
                "download_detour": "select",
                "update_interval": "1d"
            },
            {
                "tag": "geosite-cn",
                "type": "remote",
                "format": "binary",
                "url": "https://cdn.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo/geosite/geolocation-cn.srs",
                "download_detour": "select",
                "update_interval": "1d"
            },
            {
                "tag": "geoip-cn",
                "type": "remote",
                "format": "binary",
                "url": "https://cdn.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo/geoip/cn.srs",
                "download_detour": "select",
                "update_interval": "1d"
            }
        ],
    "auto_detect_interface": true,
    "final": "select",
    "rules": [
      {
      "inbound": "tun-in",
      "action": "sniff"
      },
      {
      "protocol": "dns",
      "action": "hijack-dns"
      },
      {
      "port": 443,
      "network": "udp",
      "action": "reject"
      },
      {
        "clash_mode": "Direct",
        "outbound": "direct"
      },
      {
        "clash_mode": "Global",
        "outbound": "select"
      },
      {
        "rule_set": "geoip-cn",
        "outbound": "direct"
      },
      {
        "rule_set": "geosite-cn",
        "outbound": "direct"
      },
      {
      "ip_is_private": true,
      "outbound": "direct"
      },
      {
        "rule_set": "geosite-geolocation-!cn",
        "outbound": "select"
      }
    ]
  },
    "ntp": {
    "enabled": true,
    "server": "time.apple.com",
    "server_port": 123,
    "interval": "30m",
    "detour": "direct"
  }
}
EOF

cat > clash_meta.yaml <<EOF
port: 7890
allow-lan: true
mode: rule
log-level: info
unified-delay: true
global-client-fingerprint: chrome
dns:
  enable: false
  listen: :53
  ipv6: true
  enhanced-mode: fake-ip
  fake-ip-range: 198.18.0.1/16
  default-nameserver: 
    - 223.5.5.5
    - 8.8.8.8
  nameserver:
    - https://dns.alidns.com/dns-query
    - https://doh.pub/dns-query
  fallback:
    - https://1.0.0.1/dns-query
    - tls://dns.google
  fallback-filter:
    geoip: true
    geoip-code: CN
    ipcidr:
      - 240.0.0.0/4

proxies:
- name: vless-reality-vision-$snb-$USERNAME               
  type: vless
  server: $IP                           
  port: $vless_port                                
  uuid: $UUID   
  network: tcp
  udp: true
  tls: true
  flow: xtls-rprx-vision
  servername: $reym                 
  reality-opts: 
    public-key: $public_key                      
  client-fingerprint: chrome                  

- name: vmess-ws-$snb-$USERNAME                         
  type: vmess
  server: $IP                       
  port: $vmess_port                                     
  uuid: $UUID       
  alterId: 0
  cipher: auto
  udp: true
  tls: false
  network: ws
  servername: www.bing.com                    
  ws-opts:
    path: "/$UUID-vm"                             
    headers:
      Host: www.bing.com                     

- name: hysteria2-$snb-$USERNAME                            
  type: hysteria2                                      
  server: $IP                               
  port: $hy2_port                                
  password: $UUID                          
  alpn:
    - h3
  sni: www.bing.com                               
  skip-cert-verify: true
  fast-open: true

- name: vmess-tls-argo-$snb-$USERNAME                         
  type: vmess
  server: www.visa.com.hk                        
  port: 8443                                     
  uuid: $UUID       
  alterId: 0
  cipher: auto
  udp: true
  tls: true
  network: ws
  servername: $argodomain                    
  ws-opts:
    path: "/$UUID-vm"                             
    headers:
      Host: $argodomain

- name: vmess-argo-$snb-$USERNAME                         
  type: vmess
  server: www.visa.com.hk                        
  port: 8880                                     
  uuid: $UUID       
  alterId: 0
  cipher: auto
  udp: true
  tls: false
  network: ws
  servername: $argodomain                   
  ws-opts:
    path: "/$UUID-vm"                             
    headers:
      Host: $argodomain 

proxy-groups:
- name: Balance
  type: load-balance
  url: https://www.gstatic.com/generate_204
  interval: 300
  strategy: round-robin
  proxies:
    - vless-reality-vision-$snb-$USERNAME                              
    - vmess-ws-$snb-$USERNAME
    - hysteria2-$snb-$USERNAME
    - vmess-tls-argo-$snb-$USERNAME
    - vmess-argo-$snb-$USERNAME

- name: Auto
  type: url-test
  url: https://www.gstatic.com/generate_204
  interval: 300
  tolerance: 50
  proxies:
    - vless-reality-vision-$snb-$USERNAME                             
    - vmess-ws-$snb-$USERNAME
    - hysteria2-$snb-$USERNAME
    - vmess-tls-argo-$snb-$USERNAME
    - vmess-argo-$snb-$USERNAME
    
- name: Select
  type: select
  proxies:
    - Balance                                         
    - Auto
    - DIRECT
    - vless-reality-vision-$snb-$USERNAME                              
    - vmess-ws-$snb-$USERNAME
    - hysteria2-$snb-$USERNAME
    - vmess-tls-argo-$snb-$USERNAME
    - vmess-argo-$snb-$USERNAME
rules:
  - GEOIP,LAN,DIRECT
  - GEOIP,CN,DIRECT
  - MATCH,Select
  
EOF

cat clash_meta.yaml > ${FILE_PATH}/${UUID}_clashmeta.txt
cat sing_box.json > ${FILE_PATH}/${UUID}_singbox.txt
V2rayN_LINK="https://${USERNAME}.${address}/${UUID}_v2sub.txt"
Clashmeta_LINK="https://${USERNAME}.${address}/${UUID}_clashmeta.txt"
Singbox_LINK="https://${USERNAME}.${address}/${UUID}_singbox.txt"
hyp=$(jq -r '.inbounds[0].listen_port' config.json)
vlp=$(jq -r '.inbounds[3].listen_port' config.json)
vmp=$(jq -r '.inbounds[4].listen_port' config.json)
showuuid=$(jq -r '.inbounds[0].users[0].password' config.json)
cat > list.txt <<EOF
=================================================================================================

当前客户端正在使用的IP：$IP
如默认节点IP被墙，可在客户端地址更换以下其他IP
$a
$b
$c

当前各协议正在使用的端口如下
vless-reality端口：$vlp
Vmess-ws端口(设置Argo固定域名端口)：$vmp
Hysteria2端口：$hyp

UUID密码：$showuuid

Argo域名：${argodomain}
-------------------------------------------------------------------------------------------------

一、Vless-reality分享链接如下：
$vl_link

注意：如果之前输入的reality域名为CF域名，将激活以下功能：
可应用在 https://github.com/yonggekkk/Cloudflare_vless_trojan 项目中创建CF vless/trojan 节点
1、Proxyip(带端口)信息如下：
方式一全局应用：设置变量名：proxyip    设置变量值：$IP:$vless_port  
方式二单节点应用：path路径改为：/pyip=$IP:$vless_port
CF节点的TLS可开可关
CF节点落地到CF网站的地区为：$IP所在地区

2、非标端口反代IP信息如下：
客户端优选IP地址为：$IP，端口：$vless_port
CF节点的TLS必须开启
CF节点落地到非CF网站的地区为：$IP所在地区

注：如果Serv00/Hostuno的IP被墙，proxyip依旧有效，但用于客户端地址的非标端口反代IP将不可用
注：可能有大佬会扫Serv00/Hostuno的反代IP作为其共享IP库或者出售，请慎重将reality域名设置为CF域名
-------------------------------------------------------------------------------------------------


二、Vmess-ws分享链接三形态如下：

1、Vmess-ws主节点分享链接如下：
(该节点默认不支持CDN，如果设置为CDN回源(需域名)：客户端地址可自行修改优选IP/域名，7个80系端口随便换，被墙依旧能用！)
$vmws_link

2、Vmess-ws-tls_Argo分享链接如下： 
(该节点为CDN优选IP节点，客户端地址可自行修改优选IP/域名，6个443系端口随便换，被墙依旧能用！)
$vmatls_link

3、Vmess-ws_Argo分享链接如下：
(该节点为CDN优选IP节点，客户端地址可自行修改优选IP/域名，7个80系端口随便换，被墙依旧能用！)
$vma_link
-------------------------------------------------------------------------------------------------


三、HY2分享链接如下：
$hy2_link
-------------------------------------------------------------------------------------------------


四、聚合通用节点，共计22个节点：
3个IP全覆盖：3个reality、3个vmess+ws、3个hy2
13个argo节点全覆盖 (已添加CF不死IP)：7个关tls 80系端口节点、6个开tls 443系端口节点

订阅分享链接：
$V2rayN_LINK

剪切分享码：
$baseurl
-------------------------------------------------------------------------------------------------


五、查看Sing-box与Clash-meta的订阅配置文件，请进入主菜单选择4

Clash-meta订阅分享链接：
$Clashmeta_LINK

Sing-box订阅分享链接：
$Singbox_LINK
-------------------------------------------------------------------------------------------------

=================================================================================================

EOF
cat list.txt
sleep 2
rm -rf sb.log core tunnel.yml tunnel.json fake_useragent_0.2.0.json
}

showlist(){
if [[ -e $WORKDIR/list.txt ]]; then
green "查看节点、订阅、反代IP、ProxyIP等信息！更新中，请稍等……"
sleep 3
cat $WORKDIR/list.txt
else
red "未安装脚本，请选择1进行安装" && exit
fi
}

showsbclash(){
if [[ -e $WORKDIR/sing_box.json ]]; then
green "查看clash与singbox配置明文！更新中，请稍等……"
sleep 3
green "Sing_box配置文件如下，可上传到订阅类客户端上使用："
yellow "其中Argo节点为CDN优选IP节点，server地址可自行修改优选IP/域名，被墙依旧能用！"
sleep 2
cat $WORKDIR/sing_box.json 
echo
echo
green "Clash_meta配置文件如下，可上传到订阅类客户端上使用："
yellow "其中Argo节点为CDN优选IP节点，server地址可自行修改优选IP/域名，被墙依旧能用！"
sleep 2
cat $WORKDIR/clash_meta.yaml
echo
else
red "未安装脚本，请选择1进行安装" && exit
fi
}

servkeep() {
sed -i '' -e "14s|''|'$UUID'|" serv00keep.sh
sed -i '' -e "17s|''|'$vless_port'|" serv00keep.sh
sed -i '' -e "18s|''|'$vmess_port'|" serv00keep.sh
sed -i '' -e "19s|''|'$hy2_port'|" serv00keep.sh
sed -i '' -e "20s|''|'$IP'|" serv00keep.sh
sed -i '' -e "21s|''|'$reym'|" serv00keep.sh
if [ ! -f "$WORKDIR/boot.log" ]; then
sed -i '' -e "15s|''|'${ARGO_DOMAIN}'|" serv00keep.sh
sed -i '' -e "16s|''|'${ARGO_AUTH}'|" serv00keep.sh
fi
echo '#!/bin/bash
red() { echo -e "\e[1;91m$1\033[0m"; }
green() { echo -e "\e[1;32m$1\033[0m"; }
yellow() { echo -e "\e[1;33m$1\033[0m"; }
purple() { echo -e "\e[1;35m$1\033[0m"; }
USERNAME=$(whoami | tr '\''[:upper:]'\'' '\''[:lower:]'\'')
WORKDIR="${HOME}/domains/${USERNAME}.serv00.net/logs"
snb=$(hostname | cut -d. -f1)
hona=$(hostname | cut -d. -f2)
' > webport.sh
declare -f resallport >> webport.sh
declare -f check_port >> webport.sh
declare -f resservsb >> webport.sh
echo 'resallport' >> webport.sh
chmod +x webport.sh
green "开始安装多功能主页，请稍等……"
devil www del ${snb}.${USERNAME}.${hona}.net > /dev/null 2>&1
devil www add ${USERNAME}.${hona}.net php > /dev/null 2>&1
devil www add ${snb}.${USERNAME}.${hona}.net nodejs /usr/local/bin/node18 > /dev/null 2>&1
ln -fs /usr/local/bin/node18 ~/bin/node > /dev/null 2>&1
ln -fs /usr/local/bin/npm18 ~/bin/npm > /dev/null 2>&1
mkdir -p ~/.npm-global
npm config set prefix '~/.npm-global'
echo 'export PATH=~/.npm-global/bin:~/bin:$PATH' >> $HOME/.bash_profile && source $HOME/.bash_profile
rm -rf $HOME/.npmrc > /dev/null 2>&1
cd "$keep_path"
npm install basic-auth express dotenv axios --silent > /dev/null 2>&1
rm $HOME/domains/${snb}.${USERNAME}.${hona}.net/public_nodejs/public/index.html > /dev/null 2>&1
devil www restart ${snb}.${USERNAME}.${hona}.net
curl -sk "http://${snb}.${USERNAME}.${hona}.net/up" > /dev/null 2>&1
green "安装完毕，多功能主页地址：http://${snb}.${USERNAME}.${hona}.net" && sleep 2
}

okip(){
    IP_LIST=($(devil vhost list | awk '/^[0-9]+/ {print $1}'))
    API_URL="https://status.eooce.com/api"
    IP=""
    THIRD_IP=${IP_LIST[2]}
    RESPONSE=$(curl -s --max-time 2 "${API_URL}/${THIRD_IP}")
    if [[ $(echo "$RESPONSE" | jq -r '.status') == "Available" ]]; then
        IP=$THIRD_IP
    else
        FIRST_IP=${IP_LIST[0]}
        RESPONSE=$(curl -s --max-time 2 "${API_URL}/${FIRST_IP}")
        
        if [[ $(echo "$RESPONSE" | jq -r '.status') == "Available" ]]; then
            IP=$FIRST_IP
        else
            IP=${IP_LIST[1]}
        fi
    fi
    echo "$IP"
    }

fastrun(){
if [[ -e $WORKDIR/config.json ]]; then
  COMMAND="sb"
  SCRIPT_PATH="$HOME/bin/$COMMAND"
  mkdir -p "$HOME/bin"
  curl -Ls https://raw.githubusercontent.com/yonggekkk/sing-box-yg/main/serv00.sh > "$SCRIPT_PATH"
  chmod +x "$SCRIPT_PATH"
if [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
    echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.bashrc"
    grep -qxF 'source ~/.bashrc' ~/.bash_profile 2>/dev/null || echo 'source ~/.bashrc' >> ~/.bash_profile
    source ~/.bashrc
fi
if [ "$hona" = "serv00" ]; then
curl -sL https://raw.githubusercontent.com/yonggekkk/sing-box-yg/main/app.js -o "$keep_path"/app.js
sed -i '' "15s/name/$snb/g" "$keep_path"/app.js
sed -i '' "59s/key/$UUID/g" "$keep_path"/app.js
sed -i '' "90s/name/$USERNAME/g" "$keep_path"/app.js
sed -i '' "90s/where/$snb/g" "$keep_path"/app.js
curl -sSL https://raw.githubusercontent.com/yonggekkk/sing-box-yg/main/serv00keep.sh -o serv00keep.sh && chmod +x serv00keep.sh
fi
curl -sL https://raw.githubusercontent.com/yonggekkk/sing-box-yg/main/index.html -o "$FILE_PATH"/index.html
curl -sL https://raw.githubusercontent.com/yonggekkk/sing-box-yg/main/sversion | awk -F "更新内容" '{print $1}' | head -n 1 > $WORKDIR/v
else
red "未安装脚本，请选择1进行安装" && exit
fi
}

resservsb(){
if [[ -e $WORKDIR/config.json ]]; then
yellow "重启中……请稍后……"
cd $WORKDIR
ps aux | grep '[r]un -c con' | awk '{print $2}' | xargs -r kill -9 > /dev/null 2>&1
if [ "$hona" = "serv00" ]; then
curl -sk "http://${snb}.${USERNAME}.${hona}.net/up" > /dev/null 2>&1
sleep 5
else
sbb=$(cat sb.txt)
nohup ./"$sbb" run -c config.json >/dev/null 2>&1 &
sleep 1
fi
if pgrep -x "$sbb" > /dev/null; then
green "$sbb 主进程重启成功"
else
red "$sbb 主进程重启失败"
fi
cd
else
red "未安装脚本，请选择1进行安装" && exit
fi
}

resargo(){
if [[ -e $WORKDIR/config.json ]]; then
cd $WORKDIR
argoport=$(jq -r '.inbounds[4].listen_port' config.json)
yellow "你可以重置临时隧道; 可以继续使用上回的固定隧道; 也可以更换固定隧道的域名或token"
argogdshow(){
echo
if [ -f ARGO_AUTH_show.log ]; then
purple "上回设置的Argo固定域名：$(cat ARGO_DOMAIN_show.log 2>/dev/null)"
purple "上回固定隧道的Token：$(cat ARGO_AUTH_show.log 2>/dev/null)"
purple "目前检查CF官网的Argo固定隧道端口：$argoport"
fi
echo
}
if [ -f boot.log ]; then
green "当前正在使用Argo临时隧道"
argogdshow
else
green "当前正在使用Argo固定隧道"
argogdshow
fi
argo_configure
ps aux | grep '[t]unnel --u' | awk '{print $2}' | xargs -r kill -9 > /dev/null 2>&1
ps aux | grep '[t]unnel --n' | awk '{print $2}' | xargs -r kill -9 > /dev/null 2>&1
agg=$(cat ag.txt)
if [[ "$argo_choice" =~ (G|g) ]]; then
if [ "$hona" = "serv00" ]; then
sed -i '' -e "15s|''|'$(cat ARGO_DOMAIN_show.log 2>/dev/null)'|" ~/serv00keep.sh
sed -i '' -e "16s|''|'$(cat ARGO_AUTH_show.log 2>/dev/null)'|" ~/serv00keep.sh
fi
args="tunnel --no-autoupdate run --token $(cat ARGO_AUTH_show.log)"
else
rm -rf boot.log
if [ "$hona" = "serv00" ]; then
sed -i '' -e "15s|'$(cat ARGO_DOMAIN_show.log 2>/dev/null)'|''|" ~/serv00keep.sh
sed -i '' -e "16s|'$(cat ARGO_AUTH_show.log 2>/dev/null)'|''|" ~/serv00keep.sh
fi
args="tunnel --url http://localhost:$argoport --no-autoupdate --logfile boot.log --loglevel info"
fi
    nohup ./"$agg" $args >/dev/null 2>&1 &
    sleep 10
if pgrep -x "$agg" > /dev/null; then
    green "$agg Argo进程已启动"
else
    red "$agg Argo进程未启动, 重启中..."
    pkill -x "$agg"
    nohup ./"$agg" "${args}" >/dev/null 2>&1 &
    sleep 5
    purple "$agg Argo进程已重启"
fi
showchangelist
cd
else
red "未安装脚本，请选择1进行安装" && exit
fi
}

showchangelist(){
IP=$(<$WORKDIR/ipone.txt)
UUID=$(<$WORKDIR/UUID.txt)
reym=$(<$WORKDIR/reym.txt)
ARGO_DOMAIN=$(cat "$WORKDIR/ARGO_DOMAIN.log" 2>/dev/null)
ARGO_AUTH=$(cat "$WORKDIR/ARGO_AUTH.log" 2>/dev/null)
check_port >/dev/null 2>&1
download_and_run_singbox >/dev/null 2>&1
get_links
}

menu() {
   clear
   echo "============================================================"
   green "甬哥Github项目  ：github.com/yonggekkk"
   green "甬哥Blogger博客 ：ygkkk.blogspot.com"
   green "甬哥YouTube频道 ：www.youtube.com/@ygkkk"
   green "Serv00/Hostuno三协议共存脚本：vless-reality/Vmess-ws(Argo)/Hy2"
   green "脚本快捷方式：sb"
   echo   "============================================================"
   green  "1. 一键安装 Serv00/Hostuno-sb-yg"
   echo   "------------------------------------------------------------"
   yellow "2. 卸载删除 Serv00/Hostuno-sb-yg"
   echo   "------------------------------------------------------------"
   green  "3. 重启主进程 (修复主节点)"
   echo   "------------------------------------------------------------"
   green  "4. Argo重置（临时隧道与固定隧道相互切换、更换固定域名）"
   echo   "------------------------------------------------------------"
   green  "5. 更新脚本"
   echo   "------------------------------------------------------------"
   green  "6. 查看各节点分享/sing-box与clash订阅链接/反代IP/ProxyIP"
   echo   "------------------------------------------------------------"
   green  "7. 查看sing-box与clash配置文件"
   echo   "------------------------------------------------------------"
   yellow "8. 端口重置并随机生成新端口"
   echo   "------------------------------------------------------------"
   red    "9. 清理所有服务进程与文件 (系统初始化)"
   echo   "------------------------------------------------------------"
   red    "0. 退出脚本"
   echo   "============================================================"
ym=("$HOSTNAME" "cache$nb.${hona}.com" "web$nb.${hona}.com")
rm -rf $WORKDIR/ip.txt
for host in "${ym[@]}"; do
response=$(curl -sL --connect-timeout 5 --max-time 7 "https://ss.fkj.pp.ua/api/getip?host=$host")
if [[ "$response" =~ (unknown|not|error) ]]; then
dig @8.8.8.8 +time=5 +short $host | sort -u >> $WORKDIR/ip.txt
sleep 1  
else
while IFS='|' read -r ip status; do
if [[ $status == "Accessible" ]]; then
echo "$ip: 可用" >> $WORKDIR/ip.txt
else
echo "$ip: 被墙 (Argo与CDN回源节点、proxyip依旧有效)" >> $WORKDIR/ip.txt
fi	
done <<< "$response"
fi
done
if [[ ! "$response" =~ (unknown|not|error) ]]; then
grep ':' $WORKDIR/ip.txt | sort -u -o $WORKDIR/ip.txt
fi
if [ "$hona" = "serv00" ]; then
red "目前免费Serv00使用代理脚本会有被封账号的风险，请知晓！！！"
fi
green "${hona}服务器名称：${snb}"
echo
green "当前可选择的IP如下："
cat $WORKDIR/ip.txt
echo
portlist=$(devil port list | grep -E '^[0-9]+[[:space:]]+[a-zA-Z]+' | sed 's/^[[:space:]]*//')
if [[ -n $portlist ]]; then
green "已设置的端口如下："
echo -e "$portlist"
else
yellow "未设置端口"
fi
echo
insV=$(cat $WORKDIR/v 2>/dev/null)
latestV=$(curl -sL https://raw.githubusercontent.com/yonggekkk/sing-box-yg/main/sversion | awk -F "更新内容" '{print $1}' | head -n 1)
if [ -f $WORKDIR/v ]; then
if [ "$insV" = "$latestV" ]; then
echo -e "当前 Serv00/Hostuno-sb-yg 脚本最新版：${purple}${insV}${re} (已安装)"
else
echo -e "当前 Serv00/Hostuno-sb-yg 脚本版本号：${purple}${insV}${re}"
echo -e "检测到最新 Serv00/Hostuno-sb-yg 脚本版本号：${yellow}${latestV}${re} (可选择5进行更新)"
echo -e "${yellow}$(curl -sL https://raw.githubusercontent.com/yonggekkk/sing-box-yg/main/sversion)${re}"
fi
echo -e "========================================================="
sbb=$(cat $WORKDIR/sb.txt 2>/dev/null)
if pgrep -x "$sbb" > /dev/null; then
green "Sing-box主进程运行正常"
else
yellow "Sing-box主进程启动失败，建议先选择3重启，依旧失败就选择8重置端口，再选择9卸载重装"
fi
if [ -f "$WORKDIR/boot.log" ]; then
argosl=$(cat "$WORKDIR/boot.log" 2>/dev/null | grep -a trycloudflare.com | awk 'NR==2{print}' | awk -F// '{print $2}' | awk '{print $1}')
checkhttp=$(curl -o /dev/null -s -w "%{http_code}\n" "https://$argosl")
[[ "$checkhttp" == 404 ]] && check="域名有效" || check="临时域名暂时无效，如已启用保活，后续会自动恢复有效"
green "Argo临时域名：$argosl  $check"
else
argogd=$(cat $WORKDIR/ARGO_DOMAIN.log 2>/dev/null)
checkhttp=$(curl --max-time 2 -o /dev/null -s -w "%{http_code}\n" "https://$argogd")
if [[ "$checkhttp" == 404 ]]; then
check="域名有效"
elif [[ "$argogd" =~ ddns|cloudns|dynamic|cloud-ip ]]; then
check="域名可能有效，请自行检测argo节点是否可用"
else
check="固定域名无效，请检查域名、端口、密钥token是否输入有误"
fi
green "Argo固定域名：$argogd $check"
fi
if [ "$hona" = "serv00" ]; then
green "多功能主页如下 (支持保活、重启、重置端口、进程查看、节点查询)"
purple "http://${snb}.${USERNAME}.${hona}.net"
fi
else
echo -e "当前 Serv00/Hostuno-sb-yg 脚本版本号：${purple}${latestV}${re}"
yellow "未安装 Serv00/Hostuno-sb-yg 脚本！请选择 1 安装"
fi
   echo -e "========================================================="
   reading "请输入选择【0-9】: " choice
   echo
    case "${choice}" in
        1) install_singbox ;;
        2) uninstall_singbox ;; 
	3) resservsb ;;
        4) resargo ;;
	5) fastrun && green "脚本已更新成功" && sleep 2 && sb ;; 
        6) showlist ;;
	7) showsbclash ;;
        8) resallport ;;
        9) kill_all_tasks ;;
	0) exit 0 ;;
        *) red "无效的选项，请输入 0 到 9" ;;
    esac
}
menu
