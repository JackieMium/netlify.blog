---
title: 跟着 mimic-code 探索 MIMIC 数据之 notebooks CRRT (一)
author: Jackie
date: '2018-08-15'
slug: mimic-code-notebooks-crrt1
categories:
  - ICU
tags:
  - Code
  - MIMIC
  - PostgreSQL
  - 实践
disable_comments: no
show_toc: yes
---

![0.cover](/post/2018-08-15-mimic-code-notebooks-crrt1_files/0.cover.png)

花了几天时间把 [`mimic-code/notebooks/crrt-notebook.ipynb`](https://github.com/MIT-LCP/mimic-code/blob/master/notebooks/crrt-notebook.ipynb) 从头到尾看了一遍。虽然消化得还不是很好，但是觉得这一篇教程真的是干货满满。决定还是再花点时间仔细跟着 tutorial 走一遍并且整理一遍。和前面一样，我还是尽量放到 R 里做，R 不好做的我再到 Juputer 里做。R 的设置在上一篇里写过，这里我就只写 Python 里的准备工作了。需要的东西有：

- PostgreSQL 运行，本地建立好 MIMIC-III 数据库
- Python，我是 conda 环境的 Python 3.6。使用 Jupyter 的话当然还得搭配浏览器
- R，最好搭配 RStudio

------

这个记事本（因为教程以 Jupyter Notebook 的形式存在存在，所以一直称为记事本）总体讲述如何在 MIMIC 数据中定义 CRRT。CRRT，Continuous renal replacement therapy，中文作连续性肾脏替代治疗，也被称作连续血液净化治疗 (continuous blood purification, CBP)。

CRRT 是临床出现一种新的代替肾脏治疗方法 , 即每天持续 24 小时或接近 24 小时的一种长时间、连续体外血液净化疗法。

![1.CRRT.ref](/post/2018-08-15-mimic-code-notebooks-crrt1_files/1.CRRT.ref.png)
以及
![1.CRRT.ref2](/post/2018-08-15-mimic-code-notebooks-crrt1_files/1.CRRT.ref2.png)

来自中国知网：

- 【邓青志 , 余阶洋 , 彭佳华 . 连续性肾脏替代治疗对 ICU 脓毒症患者的临床研究进展 [J]. 中国医学工程 ,2018,26(04):30-32.】
- 【马帅 , 丁峰 . 连续性肾脏替代治疗的过去、现在与未来 [J]. 上海医药 ,2018,39(09):3-5+11.】

这个记事本主要目的是在 MIMIC-III v1.4 数据中定义病人 CRRT 的开始和结束时间；次要目的是展示如何从 MIMIC-III 数据中提取和整理临床数据。

## 框架

在 MIMIC-III 数据库中，定义一个临床概念包含一下几个关键步骤：

1. 鉴定描述这一临床概念的关键词和语句
2. 在 `d_items` 表格中搜索这些关键词（如果是实验室检查的话要看 `d_labitems` 表格）。
3. 从 `d_items` 表格的 `linksto` 这一列指定的表格中提取数据
4. 用提取数据的规则制定定义这一临床概念
5. 通过逐个查看和聚合操作做验证

这整个过程是迭代进行的，也没有上面描述的那么清晰——验证时你可能又要回去修改数据提取的规则，等等。而且对于 MIMIC-III 数据，这整个过程必须重复一次：一次是提取 MetaVision 的数据，一次是 CareVue 的。

## MetaVision 和 CareVue

MIMIC-III 中的数据来自两个不同的 ICU 数据库系统。其结果就是，同一个临床概念的数据可能对应到多个不同的 `itemid` 。

比如，病人心率数据算是一个比较容易提取的临床概念了，但是在 `d_items` 表格中匹配 “heart rate” 却可以发现至少两个 `itemid`：
`SELECT itemid, label, abbreviation, dbsource, linksto FROM mimiciii.d_items WHERE label='Heart Rate';` 得到：

| itemid | label      | abbreviation | dbsource   | linksto     |
| :----- | :--------- | :----------- | :--------- | :---------- |
| 211    | Heart Rate |              | carevue    | chartevents |
| 220045 | Heart Rate | HR           | metavision | chartevents |

可以看到两个 `itemid` 都对应心率——但是一个是 CareVue 数据库系统使用的（(dbsource = 'carevue'）而另一个是 MetaVision 系统使用的（dbsource = 'metavision'）。这也就是上面提到的，数据提取过程必须重复一次。

通常来讲，推荐先提取 MetaVision 数据，因为其数据组织形式更好并且为需要纳入哪些因素提供了十分有用的信息。比如，MetaVision 里的 `itemid` 的每一个 `label` 都有一个相应的缩写，而这些缩写可以用来在 CareVue 中搜索用。

## Step 0: import libraries, connect to the database

由于是 Python 来做的，所以首先是载入包和一些设置。首先是所有要用到的包：

```python
# Import libraries
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import psycopg2
# used to print out pretty pandas dataframes
from IPython.display import display, HTML
import matplotlib.dates as dates
import matplotlib.lines as mlines
```

然后一些简单的设置和连接数据库：

```python
%matplotlib inline
plt.style.use('ggplot') 

# specify user/password/where the database is
sqluser = 'postgres'
dbname = 'mimic'
schema_name = 'mimiciii'
host = 'localhost'

query_schema = 'SET search_path to ' + schema_name + ';'

# connect to the database
con = psycopg2.connect(dbname=dbname, user=sqluser, password=getpass.getpass(prompt='Password:'.format(user)), host=host)
```

我自己在连接数据库的时候每次都会出现报错：

```
OperationalError: could not connect to server: No such file or directory
	Is the server running locally and accepting
	connections on Unix domain socket "/tmp/.s.PGSQL.5432"?
```

Google 了一下就是这个文件放在不同的位置了，建立一个软链接就好：`ln -s /var/run/postgresql/.s.PGSQL.5432 /tmp/.s.PGSQL.5432`。

## Step 1: Identification of key terms

我们感兴趣的是 CRRT，那么首先我们直接在 MetaVision 数据中搜索”CRRT“看看：

```python
query = query_schema + """
select itemid
, label
, category
, linksto
from d_items
where dbsource = 'metavision'
and lower(label) like '%crrt%'
"""

df = pd.read_sql_query(query,con)

df
```

可以得到：

```
# A tibble: 6 x 4
  itemid label                         category    linksto           
*  <int> <chr>                         <chr>       <chr>             
1 227290 CRRT mode                     Dialysis    chartevents       
2 225436 CRRT Filter Change            Dialysis    procedureevents_mv
3 227525 Calcium Gluconate (CRRT)      Medications inputevents_mv    
4 225802 Dialysis - CRRT               Dialysis    procedureevents_mv
5 227536 KCl (CRRT)                    Medications inputevents_mv    
6 225956 Reason for CRRT Filter Change Dialysis    chartevents  
```

然后我们就可以通过结果拓展我们开始的搜索方法了：

- category = ‘Dialysis’
- lower(label) like '%dialysis%'



## Step 2: Extraction of ITEMIDs from tables



### Get list of itemid related to CRRT

（从这里开始为了贴结果方便我还是切到 R 里做了）


首先我们根据刚刚改进的搜索词来找到对应的 `itemid`：

```r
query("SELECT itemid, label, category, linksto FROM d_items di
       WHERE dbsource = 'metavision' 
          AND (lower(label) LIKE '%dialy%'
          OR category = 'Dialysis'
          OR lower(label) LIKE '%crrt%')
       ORDER BY linksto, category, label;")

# A tibble: 65 x 4
   itemid label                                          category                linksto    
 *  <int> <chr>                                          <chr>                   <chr>      
 1 225740 Dialysis Catheter Discontinued                 Access Lines - Invasive chartevents
 2 227357 Dialysis Catheter Dressing Occlusive           Access Lines - Invasive chartevents
 3 225776 Dialysis Catheter Dressing Type                Access Lines - Invasive chartevents
 4 226118 Dialysis Catheter placed in outside facility   Access Lines - Invasive chartevents
 5 227753 Dialysis Catheter Placement Confirmed by X-ray Access Lines - Invasive chartevents
 6 225323 Dialysis Catheter Site Appear                  Access Lines - Invasive chartevents
 7 225725 Dialysis Catheter Tip Cultured                 Access Lines - Invasive chartevents
 8 227124 Dialysis Catheter Type                         Access Lines - Invasive chartevents
 9 225126 Dialysis patient                               Adm History/FHPA        chartevents
10 224149 Access Pressure                                Dialysis                chartevents
# ... with 55 more rows
```

### Manually label above itemid

上面得到的是所有有可能会用来提取 CRRT 数据的数据元素。所以下一步就是鉴别哪些元素可以用来定义治疗的开始和结束的时间。这个工作得依靠专业知识进行（而不是简单地编程的问题）。

通过 `linksto` 列把表格分开，人工查看所有 `itemid` 后我们得到下面这张表格，初步筛选后把所有 `itemid` 标记为 "consider for further review"（待商榷） 或者 "not relevant"（无关）。

**Links to CHARTEVENTS**

| itemid | label                                            | category                | linksto     | Included/comment           |
| :----- | :----------------------------------------------- | :---------------------- | :---------- | :------------------------- |
| 225740 | Dialysis Catheter Discontinued                   | Access Lines - Invasive | chartevents | No - access line           |
| 227357 | Dialysis Catheter Dressing Occlusive             | Access Lines - Invasive | chartevents | No - access line           |
| 225776 | Dialysis Catheter Dressing Type                  | Access Lines - Invasive | chartevents | No - access line           |
| 226118 | Dialysis Catheter placed in outside facility     | Access Lines - Invasive | chartevents | No - access line           |
| 227753 | Dialysis Catheter Placement Confirmed by X-ray   | Access Lines - Invasive | chartevents | No - access line           |
| 225323 | Dialysis Catheter Site Appear                    | Access Lines - Invasive | chartevents | No - access line           |
| 225725 | Dialysis Catheter Tip Cultured                   | Access Lines - Invasive | chartevents | No - access line           |
| 227124 | Dialysis Catheter Type                           | Access Lines - Invasive | chartevents | No - access line           |
| 225126 | Dialysis patient                                 | Adm History/FHPA        | chartevents | No - admission information |
| 224149 | Access Pressure                                  | Dialysis                | chartevents | Yes - CRRT setting         |
| 224404 | ART Lumen Volume                                 | Dialysis                | chartevents | Yes - CRRT setting         |
| 224144 | Blood Flow (ml/min)                              | Dialysis                | chartevents | Yes - CRRT setting         |
| 228004 | Citrate (ACD-A)                                  | Dialysis                | chartevents | Yes - CRRT setting         |
| 227290 | CRRT mode                                        | Dialysis                | chartevents | Yes - CRRT setting         |
| 225183 | Current Goal                                     | Dialysis                | chartevents | Yes - CRRT setting         |
| 225977 | Dialysate Fluid                                  | Dialysis                | chartevents | Yes - CRRT setting         |
| 224154 | Dialysate Rate                                   | Dialysis                | chartevents | Yes - CRRT setting         |
| 224135 | Dialysis Access Site                             | Dialysis                | chartevents | No - access line           |
| 225954 | Dialysis Access Type                             | Dialysis                | chartevents | No - access line           |
| 224139 | Dialysis Site Appearance                         | Dialysis                | chartevents | No - access line           |
| 225810 | Dwell Time (Peritoneal Dialysis)                 | Dialysis                | chartevents | No - peritoneal dialysis   |
| 224151 | Effluent Pressure                                | Dialysis                | chartevents | Yes - CRRT setting         |
| 224150 | Filter Pressure                                  | Dialysis                | chartevents | Yes - CRRT setting         |
| 226499 | Hemodialysis Output                              | Dialysis                | chartevents | No - hemodialysis          |
| 225958 | Heparin Concentration (units/mL)                 | Dialysis                | chartevents | Yes - CRRT setting         |
| 224145 | Heparin Dose (per hour)                          | Dialysis                | chartevents | Yes - CRRT setting         |
| 224191 | Hourly Patient Fluid Removal                     | Dialysis                | chartevents | Yes - CRRT setting         |
| 225952 | Medication Added #1 (Peritoneal Dialysis)        | Dialysis                | chartevents | No - peritoneal dialysis   |
| 227638 | Medication Added #2 (Peritoneal Dialysis)        | Dialysis                | chartevents | No - peritoneal dialysis   |
| 225959 | Medication Added Amount #1 (Peritoneal Dialysis) | Dialysis                | chartevents | No - peritoneal dialysis   |
| 227639 | Medication Added Amount #2 (Peritoneal Dialysis) | Dialysis                | chartevents | No - peritoneal dialysis   |
| 225961 | Medication Added Units #1 (Peritoneal Dialysis)  | Dialysis                | chartevents | No - peritoneal dialysis   |
| 227640 | Medication Added Units #2 (Peritoneal Dialysis)  | Dialysis                | chartevents | No - peritoneal dialysis   |
| 228005 | PBP (Prefilter) Replacement Rate                 | Dialysis                | chartevents | Yes - CRRT setting         |
| 225965 | Peritoneal Dialysis Catheter Status              | Dialysis                | chartevents | No - peritoneal dialysis   |
| 225963 | Peritoneal Dialysis Catheter Type                | Dialysis                | chartevents | No - peritoneal dialysis   |
| 225951 | Peritoneal Dialysis Fluid Appearance             | Dialysis                | chartevents | No - peritoneal dialysis   |
| 228006 | Post Filter Replacement Rate                     | Dialysis                | chartevents | Yes - CRRT setting         |
| 225956 | Reason for CRRT Filter Change                    | Dialysis                | chartevents | Yes - CRRT setting         |
| 225976 | Replacement Fluid                                | Dialysis                | chartevents | Yes - CRRT setting         |
| 224153 | Replacement Rate                                 | Dialysis                | chartevents | Yes - CRRT setting         |
| 224152 | Return Pressure                                  | Dialysis                | chartevents | Yes - CRRT setting         |
| 225953 | Solution (Peritoneal Dialysis)                   | Dialysis                | chartevents | No - peritoneal dialysis   |
| 224146 | System Integrity                                 | Dialysis                | chartevents | Yes - CRRT setting         |
| 226457 | Ultrafiltrate Output                             | Dialysis                | chartevents | Yes - CRRT setting         |
| 224406 | VEN Lumen Volume                                 | Dialysis                | chartevents | Yes - CRRT setting         |
| 225806 | Volume In (PD)                                   | Dialysis                | chartevents | No - peritoneal dialysis   |
| 227438 | Volume not removed                               | Dialysis                | chartevents | No - peritoneal dialysis   |
| 225807 | Volume Out (PD)                                  | Dialysis                | chartevents | No - peritoneal dialysis   |

**Links to DATETIMEEVENTS**

| itemid | label                                   | category                | linksto        | Included/comment           |
| :----- | :-------------------------------------- | :---------------------- | :------------- | :------------------------- |
| 225318 | Dialysis Catheter Cap Change            | Access Lines - Invasive | datetimeevents | No - access lines          |
| 225319 | Dialysis Catheter Change over Wire Date | Access Lines - Invasive | datetimeevents | No - access lines          |
| 225321 | Dialysis Catheter Dressing Change       | Access Lines - Invasive | datetimeevents | No - access lines          |
| 225322 | Dialysis Catheter Insertion Date        | Access Lines - Invasive | datetimeevents | No - access lines          |
| 225324 | Dialysis CatheterTubing Change          | Access Lines - Invasive | datetimeevents | No - access lines          |
| 225128 | Last dialysis                           | Adm History/FHPA        | datetimeevents | No - admission information |

**Links to INPUTEVENTS_MV**

| itemid | label                    | category    | linksto        | Included/comment   |
| ------ | ------------------------ | ----------- | -------------- | ------------------ |
| 227525 | Calcium Gluconate (CRRT) | Medications | inputevents_mv | Yes - CRRT setting |
| 227536 | KCl (CRRT)               | Medications | inputevents_mv | Yes - CRRT setting |

**Links to PROCEDUREEVENTS_MV**

| itemid | label               | category                | linksto            | Included/comment         |
| ------ | ------------------- | ----------------------- | ------------------ | ------------------------ |
| 225441 | Hemodialysis        | 4-Procedures            | procedureevents_mv | No - hemodialysis        |
| 224270 | Dialysis Catheter   | Access Lines - Invasive | procedureevents_mv | No - access lines        |
| 225436 | CRRT Filter Change  | Dialysis                | procedureevents_mv | Yes - CRRT setting       |
| 225802 | Dialysis - CRRT     | Dialysis                | procedureevents_mv | Yes - CRRT setting       |
| 225803 | Dialysis - CVVHD    | Dialysis                | procedureevents_mv | Yes - CRRT setting       |
| 225809 | Dialysis - CVVHDF   | Dialysis                | procedureevents_mv | Yes - CRRT setting       |
| 225955 | Dialysis - SCUF     | Dialysis                | procedureevents_mv | Yes - CRRT setting       |
| 225805 | Peritoneal Dialysis | Dialysis                | procedureevents_mv | No - peritoneal dialysis |

### Reasons for inclusion/exclusion

筛选时的纳入和排除标准为：

- CRRT Setting - 纳入，因为只有在病人正在接受 CRRT 治疗时才会记录。
- Access lines - 排除，这些 `itemid` 被排除的原因是有 access line 并不一定保证病人正在接受 CRRT 治疗。虽然对于 CRRT 治疗 access line 确实必不可少，但是病人并未正在透析时也会有这些记录。（这一段不是很懂，原文：Access lines- no (excluded) - these ITEMIDs are not included as the presence of an access line does not guarantee that CRRT is being delivered. While having an access line is a requirement of performing CRRT, these lines are present even when a patient is not actively being hemodialysed. 主要问题在于 Access line 到底指的什么。是指数据中的记录呢？还是指做透析用的输液管之类的什么东西）
- Peritoneal dialysis - 排除，腹膜透析是另一种类型的透析，不是 CRRT。
- Hemolysis - 排除，和腹膜透析类似，血液透析也是另一种类型的透析而不是 CRRT。



## Step 3: Define rules based upon ITEMIDs



我们已经初步筛选得到应该纳入的数据元素了，现在就可以通过对应的 `itemid` 对应筛选到的数据来进一步定义 CRRT 了：这些数据表示 CRRT 开始、停止、继续还是其他什么呢？

我们直接根据上面的表格按照 **CHARTEVENTS**, **INPUTEVENTS_MV**, 以及  **PROCEDUREEVENTS_MV** 的顺序再来看看这些数据到底代表着 CRRT 的什么过程。注意这些 **_MV** 后缀就是表示这些表格数据来自于 MetaVision，而 _CV 就代表来自 CareVue。所以等我们把 MetaVision 数据提取完了，还必须针对 CareVue 再做一次。

### table 1 of 3: itemid from CHARTEVENTS

从 **CHARTEVENTS** 表格里纳入的 CRRT 有关的数据元素有：

| itemid | label                            | param_type |
| :----- | :------------------------------- | :--------- |
| 224144 | Blood Flow (ml/min)              | Numeric    |
| 224145 | Heparin Dose (per hour)          | Numeric    |
| 224146 | System Integrity                 | Text       |
| 224149 | Access Pressure                  | Numeric    |
| 224150 | Filter Pressure                  | Numeric    |
| 224151 | Effluent Pressure                | Numeric    |
| 224152 | Return Pressure                  | Numeric    |
| 224153 | Replacement Rate                 | Numeric    |
| 224154 | Dialysate Rate                   | Numeric    |
| 224191 | Hourly Patient Fluid Removal     | Numeric    |
| 224404 | ART Lumen Volume                 | Numeric    |
| 224406 | VEN Lumen Volume                 | Numeric    |
| 225183 | Current Goal                     | Numeric    |
| 225956 | Reason for CRRT Filter Change    | Text       |
| 225958 | Heparin Concentration (units/mL) | Text       |
| 225976 | Replacement Fluid                | Text       |
| 225977 | Dialysate Fluid                  | Text       |
| 226457 | Ultrafiltrate Output             | Numeric    |
| 227290 | CRRT mode                        | Text       |
| 228004 | Citrate (ACD-A)                  | Numeric    |
| 228005 | PBP (Prefilter) Replacement Rate | Numeric    |
| 228006 | Post Filter Replacement Rate     | Numeric    |

我们先看看这些数字型的数据。根据专业人士的意见，这些数据应该是 CRRT 的关键参数并且接受 CRRT 的病人会每小时都有记录。

```r
query("SELECT ce.icustay_id, di.label, ce.charttime, ce.value, ce.valueuom
       FROM chartevents ce INNER JOIN d_items di ON
          ce.itemid = di.itemid
       WHERE ce.icustay_id = 246866
       AND ce.itemid in
       (
          224404, -- | ART Lumen Volume
          224406, -- | VEN Lumen Volume
          228004, -- | Citrate (ACD-A)
          224145, -- | Heparin Dose (per hour)
          225183, -- | Current Goal
          224149, -- | Access Pressure
          224144, -- | Blood Flow (ml/min)
          224154, -- | Dialysate Rate
          224151, -- | Effluent Pressure
          224150, -- | Filter Pressure
          224191, -- | Hourly Patient Fluid Removal
          228005, -- | PBP (Prefilter) Replacement Rate
          228006, -- | Post Filter Replacement Rate
          224153, -- | Replacement Rate
          224152, -- | Return Pressure
          226457  -- | Ultrafiltrate Output
      )
      ORDER BY ce.icustay_id, ce.charttime, di.label;")
```

得到：

| *    | icustay_id | label                   | charttime           | value | valueuom |
| :--- | :--------- | :---------------------- | :------------------ | :---: | :------- |
| 1    | 246866     | ART Lumen Volume        | 2161-12-11 20:00:00 |  1.3  | mL       |
| 2    | 246866     | VEN Lumen Volume        | 2161-12-11 20:00:00 |  1.2  | mL       |
| 3    | 246866     | Access Pressure         | 2161-12-11 23:43:00 |  -87  | mmHg     |
| 4    | 246866     | Blood Flow (ml/min)     | 2161-12-11 2343::00 |  200  | ml/min   |
| 5    | 246866     | Citrate (ACD-A)         | 2161-12-11 23:43:00 |   0   | ml/hr    |
| 6    | 246866     | Current Goal            | 2161-12-11 23:43:00 |   0   | mL       |
| 7    | 246866     | Dialysate Rate          | 2161-12-11 23:43:00 |  500  | ml/hr    |
| 8    | 246866     | Effluent Pressure       | 2161-12-11 23:43:00 |  118  | mmHg     |
| 9    | 246866     | Filter Pressure         | 2161-12-11 23:43:00 |  197  | mmHg     |
| 10   | 246866     | Heparin Dose (per hour) | 2161-12-11 23:43:00 |   0   | units    |

从结果中可以看到 `ART Lumen Volume` 和 `VEN Lumen Volume` 的记录时间和其它项差别很大。和专业人员讨论后他们认为这是合理的，这些容量参数意味着输液管是开着的，但是这并不代表 CRRT 正在进行（这一句不知道翻译是否正确，原文：as these volumes indicate settings to keep open the line and are not directly relevant to the administration of CRRT）——最好的情况是这些数据是冗余的，最坏的情况是引起对判断 CRRT 开始和停止的误判。因此最后我们把这两项去掉了。

剩下的 `itemid` 有：

> 224149, -- Access Pressure  
> 224144, -- Blood Flow (ml/min)  
> 228004, -- Citrate (ACD-A)  
> 225183, -- Current Goal  
> 224154, -- Dialysate Rate  
> 224151, -- Effluent Pressure  
> 224150, -- Filter Pressure  
> 224145, -- Heparin Dose (per hour)  
> 224191, -- Hourly Patient Fluid Removal  
> 228005, -- PBP (Prefilter) Replacement Rate  
> 228006, -- Post Filter Replacement Rate  
> 224153, -- Replacement Rate  
> 224152, -- Return Pressure  
> 226457  -- Ultrafiltrate Output  

再来看剩下的字符型数据：

| itemid | label                            | param_type |
| :----- | :------------------------------- | :--------- |
| 224146 | System Integrity                 | Text       |
| 225956 | Reason for CRRT Filter Change    | Text       |
| 225958 | Heparin Concentration (units/mL) | Text       |
| 225976 | Replacement Fluid                | Text       |
| 225977 | Dialysate Fluid                  | Text       |
| 227290 | CRRT mode                        | Text       |

我们一个一个 `itemid` 往下看。首先为了查看方便我们再来定义一个简单地函数：

```r
query_item <- function(item_id){
  qur <- stringr::str_replace_all(paste("
         SELECT value
         , COUNT(distinct icustay_id) AS number_of_patients
         , COUNT(icustay_id) AS number_of_observations
         FROM chartevents
         WHERE itemid = '",item_id,
         "' GROUP BY value ORDER BY value;", sep = ""), "[\n]", "")

  query(qur)
}
```

**224146 - System Integrity**

用上面定义的偷懒函数直接 `query_item(224146)` 得：

```
   value                      number_of_patients number_of_observations
 * <chr>                                   <dbl>                  <dbl>
 1 Active                                    539                  48072
 2 Clots Increasing                          245                   1419
 3 Clots Present                             427                  16836
 4 Clotted                                   233                    441
 5 Discontinued                              339                    771
 6 Line pressure inconsistent                127                    431
 7 New Filter                                357                   1040
 8 No Clot Present                           275                   2615
 9 Recirculating                             172                    466
10 Reinitiated                               336                   1207
```

和专业人员谈论后，我们得知这每一项都代表 CRRT 治疗的不同阶段。我们简单地分为三类：started，stopped 或者 active （即已开始，已停止和进行中）。既然 active 表明 CRRT 进行中，那么 active 首次出现也有可能指开始，因此我们直接归类为 “active/started”。所以人工整理后得到：

| value                      | count | interpretation      |
| :------------------------- | :---- | :------------------ |
| Active                     | 539   | CRRT active/started |
| Clots Increasing           | 245   | CRRT active/started |
| Clots Present              | 427   | CRRT active/started |
| Clotted                    | 233   | CRRT stopped        |
| Discontinued               | 339   | CRRT stopped        |
| Line pressure inconsistent | 127   | CRRT active/started |
| New Filter                 | 357   | CRRT started        |
| No Clot Present            | 275   | CRRT active/started |
| Recirculating              | 172   | CRRT stopped        |
| Reinitiated                | 336   | CRRT started        |

后面我们再写代码来根据这三类不同的意义合并这些 `itemid`。

**225956 - Reason for CRRT Filter Change**

`query_item(225956)`：

```
  value        number_of_patients number_of_observations
* <chr>                     <dbl>                  <dbl>
1 Clotted                      50                     69
2 Line changed                  9                     11
3 Procedure                    20                     31
```

这三项是 stop （即 CRRT 停止），因为这时候要更换滤器。随后的 CRRT 则为 restart （重新开始），而不是当前 CRRT 的延续。（这一段不是很懂是要表示什么，按理来说更换滤器之后开始应该是算作一次啊）

**225958 - Heparin Concentration (units/mL)**

`query_item(225958)`：

```
  value          number_of_patients number_of_observations
* <chr>                       <dbl>                  <dbl>
1 100                            16                    995
2 1000                           41                     94
3 Not applicable                120                   8796
```

这些是 CRRT 的常规参数，可以和其他数字型字段放到一起。

**225976 - Replacement Fluid**

`query_item(225976)`:

```
  value                   number_of_patients number_of_observations
* <chr>                                <dbl>                  <dbl>
1 None                                    14                     19
2 Normal Saline 0.9%                       1                     12
3 Prismasate K0                           78                    201
4 Prismasate K2                          459                  27603
5 Prismasate K4                          387                  30872
6 Sodium Bicarb 150/D5W                    2                      8
7 Sodium Bicarb 75/0.45NS                  6                     48
```

CRRT 的常规参数，可以和其他数字型字段放到一起。

**225977 - Dialysate Fluid**

`query_item(225977)`:

```
  value         number_of_patients number_of_observations
* <chr>                      <dbl>                  <dbl>
1 None                          97                   6025
2 Normal Saline                 32                    695
3 Prismasate K0                 89                    231
4 Prismasate K2                438                  24271
5 Prismasate K4                357                  27320
```

CRRT 的常规参数，可以和其他数字型字段放到一起。

**227290 - CRRT mode**

`query_item(227290)`:

```
  value  number_of_patients number_of_observations
* <chr>               <dbl>                  <dbl>
1 CVVH                   40                   1280
2 CVVHD                  24                    583
3 CVVHDF                498                  25533
4 SCUF                    1                      7
```

虽然看起来不错，但是有可能 `CRRT mode`（CRRT 模式）和真正 CRRT 治疗不是同时记录的。我们来看看是不是所有有 CRRT 参数记录的病人都同时记录了 `CRRT mode`：

```r
query("WITH t1 AS
(
  SELECT icustay_id,
  MAX(CASE WHEN
          itemid = 227290 THEN 1
      ELSE 0 END) AS HasMode
  FROM chartevents ce
  WHERE itemid IN
  (
  227290, --  CRRT mode
  228004, --  Citrate (ACD-A)
  225958, --  Heparin Concentration (units/mL)
  224145, --  Heparin Dose (per hour)
  225183, --  Current Goal -- always there
  224149, --  Access Pressure
  224144, --  Blood Flow (ml/min)
  225977, --  Dialysate Fluid
  224154, --  Dialysate Rate
  224151, --  Effluent Pressure
  224150, --  Filter Pressure
  224191, --  Hourly Patient Fluid Removal
  228005, --  PBP (Prefilter) Replacement Rate
  228006, --  Post Filter Replacement Rate
  225976, --  Replacement Fluid
  224153, --  Replacement Rate
  224152, --  Return Pressure
  226457  --  Ultrafiltrate Output
  )
  GROUP BY icustay_id
)
  SELECT COUNT(icustay_id) AS Num_ICUSTAY_ID
  , SUM(hasmode) AS Num_With_Mode
  FROM t1;")
```

结果：

| num\_icustay\_id | num\_with\_mode |
| :--------------- | :-------------- |
| 784              | 533             |

或者现在进一步查询，有多少人没有其他 CRRT 参数记录而仅有 `CRRT mode` 呢？

```r
query("
WITH t1 AS 
  (
    SELECT icustay_id, charttime
    , MAX(CASE WHEN
            itemid = 227290 THEN 1
          ELSE 0 END) AS HasCRRTMode
    , MAX(CASE WHEN
            itemid != 227290 THEN 1
          ELSE 0 END) AS OtherITEMID
    FROM chartevents ce
    WHERE itemid in
    (
      227290, --  CRRT mode
      228004, --  Citrate (ACD-A)
      225958, --  Heparin Concentration (units/mL)
      224145, --  Heparin Dose (per hour)
      225183, --  Current Goal -- always there
      224149, --  Access Pressure
      224144, --  Blood Flow (ml/min)
      225977, --  Dialysate Fluid
      224154, --  Dialysate Rate
      224151, --  Effluent Pressure
      224150, --  Filter Pressure
      224191, --  Hourly Patient Fluid Removal
      228005, --  PBP (Prefilter) Replacement Rate
      228006, --  Post Filter Replacement Rate
      225976, --  Replacement Fluid
      224153, --  Replacement Rate
      224152, --  Return Pressure
      226457  --  Ultrafiltrate Output
    )
    GROUP BY icustay_id, charttime
  )
  SELECT count(icustay_id) AS NumObs
  , SUM(CASE WHEN HasCRRTMode = 1 AND OtherITEMID = 1 THEN 1 ELSE 0 END) AS Both
  , SUM(CASE WHEN HasCRRTMode = 1 AND OtherITEMID = 0 THEN 1 ELSE 0 END) AS OnlyCRRTMode
  , SUM(CASE WHEN HasCRRTMode = 0 AND OtherITEMID = 1 THEN 1 ELSE 0 END) AS NoCRRTMode
  FROM t1;"
)

```

得到：

| -    | numobs | both  | onlycrrtmode | nocrrtmode |
| :--- | :----- | :---- | :----------- | :--------- |
| 0    | 81162  | 27446 | 1            | 53778      |

可以看到 CRRT mode 这个参数基本上冗余度非常高 (27446/81162 例既有 CRRT mode 的记录也有其他，而只有个别人只有 CRRT mode 记录而没有其他)，并且也不能表示 CRRT 正在进行中（53778/81162 例接受 CRRT 治疗的病人其实并没有 CRRT mode 的记录），而且数据也不完全兼容（不知道这句话指的具体是什么，但是我注意到在上面的表格里  81162 != 27446 + 1 + 53778），所以我们把这个 `item_id` 排除了。

**CHARTEVENTS wrap up**

稍稍总结下，最后 **CHARTEVENTS** 里剩下的表示 CRRT 的 started/ongoing 的 `itemid` 是这些：

> 224149, -- Access Pressure  
> 224144, -- Blood Flow (ml/min) 
> 228004, -- Citrate (ACD-A)  
> 225183, -- Current Goal  
> 225977, -- Dialysate Fluid  
> 224154, -- Dialysate Rate  
> 224151, -- Effluent Pressure  
> 224150, -- Filter Pressure  
> 225958, -- Heparin Concentration (units/mL)  
> 224145, -- Heparin Dose (per hour)  
> 224191, -- Hourly Patient Fluid Removal  
> 228005, -- PBP (Prefilter) Replacement Rate  
> 228006, -- Post Filter Replacement Rate  
> 225976, -- Replacement Fluid  
> 224153, -- Replacement Rate  
> 224152, -- Return Pressure  
> 226457  -- Ultrafiltrate Output 

还有下面这些表示 CRRT 的 started/stopped/ongoing 但是还需要特别处理的：

> 224146, -- System Integrity
> 225956  -- Reason for CRRT Filter Change



### table 2 of 3: INPUTEVENTS_MV



**INPUTEVENT_MV** 里的 `item_id` 有：

> 227525,-- Calcium Gluconate (CRRT)
> 227536 -- KCl (CRRT)

根据专业人士的意见，这些项目肯定是 CRRT 才会有的不需要特别去看了，我们直接把它们标记为 CRRT active/started。

### table 3 of 3: PROCEDUREEVENTS_MV

**PROCEDUREEVENTS_MV** 里的 `item_id` 有：

| itemid | label              |
| :----- | :----------------- |
| 225436 | CRRT Filter Change |
| 225802 | Dialysis - CRRT    |
| 225803 | Dialysis - CVVHD   |
| 225809 | Dialysis - CVVHDF  |
| 225955 | Dialysis - SCUF    |

唯一有点争议的 `item_id` 是 `225436`(CRRT Filter Change)。这个 `item_id` 代表 CRRT 中断，并且更换完成后 CRRT 再开始。原则上这可以作为结束时间，但是这一记录没有 100% 完整，专业人士的意见是相比把它作为 CRRT 结束时间，可能直接忽略这个参数更好。

因此最终纳入的是：

> 225802, -- Dialysis - CRRT  
> 225803, -- Dialysis - CVVHD  
> 225809, -- Dialysis - CVVHDF  
> 225955  -- Dialysis - SCUF  

到这里第 3 步也是最繁琐的人工查看每个 `item_id` 并依据专业知识决定是否纳入以及纳入的元素如何分类就做完了。下面就是利用我们选好的 `item_id` 来定义 CRRT 的时间了。

下一篇继续。