setwd("/Users/zp/Desktop/Financial_Econ") #set your own wd

library("ggplot2") #plotting
library("moments") #for skew and kurtosis
library("stabledist") #for stable dist curve
library("fBasics") #for stable dist param estimation

base_path <- getwd()
print(base_path)

all_files <- c(list.files(file.path(base_path, "73267075"), full.names=TRUE),
               list.files(file.path(base_path, "54520099"), full.names=TRUE)
)

price_list_raw <- lapply(all_files, read.csv)
names(price_list_raw) <- tools::file_path_sans_ext(basename(all_files)) #get the names of all stocks
names(price_list_raw)

head(price_list_raw[["BIO"]]) #check the structure of the data


sapply(price_list_raw, colnames) #check if column names are same format
colnames(price_list_raw[["PHM"]])[2] <- "Close" #correct PHM Close column


price_list <- lapply(price_list_raw, function(df) df[, c("Date", "Close")])
sapply(price_list, colnames)

str(price_list[["BIO"]]) #check for disparities
str(price_list[["CAH"]]) #need to reformat the column types

price_list <- lapply(price_list, function(df) {
    df$Date <- as.Date(df$Date)
    df$Close <- as.numeric(df$Close)
    return(df)
})

sapply(price_list, function(df) sum(is.na(df$Close)))

price_list <- lapply(price_list, function(df) na.omit(df)) #remove NAs
sapply(price_list, function(df) sum(is.na(df$Close)))

sapply(price_list, function(df) sum(duplicated(df$Date))) #check for date duplicates

rets_list <- lapply(price_list, function(df){
    data.frame(
        Date = df$Date[-1], #remove 1st date as we don't have return for it
        rets = diff(log(df$Close)),
        rets_simple = diff(df$Close)/df$Close[-nrow(df)]
    )
})

head(rets_list[["BIO"]])

#combine the returns into a long data frame for ggplot2
rets_long <- do.call(rbind, lapply(names(rets_list), function(name) {
    data.frame(
        Date=rets_list[[name]]$Date,
        rets=rets_list[[name]]$rets,
        ticker=name
    )
}))

options(repr.plot.width=15, repr.plot.height=10)
ggplot(rets_long, aes(x=Date, y=rets, color=ticker)) +
    geom_line() + 
    facet_wrap(~ticker, scales="free_y") +
    labs(title="Log Returns", x="Date", y="Return")

desc_stat <- do.call(rbind, lapply(names(rets_list), function(name){
    r <- rets_list[[name]]$rets
    data.frame(
        ticker = name,
        mean = mean(r),
        sd = sd(r),
        min = min(r),
        max = max(r),
        skew = skewness(r),
        kurt = kurtosis(r)
    )
}))

format(desc_stat, digits=2)

options(repr.plot.width=10, repr.plot.height=8)
par(mfrow=c(2,1))

plot(price_list[["CVX"]]$Date, price_list[["CVX"]]$Close, 
    type='l', main="CVX price chart", xlab="Date", ylab="Price"
)

plot(rets_list[["CVX"]]$Date, rets_list[["CVX"]]$rets, 
    type='l', main="Log returns", xlab="Date", ylab="Return"
)

rets_list[["CVX"]][abs(rets_list[["CVX"]]$rets) > 0.5, ] #to get the exact dates of the outlier dates

rets_list[["CVX"]] <- rets_list[["CVX"]][abs(rets_list[["CVX"]]$rets) < 0.5, ] #keep only ret < 50% in magnitude

options(repr.plot.width=10, repr.plot.height=6)
plot(rets_list[["CVX"]]$Date, rets_list[["CVX"]]$rets, 
    type='l', main="Log returns", xlab="Date", ylab="Return"
)

CVX <- rets_list[["CVX"]]$rets
cat("Mean:", mean(CVX), 
    "\nSD:", sd(CVX), 
    "\nMin:", min(CVX), 
    "\nMax:", max(CVX), 
    "\nSkewness:", skewness(CVX), 
    "\nKurtosis:", kurtosis(CVX)
)

FE <- rets_list[["FE"]]$rets #plotting log returns - more likely to be normal than simple returns

