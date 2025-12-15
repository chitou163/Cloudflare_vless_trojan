#!/bin/bash
export LANG=en_US.UTF-8
arch="$(uname -m)"
case "$arch" in
x86_64|x64|amd64)   cpu=amd64 ;;
i386|i686)          cpu=386 ;;
armv8|armv8l|arm64|aarch64) cpu=arm64 ;;
armv7l)             cpu=arm ;;
mips64le)           cpu=mips64le ;;
mips64)             cpu=mips64 ;;
mips|mipsle)        cpu=mipsle ;;
*)
echo "当前架构为 $arch，暂不支持"
exit
;;
esac
showmenu(){
files=$(ps | grep "$HOME/cfs5http/cfwp" | grep -v grep | sed -n 's/.*client_ip=:\([0-9]\+\).*/\1/p')
if [ -n "$files" ]; then
echo "已安装节点端口："
while IFS= read -r f; do
echo "$f"
done <<< "$files"
else
echo "未安装任何节点"
fi
}
echo "================================================================"
echo "甬哥Github项目 ：github.com/yonggekkk"
echo "甬哥Blogger博客 ：ygkkk.blogspot.com"
echo "甬哥YouTube频道 ：www.youtube.com/@ygkkk"
echo "================================================================"
echo "Cloudflare Socks5/Http本地代理脚本"
echo "支持 Workers域名、Pages域名、自定义域名"
echo "可选 ECH-TLS、普通TLS、无TLS 三种代理模式，应对各种阻断封杀"
echo "脚本快捷方式：bash cfsh.sh"
echo "================================================================"
echo "1、增设CF-Socks5/Http节点配置"
echo "2、查看某个节点配置信息及日志"
echo "3、删除某个节点"
echo "4、卸载删除所有配置节点"
echo "5、退出"
echo
showmenu
echo
read -p "请选择【1-5】:" menu
if [ "$menu" = "1" ]; then
mkdir -p "$HOME/cfs5http"
if [ ! -s "$HOME/cfs5http/cfwp" ]; then
curl -L -o "$HOME/cfs5http/cfwp" -# --retry 2 --insecure https://raw.githubusercontent.com/yonggekkk/Cloudflare-vless-trojan/main/s5http_wkpgs/linux-$cpu
chmod +x "$HOME/cfs5http/cfwp"
fi
echo
read -p "1、客户端本地端口设置（回车跳过为30000）:" menu
port="${menu:-30000}"
echo
read -p "2、CF workers/pages/自定义的域名设置（格式为：域名:443系端口或者80系端口）:" menu
cf_domain="$menu"
echo
read -p "3、客户端地址优选IP/域名（回车跳过为yg1.ygkkk.dpdns.org）:" menu
cf_cdnip="${menu:-yg1.ygkkk.dpdns.org}"
echo
read -p "4、密钥设置（回车跳过为不设密钥）:" menu
token="${menu:-}"
echo
read -p "5、DoH服务器设置（回车跳过为dns.alidns.com/dns-query）:" menu
dns="${menu:-dns.alidns.com/dns-query}"
echo
read -p "6、ECH开关（回车跳过或者输入y表示开启ECH，输入n表示关闭ECH）:" menu
enable_ech=$([ -z "$menu" ] || [ "$menu" = y ] && echo y || echo n)
echo
read -p "7、分流开关（回车跳过或者输入y表示国内外分流代理，输入n表示全局代理）:" menu
cnrule=$([ -z "$menu" ] || [ "$menu" = y ] && echo y || echo n)
echo
SCRIPT="$HOME/cfs5http/cf_$port.sh"
cat > "$SCRIPT" << EOF
#!/bin/bash
INIT_SYSTEM=\$(cat /proc/1/comm)
CMD="$HOME/cfs5http/cfwp \
client_ip=:$port \
dns=$dns \
cf_domain=$cf_domain \
cf_cdnip=$cf_cdnip \
token=$token \
enable_ech=$enable_ech \
cnrule=$cnrule"
LOG="$HOME/cfs5http/$port.log"
if [ "\$INIT_SYSTEM" = "systemd" ]; then
exec \$CMD
else
nohup \$CMD > "\$LOG" 2>&1 &
fi
EOF
chmod +x "$SCRIPT"
INIT_SYSTEM=$(cat /proc/1/comm)
if [ "$INIT_SYSTEM" = "systemd" ]; then
cat > "/etc/systemd/system/cf_$port.service" << EOF
[Unit]
Description=CF $port Service
After=network.target
[Service]
Type=simple
ExecStart=/bin/bash $SCRIPT
Restart=always
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload >/dev/null 2>&1
systemctl start "cf_$port.service" >/dev/null 2>&1
systemctl enable "cf_$port.service" >/dev/null 2>&1
elif [ "$INIT_SYSTEM" = "procd" ]; then
RCLOCAL="/etc/rc.local"
[ ! -f "$RCLOCAL" ] && touch "$RCLOCAL"
grep -q "$SCRIPT" "$RCLOCAL" || sed -i "/^exit 0/i /bin/bash $SCRIPT" "$RCLOCAL"
bash "$SCRIPT"
else
bash "$SCRIPT"
fi
echo "安装完毕，Socks5/Http节点已在运行中，可进入菜单选择2，查看节点配置信息及日志" && sleep 5
echo
until grep -q '服务端域名与端口\|客户端地址与端口\|运行中的优选IP' "$HOME/cfs5http/$port.log"; do sleep 1; done; head -n 16 "$HOME/cfs5http/$port.log" | grep '服务端域名与端口\|客户端地址与端口\|运行中的优选IP'
echo
elif [ "$menu" = "2" ]; then
showmenu
echo
read -p "选择要查看的端口节点配置信息及日志（输入端口即可）:" port
{ echo "$port端口节点配置信息及日志如下：" ; echo "------------------------------------"; sed -n '1,16p' "$HOME/cfs5http/$port.log" | grep '服务端域名与端口\|客户端地址与端口\|运行中的优选IP' ; echo "------------------------------------" ; sed '1,16d' "$HOME/cfs5http/$port.log" | tail -n 10; }
elif [ "$menu" = "3" ]; then
showmenu
echo
read -p "选择要删除的端口节点（输入端口即可）:" port
pid=$(lsof -t -i :$port)
if [ -n "$pid" ]; then
systemctl stop "cf_$port.service" >/dev/null 2>&1
systemctl disable "cf_$port.service" >/dev/null 2>&1
rm -rf "/etc/systemd/system/cf_$port.service"
kill -9 $pid >/dev/null 2>&1
echo "端口 $port 的进程已被终止"
else
echo "端口 $port 没有占用进程"
fi
rm -rf "$HOME/cfs5http/$port.log" "$HOME/cfs5http/cf_$port.sh"
elif [ "$menu" = "4" ]; then
showmenu
if [ -n "$files" ]; then
while IFS= read -r port; do
echo "$port"
systemctl stop "cf_$port.service" >/dev/null 2>&1
systemctl disable "cf_$port.service" >/dev/null 2>&1
rm -f "/etc/systemd/system/cf_$port.service"
done <<< "$files"
systemctl daemon-reload
fi
ps | grep '[c]fwp' | awk '{print $1}' | xargs kill -9
rm -rf "$HOME/cfs5http" cfsh.sh
echo "卸载完成"
else
exit
fi
