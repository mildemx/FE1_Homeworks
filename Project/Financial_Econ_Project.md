# Financial Econometrics I - Project
#### **Authors:** Maxim Milde (`73267075`), Zahid Pashayev (`54520099`)

**Individual contributions**:

**AI tool usage**: 

**Data used**: `Asset 12`

---

## Setup

---
# 1. Data Description

The dataset contains 1,500 daily observations of Asset 12 over time period of January 5, 2010 through January 22, 2016. Six variables are included: returns (ret), realized volatility (RV), positive realized semi-volatility (RV_p) and negative realized semi-volatility (RV_n), realized skewness (RS) and realized kurtosis (RK). No data is missing.

## Descriptive Statistics

The **returns** are close to zero mean and are negatively skewed with positive excess kurtosis. This is common when describing the characteristics of financial returns. **Realized Volatility (RV)** appears to be right skewed; the mean is greater than the median`, and has some larger spikes within the dataset reflecting volatility clustering.` The two realized semi-variabilities **(RV_p & RV_n)** have nearly identical means in this example, although they differ substantially in higher moments. `although it may be an anomaly of this particular asset`. **Realized Skewness (RS)** is centered close to zero, however, it can range anywhere from approximately (-8) to (+6) - extreme skewness is more severe on the negative side. `Therefore, there will occasionally be days where the intraday asymmetry will be significantly different from average.`  **Realized Kurtosis (RK)** is generally well above 3 and is also highly right skewed. `Many days' returns exhibit more severe tailed distributions than those described by a standard normal distribution.` Fat-tailed intraday distributions appear to be the norm. Some days have extreme tail behaviour reaching as high as 69.7.

## Time Series Plots

The evidence from RV clearly demonstrates that the returns exhibit **"volatility clustering"** (i.e., periods of calm markets and those of turbulence) and that periods of high volatility in the returns typically remain for a number of weeks. Visually, the returns appear to be `roughly` stationary; however, they do occasionally experience severe negative shocks. **RV** exhibits 2-4 sharp temporary spikes, which return to base levels rather quickly. The behaviour of both **RV_p and RV_n** appears very similar. Nevertheless, it is evident that the most negative and most positive volatility spikes, do not occur at the same time. `yet are never identical.` **RS** does not portray evident clusters and fluctuates around 0. `occasionally has an extreme spikes when the stock's price or volume exhibits unusual behavior throughout the trading day.` **RK**: there seems to be some correlation between RK and RV spikes. RK, which appears to be consistently above 3, exhibits numerous spikes along the sample, with the most extreme one falling within a positive net return day, as it can be seen below.

## ACF Plots

**Returns** demonstrate almost no serial correlation at any lag (mostly lag 1), which is consistent with weak form market efficiency. **RV, RV_p, and RV_n** demonstrate a strong autocorrelation that is relatively slow to decay. This suggests the presence of persistent volatility dynamics that motivates the use of the HAR (Heterogeneous Autoregressive) model. **RS** is close to a white noise - `therefore it displays characteristics typical of such as well as` nearly no autocorrelation. **RK** `has some level of serial correlation at shorter lags; however, this autocorrelation dissipates much quicker than the autocorrelations seen in the volatility measures.` does not seem to portray systematic autocorrelation, with several lags crossing the significance level rather arbitrarily.

## Histograms & Density

The **returns** appear to be rather close to normally distributed; however, they have "fatter tails" than a true normal distribution (which corresponds to the excess kurtosis reported in the descriptive statistics). All **three RV metrics** are skewed toward the right with an extended tail - i.e., most of the time, intraday volatilities are relatively low, but from time-to-time, volatility spikes significantly. **RS** appears to be approximately symmetrical around zero but it is more heavily tailed than a normal ( substantial intra-day skewness occurs at times). **RK** is centered around 3-5, but it also has a significant amount of mass in its `upper-`right tail`, with some large outliers present for days when both intra-day returns are characterized by large amounts of heavy-tail behavior?` with very large outliers. Normal distribution is a poor fit overall.

# 2. In-Sample Fit

We estimate **six volatility models** on all of our sample data. Our HAR family models have $RV_t$ (Realized Volatility) as their dependent variable. `Our GARCH family models measure the conditional volatility of stock returns ($h_t$) and map that back onto the RV scale via a measurement equation.` Our GARCH family models measure the Conditional Variance ($h_t$) of stock returns. Their $\sigma_t=sqrt(h_t)$ can therefore be directly compared against $RV_t$.

