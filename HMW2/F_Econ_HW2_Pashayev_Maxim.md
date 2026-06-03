# Financial Econometrics I - Homework 2
#### **Authors:** Maxim Milde (`73267075`), Zahid Pashayev (`54520099`)
**Individual contributions**: Maxim Milde (construction of Problems 1-3), Zahid Pashayev (construction of Problems 4-6); cross-revision, refinement and elaboration by both students on all parts.

**AI tool usage**: Claude.ai was used for coding assistance (syntax - if not found in the seminars, debugging, R package usage) and as a discussion partner for improvement of concept understanding. All interpretation, reasoning, and written analysis is fully composed by the students.

**Data used**: 73267075

## Problem 1: Preliminary analysis

From comparing both return series and return^2 series (proxy for volatility, since returns appear to have a mean close to 0), it appears that:
- **Series B**: while it exhibits the highest degree of volatility clustering (high alpha - reactiveness), it appears to be relatively short lived (the series mean-reverts quickly, moderate beta); strongest GARCH effects
- **Series A**: appears to be the series with moderate volatility clustering spread over the sample. Nevertheless the persistence of these clusters appear to last longer than Series B (higher beta).
- **Series C**: exhibits the lowest degree of GARCH dynamics - it has rather constant variance, with no sustained and obvious clustering.

**Initial hypothesis**: Series B exhibits the most persistent volatility clustering, Series A shows moderate persistence, and Series C appears closest to homoskedastic with no sustained clustering. To be confirmed from further analysis.

## Problem 2: Identification of the conditional mean

Potential ARMA specifications based on ACF/PACF:

**Series A**: ARMA(0,1), ARMA(0,0), ARMA(1,1) (unlikely)
- The ACF cuts off after the first lag, every other is whithin confidence bands - this suggests MA(1). The $\theta$ coefficient being very small could justify the sharp cutoff in PACF. It could also simply be white noise (ARMA(0,0)), since all but 1 lags are within conficence bands.

**Series B**: ARMA(7,2), ARMA(3,1), ARMA(3,2) 
- It becomes very hard to judge the process, as the significance of lag autocorrelations persist at high lags and no clear cutoff pattern
- High order ARMA is likely overfitting from GARCH contamination

**Series C**: ARMA(2,1), ARMA(4,0), ARMA(0,4)
- Lags 1 and 4 are significant in ACF, suggesting MA up to order 4, however 1st lag in ACF and 2nd in PACF seem the most significant
- Lags 1, 2, 4 are significant in PACF, suggesting AR of order up to 4
---

### Model fitting
#### Series A

We fail to reject the null of joint insignificance of residual autocorrelation.

From the ACF and the formal test, we observe that ARMA(0,0) does not eliminate residual autocorrelation - the null of joint insignificance is rejected for all lags tested. There must be an exploitable mean structure.

In contrast, ARMA(1,1) is appropriate as indicated by both the inability to reject of the null of joint residual autocorrelation and the ACF - we do not observe residual autocorrelation after fitting this model.

Upon further inspection, it appears that ARMA(1,0) is more appropriate candidate than some of the hypothesized ones above. We cannot reject the null and the ACF and PACF show no residual autocorrelation.

**Top candidates for series A**:
- ARMA(0,1)
- ARMA(1,0)
- ARMA(1,1)
---

#### Series B

While all coefficients appear to be significant, the Ljung-Box null cannot be rejected (for lower lags), we observe high autocorrelation at higher lags (PACF), which is also strongly supported by the formal test.
These results strongly suggest GARCH contamination and that any order ARMA we attempt to fit, will either be innapropriate, or overfit the data.
Given that residual autocorrelation persists at high lags even under ARMA(7,2), the initially hypothesised lower-order specifications ARMA(3,1) and ARMA(3,2) would perform no better. We therefore depart from those candidates and instead explore higher-order alternatives — ARMA(15,1) and ARMA(6,6) — to test the limits of pure ARMA modeling for this series and further demonstrate the likely presence of GARCH contamination.

