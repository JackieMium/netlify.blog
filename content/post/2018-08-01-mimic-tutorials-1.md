---
title: 跟着 mimic-code 探索 MIMIC 数据之 tutorials (一)
author: Jackie
date: '2018-08-01'
slug: mimic-tutorials-1
categories:
  - ICU
tags:
  - Code
  - PostgreSQL
  - MIMIC
disable_comments: no
show_toc: yes
---

![LongRoad](/post/2018-08-01-mimic-tutorials-1_files/0.cover.jpg)

SQL 算是学完了，结果回去看 mimic-code 发现大多数脚本根本看不懂！想起来小学做数学习题：

>
> - __课本例题__: 小明有 3 个苹果，吃了 1 个，请问小明还有几个苹果 ?
>
>
> - __课后习题__：小华前天买了 5 个橘子，昨天吃了 1 个梨，请问小红今天还剩下几个苹果？
>
>
> - __我__：卒 .....
>

没有办法，我就把 mimic-code 翻来覆去地看，看看有没有什么我能看懂的。果然，MIMIC 很良心的，`mimic-code/tutorials/` 里面就放了针对新人的几个简单的小课程，小课程搭配习题，答案也有，可以说是很好了。

一个个来看吧。


## 1. sql-intro

这个文档基本就是教我们 SQL 的了。基本上我就是泛泛地看了看。有几个值得记下来的：


### How can we use temporary tables to help manage queries?

临时的表格可以用 **WITH  foo AS bar** 这样的语法来存放。比如我们要得到从 `patients` 表格中得出年龄并做他用：

```sql
WITH patient_dates AS (
SELECT p.subject_id, p.dob, a.hadm_id, a.admittime,
    ( (cast(a.admittime as date) - cast(p.dob as date)) / 365.2 ) as age
FROM patients p
INNER JOIN admissions a
ON p.subject_id = a.subject_id
ORDER BY subject_id, hadm_id
)
SELECT *
FROM patient_dates;
```

另一个办法是使用 materialised views，即物化视图： 

```sql
-- we begin by dropping any existing views with the same name
DROP MATERIALIZED VIEW IF EXISTS patient_dates_view;
CREATE MATERIALIZED VIEW patient_dates_view AS
SELECT p.subject_id, p.dob, a.hadm_id, a.admittime,
    ( (cast(a.admittime as date) - cast(p.dob as date)) / 365.2 ) as age
FROM patients p
INNER JOIN admissions a
ON p.subject_id = a.subject_id
ORDER BY subject_id, hadm_id;
```

### CASE statement for if/else logic

**CASE WHEN** 是简单的逻辑判断语句。比如我们想对 `icustays` 中 ICU 住院时间长短 (`los`) 分组：

```sql
-- Use if/else logic to categorise length of stay
-- into 'short', 'medium', and 'long'
SELECT subject_id, hadm_id, icustay_id, los,
    CASE WHEN los < 2 THEN 'short'
         WHEN los >=2 AND los < 7 THEN 'medium'
         WHEN los >=7 THEN 'long'
         ELSE NULL END AS los_group
FROM icustays;
```

### Window functions

Window functions 中文好像翻译为窗口函数，这个窗口其实是艾滋病感染潜伏期窗口那个意思，在 Bowtie2 之类的 RNA-Seq 数据比对之类的软件计算比对质量的时候也会用到这个这个概念。
不知道为什么 SQLBolt 竟然没有涉及到 Window functions，感觉很实用的功能。

Window functions 和 Aggregate 很像，但是 Aggregate 是聚合，会按照我们要求对相同的行进行合并，而 Window functions 则不同。用例子来看会很清楚，比如我们想要对同一个病人多次住 ICU 进行编号。这种情况下直接用 `GROUP BY subject_id` 会直接把同一个病人信息合并到一行，而我们想要的是每个病人每次入 ICU 的信息仍然单独是一行，顺序通过 `admission_time` 进行编号。这里的 ` 窗 ` 就是 `subject_id` ，每个病人为一个处理单位，`RANK()` 生成顺序编号。 代码：

```sql
-- find the order of admissions to the ICU for a patient
SELECT subject_id, icustay_id, intime,
    RANK() OVER (PARTITION BY subject_id ORDER BY intime)
FROM icustays;
```