## Constructing Regressors

The HAR family has three measures of how long past volatilities continue in some form of past behavior. Those are **daily**, **weekly** (a 5-day average) and **monthly** (a 22-day average). All regressors are lagged by one day to ensure we use only information available at time $t-1$.

## Model 1: AR(1)-RV

$$RV_t = \beta_0 + \beta_1\, RV_{t-1} + \varepsilon_t$$

The **AR(1) coefficient** on the lagged RV is nearly **0.50** and highly significant. Thus, we can see a large/moderate amount of day-to-day persistence in volatility. We find an adjusted R² of approximately **0.25** - a quarter of the variance in the current day's volatility is explained by the previous day's volatility. This is the simplest baseline.

## Model 2: HAR-RV

$$RV_t = \beta_0 + \beta_d\, RV_{t-1} + \beta_w\, RV_{t-1}^{(w)} + \beta_m\, RV_{t-1}^{(m)} + \varepsilon_t$$

Because in HAR models the rolling weekly ($RV_t^{(w)}$) and monthly ($RV_t^{(m)}$) averages overlap over consecutive periods, this makes the OLS residuals exhibit serial correlation. As such, the standard errors are biased. We correct for this using Newey West standard errors at lag 22 (the largest lag in the model).

We find all of these components of volatility persistence to be **statistically significant**. The daily lagged term provides the largest contribution to volatility persistence (approximately 0.32). It represents a measure of short-term persistence in volatility. Next, we find the weekly average term contributing a smaller portion of total variability in volatility (around 0.19). Therefore, it provides evidence of medium-term volatility clustering. Lastly, we also indentify the monthly average term to be statistically significant `and provided another, larger portion of total variability in volatility` with a coefficient of approximately 0.30. Finally, we can see a `substantial` meaningful increase in the adjusted R² to around 0.30, which indicates volatility persistence occurring on multiple time scales simultaneously.

## Model 3: HAR-RS (Realized Semivariances)

We `split RV into` use positive (RV_p) and negative (RV_n) semi-volatility for each of our three time horizons based on Patton & Sheppard (2015). In our data, RV_p and RV_n are semi-volatilities (not variances) – they satisfy $RV_p^2 + RV_n^2 = RV^2$ rather than summing to RV directly. This segmentation allows the predictive power of upside versus downside movements to be different for future volatility. 

$$RV_t = \beta_0 + \beta_d^{+} RV_{p,t-1} + \beta_d^{-} RV_{n,t-1} + \beta_w^{+} RV_{p,t-1}^{(w)} + \beta_w^{-} RV_{n,t-1}^{(w)} + \beta_m^{+} RV_{p,t-1}^{(m)} + \beta_m^{-} RV_{n,t-1}^{(m)} + \varepsilon_t$$

The daily negative semi-volatility coefficient of around 0.36 is approximately double that of its positive counterpart (0.18), each of which is statistically significant. Both results align with a **leverage-type asymmetry**; large down-side movements generally forecast larger subsequent volatilities relative to corresponding up-side movements. At longer horizons, weekly and monthly terms, `various coefficients are in agreement as far as the signs, however most do not reach statistical significance` the coefficients keep the same sign pattern (negative semivariances having a higher coefficient), although only the monthly negative semivariance reaches statistical significance at the 5% level (the only change in significance after implementation of NW se). Adjusted $R^2$ is around 0.32 and thus shows an improvement on the standard HAR. As such, separation of positive and negative variation adds predictive power.

## Model 4: HAR-Rskew-Rkurt

We augment the HAR-RS model with realized skewness and realized kurtosis at daily, weekly, and monthly horizons:

$$RV_t = \beta_0 + \beta_d^{+} RV_{p,t-1} + \beta_d^{-} RV_{n,t-1} + \beta_w^{+} RV_{p,t-1}^{(w)} + \beta_w^{-} RV_{n,t-1}^{(w)} + \beta_m^{+} RV_{p,t-1}^{(m)} + \beta_m^{-} RV_{n,t-1}^{(m)}$$
$$+ \gamma_d RS_{t-1} + \gamma_w RS_{t-1}^{(w)} + \gamma_m RS_{t-1}^{(m)} + \delta_d RK_{t-1} + \delta_w RK_{t-1}^{(w)} + \delta_m RK_{t-1}^{(m)} + \varepsilon_t$$

