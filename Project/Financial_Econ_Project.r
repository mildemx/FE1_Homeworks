library(xts)
library(forecast) 
library(rugarch)
library(lmtest)
library(sandwich)

options(repr.plot.width = 12, repr.plot.height = 7)

#library(zoo) ####### not used
#library(ggplot2) ###### not used
#library(fGarch) ###########delete
#library(tseries) ###### not used

#Loading data
load("data_project/12.RData")

dates <- as.Date(index(adp))
df <- data.frame(date = dates, coredata(adp)) #xts to df for regressions
n <- nrow(df)

str(df)
head(df, 3)
tail(df, 1)
colSums(is.na(df))

vars <- c("ret", "RV", "RV_p", "RV_n", "RS", "RK")

#Functions for sample skewness and excess kurtosis
skew <- function(x) {
  n <- length(x)
  x_bar <- mean(x)
  s <- sd(x)
  
  n / ((n - 1) * (n - 2)) * sum(((x - x_bar) / s)^3) #bias corrected skew
}

kurt <- function(x) {
  n <- length(x)
  x_bar <- mean(x)
  s <- sd(x)
  
  term1 <- (n * (n + 1)) / ((n - 1) * (n - 2) * (n - 3)) #bias correction factor
  term2 <- 3 * (n - 1)^2 / ((n - 2) * (n - 3)) #bias corrected version of -3
  
  term1 * sum(((x - x_bar) / s)^4) - term2 #excess kurtosis
}

desc <- data.frame(
  variable = vars,
  min = sapply(vars, function(v) min(df[[v]])),
  mean = sapply(vars, function(v) mean(df[[v]])),
  median = sapply(vars, function(v) median(df[[v]])),
  max = sapply(vars, function(v) max(df[[v]])),
  sd = sapply(vars, function(v) sd(df[[v]])),
  skewness = sapply(vars, function(v) skew(df[[v]])),
  ex_kurt = sapply(vars, function(v) kurt(df[[v]])),
  n = sapply(vars, function(v) sum(!is.na(df[[v]])))
)
round(desc[, -1], 5)

par(mfrow = c(3, 2), mar = c(3, 4, 2, 1))
for (v in vars) {
  plot(df$date, df[[v]], type = "l", main = v, xlab = "", ylab = v)
  grid()
}

df[which.max(df$RK), ]

par(mfrow = c(3, 2), mar = c(3, 4, 3, 1))
for (v in vars) {
  acf(df[[v]], lag.max = 100, main = paste(v))
}

options(repr.plot.height = 8, repr.plot.width = 15)
par(mfrow = c(3, 2))

for (v in vars) {
  hist(df[[v]], breaks = 50, main = v, xlab = v, freq = FALSE)
  lines(density(df[[v]]), col = "red")
  curve(dnorm(x, mean = mean(df[[v]]), sd = sd(df[[v]])),
    add = TRUE, col = "blue")
}

legend("topright", legend = c("KDE", "Normal"),
  col = c("red", "blue"), lty = 1)

#Extracting the variables used in the models
RV <- df$RV
ret <- df$ret
RV_p <- df$RV_p
RV_n <- df$RV_n
RS <- df$RS
RK <- df$RK

#Function for trailing moving averages
ma <- function(x, k) {
  as.numeric(stats::filter(x, rep(1 / k, k), sides = 1))
}

#Weekly & monthly averages
RV_w <- ma(RV, 5)
RV_m <- ma(RV, 22)

RVp_w <- ma(RV_p, 5)
RVp_m <- ma(RV_p, 22)

RVn_w <- ma(RV_n, 5)
RVn_m <- ma(RV_n, 22)

RS_w <- ma(RS, 5)
RS_m <- ma(RS, 22)

RK_w <- ma(RK, 5)
RK_m <- ma(RK, 22)


#Starting from observation 23 because the 22-day average needs enough past data
s <- 23

#Regression ready dataset
model_df <- data.frame(
  date = df$date[s:n],
  RV = RV[s:n],
  
  RV_lag1 = RV[(s - 1):(n - 1)], #RV at t, regressors at t-1
  RV_w = RV_w[(s - 1):(n - 1)],
  RV_m = RV_m[(s - 1):(n - 1)],
  
  RVp_lag1 = RV_p[(s - 1):(n - 1)],
  RVn_lag1 = RV_n[(s - 1):(n - 1)],
  RVp_w = RVp_w[(s - 1):(n - 1)],
  RVn_w = RVn_w[(s - 1):(n - 1)],
  RVp_m = RVp_m[(s - 1):(n - 1)],
  RVn_m = RVn_m[(s - 1):(n - 1)],
  
  RS_lag1 = RS[(s - 1):(n - 1)],
  RS_w = RS_w[(s - 1):(n - 1)],
  RS_m = RS_m[(s - 1):(n - 1)],
  
  RK_lag1 = RK[(s - 1):(n - 1)],
  RK_w = RK_w[(s - 1):(n - 1)],
  RK_m = RK_m[(s - 1):(n - 1)],
  
  ret_lag1 = ret[(s - 1):(n - 1)])

