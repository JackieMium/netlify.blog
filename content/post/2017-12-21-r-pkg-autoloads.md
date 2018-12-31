---
title: R 启动时加载包的正确姿势
author: Jackie
date: '2017-12-21'
slug: r-pkg-autoloads
categories:
  - R
tags:
  - R
  - 基础
  - 问题
disable_comments: no
---


今天看 Hadley Wickham 大大的 [《R for Data Science》](http://r4ds.had.co.nz/) 的时候无意踩坑了，记录一下。


看到章节 **4. Workflow: basics** 的 **4.4** 节做练习的时候，本来这一章十分简单，5 分钟看完的，练习也简单，基本上就是拼写错误啥的。然后第二题：

>Tweak each of the following R commands so that they run correctly:
>
```R
library(tidyverse)

ggplot(dota = mpg) + 
    geom_point(mapping = aes(x = displ, y = hwy))

fliter(mpg, cyl = 8)
filter(diamond, carat > 3
```


ggplot 里面 `data` 写成了 `dota`，嗯好的，原来 Hadley 大大也是宅男。

改过来之后 OK 了。


`filter` 写成了 `fliter`，然后 `=` 应该是 `==`，口亨，so easy。

然后， 然后，改过了之后还是报错：

```R
R >>> filter(mpg, cyl == 8)
Error in stats::filter(mpg, cyl == 8) : object 'cyl' not found
In addition: Warning messages:
1: In data.matrix(data) : NAs introduced by coercion
2: In data.matrix(data) : NAs introduced by coercion
3: In data.matrix(data) : NAs introduced by coercion
4: In data.matrix(data) : NAs introduced by coercion
5: In data.matrix(data) : NAs introduced by coercion
6: In data.matrix(data) : NAs introduced by coercion
```

我瞬间炸了。

把眼睛凑近点看以为是不是哪个 `l` 其实是个 `1` 之类的，发现没问题啊。

实在不行，我觉得可能是代码是复制粘贴的，有看不见的字符之类的问题，决定手打一遍，然后， 然后，然后：

```R
R >>> filter(mpg, cyl == 8)
Error in stats::filter(mpg, cyl == 8) : object 'cyl' not found
In addition: Warning messages:
1: In data.matrix(data) : NAs introduced by coercion
2: In data.matrix(data) : NAs introduced by coercion
3: In data.matrix(data) : NAs introduced by coercion
4: In data.matrix(data) : NAs introduced by coercion
5: In data.matrix(data) : NAs introduced by coercion
6: In data.matrix(data) : NAs introduced by coercion
```

我一度以为我眼睛瞎了。

算了，可能环境乱了，我重新开一个 R 试试，然后， 然后，然后， 然后：

```R
R >>> filter(mpg, cyl == 8)
Error in stats::filter(mpg, cyl == 8) : object 'cyl' not found
In addition: Warning messages:
1: In data.matrix(data) : NAs introduced by coercion
2: In data.matrix(data) : NAs introduced by coercion
3: In data.matrix(data) : NAs introduced by coercion
4: In data.matrix(data) : NAs introduced by coercion
5: In data.matrix(data) : NAs introduced by coercion
6: In data.matrix(data) : NAs introduced by coercion
```

。。。卒 。。。



只能 Google 了，结果还真有悲摧的人碰到这个问题你别说，[Unable to run examples](https://github.com/tidyverse/dplyr/issues/1683) ，直接在 Hadley 的 GitHub repo 里提问了。大大不愧是大大，一语道破真相：

> **Are you loading `dplyr` in your .Rprofile?**

可不是嘛，我偷懒在 `~/.Rprofile` 里加载了好几个常用的包。这个在我另一篇文里写了： [R 启动设置](https://jiangjun.netlify.com/post/2017/04/r-startup/)。 当时还只加载了 `colorout` 这个包。之后我在看 R4DS 这本书时因为 `tidyverse` 老是要用所以也加进去了，还加了几个。然后 `dplyr` 作为光荣的 `tidyverse` 全家桶的一员当然也就一起加载了。

Hadley 下面解释了原因，并且再下面还有人直接提出了解决方案：

> That's a bad idea for exactly this reason. It gets loaded before stats, so `stats::filter()` overrides `dplyr::filter()`

>A better way to handle this is to set the `defaultPackages` option, and ensure the packages are set in the order you wish to load them. E.g. in your `.Rprofile` you could have:
>
```R
.First <- function() {
    autoloads <- c("dplyr", "ggplot2", "Hmisc")
    options(defaultPackages = c(getOption("defaultPackages"), autoloads))
}
```


就是说因为 `dplyr` 加载太早，早于 R 默认会加载的 `stats` 包的加载，所以最后 `stats` 包再加载的时候 `stats::filter` 就 mask 了 `dplyr::filter`。也就是说上面报错是 `stats::filter` 在报错（细心一点其实早就应该看到啊）。验证一下：

```R
R >>> stats::filter(mpg, cyl == 8)
Error in stats::filter(mpg, cyl == 8) : object 'cyl' not found
In addition: Warning messages:
1: In data.matrix(data) : NAs introduced by coercion
2: In data.matrix(data) : NAs introduced by coercion
3: In data.matrix(data) : NAs introduced by coercion
4: In data.matrix(data) : NAs introduced by coercion
5: In data.matrix(data) : NAs introduced by coercion
6: In data.matrix(data) : NAs introduced by coercion

R >>> dplyr::filter(mpg, cyl == 8)
# A tibble: 70 x 11
   manufacturer              model displ  year   cyl      trans   drv   cty   hwy    fl   class
          <chr>              <chr> <dbl> <int> <int>      <chr> <chr> <int> <int> <chr>   <chr>
 1         audi         a6 quattro   4.2  2008     8   auto(s6)     4    16    23     p midsize
 2    chevrolet c1500 suburban 2wd   5.3  2008     8   auto(l4)     r    14    20     r     suv
 3    chevrolet c1500 suburban
```

果然。