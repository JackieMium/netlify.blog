library(ggplot2)
theme_set(theme_classic())

# Histogram on a Continuous (Numeric) Variable
g <- ggplot(mpg, aes(displ)) + scale_fill_brewer(palette = "Spectral")
g + geom_histogram(aes(fill=class),
                   binwidth = .1,
                   col="black",
                   size=.1) +  # change binwidth
    labs(title="Histogram with Auto Binning",
         subtitle="Engine Displacement across Vehicle Classes")

g + geom_histogram(aes(fill=class),
                   bins=5,
                   col="black",
                   size=.1) +   # change number of bins
    labs(title="Histogram with Fixed Bins",
         subtitle="Engine Displacement across Vehicle Classes")


library(ggplot2)
theme_set(theme_classic())
# Histogram on a Categorical variable
g <- ggplot(mpg, aes(manufacturer))
g + geom_bar(aes(fill=class), width = 0.5) +
    theme(axis.text.x = element_text(angle=65, vjust=0.6)) +
    labs(title="Histogram on Categorical Variable",
         subtitle="Manufacturer across Vehicle Classes")


library(ggplot2)
theme_set(theme_classic())
# Plot
g <- ggplot(mpg, aes(cty))
g + geom_density(aes(fill=factor(cyl)), alpha=0.8) +
    labs(title="Density plot",
         subtitle="City Mileage Grouped by Number of cylinders",
         caption="Source: mpg",
         x="City Mileage",
         fill="# Cylinders")


library(ggplot2)
theme_set(theme_classic())
# Plot
g <- ggplot(mpg, aes(class, cty))
g + geom_boxplot(varwidth=T, fill="plum") +
    labs(title="Box plot",
         subtitle="City Mileage grouped by Class of vehicle",
         caption="Source: mpg",
         x="Class of Vehicle",
         y="City Mileage")

library("ggplot2")
library("ggthemes")
g <- ggplot(mpg, aes(class, cty))
g + geom_boxplot(aes(fill=factor(cyl))) +
    theme(axis.text.x = element_text(angle=65, vjust=0.6)) +
    labs(title="Box plot",
         subtitle="City Mileage grouped by Class of vehicle",
         caption="Source: mpg",
         x="Class of Vehicle",
         y="City Mileage")


library(ggplot2)
theme_set(theme_bw())

# plot
g <- ggplot(mpg, aes(manufacturer, cty))
g + geom_boxplot() +
    geom_dotplot(binaxis='y',
                 stackdir='center',
                 dotsize = .5,
                 fill="red") +
    theme(axis.text.x = element_text(angle=65, vjust=0.6)) +
    labs(title="Box plot + Dot plot",
         subtitle="City Mileage vs Class: Each dot represents 1 row in source data",
         caption="Source: mpg",
         x="Class of Vehicle",
         y="City Mileage")



library(ggthemes)
library(ggplot2)
theme_set(theme_tufte())  # from ggthemes

# plot
g <- ggplot(mpg, aes(manufacturer, cty))
g + geom_tufteboxplot() +
    theme(axis.text.x = element_text(angle=65, vjust=0.6)) +
    labs(title="Tufte Styled Boxplot",
         subtitle="City Mileage grouped by Class of vehicle",
         caption="Source: mpg",
         x="Class of Vehicle",
         y="City Mileage")


library(ggplot2)
theme_set(theme_bw())

# plot
g <- ggplot(mpg, aes(class, cty))
g + geom_violin() +
    labs(title="Violin plot",
         subtitle="City Mileage vs Class of vehicle",
         caption="Source: mpg",
         x="Class of Vehicle",
         y="City Mileage")


library(ggplot2)
library(ggthemes)
options(scipen = 999)  # turns of scientific notations like 1e+40

# Read data
email_campaign_funnel <-
    read.csv(
        "https://raw.githubusercontent.com/selva86/datasets/master/email_campaign_funnel.csv"
    )

# X Axis Breaks and Labels
brks <- seq(-15000000, 15000000, 5000000)
lbls = paste0(as.character(c(seq(15, 0, -5), seq(5, 15, 5))), "m")

