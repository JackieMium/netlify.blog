---
title: Hugo + GitHub + Netlify 的第一篇博客
author: Jackie
date: '2018-12-30'
slug: first-post
categories:
  - Blog
tags:
  - Blog
  - Hugo
disable_comments: false
---

这虽然可能显示出来并非是第一篇博文，但是确实是 Hugo 上的第一篇。没有显示为第一篇是因为我把其他平台的博文迁移到这里之后保留原始的发文日期。

## 缘起

Hexo 嫌麻烦的我直接复制粘贴到 Github Issues 了，方便倒是还行，只需要写好 markdown 文件，图片事先上传到仓库然后再替换 markdown 文件里的本地图片地址为在线地址，最后再把改好的 markdown 文件内容整体复制粘贴到 Issues。

但是 Issues 也有一些小问题：

- 首先没有 Archieve 功能，所以博客不能很好的归档，我的办法是自己手动把仓库的 README 当作归档和目录
- 其次是 Tags/Labels  功能依赖于颜色做区分，花哨而不实用，看得眼花缭乱的还得不到很多有用信息，当然可以不管颜色直接用，但是颜色又影响查找，因为你在找一个标签的时候它有颜色你会自动去依赖颜色看的
- 再就是图片的问题，自己事先上传图片到仓库然后替换 markdown 里的图片地址为仓库的在线地址虽然不难，但是图片一多工作量就大了，而且容易遗漏
- 最后，Github Issue 没法用主题，美观且不说，无法显示整个博文的目录。整体博文长了之后看起来太素且无法跳转，太长了我自己都不大搞的清楚脉络

还有一些小问题不一一列举了。所以，今天看了看，Hexo 我是不准备用了，Hugo 我一看 Debian 直接 apt 就行，太方便了。所以就建个仓库试试看 Hugo。现在只是试试，博文暂时还放在 Issue，有空了再决定要不要做迁移吧。

## 测试

常规惯例，测试一下常用功能。

首先是代码， `ggplot2` 学习代码来一个：

```r
library(ggplot2)
data("midwest", package = "ggplot2")

# Scatterplot
gg <- ggplot(midwest, aes(x=area, y=poptotal)) + 
  geom_point(aes(col=state, size=popdensity)) + 
  geom_smooth(method="loess", se=F) + 
  xlim(c(0, 0.1)) + 
  ylim(c(0, 500000)) + 
  labs(subtitle="Area Vs Population", 
       y="Population", 
       x="Area", 
       title="Scatterplot", 
       caption = "Source: midwest")
plot(gg)
```

在线图片插一个：

![tmp](https://i.imgur.com/Hc4gij4.jpg)

再来一个本地我老婆的照片：

<img src="/post/2018-12-30-first-post_files/gakki.jpeg" alt="gakki" width="50%" height="50%"/>

表格来一个：

| Tables   |      Are      |  Cool |
|----------|:-------------:|------:|
| col 1 is |  left-aligned | $1600 |
| col 2 is |    centered   |   $12 |
| col 3 is | right-aligned |    $1 |