In Model 4, NW se lead to the statistical significance of several coefficients to change.

Semivariance coefficients follow a similar pattern as found in HAR-RS, although the positive RV at lag 1 is no longer significant. Montly negative RV is now significant at 5%.

Regarding higher moments `semivariance`, the daily realized skewness coefficient is positive although no longer significant after NW - `given that there are more extreme (positively) skewed intraday returns today predict higher realized volatility tomorrow`. Weekly and monthly RS coefficients are insignificant. Daily and weekly realized kurtosis coefficients are negative and marginally significant at 10%. `This may seem unexpected at first, as we would expect fatter tails today to predict more volatility tomorrow but likely reflects mean-reversion, but once we control for the level of volatility through the semivariances, extremely heavy tailed days are likely to be followed by much calmer days. The monthly RK coefficient is insignificant.` Adjusted R² values reach around 0.33, the highest R² value of all the HAR type models (slight improvement over HAR_RS). This indicates that skewness and kurtosis provide some limited additional information on predicting future volatility, above and beyond the semivariance breakdown. At least after correcting for autocorellation in standard errors.

## `Model 5: Realized GARCH (Approximation)`

The Realized GARCH of Hansen, Huang and Shek (2012) is a joint model. It estimates three equations in total; a return equation, a variance equation that utilizes realized volatility as a feedback mechanism for variance, and an estimation equation (measurement equation) to estimate the parameters of the first two. Since we can't run this entire model here (the rugarch package is needed), we create a **two-stage approximation** of the original model;

1. Fit a standard GARCH(1,1) on returns to get the conditional variance $h_t$.
2. Regress: $RV_t = \xi_0 + \xi_1\, h_t + u_t$.

This isn't a true Realized GARCH. RV does not get fed back into the variance equation. We're estimating $h_t$ using only returns data and then estimating how these values map to RV using a second stage OLS estimation. Therefore the results need to be viewed with this in mind

The estimates for the GARCH (1, 1) are: $\alpha_1 = ~0.35$  & $\beta_1 = ~0.43$. Thus, there is persistence in the system at about 0.78. It's less than 1 which indicates that both the variance and the returns process are stationary and mean-reverting.

We see in our results that the variance does link to returns (RV), however, it also appears to be very weak as indicated by the low adjusted $R^2$ of approximately 0.04. That's not surprising since $h_t$ is estimated purely from returns. Thus, if we can estimate a Realized GARCH model where RV is fed back into the variance equation then it's likely to perform better, but we cannot test this here.

## `Model 6: ARMA(1,1)-GARCH(1,1)`

We model the conditional mean with an ARMA(1,1) process and the conditional variance with a GARCH(1,1). As with the Realized GARCH approximation, we map the conditional variance to the RV scale via a measurement equation for a fair comparison.

Persistence appears to be greater (approximately 0.86) compared to a standard GARCH model, and it makes some logical sense as the ARMA mean component changes residual structure. The ARMA term appears to be moderate while the MA term may not even be statistically significant. This implies that introducing mean dynamics does little to enhance the ability of return-based GARCH models to explain day-to-day RV variance as evidenced by similar levels of persistence in the R² of the measurement equation.

## Model 5: Realized GARCH

The Realized GARCH of Hansen, Huang and Shek (2012) is a joint model. It estimates three equations in total; a return equation, a variance equation that utilizes realized volatility as a feedback mechanism for variance, and an estimation equation (measurement equation) to estimate the parameters of the first two: 

$$
\begin{align}
r_t &= \mu + \sqrt{h_t} z_t \\
\ln(h_t) &= \omega + \alpha_1 \ln(RV_{t-1}^2) + \beta_1 \ln(h_{t-1}) \\
\ln(RV_t^2) &= \xi + \delta \ln(h_t) + \tau(z_t) + u_t \\
\tau(z_t) &= \eta_{11} z_t + \eta_{21}(z_t^2 - 1)
\end{align}
$$

where
- $r_t$ - daily return
- $h_t$ - conditional variance
- $z_t$ - standardized return shock
- $RV_t^2$ - realized variance
- $\tau(z_t)$ - leverage function
- $u_t$ - measurement equation error

