---
title: Postgres + MIMIC 从头到尾
author: Jackie
date: '2019-05-05'
slug: postgres-mimic-a2z
categories:
  - PostgreSQL
tags:
  - MIMIC
  - PostgreSQL
  - 问题
disable_comments: no
show_toc: yes
output:
  blogdown::html_page:
    toc: yes
---


之前其实也写过这个了，但是比较零散和简单。这次换硬盘，也不打算迁移数据库，直接重新建立一次。所以从前到后记录一下。

参考：

- [Installing MIMIC-III in a local Postgres database](https://mimic.physionet.org/tutorials/install-mimic-locally-ubuntu/)
- [Why psql can't connect to server?](https://stackoverflow.com/questions/31645550/why-psql-cant-connect-to-server)
- [PostgreSQL change the data directory](https://stackoverflow.com/questions/37901481/postgresql-change-the-data-directory)
- [Install postgresql. Why is initdb unavailable?](https://askubuntu.com/questions/371737/install-postgresql-why-is-initdb-unavailable)
- [Restoring the superuser account on the postgres server](https://dba.stackexchange.com/questions/61781/restoring-the-superuser-account-on-the-postgres-server)

首先一样的，postgres 装上之后直接连接的话会报错 `psql: FATAL: Peer authentication failed for user "postgres"`。这是用户认证的问题，改配置文件就行。首先我们停掉 postgres 服务：

```bash
➜ systemctl start postgresql.service
➜ systemctl status postgresql.service
```

然后打开 `/etc/postgresql/11/main/pg_hba.conf` 找到：

```
# Database administrative login by Unix domain socket
local   all             postgres                                trust
```

这个 `trust` 的作用确保通过 socket 登录的时候不需要密码。

说到 socket，我们顺便改一下 postgres 的 socket 存放的地方，这个在 R 里连接的时候需要 socket 存放在 `/tmp` 。文件 `/etc/postgresql/11/main/postgresql.conf` 里面有：

```
unix_socket_directories = '/var/run/postgresql'	# comma-separated list of directories
```

我们可以直接改后面的目录为 `/tmp` 就行，但是以防有其他软件会调用原来的路径，而本来后面也说了可以以逗号分隔写多个路径，这样安全起见我们干脆自己加上 `/tmp` 并且保留原来的。

然后就是 postgres 数据存储路径了。因为根分区小，默认存到根分区上分分钟根分区就炸了，并且放到家目录分区上也方便数据迁移。

首先我们需要确定数据存放到哪里。由于 postgres 默认会自动创建一个 postgres 用户，所以我就直接在把数据存放到这个用户的家目录算了。这个用户默认是没有家目录的，我们给建立一个并且把归属设置一下：

```bash
➜ sudo mkdir /home/postgres
➜ chown -R postgres:postgres /home/postgres 
```

而改数据存储路径配置，也在 `/etc/postgresql/11/main/postgresql.conf` 里：

```
data_directory = '/var/lib/postgresql/11/main'		# use data in another directory
```

直接在这里改后面的目录为 `/home/postgres` 就行。后面我们要初始化这个目录:

```bash
➜ sudo su - postgres
➜ /usr/lib/postgresql/11/bin/initdb -D /home/postgres/
```

会出现类似

```
Success. You can now start the database server using:

    /usr/lib/postgresql/11/bin/pg_ctl -D /home/postgres/ -l logfile start
```

的提示。后面说我们启动 postgres 的时候还要加上 `-D` 指定数据路径，但是我自己发现其实直接启动 postgres 也是没有问题的：

```
➜ systemctl start postgresql.service 
➜ systemctl status postgresql.service 
➜ ps -ef |grep postgres
```

根据 `ps` 的结果，运行的命令就是 `/usr/lib/postgresql/11/bin/postgres -D /home/postgres -c config_file=/etc/postgresql/11/main/postgresql.conf`，可以看到 postgres 已经按照的设置的数据存储路径来启动了。

后面我们再根据官方教程一步步来就行了。

**这里有一点很好（keng）玩（die）**，本地数据库建立好了以后我就在 R 里连接数据库：

```R
library("RPostgreSQL")

drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv = drv, dbname = "mimic",
                 host = "localhost", port = 5432,
                 user = "postgres", password = "password")
```

发现连接的时候必须有密码，而我这个用户是 postgres 自带的并且没有设置密码。一查 `ALTER USER postgres WITH PASSWORD 'postgres';`  设置个密码呗。结果发现提示 `ERROR:  must be superuser to alter replication users`，就是说只有超级用户才能改用户的密码。行，把我自己设置成超级用户吧，`alter user 'postgres' with superuser;` 结果提示 `ERROR:  must be superuser to alter superusers`。

仔细一看，我发现教程里我无脑复制的官方教程里的命令最后会有一步 `alter user mimicuser nosuperuser;` 就是把用户设置为**非**超级用户。

所以现在就是由于我偷懒和无脑了直接用了自带的 postgres 用户并且复制粘贴完全不审查，所以这个唯一的账户（posgres 命令 `\du` 可以列出所有用户）想改密码就成了鸡生蛋蛋生鸡问题了....

赶紧 Google 了一下，发现人家官方还真替你考虑到这种情况了。 *single user mode* 即单用户模式，类似于安全模式吧。这个模式默认只能通过 superuser 运行。所以我们可以利用这个来把 postgres 改回超级用户，然后就可以改密码了。


```bash
➜ systemctl stop postgresql.service
➜ sudo -u postgres  /usr/lib/postgresql/11/bin/postgres --single -D /home/postgres
```

然后我们终于可以 `ALTER USER postgres SUPERUSER;` 了🤦。完了之后退出 *single user mode* 再 `systemctl start postgresql.service` 启动服务再进去就可以顺利通过 `alter user postgres with password 'password';` 设置密码了。