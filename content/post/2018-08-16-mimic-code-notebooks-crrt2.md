---
title: 跟着 mimic-code 探索 MIMIC 数据之 notebooks CRRT (二)
author: Jackie
date: '2018-08-16'
slug: mimic-code-notebooks-crrt2
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

![0.cover](/post/2018-08-16-mimic-code-notebooks-crrt2_files/0.cover.BingWallpaper-2018-08-15.jpg)


书接上回。
上回说到，我们首先自己搜索 `d_items` 表格找到对应的 `item_id`，然后运用专业知识对这些 `item_id` 进行筛选和归类，最后得到真正能够定义 CRRT 时间的那些 `item_id`。

下面，我们就要通过最后得到的这些 `item_id` 来制定规则，看看到底 CRRT 的时间是如何对应到这些数据上的。

(上一篇放到 GitHub 上之后发现由于代码基本上都是 SQL，只是通过懒人函数 `query` 套壳到 R 了，所以粘贴时按照 R 来高亮。导致高亮这么重要的功能基本上算是废了。所以这一篇决定还是直接贴 SQL 代码好了，要用的时候要么放到 psql 终端要么再套 `query` 的壳就行了。这样有个问题就是和上一篇其实代码上不统一，加之这一篇我也是边写边改，写到后面才决定整体干脆用 SQL 代码又回来改掉的，所以代码风格可能也不一致，写在这里算了，有空再改。反正长长的 Todo list 也不差再多一个了 ...)

**To do:**

- [ ] 检查代码风格是否统一

----

### Step 4: definition of concept using rules

我们再回头想想这个笔记本最开始的目的。我们是想得到每个病人 CRRT 的时间段，就是说对于每个 `icustay_id` 我们都要得到：

- 一个 `STARTTIME`
- 一个 `ENDTIME`

因为在一个病人住院期间，CRRT 有可能会有中断，因此对于一个 `icustay_id` 来说可能不止有一个 `STARTTIME` 和 `ENDTIME`，并且多个时段之间不应该有重叠。

回想一下，**CHARTEENTS** 就是存储各种事件的时刻（`charttime`）用的，而且所有参数设置都记录为一个单独的时间点。因此对于 **CHARTEVENTS** 来说，我们现在的主要任务就是把一系列的 `charttime` 转成一对一对的 `STARTTIME` 和 `ENDTIME`。乍一看这个直接查看连续的一个一个小时的参数然后把它们组合起来就行了。第一个出现的 `charttime` 就作为 `STARTTIME` 而最后一个就是 `ENDTIME`。但是，事实上这些数据不仅仅存储在 **CHARTEVENTS** 里。为了提高准确性，我们还要考虑 **INPUTEVENTS_MV** 和 **PROCEDUREEVENTS_MV**。对于 **INPUTEVENTS_MV** 这个不是很复杂，**INPUTEVENTS** 里对每个观测也有一个 `charttime`，所有我们只需要处理之前把这张表格和 **CHARTEVENTS** 组合起来就行了（可能用 SQL 的 `UNION` 语句吧）。

但是 **PROCEDUREEVENTS_MV** 就略微复杂点了，因为这个表格本来就有 `STARTTIME` 和 `ENDTIME` 这两列。所以我们得先把 **CHARTEVENTS/INPUTEVENTS_MV** 的数据提取完之后再和 **PROCEDUREEVENTS_MV** 合并。

任务明确了我们就可以开始了。我们需要做这些：

1. 把 **INPUTEVENTS_MV** 的时刻聚合成时间段
2. 把 **CHARTEVENTS** 的时刻也转成时间段
3. 把得到的数据和 **PROCEDUREEVENTS_MV** 的比较，想办法把这两个数据合并起来
4. 最后把 **PROCEDUREEVENTS_MV** 和上面 **CHARTEVENTS/INPUTEVENTS_MV** 合并得到的数据再合并起来得到所有 MetaVision 数据的时间段。

这个记事本本来作为示例，为了代码运行效率我们把查询限制为一个 `icustay_id`，我们这里使用 `icustay_id = 246866`（从前面可以看到这其实就是第一个 `icustay_id`）。所以每次代码 `WHERE` 里最后都要记得加上 `AND icustay_id = 246866`。

（原文这里还定义了函数用来在输出里去掉  `icustay_id` 和年月使查看结果时表格不至于太宽不方便看）

###  Aggregating INPUTEVENTS_MV

我们先来看 **INPUTEVENTS_MV**。这个表的每条记录都有一个 `starttime` 和 `endtime`。注意我们查询时要加上一个 `statusdescription = 'Rewritten'`，因为这些都是没有没有实际执行而被重写的医嘱（用作审计用途，但是并没有说明用的药物是什么）。

```sql
SELECT linkorderid
  , orderid
  , CASE WHEN itemid = 227525 THEN 'Calcium' ELSE 'KCl' END AS label
  , starttime, endtime
  , rate, rateuom
  , statusdescription
FROM inputevents_mv
WHERE itemid IN
(
  --227525,-- Calcium Gluconate (CRRT)
  227536 -- KCl (CRRT)
)
AND statusdescription != 'Rewritten'
AND icustay_id = '246866'
ORDER BY starttime, endtime;
```

得到：

