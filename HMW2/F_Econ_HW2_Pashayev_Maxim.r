library(repr)
library(tseries)
library(forecast)
library(stats)
library(FinTS)
library(rugarch)
library(lmtest)

seriesA <- read.csv("73267075/series_A.csv")
seriesB <- read.csv("73267075/series_B.csv")
seriesC <- read.csv("73267075/series_C.csv")

cat("Series A - Dimensions:", dim(seriesA), "\n"); head(seriesA)
cat("Series B - Dimensions:", dim(seriesB), "\n"); head(seriesB)
cat("Series C - Dimensions:", dim(seriesC), "\n"); head(seriesC)

options(repr.plot.height=10, repr.plot.width=12)
par(mfrow=c(3, 2))
ts.plot(seriesA$ret, col="blue", ylab="Return", main="Series A")
ts.plot(seriesA$ret^2, col="blue", ylab="Squared Return", main="Series A")

ts.plot(seriesB$ret, col="red", ylab="Return", main="Series B")
ts.plot(seriesB$ret^2, col="red", ylab="Squared Return", main="Series B")

ts.plot(seriesC$ret, col="purple", ylab="Return", main="Series C")
ts.plot(seriesC$ret^2, col="purple", ylab="Squared Return", main="Series C")

#note the difference in scale of the y-axis across series

par(mfrow=c(3,2))
Acf(seriesA$ret, main="ACF Series A")
Pacf(seriesA$ret, main="PACF Series A")
Acf(seriesB$ret, main="ACF Series B")
Pacf(seriesB$ret, main="PACF Series B")
Acf(seriesC$ret, main="ACF Series C")
Pacf(seriesC$ret, main="PACF Series C")

a_arma01 <- Arima(seriesA$ret, order=c(0,0,1))
summary(a_arma01)

options(repr.plot.height=4, repr.plot.width=10)
par(mfrow=c(1,2))
acf(a_arma01$residuals)
pacf(a_arma01$residuals)

Box.test(a_arma01$residuals, type="Ljung-Box", lag=4)
Box.test(a_arma01$residuals, type="Ljung-Box", lag=8)
Box.test(a_arma01$residuals, type="Ljung-Box", lag=12)

a_arma00 <- Arima(seriesA$ret, order=c(0,0,0))
summary(a_arma00)

par(mfrow=c(1,2))
acf(a_arma00$residuals)
pacf(a_arma00$residuals)

Box.test(a_arma00$residuals, type="Ljung-Box", lag=4)
Box.test(a_arma00$residuals, type="Ljung-Box", lag=8)
Box.test(a_arma00$residuals, type="Ljung-Box", lag=12)

a_arma11 <- Arima(seriesA$ret, order=c(1,0,1))
summary(a_arma11)

par(mfrow=c(1,2))
acf(a_arma11$residuals)
pacf(a_arma11$residuals)

Box.test(a_arma11$residuals, type="Ljung-Box", lag=4)
Box.test(a_arma11$residuals, type="Ljung-Box", lag=8)
Box.test(a_arma11$residuals, type="Ljung-Box", lag=12)

a_arma10 <- Arima(seriesA$ret, order=c(1,0,0))
summary(a_arma10)

par(mfrow=c(1,2))
acf(a_arma10$residuals)
pacf(a_arma10$residuals)

Box.test(a_arma10$residuals, type="Ljung-Box", lag=4)
Box.test(a_arma10$residuals, type="Ljung-Box", lag=8)
Box.test(a_arma10$residuals, type="Ljung-Box", lag=12)

b_arma72 <- Arima(seriesB$ret, order=c(7,0,2))
summary(b_arma72)

par(mfrow=c(1,2))
acf(b_arma72$residuals)
pacf(b_arma72$residuals)

