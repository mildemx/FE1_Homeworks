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
    variance.model = list(model='sGARCH', garchOrder = c(1, 1)),
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

w_l <- 750 #window len
n_for <- nrow(model_df) - w_l #forecast period

forecast_dates <- model_df$date[(w_l + 1):(nrow(model_df))] #vector of dates
actual_oos <- model_df$RV[(w_l + 1):nrow(model_df)]

#n_for
#length(forecast_dates)
#length(actual_oos)

#Expanding window
#HAR family 
m1_exp <- sapply(1:n_for, function(x){
    fit <- lm(RV ~ RV_lag1, data = model_df[1:(w_l + x - 1), ]) 
    predict(fit, newdata = model_df[w_l + x, ])
})

m2_exp <- sapply(1:n_for, function(x){
    fit <- lm(RV ~ RV_lag1 + RV_w + RV_m, data = model_df[1:(w_l + x - 1), ])
    predict(fit, newdata = model_df[w_l + x, ])
})

m3_exp <- sapply(1:n_for, function(x){
    fit <- lm(RV ~ RVp_lag1 + RVn_lag1 + RVp_w + RVn_w + RVp_m + RVn_m, data = model_df[1:(w_l + x - 1), ])
    predict(fit, newdata = model_df[w_l + x, ])
})

m4_exp <- sapply(1:n_for, function(x){
    fit <- lm(
        RV ~ RVp_lag1 + RVn_lag1 + RVp_w + RVn_w + RVp_m + 
        RVn_m + RS_lag1 + RS_w + RS_m + RK_lag1 + RK_w + RK_m, 
        data = model_df[1:(w_l + x - 1), ])
    predict(fit, newdata = model_df[w_l + x, ])
})

#GARCH family
m5_exp <- ugarchroll(real_garch_spec,
    data = xts(100 * df$ret, order.by = df$date), #scale for convergence
    n.ahead = 1,
    forecast.length = n_for,
    refit.window = 'recursive',
    window.size = w_l,
    solver = 'hybrid',
    refit.every = 1,
    realizedVol = xts(100 * df$RV, order.by = df$date)
)

m6_exp <- ugarchroll(arma_garch_spec,
    data = xts(df$ret, order.by = df$date),
    n.ahead = 1,
    forecast.length = n_for,
    refit.window = 'recursive',
    window.size = w_l,
    solver = 'hybrid',
    refit.every = 1
)

#Rolling window
#HAR family 
m1_roll <- sapply(1:n_for, function(x){
    fit <- lm(RV ~ RV_lag1, data = model_df[x:(w_l + x - 1), ]) 
    predict(fit, newdata = model_df[w_l + x, ])
})

m2_roll <- sapply(1:n_for, function(x){
    fit <- lm(RV ~ RV_lag1 + RV_w + RV_m, data = model_df[x:(w_l + x - 1), ])
    predict(fit, newdata = model_df[w_l + x, ])
})

m3_roll <- sapply(1:n_for, function(x){
    fit <- lm(RV ~ RVp_lag1 + RVn_lag1 + RVp_w + RVn_w + RVp_m + RVn_m, data = model_df[x:(w_l + x - 1), ])
    predict(fit, newdata = model_df[w_l + x, ])
})

m4_roll <- sapply(1:n_for, function(x){
    fit <- lm(
        RV ~ RVp_lag1 + RVn_lag1 + RVp_w + RVn_w + RVp_m + 
        RVn_m + RS_lag1 + RS_w + RS_m + RK_lag1 + RK_w + RK_m, 
        data = model_df[x:(w_l + x - 1), ])
    predict(fit, newdata = model_df[w_l + x, ])
})

m6_roll <- ugarchroll(arma_garch_spec,
    data = xts(df$ret, order.by = df$date),
    n.ahead = 1,
    forecast.length = n_for,
    refit.window = 'moving',
    window.size = w_l,
    solver = 'hybrid',
    refit.every = 1
)

# Realized GARCH (manual function) - rugarch does not work (fails to converge)
#Fit all windows and store results
m5_roll_fits <- lapply(1:n_for, function(x) {
    tryCatch(
        ugarchfit(real_garch_spec,
            data = xts(1000 * df$ret, order.by = df$date)[(22 + x):(21 + x + w_l)], #offset by 22 to match model_df (using df since ugarchfit needs xts)
            solver = 'hybrid',
            realizedVol = xts(1000 * df$RV, order.by = df$date)[(22 + x):(21 + x + w_l)]
        ),
        error = function(e) NULL
    )
})

#Forecast Realized GARCH
m5_roll_forecast <- sapply(1:n_for, function(x) {
    if(is.null(m5_roll_fits[[x]])) return(NA)
    as.numeric(ugarchforecast(m5_roll_fits[[x]], n.ahead = 1)@forecast$sigmaFor) / 1000
})

length(m5_roll_forecast)

#Get GARCH forecasts 
m5_exp_forecast <- m5_exp@forecast$density$Sigma / 100 #re-scale back
m6_exp_forecast <- m6_exp@forecast$density$Sigma

#m5_roll_forecast excracted from manual func
m6_roll_forecast <- m6_roll@forecast$density$Sigma

#Put forecasts into matrices
forecasts_exp <- cbind(m1_exp, m2_exp, m3_exp, m4_exp, m5_exp_forecast, m6_exp_forecast)
forecasts_roll <- cbind(m1_roll, m2_roll, m3_roll, m4_roll, m5_roll_forecast, m6_roll_forecast)

colnames(forecasts_exp) <- colnames(forecasts_roll) <- c("AR", "HAR", "HAR-RS", "HAR-RS-RK", "RealGARCH", "ARMA-GARCH")