It is evident that in order to eliminate the residual autocorrelation in PACF by fitting only an ARMA model, it would necessitate very high order AR terms. The MA part appears to be around 1. Attempting to fit more ARMA models to this series is of no use, as we will likely be overfitting the model instead. Nevertheless, we continue as per assignment.

This model performs similarly to ARMA(15,1).

**Best candidate**:
- ARMA(15,1)
- ARMA(6,6)

However, we know that these are not appropriate.

#### Series C

None of the coefficients show to be significant (coeff/s.e.).
Nevertheless, we cannot reject the null of insignificant residual autocorrelation at any of the examined lags. However, we still see one lag (4) in the PACF to be outside of the confidence bounds. We will therefore test ARMA(4,0)

Hereby, all residual autocorrelations disappear. We cannot reject the null and the ACF and PACF do not exhibit peculiar behaviour. We are inclined to believe this could be close to the data generating model.

Upon further inspection, ARMA(0,4) also provides a good fit, similar to ARMA(4,0). The behaviour is similar if we even attempt ARMA(4,4) as it can be seen below.

However, this is not the most parsimonuous model and we are likely overfitting at this stage.

**Best candidate models**:
- ARMA(4,0)
- ARMA(0,4)

`Side note`: splitting the model into sub-periods and considering different models for separate periods has not been considered, as we believe the assignment does not ask for that.

---

### Information Criteria comparison

The three examined criteria are defined as follows:

$$AIC = -2\ell(\hat{\theta}) + 2k$$

$$AICc = AIC + \frac{2k(k+1)}{n-k-1}$$

$$BIC = -2\ell(\hat{\theta}) + k\ln(n)$$

where $\ell(\hat{\theta})$ is the log-likelihood evaluated at the estimated parameters,
$k$ is the number of estimated parameters, and $n$ is the sample size.

The AIC and AICc differ with respect to penalization - AIC and AICc both reward fit and penalise complexity. AICc, however, introduces an additional correction term which penalises small sample sizes. Since our series samples are large, AIC and AICc are almost identical.

BIC: The penalty term $k\ln(n)$ grows with both the number of parameters $k$ and 
sample size $n$. For $n > e^2 \approx 7.4$, $\ln(n) > 2$. This means BIC always 
penalises complexity more heavily than AIC. With $n=4000$, $\ln(n) \approx 8.3$, 
around 4x the AIC penalty per parameter.


**Series A**:
Both ARMA(0,1) and ARMA(1, 0) perform similarly across all criteria, with ARMA(1,0) being negligably preferred across criteria. This suggests that both specifications model the mean equally well.

**Series B**:
AIC/AICc slightly prefer ARMA(15,1). BIC in turn prefers ARMA(6,6) as it finds it to be the more parsimonious specification. Since we suspected Series B to have the highest magnitude of GARCH effects, both specifications examined likely represent overfitting risk.

**Series C**: 
All three candidates perform similarly. AIC prefer ARMA(4,0) slightly (the difference is negligible), similar to BIC (which penalises the more complex ARMA(4,4))

---
Based on the information criteria and ACF/PACF graphs (for the examined specifications), we find the most appropriate ones to be:

**Series A**: ARMA(1,0)
- Unanimously selected by the information criteria by a small amount. Nevertheless, if it were truly an AR(1) process,while we would expect to have 1 significant lag at the PACF, we would also expect to see a slowly decaying ACF (it could be that the memory of this process is very short)

**Series B**: ARMA(6,6)
- The BIC finds the order 6,6 to be less complex, while the AIC(c) does not differentiate substantially between the two models. Neither model manages to eliminate completely the residual autocorrelation - remaining dynamics likely GARCH. This selection is provisional — if the residual autocorrelation is confirmed to stem from GARCH contamination rather than true mean dynamics in Problem 3, a more parsimonious mean specification may be adopted at the GARCH estimation stage.

