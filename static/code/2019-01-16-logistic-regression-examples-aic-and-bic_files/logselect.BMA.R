library("BMA")

# e.g. 1 ------------------------------------------------------------------

rates <- round(seq(.1, .9, length.out=15), 2)
rates

set.seed(1234)
x1 <- rbinom(1000, 1, rates[1])
x2 <- rbinom(1000, 1, rates[2])
x3 <- rbinom(1000, 1, rates[3])
x4 <- rbinom(1000, 1, rates[4])
x5 <- rbinom(1000, 1, rates[5])
x6 <- rbinom(1000, 1, rates[6])
x7 <- rbinom(1000, 1, rates[7])
x8 <- rbinom(1000, 1, rates[8])
x9 <- rbinom(1000, 1, rates[9])
x10 <- rbinom(1000, 1, rates[10])
x11 <- rbinom(1000, 1, rates[11])
x12 <- rbinom(1000, 1, rates[12])
x13 <- rbinom(1000, 1, rates[13])
x14 <- rbinom(1000, 1, rates[14])
x15 <- rbinom(1000, 1, rates[15])

x16 <- rnorm(1000)
x17 <- rnorm(1000)
x18 <- rnorm(1000)
x19 <- rnorm(1000)
x20 <- rnorm(1000)
x21 <- rnorm(1000)
x22 <- rnorm(1000)
x23 <- rnorm(1000)
x24 <- rnorm(1000)
x25 <- rnorm(1000)
x26 <- rnorm(1000)
x27 <- rnorm(1000)
x28 <- rnorm(1000)
x29 <- rnorm(1000)
x30 <- rnorm(1000)

y <- rbinom(1000, 1, 0.5)

example1.dat <- data.frame(y, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10,
                           x11, x12, x13, x14, x15, x16, x17, x18, x19, x20,
                           x21, x22, x23, x24, x25, x26, x27, x28, x29, x30)
names(example1.dat)
head(example1.dat)

fml <- as.formula(paste0("y ~",
                         paste(names(example1.dat[, -y]), collapse = ' + ')))
output1 <- bic.glm(fml, glm.family = "binomial",
                   data = example1.dat, maxCol = 31)
summary(output1)
output1$postprob
output1$label
output1$probne0
output1$postmean
output1$postsd

output1$mle
output1$se

imageplot.bma(output1)

output1.aic <- glm(fml, data = example1.dat, family = binomial(link = 'logit'))
summary(output1.aic)
step.aic1 <- step(output1.aic)
summary(step.aic1)


# e.g. 2 -------------------------------------------------------------------

rates <- round(seq(.1, .9, length.out=15), 2)
rates

x1 <- rbinom(500, 1, rates[1])
x2 <- rbinom(500, 1, rates[2])
x3 <- rbinom(500, 1, rates[3])
x4 <- rbinom(500, 1, rates[4])
x5 <- rbinom(500, 1, rates[5])
x6 <- rbinom(500, 1, rates[6])
x7 <- rbinom(500, 1, rates[7])
x8 <- rbinom(500, 1, rates[8])
x9 <- rbinom(500, 1, rates[9])
x10 <- rbinom(500, 1, rates[10])

x11 <- rnorm(500)
x12 <- rnorm(500)
x13 <- rnorm(500)
x14 <- rnorm(500)
x15 <- rnorm(500)
x16 <- rnorm(500)
x17 <- rnorm(500)
x18 <- rnorm(500)
x19 <- rnorm(500)
x20 <- rnorm(500)

inv.logit.rate <- exp(x1 + x2 + x3 + x4 + x5 + x11 + x12 + x13 + x14 +x15) /
    (1 + exp(x1 + x2 + x3 + x4 + x5 + x11 + x12 + x13 + x14 +x15))
y <- rbinom(500, 1, inv.logit.rate)

example2.dat <- data.frame(y, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10,
                           x11, x12, x13, x14, x15, x16, x17, x18, x19, x20)

fml <- as.formula(paste0("y ~",
                         paste(names(example2.dat[, -y]), collapse = ' + ')))
output2 <- bic.glm(fml, glm.family = "binomial",
                   data = example2.dat)
summary(output2)
output2$postprob
output2$label
output2$probne0
output2$postmean

output2$mle
output2$se


output2.aic <- glm(fml, data = example2.dat, family = "binomial")
summary(output2.aic)
step.aic <- step(output2.aic)
summary(output2.aic)

# e.g. 3 --------------------------------------------

data("birthwt", package = 'MASS')

birthwt$smoke <- as.factor(birthwt$smoke)
birthwt$race <- as.factor(birthwt$race)
birthwt$ptl <- as.factor(birthwt$ptl)
birthwt$ht <- as.factor(birthwt$ht)
birthwt$ui <- as.factor(birthwt$ui)
birthwt <- subset(birthwt, select = -c(id, bwt))
summary(birthwt)

output3 <- bic.glm(low ~ age + lwt + smoke + ptl + ht + ui +
                       ftv + race, glm.family = binomial, data = birthwt)
summary(output3)
output3$postprob
output3$names
output3$probne0

output3$postmean

output3$mle

output3$se