| linkorderid | orderid | label | starttime            | endtime              | rate       | rateuom   | statusdescription |
|-------------|---------|-------|----------------------|----------------------|------------|-----------|-------------------|
| 8522257     | 8522257 | KCl   | 2161-12-11T13:30:00Z | 2161-12-11T18:30:00Z | 4.0000002  | mEq./hour | FinishedRunning   |
| 9370484     | 9370484 | KCl   | 2161-12-11T15:45:00Z | 2161-12-11T18:41:00Z | 10.002273  | mEq./hour | FinishedRunning   |
| 3507252     | 3507252 | KCl   | 2161-12-11T18:41:00Z | 2161-12-11T21:36:00Z | 9.997713   | mEq./hour | FinishedRunning   |
| 9525961     | 9525961 | KCl   | 2161-12-11T21:36:00Z | 2161-12-12T00:31:00Z | 10.2857148 | mEq./hour | FinishedRunning   |
| 7118985     | 7118985 | KCl   | 2161-12-12T00:31:00Z | 2161-12-12T03:29:00Z | 10.1123598 | mEq./hour | FinishedRunning   |
| 5395095     | 5395095 | KCl   | 2161-12-12T03:29:00Z | 2161-12-12T06:28:00Z | 10.0558662 | mEq./hour | FinishedRunning   |
| 8065541     | 8065541 | KCl   | 2161-12-12T06:28:00Z | 2161-12-12T09:25:00Z | 10.1694918 | mEq./hour | FinishedRunning   |
| 5758899     | 5758899 | KCl   | 2161-12-12T09:25:00Z | 2161-12-12T12:24:00Z | 10.0558662 | mEq./hour | FinishedRunning   |
| 7157126     | 7157126 | KCl   | 2161-12-12T12:24:00Z | 2161-12-12T12:30:00Z | 10.0000002 | mEq./hour | Paused            |
| 7157126     | 3853798 | KCl   | 2161-12-12T13:30:00Z | 2161-12-12T13:35:00Z | 9.9976338  | mEq./hour | Changed           |
| 7157126     | 6292957 | KCl   | 2161-12-12T13:35:00Z | 2161-12-12T18:08:00Z | 6.1905486  | mEq./hour | FinishedRunning   |
| 271343      | 271343  | KCl   | 2161-12-12T18:08:00Z | 2161-12-12T23:06:00Z | 6.0402684  | mEq./hour | FinishedRunning   |
| 9407942     | 9407942 | KCl   | 2161-12-12T23:06:00Z | 2161-12-13T04:03:00Z | 6.00606    | mEq./hour | FinishedRunning   |
| 9182119     | 9182119 | KCl   | 2161-12-13T04:03:00Z | 2161-12-13T08:29:00Z | 6.005904   | mEq./hour | Stopped           |
| 9720623     | 9720623 | KCl   | 2161-12-13T10:15:00Z | 2161-12-13T15:15:00Z | 6          | mEq./hour | FinishedRunning   |
| 2194578     | 2194578 | KCl   | 2161-12-14T07:28:00Z | 2161-12-14T10:47:00Z | 6          | mEq./hour | FinishedRunning   |
| 7567525     | 7567525 | KCl   | 2161-12-14T10:47:00Z | 2161-12-14T11:01:00Z | 6          | mEq./hour | Changed           |
| 7567525     | 4605649 | KCl   | 2161-12-14T11:01:00Z | 2161-12-14T15:04:00Z | 4.00737984 | mEq./hour | Changed           |
| 7567525     | 5699592 | KCl   | 2161-12-14T15:04:00Z | 2161-12-14T15:18:00Z | 5.8714284  | mEq./hour | FinishedRunning   |
| 8743715     | 8743715 | KCl   | 2161-12-14T15:18:00Z | 2161-12-14T18:28:00Z | 5.9052636  | mEq./hour | FinishedRunning   |
| 4080709     | 4080709 | KCl   | 2161-12-14T18:28:00Z | 2161-12-14T21:44:00Z | 5.96938758 | mEq./hour | FinishedRunning   |
| 4644782     | 4644782 | KCl   | 2161-12-14T21:44:00Z | 2161-12-15T00:57:00Z | 5.90673564 | mEq./hour | FinishedRunning   |
| 741589      | 741589  | KCl   | 2161-12-15T00:57:00Z | 2161-12-15T04:08:00Z | 5.9057589  | mEq./hour | FinishedRunning   |
| 6190220     | 6190220 | KCl   | 2161-12-15T04:08:00Z | 2161-12-15T07:17:00Z | 5.904762   | mEq./hour | FinishedRunning   |
| 1921010     | 1921010 | KCl   | 2161-12-15T07:17:00Z | 2161-12-15T10:34:00Z | 5.9086293  | mEq./hour | FinishedRunning   |
| 3011912     | 3011912 | KCl   | 2161-12-15T10:34:00Z | 2161-12-15T13:46:00Z | 5.90624976 | mEq./hour | FinishedRunning   |
| 1107318     | 1107318 | KCl   | 2161-12-15T13:46:00Z | 2161-12-15T17:01:00Z | 5.90769276 | mEq./hour | FinishedRunning   |
| 609665      | 609665  | KCl   | 2161-12-15T17:01:00Z | 2161-12-15T20:18:00Z | 5.9086293  | mEq./hour | FinishedRunning   |
| 4995198     | 4995198 | KCl   | 2161-12-15T20:18:00Z | 2161-12-15T23:36:00Z | 5.90303016 | mEq./hour | FinishedRunning   |
| 4667423     | 4667423 | KCl   | 2161-12-15T23:36:00Z | 2161-12-16T02:54:00Z | 5.90303016 | mEq./hour | FinishedRunning   |
| 4802077     | 4802077 | KCl   | 2161-12-16T02:54:00Z | 2161-12-16T06:12:00Z | 5.90303016 | mEq./hour | FinishedRunning   |
| 8427007     | 8427007 | KCl   | 2161-12-16T06:12:00Z | 2161-12-16T08:04:00Z | 5.90561268 | mEq./hour | Stopped           |

（我没有改代码把年月去掉，我得到的结果和原文有一点点差别，我懒得再去改了。但我得到的结果和原文内容上没有差别）

正常情况下 `linkorderid` 会把同属于一个医嘱的项目但是可能输液速度发生改动的多行相关联，但是效果不是很好。8-10 行和 16-18 行连到一起了（即它们应该是相连续的，只是输液速度可能变了或者没变），但是我们发现很多应该是同一个的也没有连起来。我们想要的就是连续性事件都合并起来简化得到时间段，看来我们得检查数据然后把一行的 `starttime` 与上一行的 `endtime` 这样的行合并起来。大概步骤是：

1. 创建一个二进制的 flag 用来标记新的 “event”，“event” 认为是多个时间上相连续的用药（不知道 administrtions 到底翻译成什么比较好 ...），即如果下一行与上一行在时间上不连续就认为是新的 “event” 并标记为 `1`, 下一行在时间上与上一行直接连续则标记为 `0`
2. 聚合得到的二进制 flag，然后给每个事件分配一个唯一的整数值（需要在 event 上 `PARTITION`） 
3. 对于每个事件再创建一个用来标识最后一行的整数值（用来从最后一行获得有用的信息）
4. 在每个 event 的 partition 上直接分组聚合，把多个连续的用药信息合并得到一个 `starttime` 和 `endtime`

