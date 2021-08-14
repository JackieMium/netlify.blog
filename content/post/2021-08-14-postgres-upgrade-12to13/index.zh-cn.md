---
title: Postgres 跨版本数据库迁移
author: Jackie
date: '2021-08-14'
slug: postgres-upgrade-12to13
categories:
  - Linux
  - PostgreSQL
tags:
  - 基础
  - 实践
  - 问题
  - PostgreSQL
  - Code
  - Blog
lastmod: '2021-08-14T22:13:16+08:00'
keywords: []
description: ''
comment: yes
toc: no
autoCollapseToc: no
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

Debian 的 Postgres 早就升级到 13 了，但是由于我太懒就一直没有升级数据库，这次要往数据库放新数据了，就想趁这个机会刚好把数据都迁移到 13 吧。以前看过类似资料，postgres 本身提供了升级工具，所以我想找个靠铺点的教程一步步照着来应该问题不大。

<!--more-->


找到了这个博文：[How to upgrade PostgreSQL from 12 to 13](https://www.kostolansky.sk/posts/upgrading-to-postgresql-12/) 和 StackOverflow 上的一个回答：[How to upgrade postgresql database from 10 to 12 without losing data for openproject](https://stackoverflow.com/a/62198992) 写的东西基本上一样，所以确定这就是正确的方法了，照着来吧。


首先自己查看 `pg_hba.conf` 和 `postgresql.conf` 按需更改，比如端口、数据存放目录、socket 目录等等。按照教程里 `diff` 看看文件差异：

```bash
diff /etc/postgresql/12/main/postgresql.conf /etc/postgresql/13/main/postgresql.conf
diff /etc/postgresql/12/main/pg_hba.conf /etc/postgresql/13/main/pg_hba.conf
```

再改起来很快。

配置文件改好就可以开始准备了，**确保数据库未在后台运行情况下**运行 `check` :

```bash
 /usr/lib/postgresql/13/bin/pg_upgrade \
  --old-datadir=/home/postgres/12/main/ \  # 自定义
  --new-datadir=/home/postgres/13/main/ \
  --old-bindir=/usr/lib/postgresql/12/bin \
  --new-bindir=/usr/lib/postgresql/13/bin \
  --old-options '-c config_file=/etc/postgresql/12/main/postgresql.conf' \
  --new-options '-c config_file=/etc/postgresql/13/main/postgresql.conf' \
  --check  
```

结果我这儿一上来就报错：

```bash
could not open version file "/home/postgres/12/main/PG_VERSION": Permission denied
Failure, exiting 
```

权限不对，我想那肯定是我使用本地用户登录的，换成那个一开始创建没怎么用的 `postgres` 吧我忘了用户密码，那就直接 sudo/doas 吧。结果：

```
pg_upgrade: cannot be run as root
Failure, exiting
```

这个命令不让管理员使用。好吧，只能切 `sudo su postgres` 用户了：

```
su: failed to execute /usr/bin/nologin: No such file or directory
```

我也不知道为什么，查了一下，原来是用户没有正确的登录 Shell，需要指定一个（[StackOverflow: How to fix “login: no shell: No such file or directory” when I can not even login?](https://unix.stackexchange.com/q/40292)）。`sudo chsh postgres -s /bin/zsh` 之后再 `su` 果然可以了。再来：

```
 /usr/lib/postgresql/13/bin/pg_upgrade \
  --old-datadir=/home/postgres/12/main/ \  # 自定义
  --new-datadir=/home/postgres/13/main/ \
  --old-bindir=/usr/lib/postgresql/12/bin \
  --new-bindir=/usr/lib/postgresql/13/bin \
  --old-options '-c config_file=/etc/postgresql/12/main/postgresql.conf' \
  --new-options '-c config_file=/etc/postgresql/13/main/postgresql.conf' \
  --check  
```

这次报错又不一样了：

```
could not open log file "pg_upgrade_internal.log": Permission denied
Failure, exiting
```

依旧是 Google 一下，[StackOverflow: “cannot write to log file pg_upgrade_internal.log” when upgrading from Postgresql 9.1 to 9.3](https://stackoverflow.com/q/23216734) 再次给出满分答案。再次继续，再次碰到新（还是旧问题？）：

```
could not open version file "/home/postgres/13/main/PG_VERSION": No such file or directory`
```

哦，我自己创建的 `/home/postgres/13` 原来是不行的，查了一下 `/usr/lib/postgresql/13/bin/initdb -D /home/postgres/13/main` 才可以初始化这个目录为 data cluster。最后再来一次 `checck`：

```
lc_collate values for database "postgres" do not match:  old "zh_CN.utf8    ", new "en_US.UTF-8"                             
Failure, exiting
```

两个数据库的 locale 设置不一致，删掉 `/home/postgres/13/main` 这个目录重新指定 locale 初始化 `/usr/lib/postgresql/13/bin/initdb -D /home/postgres/13/main --lc-collate="zh_CN.utf8"` 终于提示 `*Clusters are compatible*` 了，可以开心的迁移了。命令还是上面的，去掉 `check` 就行了：

```
 /usr/lib/postgresql/13/bin/pg_upgrade \
  --old-datadir=/home/postgres/12/main/ \  # 自定义
  --new-datadir=/home/postgres/13/main/ \
  --old-bindir=/usr/lib/postgresql/12/bin \
  --new-bindir=/usr/lib/postgresql/13/bin \
  --old-options '-c config_file=/etc/postgresql/12/main/postgresql.conf' \
  --new-options '-c config_file=/etc/postgresql/13/main/postgresql.conf'
```

一路顺畅，没什么问题，比想象中快。然后就可以分别启动 12 和 13 两个版本数据库确保数据没有问题。没问题就可以清理了：

```
./delete_old_cluster.sh
doas apt purge postgresql-12 postgresql-client-12
doas rm -rf /home/postgres/12 /var/lib/postgresql/12
```

至此就可以数据无损的情况下从 Postgres 12 迁移到 13 了。