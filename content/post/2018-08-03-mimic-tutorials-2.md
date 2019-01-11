---
title: 跟着 mimic-code 探索 MIMIC 数据之 tutorials (二)
author: Jackie
date: '2018-08-03'
slug: mimic-tutorials-2
categories:
  - ICU
tags:
  - MIMIC
  - PostgreSQL
  - Code
disable_comments: no
show_toc: no
---

mimic-code 的 `tutorials` 还提供了 `sql-crosstab`，很短，我大概看了感觉不是很有用，先放着了。`using_r_with_jupyter.ipynb` 就是教你怎么用 Jupyter + R，没什么。`explore-items.Rmd` 是 MySQL + R，但是没太搞懂这是在干嘛，而且我也没 MySQL，代码转 Postgres 应该不难，我太懒了。直接看最后一个，`cohort-selection.ipynb`，打开看了 Postgres + Python，讲怎么选择病例队列的一些小技巧，感觉写得挺好的。就这个了，开始。

原文档用的 Python，我不喜欢。当然还是 R 好啦，所以我直接用里面的 `sql` 语句就行了。


## Cohort selection

The aim of this tutorial is to describe how patients are tracked in the MIMIC-III database. By the end of this notebook you should:

- Understand what `subject_id`, `hadm_id`, and `icustay_id` represent
- Know how to set up a cohort table for subselecting a patient population
- Understand the difference between service and physical location

Requirements:

- MIMIC-III in a PostgreSQL database
- Python packages installable with:
  `pip install numpy pandas matplotlib psycopg2 jupyter`

文档的目的是展示 MIMIC 中病例信息的跟踪追溯。主要讲解 `subject_id`, `hadm_id`, 和 `icustay_id` 代表着什么，怎么提取研究病例队列，以及理解病人接受 `service` 和患者物理位置之间的差别（老实说我都不知道这个到底是什么，大概指病人人在 ICU 外但是接受 ICU 治疗？）。

我自己用的是 RStudio + PostgreSQL，所以代码相对原文档会有一些改动。

首先是设置和数据库连接和基本选项：

```r
library(RPostgreSQL)
library(tidyverse)

# connect to PostgresSQL
drv <- dbDriver("PostgreSQL")
con <- dbConnect(
  drv = drv,
  dbname = "mimic",
  user = "postgres",
  .rs.askForPassword("Enter password for user postgres:")
)

# set the search path to the mimiciii schema
dbSendQuery(con, "SET search_path TO mimiciii, public;")

# 为了偷懒我写了一个方便查询数据库的函数
query <- function(query = query) {
  con %>%
    dbGetQuery(sql(query)) %>%
    as_tibble()
}
```

队列选择一般都是从这三个表开始 : `patients`, `admissions` 以及 `icustays`:

- `patients`: information about a patient that does not change - e.g. date of birth, genotypical sex
- `admissions`: information recorded on hospital admission - admission type (elective, emergency), time of admission
- `icustays`: information recorded on intensive care unit admission - primarily admission and discharge time


MIMIC-III 主要是关注 ICU 的数据库，所以我们一般都是想看患者在 ICU 的进科出科情况。也因此，一般在选取患者队列时都不会从病例作为切入 (即通过 `subject_id`)，而是通过 ICU 出入情况，即通过 `icustays` 表格中的 `icustay_id` 切入。

```r
query("SELECT subject_id
       , hadm_id
       , icustay_id
	   FROM icustays LIMIT 10;")
# 在仅仅是尝试性或者探索性的看看数据的时候一般都用 LIMIT 10


# A tibble: 10 x 3
   subject_id hadm_id icustay_id
 *      <int>   <int>      <int>
 1        268  110404     280836
 2        269  106296     206613
 3        270  188028     220345
 4        271  173727     249196
 5        272  164716     210407
 6        273  158689     241507
 7        274  130546     254851
 8        275  129886     219649
 9        276  135156     206327
10        277  171601     272866
```

计算 ICU 的住院时间：

```r
query("SELECT subject_id
       , hadm_id
       , icustay_id
       , outtime - intime AS icu_length_of_stay_interval
       , EXTRACT(EPOCH FROM outtime - intime) AS icu_length_of_stay
       FROM icustays LIMIT 10;")

# A tibble: 10 x 5
   subject_id hadm_id icustay_id icu_length_of_stay_interval icu_length_of_stay
 *      <int>   <int>      <int> <chr>                                    <dbl>
 1        268  110404     280836 3 days 05:58:33                         280713
 2        269  106296     206613 3 days 06:41:28                         283288
 3        270  188028     220345 2 days 21:27:09                         250029
 4        271  173727     249196 2 days 01:26:22                         177982
 5        272  164716     210407 1 day 14:53:09                          139989
 6        273  158689     241507 1 day 11:40:06                          128406
 7        274  130546     254851 8 days 19:32:32                         761552
 8        275  129886     219649 7 days 03:09:14                         616154
 9        276  135156     206327 1 day 08:06:29                          115589
10        277  171601     272866 17:33:02                                 63182
```