**Series C**: ARMA(4,0)
- (4,4) is penalised for complexity, while (4,0) and (0,4) differ minimally based on the criteria. (4,0) has slightly more negative criteria. Such a finding is rather consistent with the PACF, as we see a cutoff around lag 4, while the ACF appears to be decaying in some form.

To be investigated further.

## Problem 3

Based on the ACFs and the cond. heteroscedasticity tests, we observe that series A and B are not accurately modeled, as there is residual autocorrelation in the squared residuals. These findings reflect the fact that ARMA models only manage to model the conditional mean, and are insufficient to model the conditional variance - need to fit a GARCH model.

The strong rejection of the null in Series A and B (as initially hypothesised) suggests that there are significant ARCH effects remaining after fitting ARMA (especially in Series B).

Meanwhile, Series C exhibits no significant residual^2 autocorrelation at lagged values. This suggessts that ARMA(4,0) is sufficient specification of the conditional mean - no evidence of ARCH effects, which aligns with our initial hypothesis from Problem 1.

- Since financial data tend to exhibit volatility clustering (conditinal heteroscedasticity), an ARMA model, which treats all observations equally (calm and turbulent period observations should not be treated as such) is not able to accurately fit such data. ARCH or GARCH models on the other hand, account for time varying estimates of $\sigma_t^2$, which can be used to standardise residuals. This leads to improvement in parameter estimation (when estimating parameters jointly ARMA-GARCH), as such a model accounts for heteroscedasticity in the error term. Consequently, we get better inference when we account for volatility clustering - otherwise heteroscedastic residuals would inflate SEs and make significance tests unreliable.

**In summary**: A review of the ACF plots and the results from the conditional heteroscedasticity test indicate that series A and B cannot be adequately modeled as they contain residual autocorrelation in their squared residuals. Both findings demonstrate that ARMA models are unable to model the conditional variance and therefore require a GARCH model to capture this component.

---

## Problem 4: Modeling conditional volatility

### Preferred ARMA specifications passed through from Problems 2 & 3

| Series | ARMA (Box-Jenkins) | ARMA for GARCH stage | Reason for revision |
|--------|-------------------|----------------------|---------------------|
| A | ARMA(1,0) | **ARMA(1,0)** | No change; clean identification |
| B | ARMA(6,6) *(provisional)* | **ARMA(1,0)** | Modified: Problem 3 demonstrated that high order lags capture GARCH influences as opposed to true mean dynamics; a parsimonious mean equation will serve as a more reasonable choice for estimating jointly |
| C | ARMA(4,0) | **ARMA(4,0)** | No change; clean identification |

The conditional variance equation applied to all three series is GARCH(1,1):

$$\sigma_t^2 = \omega + \alpha_1 \varepsilon_{t-1}^2 + \beta_1 \sigma_{t-1}^2$$

where $\omega > 0$ is the long-run variance intercept, $\alpha_1 \geq 0$ measures 
reactivity to lagged squared shocks (the ARCH effect), and $\beta_1 \geq 0$ captures 
persistence from the previous conditional variance (the GARCH effect).

### Estimated GARCH(1,1) parameters: ω, α₁, β₁

### Parameter explanation

Series A - ARMA(1,0)-GARCH(1,1)

- **ω** (omega): Estimated at 2.1e-05 is small but positive. Omega represents the baseline level of conditional variance that the process reverts to in the long run. This in turn suggests that in the absence of shocks, the conditional variance returns to a low but non-zero level.

- **α₁ (alpha1)**: Estimated at .1852. This represents how much a lagged "shock" affects todays' conditional variance. The value suggests that around 18.5% of last period's squared shock contributes to today's variance.

- **β₁ (beta1)**: Estimated at .6030. This means that around 60.3% of yesterday's estimated conditional variance carries into today (despite new shocks).

- **α₁ + β₁**: Estimated at .7882. This represents moderate to high persistence. In addition, since $\alpha + \beta < 1$, the variance will revert to its mean after any shock.