我们一步一步来看代码怎么写。

#### Step 4.1: create a binary flag for new events

先看这段代码 (这是不完整示例，不可运行)：

```sql
WITH t1 AS
(
SELECT icustay_id
  , CASE WHEN itemid = 227525 then 'Calcium' else 'KCl' END AS label
  , starttime
  , endtime
  , CASE WHEN LAG(endtime) 
		  OVER (PARTITION BY icustay_id, itemid 
			  ORDER BY starttime, endtime) = starttime 
		THEN 0 ELSE 1 END
    AS new_event_flag
  , rate, rateuom
  , statusdescription
FROM inputevents_mv
WHERE itemid IN
(
  --227525,-- Calcium Gluconate (CRRT)
  227536 -- KCl (CRRT)
)
AND statusdescription != 'Rewritten'
AND icustay_id = '246866';
```

这段代码就可以把一个病人的 KCl 使用情况从 **INPUTEVENTS_MV** 中提取出来（因为仅仅是示例所以才加了针对一个病人的限制条件，把这个限制条件去掉就能查询所有人了）。

关键的代码是：

```sql
, CASE WHEN LAG(endtime) OVER
	(PARTITION BY icustay_id, itemid 
		ORDER BY starttime, endtime) = starttime
THEN 0 ELSE 1 END AS new_event_flag
```

这段代码的作用是生成一个布尔值，在当前行的 `starttime` 和上一行的 `endtime` 不等时为 `1`。即，这个布尔值 flag 标记了新的“event”。看看实际运行的效果：

```sql
WITH t1 AS
(
  SELECT icustay_id
  , CASE WHEN 
      itemid = 227525 THEN 'Calcium' 
    ELSE 'KCl' END AS label
  , starttime, endtime
  , LAG(endtime) OVER 
      (PARTITION BY icustay_id, itemid ORDER BY starttime, endtime)
      AS endtime_lag
  , CASE WHEN LAG(endtime) OVER 
      (PARTITION BY icustay_id, itemid ORDER BY starttime, endtime) = starttime THEN 0
    ELSE 1 END AS new_event_flag
  , rate, rateuom
  , statusdescription
  FROM inputevents_mv
  WHERE itemid IN
	  (
  --227525,-- Calcium Gluconate (CRRT)
  227536 -- KCl (CRRT)
	  )
  AND statusdescription != 'Rewritten'
  AND icustay_id = '246866'
)
SELECT 
label
, starttime, endtime, endtime_lag
, new_event_flag
, rate, rateuom
, statusdescription
FROM t1;
```

|      | label | starttime     | endtime       | endtime_lag   | new_event_flag | rate      | rateuom   | statusdescription |
| :--- | :---- | :------------ | :------------ | :------------ | :------------- | :-------- | :-------- | :---------------- |
| 0    | KCl   | Day 11, 21:30 | Day 12, 02:30 | NaT           | 1              | 4.000000  | mEq./hour | FinishedRunning   |
| 1    | KCl   | Day 11, 23:45 | Day 12, 02:41 | Day 12, 02:30 | 1              | 10.002273 | mEq./hour | FinishedRunning   |
| 2    | KCl   | Day 12, 02:41 | Day 12, 05:36 | Day 12, 02:41 | 0              | 9.997713  | mEq./hour | FinishedRunning   |
| 3    | KCl   | Day 12, 05:36 | Day 12, 08:31 | Day 12, 05:36 | 0              | 10.285715 | mEq./hour | FinishedRunning   |
| 4    | KCl   | Day 12, 08:31 | Day 12, 11:29 | Day 12, 08:31 | 0              | 10.112360 | mEq./hour | FinishedRunning   |
| 5    | KCl   | Day 12, 11:29 | Day 12, 14:28 | Day 12, 11:29 | 0              | 10.055866 | mEq./hour | FinishedRunning   |
| 6    | KCl   | Day 12, 14:28 | Day 12, 17:25 | Day 12, 14:28 | 0              | 10.169492 | mEq./hour | FinishedRunning   |
| 7    | KCl   | Day 12, 17:25 | Day 12, 20:24 | Day 12, 17:25 | 0              | 10.055866 | mEq./hour | FinishedRunning   |
| 8    | KCl   | Day 12, 20:24 | Day 12, 20:30 | Day 12, 20:24 | 0              | 10.000000 | mEq./hour | Paused            |
| 9    | KCl   | Day 12, 21:30 | Day 12, 21:35 | Day 12, 20:30 | 1              | 9.997634  | mEq./hour | Changed           |
| 10   | KCl   | Day 12, 21:35 | Day 13, 02:08 | Day 12, 21:35 | 0              | 6.190549  | mEq./hour | FinishedRunning   |
| 11   | KCl   | Day 13, 02:08 | Day 13, 07:06 | Day 13, 02:08 | 0              | 6.040268  | mEq./hour | FinishedRunning   |
| 12   | KCl   | Day 13, 07:06 | Day 13, 12:03 | Day 13, 07:06 | 0              | 6.006060  | mEq./hour | FinishedRunning   |
| 13   | KCl   | Day 13, 12:03 | Day 13, 16:29 | Day 13, 12:03 | 0              | 6.005904  | mEq./hour | Stopped           |
| 14   | KCl   | Day 13, 18:15 | Day 13, 23:15 | Day 13, 16:29 | 1              | 6.000000  | mEq./hour | FinishedRunning   |
| 15   | KCl   | Day 14, 15:28 | Day 14, 18:47 | Day 13, 23:15 | 1              | 6.000000  | mEq./hour | FinishedRunning   |
| 16   | KCl   | Day 14, 18:47 | Day 14, 19:01 | Day 14, 18:47 | 0              | 6.000000  | mEq./hour | Changed           |
| 17   | KCl   | Day 14, 19:01 | Day 14, 23:04 | Day 14, 19:01 | 0              | 4.007380  | mEq./hour | Changed           |
| 18   | KCl   | Day 14, 23:04 | Day 14, 23:18 | Day 14, 23:04 | 0              | 5.871428  | mEq./hour | FinishedRunning   |
| 19   | KCl   | Day 14, 23:18 | Day 15, 02:28 | Day 14, 23:18 | 0              | 5.905264  | mEq./hour | FinishedRunning   |
| 20   | KCl   | Day 15, 02:28 | Day 15, 05:44 | Day 15, 02:28 | 0              | 5.969388  | mEq./hour | FinishedRunning   |
| 21   | KCl   | Day 15, 05:44 | Day 15, 08:57 | Day 15, 05:44 | 0              | 5.906736  | mEq./hour | FinishedRunning   |
| 22   | KCl   | Day 15, 08:57 | Day 15, 12:08 | Day 15, 08:57 | 0              | 5.905759  | mEq./hour | FinishedRunning   |
| 23   | KCl   | Day 15, 12:08 | Day 15, 15:17 | Day 15, 12:08 | 0              | 5.904762  | mEq./hour | FinishedRunning   |
| 24   | KCl   | Day 15, 15:17 | Day 15, 18:34 | Day 15, 15:17 | 0              | 5.908629  | mEq./hour | FinishedRunning   |
| 25   | KCl   | Day 15, 18:34 | Day 15, 21:46 | Day 15, 18:34 | 0              | 5.906250  | mEq./hour | FinishedRunning   |
| 26   | KCl   | Day 15, 21:46 | Day 16, 01:01 | Day 15, 21:46 | 0              | 5.907693  | mEq./hour | FinishedRunning   |
| 27   | KCl   | Day 16, 01:01 | Day 16, 04:18 | Day 16, 01:01 | 0              | 5.908629  | mEq./hour | FinishedRunning   |
| 28   | KCl   | Day 16, 04:18 | Day 16, 07:36 | Day 16, 04:18 | 0              | 5.903030  | mEq./hour | FinishedRunning   |
| 29   | KCl   | Day 16, 07:36 | Day 16, 10:54 | Day 16, 07:36 | 0              | 5.903030  | mEq./hour | FinishedRunning   |
| 30   | KCl   | Day 16, 10:54 | Day 16, 14:12 | Day 16, 10:54 | 0              | 5.903030  | mEq./hour | FinishedRunning   |
| 31   | KCl   | Day 16, 14:12 | Day 16, 16:04 | Day 16, 14:12 | 0              | 5.905613  | mEq./hour | Stopped           |