`EXTRACT(EPOCH FROM ... )` 从 `TIMESTAMP` 中提出以秒为单位的 `INTERVAL`，所以真正要计算时间，还要除以 (60 * 60 * 24)：

```r
query("SELECT subject_id
       , hadm_id
       , icustay_id
       , EXTRACT(EPOCH FROM outtime - intime)/60.0/60.0/24.0 AS icu_length_of_stay 
       FROM icustays LIMIT 10;")

#---

# A tibble: 10 x 4
   subject_id hadm_id icustay_id icu_length_of_stay
 *      <int>   <int>      <int>              <dbl>
 1        268  110404     280836              3.25 
 2        269  106296     206613              3.28 
 3        270  188028     220345              2.89 
 4        271  173727     249196              2.06 
 5        272  164716     210407              1.62 
 6        273  158689     241507              1.49 
 7        274  130546     254851              8.81 
 8        275  129886     219649              7.13 
 9        276  135156     206327              1.34 
10        277  171601     272866              0.731
```

如果还想对 ICU 住院时间进行筛选，比如只想看住院超过 24h 的，就得先建个临时表格。比如：

```r
query("WITH co AS
      (SELECT subject_id
      , hadm_id
      , icustay_id
      , EXTRACT(EPOCH FROM outtime - intime)/60.0/60.0/24.0 AS icu_length_of_stay 
      FROM icustays LIMIT 10
      ) 
      SELECT co.subject_id
      , co.hadm_id
      , co.icustay_id
      , co.icu_length_of_stay 
      FROM co
      WHERE icu_length_of_stay >= 2;")

# A tibble: 6 x 4
  subject_id hadm_id icustay_id icu_length_of_stay
*      <int>   <int>      <int>              <dbl>
1        268  110404     280836               3.25
2        269  106296     206613               3.28
3        270  188028     220345               2.89
4        271  173727     249196               2.06
5        274  130546     254851               8.81
6        275  129886     219649               7.13
```

这样就只筛选到住院时间 > 2 天的病例。

很多使用 MIMIC 数据库的研究都会聚焦于特定的人群。比如，MIMIC 中的数据包含了 ICU 中成人和新生儿的住院记录，但是一般研究是不会在这两个人群里同时开展的。所以很多研究的第一步就是从 `icustays` 表格中选择病例人群，即从这张表格中筛选合适的 `icustay_id`。上面的例子就是选取 ICU 住院时间超过 2 天的。

选取病例人群的时候，好的做法是构建一个队列表格。这个表格应该包含数据库中所有的 `icustay_id`，然后通过一个添加一个 binary flag 来指明每个病例是否要从研究人群中剔除。比如还是上面的筛选 ICU 住院时间 > 2 天的病例的例子：

```r
query("WITH co AS 
      (
        SELECT subject_id
        , hadm_id
        , icustay_id
        , EXTRACT(EPOCH FROM outtime - intime)/60.0/60.0/24.0 AS icu_length_of_stay 
        FROM icustays LIMIT 10 
      )
      SELECT co.subject_id
      , co.hadm_id
      , co.icustay_id
      , co.icu_length_of_stay,
      CASE
        WHEN co.icu_length_of_stay < 2 THEN 1 
      ELSE 0 END AS exclusion_los
      FROM co;")

# A tibble: 10 x 5
   subject_id hadm_id icustay_id icu_length_of_stay exclusion_los
 *      <int>   <int>      <int>              <dbl>         <int>
 1        268  110404     280836              3.25              0
 2        269  106296     206613              3.28              0
 3        270  188028     220345              2.89              0
 4        271  173727     249196              2.06              0
 5        272  164716     210407              1.62              1
 6        273  158689     241507              1.49              1
 7        274  130546     254851              8.81              0
 8        275  129886     219649              7.13              0
 9        276  135156     206327              1.34              1
10        277  171601     272866              0.731             1
```

之前的例子里，最后结果只返回了 6 行，因为有 4 行被我们筛选出去了。而在这里，所有的 10 行数据都在，但是最后一列显示有 4 行数据是不应该包含在我们的研究人群中的。
这种做法的好处在于在研究的最后，我们很容易总结整个研究人群的排除情况，也很容易根据需要作出修改。