# Plot
ggplot(email_campaign_funnel, aes(x = Stage, y = Users, fill = Gender)) +   # Fill column
    geom_bar(stat = "identity", width = .6) +   # draw the bars
    scale_y_continuous(breaks = brks,   # Breaks
                       labels = lbls) + # Labels
    coord_flip() +  # Flip axes
    labs(title = "Email Campaign Funnel") +
    theme_tufte() +  # Tufte theme from ggfortify
    theme(plot.title = element_text(hjust = .5),
          axis.ticks = element_blank()) +   # Centre plot title
    scale_fill_brewer(palette = "Dark2")  # Color palette




var <- mpg$class  # the categorical data
## Prep data (nothing to change here)
nrows <- 10
df <- expand.grid(y = 1:nrows, x = 1:nrows)
categ_table <- round(table(var) * ((nrows * nrows) / (length(var))))
categ_table

df$category <- factor(rep(names(categ_table), categ_table))
# NOTE: if sum(categ_table) is not 100 (i.e. nrows^2), it will need adjustment to make the sum to 100.

## Plot
ggplot(df, aes(x = x, y = y, fill = category)) +
    geom_tile(color = "black", size = 0.5) +
    scale_x_continuous(expand = c(0, 0)) +
    scale_y_continuous(expand = c(0, 0), trans = 'reverse') +
    scale_fill_brewer(palette = "Set3") +
    labs(title = "Waffle Chart",
         subtitle = "'Class' of vehicles",
         caption = "Source: mpg") +
    theme(
        panel.border = element_rect(size = 2),
        plot.title = element_text(size = rel(1.2)),
        axis.text = element_blank(),
        axis.title = element_blank(),
        axis.ticks = element_blank(),
        legend.title = element_blank(),
        legend.position = "right"
    ) +
    theme_dark()



library(ggplot2)
theme_set(theme_classic())

# Source: Frequency table
df <- as.data.frame(table(mpg$class))
colnames(df) <- c("class", "freq")
pie <- ggplot(df, aes(x = "", y = freq, fill = factor(class))) +
    geom_bar(width = 1, stat = "identity") +
    theme(axis.line = element_blank(),
          plot.title = element_text(hjust = 0.5)) +
    labs(
        fill = "class",
        x = NULL,
        y = NULL,
        title = "Pie Chart of class",
        caption = "Source: mpg"
    )

pie + coord_polar(theta = "y", start = 0)

# Source: Categorical variable.
# mpg$class
pie <- ggplot(mpg, aes(x = "", fill = factor(class))) +
    geom_bar(width = 1) +
    theme(axis.line = element_blank(),
          plot.title = element_text(hjust = 0.5)) +
    labs(
        fill = "class",
        x = NULL,
        y = NULL,
        title = "Pie Chart of class",
        caption = "Source: mpg"
    )

pie + coord_polar(theta = "y", start = 0)


# load library
library(ggplot2)
# Create test data.
data <- data.frame(category = c("A", "B", "C"),
                   count = c(10, 60, 30))
# Compute percentages
data$fraction <- data$count / sum(data$count)
# Compute the cumulative percentages (top of each rectangle)
data$ymax <- cumsum(data$fraction)
# Compute the bottom of each rectangle
data$ymin <- c(0, head(data$ymax, n = -1))
# Compute label position
data$labelPosition <- (data$ymax + data$ymin) / 2
# Compute a good label
data$label <- paste0(data$category, "\n value: ", data$count)

# Make the plot
ggplot(data, aes(
    ymax = ymax,
    ymin = ymin,
    xmax = 4,
    xmin = 3,
    fill = category
)) +
    geom_rect() +
    geom_label(x = 3.5,
               aes(y = labelPosition, label = label),
               size = 2) +
    scale_fill_brewer(palette = 4) +
    coord_polar(theta = "y") +
    xlim(c(4, 4)) +
    theme_void() +
    theme(legend.position = "none")



library("ggplot2")
# prep frequency table
freqtable <- table(mpg$manufacturer)
df <- as.data.frame.table(freqtable)
head(df)

theme_set(theme_classic())
# Plot
g <- ggplot(df, aes(Var1, Freq))
g + geom_bar(stat = "identity", width = 0.5, fill = "tomato2") +
    labs(title = "Bar Chart",
         subtitle = "Manufacturer of vehicles",
         caption = "Source: Frequency of Manufacturers from 'mpg' dataset") +
    theme(axis.text.x = element_text(angle = 65, vjust = 0.6))