上面的例子里为了清楚地展示这一查询的工作原理，我们特异添加了 `endtime_lag` 这一列。可以看到第一行的 `endtime_lag` 是 `null`，所以 `new_event_flag = 1`。而下一行 `endtime_lag != starttime`，所以 `new_event_flag` 又是 `1`。再然后，第 2 行（最左边标记为 `2`，下同）的 `endtime_lag == starttime`，所以 `new_event_flag = 0`（时间上连续，所以不是新事件，记 `0`）。这一连续事件一直持续到第 9 行再一次出现 `endtime_lag != starttime`（即一个新的事件，`0` 变为 `1`）。可以看到第 8 行甚至告诉我们原因：因为用药”Paused“（暂停）了。这就是我们上面提到的，一个事件的最后一行可能回提供有用的信息的意思。

#### Step 4.2: create a binary flag for new events

在 SQL 里，要把行通过分组聚合起来要用 *partition* 。要用 _partition_ ，那我们得借助这些分组的某种唯一键值（一般是整数）。一旦有了这个键值就能用 SQL 标准的聚合操作，比如 `MAX()`、`MIN()` 等等这些（不指定特定列的情况下，SQL 的窗口函数运行的原则与这些函数相同）。

这样来说，我们下一步就是要用上面得到的 `new_event_flag` 在我们想要合并的行分组上再得到一个整数键值了。因为我们想要的是把新事件合并起来，那可以通过在 `new_event_flag` 上累加，当有新的事件时 (`new_event_flag = 1`) 这个值就会加 1, 这样同属一个事件的行的这个和会一样，知道下一事件这个值就会再加 1。这样就很巧妙地为每一个事件分配了一个唯一的整数键值了。代码大概是：

```sql
SUM(new_event_flag) OVER 
    (PARTITION BY icustay_id, label 
    ORDER BY starttime, endtime) AS time_partition
```

看看实际效果：

```sql
WITH t1 AS
  (
    SELECT icustay_id
    , CASE WHEN
        itemid = 227525
        THEN 'Calcium' ELSE 'KCl' END AS label
    , starttime, endtime
    , CASE WHEN
        LAG(endtime) OVER
          (PARTITION BY icustay_id, itemid
          ORDER BY starttime, endtime) = starttime
        THEN 0 ELSE 1 END AS new_event_flag
    , rate, rateuom, statusdescription
    FROM inputevents_mv
    WHERE itemid IN
      (
        --227525,-- Calcium Gluconate (CRRT)
        227536 -- KCl (CRRT)
      )
    AND statusdescription != 'Rewritten'
    AND icustay_id = '246866'
  )
  ,t2 AS
  (
    SELECT icustay_id
    , label, starttime, endtime, new_event_flag
    , SUM(new_event_flag) OVER
        (PARTITION BY icustay_id, label
        ORDER BY starttime, endtime) AS time_partition
    , rate, rateuom, statusdescription
    FROM t1
  )
SELECT
label
, starttime, endtime
, new_event_flag
, time_partition
, rate, rateuom, statusdescription
FROM t2
ORDER BY starttime, endtime;
```

得到：

