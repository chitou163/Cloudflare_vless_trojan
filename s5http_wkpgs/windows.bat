@echo off

set client_ip=127.0.0.1:30000
set dns=dns.alidns.com/dns-query
set token=服务端密钥
set cf_domain=workers域名/pages域名/自定义域名:13个CF端口
set cf_cdnip=优选IP/域名
set enable_ech=y开启ECH，n关闭ECH

windows-amd64.exe client_ip=%client_ip% cf_domain=%cf_domain% cf_cdnip=%cf_cdnip% token=%token% enable_ech=%enable_ech% dns=%dns%
pause