# From on a categorical column variable
g <- ggplot(mpg, aes(manufacturer))
g + geom_bar(aes(fill = class), width = 0.5) +
    theme(axis.text.x = element_text(angle = 65, vjust = 0.6)) +
    labs(title = "Categorywise Bar Chart",
         subtitle = "Manufacturer of vehicles",
         caption = "Source: Manufacturers from 'mpg' dataset")

## From Timeseries object (ts)
library("ggplot2")
library("ggfortify")
theme_set(theme_classic())

# Plot
autoplot(AirPassengers) +
    labs(title = "AirPassengers") +
    theme(plot.title = element_text(hjust = 0.5))


library("ggplot2")
theme_set(theme_classic())

economics$returns_perc <-
    c(0,
      diff(economics$psavert) / economics$psavert[-length(economics$psavert)])
# Allow Default X Axis Labels
ggplot(economics, aes(x = date)) +
    geom_line(aes(y = returns_perc)) +
    labs(
        title = "Time Series Chart",
        subtitle = "Returns Percentage from 'Economics' Dataset",
        caption = "Source: Economics",
        y = "Returns %"
    )



library("ggplot2")
library("lubridate")
theme_set(theme_bw())

economics_m <- economics[1:24,]

# labels and breaks for X axis text
lbls <-
    paste0(month.abb[month(economics_m$date)],
           " ",
           lubridate::year(economics_m$date))
brks <- economics_m$date

# plot
ggplot(economics_m, aes(x = date)) +
    geom_line(aes(y = returns_perc)) +
    labs(
        title = "Monthly Time Series",
        subtitle = "Returns Percentage from Economics Dataset",
        caption = "Source: Economics",
        y = "Returns %"
    ) +  # title and caption
    scale_x_date(labels = lbls,
                 breaks = brks) +  # change to monthly ticks and labels
    theme(axis.text.x = element_text(angle = 90, vjust = 0.5),
          # rotate x axis text
          panel.grid.minor = element_blank())  # turn off minor grid


library("ggplot2")
library("lubridate")
theme_set(theme_bw())

economics_y <- economics[1:90,]

# labels and breaks for X axis text
brks <- economics_y$date[seq(1, length(economics_y$date), 12)]
lbls <- lubridate::year(brks)

# plot
ggplot(economics_y, aes(x = date)) +
    geom_line(aes(y = returns_perc)) +
    labs(
        title = "Yearly Time Series",
        subtitle = "Returns Percentage from Economics Dataset",
        caption = "Source: Economics",
        y = "Returns %"
    ) +  # title and caption
    scale_x_date(labels = lbls,
                 breaks = brks) +  # change to monthly ticks and labels
    theme(axis.text.x = element_text(angle = 90, vjust = 0.5),
          # rotate x axis text
          panel.grid.minor = element_blank())  # turn off minor grid





library("ggplot2")
library("lubridate")
theme_set(theme_bw())

data(economics_long, package = "ggplot2")
head(economics_long)

df <-
    economics_long[economics_long$variable %in% c("psavert", "uempmed"),]
df <- df[lubridate::year(df$date) %in% c(1967:1981),]

# labels and breaks for X axis text
brks <- df$date[seq(1, length(df$date), 12)]
lbls <- lubridate::year(brks)

# plot
ggplot(df, aes(x = date)) +
    geom_line(aes(y = value, col = variable)) +
    labs(
        title = "Time Series of Returns Percentage",
        subtitle = "Drawn from Long Data format",
        caption = "Source: Economics",
        y = "Returns %",
        color = NULL
    ) +  # title and caption
    scale_x_date(labels = lbls, breaks = brks) +  # change to monthly ticks and labels
    scale_color_manual(
        labels = c("psavert", "uempmed"),
        values = c("psavert" = "#00ba38", "uempmed" = "#f8766d")
    ) +  # line color
    theme(
        axis.text.x = element_text(
            angle = 90,
            vjust = 0.5,
            size = 8
        ),
        # rotate x axis text
        panel.grid.minor = element_blank()
    )  # turn off minor grid




library("ggplot2")
library("lubridate")
theme_set(theme_bw())

df <- economics[, c("date", "psavert", "uempmed")]
df <- df[lubridate::year(df$date) %in% c(1967:1981),]

# labels and breaks for X axis text
brks <- df$date[seq(1, length(df$date), 12)]
lbls <- lubridate::year(brks)

