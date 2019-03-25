---
title: 科学上网笔记：Shadowsocks 和 v2ray
author: Jackie
date: '2019-01-30'
slug: shadowsocks-v2ray
categories:
  - Blog
tags:
  - Blog
  - Linux
  - 实践
  - 软件
disable_comments: no
show_toc: yes
output:
  blogdown::html_page:
    toc: yes
---


搭梯简单记录，我知道网上教程一 Google 一大把。我写下来主要是这是我一直在用的流程，但是每一次都要一边操作一边到处查，所以干脆就写下来算了。以后就可以咔咔咔复制粘贴了。所以，这个不是面向新手的教程。

以 bwg 的 Debian 9 x64_86 服务器为例。

# 1. 安装必要的包

因为是服务器，所以就用 Debian stable。包老一点无所谓，重要的是稳定。

安装完系统，第一步是确定系统更新到最新，毕竟是服务器，安全一点总没错。Root 用户登录后：

```bash
# set password for root
passwd

# add new user and set SHELL
useradd user -m -s /bin/bash
passwd user

# update system
apt update
apt upgrade

# useful tools
apt install -y sudo vim curl shadowsocks-libev firewalld
```

然后安装 [v2ray](https://www.v2ray.com/):

```bash
bash <(curl -L -s https://install.direct/go.sh)
```

到这里呢，shadowcosks、v2ray 都装好了，剩下的就是配置和测试。另外，我还安装了 firewalld 作为防火墙。还是那句话，服务器嘛，稳定安全点错不了。

# 2. 配置 ssh

以后基本上要连服务器不会再用网页，都是 ssh，所以先来把它配置好。我习惯配置成非默认端口、非 Root 用户登录。

首先得把新添加的用户添加到 `/etc/sudoers`，习惯做法是直接添加一行：

```bash
user	ALL=(ALL:ALL) ALL
```

这不是标准做法，但是简单粗暴解决问题。


**确定新用户可以 ssh 远程登录服务器**，然后接下来的操作都以普通用户身份进行。

```bash
ssh user@ser.ver.ip.addr
```

确认登录无误的话，下面修改 ssh 的配置文件 `/etc/ssh/sshd_config`，分别找到 `PermitRootLogin` 和 `Port` 设置的行改为：

```bash
PermitRootLogin no
Port pp
```

注意 `pp` 是一个端口数字（默认为  22）。这样我们就设置默认情况下 Root 用户无法登录，并且端口也不再是默认的 22。修改完后重启 ssh 服务：`sudo systemctl restart sshd.service`。不出意外的话，打完这个命令执行之后登录的会话会死掉（卡住）。因为我们正在使用 ssh 连接，但是又把远程的 ssh 服务给重启了，所以当前会话会断掉一次。

这时候关掉当前终端，重新打开一个并且分别 Root 和 user 和新设置的端口远程登录试一下。不出意外的话此时 Root 无法登录，user 可以。

# 3. 配置 shadowsocks 和 v2ray

Shadowsocks 和 v2ray 的配置其实都非常简单，无非就是服务器地址、端口、密码和加密方式这些。

## 3.1 服务器端

先看 Shadowsocks 配置文件`/etc/shadowsocks-libev/config.json`：

```bash
{
    "server":"0.0.0.0",
    "local_address":"127.0.0.1",
    "server_port":port1,
    "local_port":1080,
    "password":"pasword",
    "timeout":60,
    "method": "aes-256-cfb"
}
```

大概就是这个形式，按照上面的这样这个文件我们只需要改好 `server_port` 和 `password` 就行，当然也可以设置其他的加密方式。

然后 v2ray 一样看配置文件 `/etc/v2ray/config.json`：

```bash
{
  "inbounds": [{
    "port": port2,
    "protocol": "vmess",
    "settings": {
      "clients": [
        {
          "id": "xxxxxxxx-yyyy-zzzz-aaaa-bbbbbbccccc",
          "level": 1,
          "alterId": 64
        }
      ]
    }
  }],
.....
```

我们只需要改一下 `port2` 为想要设置的端口就行了。但是 v2ray 还有 `id` 这个 UUID 和 alterId 都需要记下来，这个填到客户端起到密码的作用。这里需要注意 Shadowsocks 和  v2ray 不要设置成一个端口了，不然会因为端口占用的问题不能同时跑起来。

服务器段 Shadowsocks 和 v2ray 理论上来讲应该可以跑起来了，我们直接先直接 `ss-server -c /etc/shadowsocks-libev/config.json` 和 `/usr/bin/v2ray/v2ray --config /etc/v2ray/config.json` 看看服务器端是不是能跑起来了。如果能跑起来，我们直接来配置客户端了，有问题的话按照报错来处理。

## 3.2 客户端

客户端  Shadowsocks  `/etc/shadowsocks-libev/config.json` 配置基本上一样：

```bash
{
    "server":"ser.ver.ip.addr",
    "server_port":port1,
    "local_port":1080,
    "password":"password",
    "timeout":60,
    "method":"aes-256-cfb"
}
```

就是服务器地址和端口、密码和加密方式。


v2ray 的配置文件 `/etc/shadowsocks-libev/config.json` 类似：

```bash
{
  "inbounds": [{
    "port": 1080,
    "protocol": "socks",
    "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls"]
      },
    "settings": {
      "clients": [
        {
          "id": "xxxxxxxx-yyyy-zzzz-aaaa-bbbbbbccccc",
          "level": 1,
          "alterId": 64
        }
      ]
    }
  }],
  "outbounds": [{
    "protocol": "vmess",
    "settings": {
    "vnext": [{
            "address": "ser.ver.ip.addr",
            "port": port2,
            "users": [
              {
                "id": "xxxxxxxx-yyyy-zzzz-aaaa-bbbbbbccccc",
                "alterId": 64
              }
            	    ]
          }]
.....
```

其中注意除了服务器地址和端口之外，注意 `id` 和 `alterid` 都填两次并且和服务器端保持一致。

都配置好了，由于我们服务器端 Shadowsocks  和  v2ray 都已经跑起来了，现在就可以连接试一下了。

```
# Shadowsocks 
ss-local -c /etc/shadowsocks-libev/config.json
```

命令没有报错的话就可以浏览器打开 Google 试一下了。没有问题的话，**关掉 Shadowsocks 再来试试  v2ray** ：

```bash
# v2ray
/usr/bin/v2ray/v2ray --config /etc/v2ray/config.json
```

一样的，浏览器试试。

# 4. 配置 systemd 开机启动服务

Shadowsocks  和  v2ray  都可以使用 systemd 开机启动。首先：

```bash
# Shadowsocks 
sudo systemctl enable shadowsocks-libev.service

#  v2ray 
sudo systemctl enable v2ray.service
```

根据提示我们知道两个 service 模块分别是 `/lib/systemd/system/shadowsocks-libev.service` 和 `/etc/systemd/system/v2ray.service`，我们还得注意看看里面命令是不是对的：

```bash
grep ExecStart /lib/systemd/system/shadowsocks-libev.service
# ExecStart=/usr/bin/ss-server -c $CONFFILE $DAEMON_ARGS

grep ExecStart /etc/systemd/system/v2ray.service             
# ExecStart=/usr/bin/v2ray/v2ray -config /etc/v2ray/config.json
```

看到模块里的命令（第二行输出前面的注释符号是我另加的），发现  v2ray 没问题，Shadowsocks  的命令有问题，改成  `/usr/bin/ss-server -c /etc/shadowsocks-libev/config.json` 就行了。

然后启动看看吧：

```bash
# Shadowsocks 
sudo systemctl start shadowsocks-libev.service

#  v2ray 
sudo systemctl start v2ray.service

journalctl -e
```

最后一步是看最近的日志确定二者都启动成功了。

# 5. 防火墙

服务都已经搞定了，下面来配置防火墙。这一步不是必要的，但是怕别人给我乱扫端口登录（毕竟我开的是用户密码登录啊），决定配置个防火墙。firewalld 特别方便，比我之前哼哧哼哧查 iptables 用法简单多了：

```bash
sudo systemctl enable firewalld

# query current settings
sudo firewall-cmd --list-all

sudo firewall-cmd –permanent –add-port=pp/tcp
sudo firewall-cmd –permanent –add-port=port1/tcp
sudo firewall-cmd –permanent –add-port=port2/tcp
sudo firewall-cmd --complete-reload

sudo systemctl start firewalld
journalctl -e
```

注意上面添加了 3 个端口分别对应前面的 ssh、Shadowsocks 和  v2ray  的端口。然后启动防火墙并且查看日志确认防火墙启动没有问题。最后，防火墙起来了应该再次看两个客户端连接是否通畅，如果没问题的话，网页控制面板重启一下服务器然后再客户端连接一下试试，到这里还没问题那就是大功告成。

后记：

- 如果 ssh 端口经常更换的话，似乎还可以 `firewall-cmd --enable service=ssh` 直接防火墙放过 ssh 服务，不过我没有试验过
- [GFWList (GitHub)](https://raw.githubusercontent.com/gfwlist/gfwlist/master/gfwlist.txt)
- [SwitchyOmega GitHub](https://github.com/FelisCatus/SwitchyOmega)