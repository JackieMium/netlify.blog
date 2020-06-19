---
title: VPS 防暴指南——用 fail2ban 和密钥登录加固远程服务器的 SSH
author: Jackie
date: '2020-05-28'
slug: VPS-harden-SSH
categories:
  - Linux
tags:
  - Linux
  - 实践
  - 软件
lastmod: '2020-05-28T19:42:56+08:00'
keywords: []
description: ''
comment: yes
toc: yes
autoCollapseToc: yes 
postMetaInFooter: no
hiddenFromHomePage: no
contentCopyright: no
reward: no
mathjax: no
mathjaxEnableSingleDollar: no
mathjaxEnableAutoNumber: no
hideHeaderAndFooter: no
flowchartDiagrams:
  enable: no
  options: ''
sequenceDiagrams:
  enable: no
  options: ''
---


VPS 上的梯子有时不太稳定，前两天登录上去看的时候偶然发现日志里有一些陌生的 IP 地址通过 SSH 登录失败的记录。出于好奇就仔细看了什么情况，这一[看](https://i.loli.net/2020/05/28/Y42OawVEkpgzIrL.png)吓坏了。

<!--more-->

![ssh-logLines](/post/2020-05-28-vps-harden-ssh.zh-cn_files/ssh-logLines.png)

感觉不妙，`tail -f /var/log/auth.log` 直接实时[看](https://i.loli.net/2020/05/28/aeR5qrnYzLtDfw4.png)到有不明 IP 一直在尝试不同的用户和密码登录。没错，有人在暴力破解 SSH 用户和密码尝试登录。


![ssh-log.png](/post/2020-05-28-vps-harden-ssh.zh-cn_files/ssh-log.png)


这个的时候立马去看了另一台 VPS，发现也有类似记录只是少一点，事情并不简单（汗...）。那么接下来改做什么就很简单了：加固 SSH 提升安全性，防止被他人暴力破解登录。



加固 SSH 登录安全性常见的两个方法，一是采用类似于 **fail2ban** 的工具主动封禁可疑 IP 地址，二是更保险的做法：关闭密码登录并采用密钥登录。



## ⛔️️安装配置 fail2ban

**fail2ban** 在 Debian 官方仓库就有，所以直接 apt 就好了。主要看配置。



**fail2ban** 会读取系统日志，根据设定值封禁一定时间内超过一定尝试次数的远程登录一段时间。上述 `一定时间内`、`一定尝试次数` 和 `一段时间` 都是可设置选项。封禁的单位是 **jail**，比如针对 SSH 设置一个 **jail**，针对 nginx 设置一个或多个 **jail**。



**fail2ban** 自带的 **jail** 配置文件是 `/etc/fail2ban/jail.conf`，但是为了防止在软件更新时被覆盖，推荐做法是把自己的配置放在`/etc/fail2ban/jail.local`。 很多地方都推荐 `sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local` 然后去改，但是我自己试了一下 **fail2ban** 竟然跑不起来，该文件太长我又懒得一点点看所以还是直接新建了。参照网上资料我写的配置文件：



```
[DEFAULT]
# IP 地址白名单，可填 IP 或 CIDR，以空格做分割
ignoreip = 127.0.0.1/8
# 封锁时长
bantime  = 86400
# 默认在 findtime 内达到 maxretry 次尝试登录失败封锁
findtime = 36000
maxretry = 3

[sshd]
enabled = true
# 指定日志文件
logpath  = /var/log/auth.log
filter   = sshd
```



解读一下：这个配置文件定义了一个 `sshd` 的 **jail**，让 **fail2ban** 读取位于 `/var/log/auth.log` 日志并过滤到 `sshd` 条目，当发现某个 IP 地址在 36000s（10h）内有 3 次尝试登录时实施封禁 86400s（1d），同时白名单设为本地主机。



设置完成后就可以启动 **fail2ban** 了。`fail2ban.service` 必须以 root 用户启动，所以这时候直接切到 root 用户操作比较方便。root 权限 `systemctl start fail2ban.service` 就可以了。这时候不出意外的话 `systemctl status fail2ban.service` 或者 `journalctl -u fail2ban.service` 都可以看到 **fail2ban** 成功启动的信息。另外 **fail2ban** 也提供了检查运行状态的命令 `fail2ban-client ping`，服务后台正在运行的话会返回 `Server replied: pong` 的字样。此时 `fail2ban-client status` 也会看到有一个名为 `sshd` 的 **jail** 正在运行。`fail2ban-client status sshd` 则可以看到这个 **jail** 详细的数据，包括一共在日志里扫描到多少失败记录、已经封禁多少 IP 以及这些 IP 的列表。`/var/log/fail2ban.log` 日志里也能看到处理的记录。

当 **fail2ban** 发现并封禁一些 IP 后，`iptables -L` 查看防火墙规则列表也能看到这些 IP 记录被添加到防火墙。最后，如果自己不小心封禁了自己的 IP，可以`fail2ban-client set sshd unbanip 111.23.45.678` 手动解封。

## 🔐️ SSH 密钥登录



SSH 设置密钥登录就简单多了（以前一直以为很麻烦就没去了解）。简单来说就是本地生成 SSH 公钥和私钥，然后把公钥放到服务器上去，然后以后就可以让 SSH 直接用这一对密钥进行认证登录了。设置好后可以直接禁用账户密码登录，以后 SSH 远程登录也不再需要输入密码了。理论上来讲，SSH 改端口、禁用密码登录改为密钥登录之后，已经很难被其人破解登录了。



首先是生成密钥对，这个和设置 GitHub 那些网址一样，没有的话 `sshkey-gen` 直接生成默认密钥就行了。下面一步是把自己的公钥上传到远程服务器上去。最简单直接暴力的方法就是 `cat ~/.ssh/id_rsa.pub` 然后复制粘贴到远程机器的 `~/.ssh/authorized_keys` 里(SSH 登录情况下)。不过，SSH 本身也提供了命令实现，比如下面两个效果是一样的：

```
ssh-copy-id USER@111.23.45.678 -p PORT -i ~/.ssh/id_rsa.pub
# 或者
cat ~/.ssh/id_rsa.pub |ssh USER@111.23.45.678 -p PORT "cat > ~/.ssh/authorized_keys"`
```



这时候远程服务器已经有了公钥，接下来需要修改 SSH 配置文件，禁用密码登录并启用密钥登录（注意修改前一定要保留一个 SSH 登录会话，以防修改后文件出错自己无法再登录上）。修改完后可以检查文件所有配置项 `grep -v '#' /etc/ssh/sshd_config`，比如：

```
Port xx
PermitRootLogin no
PubkeyAuthentication yes
AuthorizedKeysFile      .ssh/authorized_keys .ssh/authorized_keys2

PasswordAuthentication no
PermitEmptyPasswords no

ChallengeResponseAuthentication no
UsePAM no
```

确保文件无误后 `systemctl restart sshd.service` 重启 SSH 服务，这时候本地再

```
ssh USER@111.23.45.678 -p PORT
```

就发现不输入密码就直接登录上了，再换用 root 登录会直接提示 `Permission denied (publickey)` 登录失败。



至此，SSH 经历了换用非默认端口、**fail2ban** 和密钥登录三重安全加固，普通攻击应该都能有效抵挡了，peace✌。



- [ArchWiki: Fail2ban](https://wiki.archlinux.org/index.php/Fail2ban)

- [如何使用 fail2ban 防御 SSH 服务器的暴力破解攻击](https://linux.cn/article-5067-1.html)
- [安全运维那些事之SSH](https://zhuanlan.zhihu.com/p/29623339)
- [SSH login without password](http://www.linuxproblem.org/art_9.html)
- [How To Configure SSH Key-Based Authentication on a Linux Server](https://www.digitalocean.com/community/tutorials/how-to-configure-ssh-key-based-authentication-on-a-linux-server)