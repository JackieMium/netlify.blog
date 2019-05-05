library("dummies")

set.seed(1234)
n = 1000

x1 <- rnorm(n = n, mean = 0, sd = 1)
x2 <- rnorm(n = n, mean = 0, sd = 1)
x3 <- factor(round(runif(n = n, min = 1, max = 5)),
             ordered = TRUE, labels = LETTERS[1:5])
x4 <- factor(x3, ordered = FALSE, labels = letters[1:5])
table(x3)
table(x4)

beta0 <- 1
betaB <- -2
betaC <- 3
betaD <- -4
betaE <- 5

head(dummy(x3))

linpred <- cbind(x1, x2, 1, dummy(x4)[, -1]) %*% c(2, -3, beta0, betaB, betaC, betaD, betaE)
linpred <- cbind(x1, x2, dummy(x4)) %*% c(2, -3, beta0, betaB, betaC, betaD, betaE)
pi <- exp(linpred) / (1 + exp(linpred))
y <- rbinom(n = n, size = 1, prob = pi)
table(y)

dat <- data.frame(y, x1, x2, x3, x4)
head(dat)
str(dat)

fit.ord <- glm(y ~ x1 + x2 + x3,
               family = binomial(link = "logit"),
               data = dat)
fit.unord <- glm(y ~ x1 + x2 + x4,
                 family = binomial(link = "logit"),
                 data = dat)
summary(fit.ord); exp(coef(fit.ord))
summary(fit.unord); exp(coef(fit.unord))

getOption("contrasts")
contrasts(dat$x3) # ord
contrasts(dat$x4)  # un-ord
# set contrast for ord.factor to contr.treatment
options(contrasts = c("contr.treatment", "contr.treatment"))
getOption("contrasts")

fit.ord2 <- glm(y ~ x1 + x2 + x3, family = binomial(link = "logit"), data = dat)
fit.unord2 <- glm(y ~ x1 + x2 + x4, family = binomial(link = "logit"), data = dat)
summary(fit.ord2)
summary(fit.unord2)

fit.ord.reduced <- glm(y ~ x2 + x3, family = binomial(), data = dat)
fit.null <- glm(y ~ 1, family = binomial(), data = dat)
summary(fit.ord.reduced)
summary(fit.null)
with(fit.ord.reduced,
     pchisq(null.deviance - deviance,
            df.null - df.residual, lower.tail = FALSE))
with(fit.ord,
     pchisq(null.deviance - deviance,
            df.null - df.residual, lower.tail = FALSE))
vcdExtra::LRstats(vcdExtra::glmlist(fit.ord2, fit.ord.reduced, fit.null)) # goodness of fit
anova(fit.ord, fit.ord.reduced, test = 'Chisq')

c(model.ord = pscl::pR2(fit.ord)["McFadden"],   # Pseudo R^2,  higher is better
  model.unord = pscl::pR2(fit.unord)["McFadden"],
  model.ord.reduced = pscl::pR2(fit.ord.reduced)["McFadden"])