pdf(NULL) #because stableFit produces an unnecessary graph
stable_param <- stableFit(FE, type="q") #fit the stable distrib (get the parameters)
dev.off()

print(stable_param@fit$estimate)
hist(FE, breaks=100, freq=FALSE, main="FE Log Returns", xlab="Return")

curve(dnorm(x, mean=mean(FE), sd=sd(FE)), add=TRUE, col="blue", lwd=2) #normal distrib 

curve(dstable(x,alpha=stable_param@fit$estimate[1], #stable distrib
                beta=stable_param@fit$estimate[2],
                gamma=stable_param@fit$estimate[3],
                delta=stable_param@fit$estimate[4]),
    add=TRUE, col="red", lwd=2
)

legend("topright", legend=c("Normal", "Stable"), col=c("blue", "red"), lwd=2)

hist(FE, breaks=100, freq=FALSE, main="FE Log Returns", xlab="Return", xlim=c(-0.25, -0), ylim=c(0, 30))
curve(dnorm(x, mean=mean(FE), sd=sd(FE)), add=TRUE, col="blue", lwd=0.5)
legend("topleft", legend="Normal", col="blue", lwd=1)

#Checking dates & observations for each stock before combining them 
date_summary <- data.frame( 
    ticker = names(rets_list),
    observations = sapply(rets_list, nrow),
    start_date = as.Date(sapply(rets_list, function(df) min(df$Date))),
    end_date = as.Date(sapply(rets_list, function(df) max(df$Date))) #creating a dataframe with all the stocks 
)
                          
date_summary

#Keeping only time periods with returns that are present for all tickers
stock_list <- lapply(names(rets_list), function(ticker_name) {
  stock_data <- rets_list[[ticker_name]][, c("Date", "rets")]
  colnames(stock_data)[2] <- ticker_name
  stock_data}
)

aligned_rets <- Reduce(function(left, right) merge(left, right, by = "Date"), stock_list)
aligned_rets <- aligned_rets[order(aligned_rets$Date), ]

#Checking the overall state of combined dataset
portfolio_summary <- data.frame(
  trading_days = nrow(aligned_rets),
  number_of_series = ncol(aligned_rets) - 1,
  first_date = as.character(min(aligned_rets$Date)),
  last_date = as.character(max(aligned_rets$Date))
)
                       
portfolio_summary

#Seeing the amount rows we lost after aligning dates
obs_lost <- sapply(names(rets_list),function(name) {
    nrow(rets_list[[name]]) - nrow(aligned_rets)}
                  )

sort(obs_lost, decreasing = TRUE)

tickers <- setdiff(colnames(aligned_rets), "Date")

#Computing cross-sectional mean log return
aligned_rets$mean_ret <- rowMeans(aligned_rets[, tickers])

#A summary of mean return series results
mean_stats <- data.frame(
    mean = mean(aligned_rets$mean_ret),
    sd = sd(aligned_rets$mean_ret),
    min = min(aligned_rets$mean_ret),
    q1 = quantile(aligned_rets$mean_ret, 0.25),
    median = median(aligned_rets$mean_ret),
    q3 = quantile(aligned_rets$mean_ret, 0.75),
    max = max(aligned_rets$mean_ret),
    skewness = skewness(aligned_rets$mean_ret),
    kurtosis = kurtosis(aligned_rets$mean_ret)
)

mean_stats

plot(aligned_rets$Date, aligned_rets$mean_ret, type="l", ylab="Log Mean Returns", xlab="Date")

#Stable distribution fitted to cross-sectional mean returns
mean_rets <- aligned_rets$mean_ret

pdf(NULL)  #suppress the plot stableFit generates
stable_mean <- stableFit(mean_rets, type = "q")
dev.off()

#Comparing with the FE fit from Part 1
comparison <- data.frame(
    parameter = c("alpha", 
                  "beta", 
                  "gamma", 
                  "delta"),
    FE = stable_param@fit$estimate,
    mean_returns = stable_mean@fit$estimate
)

comparison

#Plotting histogram of the mean returns
options(repr.plot.width = 10, repr.plot.height = 7)