Box.test(b_arma72$residuals, type="Ljung-Box", lag=4)
Box.test(b_arma72$residuals, type="Ljung-Box", lag=8)
Box.test(b_arma72$residuals, type="Ljung-Box", lag=12)
Box.test(b_arma72$residuals, type="Ljung-Box", lag=35)

b_arma_bigAR <- Arima(seriesB$ret, order=c(15,0,1))
summary(b_arma_bigAR)

par(mfrow=c(1,2))
acf(b_arma_bigAR$residuals)
pacf(b_arma_bigAR$residuals)

Box.test(b_arma_bigAR$residuals, type="Ljung-Box", lag=4)
Box.test(b_arma_bigAR$residuals, type="Ljung-Box", lag=8)
Box.test(b_arma_bigAR$residuals, type="Ljung-Box", lag=12)
Box.test(b_arma_bigAR$residuals, type="Ljung-Box", lag=40)

b_arma66 <- Arima(seriesB$ret, order=c(6,0,6))
summary(b_arma66)

par(mfrow=c(1,2))
acf(b_arma66$residuals)
pacf(b_arma66$residuals)

Box.test(b_arma66$residuals, type="Ljung-Box", lag=4)
Box.test(b_arma66$residuals, type="Ljung-Box", lag=8)
Box.test(b_arma66$residuals, type="Ljung-Box", lag=12)
Box.test(b_arma66$residuals, type="Ljung-Box", lag=35)

c_arma21 <- Arima(seriesC$ret, order=c(2,0,1))
summary(c_arma21)

par(mfrow=c(1,2))
acf(c_arma21$residuals)
pacf(c_arma21$residuals)

Box.test(c_arma21$residuals, type="Ljung-Box", lag=4)
Box.test(c_arma21$residuals, type="Ljung-Box", lag=8)
Box.test(c_arma21$residuals, type="Ljung-Box", lag=12)

c_arma40 <- Arima(seriesC$ret, order=c(4,0,0))
summary(c_arma40)

par(mfrow=c(1,2))
acf(c_arma40$residuals)
pacf(c_arma40$residuals)

Box.test(c_arma40$residuals, type="Ljung-Box", lag=4)
Box.test(c_arma40$residuals, type="Ljung-Box", lag=8)
Box.test(c_arma40$residuals, type="Ljung-Box", lag=12)

c_arma04 <- Arima(seriesC$ret, order=c(0,0,4))
summary(c_arma04)

par(mfrow=c(1,2))
acf(c_arma04$residuals)
pacf(c_arma04$residuals)

Box.test(c_arma04$residuals, type="Ljung-Box", lag=4)
Box.test(c_arma04$residuals, type="Ljung-Box", lag=8)
Box.test(c_arma04$residuals, type="Ljung-Box", lag=12)

c_arma44 <- Arima(seriesC$ret, order=c(4,0,4))
summary(c_arma44)

par(mfrow=c(1,2))
acf(c_arma44$residuals)
pacf(c_arma44$residuals)

Box.test(c_arma44$residuals, type="Ljung-Box", lag=4)
Box.test(c_arma44$residuals, type="Ljung-Box", lag=8)
Box.test(c_arma44$residuals, type="Ljung-Box", lag=12)

#Put all ICs into a dataframe to present collectively
ic_A <- data.frame(
    Model = c("ARMA(0,1)", "ARMA(1,0)", "ARMA(1,1)"),
    AIC = c(a_arma01$aic, a_arma10$aic, a_arma11$aic),
    AICc = c(a_arma01$aicc, a_arma10$aicc, a_arma11$aicc),
    BIC = c(a_arma01$bic, a_arma10$bic, a_arma11$bic)
)

ic_B <- data.frame(
    Model = c("ARMA(7,2)", "ARMA(15,1)", "ARMA(6,6)"),
    AIC = c(b_arma72$aic, b_arma_bigAR$aic, b_arma66$aic),
    AICc = c(b_arma72$aicc, b_arma_bigAR$aicc, b_arma66$aicc),
    BIC = c(b_arma72$bic, b_arma_bigAR$bic, b_arma66$bic)
)