model_df <- na.omit(model_df)

nrow(model_df)

m1 <- lm(RV ~ RV_lag1, data = model_df)

summary(m1)

m2 <- lm(RV ~ RV_lag1 + RV_w + RV_m, data = model_df)

summary(m2)

NW2 <- NeweyWest(m2, lag=22)
coeftest(m2, vcov=NW2)


m3 <- lm(RV ~ RVp_lag1 + RVn_lag1 + RVp_w + RVn_w + RVp_m + RVn_m, data = model_df)

summary(m3)

NW3 <- NeweyWest(m3, lag=22)
coeftest(m3, vcov=NW3)

m4 <- lm(RV ~ RVp_lag1 + RVn_lag1 + RVp_w + RVn_w + RVp_m + RVn_m +
           RS_lag1 + RS_w + RS_m +
           RK_lag1 + RK_w + RK_m, data = model_df)

summary(m4)

NW4 <- NeweyWest(m4, lag=22)
coeftest(m4, vcov=NW4)

#Fitting GARCH(1,1) on returns, same sample as HAR models
#ret_model <- df$ret[s:n][1:nrow(model_df)]
#garch11 <- garchFit(~ garch(1,1), data = ret_model, trace = FALSE)
#summary(garch11)

#Measurement equation

#h_t <- garch11@h.t
#m5_meas <- lm(model_df$RV ~ h_t)
#summary(m5_meas)

#m6 <- garchFit(~ arma(1,1) + garch(1,1), data = ret_model,
               #trace = FALSE)
#summary(m6)

#Measurement equation: map ARMA-GARCH h_t to RV scale

#m6_h <- m6@h.t
#m6_meas <- lm(model_df$RV ~ m6_h)
#summary(m6_meas)

real_garch_spec <- ugarchspec(variance.model = list(model = 'realGARCH', garchOrder = c(1, 1)),
    mean.model = list(armaOrder = c(0, 0), include.mean = TRUE)
)

m5 <- ugarchfit(
    real_garch_spec, 
    data = xts(df$ret, order.by = df$date), #original df as rugarch will handle lagging internally
    solver = 'hybrid',
    realizedVol = xts(df$RV, order.by = df$date)
)
m5

arma_garch_spec <- ugarchspec(
    variance.mode = list(model='sGARCH', garchOrder = c(1, 1)),
    mean.model = list(armaOrder = c(1, 1), include.mean = TRUE)
)
m6 <- ugarchfit(arma_garch_spec, data = df$ret, solver = 'hybrid')
m6

#MSE, MAE comparison

#need to ensure GARCH and HAR family fitted values are matching
n_drop <- nrow(df) - nrow(model_df) # = 22

fits <- cbind( #in-sample
    sapply(list(m1, m2, m3, m4), fitted),
    as.numeric(sigma(m5)[(n_drop + 1):nrow(df)]), #drop first 22 obs to match model_df
    as.numeric(sigma(m6)[(n_drop + 1):nrow(df)])
)
colnames(fits) <- c("AR(1)-RV", "HAR-RV", "HAR-RS", "HAR-Rskew-Rkurt", "Realized GARCH", "ARMA-GARCH")

actual <- model_df$RV 

comp <- data.frame(
    MSE = colMeans((actual - fits)^2),
    MAE = colMeans(abs(actual - fits)),
    Adj_R2 = c(sapply(list(m1, m2, m3, m4), function(m) summary(m)$adj.r.squared), NA, NA)
)
comp

options(repr.plot.height = 12, repr.plot.width = 18)
par(mfrow = c(3, 2))

for (i in seq_along(colnames(fits))) {
  plot(model_df$date, actual, type = "l", col = "grey",
       main = colnames(fits)[i], xlab = "", ylab = "RV")
  lines(model_df$date, fits[, i], col = "red")
  legend("topright", c("Actual", "Fitted"), col = c("grey", "red"), lty = 1, cex = 0.7)
}

options(repr.plot.height = 10, repr.plot.width = 18)
colors <- c("black", "blue", "green", "purple", "red", "orange")

plot(model_df$date, actual, type="l", col="grey", lwd=2,
    main="In-Sample Fits: All models vs Actual RV",
    xlab="", ylab="RV"
)

for (i in 1:ncol(fits)){
    lines(model_df$date, fits[, i], col=colors[i], lwd=1)
}

legend("topleft", legend=c("Actual", colnames(fits)),
    col=c("grey", colors),
    lwd=c(2), cex=0.65
)
