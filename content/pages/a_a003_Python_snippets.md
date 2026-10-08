---
title: "Python snippets"
slug: python-snippets
date: 2026-06-28T22:48:13-06:00
lastmod: 2026-07012T19:58:40-06:00
draft: false
author: "Jackie"
toc: true
autoCollapseToc: true
postMetaInFooter: false
hiddenFromHomePage: true
unlisted: true
contentCopyright: true
reward: false
contentCopyright: "CC BY-NC-SA 4.0"
---


# Hush warning messages in a Jupyter Notebook

```
# suppress specific warnings
import warnings
# from numba.core.errors import NumbaDeprecationWarning
warnings.filterwarnings(action="ignore", module="scanpy", message="No data for colormapping")
# warnings.filterwarnings(action="ignore", category=NumbaDeprecationWarning)
warnings.simplefilter("ignore", category=UserWarning)
warnings.filterwarnings("ignore", category=DeprecationWarning)
# or simply ignore all
warnings.filterwarnings("ignore")
```