有了这样一个编号我们就可以很方便的筛选只住过一次 ICU 的病例了 (这个在文献里经常看到)：

```sql
-- select patients from icustays who've stayed in ICU for only once
WITH icustayorder AS (
SELECT subject_id, icustay_id, intime,
  RANK() OVER (PARTITION BY subject_id ORDER BY intime)
FROM icustays
)
SELECT *
FROM icustayorder
WHERE rank = 1;
```

### Multiple temporary views

多个临时视图，这个在 mimic-code 里简直不要太常见。

`services` 表格包含了病人接受治疗的情况（比如是在外科还是内科这种）：

```sql
-- find the care service provided to each hospital admission
SELECT subject_id, hadm_id, transfertime, prev_service, curr_service
FROM services;
```

但是这个表格里没有 `icustay_id`，我们只能通过 `hadm_id` 来 **JOIN**：

```sql
WITH serv as (
  SELECT subject_id, hadm_id, transfertime, prev_service, curr_service
  FROM services
)
, icu as
(
  SELECT subject_id, hadm_id, icustay_id, intime, outtime
  FROM icustays
)
SELECT icu.subject_id, icu.hadm_id, icu.icustay_id, icu.intime, icu.outtime
, serv.transfertime, serv.prev_service, serv.curr_service
FROM icu
INNER JOIN serv
ON icu.hadm_id = serv.hadm_id
```

但是，这个过程其实中间是有一些猫腻的。**INNER JOIN** 是取交集的：

![SQL.join](/post/2018-08-01-mimic-tutorials-1_files/1.SQL.join.png)

那么取完后的结果的行数肯定不多于之前的数据。但是我们看看我们的数据：

```sql
WITH serv as (
  SELECT subject_id, hadm_id, transfertime, prev_service, curr_service
  FROM services
)
, icu as
(
  SELECT subject_id, hadm_id, icustay_id, intime, outtime
  FROM icustays
)
SELECT COUNT(*)
FROM icu
INNER JOIN serv
ON icu.hadm_id = serv.hadm_id
```

这个在我电脑上显示 `78840` 行，那我们再看 `icustays` 数据：

```sql
SELECT count(*)
FROM icustays;
```

`61532` 行。哈哈，**INNER JOIN** 之后行数变多了，刺激！


下面很快给出了解释：

事实是，每个 `hadm_id` 可能对应了好几个 service 和好几个 `icustay_id` ，即一个病人院内转科和多次住 ICU 的情况。所以当通过 `hadm_id`  来 **JOIN** 两个表的时候，在 `hadm_id`  相同而 `icustay_id` 和 `services` 不同时每种组合都会在结果里作为单独的一行。专业的解释：

> More technically, the first query joined two tables on non-unique keys: there may be multiple `hadm_id` with the same value in the *services* table, and there may be multiple `hadm_id` with the same value in the *admissions* table. For example, if the *services* table has `hadm_id = 100001` repeated N times, and the *admissions* table has `hadm_id = 100001` repeated M times, then joining these two on `hadm_id` will result in a table with NxM rows: one for every pair. With MIMIC, it is generally very bad practice to join two tables on non-unique columns: at least one of the tables should have unique values for the column, otherwise you end up with duplicate rows and the query results can be confusing.

所以最后，我们可以通过在 `services` 里对相同的 `hadm_id`  利用窗口函数排序，只留下第一个 `service` 记录，这样 `hadm_id` 也就变成了 unique key 了。

```sql
 WITH serv as (
   SELECT subject_id, hadm_id, transfertime, prev_service, curr_service,
    RANK() OVER (PARTITION BY hadm_id ORDER BY transfertime) as rank
   FROM services
   )
   , icu as
   (
   SELECT subject_id, hadm_id, icustay_id, intime, outtime
   FROM icustays
   )
   SELECT COUNT(*)
   FROM icu
   INNER JOIN serv
   ON icu.hadm_id = serv.hadm_id
   AND serv.rank = 1;
```


本来打算只写一点点做个笔记，没想到已经这么长了，那干脆分篇好了。

参考：

- 关于窗口函数 [官方文档](https://www.postgresql.org/docs/10/static/tutorial-window.html) 和 [中文文档](http://www.postgres.cn/docs/10/tutorial-window.html)
- mimic-code 的 [tutorails](https://github.com/MIT-LCP/mimic-code/tree/master/tutorials) 。

To be continued...