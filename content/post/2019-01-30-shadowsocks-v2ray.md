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



搭梯简单记录，我知道网上教程一 Google 一大把。我写下来主要是这是我一直在用的流程，以免都要一边操作一边到处查，所以干脆就写下来算了。以后就可以咔咔咔复制粘贴了。所以，**这个不是面向新手的教程**。

下面命令全部以 BandwagonHost（俗称的搬瓦工） 的 Debian 9 x64_86 VPS 为例。

# 1. 安装必要的包

因为是服务器，所以就用 Debian stable。包老一点无所谓，重要的是稳定。

安装完系统，第一步是确定系统更新到最新，毕竟是服务器，安全一点总没错。root 用户登录后：

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
apt install -y sudo vim git wget curl shadowsocks-libev firewalld
```

然后安装 [v2ray](https://www.v2ray.com/):

```bash
bash <(curl -L -s https://install.direct/go.sh)
```

到这里呢，**Shadowcosks** 和 **v2ray** 就都装好了，剩下的就是配置和测试。另外，我还安装了 **firewalld** 作为防火墙。还是那句话，服务器嘛，稳定安全点错不了。

# 2. 配置 ssh

以后基本上要连服务器不会再用网页，都是 SSH 远程，所以先来把它配置好。我习惯配置成非默认端口、非 root 用户登录。

首先得把新添加的用户添加到 `/etc/sudoers`，我的习惯做法是直接添加一行：

```bash
user	ALL=(ALL:ALL) ALL
```

这不是标准做法，但是简单粗暴解决问题。

**systemd 确定服务端 SSH 正在运行后，确保新用户可以用 ssh 命令远程登录服务器**。接下来的操作都以客户端普通用户身份进行。

```bash
ssh user@ser.ver.ip.addr
```

确认登录无误的话，下面修改 SSH 的配置文件 `/etc/ssh/sshd_config`，分别找到 `PermitRootLogin` 和 `Port` 设置的行改为：

```bash
PermitRootLogin no
Port pp
```

注意 `pp` 是一个端口数字（默认为  22）。这样我们就设置默认情况下 root 用户无法登录，并且端口也不再是默认的 22。修改完后重启 sshd 服务：`sudo systemctl restart sshd.service`。不出意外的话，打完这个命令执行之后登录的会话会死掉（卡住）。因为我们正在使用 SSH 连接，但是又把远程的 SSH 服务给重启了，所以当前会话会断掉一次。

这时候关掉当前终端，重新打开一个并且分别 root 和 user 和新设置的端口远程登录试一下。不出意外的话此时 root 无法登录而 user 可以。这样 SSH 服务也配置好了，下面的操作我们都可以用客户端通过 SSH 远程到 VPS 来操作了。

# 3. 配置 shadowsocks 和 v2ray

**Shadowsocks** 和 **v2ray** 的配置其实都非常简单，无非就是服务器地址、端口、密码和加密方式这些。

## 3.1 服务器端

先看 **Shadowsocks**，我选择的是推荐的 **shadowsocks-libev**，这是基于 C 实现的 **Shadowsocks**。配置文件`/etc/shadowsocks-libev/config.json`：

```bash
{
    "server":"0.0.0.0",
    "server_port":port1,
    "password":"pasword",
    "timeout":60,
    "method": "aes-256-cfb"
}
```

大概就是这个形式，这个文件只需要改好 `server_port` 和 `password` 就行，当然也可以设置其他的加密方式。



然后 **v2ray** 一样看配置文件 `/etc/v2ray/config.json`：

```bash
{
  "inbounds": [{
    "port": port2,
    "protocol": "vmess",
    "settings": {
      "clients": [
        {
          "id": "aaaaaaa8-bbb4-ccc4-ddd4-eeeeeeeeee12",
          "level": 1,
          "alterId": 64
        }
      ]
    }
  }],
.....
```

我们只需要改一下 `port2` 为想要设置的端口就行了。



但是 **v2ray** 还有 `id` 这里的 UUID 和 `alterId` （但是 `alterId` 一般都不改所以也可以不记）都需要记下来，这个填到客户端起到密码的作用。默认的 UUID 为了安全起见也不要用它，自己换一个，在线 UUID 生成器很多随便找一个用一下就行了，注意格式是 `aaaaaaa8-bbb4-ccc4-ddd4-eeeeeeeeee12` 带连字符共 36 位。

如果服务器端同时开 shadowsocks-libev 和  v2ray 服务的话还需要两个服务不要设置成一个端口，不然会因为端口占用的问题不能同时跑起来。

服务器端 shadowsocks-libev 和 v2ray 服务理论上来讲应该可以跑起来了，我们直接先直接 `ss-server -c /etc/shadowsocks-libev/config.json` 和 `/usr/bin/v2ray/v2ray --config /etc/v2ray/config.json` 看看服务器端是不是能跑起来了。如果能跑起来，我们直接来配置客户端了，有问题的话按照报错来处理。

## 3.2 客户端

客户端 **shadowsocks-libev** 配置文件 `/etc/shadowsocks-libev/config.json` 和服务器端基本上一样：

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

就是服务器地址和端口、密码、本地端口和连接的加密方式。

**v2ray** 的配置文件 `/etc/v2ray/config.json` 类似：

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
          "id": "aaaaaaa8-bbb4-ccc4-ddd4-eeeeeeeeee12",
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
                "id": "aaaaaaa8-bbb4-ccc4-ddd4-eeeeeeeeee12",
                "alterId": 64
              }
            	    ]
          }]
.....
```

其中注意除了服务器地址和端口之外，注意 `id` 和 `alterid` 都填两次并且和服务器端保持一致。

都配置好了，由于我们服务器端 shadowsocks-libev 和  v2ray 服务都已经跑起来了，现在就可以连接试一下了。

```
# shadowsocks-libev
/usr/bin/ss-local -c /etc/shadowsocks-libev/config.json
```

命令没有报错的话就可以浏览器打开 Google 试一下了。没有问题的话，**关掉 Shadowsocks 再来试试  v2ray** ：

```
# v2ray
/usr/bin/v2ray/v2ray --config /etc/v2ray/config.json
```

一样的，浏览器试试。

# 4. 配置 systemd 开机启动服务

## 4.1 shadowsocks-libev

在阅读了 [systemd 的文档](https://www.freedesktop.org/wiki/Software/systemd/)，更确切的说是 [#10: Instantiated Services](http://0pointer.de/blog/projects/instances.html) 这篇博客之后，我又赶忙跑去仔细看了 [ArchWiki: Shadowsocks]( https://wiki.archlinux.org/index.php/Shadowsocks)，才对于 **shadowsocks-libev** 安装后自带的 service unit（就是那些 xxxxx.sercice 文件）有个了解。举例子，如果我的客户端有个配置文件 `/etc/shadowsocks-libev/server1.json` 的话，想要启动客户端连接的话可以直接 `systemctl start shadowsocks-libev-local@server1`。相应的，stop、status、restart 等等其他命令也都可以用。这样不仅仅启动关闭之类的命令更加便捷，另一个好处是现在可以借助 `journalctl -eu shadowsocks-libev-local@server1.service` 查看日志了。

相应的，服务器端进程也都是可以用 **systemd** 来接管。看看 **shadowsocks-libev** 为用户想得多周到啊（此处话里有话，后面揭晓）：

```
➜  ~ dpkg -L shadowsocks-libev |grep service
/lib/systemd/system/shadowsocks-libev-local@.service
/lib/systemd/system/shadowsocks-libev-redir@.service
/lib/systemd/system/shadowsocks-libev-server@.service
/lib/systemd/system/shadowsocks-libev-tunnel@.service
/lib/systemd/system/shadowsocks-libev.service
```

所以服务端要启用 `/etc/shadowsocks-libev/server1.json` 这个服务的话是 `systemctl start shadowsocks-libev-server@server1`。

我在启用我的服务端的时候发现一直报错，最后 Google 了一下发现其实服务端配置文件 `/etc/shadowsocks-libev/config.json` 里 `local_address` 和 `local_port` 似乎是多余的条目需要删掉。之后就可以愉快地用 **systemd** 管理 **shadowsocks-libev** 的进程了！(说得好像我是 **systemd** 狂热粉丝一样，不！我不是！)


## 4.2 v2ray

本来以为很轻松地也可以让 **systemd** “顺便”也接管 **v2ray** 的进程，但是下载个最新的（现在是 `v4.24.2`） **v2ray** 解压打开看只带了一个最简单的 `v2ray.service` 文件:

```
[Unit]
Description=V2Ray Service
Documentation=https://www.v2ray.com/ https://www.v2fly.org/
After=network.target nss-lookup.target

[Service]
# If the version of systemd is 240 or above, then uncommenting Type=exec and commenting out Type=simple
#Type=exec
Type=simple
# This service runs as root. You may consider to run it as another user for security concerns.
# By uncommenting User=nobody and commenting out User=root, the service will run as user nobody.
# More discussion at https://github.com/v2ray/v2ray-core/issues/1011
User=root
#User=nobody
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/bin/v2ray/v2ray -config /etc/v2ray/config.json
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

ExecStart 命令直接写死了，服务端可以直接用没事，客户端如果同时有多个服务器的配置文件的话，显然这个 unit 文件是不支持实例化的。这就是我前面说 **shadowsocks-libev** 做得周到的地方。好在得知 Debian 有开发者正在积极推动 **v2ray** （[golang-v2ray-core](https://salsa.debian.org/go-team/packages/golang-v2ray-core/)）进入官方源，他们也好心的加上了类似的 syetemd unit 文件。



现在暂时的话我们只能照猫画虎自己写一个了：

```
[Unit]
Description=V2Ray Client Service for %I
Documentation=https://www.v2ray.com/ https://www.v2fly.org/
After=network-oneline.target

[Service]
Type=simple
User=nobody
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
DynamicUser=true
ExecStart=/usr/bin/v2ray/v2ray -config /etc/v2ray/%i.json
Restart=on-failure
# Don't restart in the case of configuration error
# https://salsa.debian.org/go-team/packages/golang-v2ray-core
RestartPreventExitStatus=23

[Install]
WantedBy=multi-user.target
```

重命名为 `v2ray-local@.serive` 并放到 `/etc/systemd/system/`（也可以是其他一些目录，参见 [What's the difference between /usr/lib/systemd/system and /etc/systemd/system?](https://unix.stackexchange.com/q/206315)、[Difference between /usr/lib/systemd/\*/\*.service and /lib/systemd/\*/\*.service](https://unix.stackexchange.com/q/550001) )，然后就可以愉快的 `systemctl start v2ray-local@server1` 了。


上面这是客户端的情况，服务器端类似不再赘述。

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

注意上面添加了 3 个端口分别对应前面的 SSH、shadowsocks-libev 和  v2ray  的端口。然后启动防火墙并且查看日志确认防火墙启动没有问题。最后，防火墙起来了应该再次看两个客户端连接是否通畅，如果没问题的话，网页控制面板重启一下服务器然后再客户端连接一下试试，到这里还没问题那就是大功告成。



后记：

- [Online UUID Generator](https://www.uuidgenerator.net/)
- 在 GitHub 上也偶然发现一个针对 v2ray 的项目 [v2fly/fhs-install-v2ray](https://github.com/v2fly/fhs-install-v2ray) 挺有意思的，这里记录一下。


- 如果 ssh 端口经常更换的话，似乎还可以 `firewall-cmd --enable service=ssh` 直接防火墙放过 ssh 服务，不过我没有试验过
- [GFWList (GitHub)](https://raw.githubusercontent.com/gfwlist/gfwlist/master/gfwlist.txt)
- [SwitchyOmega GitHub](https://github.com/FelisCatus/SwitchyOmega)
