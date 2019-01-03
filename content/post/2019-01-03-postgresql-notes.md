---
title: PostgreSQL 基础补课
author: Jackie
date: '2018-07-09'
slug: postgresql-notes
categories:
  - ICU
tags:
  - PostgreSQL
  - 基础
disable_comments: no
---


接触 MIMIC 数据库一小阵，勉强一边 Google 一边看 `mimic-code` 提供的脚本搞定了本地数据库并且把所有提供的 concepts 都建立好了。

过程中 R 配合 `RPostgreSQL` 来连接和操作数据已经相对很容易了，然后还 `tidyverse` 强大的管道 + 数据清洗功能，但是每每涉及到要去看数据 `mimic-code` 没有提供的数据的时候都对数据库操作力不从心。

__所以说落下的课终究是要补的，天道好轮回，苍天饶过谁__。

## 1. 一些基础概念

postgreSQL 数据库，有几个很重要的概念：Schema（模式）和 View（视图）、Materialized View（物化视图）。

### Schema

Schema 类似与分组，它可以将数据库对象组织到一起形成逻辑组，方便管理。

我们在 postgreSQL 数据库中创建的任何对象 (表、索引、视图和物化视图) 都会在一个 schema 下创建的。如果未指定 Schema，这些对象将会在默认的 schema 下创建。这个模式叫做 `public`。每一个数据库在创建的时候就会有一个这样的模式。

创建一个新的 schema 就是 `CREATE SCHEMA my_schema;`，要在这个指定的 schema 里建立表格：

```sql
CREATE TABLE my_schema.mytable (
...
);
```

删除一个空 schema 是 `DROP SCHEMA my_schema;`，如果不是空的就得 `DROP SCHEMA myschema CASCADE;` 级联删除了。

假如我们进入一个数据库并执行一个命令操作一个叫 my_table 的表格的时候，默认情况下数据库会在 `public` 这个 schema 中找，找不到就报错，哪怕这个 my_table 本身在另一个 schema（比如 my_schema）里已经存在。这个时候我们就要设置搜索路径了：

```sql
SET search_path TO my_schema, public;
```

这样就把 `my_schema` 放到了搜索路径里 `public` 的前面。这个有点像 Linux 的用户 PATH 这个环境变量。设置了这个之后我们在建立数据库不指定模式的建立对象时默认都会放到 `my_schema`。但是需要注意，`SET search_path` 这个设置不是永久的，只在当前会话有效。这有点像 Linux 下终端里 export 一个变量，关掉终端之后就没了。


### View & Materialized View，视图与物化视图