ic_C <- data.frame(
    Model = c("ARMA(4,0)", "ARMA(0,4)", "ARMA(4,4)"),
    AIC = c(c_arma40$aic, c_arma04$aic, c_arma44$aic),
    AICc = c(c_arma40$aicc, c_arma04$aicc, c_arma44$aicc),
    BIC = c(c_arma40$bic, c_arma04$bic, c_arma44$bic)
)

ic_all <- rbind(
    cbind(Series="A", ic_A),
    cbind(Series="B", ic_B),
    cbind(Series="C", ic_C)
)
ic_all

options(repr.plot.height=8, repr.plot.width=8)
par(mfrow=c(3,1))
acf(a_arma10$residuals^2)
acf(b_arma66$residuals^2)
acf(c_arma40$residuals^2)

ArchTest(a_arma10$residuals) #conditional heteroscedasticity test
ArchTest(b_arma66$residuals)
ArchTest(c_arma40$residuals)

#Series A: Box-Jenkins identified a clean AR(1) structure with no signs
#of misspecification, so ARMA(1,0) is carried forward unchanged.
spec_A <- ugarchspec(
  variance.model = list(model = "sGARCH", garchOrder = c(1,1)),
  mean.model = list(armaOrder = c(1,0), include.mean = TRUE),
  distribution.model = "norm"
)

fit_A <- ugarchfit(spec = spec_A, 
                   data = seriesA$ret)

#Series B: the mean equation is revised down to ARMA(1,0).
#Problem 3 showed that the serial dependence left in the squared residuals after ARMA(6,6) is located in the conditional variance, not the mean.
#A parsimonious AR(1) is therefore the appropriate working mean here, leaving GARCH(1,1) to absorb the volatility dynamics.
spec_B <- ugarchspec(variance.model = list(model = "sGARCH", 
                                           garchOrder = c(1,1)),
                     mean.model = list(armaOrder = c(1,0), include.mean = TRUE),
                     distribution.model = "norm"
                    )

fit_B <- ugarchfit(spec = spec_B, 
                   data = seriesB$ret)

#Series C: ARMA(4,0) was previously established in Problem 2 and Problem 3 revealed no indication of ARCH effects; 
#hence, the specification remains unchanged.
spec_C <- ugarchspec(variance.model = list(model = "sGARCH", 
                                           garchOrder = c(1,1)),
                     mean.model = list(armaOrder = c(4,0), include.mean = TRUE),
                     distribution.model = "norm"
                    )

fit_C <- ugarchfit(spec = spec_C, data = seriesC$ret)

#fit_A 
#fit_B
#fit_C #notable beta coeff

garch_params <- function(model_fit, series_name) {
  coefs <- coef(model_fit)
  persistence <- coefs["alpha1"] + coefs["beta1"]

  data.frame(Series = series_name,
             Omega = round(coefs["omega"], 6),
             Alpha1 = round(coefs["alpha1"], 4),
             Beta1 = round(coefs["beta1"], 4),
             Persistence = round(persistence, 4))
}

garch_table <- rbind(garch_params(fit_A, "Series A"),
                     garch_params(fit_B, "Series B"),
                     garch_params(fit_C, "Series C")
                    )

garch_table

print("Series A")
show(fit_A)

print("Series B")
show(fit_B)

print("Series C")
show(fit_C)

options(repr.plot.height = 12, repr.plot.width = 14)
par(mfrow = c(3, 1), mar = c(4, 4, 3, 1))

vol_A <- sigma(fit_A)
vol_B <- sigma(fit_B)
vol_C <- sigma(fit_C)

ylim = range(c(vol_A, vol_B, vol_C)) #for apples-to-apples comparison