再回想一下之前提到的剔除标准：标记非成人病例为剔除对象。所以，首先必须得知道病人在进入 ICU 时的年龄，这个需要用患者出生日期和 ICU 入院时间来计算。`icustays` 里的 `intime` 记录病人入 ICU 的时间，所以我们还需要从 `patients` 得到病人的出生日期用来计算入 ICU 时的年龄。

```r
query("WITH co AS
      (
        SELECT icu.subject_id
        , icu.hadm_id
        , icu.icustay_id
        , EXTRACT(EPOCH FROM outtime - intime)/60.0/60.0/24.0 AS icu_length_of_stay
        ,icu.intime - pat.dob AS age
        FROM icustays icu
        INNER JOIN patients pat ON
          icu.subject_id = pat.subject_id
        LIMIT 10
      )
      SELECT co.subject_id
      , co.hadm_id
      , co.icustay_id
      , co.icu_length_of_stay
      , co.age,
      CASE
        WHEN co.icu_length_of_stay < 2 THEN 1
        ELSE 0 END AS exclusion_los
      FROM co;")

# A tibble: 10 x 6
   subject_id hadm_id icustay_id icu_length_of_stay age                 exclusion_los
 *      <int>   <int>      <int>              <dbl> <chr>                       <int>
 1          2  163353     243653             0.0918 21:20:07                        1
 2          3  145834     211552             6.06   27950 days 19:10:11             0
 3          4  185777     294638             1.68   17475 days 00:29:31             1
 4          5  178980     214757             0.0844 06:04:24                        1
 5          6  107064     228232             3.67   24084 days 21:30:54             0
 6          7  118037     278444             0.268  15:35:29                        1
 7          7  118037     236754             0.739  2 days 03:26:01                 1
 8          8  159514     262299             1.08   12:36:10                        1
 9          9  150750     220597             5.32   15263 days 13:07:02             0
10         10  184167     288409             8.09   11:39:05                        0
```

结果发现，再一次的，计算的年龄成了 `INTERVAL`。所以还得转换。转换有 3 种办法：

- 用 `EXTRACT()` 提取 `INTERVAL`，此时 `INTERVAL` 是 ` 天 + 小时 : 分钟 : 秒 ` 这样的形式，然后作除法得到年（前面用到的做法）；
- 先用 PostgreSQL 的 `AGE()` 返回为年龄精确值，然后用 `DATE_PART()` 提取年数得到以年为单位的年龄；
- 一样，`AGE()` 得到年龄精确值，`DATE_PART()` 分别提取年月日计算精确年龄。

我们把三种方法都试试看：

```r
query("WITH co AS 
      (
      SELECT icu.subject_id
      , icu.hadm_id
      , icu.icustay_id
      , EXTRACT(EPOCH FROM outtime - intime)/60.0/60.0/24.0 AS icu_length_of_stay
      , icu.intime - pat.dob AS age FROM icustays icu
      INNER JOIN patients pat ON
        icu.subject_id = pat.subject_id
      LIMIT 10
      )
      SELECT co.subject_id
      , co.hadm_id
      , co.icustay_id
      , co.icu_length_of_stay
      , co.age
      , EXTRACT('year' FROM co.age) AS age_extract_year
      , EXTRACT('year' FROM co.age) 
        + EXTRACT('months' FROM co.age) / 12.0
        + EXTRACT('days' FROM co.age) / 365.242
        + EXTRACT('hours' FROM co.age) / 24.0 / 364.242 AS age_extract_precise
      , EXTRACT('epoch' FROM co.age) / 60.0 / 60.0 / 24.0 / 365.242 AS age_extract_epoch,
      CASE WHEN
        co.icu_length_of_stay < 2 THEN 1
      ELSE 0 END AS exclusion_los
      FROM co;")

# A tibble: 10 x 7
   subject_id icu_length_of_stay age                 age_extract_year age_extract_precise age_extract_epoch exclusion_los
 *      <int>              <dbl> <chr>                          <dbl>               <dbl>             <dbl>         <int>
 1          2             0.0918 21:20:07                           0            0.00240           0.00243              1
 2          3             6.06   27950 days 19:10:11                0           76.5              76.5                  0
 3          4             1.68   17475 days 00:29:31                0           47.8              47.8                  1
 4          5             0.0844 06:04:24                           0            0.000686          0.000693             1
 5          6             3.67   24084 days 21:30:54                0           65.9              65.9                  0
 6          7             0.268  15:35:29                           0            0.00172           0.00178              1
 7          7             0.739  2 days 03:26:01                    0            0.00582           0.00587              1
 8          8             1.08   12:36:10                           0            0.00137           0.00144              1
 9          9             5.32   15263 days 13:07:02                0           41.8              41.8                  0
10         10             8.09   11:39:05                           0            0.00126           0.00133              0
```

