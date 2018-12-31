---
title: 让 R 在完成任务时发送通知或者叮一声
author: Jackie
date: '2017-06-22'
slug: r-beep-notify
categories:
  - R
tags:
  - 问题
  - R
disable_comments: false
---


R 有时候计算或者任务会比较慢，比如很多基因一起做 GO enrichment、下载在线数据集、模拟缺失数据等等，这时候我经常喜欢去干点别的，比如去刷刷饭、看看视频或者听听歌之类的。我的习惯是在 Linux 里多开几个桌面，一个桌面用来工作，另一个桌面就是刷饭啊看视频啊这些。所以往往在这个等的时间去干点别的还得来回切看这个任务什么时候完成，更有甚者有时候看别的就忘了看，其实任务早就跑完了的.....所以就很需要 R 可以在任务完成的时候以某种方式发出一个通知。通知呢，最好是有两种，一种是直接和普通系统通知一样弹窗，只要你还盯着屏幕的话肯定不会错过；另外一种就是能发出声音，这样就算这时候你在低头刷手机也能及时知道。

所以呢，我就去 Google 了一下，首先找到了这个：

[Is there a way to make R beep/play a sound at the end of a script?](https://stackoverflow.com/questions/3365657/is-there-a-way-to-make-r-beep-play-a-sound-at-the-end-of-a-script) 。这里就提到了多种办法，有通知的也有发声的。总结一下我各自挑选了一种优雅的办法：

## 1. 任务完成时 “叮” 一声

这个有一些调用系统内部发声的办法，但是综合一下我选了用 [beepr](https://github.com/rasmusab/beepr) 这个包，简单可靠而且可以自动自定义。

```R
install.packages("beepr")
library(beepr)
beep()
```

而且这个包自带了多种声音：

   > ### Usage
   >
   > `beep(sound = 1, expr = NULL)`
   >
   > ### Arguments
   >
   > `sound` character string or number specifying what sound to be played by either specifying one of the built in sounds or specifying the path to a wav file. The default is 1. Possible sounds are:
   >
   > 0. random
   >
   >
   > 1. "ping"
   > 2. "coin"
   > 3. "fanfare"
   > 4. "complete"
   > 5. "treasure"
   > 6. "ready"
   > 7. "shotgun"
   > 8. "mario"
   > 9. "wilhelm"
   > 10. "facebook"
   > 11. "sword"

我的做法是就用默认的声音（类似于微波炉加热到时间的那个声音），但是为了偷懒，我是在 `~/.Rprofile` 添加了一行：

```R
beep <- function(){beepr::beep()}
```

这样既免了每次用的时候都要加载一下包或者要打 `beepr::beep()` 这么长的命令。

## 2. 让 R 发出系统通知

Linux 下我们要用到 `notify-send` 这个命令，在 Debian 下对应 libnotify-bin 这个包。`notify-send` 的命令格式：

```shell
Usage:
  notify-send [OPTION?] <SUMMARY> [BODY] - create a notification

Help Options:
  -?, --help                        Show help options

Application Options:
  -u, --urgency=LEVEL               Specifies the urgency level (low, normal, critical).
  -t, --expire-time=TIME            Specifies the timeout in milliseconds at which to expire the notification.
  -a, --app-name=APP_NAME           Specifies the app name for the icon
  -i, --icon=ICON[,ICON...]         Specifies an icon filename or stock icon to display.
  -c, --category=TYPE[,TYPE...]     Specifies the notification category.
  -h, --hint=TYPE:NAME:VALUE        Specifies basic extra data to pass. Valid types are int, double, string and byte.
  -v, --version                     Version of the package.
```

直接 `notify-send "test msg"` 应该就能看到系统弹出通知，内容就是 "test msg"。如果这时候系统就不能发通知的话可能要检查 `notification-daemon` 的状况，参考 [notify-send not working on Debian Wheezy](https://unix.stackexchange.com/questions/173829/notify-send-not-working-on-debian-wheezy) 。我的系统上没什么问题，所以接下来就是 R 怎么调用这个系统命令的问题了。幸好，R 有个 `system()`  就是专门干这个的。所以，和前面一样，我的偷懒做法就是在 `~/.Rprofile` 里写一个自定义函数：

```R
notify <- function(){
	cmd <- "notify-send"
	system2(cmd, args="-i emblem-default 'R Message' 'Mission Complete!'")
}
```

-----------

以后执行需要长时间跑的命令时，如果你打算去打开网页看其他东西，直接在末尾放上 `notify()` 任务完成时桌面会弹出通知。如果你打算~~玩手机~~看看书，`beep()` 会在任务完成是发出声音（在自习室或图书馆请插上耳机谢谢）。