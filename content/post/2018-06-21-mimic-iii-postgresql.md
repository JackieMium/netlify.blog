---
title: MIMIC iii 数据 + PostgreSQL 数据库
author: Jackie
date: '2018-06-21'
slug: mimic-iii-postgresql
categories:
  - ICU
tags:
  - Code
  - PostgreSQL
  - Linux
disable_comments: no
---

![20180620_13-30-29](/post/2018-06-21-mimic-iii-postgresql_files/20180620_13-30-29.png)


申请的 [MIMIC III 数据库](https://mimic.physionet.org/about/mimic/) 今天终于通过了，下载发现一堆 `csv.gz` 大小也是惊人。所以自己一一个直接用表格数据导入 R 怕是不可能了，只能去用他们推荐的数据库管理了。

## 安装和配置
首先第一步就是用官方提供的 [mimin-code](https://github.com/MIT-LCP/mimic-code/tree/master/buildmimic) 来构建数据库了。官方推荐 `postgreSQL`，那就用这个好了。

Debian 的话安装 postgresql 倒是没什么，直接 `sudo apt install postgresql` 就 KO 了。看了一下版本

```bash
➜ psql --version
psql (PostgreSQL) 10.4 (Debian 10.4-2)
```

还是挺新的。很多基础的东西文档都已经覆盖，但是人懒就是没看，碰到问题查，感觉浪费的时间也不少。

安装完之后默认会创建 `postgres` 这个用户，然后我就 `psql -U postgres` 打算登录，结果报错：

```
psql: FATAL:  Peer authentication failed for user "postgres"
```

上网查了一下就解决了。解决办法是
编辑 `/etc/postgresql/10/main/pg_hba.conf` 文件，将

```
# Database administrative login by Unix domain socket
local   all             postgres                                peer
```

中 `peer` 改成 `trust`，然后 `systemctl restart postgresql.service` 重启下服务重载设置应该就能登录了。确保 `posgres` 用户可用之后就能直接用 mimic-code 提供的脚本构建数据库了，由于这个数据很大，构建数据库需要一会儿，可以先坐和放宽。

## 简单使用

现在只有 `postgres` 用户，数据我自己用，我们显然想自己的用户也是 super user 的。所以下面就是给我自己授权了。

首先 `psql -U postgres` 登录 postgres 用户，然后：

```sql
CREATE USER user_name;
ALTER USER user_name SUPERUSER CREATEDB;
\du
```

就行了。这样我自己的 Linux 用户也能直接连接和管理数据库了。

以后要进入 mimic 数据库，直接 `psql mimic` 就行了。

值得注意的是，mimic-code 提供了很多 `concepts`，就是已经定义好的一些疾病和数据提取整理的数据库脚本。但是按照 README 里写的直接 `make concepts` 并不能直接生成这些数据，我自己就看了 `Makefile`，发现根本就没写 `concepts` 的规则，也难怪直接 make 不行。所以需要把 `mimic-code/buildmimic/postgres/Makefile` 复制一份到 `mimic-code/concepts/`，然后自己编辑加入 `concepts` 规则。具体做法倒很简单，直接把上面的那些规则复制一份然后改动具体调用的 `sql` 文件为当前目录下的 `make-concepts.sql` 就行了。
这个也不知道是 mimic-code 本来设置如此还是我搞错，但是反正黑猫白猫吧，那些物化视图我倒是都顺利生成了。


最后来看看 `MIMIC III` 里的数据的样子：

![patients](/post/2018-06-21-mimic-iii-postgresql_files/patients.png)

嗯，很好，数据库建立完毕，剩下的就是怎么用数据库和数据怎么从数据库导入 R 分析的问题了。