Series B - ARMA(1,0)-GARCH(1,1)

- **ω** (omega): Being nearly zero, the estimated ω is similar to Series A indicating the same unconditional variance baseline. The increased volatility characteristics of Series B are generated by the GARCH parameters rather than the intercept. 

- **α₁ (alpha1)**: The reactivity coefficient is largest (.2319). Therefore, Series B shows significant volatility increases after large shock events. The size of alpha1 causes significant jumps in conditional variance due to the squared innovation terms.

- **β₁ (beta1)**: The estimated beta1 of .75 is also large. Thus, once volatility rises significantly in Series B it tends to stay that way for several periods. With alpha1 and beta1 being very large, these represent the most persistent characteristic of a high-persistent GARCH model. Volatility shocks tend to be forgotten very slowly.

- **α₁ + β₁**: The largest persistence is exhibited by Series B with a persistence estimate of .9822 and very close to 1. Thus, the conditional variance shocks lose their influence very slowly.

Series C - ARMA(4,0)-GARCH(1,1)

- **ω** (omega): The estimated ω is effectively zero. This corresponds with our findings from Problem 3 that Series C contains virtually no ARCH effects. In general, conditional variance in Series C is near constant. 

- **α₁ (alpha1)**: Alpha1 is approximately 2.22e-03. As such, there is very little economic effect on conditional variance by new shocks. 

- **β₁ (beta1)**: Beta1 = 0.9957. This is close enough to 1 that one could treat it as equal. However, in a near-homoscedastic data set like Series C, the GARCH estimator can force beta into the region near 1 as an artifact of the optimizer.

- **α₁ + β₁**: Since this sum is 0.9979 (very close to 1), it is not economically relevant here either. The ARCH-LM test from Problem 3 did not indicate rejection of homoskedasticity therefore this fitted persistence measure is considered a boundary artifact and not an actual representation of the degree of volatility clustering.

### Persistence measure α₁ + β₁

The decay of a volatility shock follows the geometric sequence $(α_1 + β_1)^k$ 
for $k$ periods ahead. When the sum is close to 1 the shock dissipates very slowly 
(high persistence); when it is close to zero the shock vanishes almost immediately.
For the process to be covariance-stationary, we require α₁ + β₁ < 1.

Finally, we reject our initial hypothesis that Series A exhibits higher $\beta$ and therefore  longer lasting volatility persistence thant Series B.

### Full model output

### Conditional volatility plots

### Conditional volatility dynamics

**Series A** exhibits moderate conditional volatility throughout the sample. When a shock hits, we observe a meaningful variance reaction, although not to extreme levels as series B. In addition, the variance reverts back to its long-run level rather quickly. This is consistent with both $\alpha$ and $\beta$ being moderate.


**Series B** demonstrates the greatest degree of time-varying conditional volatility -- sharp large spikes followed by a prolonged period at elevated levels of volatility prior to reversion. This behavior is indicative of a high level of both α₁ (reaction to shock) and β₁ (slow rate of decay).

Following the revision of the mean specification from ARMA(6,6) to ARMA(1,0) , the GARCH is performing the correct function: it is absorbing the serial dependence that the higher order ARMA was capturing inaccurately.

**Series C** produces a nearly horizontal line for conditional volatility and provides no evidence of ARCH effects when using ARMA(4,0) residuals. Although the reported value of ω for the fitted GARCH(1,1) is effectively zero, the sum of the estimated values for α₁ and β₁ is very close to unity. Since ω is approximately zero, α₁ is small enough to be considered economically insignificant, and since including GARCH does little to improve the model overall, it can be concluded that Series C represents homoscedastic data and therefore estimates of persistence associated with GARCH are not economically significant.

### Classification
- **Most persistent meaningful GARCH effects:** Series B (highest level of persistence among all three series for which GARCH is economically justified)
- **Moderate GARCH effects:** Series A (evident clustering but less volatile and faster mean reversion compared to series B)
- **No/negligible GARCH effects:** Series C (no support from ARCH diagnostics for a meaningful GARCH effect; best to interpret boundary case as such)