视图和物化视图就没那么好解释了，我 Google 了一下找到这个博客我觉得比较好理解：[It's a view, it's a table... no, it's a materialized view!](https://www.compose.com/articles/its-a-view-its-a-table-no-its-a-materialized-view/)，节选下重点 :

> Let's start with TABLE – it's basically an organized storage for your data - columns and rows. You can easily query the TABLE using predicates on the columns. To simplify your queries or maybe to apply different security mechanisms on data being accessed you can use VIEWs – named queries – think of them as glasses through which you can look at your data.
>
> **So if TABLE is storage, a VIEW is just a way of looking at it, a projection of the storage you might say. When you query a TABLE, you fetch its data directly. On the other hand, when you query a VIEW, you are basically querying another query that is stored in the VIEW's definition**. But the query planner is aware of that and can (and usually does) apply some "magic" to merge the two together.
>
> Between the two there is MATERIALIZED VIEW - it's a VIEW that has a query in its definition and uses this query to fetch the data directly from the storage, but it also has it's own storage that basically acts as a cache in between the underlying TABLE(s) and the queries operating on the MATERIALIZED VIEW. It can be refreshed, just like an invalidated cache - a process that would cause its definition's query to be executed again against the actual data. It can also be truncated, but then it wouldn't behave like a TABLE nor a VIEW. It's worth noting that this dual nature has some interesting consequences; unlike simple "nominal" VIEWs their MATERIALIZED cousins are "real", meaning you can - for example - create indices on them. On the other hand, you should also take care of removing bloat from them.

视图的本质是查询语句，而不是实在的表格。而物化视图的介于两者之间 ..... 好吧，物化视图的解释没有很看懂。
我这个需求大概应该懂就行了吧。实际上在 mimic-code 提供的代码里基本上也都是在导入的原始数据上建立物化视图的。

因为视图和物化视图都是建立在查询上的，所以在创建时也就必须得有查询语句：

```sql
CREATE [MATERIALIZED] VIEW view_name AS
	SELECT column1, column2..... FROM table_name
		WHERE [condition]; 
```

删除视图类似删除表 `DROP VIEW IF EXISTS view_name;`，非空视图要 `DROP VIEW IF EXISTS view_name CASCADE;` 级联删除。


## 2. PostgreSQL 中的数据类型

这个涉及得倒不多，因为我自己主要做的是已有数据的整理分析。仅作了解吧。

参考这一篇介绍 PostgreSQL 数据类型的博文：[PostgreSQL 数据类型](https://www.yiibai.com/postgresql/postgresql-datatypes.html)。

数据类型指定要在表格中每一列存储哪种类型的数据。
创建表格时每列都必须使用数据类型。PotgreSQL 中主要有三种数据类型：

- 数值
- 字符串
- 日期/时间


### 数值

常见数值类型包括：

- smallint：小范围整数；
- integer：典型的整数类型；
- bigint：可以存储大范围整数；
- decimal，numeric：指定的精度的数字，精确数字；
- real，double：可变精度数字，前者精度为 6 位，后者 15 位；


### 字符串

字符串类型包括

- char(size)，character(size)：固定长度字符串，size 规定了需存储的字符数，由右边的空格补齐；
- varchar(size)，character varying(size)：可变长度字符串，size 规定了需存储的字符数；
- text：可变长度字符串。

### 日期 / 时间

表示日期或时间的数据类型有：

- timestamp：日期和时间，有或无时区；
- date：日期，无时间；
- time：时间，有或无时区；
- interval：时间间隔。


### 其他

其他数据类型类型还有布尔值 boolean （true 或 false），货币数额 money 和 几何数据等。



## 3. 入门命令

标准进入数据库的命令是 `psql -U USER -d DB -h HOST -p PORT` ，这样会要求密码然后进入 DB 数据库。但是我数据库是本地用，而且用户也添加到了数据库超级用户了，所以用户、主机、端口都可以省掉了。最后就是直接 `psql -d DB` 甚至 `psql DB` 就行了。 

极其常用命令列表一下：

| 命令       | 功能                     | 命令       | 功能                                 |
|:---------- |:------------------------ |:---------- |:------------------------------------ |
| `\?`       | 命令列表                 | `\h cmd`   | 获取命令解释                         |
| `\l`       | 列举所有数据库           | `\c	db`  | 连接到另一数据库                     |
| `\d`       | 列举当前数据库的所有对象 | `\d+`      | 列举当前数据库的所有对象及其额外信息 |
| `\d table` | 列出表格的元数据         | `\du`      | 列出所有用户                         |
| `\dn`      | 列出所有 schema          | `\e`       | 编辑器                               |
| `\r`       | 重置当前的 query         | `\i file`  | 执行文件                             |

----

2018-07-10 更新

看 [文档](https://www.postgresql.org/docs/10/static/tutorial-views.html) 算是对视图解释很直观了：

>  Suppose the combined listing of weather records and city location is of particular interest to your application, but you do not want to type the query each time you need it. You can create a view over the query, which gives a name to the query that you can refer to like an ordinary table.
>  Making liberal use of views is a key aspect of good SQL database design. Views allow you to encapsulate the details of the structure of your tables, which might change as your application evolves, behind consistent interfaces.
>
>  Views can be used in almost any place a real table can be used. Building views upon other views is not uncommon.

视图好比我们对需要经常使用，而又不想每次都一次次执行的查询取了个名字，这样以后再需要执行这个查询的时候我们需要做的就跟使用表格一样简单了。