| *    | label | starttime     | endtime       | new_event_flag | time_partition | rate      | rateuom   | statusdescription |
| ---- | ----- | ------------- | ------------- | -------------- | -------------- | --------- | --------- | ----------------- |
| 0    | KCl   | Day 11, 21:30 | Day 12, 02:30 | 1              | 1              | 4.000000  | mEq./hour | FinishedRunning   |
| 1    | KCl   | Day 11, 23:45 | Day 12, 02:41 | 1              | 2              | 10.002273 | mEq./hour | FinishedRunning   |
| 2    | KCl   | Day 12, 02:41 | Day 12, 05:36 | 0              | 2              | 9.997713  | mEq./hour | FinishedRunning   |
| 3    | KCl   | Day 12, 05:36 | Day 12, 08:31 | 0              | 2              | 10.285715 | mEq./hour | FinishedRunning   |
| 4    | KCl   | Day 12, 08:31 | Day 12, 11:29 | 0              | 2              | 10.112360 | mEq./hour | FinishedRunning   |
| 5    | KCl   | Day 12, 11:29 | Day 12, 14:28 | 0              | 2              | 10.055866 | mEq./hour | FinishedRunning   |
| 6    | KCl   | Day 12, 14:28 | Day 12, 17:25 | 0              | 2              | 10.169492 | mEq./hour | FinishedRunning   |
| 7    | KCl   | Day 12, 17:25 | Day 12, 20:24 | 0              | 2              | 10.055866 | mEq./hour | FinishedRunning   |
| 8    | KCl   | Day 12, 20:24 | Day 12, 20:30 | 0              | 2              | 10.000000 | mEq./hour | Paused            |
| 9    | KCl   | Day 12, 21:30 | Day 12, 21:35 | 1              | 3              | 9.997634  | mEq./hour | Changed           |
| 10   | KCl   | Day 12, 21:35 | Day 13, 02:08 | 0              | 3              | 6.190549  | mEq./hour | FinishedRunning   |
| 11   | KCl   | Day 13, 02:08 | Day 13, 07:06 | 0              | 3              | 6.040268  | mEq./hour | FinishedRunning   |
| 12   | KCl   | Day 13, 07:06 | Day 13, 12:03 | 0              | 3              | 6.006060  | mEq./hour | FinishedRunning   |
| 13   | KCl   | Day 13, 12:03 | Day 13, 16:29 | 0              | 3              | 6.005904  | mEq./hour | Stopped           |
| 14   | KCl   | Day 13, 18:15 | Day 13, 23:15 | 1              | 4              | 6.000000  | mEq./hour | FinishedRunning   |
| 15   | KCl   | Day 14, 15:28 | Day 14, 18:47 | 1              | 5              | 6.000000  | mEq./hour | FinishedRunning   |
| 16   | KCl   | Day 14, 18:47 | Day 14, 19:01 | 0              | 5              | 6.000000  | mEq./hour | Changed           |
| 17   | KCl   | Day 14, 19:01 | Day 14, 23:04 | 0              | 5              | 4.007380  | mEq./hour | Changed           |
| 18   | KCl   | Day 14, 23:04 | Day 14, 23:18 | 0              | 5              | 5.871428  | mEq./hour | FinishedRunning   |
| 19   | KCl   | Day 14, 23:18 | Day 15, 02:28 | 0              | 5              | 5.905264  | mEq./hour | FinishedRunning   |
| 20   | KCl   | Day 15, 02:28 | Day 15, 05:44 | 0              | 5              | 5.969388  | mEq./hour | FinishedRunning   |
| 21   | KCl   | Day 15, 05:44 | Day 15, 08:57 | 0              | 5              | 5.906736  | mEq./hour | FinishedRunning   |
| 22   | KCl   | Day 15, 08:57 | Day 15, 12:08 | 0              | 5              | 5.905759  | mEq./hour | FinishedRunning   |
| 23   | KCl   | Day 15, 12:08 | Day 15, 15:17 | 0              | 5              | 5.904762  | mEq./hour | FinishedRunning   |
| 24   | KCl   | Day 15, 15:17 | Day 15, 18:34 | 0              | 5              | 5.908629  | mEq./hour | FinishedRunning   |
| 25   | KCl   | Day 15, 18:34 | Day 15, 21:46 | 0              | 5              | 5.906250  | mEq./hour | FinishedRunning   |
| 26   | KCl   | Day 15, 21:46 | Day 16, 01:01 | 0              | 5              | 5.907693  | mEq./hour | FinishedRunning   |
| 27   | KCl   | Day 16, 01:01 | Day 16, 04:18 | 0              | 5              | 5.908629  | mEq./hour | FinishedRunning   |
| 28   | KCl   | Day 16, 04:18 | Day 16, 07:36 | 0              | 5              | 5.903030  | mEq./hour | FinishedRunning   |
| 29   | KCl   | Day 16, 07:36 | Day 16, 10:54 | 0              | 5              | 5.903030  | mEq./hour | FinishedRunning   |
| 30   | KCl   | Day 16, 10:54 | Day 16, 14:12 | 0              | 5              | 5.903030  | mEq./hour | FinishedRunning   |
| 31   | KCl   | Day 16, 14:12 | Day 16, 16:04 | 0              | 5              | 5.905613  | mEq./hour | Stopped           |

上面的例子（希望是）清楚地展示了如何通过对 KCl 用药情况上用窗函数 *partition* 对 `new_event_flag` 的累加得到一个新的列 `time_partition`。

#### Step 4.3: create an integer to mark the last row of an event

从前面我们知道，每个事件的最后一个 `statusdescription` 可能会提供关于事件为何停止的有用信息，所以我们想到应该为每个事件的最后一行加上一个 flag，及为本事件最后一行添加新的 flag 标记为 `1`。

```sql
WITH t1 AS
  (
    SELECT icustay_id
    , CASE WHEN 
        itemid = 227525 THEN 'Calcium' 
      ELSE 'KCl' END AS label
    , starttime, endtime
    , CASE WHEN LAG(endtime) OVER 
        (PARTITION BY icustay_id, itemid
        ORDER BY starttime, endtime) = starttime
        THEN 0
      ELSE 1 END AS new_event_flag
    , rate, rateuom, statusdescription
    FROM inputevents_mv
    WHERE itemid IN
    (
      --227525,-- Calcium Gluconate (CRRT)
      227536 -- KCl (CRRT)
    )
    AND statusdescription != 'Rewritten'
    AND icustay_id = '246866'
  )
  , t2 AS
  (
    SELECT 
    icustay_id, label
    , starttime, endtime
    , SUM(new_event_flag) OVER 
        (PARTITION BY icustay_id, label 
	        ORDER BY starttime, endtime)
	    AS time_partition 
    , rate, rateuom, statusdescription
    FROM t1
  )
  , t3 AS
  (
    SELECT
    icustay_id, label
    , starttime, endtime, time_partition 
    , rate, rateuom, statusdescription
    , ROW_NUMBER() OVER 
        (PARTITION BY icustay_id, label, time_partition 
            ORDER BY starttime DESC, endtime DESC) 
        AS lastrow
    FROM t2
  )
SELECT 
label, starttime, endtime, time_partition
, rate, rateuom
, statusdescription, lastrow
FROM t3
ORDER BY starttime, endtime;
```