## Problem 5: Comparing volatility persistence

### Classification & discussion

**Persistence ranking (all three series):**

| Rank | Series | $\alpha_1 + \beta_1$ | Category | Supported by diagnostics? |
|------|--------|----------------------|----------|---------------------------|
| 1 | Series B | 0.9822 | High persistence | Yes |
| 2 | Series A | 0.7882 | Moderate persistence | Yes |
| 3 | Series C | 0.9979 | No / negligible GARCH | No;boundary artifact |

**Note:** Series C is ranked last despite its numerically high persistence because the ARCH-LM test does not reject homoskedasticity; the fitted $\alpha_1 + \beta_1$ is a boundary artifact of forcing GARCH(1,1) onto homoskedastic data and is not economically interpretable.

**How the classification is supported**

**Estimated parameters**
The GARCH models are based on diagnostic results from all three series; however, among those for which they are supported by these results, Series B has the highest level of persistence and the slowest rate of volatility decay. The same may be said about Series A, although it exhibits a clearer but less extreme level of persistence. Series C, however, is subject to an estimated near unit persistence due to a mechanical aspect of the GARCH model. However, this should not be viewed as indicative of actual volatility clustering since the ARCH LM test indicates homoscedasticity and the GARCH model specifications were not supported by the diagnostics.

**Behavior of conditional volatility**
Conditional volatility in Series B tends to explode into large spikes that last for extensive intervals then rapidly decline. Conditional volatility in Series A exhibits relatively mild and smooth movements around its unconditional mean. On the other hand, there appears to be no variation over time in the variance of Series C (i.e., the conditional σ̂ₜ is essentially flat).

**Volatility clustering in raw data**
Both plots of returns (and returns^2) for Series B exhibit long stretches of time during which there is little or no movement in returns followed by short periods of extremely rapid changes (a classic example of high-persistence clustering). While both plots of returns for Series A appear to cluster together to some extent, it is not nearly as pronounced as for Series B. Furthermore, plots of returns for Series C appear to be homoscedastic throughout and do not exhibit any type of clustering. 

**Effect of persistence on rate of shock decay**
Whereas GARCH was supported by diagnostics for Series A and B, the rate at which a shock to volatility decays from a particular point t follows a geometric sequence $(α₁ + β₁)^k$ for k periods subsequent to t.

- When α₁ + β₁ ≈ **1**, the rate of decay will be quite slow. In the case of **Series B**, this means that shocks to volatility can affect future values for many periods.
- When α₁ + β₁ < **1**, the rate of decay will be faster. In the case of **Series A**, we observe clustering; however, these clusters dissipate fairly quickly.
- For **Series C**, this relationship is not given economic interpretation. Although α₁ + β₁ is numerically close to **1** for Series C, the diagnostics indicate that GARCH effects are not real; therefore, our treatment of this calculated value for persistence is that it represents an artificial boundary and does not represent slow volatility decay.

## Problem 6: Joint modeling of mean & volatility

The results obtained by fitting the pure ARMA models to the data set used in problem 2 will be compared with those of the joint ARMA-GARCH models fitted to the same data set in problem 4. In addition to comparing these two types of models, we also seek to answer three specific questions:

1. Does taking into account **conditional heterogeneity** affect either the **magnitude** of the mean (i.e., the ARMA) parameters or their **statistical significance**?

2. Are there **improvements in residual diagnostic measures**, such as white noise tests and other residual analysis, when a GARCH model is added to an ARMA model?

3. What does **simultaneous estimation** of the mean and volatility components contribute to the overall goal of using financial econometric models?

### Discussion

#### Does accounting for heteroscedasticity change the estimates of the mean parameters?

Theory states that if you perform an Ordinary Least Squares or Conditional Maximum Likelihood Estimation (OLS/C-MLE) on a dataset that includes heteroscedasticity, you will obtain consistent estimates for your parameter estimates, but **your estimates will be less efficient** -- your **parameter estimates** for the mean will be unbiased, but your **standard error** will be larger than it would have been under correct weighting (due to the fact that the standard deviation varies over the entire sample period).