plot(vol_A, type = "l",
     main = "Series A: ARMA(1,0)-GARCH(1,1)",
     col = "blue",
     xlab = "Time",
     ylim = ylim, 
     ylab = expression(hat(sigma)[t]))


plot(vol_B, type = "l",
     main = "Series B: ARMA(1,0)-GARCH(1,1)",
     col = "red",
     xlab = "Time", 
     ylim = ylim, 
     ylab = expression(hat(sigma)[t]))

plot(vol_C, type = "l",
     main = "Series C: ARMA(4,0)-GARCH(1,1)",
     col = "orange",
     xlab = "Time",
     ylim = ylim,  
     ylab = expression(hat(sigma)[t]))

#Extracting GARCH coefficients
coef_A <- coef(fit_A)
coef_B <- coef(fit_B)
coef_C <- coef(fit_C)

#ARCH-LM test p-values from selected ARMA benchmark models
arch_p_A <- ArchTest(a_arma10$residuals)$p.value
arch_p_B <- ArchTest(b_arma66$residuals)$p.value
arch_p_C <- ArchTest(c_arma40$residuals)$p.value

#Building a summary table for all three series
classification_table <- data.frame(Series = c("Series A", "Series B", "Series C"),
                                   omega = c(coef_A["omega"],  coef_B["omega"],  coef_C["omega"]),
                                   alpha1 = c(coef_A["alpha1"], coef_B["alpha1"], coef_C["alpha1"]),
                                   beta1 = c(coef_A["beta1"],  coef_B["beta1"],  coef_C["beta1"]),
                                   Persistence = c(coef_A["alpha1"] + coef_A["beta1"],
                                                   coef_B["alpha1"] + coef_B["beta1"],
                                                   coef_C["alpha1"] + coef_C["beta1"]),
                                   ARCH_p_value = c(arch_p_A, arch_p_B, arch_p_C),
                                   Interpret_persistence = c(TRUE, TRUE, FALSE),
                                   Category = c("Moderate persistence",
                                                "High persistence",
                                                "No / negligible GARCH")
                                  )


classification_table

#Ranking only the series for which persistence is economically meaningful
ranked_persistence <- classification_table[order(-classification_table$Persistence), ]
rownames(ranked_persistence) <- NULL

ranked_persistence[, c("Series", "Persistence", "Category")]

#Computing half-life: number of periods for a shock to decay to 50%

persistence_A <- coef_A["alpha1"] + coef_A["beta1"]
persistence_B <- coef_B["alpha1"] + coef_B["beta1"]

#(alpha + beta)^k = 0.5
halfl_A <- ceiling(log(0.5) / log(persistence_A)) #get an integer number from ceiling()
halfl_B <- ceiling(log(0.5) / log(persistence_B))

data.frame(Series = c("Series A", "Series B", "Series C"),
           Persistence = c(round(persistence_A, 4), 
                           round(persistence_B, 4), NA),
           Half_life = c(halfl_A, halfl_B, NA),
           Note = c("Moderate", "High", 
           "No meaningful GARCH effects")
          )

#Plotting how quickly a volatility shock fades over time

options(repr.plot.height = 5, repr.plot.width = 11)

horizon <- 100
periods <- 0:horizon

#Computing the decay path for the two series with supported GARCH effects
decay_A <- persistence_A^periods
decay_B <- persistence_B^periods

#Plotting the decay path for Series A
plot(periods, decay_A,
     type = "l",
     col = "blue",
     ylim = c(0, 1),
     xlab = "Periods after shock",
     ylab = "Remaining impact of shock",
     main = "Decay of volatility shocks"
    )

#Adding the decay path for Series B
lines(periods, decay_B, col = "red")

abline(h = 0.5, lty = 2)

legend("topright",
       legend = c("Series A (moderate)", "Series B (high)"),
       col = c("blue", "red"),
       lwd = 2,
       bty = "n"
      )