From the Robust SE results:

Persistence = $\beta_1 + \delta \times \alpha_1 = 0.469 + 0.560 \times 0.755 = 0.787$ - confirmation that the process is stationary and mean-reverting (around 79% of today's variance carries over to tomorrow).

$\alpha_1$ coefficient (0.75) is statistically significant and shows that past realized volatility is informative for current conditional variance.

$\beta_1$ (0.47) is also statistically significant and portrays the persistence of past conditional variance.

$\eta_{11}$ of -0.05 shows the significant leverage effect, where negative return shocks are associated with higher realized volatility.

The significant lambda coefficient (0.24) proves that $RV$ is a noisy proxy for variance $h_t$ and that there is substantial measurement error in $RV$.

## Model 6: ARMA(1,1)-GARCH(1,1)

We model the conditional mean with an ARMA(1,1) process and the conditional variance with a GARCH(1,1) - a return based model. We can then compare its $\sigma = \sqrt(h_t)$ to RV.

Persistence = $\alpha_1 + \beta_1 = 0.257 + 0.595 = 0.852$, which is bigger than Realized GARCH (0.787). ARMA-GARCH suggests that shocks die out more slowly (estimating from returns only) than in Realized GARCH.

The ARMA terms are both insignificant, so we can derive that mean dynamics do not explain much and returns are close to white noise (or at least 1,1 is not the correct mean specification, consistent with ACF).

The GARCH terms ($\alpha_1$ and $\beta_1$) become insignificant after SE correction.

## Comparison of In-Sample Fits

`models <- list(m1, m2, m3, m4, m5, m6)
names(models) <- c("AR(1)-RV", "HAR-RV", "HAR-RS", "HAR-Rskew-Rkurt",
                    "Realized GARCH*", "ARMA-GARCH")`

`fits <- sapply(models, fitted) #predicted RV values from models
actual <- model_df$RV`

`comp <- data.frame(
  Model = names(models),
  MSE = colMeans((actual - fits)^2),
  MAE = colMeans(abs(actual - fits)),
  Adj_R2 = sapply(models, function(m) summary(m)$adj.r.squared)
)`
`comp`

`*\*Realized GARCH is a two-step approximation, not a full joint estimation (Model 5: Realized GARCH)*`

`**AR (1)** is the least complex model. It only has an $R^2$ of around 0.25 when including only one lag of RV. Adding weekly and monthly components, as in **HAR-RV**, improves results by approximately 0.30. These results indicate volatility persistence exists at more than one frequency.` 

`By introduction of weekly and monthly components, there's a further improvement in **HAR-RS** (around 0.32). The size of the negative semi-volatility effect is larger than the positive semi-volatility effect which is consistent with leverage type asymmetry. `

`**HAR-Rskew-Rkurt** provides the highest in sample $R^2$ (nearly 0.33). The addition of kurtosis terms adds additional information on the top of semivariance split. `

`**Both GARCH** models sit below the HAR family. Although they can map their estimated conditional variance back onto the RV scale through a measurement equation, the explanatory power of each model relative to RV will be much less. In other words, while GARCH models measure the conditional variance of returns, this is related to RV, but is not equivalent to it.`

The following patterns can be observed from the plot:

The HAR family models follow closely actual RV during calm periods but consistently undershoot large spikes (smooth out the extreme values). ARMA-GARCH is the most volatile fitted line, which overshoots consistently and significantly, especially in the period 2014-15 (it overreacts to shocks). Furthermore, Realized GARCH and ARMA-GARCH consistently fit values above actual RV.

The HAR models are hardly distinguishable in the plots (confirmed by the similar R^2) and fit actual RV more closely than the GARCH family.

Since GARCH family models update conditional variance only from returns, they are slower to react to volatility changes. The HAR family use lagged RV directly and as such respond more quickly to changes in RV levels.

It appears that HAR models track the general level of RV better, but underestimate large volatility spikes on consistent basis. ARMA-GARCH introduces a lot of noise (false spikes). Overall, none of the models capture the largest spikes in volatility accurately. Realized GARCH appears to be the more balanced GARCH model. HAR_Rskew_Rkurt obtains the lowest MSE and MAE of all models.