# plot
ggplot(df, aes(x = date)) +
    geom_line(aes(y = psavert, col = "psavert")) +
    geom_line(aes(y = uempmed, col = "uempmed")) +
    labs(
        title = "Time Series of Returns Percentage",
        subtitle = "Drawn From Wide Data format",
        caption = "Source: Economics",
        y = "Returns %"
    ) +  # title and caption
    scale_x_date(labels = lbls, breaks = brks) +  # change to monthly ticks and labels
    scale_color_manual(name = "",
                       values = c("psavert" = "#00ba38", "uempmed" = "#f8766d")) +  # line color
    theme(panel.grid.minor = element_blank())  # turn off minor grid



library("dplyr")
theme_set(theme_classic())
url <- textConnection(RCurl::getURL("https://raw.githubusercontent.com/jkeirstead/r-slopegraph/master/cancer_survival_rates.csv"))
source_df <- read.csv(url)
head(source_df)

# Define functions. Source: https://github.com/jkeirstead/r-slopegraph
tufte_sort <-
    function(df,
             x = "year",
             y = "value",
             group = "group",
             method = "tufte",
             min.space = 0.05) {
        ## First rename the columns for consistency
        ids <- match(c(x, y, group), names(df))
        df <- df[, ids]
        names(df) <- c("x", "y", "group")

        ## Expand grid to ensure every combination has a defined value
        tmp <- expand.grid(x = unique(df$x), group = unique(df$group))
        tmp <- merge(df, tmp, all.y = TRUE)
        df <- dplyr::mutate(tmp, y = ifelse(is.na(y), 0, y))

        ## Cast into a matrix shape and arrange by first column
        require("reshape2")
        tmp <- reshape2::dcast(df, group ~ x, value.var = "y")
        ord <- order(tmp[, 2])
        tmp <- tmp[ord, ]

        min.space <- min.space * diff(range(tmp[, -1]))
        yshift <- numeric(nrow(tmp))
        ## Start at "bottom" row
        ## Repeat for rest of the rows until you hit the top
        for (i in 2:nrow(tmp)) {
            ## Shift subsequent row up by equal space so gap between
            ## two entries is >= minimum
            mat <- as.matrix(tmp[(i - 1):i, -1])
            d.min <- min(diff(mat))
            yshift[i] <- ifelse(d.min < min.space, min.space - d.min, 0)
        }


        tmp <- cbind(tmp, yshift = cumsum(yshift))

        scale <- 1
        tmp <-
            reshape2::melt(
                tmp,
                id = c("group", "yshift"),
                variable.name = "x",
                value.name = "y"
            )
        ## Store these gaps in a separate variable so that they can be scaled ypos = a*yshift + y

        tmp <- transform(tmp, ypos = y + scale * yshift)
        return(tmp)

    }

plot_slopegraph <- function(df) {
    ylabs <- subset(df, x == head(x, 1))$group
    yvals <- subset(df, x == head(x, 1))$ypos
    fontSize <- 3
    gg <- ggplot(df, aes(x = x, y = ypos)) +
        geom_line(aes(group = group), colour = "grey80") +
        geom_point(colour = "white", size = 8) +
        geom_text(aes(label = y), size = fontSize, family = "American Typewriter") +
        scale_y_continuous(name = "",
                           breaks = yvals,
                           labels = ylabs)
    return(gg)
}

## Prepare data
df <- tufte_sort(
    source_df,
    x = "year",
    y = "value",
    group = "group",
    method = "tufte",
    min.space = 0.05
)

df <- transform(df,
                x = factor(
                    x,
                    levels = c(5, 10, 15, 20),
                    labels = c("5 years", "10 years", "15 years", "20 years")
                ),
                y = round(y))

## Plot
plot_slopegraph(df) + labs(title = "Estimates of % survival rates") +
    theme(
        axis.title = element_blank(),
        axis.ticks = element_blank(),
        plot.title = element_text(
            hjust = 0.5,
            family = "American Typewriter",
            face = "bold"
        ),
        axis.text = element_text(family = "American Typewriter",
                                 face = "bold")
    )



library("ggplot2")
library("forecast")
theme_set(theme_classic())

# Subset data for a smaller timewindow
nottem_small <- window(nottem,
                       start = c(1920, 1),
                       end = c(1925, 12))

# Plot
ggseasonplot(AirPassengers) +
    labs(title = "Seasonal plot: International Airline Passengers")
ggseasonplot(nottem_small) +
    labs(title = "Seasonal plot: Air temperatures at Nottingham Castle")
