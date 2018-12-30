---
title: Hugo + Blogdown + Github + Netlify 搭建博客记录
author: Jackie
date: '2018-12-30'
slug: hugo-netlify
categories:
  - Blog
tags:
  - Blog
  - Hugo
disable_comments: false
---

前面也说了，是为了图方便省事迁移到 Hugo 的。Hugo 在 Debian 的官方仓库就有，就算没有的话，Hugo 本身也提供二进制包下载，仅从这点来说真的比起 Hexo 要简单好多。这一篇简单记录一下整个过程和碰到的问题。

## Hugo + Blogdown + Github + Netlify 搭建博客

Hugo + Blogdown 搭建博客思路很简单：

1. 安装好 Hugo 和 Blogdown，配合 RStudio 写文和本地预览
2. 本地确定网站没问题后，将整个目录作为一个仓库推到 Github
3. 利用 Netlify 的持续构建（continuous deployment）功能连接到 Github 并自动构建和发布网站

整个过程非常简单。RStudio + Blogdown 基本上真正做到了让用户专注于内容写作，而其他的基本上已经傻瓜化了。详细的教程可以看 [用 R 语言的 blogdown+hugo+netlify+github 建博客](https://cosx.org/2018/01/build-blog-with-blogdown-hugo-netlify-github/) 以及谢益辉大大的终极指南 [blogdown: Creating Websites with R Markdown](https://bookdown.org/yihui/blogdown/) 。


## 小问题

虽然说是很简单，但是过程中也碰到一些问题。

### 选择主题 

整体来看 Hugo + Blogdown 搭建博客真的非常快非常简单，但最后我们再来说说主题的事，这个是整个搭建完我这个博客**我花时间最久的事情**。
主题漂亮炫酷什么的我倒不是很关心，我考虑的主要因素有：Archive + Tag ，评论系统，博文 TOC。

- 归档和标签只要博文数量达到 10+ 以上就很有用了，相当于整个博客的目录和归类
- 评论系统虽然不是很必要，但是我想有的东西更新和补充直接放到评论
- TOC 在文章长了的时候查看整个文章的脉络也很方便

综合了这 3 个因素最终我选择了 whiteplain 和 Hugo-ivy 这两个主题，其中 Hugo-ivy 是[谢益辉大大](https://yihui.name/en/about/)的大作，所以风格淡雅合我的口味，对 R 的高亮支持也会很好，唯一缺憾是没有 TOC。也是在摸索过程中发现应用主题最简单的办法是直接拿主题的默认 `config.toml` 文件过来改而不是自己写。

Hugo-ivy 默认没有支持 Disqus，最后也还是查看了谢益辉做的另一个主题 [Hugo-Xmin](https://github.com/yihui/hugo-xmin) 的[一个 commit](https://github.com/yihui/hugo-xmin/commit/0805ade300ae35b57115470d295bb7e54e75a437) 照葫芦画瓢在 `/path/to/hugo_blog/themes/hugo-ivy/layouts/partials/foot_custom.html` 里添加一行：

```
{{ template "_internal/disqus.html" . }}
```

以后写博文在开头部分设置 `disable_comments: false` 就可以打开评论，反之 `disable_comments: true` 可以关掉评论，很方便了。

### Netlify 的部署和 Hugo 版本

Netlify 注册完帐号选择部署网站，然后选择连接到 Github 仓库，这些前面的都很简单。下一步是构建的具体参数，我们用 Hugo 的话，build command 就是 hugo，publish dir 是 public。这个的意思是我们的网站用 hugo 命令构建，构建出来的网站放在 public 文件夹下供发布。最开始我就这样简单设置了，但是 deploy老是各种提示出错失败，Google 了发现基本上都是因为 Hugo 版本的问题。解决办法呢，就是保证 Netlify 使用的 Hugo 和我们本地构建预览的时候是同个版本，这样肯定就不会有问题了。在 Netlify 的 Deploy settings 里有个 Build environment variables 的选项，我们就需要添加 HUGO_VERSION 变量来指定使用的 Hugo 版本。这时候打开终端 `hugo version` 一下就知道自己用的哪个版本，换成这个版本的 Hugo 再次构建，一次成功。 

## 后记

这篇博客的一个作用是以后要迁移或者重装系统时作参考。其次是通过梳理清楚这个过程搞清楚我们哪些文件是自己的需要备份而哪些可以直接扔掉换电脑再新建就完了。简单来说，`config.toml` 文件 + `content` 文件夹保留下来就可以完整迁移了。主题自己再去下载，目录结构自己用 Hugo 生成。