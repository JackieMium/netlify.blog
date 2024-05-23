---
title: 不一样的网上冲浪和一些想法
author: Jackie
date: '2023-08-19'
slug: update_2023_different_internet_and_thoughts
categories:
  - Blog
tags:
  - Blog
  - Life
lastmod: '2023-08-19T23:25:17+08:00'
draft: no
keywords: []
description: ''
comment: yes
toc: yes
autoCollapseToc: yes
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

## 互联网/万维网之外？

  从来好像互联网和万维网（World Wide Web，3W，WWW）好像就是同义词，“自古以来”网上冲浪的网就是 WWW。直到我发现还有一个东西就 Gopher，以及稍微更现代版的 Gemini。这二者都是网络协议，简单地说就是它们和 WWW 一样，是一种实现网络间通信信息展示的方案。类比就好像，同样是从中国上海到美国纽约，我们第一个想到的肯定是是坐飞机（就好像说上网我们想到的就是 WWW），但是其实还有一种途径是从海上坐轮船过去（🎵  Once more, you open the door...），而 Gopher 这个单次的原意是“地鼠”那可能就是海底隧道过去吧 :D

<!--more-->

  其实 Gopher 是一种比 HTTP/WWW 出现更早的协议，所以在万维网还没出现以前，大家网上冲浪就已经可以通过访问“地鼠洞”（Gopher holes）来实现的，一个“地鼠洞”相当于一个万维网的网站。在万维网世界里，一个网站比如 Google 的网址是 `https://www.google.com`，在 Gopher 世界里，一个网址长这样：`gopher://gopher.floodgap.com`。把 Google 的网址复制到 Chrome/Firefox 等浏览器，回车就能访问这个网址，同样地把一个 Gopher 网址复制到 Chrome/Firefox 等浏览器，回车 **当然不能访问** 一个 Gopher 网站，duh！因为 Chrome/Firefox 等浏览器不支持 Gopher 协议（早期 Firefox 是支持的后来放弃了）。
  
  此外还有 Gemini 协议，它是在设计和功能上个介于 Gopher 和 HTTP 之间的协议，详见维基百科 [Gemini_(protocol)](https://en.wikipedia.org/wiki/Gemini_protocol#Software)
  
  支持 Gopher 的浏览器，目前有 [Lagrange](https://github.com/skyjake/lagrange)（同时支持 Gopher 和 Gemini）、[Kristall](https://kristall.random-projects.net/)（支持 Gopher、Gemini 和 HTTP）等等，Linux 命令行还有 Lynx、Bombadillo 等等。一些有意思的网站（地鼠警告）：
  
- [Floodgap](gopher://floodgap.com)
- [SDF Gopher Club](gopher://sdf.org:70/1/)
- [tilde.team](gopher://gopher.tildeverse.org)
- [quux.org](gopher://gopher.quux.org:70/1)
- [Geminispace](gemini://geminispace.info/known-hosts)

我也尝试建立了一个“地鼠洞”，目前仅仅写了几篇短小的流水帐式的博客。在 WWW 里博客叫 blog，在地鼠界为了区分，一般叫 phlog。目前感觉 phlog 页面简洁到除了内容真的毫无其他 eye-candy 的东西，当然另一方面 phlog 不利于展示多媒体也是一个短板。

## 轻戒端社交网络

有时候我拿起手机要查个什么东西，但是屏幕一点亮就看到一些社交网络上时间线有更新，一些 App 有新通知，点进去一看手机划划划，五分钟之后放下手机。诶刚刚我拿起手机是要干嘛来着？出现这种情况多了，不由得让我思考社交网络分散了我的注意力，让人习惯于片段性的工作流程而不容易长时间沉浸地专注与一件事情。社交媒体 Facebook、 Twitter 和微博这些平台从起步到最火爆的时候，最常见的用户也是年轻一代；但是在短视频时代，重度用户上到花甲古稀、下到地铁上的中小学生。无法不让我心生警惕，即使我常用的社交网络不在朋友圈微博，我也没有抖音和快手，但是我还是经常在 Mastodon 上刷陌生人动态一刷也能刷很多页。

这也是这一节标题我用了“戒端社交网络”这个说法的原因。据说除了社交网络时代把消费者改称用户（user），另外一个就是在讨论药物滥用、毒品的时候会说 drug users，讽刺。所以我在尝试，尽量减少社交网络的使用，尽量不要无聊的时候就点开社交软件无意义无目的开始刷新。生活毕竟还是要在线下去体验，去留意今天的天是不是很蓝云是不是很美，去关注路边的花今天开了没有楼前割草了以后是不是有青草的芳香，去尝试今天早上还能不能碰到昨晚在树下喵喵叫那只野猫。记得一个播客说，线上的一句“你在干嘛想你了”，可能都抵不过面对面时候一个温柔的眼神。

## 尝试更多地使用 RSS

减少关注社交网络，要探索感兴趣的东西，一方面我开始订阅很多我喜欢的博客和网站的 RSS，另一方面我还有播客。播客已经听了几年了，基本上“播放列表”里的东西一年年只会增多不会减少。手机安装几个浏览器，打开的标签也不断增多，总以为会慢慢看完关掉整理好。这都是不好的习惯，也要慢慢改掉。订阅播客的本质和 RSS 定阅博客是一样的，都只会看到自己想看到的东西，而不是通过无目的的刷社交网络去寻找感兴趣的内容。这也是我不想使用“小宇宙”这种重社交的播客软件的原因之一。近来知道 RssHub 支持导出小宇宙播客到 RSS，我也再也不用手动去搜索那些只在小宇宙上架的播客了。

这样看来，我的信息源已经对社交网络依赖很轻了。当然我的电脑和手机一起几乎保持 Telegram 永远在线，这可能也是需要慢慢改掉的地方。Telegram 我订阅了一些频道，相当于是 RSS 定阅特定网站/话题，群组活跃度有限不过还是需要努力再减少使用。目前最依赖的功能还是利用 Saved messages 当作手机和电脑之间传文件的不限速、空间无上限、永久保存记录的网盘，以及临时的记事本。我开了很多私密频道专门分门别类当作不同的记事本使用，这也是还需要有一个更好的解决办法的场景。

## One More Thing

可能下次更新博客人已经不在国内了，wish me luck!