可以看到后面两种方法计算的年龄其实基本上没什么差别。而第一种办法，由于提取出来的实际上都是以天为单位的 `INTERVAL`，所以提取年得不到年龄的，只得到 0 了。所以结论就是，其实用不同的办法算得年龄没什么大的区别，按个人喜好自己定一个就 OK。后面我们都会用最简单的 `EXTRACT(EPOCH FROM ... )` 这种方法。

然后我们就可以通过设置年龄必须 >= 16 来把新生儿剔除掉了（虽然也把青少年剔除了，但是其实 MIMIC 只有新生儿和成人）：

```r
query("WITH co AS
      (
      SELECT icu.subject_id
      , icu.hadm_id
      , icu.icustay_id
      , EXTRACT(EPOCH FROM outtime - intime)/60.0/60.0/24.0 AS icu_length_of_stay
      , EXTRACT('epoch' from icu.intime - pat.dob) / 60.0 / 60.0 / 24.0 / 365.242 AS age
      FROM icustays icu
      INNER JOIN patients pat ON
        icu.subject_id = pat.subject_id
      LIMIT 10
      )
      SELECT co.subject_id
      , co.hadm_id
      , co.icustay_id
      , co.icu_length_of_stay
      , co.age,
      CASE WHEN
        co.icu_length_of_stay < 2 THEN 1
      ELSE 0 END AS exclusion_los
      ,CASE WHEN co.age < 16 THEN 1
      ELSE 0 END AS exclusion_age
      FROM co;")

# A tibble: 10 x 7
   subject_id hadm_id icustay_id icu_length_of_stay       age exclusion_los exclusion_age
 *      <int>   <int>      <int>              <dbl>     <dbl>         <int>         <int>
 1          2  163353     243653             0.0918  0.00243              1             1
 2          3  145834     211552             6.06   76.5                  0             0
 3          4  185777     294638             1.68   47.8                  1             0
 4          5  178980     214757             0.0844  0.000693             1             1
 5          6  107064     228232             3.67   65.9                  0             0
 6          7  118037     278444             0.268   0.00178              1             1
 7          7  118037     236754             0.739   0.00587              1             1
 8          8  159514     262299             1.08    0.00144              1             1
 9          9  150750     220597             5.32   41.8                  0             0
10         10  184167     288409             8.09    0.00133              0             1
```

可以看到有 6 行因为年龄不足 16 岁而标记为待剔除，而且这 6 例里大部分也和之前的住院日 > 2 天有很多重合。

下面再尝试另一个常见的剔除标准：二次入 ICU 病例，不管是院内还是院外的。这么做的理由是筛选后可以达到很多统计分析所需要的各样本之间独立的要求。如果保留同一患者多次 ICU 住院信息，那么就必须考虑到这多次入院之间的高度相关性（同一患者因同样的情况多次入院），这对统计分析添加了不必要的麻烦。所以，我们通过 `RANK()` 对多次入院情况做排序编号：

```r
query("
  WITH co AS (
  SELECT icu.subject_id
  , icu.hadm_id
  , icu.icustay_id
  , EXTRACT(EPOCH FROM outtime - intime)/60.0/60.0/24.0 AS icu_length_of_stay
  , EXTRACT('epoch' FROM icu.intime - pat.dob) / 60.0 / 60.0 / 24.0 / 365.242 AS age
  , RANK() OVER (PARTITION BY icu.subject_id ORDER BY icu.intime) AS icustay_id_order
  FROM icustays icu
  INNER JOIN patients pat ON
    icu.subject_id = pat.subject_id LIMIT 10
  )
  SELECT co.subject_id
  , co.hadm_id
  , co.icustay_id
  , co.icu_length_of_stay
  , co.age
  , co.icustay_id_order,
  CASE WHEN 
    co.icu_length_of_stay < 2 THEN 1
  ELSE 0 END AS exclusion_los,
  CASE WHEN
    co.age < 16 THEN 1
  ELSE 0 END AS exclusion_age
  FROM co;")

# A tibble: 10 x 8
   subject_id hadm_id icustay_id icu_length_of_stay       age icustay_id_order exclusion_los exclusion_age
 *      <int>   <int>      <int>              <dbl>     <dbl>            <dbl>         <int>         <int>
 1          2  163353     243653             0.0918  0.00243                 1             1             1
 2          3  145834     211552             6.06   76.5                     1             0             0
 3          4  185777     294638             1.68   47.8                     1             1             0
 4          5  178980     214757             0.0844  0.000693                1             1             1
 5          6  107064     228232             3.67   65.9                     1             0             0
 6          7  118037     278444             0.268   0.00178                 1             1             1
 7          7  118037     236754             0.739   0.00587                 2             1             1
 8          8  159514     262299             1.08    0.00144                 1             1             1
 9          9  150750     220597             5.32   41.8                     1             0             0
10         10  184167     288409             8.09    0.00133                 1             0             1
```

