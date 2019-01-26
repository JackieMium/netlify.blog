options(scipen=999)  # turn off scientific notation like 1e+06
library(ggplot2)
data("midwest", package = "ggplot2")  # load the data

ggplot(midwest, aes(x=area, y=poptotal))  # area and poptotal are columns in 'midwest'

ggplot(midwest, aes(x=area, y=poptotal)) + geom_point()

g <- ggplot(midwest, aes(x=area, y=poptotal)) + geom_point() +
    geom_smooth(method="lm", se = FALSE)
plot(g)

g <- ggplot(midwest, aes(x=area, y=poptotal)) + geom_point() +
    geom_smooth(method="lm", se = FALSE)
g + xlim(c(0, 0.1)) + ylim(c(0, 1000000))

g1 <- g + coord_cartesian(xlim=c(0,0.1), ylim=c(0, 1000000))
plot(g1)

g <- ggplot(midwest, aes(x=area, y=poptotal)) + geom_point() +
    geom_smooth(method="lm", se = FALSE)
g1 <- g + coord_cartesian(xlim=c(0,0.1), ylim=c(0, 1000000))

g1 + labs(title="Area Vs Population",
          subtitle="From midwest dataset",
          y="Population", x="Area",
          caption="Midwest Demographics")
g1 + ggtitle("Area Vs Population", subtitle="From midwest dataset") +
    xlab("Area") +
    ylab("Population")


library(ggplot2)
ggplot(midwest, aes(x = area, y = poptotal)) +
    geom_point() +
    geom_smooth(method = "lm", se = FALSE) +
    coord_cartesian(xlim = c(0, 0.1), ylim = c(0, 1000000)) +
    labs(title = "Area Vs Population",
         subtitle = "From midwest dataset",
         x = "Area",
         y = "Population",
         caption = "Midwest Demographics")


ggplot(midwest, aes(x = area, y = poptotal)) +
    geom_point(col = "steelblue", size = 3) +
    geom_smooth(method = "lm", col = "firebrick", se = FALSE) +
    coord_cartesian(xlim = c(0, 0.1), ylim = c(0, 1000000)) +
    labs(title = "Area Vs Population",
        subtitle = "From midwest dataset",
        y = "Population",
        x = "Area",
        caption = "Midwest Demographics")

gg <- ggplot(midwest, aes(x = area, y = poptotal)) +
    geom_point(aes(col = state), size = 3) +
    geom_smooth(method = "lm", col = "firebrick", size = 2, se = FALSE) +
    coord_cartesian(xlim = c(0, 0.1), ylim = c(0, 1000000)) +
    labs(title = "Area Vs Population",
        subtitle = "From midwest dataset",
        y = "Population",
        x = "Area",
        caption = "Midwest Demographics")
plot(gg)

gg + theme(legend.position="None")
gg + scale_colour_brewer(palette = "Set1")

library(RColorBrewer)
head(brewer.pal.info, 10)


gg <- ggplot(midwest, aes(x = area, y = poptotal)) +
    geom_point(aes(col = state), size = 3) +  # Set color to vary based on state categories.
    geom_smooth(method = "lm", col = "firebrick", size = 2) +
    coord_cartesian(xlim = c(0, 0.1), ylim = c(0, 1000000)) +
    labs(title = "Area Vs Population",
        subtitle = "From midwest dataset",
        y = "Population",
        x = "Area",
        caption = "Midwest Demographics")

gg + scale_x_continuous(breaks = seq(0, 0.1, 0.01))
gg + scale_x_continuous(breaks = seq(0, 0.1, 0.01), labels = letters[1:11])
gg + scale_x_reverse()

gg <- ggplot(midwest, aes(x = area, y = poptotal)) +
    geom_point(aes(col = state), size = 3) +  # Set color to vary based on state categories.
    geom_smooth(method = "lm", col = "firebrick", size = 2) +
    coord_cartesian(xlim = c(0, 0.1), ylim = c(0, 1000000)) +
    labs(title = "Area Vs Population",
        subtitle = "From midwest dataset",
        y = "Population",
        x = "Area",
        caption = "Midwest Demographics")

gg + scale_x_continuous(breaks = seq(0, 0.1, 0.01),
                        labels = sprintf("%1.2f%%", seq(0, 0.1, 0.01))) +
    scale_y_continuous(breaks = seq(0, 1000000, 200000),
                       labels = function(x) {paste0(x / 1000, 'K')})

gg <- ggplot(midwest, aes(x = area, y = poptotal)) +
    geom_point(aes(col = state), size = 3) +
    geom_smooth(method = "lm", col = "firebrick", size = 2) +
    coord_cartesian(xlim = c(0, 0.1), ylim = c(0, 1000000)) +
    labs(title = "Area Vs Population",
        subtitle = "From midwest dataset",
        y = "Population",
        x = "Area",
        caption = "Midwest Demographics") +
    scale_x_continuous(breaks = seq(0, 0.1, 0.01))

gg + theme_bw() + labs(subtitle = "BW Theme")
gg + theme_classic() + labs(subtitle="Classic Theme")