得到：

| *    | label | starttime     | endtime       | time_partition | rate      | rateuom   | statusdescription | lastrow |
| :--- | :---- | :------------ | :------------ | :------------- | :-------- | :-------- | :---------------- | :------ |
| 0    | KCl   | Day 11, 21:30 | Day 12, 02:30 | 1              | 4.000000  | mEq./hour | FinishedRunning   | 1       |
| 1    | KCl   | Day 11, 23:45 | Day 12, 02:41 | 2              | 10.002273 | mEq./hour | FinishedRunning   | 8       |
| 2    | KCl   | Day 12, 02:41 | Day 12, 05:36 | 2              | 9.997713  | mEq./hour | FinishedRunning   | 7       |
| 3    | KCl   | Day 12, 05:36 | Day 12, 08:31 | 2              | 10.285715 | mEq./hour | FinishedRunning   | 6       |
| 4    | KCl   | Day 12, 08:31 | Day 12, 11:29 | 2              | 10.112360 | mEq./hour | FinishedRunning   | 5       |
| 5    | KCl   | Day 12, 11:29 | Day 12, 14:28 | 2              | 10.055866 | mEq./hour | FinishedRunning   | 4       |
| 6    | KCl   | Day 12, 14:28 | Day 12, 17:25 | 2              | 10.169492 | mEq./hour | FinishedRunning   | 3       |
| 7    | KCl   | Day 12, 17:25 | Day 12, 20:24 | 2              | 10.055866 | mEq./hour | FinishedRunning   | 2       |
| 8    | KCl   | Day 12, 20:24 | Day 12, 20:30 | 2              | 10.000000 | mEq./hour | Paused            | 1       |
| 9    | KCl   | Day 12, 21:30 | Day 12, 21:35 | 3              | 9.997634  | mEq./hour | Changed           | 5       |
| 10   | KCl   | Day 12, 21:35 | Day 13, 02:08 | 3              | 6.190549  | mEq./hour | FinishedRunning   | 4       |
| 11   | KCl   | Day 13, 02:08 | Day 13, 07:06 | 3              | 6.040268  | mEq./hour | FinishedRunning   | 3       |
| 12   | KCl   | Day 13, 07:06 | Day 13, 12:03 | 3              | 6.006060  | mEq./hour | FinishedRunning   | 2       |
| 13   | KCl   | Day 13, 12:03 | Day 13, 16:29 | 3              | 6.005904  | mEq./hour | Stopped           | 1       |
| 14   | KCl   | Day 13, 18:15 | Day 13, 23:15 | 4              | 6.000000  | mEq./hour | FinishedRunning   | 1       |
| 15   | KCl   | Day 14, 15:28 | Day 14, 18:47 | 5              | 6.000000  | mEq./hour | FinishedRunning   | 17      |
| 16   | KCl   | Day 14, 18:47 | Day 14, 19:01 | 5              | 6.000000  | mEq./hour | Changed           | 16      |
| 17   | KCl   | Day 14, 19:01 | Day 14, 23:04 | 5              | 4.007380  | mEq./hour | Changed           | 15      |
| 18   | KCl   | Day 14, 23:04 | Day 14, 23:18 | 5              | 5.871428  | mEq./hour | FinishedRunning   | 14      |
| 19   | KCl   | Day 14, 23:18 | Day 15, 02:28 | 5              | 5.905264  | mEq./hour | FinishedRunning   | 13      |
| 20   | KCl   | Day 15, 02:28 | Day 15, 05:44 | 5              | 5.969388  | mEq./hour | FinishedRunning   | 12      |
| 21   | KCl   | Day 15, 05:44 | Day 15, 08:57 | 5              | 5.906736  | mEq./hour | FinishedRunning   | 11      |
| 22   | KCl   | Day 15, 08:57 | Day 15, 12:08 | 5              | 5.905759  | mEq./hour | FinishedRunning   | 10      |
| 23   | KCl   | Day 15, 12:08 | Day 15, 15:17 | 5              | 5.904762  | mEq./hour | FinishedRunning   | 9       |
| 24   | KCl   | Day 15, 15:17 | Day 15, 18:34 | 5              | 5.908629  | mEq./hour | FinishedRunning   | 8       |
| 25   | KCl   | Day 15, 18:34 | Day 15, 21:46 | 5              | 5.906250  | mEq./hour | FinishedRunning   | 7       |
| 26   | KCl   | Day 15, 21:46 | Day 16, 01:01 | 5              | 5.907693  | mEq./hour | FinishedRunning   | 6       |
| 27   | KCl   | Day 16, 01:01 | Day 16, 04:18 | 5              | 5.908629  | mEq./hour | FinishedRunning   | 5       |
| 28   | KCl   | Day 16, 04:18 | Day 16, 07:36 | 5              | 5.903030  | mEq./hour | FinishedRunning   | 4       |
| 29   | KCl   | Day 16, 07:36 | Day 16, 10:54 | 5              | 5.903030  | mEq./hour | FinishedRunning   | 3       |
| 30   | KCl   | Day 16, 10:54 | Day 16, 14:12 | 5              | 5.903030  | mEq./hour | FinishedRunning   | 2       |
| 31   | KCl   | Day 16, 14:12 | Day 16, 16:04 | 5              | 5.905613  | mEq./hour | Stopped           | 1       |

#### Step 4.4: aggregate to merge together contiguous start/end times

现在我们在 `time_partition` （一个 `time_partition` 对应一个事件）的基础上对 `starttime` 和  `endtime` 进行聚合（即在每个事件的基础上聚合）：

- 想要的是第一个 `starttime`，因此用 `MIN(starttime)`
- 想要的是最后一个 `endtime`，因此用 `MAX(endtime)`
- 想要的是最后一个 `statusdescription`，所以我们在仅有最后一行不是 `null` 的列上聚合

最后一步不是很直观，我们来看代码：

```sql
, MIN(CASE WHEN lastrow = 1 THEN statusdescription ELSE null END) AS statusdescription
```