When performing a full maximum likelihood estimation (MLE) to estimate both the ARMA portion of your model, and the GARCH variance equation simultaneously, the likelihood function correctly assigns a weight of $1/\sigma_{t}^{2}$ to each observation. Since $\sigma_{t}^{2}$ varies with time, observations in periods of high volatility are assigned lower weights. 

As illustrated in the Table below comparing the fits from two types of estimations:

- **Series A**: Because this series actually exhibits conditional heteroscedasticity, when we use the joint ARMA/GARCH estimation for Series A, we alter the **precision** or **estimated uncertainty** of the mean parameters relative to the ARMA-only fit. Although the **point estimates** for the parameters did not vary much, the **standard errors** did change because of the proper weighting of observations based upon their time-varying volatility.

- **Series B**: For this series, the **comparative analysis** is between an ARMA(6,6) model estimated in Problem 2 and an ARMA(1,0)-GARCH(1,1) model estimated in Problem 4. Additionally, since Problem 3 indicated that any additional ARMA terms added to capture the variance contaminating the mean rather than capture any type of dynamic relationship among the variables included in the mean equation, the differences in coefficients represent both the **re-weighting** effect of jointly estimating both the mean and variance equations and the changes in specifications of the mean equation. This comparative analysis could therefore be considered somewhat **indirect** as compared to that of Series A and C; however, it does illustrate another fundamental concept: ignoring conditional heteroscedasticity can lead to misidentifying mean relationships.

- **Series C**: Given that there is virtually no evidence of GARCH effects, the coefficients estimates and standard errors from the ARMA-only fit and ARMA-GARCH fit are nearly identical

#### Do residual diagnostic tests improve once we have modeled conditional volatility?

**Yes, considerably** for Series A and B. The autocorrelation functions (ACFs) of squared residuals from solely fitted ARMA models exhibit positive correlation at multiple lags (as shown in results of ARCH tests); which demonstrates that some kind of dependence in conditional variance was unaccounted for. However, once a GARCH(1,1) component was added to the model:

- The ACF of standardized residuals ($\epsilon \hat{t}/\sigma \hat{t}$) drops well within the limits of confidence intervals; indicating that GARCH filter has successfully identified all of the variance clustering.
- The p-values associated with ARCH test results increase substantially (thus failing to reject the null hypothesis of no ARCH effects).

**Series C**, already had no ARCH effects after fitting an ARMA(4,0) model; inclusion of GARCH(1,1) components provide minimal improvement and both residual diagnostic plots appear to be equally clean.

### Why is it important to model both the mean and variance simultaneously in financial econometrics?

There are three main reasons why modeling both the mean and variance is extremely important in financial econometrics:

1. **Efficiency** -- When employing a likelihood function that uses suitable weights based upon conditional variance ($\sigma_{t}^{2}$), the estimated parameters of the mean will have reduced **variance** (i.e. smaller standard errors). If we ignore heteroscedasticity, then our estimated **variance** will be inflated -- resulting in unreliably small p-values (and thus potentially misleading conclusions about which ARMA lag variables are statistically significant).

2. **Valid inference** -- Most statistical tests employed to evaluate hypotheses about ARMA residuals employ IID (independently and identically distributed) errors. If our residuals are heteroscedastic, then these tests are **invalid**. Utilizing a joint model of variance provides us with **valid statistical inference**.

4. **Forecasts of risk** -- In finance, the conditional variance ($\sigma_{t}^{2}$) is frequently a focus of interest for purposes such as portfolio optimization, derivative valuation and forecasting value-at-risk. Pure ARMA models treat variance as constant and cannot generate **time-varying risk forecasts**. The ARMA-GARCH model generates both a **forecast for the future mean and a forecast for future volatility at every horizon**; which is typical in financial risk management