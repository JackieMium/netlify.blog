---
title: 通过 git 分支功能同步 GitHub 上游更改
author: 'Jackie'
date: '2026-02-05'
slug: git-sync-with-upstream
categories:
  - Blog
tags:
  - Blog
  - 问题
lastmod: '2026-02-05T19:32:19-06:00'
draft: false
keywords: []
description: ''
comment: true
toc: yes
autoCollapseToc: false
postMetaInFooter: true
hiddenFromHomePage: false
contentCopyright: true
reward: false
mathjax: false
mathjaxEnableSingleDollar: false
mathjaxEnableAutoNumber: false
hideHeaderAndFooter: false
flowchartDiagrams:
  enable: false
  options: ''
sequenceDiagrams:
  enable: false
  options: ''
---

之前提过，其实用 Hugo 搭建和维护博客相对来说非常省事，但是缺点也很明显。Hugo 本身版本更新迭代速度很快，经常碰到的就是升级后有一些功能不再支持，可能是被移除，或者工作方式改变。另外就是 Hugo 没有内置主题，所以必须引入第三方主题。这时候也就出现连带问题，第三方主题必须同步 Hugo 的工作方式，不然也有可能失效。

<!--more-->

如果不想完全依赖于上游主题，能力足够的话完全可以动手从头写一个主题。另一种是在一个现有主题基础上更改，删除增加不同特性，当然这样自由度有一定折扣，但是难度更小。现在这个博客使用的主题就采用的是 [Even](https://github.com/olOwOlo/hugo-theme-even) 这个分支的一个 fork。在原有基础上没有做功能的增加减少，只是在原有基础上尽量保持对最新 Hugo 一直可用，同时尽量同步主题上游更改。这就涉及到如何同步 fork 和上游更新的问题。

以我的 fork 为例，在本地 `even` 文件夹下工作时，`git remote -v` 可能查看目前的上游，本地目前只有 `master` 一个分支，它拥有权限包括 fetch 和 push，它们的上游目前都指向在 Github 上的 fork 得到的仓库。这是典型的工作流程，fork 拥有者本人拥有向自己的远程 fork 仓库的 fetch 和 push 权限，但是不拥有向上游原始仓库的拉取和推送权限。所以第一步，需要把上游仓库也添加为上游。比如要把 even 这个主题的上游仓库 `olOwOlo/hugo-theme-even` 添加为本地仓库上游并且拉取上游更新：

```
git remote add upstream_even https://github.com/olOwOlo/hugo-theme-even
git fetch upstream_even
```

之后新建一个并且切换到一个本地分支 `upstream_master`，这个本地分支设置为追踪上游的 `master` 分支

```
git checkout -b upstream_master --track upstream_even/master
```

到这里所有设置都准备好了。现在每当上游（的 `master` 分支）有新的改动需要同步，只需要采取下面的步骤：

```
# git checkout upstream_master
git pull upstream_even master
git checkout master
git merge upstream_master
```

就可以同步上游更新。这里做的工作是切换到本地的追踪上游的那个分支 `upstream_master`，而因为这个分支已经设置过追踪上游，所以直接拉取。本地这个分支拉取完上游改动后，切换回本地仓库的 `master` 分支，然后把刚刚拉取的上游更新从 `upstream_master` 里合并进来。现在只需要在本地 `master` 分支上把所有冲突解决并提交。由于本地的 `master` 分支上游追踪远程 Github 上的仓库的 `master`，所以提交更新后再 push 就会把更新推送到远程，这就完成了 fork 和上游之间的同步。


参考：

- [Merging Git Upstream changes](https://linuxsimba.github.io/merging-upstream-repo-changes)