聚合函数会忽略 `null` 值，所以我们新建的这一列仅在 `lastrow = 1` 时不为 `null`，因此保证了聚合函数最终只会返回 `lastrow = 1` 的行。而这个聚合函数其实用 `MIN()` 和 `MAX()` 都可以，因为这个聚合操作最终只会在一个值上起作用（因为每个事件里 `lastrow = 1` 只有一个）。

综合一下，我们最终的查询长这样：

```sql
WITH t1 AS
  (
    SELECT icustay_id
    , CASE WHEN
        itemid = 227525
      THEN 'Calcium' ELSE 'KCl' END AS label
    , starttime, endtime
    , CASE WHEN
        LAG(endtime) OVER
          (PARTITION BY icustay_id, itemid 
	          ORDER BY starttime, endtime) = starttime
      THEN 0
      ELSE 1 END AS new_event_flag
    , rate, rateuom, statusdescription
    FROM inputevents_mv
    WHERE itemid IN
      (
      227525,-- Calcium Gluconate (CRRT)
      227536 -- KCl (CRRT)
      )
    AND statusdescription != 'Rewritten'
    AND icustay_id = '246866'
  )
  , t2 AS
  (
    SELECT
    icustay_id, label
    , starttime, endtime
    , SUM(new_event_flag) OVER
        (PARTITION BY icustay_id, label 
	        ORDER BY starttime, endtime)
	    AS time_partition
    , rate, rateuom, statusdescription
    FROM t1
  )
  , t3 AS
  (
    SELECT
    icustay_id, label
    , starttime, endtime, time_partition
    , rate, rateuom, statusdescription
    , ROW_NUMBER() OVER
        (PARTITION BY icustay_id, label, time_partition
          ORDER BY starttime DESC, endtime DESC)
	    AS lastrow
    FROM t2
  )
SELECT
label
--, time_partition
, MIN(starttime) AS starttime
, MAX(endtime) AS endtime
, MIN(rate) AS rate_min
, MAX(rate) AS rate_max
, MIN(rateuom) AS rateuom
, MIN(CASE WHEN
        lastrow = 1 THEN statusdescription
      ELSE null END)
  AS statusdescription
FROM t3
GROUP BY icustay_id, label, time_partition
ORDER BY starttime, endtime;
```

得到：

| *    | label   | starttime     | endtime       | rate_min | rate_max  | rateuom    | statusdescription |
| :--- | :------ | :------------ | :------------ | :------- | :-------- | :--------- | :---------------- |
| 0    | KCl     | Day 11, 21:30 | Day 12, 02:30 | 4.000000 | 4.000000  | mEq./hour  | FinishedRunning   |
| 1    | KCl     | Day 11, 23:45 | Day 12, 20:30 | 9.997713 | 10.285715 | mEq./hour  | Paused            |
| 2    | Calcium | Day 11, 23:45 | Day 12, 20:30 | 1.201625 | 2.002708  | grams/hour | Paused            |
| 3    | Calcium | Day 12, 21:30 | Day 13, 15:54 | 1.206690 | 1.805171  | grams/hour | FinishedRunning   |
| 4    | KCl     | Day 12, 21:30 | Day 13, 16:29 | 6.005904 | 9.997634  | mEq./hour  | Stopped           |
| 5    | KCl     | Day 13, 18:15 | Day 13, 23:15 | 6.000000 | 6.000000  | mEq./hour  | FinishedRunning   |
| 6    | Calcium | Day 13, 18:15 | Day 13, 23:15 | 1.602136 | 1.602136  | grams/hour | Paused            |
| 7    | KCl     | Day 14, 15:28 | Day 16, 16:04 | 4.007380 | 6.000000  | mEq./hour  | Stopped           |
| 8    | Calcium | Day 14, 15:28 | Day 16, 16:05 | 1.196013 | 1.990426  | grams/hour | Stopped           |

结果看起来没什么问题。所以现在就可以去掉 `icustay_id = '246866'` 这个限制条件查询所有病人数据了：

```sql
WITH t1 AS
  (
    SELECT icustay_id
    , CASE WHEN
        itemid = 227525 THEN 'Calcium'
      ELSE 'KCl' END AS label
    , starttime, endtime
    , CASE WHEN LAS(endtime) OVER
        (PARTITION BY icustay_id, itemid
	        ORDER BY starttime, endtime) = starttime
      THEN 0
	  ELSE 1 END AS new_event_flag
    , rate, rateuom
    , statusdescription
    FROM inputevents_mv
    WHERE itemid IN
      (
      227525,-- Calcium Gluconate (CRRT)
      227536 -- KCl (CRRT)
      )
    AND statusdescription != 'Rewritten'
  )
  , t2 as
  (
    SELECT
    icustay_id, label
    , starttime, endtime
    , SUM(new_event_flag) OVER
        (PARTITION BY icustay_id, label ORDER BY starttime, endtime)
        AS time_partition
    , rate, rateuom, statusdescription
    FROM t1
  )
  , t3 as
  (
    SELECT
    icustay_id, label
    , starttime, endtime
    , time_partition
    , rate, rateuom, statusdescription
    , ROW_NUMBER() OVER
        (PARTITION BY icustay_id, label, time_partition
          ORDER BY starttime DESC, endtime DESC)
      AS lastrow
    FROM t2
  )
SELECT
icustay_id
, time_partition AS num
, MIN(starttime) AS starttime
, max(endtime) AS endtime
, label
--, MIN(rate) AS rate_min
--, max(rate) AS rate_max
--, MIN(rateuom) AS rateuom
--, MIN(CASE WHEN 
			lastrow = 1 THEN statusdescription
		ELSE null END)
	AS statusdescription
FROM t3
GROUP BY icustay_id, label, time_partition
ORDER BY starttime, endtime;
```

#### Conclusion

现在我们对于合并 **INPUTEVENTS_MV** 里的连续事件有了一个很好的方法。但注意，一般情况下没有必要这么做，因为 `linkorderid` 其实就是为了帮我们把同一时间连接起来的。举个例子，我们看一看 ICU 里一个非常常用的镇静药物丙泊酚：