##Actual vs forecast RV
options(repr.plot.height = 13, repr.plot.width = 24)
par(mfrow = c(2, 2))
y_lim <- range(c(actual_oos, forecasts_exp, forecasts_roll))

#Expanding window
plot(forecast_dates, actual_oos, type = "l", col = "darkgrey", lwd = 1.5,
    main = "Expanding Window: Forecasts vs Actual RV",
    xlab = "", ylab = "RV", ylim = y_lim,
    panel.first = grid()
)

for (i in 1:6) lines(forecast_dates, forecasts_exp[, i], col = i + 1, lty = 1)
legend("topright", legend = c("Actual", colnames(forecasts_exp)),
    col = c("darkgrey", 2:7), lty = 1, cex = 0.6
)

#Rolling window
plot(forecast_dates, actual_oos, type = "l", col = "darkgrey", lwd = 1.5,
    main = "Rolling Window: Forecasts vs Actual RV",
    xlab = "", ylab = "RV", ylim = y_lim,
    panel.first = grid()
)

for (i in 1:6) lines(forecast_dates, forecasts_roll[, i], col = i + 1, lty = 1)
legend("topright", legend = c("Actual", colnames(forecasts_roll)),
    col = c("darkgrey", 2:7), lty = 1, cex=0.6, 
)


##Errors plot
errors_exp <- forecasts_exp - actual_oos
errors_roll <- forecasts_roll - actual_oos

#Expanding window
plot(forecast_dates, errors_exp[, 1], type = "l", col = "darkgrey",
    main = "Expanding Window: Forecast Errors",
    xlab = "", ylab = "Error", ylim = range(errors_exp, errors_roll),
    panel.first = grid())
for (i in 2:6) lines(forecast_dates, errors_exp[, i], col = i + 1)
legend("topright", legend = colnames(forecasts_exp), col = 2:7, lty = 1, cex = 0.6)

#Rolling window
plot(forecast_dates, errors_roll[, 1], type = "l", col = "darkgrey",
    main = "Rolling Window: Forecast Errors",
    xlab = "", ylab = "Error", ylim = range(errors_exp, errors_roll),
    panel.first = grid())
for (i in 2:6) lines(forecast_dates, errors_roll[, i], col = i + 1)
legend("topright", legend = colnames(forecasts_roll), col = 2:7, lty = 1, cex = 0.6)

which(m5_roll_forecast > 0.05)
model_df$date[w_l + which(m5_roll_forecast > 0.05)]

#MSE and MAE
mse <- function(actual, forecast) mean((actual - forecast)^2)
mae <- function(actual, forecast) mean(abs(actual - forecast))

#Loss matrices
loss_exp <- apply(forecasts_exp, 2, function(f) c(MSE = mse(actual_oos, f), MAE = mae(actual_oos, f)))
loss_roll <- apply(forecasts_roll, 2, function(f) c(MSE = mse(actual_oos, f), MAE = mae(actual_oos, f)))

loss_table <- data.frame(
    Scheme = rep(c("Expanding", "Rolling"), each = 6),
    Model = rep(colnames(forecasts_exp), 2),
    MSE = c(loss_exp["MSE", ], loss_roll["MSE", ]),
    MAE = c(loss_exp["MAE", ], loss_roll["MAE", ])
) 
loss_table

##Loss vectors and p-values
#MSE loss vectors
mse_loss_exp <- apply(forecasts_exp, 2, function(f) (f - actual_oos)^2)
mse_loss_roll <- apply(forecasts_roll, 2, function(f) (f - actual_oos)^2)

pairs <- combn(1:6, 2) #all possible combinations

#Expanding window DM test
dm_pval_exp <- apply(pairs, 2, function(p) #vector of 15 p-vals
    dm.test(mse_loss_exp[, p[1]], mse_loss_exp[, p[2]],
        alternative = "two.sided")$p.value #test both directions
)

#Rolling window
dm_pval_roll <- apply(pairs, 2, function(p)
    dm.test(mse_loss_roll[, p[1]], mse_loss_roll[, p[2]],
        alternative = "two.sided")$p.value
)

##Organize results into a matrix
#empty matrices
models <- colnames(forecasts_exp)
dm_matrix_exp <- matrix("", 6, 6, dimnames = list(models, models)) #rows = model 1, cols = model 2
dm_matrix_roll <- matrix("", 6, 6, dimnames = list(models, models))

#assign to upper triangle
for (k in 1:ncol(pairs)) {
    dm_matrix_exp[pairs[1, k], pairs[2, k]] <- round(dm_pval_exp[k], 3)
    dm_matrix_roll[pairs[1, k], pairs[2,k]] <- round(dm_pval_roll[k], 3)
}

dm_matrix_exp
dm_matrix_roll

##MZ regressions
mz_exp <- lapply(1:6, function(i) lm(actual_oos ~ forecasts_exp[, i]))
names(mz_exp) <- colnames(forecasts_exp)

mz_roll <- lapply(1:6, function(i) lm(actual_oos ~ forecasts_roll[, i]))
names(mz_roll) <- colnames(forecasts_roll)

#summary table
mz_table <- function(mz_list){
    do.call(rbind, lapply(names(mz_list), function(m){
        coef <- summary(mz_list[[m]])$coefficients
        data.frame(
            Model = m,
            Alpha = round(coef[1, "Estimate"], 4),
            t_alpha0 = round(coef[1, "t value"], 2),
            Beta = round(coef[2, "Estimate"], 3),
            t_beta1 = round((coef[2, "Estimate"] - 1) / coef[2, "Std. Error"], 2), #we want to test against 1, not 0
            R2 = round(summary(mz_list[[m]])$r.squared, 3)
        )
    }))
}

mz_table(mz_exp)
mz_table(mz_roll)