可以对看到 `subject_id` 为 7 的患者就有两次入院信息。所以我们要做的就是再加入一个 `CASE WHEN` 把这样的病例去掉（虽然其实这个病例也会因为其他标准不符合而被剔除）：

```r
query("
  WITH co AS (
  SELECT icu.subject_id
  , icu.hadm_id
  , icu.icustay_id
  , EXTRACT(EPOCH FROM outtime - intime)/60.0/60.0/24.0 AS icu_length_of_stay
  , EXTRACT('epoch' FROM icu.intime - pat.dob) / 60.0 / 60.0 / 24.0 / 365.242 AS age
  , RANK() OVER (PARTITION BY icu.subject_id ORDER BY icu.intime) AS icustay_id_order
  FROM icustays icu 
  INNER JOIN patients pat ON
    icu.subject_id = pat.subject_id
  LIMIT 10
  )
  SELECT co.subject_id
  , co.hadm_id
  , co.icustay_id
  , co.icu_length_of_stay
  , co.age
  , co.icustay_id_order,
  CASE WHEN
    co.icu_length_of_stay < 2 THEN 1
  ELSE 0 END AS exclusion_los,
  CASE WHEN
    co.age < 16 THEN 1
  ELSE 0 END AS exclusion_age,
  CASE WHEN
    co.icustay_id_order != 1 THEN 1
  ELSE 0 END AS exclusion_first_stay
  FROM co;")

# A tibble: 10 x 9
   subject_id hadm_id icustay_id icu_length_of_stay       age icustay_id_order exclusion_los exclusion_age exclusion_first_stay
 *      <int>   <int>      <int>              <dbl>     <dbl>            <dbl>         <int>         <int>                <int>
 1          2  163353     243653             0.0918  0.00243                 1             1             1                    0
 2          3  145834     211552             6.06   76.5                     1             0             0                    0
 3          4  185777     294638             1.68   47.8                     1             1             0                    0
 4          5  178980     214757             0.0844  0.000693                1             1             1                    0
 5          6  107064     228232             3.67   65.9                     1             0             0                    0
 6          7  118037     278444             0.268   0.00178                 1             1             1                    0
 7          7  118037     236754             0.739   0.00587                 2             1             1                    1
 8          8  159514     262299             1.08    0.00144                 1             1             1                    0
 9          9  150750     220597             5.32   41.8                     1             0             0                    0
10         10  184167     288409             8.09    0.00133                 1             0             1                    0
```

可以看到 `subject_id` 为 7 的患者第 2 次的入院信息确实已经被标记为待剔除。

最后，我们可能还想根据入院接受治疗特定情况剔除掉部分人。因为不同科室接收的病人基本情况差别也很大，而通过剔除特定人群之后可以使研究的人群一致性更好。`services` 表格就提供了患者入院接受何种治疗的情况：

```r
query("SELECT subject_id
       , hadm_id
       , transfertime
       , prev_service
       , curr_service
       FROM services
       LIMIT 10;")

# A tibble: 10 x 5
   subject_id hadm_id transfertime        prev_service curr_service
 *      <int>   <int> <dttm>              <chr>        <chr>       
 1        471  135879 2122-07-22 14:07:27 TSURG        MED         
 2        471  135879 2122-07-26 18:31:49 MED          TSURG       
 3        472  173064 2172-09-28 19:22:15 NA           CMED        
 4        473  129194 2201-01-09 20:16:45 NA           NB          
 5        474  194246 2181-03-23 08:24:41 NA           NB          
 6        474  146746 2181-04-04 17:38:46 NA           NBB         
 7        475  139351 2131-09-16 18:44:04 NA           NB          
 8        476  161042 2100-07-05 10:26:45 NA           NB          
 9        477  191025 2156-07-20 11:53:03 NA           MED         
10        478  137370 2194-07-15 13:55:21 NA           NB 
```

从上面可以看到，`curr_service` 是 current service 的缩写，`prev_service` 在患者有转科的情况下记录转科前的科室，否则为 `null`。比如 `subject_id` 为 471 的患者发生过至少两次 `service` 的变更：一次从 TSURG 到 MED，另一次从 MED 到 TSURG （注：可能还有更多记录因为我们用了 `LIMIT 10` 而没有显示，可以通过 `SELECT * FROM services WHERE subject_id = 471` 进一步查看）。

