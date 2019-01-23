---
title: 记一次 Debian sid 爆炸后的修复
author: Jackies
date: '2019-01-10'
slug: debian-sid-rescue
categories:
  - Linux
tags:
  - Linux
  - 问题
disable_comments: no
show_toc: yes
---

前几天有点东西要写，Debian-cn 群里有人说 sid 更新 systemd-240-2 后炸了，我当时看到了以为个例没有特别去关注。然后过了一天看到置顶消息说 sid 和 Testing 用户不要更新 systemd-240，如果更新了记得不要运行 update-initramfs 否则重启开机会炸，直接进 Emergency Mode 。然后我一想，我好像就更新了啊，`dpkg -l |grep systemd` 查了下版本号确实更新过了。至于内核有没有 update-initramfs 不清楚，大概是有。当时还在群里开玩笑说我的也更新了，是不是这两天干脆别关机了等着修复。然后我正好要到 Windows 去用一下 Word 和 Endnote ，所以当晚把正在写的东西放到 Windows 分区下去然后关机了。

第二天早上再开机，好奇 Debian 有没爆炸就先进去看下:

<img src="/post/2019-01-10-debian-sid-rescue_files/1.debian-emergency-mode.jpg" alt="debian emergency mode" width="80%" height="80%"/>

哈哈哈华丽丽的炸了...

但是因为当时事先也有心理准备了，倒也不慌。再去群里看一下，也有解决方案了。大概就是 liveCD 开机，chroot 加 snapshot 源然后降级 systemd 到 230-x 版。看了一下好像还行，没什么很 tricky 的就放心重启去 Windows 该干嘛干嘛去了。

两天后 Windows 下该做的事完了，这才回头来处理这个问题，以下是简单记录。

## 1. liveCD & chroot

手头没有现成的 liveCD，就去下了一个。因为之前深爱 Gentoo 的缘故，我习惯用 [SystemRescueCd](http://www.system-rescue-cd.org/) 这个 Gentoo-based 的专用的系统急救的 liveCD 环境 。直接官网下载最新 iso，刻盘用 [Rufus](https://rufus.ie/en_IE.html)，刻盘注意 UEFI/MBR 不要选错。

刻完盘重启，进 U 盘，SysResCD 菜单直接选进 X 环境，联网。

然后是要 chroot 进去我的 Debian 盘。我的电脑是 128G SSD + 1T HDD 双硬盘，SSD 有 EFI 分区加一个 Windows 的系统盘两个分区；HDD 开头一个 NTFS 分区，后面依次 HOME、 swap 和 / 分区。分别 cfdisk 两个盘看了一下硬盘和分区，sda 对应 SSD，sdb 对应 HDD，没什么了，记一下分区号后直接挂载：

```
mount /dev/sdb4 /mnt
mount /dev/sdb2 /mnt/home
```

中间一度不知道 EFI 要不要挂载到 /mnt/boot，尝试挂载了一看明显文件夹里内容不对，所以又 umount 了。umount 之后再看 /mnt/boot 内容，果然是系统 /boot 下应该有的内核和 grub 文件里，确认无误。

装过 Arch/Gentoo 的肯定都知道，因为后面要 chroot，所以 dev/proc/sys 这些要记得挂载。这个我是不记得具体挂载命令的，我一样的选择去看 Gentoo 的文档 [Gentoo Handbook](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Base#Mounting_the_necessary_filesystems)。按照文档里来：

```bash
mount --types proc /proc /mnt/proc
mount --rbind /sys /mnt/sys
mount --make-rslave /mnt/sys
mount --rbind /dev /mnt/dev
mount --make-rslave /mnt/dev
```

好了下面直接 chroot: 

```bash
chroot /mnt /bin/bash
source /etc/profile
export PS1="(chroot) ${PS1}"
```

第三个命令是为了在终端命令前的 prompt 里加上 chroot 字样，作为标记防止终端开多了不记得在哪个里面 chroot 的。

后面就是加源降级了。

## 2. snapshot mirror

[snapshot.debian.org](https://snapshot.debian.org) 这个名字就很明显了，快照源。就是把之前每天的官方源做了快照备份。用了这个就能实现包降级了。

看了下主页介绍，再看群里说法 2018-12-20 是 240 版进源前一天，所以照着在源里加上：

```
deb [check-valid-until=no] https://snapshot.debian.org/archive/debian/20181220/ sid main contrib non-free
```

然后 apt update 一下。之后确认终端没有报错表明 snapshot 源元数据获取没问题。这时候再

```bash
aptitude install systemd=239-15
```

**注意**：因为这里降级势必牵涉到解决依赖的问题，所以我用了 aptitude。

但是实际我发现中依旧发现有一些依赖无法满足，我直接 `apt install systemd=239-15` 看了一下，发现 systemd 和与之相关的几个包竟然下载大小为 0Kb，什么意思呢，本地有包在。

所以就简单了，直接去 `/var/cache/apt/archives` 看了一下果然 systemd_239-15_amd64.deb 还在。然后 `dpkg -l |grep systemd` 再检查一下发现 systemd 相关的几个包 libnss-systemd, libpam-systemd, libsystemd0, systemd, systemd-coredump, systemd-sysv 都还在。直接 `dpkg -i` 把它们都装上就行了（这里其实应该还是用 apt install 装让它自己解决依赖，当时脑子抽了只想到 dpkg 了）。dpkg 后来还有报错，但是好歹包都装上了。

当时把错误记录到一个文本文件了，这也是一个失误，因为 liveCD 环境的文件留不下来，应该在挂载的 HOME 分区建文件的，这样重启了文本文件也还在。

想了一下 systemd 既然已经降级了，就直接：

```bash
update-initramfs -u
update-grub
```

更新下内核和引导。然后就放心的重启了。重启后果然，系统已经没问题了。至此这次乌龙的爆炸顺利幸存！

后来还不放心系统依赖，所以重启之后首先 `apt-mark hold systemd`。没有删掉 snapshot 源，再次 `apt update && apt upgrade` 确认系统依赖没有炸，OK。