stable_parameters <- stable_mean@fit$estimate
alpha_value <- stable_parameters[1]
beta_value  <- stable_parameters[2]
gamma_value <- stable_parameters[3]
delta_value <- stable_parameters[4]

hist(mean_rets,
     breaks = 80,
     freq = FALSE,
     main = "Cross-Sectional Mean Log Returns",
     xlab = "Return",
     col = "grey",
     border = "white")

#Comparing normal vs stable fit
curve(dnorm(x, mean = mean(mean_rets), sd = sd(mean_rets)),
      add = TRUE, col = "blue", lwd = 2)

curve(dstable(x,
              alpha = alpha_value,
              beta = beta_value,
              gamma = gamma_value,
              delta = delta_value),
      add = TRUE, col = "red", lwd = 2)

legend("topright",
       legend = c("Normal distribution", "Stable distribution"),
       col = c("blue", "red"),
       lwd = 2)

#Recalculate descriptive statistics for each stock
stock_stats <- do.call(rbind, lapply(names(rets_list), function(ticker_name) {
  returns <- rets_list[[ticker_name]]$rets

  data.frame(
    ticker = ticker_name,
    mean = mean(returns),
    sd = sd(returns),
    min = min(returns),
    max = max(returns),
    skew = skewness(returns),
    kurt = kurtosis(returns))}
))


cs_row <- data.frame(
  ticker = "CS_MEAN",
  mean = mean(mean_rets),
  sd = sd(mean_rets),
  min = min(mean_rets),
  max = max(mean_rets),
  skew = skewness(mean_rets),
  kurt = kurtosis(mean_rets)
)

comparison <- rbind(stock_stats, cs_row)
format(comparison, digits = 4)

#Setting values for simulation 

set.seed(123)

simulations <- 500
series_l <- nrow(aligned_rets)

low_sigma <- 0.01
high_sigma <- 0.15

#Simulating random walks without drift
low_noise <- matrix(rnorm(series_l * simulations, sd = low_sigma), nrow = series_l)
high_noise <- matrix(rnorm(series_l * simulations, sd = high_sigma), nrow = series_l)

rw_low <- apply(low_noise, 2, cumsum)
rw_high <- apply(high_noise, 2, cumsum)

plot_random_walks <- function(random_walks, sigma_value, line_color) {

  time_index <- 1:nrow(random_walks)

  q_25 <- apply(random_walks, 1, quantile, probs = 0.25)
  q_50 <- apply(random_walks, 1, median)
  q_75 <- apply(random_walks, 1, quantile, probs = 0.75)

  upper_bound <- 2 * sigma_value * sqrt(time_index)
  lower_bound <- -2 * sigma_value * sqrt(time_index)

  plot(NULL,
       xlim = c(1, length(time_index)),
       ylim = range(random_walks),
       xlab = "Time",
       ylab = expression(X[t]),
       main = paste("Random Walk without Drift, sigma =", sigma_value))

  chosen_paths <- sample(1:ncol(random_walks), 100)
  for (j in chosen_paths) {
    lines(time_index, random_walks[, j],
          col = adjustcolor(line_color, alpha.f = 0.15), lwd = 0.5)}

  polygon(c(time_index, rev(time_index)),
          c(q_25, rev(q_75)),
          col = adjustcolor(line_color, alpha.f = 0.3),
          border = NA)

  lines(time_index, q_50, col = line_color, lwd = 2)
  lines(time_index, upper_bound, col = "black", lty = 2)
  lines(time_index, lower_bound, col = "black", lty = 2)

  legend("topleft",
         legend = c("Sample paths", "Middle 50%", "Median", "Theoretical bounds"),
         col = c(adjustcolor(line_color, alpha.f = 0.3),
                 adjustcolor(line_color, alpha.f = 0.3),
                 line_color,
                 "black"),
         lwd = c(1, 8, 2, 1),
         lty = c(1, 1, 1, 2),
         bty = "n")}

#Low-volatility case
options(repr.plot.width = 9, repr.plot.height = 6)
plot_random_walks(rw_low, 0.5, "blue")

#High-volatility case
plot_random_walks(rw_high, 2, "red")