表格里所有的 `service` 可以从 MIMIC 网站查看：[http://mimic.physionet.org/mimictables/services/](http://mimic.physionet.org/mimictables/services/)。简单来说有这些：



| Service | Description                                                  |
|:------- |:------------------------------------------------------------ |
| CMED    | Cardiac Medical - for non-surgical cardiac related admissions |
| CSURG   | Cardiac Surgery - for surgical cardiac admissions            |
| DENT    | Dental - for dental/jaw related admissions                   |
| ENT     | Ear, nose, and throat - conditions primarily affecting these areas |
| GU      | Genitourinary - reproductive organs/urinary system           |
| GYN     | Gynecological - female reproductive systems and breasts      |
| MED     | Medical - general service for internal medicine              |
| NB      | Newborn - infants born at the hospital                       |
| NBB     | Newborn baby - infants born at the hospital                  |
| NMED    | Neurologic Medical - non-surgical, relating to the brain     |
| NSURG   | Neurologic Surgical - surgical, relating to the brain        |
| OBS     | Obstetrics - conerned with childbirth and the care of women giving birth |
| ORTHO   | Orthopaedic - surgical, relating to the musculoskeletal system |
| OMED    | Orthopaedic medicine - non-surgical, relating to musculoskeletal system |
| PSURG   | Plastic - restortation/reconstruction of the human body (including cosmetic or aesthetic) |
| PSYCH   | Psychiatric - mental disorders relating to mood, behaviour, cognition, or perceptions |
| SURG    | Surgical - general surgical service not classified elsewhere |
| TRAUM   | Trauma - injury or damage caused by physical harm from an external source |
| TSURG   | Thoracic Surgical - surgery on the thorax, located between the neck and the abdomen |
| VSURG   | Vascular Surgical - surgery relating to the circulatory system |



如果我们想剔除掉接受手术治疗的病人的，那就需要排除这些 `service`：

- CSURG
- NSURG
- ORTHO
- PSURG
- SURG
- TSURG
- VSURG

可以通过 `%SURG or ORTHO` 通配符匹配搞定：

```r
query("SELECT hadm_id
       , curr_service,
       CASE
        WHEN curr_service LIKE '%SURG' THEN 1
        WHEN curr_service = 'ORTHO' THEN 1
       ELSE 0 END AS surgical
       FROM services se
       LIMIT 10;")

# A tibble: 10 x 3
   hadm_id curr_service surgical
 *   <int> <chr>           <int>
 1  135879 MED                 0
 2  135879 TSURG               1
 3  173064 CMED                0
 4  129194 NB                  0
 5  194246 NB                  0
 6  146746 NBB                 0
 7  139351 NB                  0
 8  161042 NB                  0
 9  191025 MED                 0
10  137370 NB                  0
```

OK，该剔除的都标记好了。但是我们发现我们只有 `hadm_id`，而我们选取队列是以 `icustay_id` 为中心的。所以现在还要通过 `hadm_id` 与 `icustays` 表格来一次 **JOIN** 得到 `icustay_id`：

```r
query("SELECT icu.hadm_id
       , icu.icustay_id
       , curr_service,
       CASE
        WHEN curr_service like '%SURG' THEN 1
        WHEN curr_service = 'ORTHO' THEN 1
      ELSE 0 END AS surgical
      FROM icustays icu
      LEFT JOIN services se ON
        icu.hadm_id = se.hadm_id
      LIMIT 10;")

# A tibble: 10 x 4
   hadm_id icustay_id curr_service surgical
 *   <int>      <int> <chr>           <int>
 1  100001     275225 MED                 0
 2  100003     209281 MED                 0
 3  100006     291788 MED                 0
 4  100006     291788 OMED                0
 5  100007     217937 SURG                1
 6  100009     253656 CSURG               1
 7  100010     271147 GU                  0
 8  100011     214619 TRAUM               0
 9  100012     239289 SURG                1
10  100016     217590 MED                 0
```

然后现在新的问题又来了：一个 `icustay_id` 对应多个 `service` 怎么选择？其实**这个是关于如何选择研究队列的问题，而不是代码写法的问题。** 比如我们决定把来 ICU 之前是做手术的病人剔除掉，那么上面的 `JOIN` 就要改了：

```r
query("SELECT icu.hadm_id
       , icu.icustay_id
       , se.curr_service,
       CASE
        WHEN curr_service LIKE '%SURG' THEN 1
        WHEN curr_service = 'ORTHO' THEN 1
       ELSE 0 END AS surgical
       FROM icustays icu
       LEFT JOIN services se ON
        icu.hadm_id = se.hadm_id
       AND se.transfertime < icu.intime + interval '12' hour
       LIMIT 10;")

# A tibble: 10 x 4
   hadm_id icustay_id curr_service surgical
 *   <int>      <int> <chr>           <int>
 1  100001     275225 MED                 0
 2  100003     209281 MED                 0
 3  100006     291788 MED                 0
 4  100007     217937 SURG                1
 5  100009     253656 CSURG               1
 6  100010     271147 GU                  0
 7  100011     214619 TRAUM               0
 8  100012     239289 SURG                1
 9  100016     217590 MED                 0
10  100017     258320 MED                 0
```

与前面的结果比较，发现 `hadm_id` = 100006 的患者 `service` = OMED 的行去掉了：因为这个患者的 OMED 是在 ICU 之后的，我们不纳入研究（虽然其实 OMED 是非手术）。注意上面代码的 `JOIN` 中我们用到了 `+ interval '12' hour` ，这给我们的剔除标准增加了一点点宽容度。原因在于数据中记录的这些时间信息都是院内不同地方不同的人不同时刻进行录入的，所以必然有一些不一致。比如，一个 ICU 病人可能因为需要手术而发生 transfer，但是记录的转科时间上却在进入 ICU 的时间一小时后。这就属于行政上的“噪音”，而我们加入的 12 个小时有助于解决这个问题。** 再次说明，这个这是关于队列如何选择的问题 **——可能你觉得 12 h 太长，2-4 h 比较合适——但是其实对于我们的例子来说区别不大，因为 80% 的病人没有转科的情况。

最后，我们合并结果为每次 ICU 只有一个 `service` 记录。和前面一样，用到 `RANK()` ：

```r
query("WITH serv AS
      (
      SELECT icu.hadm_id
      , icu.icustay_id
      , se.curr_service,
      CASE WHEN
        curr_service like '%SURG' THEN 1
      WHEN curr_service = 'ORTHO' THEN 1
      ELSE 0 END AS surgical,
      RANK() OVER (PARTITION BY icu.hadm_id ORDER BY se.transfertime DESC) AS rank
      FROM icustays icu
      LEFT JOIN services se ON
        icu.hadm_id = se.hadm_id
      AND se.transfertime < icu.intime + interval '12' hour
      LIMIT 10
      )
      SELECT hadm_id
      , icustay_id
      , curr_service
      , surgical
      FROM serv
      WHERE rank = 1;")

# A tibble: 10 x 4
   hadm_id icustay_id curr_service surgical
 *   <int>      <int> <chr>           <int>
 1  100001     275225 MED                 0
 2  100003     209281 MED                 0
 3  100006     291788 MED                 0
 4  100007     217937 SURG                1
 5  100009     253656 CSURG               1
 6  100010     271147 GU                  0
 7  100011     214619 TRAUM               0
 8  100012     239289 SURG                1
 9  100016     217590 MED                 0
10  100017     258320 MED                 0
```

然后最后的最后在和我们之前的筛选队列再 **JOIN** 一下：

```r
query("WITH co AS (
      SELECT icu.subject_id
      , icu.hadm_id
      , icu.icustay_id
      , EXTRACT(EPOCH FROM outtime - intime)/60.0/60.0/24.0 AS icu_length_of_stay
      , EXTRACT('epoch' FROM icu.intime - pat.dob) / 60.0 / 60.0 / 24.0 / 365.242 AS age
      , RANK() OVER (PARTITION BY icu.subject_id ORDER BY icu.intime) AS icustay_id_order
      FROM icustays icu
      INNER JOIN patients pat ON
        icu.subject_id = pat.subject_id
      LIMIT 10),
      serv AS (
      SELECT icu.hadm_id
      , icu.icustay_id
      , se.curr_service
      , CASE 
        WHEN curr_service LIKE '%SURG' THEN 1
        WHEN curr_service = 'ORTHO' THEN 1
      ELSE 0 END AS surgical
      , RANK() OVER (PARTITION BY icu.hadm_id ORDER BY se.transfertime DESC) AS rank
      FROM icustays icu
      LEFT JOIN services se ON
        icu.hadm_id = se.hadm_id
      AND se.transfertime < icu.intime + interval '12' hour
      )
      SELECT co.subject_id
      , co.hadm_id
      , co.icustay_id
      , co.icu_length_of_stay
      , co.age, co.icustay_id_order
      , CASE
        WHEN co.icu_length_of_stay < 2 THEN 1
      ELSE 0 END AS exclusion_los
      , CASE WHEN 
        co.age < 16 THEN 1
      ELSE 0 END AS exclusion_age
      , CASE WHEN
          co.icustay_id_order != 1 THEN 1
      ELSE 0 END AS exclusion_first_stay
      , CASE WHEN serv.surgical = 1 THEN 1
      ELSE 0 END AS exclusion_surgical
      FROM co
      LEFT JOIN serv ON
        co.icustay_id = serv.icustay_id
      AND serv.rank = 1;")

# A tibble: 10 x 10
   subject_id hadm_id icustay_id icu_length_of_stay       age icustay_id_order exclusion_los exclusion_age exclusion_first_st… exclusion_surgic…
 *      <int>   <int>      <int>              <dbl>     <dbl>            <dbl>         <int>         <int>               <int>             <int>
 1          6  107064     228232             3.67   65.9                     1             0             0                   0                 1
 2          7  118037     278444             0.268   0.00178                 1             1             1                   0                 0
 3          7  118037     236754             0.739   0.00587                 2             1             1                   1                 0
 4          3  145834     211552             6.06   76.5                     1             0             0                   0                 1
 5          9  150750     220597             5.32   41.8                     1             0             0                   0                 0
 6          8  159514     262299             1.08    0.00144                 1             1             1                   0                 0
 7          2  163353     243653             0.0918  0.00243                 1             1             1                   0                 0
 8          5  178980     214757             0.0844  0.000693                1             1             1                   0                 0
 9         10  184167     288409             8.09    0.00133                 1             0             1                   0                 0
10          4  185777     294638             1.68   47.8                     1             1             0                   0                 0
```

然后我们就顺利得到了需要的病人队列，可以开始提取数据了。


最后来总结一下我们的筛选流程（最后这一步也可以在 R 里写，嫌麻烦算了，直接复制粘贴到 Python 里了...）

```python
import pandas as pd
import numpy as np
import psycopg2
from IPython.display import display, HTML
sqluser='postgres'
dbname='mimic'
schema_name='mimiciii'

con = psycopg2.connect(dbname=dbname,user=sqluser, password='not_shown_here')

query_schema = 'set search_path to ' + schema_name + ';'

query = query_schema + """
WITH co AS (
SELECT icu.subject_id
, icu.hadm_id
, icu.icustay_id
, first_careunit
, EXTRACT(EPOCH FROM outtime - intime)/60.0/60.0/24.0 AS icu_length_of_stay
, EXTRACT('epoch' from icu.intime - pat.dob) / 60.0 / 60.0 / 24.0 / 365.242 AS age
, RANK() OVER (PARTITION BY icu.subject_id ORDER BY icu.intime) AS icustay_id_order
FROM icustays icu
INNER JOIN patients pat
  ON icu.subject_id = pat.subject_id
LIMIT 10)
, serv AS
(
SELECT icu.hadm_id
, icu.icustay_id
, se.curr_service
, CASE
    WHEN curr_service LIKE '%SURG' THEN 1
    WHEN curr_service = 'ORTHO' THEN 1
    ELSE 0 END AS surgical
, RANK() OVER (PARTITION BY icu.hadm_id ORDER BY se.transfertime DESC) AS rank
FROM icustays icu
LEFT JOIN services se
 ON icu.hadm_id = se.hadm_id
AND se.transfertime < icu.intime + interval '12' hour
)
SELECT co.subject_id
, co.hadm_id
, co.icustay_id
, co.icu_length_of_stay
, co.age
, co.icustay_id_order
, serv.curr_service
, co.first_careunit
, CASE WHEN 
    co.icu_length_of_stay < 2 THEN 1
ELSE 0 END AS exclusion_los
, CASE WHEN
    co.age < 16 THEN 1
ELSE 0 END AS exclusion_age
, CASE WHEN
    co.icustay_id_order != 1 THEN 1
ELSE 0 END  AS exclusion_first_stay
, CASE WHEN
    serv.surgical = 1 THEN 1
ELSE 0 END AS exclusion_surgical
FROM co
LEFT JOIN serv ON
    co.icustay_id = serv.icustay_id
AND serv.rank = 1
"""

df = pd.read_sql_query(query, con)

print('{:20 s} {:5d}'.format('Observations', df.shape[0]))
idxExcl = np.zeros(df.shape[0],dtype=bool)
for col in df.columns:
    if "exclusion_" in col:
        print('{:20 s} {:5d} ({:2.2f}%)'.format(col, df[col].sum(), df[col].sum()*100.0/df.shape[0]))
        idxExcl = (idxExcl) | (df[col]==1)

print('')
print('{:20 s} {:5d} ({:2.2f}%)'.format('Total excluded', np.sum(idxExcl), np.sum(idxExcl)*100.0/df.shape[0]))


Observations            10
exclusion_los            6 (60.00%)
exclusion_age            6 (60.00%)
exclusion_first_stay     1 (10.00%)
exclusion_surgical       2 (20.00%)

Total excluded           9 (90.00%)
```

可以发现，由于我们前面建立了筛选的队列表格，所以最后想看整个筛选过程就变得很简单。

---

这篇文档真的觉得很有用，其一是很展示了每一步应该怎么写查询语句并有详细的解释；其二也是最重要的，给出了选择研究队列的一般理念和一个简单的例子。

THE END