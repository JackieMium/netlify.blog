---
title: Logistic 回归模型的拟合优度 (goodness of fit) 检验
author: Jackie
date: '2019-03-17'
slug: logistic-model-goodness-of-fit
categories:
  - Stats
tags:
  - R
  - stats
  - 基础
disable_comments: no
show_toc: yes
output:
  blogdown::html_page:
    toc: no
---

这篇不算是很“正常”的博文，是一阵子之前查资料也就顺手都复制粘贴下来或者加书签的一些网页什么的。整理电脑的时候干脆也就调整一下格式，并根据时间顺序前后注明然后删掉了一些不是很相关的。最后留下的觉得有价值的东西都是和评价 Logisic 回归模型拟合优度的一些内容，所以就直接当作这样一篇博文发出来算了，也方便以后自己查阅。


- 2011-05-09 [R-Help: Hosmer-Lemeshow 'goodness of fit'](https://r.789695.n4.nabble.com/Hosmer-Lemeshow-goodness-of-fit-td3508127.html) 中 [Frank Harrell](https://www.fharrell.com/) 教授谈到 Hosmer–Lemeshow  检验：

    >Please read the documentation carefully, and replace the Design package with the newer rms package. 
    >**The older Hosmer-Lemeshow test requires binning and has lower power**.  It also does not penalize for overfitting.  The newer goodness of fit test in rms/Design should not agree with Hosmer-Lemeshow. 
    >**The test in the `rms` package's residuals.lrm function is the le Cessie - van Houwelingen - Copas - Hosmer unweighted sum of squares test for global goodness of fit**.  Like all statistical tests, a large P-value has no information other than there was not sufficient evidence to reject the null hypothesis.  Here the null hypothesis is that the true probabilities are those specified by the model.  Such an omnibus test, though having good general power (better than Hosmer-Lemeshow) lacks power to detect specific alternatives.  That's why I spend more time allowing for nonlinearity of predictors. 

- 2011-11-22 [StackExchange: Hosmer-Lemeshow vs AIC for logistic regression](https://stats.stackexchange.com/questions/18750/hosmer-lemeshow-vs-aic-for-logistic-regression) 下面 [Frank Harrell](https://www.fharrell.com/) 教授又是和上面差不多的回答:

    > **The Hosmer-Lemeshow test is to some extent obsolete because it requires arbitrary binning of predicted probabilities and does not possess excellent power to detect lack of calibration. It also does not fully penalize for extreme overfitting of the model. Better methods are available** such as
    >
    > Hosmer, D. W.; Hosmer, T.; le Cessie, S. & Lemeshow, S. A comparison of goodness-of-fit tests for the logistic regression model. *Statistics in Medicine*, 1997, 16, 965-980
    >
    > Their new measure is implemented in the R `rms` package.
    >
    > More importantly, **this kind of assessment just addresses overall model calibration (agreement between predicted and observed) and does not address lack of fit** such as improperly transforming a predictor. For that matter, neither does AIC unless you use AIC to compare two models where one is more flexible than the other being tested. I think you are interested in predictive discrimination, for which a generalized R^2 measure, supplemented by *c*c-index (ROC area) may be more appropriate.


- 2013-09-30 [StackExchange: Evaluating a logistic regression model](https://stats.stackexchange.com/questions/71517/evaluating-a-logistic-regression-model) 问题如下: 

    >I have also read that the Hosmer-Lemeshow GoF test is outdated, as it divides the data by 10 in order to run the test, which is rather arbitrary.
    >
    >Instead I use the le Cessie–van Houwelingen–Copas–Hosmer test, implemented in the `rms` package. I not sure exactly how this test is performed, I have not read the papers about it yet. In any case, the results are:
    >
    >```R
    >Sum of squared errors   Expected value|H0         SD           Z   P
    >    1711.6449914        1712.2031888       0.5670868  -0.9843245  0.3249560
    >```
    >
    >**P is large, so there isn't sufficient evidence to say that my model doesn't fit**. Great! 
    >
    >
    >
    >However....When checking the predictive capacity of the model (b), I draw a ROC curve and find that the AUC is `0.6320586`. That doesn’t look very good.
    >
    
    下面的回答很不错：
    
    >There are many thousands of tests one can apply to inspect a logistic regression model, and much of this depends on whether one's goal is prediction, classification, variable selection, inference, causal modeling, etc. **The Hosmer-Lemeshow test, for instance, assesses model calibration and whether predicted values tend to match the predicted frequency when split by risk deciles**. Although, the choice of 10 is arbitrary, the test has asymptotic results and can be easily modified. The HL test, as well as AUC, have (in my opinion) very uninteresting results when calculated on the same data that was used to estimate the logistic regression model. It's a wonder programs like SAS and SPSS made the frequent reporting of statistics for wildly different analyses the de facto way of presenting logistic regression results. Tests of predictive accuracy (e.g. HL and AUC) are better employed with independent data sets, or (even better) data collected over different periods in time to assess a model's predictive ability.
    >
    >Another point to make is that prediction and inference are very different things. There is no objective way to evaluate prediction, an AUC of 0.65 is very good for predicting very rare and complex events like 1 year breast cancer risk. Similarly, inference can be accused of being arbitrary because the traditional false positive rate of 0.05 is just commonly thrown around.
    >
    >If I were you, your problem description seemed to be interested in modeling the effects of the manager reported "obstacles" in investing, so focus on presenting the model adjusted associations. Present the point estimates and 95% confidence intervals for the model odds ratios and be prepared to discuss their meaning, interpretation, and validity with others. A forest plot is an effective graphical tool. You must show the frequency of these obstacles in the data, as well, and present their mediation by other adjustment variables to demonstrate whether the possibility of confounding was small or large in unadjusted results. I would go further still and explore factors like the Cronbach's alpha for consistency among manager reported obstacles to determine if managers tended to report similar problems, or, whether groups of people tended to identify specific problems.
    >
    >**I think you're a bit too focused on the numbers and not the question at hand. 90% of a good statistics presentation takes place before model results are ever presented.**


- 2015-04-28 [StackExchange: What goodness of fit tests for logistic regression models are available in R?](https://stats.stackexchange.com/questions/148648/what-goodness-of-fit-tests-for-logistic-regression-models-are-available-in-r)  这个问题下面的回答提到 pseudo R^2 和上面提到的 Hosmer–Lemeshow ，以及 `ResourceSelection` 可以用来做 Hosmer–Lemeshow 检验: 

    > You can use various **pseudo-R statistics, which are based on deviance produced by the likelihood of full and restricted models**. Deviance is produced by the glm function so you do not need any extra packages.
    >
    > **Hosmer-Lemeshow test can also be used to test global fit for logistic regression. It can produce result that link function used might not be right one.**




- 2016-12-21 另一个类似问题：[How to test for goodness of fit for a logistic regression model?](https://stats.stackexchange.com/questions/252773/how-to-test-for-goodness-of-fit-for-a-logistic-regression-model) 下面的回答同意用 ROC 用来衡量 goodness of fit，同时还建议对 AUC 做 cross-validation 并且提供了用 `sperrorest` 的用法示例：

    >You are on the right track, `ROC` is a common error measure for logistic regression models. More often, the *Area Under The Receiver Operating Curve* (`AUROC`) is used. The advantage is that this measure is numeric and can be compared to other validation runs / model setups of your logistic regression.
    >
    >**You can, for example, use cross-validation to asses the performance of your model.** As this goodness of fit depends highly on your training and test sets, it is common to use many repetitions with different training and tests sets. At the end, you have a somewhat stable estimation of your model fit taking the mean of all repetitions.
    >
    >There are several packages providing cross-validation approaches in R. Assuming you have a fitted model, you can e.g. use the `sperrorest` package with the following setup:
    >
    >```R
    >nspres <- sperrorest(data = data, formula = formula, # your data and formula here
    >                model.fun = glm, model.args = list(family = "binomial"), 
    >                pred.fun = predict, pred.args = list(type = "response"), 
    >                smp.fun = partition.cv, 
    >                smp.args = list(repetition = 1:50, nfold = 10))
    >
    >summary(nspres$pooled.err$train.auroc)   
    >summary(nspres$pooled.err$test.auroc)                  
    >```
    >
    >This will perform a cross-validation using 10 folds, 50 repetitions and give you a summary of the overall mean repetition error.



- 2017-10-22 [StackExchange: Goodness of fit for logistic regression in r](https://stats.stackexchange.com/questions/309316/goodness-of-fit-for-logistic-regression-in-r) ：

    > I suggest to use the Hosmer-Lemeshow goodness of fit test for logistic regression which is implemented in the `ResourceSelection` library with the `hoslem.test` function. [The Hosmer-Lemeshow goodness of fit test for logistic regression](http://thestatsgeek.com/2014/02/16/the-hosmer-lemeshow-goodness-of-fit-test-for-logistic-regression/)
    >
    > The Hosmer–Lemeshow test determine if the differences between observed and expected proportions are significant. If your p is greater than 0.05, than you can say that you have a good fit. 
    > 
    > Follow a simple rule. P > 0.10 "good fitting". 0.05 < P <0.10 borderline significance. P <0.05 "bad fitting"
    
    同时注意评论里提到 Logistic 回归里似然比检验的作用和解读： 2011-01-25 [StackExchange: Likelihood ratio test in R](https://stats.stackexchange.com/questions/6505/likelihood-ratio-test-in-r)。另一个人贴出了一个博客地址，[VETERINARY EPIDEMIOLOGIC RESEARCH: GLM – LOGISTIC REGRESSION](https://denishaine.wordpress.com/2013/03/14/veterinary-epidemiologic-research-glm-logistic-regression/) 、[PART 2](https://denishaine.wordpress.com/2013/03/17/veterinary-epidemiologic-research-glm-logistic-regression-part-2/) 和 [PART 3](https://denishaine.wordpress.com/2013/03/19/veterinary-epidemiologic-research-glm-evaluating-logistic-regression-models-part-3/) 这个系列一共 3 篇讲 Logistic 回归，也很值得一看。类似，上面 [Hosmer-Lemeshow goodness of fit test for logistic regression](http://thestatsgeek.com/2014/02/16/the-hosmer-lemeshow-goodness-of-fit-test-for-logistic-regression/) 这篇博客和与之同一个系列的 [R squared in logistic regression](https://thestatsgeek.com/2014/02/08/r-squared-in-logistic-regression/) 和 [Area under the ROC curve - assessing discrimination in logistic regression](https://thestatsgeek.com/2014/05/05/area-under-the-roc-curve-assessing-discrimination-in-logistic-regression/) 都很值得一看。另外，注意模型的 **Discrimination** & **Calibration** 这两个经常使用的概念，中文里一般称为模型的**区分度**和**校准度**。这两个概念如果细细来看可能都可以详细的写出一篇新的东西来，虽然我对这些概念也没有很熟但我也暂时不打算开这个坑。目前来说，Discrimination 可以用 ROC 和 AUC 来评价，而 Calibration 可以用 Hosmer–Lemeshow  检验来做。 Hosmer–Lemeshow  检验得到 p 值小，则认为模型拟合度不够好。这个检验虽然不是很理想的统计方法，特别是在大样本的时候结果不一定可靠，但其实在文献里是经常会看到人还是这样用。



- [An R Companion for the Handbook of Biological Statistics: Simple Logistic Regression](https://rcompanion.org/rcompanion/e_06.html) 这里的几个小例子也可以快速看一边了解一下整个回归和模型诊断的过程。


- 最后， R 包 [CRAN: generalhoslem: Goodness of Fit Tests for Logistic Regression Models](https://cran.r-project.org/web/packages/generalhoslem/index.html)：
  
    >Functions to **assess the goodness of fit of binary, multinomial and ordinal logistic models.** Included are the Hosmer-Lemeshow tests (binary, multinomial and ordinal) and the Lipsitz and Pulkstenis-Robinson tests (ordinal).
    
    也可以很方便的对二分类、多分类和有序分类变量模型进行拟合优度检验。