---
title: R 启动文件配置文件的加载
author: Jackie
date: '2019-04-22'
slug: r-startup-files
categories:
  - R
tags:
  - R
  - 基础
disable_comments: no
show_toc: yes
output:
  blogdown::html_page:
    toc: yes
---

这个话题其实在之前两篇博文其实都有涉及到过，这次只是看到一些不错的资源和文档，所以干脆总结一下写得全面一点。


参考：

R 文档：

- [**Initialization at Start of an R Session**](https://stat.ethz.ch/R-manual/R-devel/library/base/html/Startup.html)
- [startup: Friendly R Startup Configuration](https://cran.r-project.org/web/packages/startup/vignettes/startup-intro.html)
- [utils::rc.settings](https://stat.ethz.ch/R-manual/R-devel/library/utils/html/rcompgen.html)

几篇博客和几个相关的 StackOverflow 问题：

- [Tony Fischetti: Fun with .Rprofile and customizing R startup](http://www.onthelambda.com/2014/09/17/fun-with-rprofile-and-customizing-r-startup/)
- [Customize your .Rprofile and Keep Your Workspace Clean](https://www.gettinggeneticsdone.com/2013/07/customize-rprofile.html)
- [Karthik Ram: Customizing your .rprofile](http://old.inundata.org/2011/09/29/customizing-your-rprofile/index.html)
- [Karthik Ram: Two incredibly useful functions to throw into your .rprofile](http://old.inundata.org/2012/02/07/two-incredibly-useful-functions-to-throw-into-your-rprofile/index.html)
- [StackOverflow: Expert R users, what's in your .Rprofile?](https://stackoverflow.com/questions/1189759/expert-r-users-whats-in-your-rprofile)
- [StackOverflow: Tricks to manage the available memory in an R session](https://stackoverflow.com/questions/1358003/tricks-to-manage-the-available-memory-in-an-r-session)

# 文件加载读入顺序

R 启动的时候，除非特别指定 `--no-environ` 参数，R 会加载 site 级和用户级的配置文件来初始化**环境变量**。site 配置文件由 `R_ENVIRON` 这个环境变量来指定；如果这个环境变量没有设置的话那 R 会默认读取 `R_HOME/etc/Renviron.site` 这个文件。[`R_HOME`](https://stat.ethz.ch/R-manual/R-devel/library/base/html/Rhome.html) 是 R 的安装目录，可以通过 `R.home(component = "home")` 查询。用户配置文件由 `R_ENVIRON_USER` 指定；如果这个环境变量没有设置的话 R 就会默认按顺序读取当前目录和用户家目录下的 `.Renviron` 文件。

接下来，除非指定了 `--no-site-file` 参数，R 会读取 site 级和用户级的启动配置文件（R 代码文件）。site 配置文件由 `R_PROFILE` 指定；如果这个环境变量未设置的话默认读取 `[R_HOME]/etc/Rprofile.site` 。R 读取这个文件的方式就是直接 `source()`。

除非指定了 `--no-init-file` 参数，否则 R 下一步会寻找并且读取用户的启动配置文件。这个文件由环境变量 `R_PROFILE_USER` 指定；如果这个环境变量未设置的话默认按顺序读取当前目录和用户家目录下的 `.Rprofile`文件。

到这里，R 还只加载了 base 包，所以如果要用其它包里的东西的时候，代码必须明确指明包名，比如 `utils::dump.frames` 这样。当然也可以先载入需要的包然后再调用里面的东西。

再之后，如果没有指定 `--no-restore-data` 或 `--no-restore` 参数的话，R 会自动读入当前目录下的 `.RData` 文件。

接下来，如果 `.First()` 函数存在的话 R 会执行这个函数。`.First()` （和 `.Last()`）可以放在 `.Rprofile` 或者 `Rprofile.site` 文件里，也可以放在 `.RData` 里。

最后，R 会执行 base 包里的 `.First.sys()`，这个函数会通过 `require()` 加载 `options("defaultPackages")`指定的自动载入的那些包。如果我们想改动 R 自动载入的包，好的做法是在 `.Rprofile` 或者`Rprofile.site` 通过 `option()` 来设置。比如，`options(defaultPackages = character())` 将设置为 R 启动是除了 base 包之外不加载其他任何包（启动 R 之前设置环境变量 `R_DEFAULT_PACKAGES = NULL` 也可以达到这个效果），`options(defaultPackages = "")` 或者 `R_DEFAULT_PACKAGES = ""` 则让 R 强制只载入默认包。

`--vanilla` 参数的意思是： `--no-site-file` + `--no-init-file` + `--no-environ`(`R CMD`除外) + `--no-restore` + `--no-save`。

从用户层面来看的话，这些设置文件的加载顺序是：

1. **第一个** `.Renviron` 文件会被首先加载，查找路径顺序是： `Sys.getenv("R_ENVIRON_USER")` --> `./.Renviron` --> `~/.Renviron`

2. **第一个** `.Rprofile` 接下来被读入，查找路径顺序是：`Sys.getenv("R_PROFILE_USER")` --> `./.Rprofile` --> `~/.Rprofile`

---------

上面介绍的启动过程里，涉及到了两种不同的文件：环境文件（*environment files*）包含相关的环境变量的配置清单，而配置文件（*profile files*）是 R 代码。（好吧，这个地方其实有点歧义，但是原文就是这样）。

环境文件是用来配置环境变量的，除了 `#` 开头的注释行外，内容行的形式是 `name=value`。这一内容将环境变量 `name` 设置为 `value`。

类 Unix 系统下 R 启动早期还会加载 `R_HOME/etc/Renviron`这个配置文件。这个文件是 R 在 configure 时设置的环境变量，这些设置可以被 site 或者用户级的环境文件的覆盖。因此不建议直接改动 `R_HOME/etc/Renviron` 文件。注意这个文件和 `R_HOME/etc/Renviron.site` 不是同一个文件。

如果我们想 R 不加载 `~/.Renviron` 或 `~/.Rprofile`，可以把  `R_ENVIRON_USER` 或 `R_PROFILE_USER` 这两个环境变量设为空（`""`）或者一个不存在的路径就行了。

# 我的一些设置

## 默认载入的包

这个上面就提到了，`options("defaultPackages")`这个参数来设置，实例推荐做法形如（其实按文档推荐更好的做法可能是 `local()` 运行）：

```R
options(defaultPackages=c(getOption("defaultPackages"), 'colorout'))
```

## 设置默认镜像

```R
# hardcode a CRAN mirror.
options(repos = "http://mirrors.ustc.edu.cn/CRAN/")
# dual mirrors are supported
options(repos = c("http://mirrors.ustc.edu.cn/CRAN/",
                  "https://mirrors.tongji.edu.cn/CRAN/",
                  "http://mirrors.tuna.tsinghua.edu.cn/CRAN/",
                  "https://mirrors.aliyun.com/CRAN/",
                  "http://mirror.lzu.edu.cn/CRAN/"))
```

这里设置一个和多个任选其一吧。

同时还可以顺便设置一下 BioConductor 镜像，不过这个选项只支持一个镜像地址：

```R
# set Bioconductor mirror at startup
options(BioC_mirror = "https://mirrors.tuna.tsinghua.edu.cn/bioconductor") 
# "http://mirrors.ustc.edu.cn/bioc/" is another great option
```

## stringsAsFactors

这个选项是个磨人的小妖精，所以设置之前一定要考虑清楚。我的代码几乎不怎么会给别人用，所以我就放心的用了这个设置。

```R
options(stringsAsFactors = FALSE)
```

## 一些小函数

alias 其实是懒人设定，以至于我有次在别人电脑上就是记不起来 `setwd()` 这个命令了，尴尬。

```R
cd <- setwd
pwd <- getwd
beep <- function(){beepr::beep()}
q <- function (save = "no", ...){quit(save = save, ...)}

hh <- function(d) {
  row_num <- min(5,nrow(d))
  col_num <- min(5,ncol(d))
  return(d[1:row_num,1:col_num])
}

notify <- function(){
	cmd <- "notify-send"
	system2(cmd, args = "-i notification-message-im 'R Message' 'Mission Complete, Next->!'")
}

u <- function() {
  rvcheck::update_all(check_R = FALSE)
}
```

这些之前都提到过，不再详细说了。这里的 `notify()` 只是针对 Linux 系统的，其他系统可以自己去查，或者直接用 [gaborcsardi/notifier](https://github.com/gaborcsardi/notifier) 这个包也是不错的，这个包对 Windows/Mac OS/Linux 应该都是支持的。

下面

```R
options(prompt = "\033[0;36mR >>> \033[0m", continue = "... ", editor = "vim")
```

定义了终端 Prompt 样式和代码分行时行首的样式，以及编辑器设置成 Vim。

```R
options(show.signif.stars = TRUE, menu.graphics = FALSE)
options(stringsAsFactors = FALSE)  # use with caution
options(max.print = 100)
```

这里只有 `menu.graphics` 这个选项需要解释一下。这个选项控制 R 里有时候弹出来的窗口的，比如不设置默认 repo 的时候 `update.packages()` 就会弹出来窗口一个小窗让你选择从哪个镜像检查更新，我这里设置为 `FALSE` 使 R 不再弹窗而是强制在终端里显示文字选项，参考 [StackOverflow: Disable/suppress tcltk popup for CRAN mirror selection in R](https://stackoverflow.com/questions/7430452/disable-suppress-tcltk-popup-for-cran-mirror-selection-in-r)。添加这个选项是因为 R 默认弹窗是 *Tk* 窗口，这个窗口加载起来很慢。

下面

```R
utils::rc.settings(ipck = TRUE)
```

这个选项就很有意思了。首先 R 默认设置可以通过 `utils::rc.settings()` 查询到。但是具体的，这些选项都是干嘛的呢？ `?rc.status` 和 `?rc.settings` 都可以看到各个选项的帮助文档。我这里设置的 `ipck = TRUE` 表示在 `library()` 和 `require()` 载入包的时候启用自动补全。

然后是前面提到的

```R
# display greeting message at startup
.First <- function(){
    if(interactive()) {
		message("Welcome back, ", Sys.getenv("USER"),"!\n",
                "Current working directory: ", getwd(),
                "\nDate and time: ", format(Sys.time(), "%Y-%m-%d %H:%M"), "\r\n")
		# display a message when all above loaded successfully
		message("###### SUCCESSFULLY LOADED. LET'S DO THIS! ######")
    }
}

# goodbye message at closing
.Last <- function() {
    if(interactive()){
		cat("\nGoodbye at ", date(), "\n")
	}
}
```

分别是在 R 启动和退出时可以运行的函数，这里完全可以根据自己的想法去写。