#Reload ARMA models from Problem 2
fit_A_arma <- Arima(seriesA$ret, order = c(1,0,0))
fit_B_arma <- Arima(seriesB$ret, order = c(6,0,6))  
fit_C_arma <- Arima(seriesC$ret, order = c(4,0,0))

#Series A: compare ARMA(1,0) with ARMA(1,0)-GARCH(1,1) 
a_coef_A <- coef(fit_A_arma)
a_se_A <- sqrt(diag(vcov(fit_A_arma)))

g_coef_A <- coef(fit_A)
g_se_A <- sqrt(diag(vcov(fit_A)))
mean_idx_A <- !names(g_coef_A) %in% c("omega","alpha1","beta1")

# Rename "mu" -> "intercept" to match Arima() naming, then reorder
g_mean_A <- g_coef_A[mean_idx_A]
names(g_mean_A)[names(g_mean_A) == "mu"] <- "intercept"
g_se_mean_A <- g_se_A[mean_idx_A]
names(g_se_mean_A)[names(g_se_mean_A) == "mu"] <- "intercept"
g_mean_A <- g_mean_A[names(a_coef_A)]
g_se_mean_A <- g_se_mean_A[names(a_coef_A)]

data.frame(Parameter = names(a_coef_A),
  ARMA_coef = round(a_coef_A, 6),
  ARMA_se = round(a_se_A, 6),
  ARMA_t = round(a_coef_A / a_se_A, 3),
  ARMA_p = round(2 * (1 - pnorm(abs(a_coef_A / a_se_A))), 4),
  GARCH_coef = round(g_mean_A, 6),
  GARCH_se = round(g_se_mean_A, 6),
  GARCH_t = round(g_mean_A / g_se_mean_A, 3),
  GARCH_p = round(2 * (1 - pnorm(abs(g_mean_A / g_se_mean_A))), 4),
  row.names  = NULL
)

#Series B: comparing ARMA(6,6) with ARMA(1,0)-GARCH(1,1)
#Mean spec changed from (6,6) to (1,0) at GARCH stage,
#so parameters differ — printed as separate tables
a_coef_B <- coef(fit_B_arma)
a_se_B <- sqrt(diag(vcov(fit_B_arma)))

g_coef_B <- coef(fit_B)
g_se_B <- sqrt(diag(vcov(fit_B)))
mean_idx_B <- !names(g_coef_B) %in% c("omega","alpha1","beta1")

#ARMA(6,6) parameters
data.frame(Parameter = names(a_coef_B),
  ARMA_coef = round(a_coef_B, 6),
  ARMA_se = round(a_se_B, 6),
  ARMA_t = round(a_coef_B / a_se_B, 3),
  ARMA_p = round(2 * (1 - pnorm(abs(a_coef_B / a_se_B))), 4),
  row.names = NULL
)

#ARMA(1,0)-GARCH(1,1) mean parameters
data.frame(Parameter = names(g_coef_B[mean_idx_B]),
  GARCH_coef = round(g_coef_B[mean_idx_B], 6),
  GARCH_se = round(g_se_B[mean_idx_B], 6),
  GARCH_t = round(g_coef_B[mean_idx_B] / g_se_B[mean_idx_B], 3),
  GARCH_p = round(2 * (1 - pnorm(abs(g_coef_B[mean_idx_B] / g_se_B[mean_idx_B]))), 4),
  row.names = NULL
)

#Series C: comparing ARMA(4,0) with ARMA(4,0)-GARCH(1,1)
a_coef_C <- coef(fit_C_arma)
a_se_C <- sqrt(diag(vcov(fit_C_arma)))

g_coef_C <- coef(fit_C)
g_se_C <- sqrt(diag(vcov(fit_C)))
mean_idx_C <- !names(g_coef_C) %in% c("omega","alpha1","beta1")