```sql
WITH t1 AS
  (
    SELECT
      icustay_id, di.label
      , mv.linkorderid, mv.orderid
      , starttime, endtime
      , rate, rateuom
      , amount, amountuom
    FROM inputevents_mv mv
    INNER JOIN d_items di ON
      mv.itemid = di.itemid
    AND statusdescription != 'Rewritten'
    AND icustay_id = '246866'
    AND mv.itemid = 222168
  )
SELECT 
  label
  , linkorderid, orderid
  , starttime, endtime
  , rate, rateuom
  , amount, amountuom
FROM t1
ORDER BY starttime, endtime;
```

可以得到：

| *    | label    | linkorderid | orderid | starttime     | endtime       | rate      | rateuom    | amount    | amountuom |
| ---- | -------- | ----------- | ------- | ------------- | ------------- | --------- | ---------- | --------- | --------- |
| 0    | Propofol | 1405816     | 1405816 | Day 09, 18:29 | Day 10, 00:14 | 50.002502 | mcg/kg/min | 17.250863 | mg        |
| 1    | Propofol | 1405816     | 2101314 | Day 10, 01:01 | Day 10, 01:05 | 50.002502 | mcg/kg/min | 0.200010  | mg        |
| 2    | Propofol | 1405816     | 7312240 | Day 10, 01:05 | Day 10, 08:05 | 40.001221 | mcg/kg/min | 16.800513 | mg        |
| 3    | Propofol | 1405816     | 7169415 | Day 10, 08:15 | Day 10, 12:00 | 40.001221 | mcg/kg/min | 9.000275  | mg        |
| 4    | Propofol | 1405816     | 5852722 | Day 10, 12:05 | Day 10, 12:40 | 40.001221 | mcg/kg/min | 1.400043  | mg        |
| 5    | Propofol | 1405816     | 3365285 | Day 10, 12:40 | Day 10, 14:00 | 20.000627 | mcg/kg/min | 1.600050  | mg        |
| 6    | Propofol | 522225      | 522225  | Day 10, 14:00 | Day 10, 14:01 |           | None       | 10.000001 | mg        |
| 7    | Propofol | 1405816     | 5245063 | Day 10, 14:00 | Day 10, 14:07 | 40.001254 | mcg/kg/min | 0.280009  | mg        |
| 8    | Propofol | 2703553     | 2703553 | Day 10, 14:05 | Day 10, 14:06 |           | None       | 10.000001 | mg        |
| 9    | Propofol | 1405816     | 6687581 | Day 10, 14:07 | Day 11, 08:45 | 30.001253 | mcg/kg/min | 33.541401 | mg        |
| 10   | Propofol | 4912696     | 4912696 | Day 10, 16:10 | Day 10, 16:11 |           | None       | 10.000001 | mg        |
| 11   | Propofol | 3838086     | 3838086 | Day 10, 16:55 | Day 10, 16:56 |           | None       | 10.000001 | mg        |
| 12   | Propofol | 5665808     | 5665808 | Day 11, 01:51 | Day 11, 01:52 |           | None       | 10.000001 | mg        |
| 13   | Propofol | 1405816     | 3755617 | Day 11, 09:10 | Day 11, 13:36 | 30.001253 | mcg/kg/min | 7.980333  | mg        |

可以看到 `linkorderid` 也可以很好地把连续的时间组合到了一起，而不需要我们上面辛辛苦苦这么多步骤。它同时也区分了不同的用药，上述第 6 行可以看到有一个 “1 分钟” 的用药。这其实是 MetaVision 系统的表格（结尾带有 `_mv` 的）标记瞬间事件的方法——具体到用药上来说，这是使用了丸剂（相对于静滴来说，口服丸剂是瞬间完成的）。**（2018-10-11 更新：这里其实是推注用药，英语用 Bolus 表示一次性推注，用以和静脉滴注相区别）**
用这个数据我们可以像之前那样在每个事件 *partition* 进行聚合，但是现在我们根本就不需要创建 *partition* 了，因为这其实就是  `linkorderid`。

```sql
WITH t1 AS
  (
    SELECT icustay_id
      , di.itemid, di.label
      , mv.linkorderid, mv.orderid
      , starttime, endtime
      , amount, amountuom
      , rate, rateuom
    FROM inputevents_mv mv
    INNER JOIN d_items di ON
      mv.itemid = di.itemid
    AND statusdescription != 'Rewritten'
    AND icustay_id = '246866'
    AND mv.itemid = 222168
  )
    SELECT icustay_id
      , label, linkorderid
      , MIN(starttime) AS starttime
      , max(endtime) AS endtime
      , MIN(rate) AS rate_min
      , MAX(rate) AS rate_max
      , MAX(rateuom) AS rateuom
      , MIN(amount) AS amount_min
      , MAX(amount) AS amount_max
      , MAX(amountuom) AS amountuom
    FROM t1
    GROUP BY icustay_id, itemid, label, linkorderid
    ORDER BY starttime, endtime;
```

得到：

| *    | label    | linkorderid | starttime     | endtime       | rate_min  | rate_max  | rateuom    | amount_min | amount_max | amountuom |
| :--- | :------- | :---------- | :------------ | :------------ | :-------- | :-------- | :--------- | :--------- | :--------- | :-------- |
| 0    | Propofol | 1405816     | Day 09, 18:29 | Day 11, 13:36 | 20.000627 | 50.002502 | mcg/kg/min | 0.200010   | 33.541401  | mg        |
| 1    | Propofol | 522225      | Day 10, 14:00 | Day 10, 14:01 |           |           | None       | 10.000001  | 10.000001  | mg        |
| 2    | Propofol | 2703553     | Day 10, 14:05 | Day 10, 14:06 |           |           | None       | 10.000001  | 10.000001  | mg        |
| 3    | Propofol | 4912696     | Day 10, 16:10 | Day 10, 16:11 |           |           | None       | 10.000001  | 10.000001  | mg        |
| 4    | Propofol | 3838086     | Day 10, 16:55 | Day 10, 16:56 |           |           | None       | 10.000001  | 10.000001  | mg        |
| 5    | Propofol | 5665808     | Day 11, 01:51 | Day 11, 01:52 |           |           | None       | 10.000001  | 10.000001  | mg        |

丸剂那一行没有 `rate`（用药速度），这很正常，丸剂只有剂量没有用药速度。

-----

又这么长了，奇怪。再分一篇吧。Peace。