# Rename "mu" -> "intercept" to match Arima() naming, then reorder
g_mean_C <- g_coef_C[mean_idx_C]
names(g_mean_C)[names(g_mean_C) == "mu"] <- "intercept"
g_se_mean_C <- g_se_C[mean_idx_C]
names(g_se_mean_C)[names(g_se_mean_C) == "mu"] <- "intercept"
g_mean_C <- g_mean_C[names(a_coef_C)]
g_se_mean_C <- g_se_mean_C[names(a_coef_C)]

data.frame(Parameter = names(a_coef_C),
  ARMA_coef = round(a_coef_C, 6),
  ARMA_se = round(a_se_C, 6),
  ARMA_t = round(a_coef_C / a_se_C, 3),
  ARMA_p = round(2 * (1 - pnorm(abs(a_coef_C / a_se_C))), 4),
  GARCH_coef = round(g_mean_C, 6),
  GARCH_se = round(g_se_mean_C, 6),
  GARCH_t = round(g_mean_C / g_se_mean_C, 3),
  GARCH_p = round(2 * (1 - pnorm(abs(g_mean_C / g_se_mean_C))), 4),
  row.names = NULL
)

#Comparing information criteria for ARMA-only and ARMA-GARCH models
#rugarch reports AIC and BIC per observation, so we multiply by the sample size to make them comparable with the values returned by Arima()

sample_size <- 4000

info_criteria <- data.frame(Series = c("A", "A", "B", "B", "C", "C"),
                            Model = c("ARMA(1,0)", "ARMA(1,0)-GARCH(1,1)",
                                      "ARMA(6,6)", "ARMA(1,0)-GARCH(1,1)",
                                      "ARMA(4,0)", "ARMA(4,0)-GARCH(1,1)"),
                            AIC = c(fit_A_arma$aic, infocriteria(fit_A)[1] * sample_size,
                                    fit_B_arma$aic, infocriteria(fit_B)[1] * sample_size,
                                    fit_C_arma$aic, infocriteria(fit_C)[1] * sample_size),
                            BIC = c(fit_A_arma$bic, infocriteria(fit_A)[2] * sample_size,
                                    fit_B_arma$bic, infocriteria(fit_B)[2] * sample_size,
                                    fit_C_arma$bic, infocriteria(fit_C)[2] * sample_size)
                           )

info_criteria

#Comparing residuals squared: ARMA-only (left) vs ARMA-GARCH standardized (right)

options(repr.plot.height = 12, repr.plot.width = 14)
par(mfrow = c(3, 2), mar = c(4, 4, 3, 1))

#Extracting standardized residuals from GARCH fits
std_residual_A <- residuals(fit_A, standardize = TRUE)
std_residual_B <- residuals(fit_B, standardize = TRUE)
std_residual_C <- residuals(fit_C, standardize = TRUE)

#Series A
acf(fit_A_arma$residuals^2, main = "Series A — ARMA only (squared resid)", lag.max = 30)
acf(std_residual_A^2, main = "Series A — ARMA-GARCH (squared std resid)", lag.max = 30)

#Series B
acf(fit_B_arma$residuals^2, main = "Series B — ARMA only (squared resid)", lag.max = 30)
acf(std_residual_B^2, main = "Series B — ARMA-GARCH (squared std resid)", lag.max = 30)

#Series C
acf(fit_C_arma$residuals^2, main = "Series C — ARMA only (squared resid)", lag.max = 30)
acf(std_residual_C^2, main = "Series C — ARMA-GARCH (squared std resid)", lag.max = 30)

#ARCH tests for residuals from the ARMA-only models
ArchTest(fit_A_arma$residuals) #Series A
ArchTest(fit_B_arma$residuals) #Series B
ArchTest(fit_C_arma$residuals) #Series C

#ARCH tests for standardized residuals from the ARMA-GARCH models
ArchTest(as.numeric(std_residual_A)) #Series A
ArchTest(as.numeric(std_residual_B)) #Series B
ArchTest(as.numeric(std_residual_C)) #Series C


