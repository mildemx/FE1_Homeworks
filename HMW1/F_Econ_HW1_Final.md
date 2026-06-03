# Financial Econometrics I - Homework 1
#### **Authors:** Maxim Milde (`73267075`), Zahid Pashayev (`54520099`)
**Individual contributions**: 
Max Milde - Problem 1, Part 1; Zahid Pashayev - Problem 1, Part 2 & Problem 2; each team member contributed to the refinement of all sections

**AI tool usage**: Claude (Anthropic) was primarily used to debug code, evaluate syntax, and provide suggestions about how to improve the layout of plots. The entire process of developing all of the statistical reasoning, making decisions about what to do with dirty data, and interpreting results was done in isolation from the AI, and was then reviewed and revised using AI feedback. The core logic and structure of the analysis was developed by the team with the help and guidance of code taught in the seminars

## Problem 1 Part 1

### 1.  Setup and Data Cleaning

We do not observe duplicated tickers from both files, so no need for special naming.

`PHM` contains "Klose" instead of "Close"

We now have only the columns we are interested in.

Need to drop NAs, so returns can be calculated properly.

### 2. Returns

From the plots, we observe that it is quite common to have daily retuns of &plusmn; 10-20%, even 30%. 

Nevertheless, `CVX` particularly stands out as it has several spikes of &plusmn; ~100% magnitude - likely a data issue.

### 3. Summary Statistics

As expected, `CVX` is a clear outlier, with kurtosis of ~228 and extreme min (-98%) and max (98%) values.

Other larger leptokurtic tickers include: `FE`, `ELV` and `XOM`, all with kurtosis above 30.
They are also the most largely skewed - likely affected by real negative events. However, `CVX` does not have a skew of high magnitude (minimal), which suggests that it is most likely a data issue.

There do not appear to be other extreme or unusual statistics.

Upon further inspection, it can be seen that on 3 occasions, the stock price drops drastically and then recovers the next day. One possibility of such price change would be innapropriate stock split data handling, however `CVX` last stock split was in 2004. As such, it seems that the issue is simply wrong data entry.

To ensure appropriate return modelling and comparison, we trim those observations. Winsorizing would be innapropriate as making an estimate of the returns on those days would affect the return distribution. Given that we have established that those observations are not true outliers, but data handling errors, we find it most appropriate to simply remove them. Trimming at the 50% absolute value of returns is appropriate as no true observations exceed this amount, only the wrong entries.

The issue is fixed.

Still, kurtosis is close to 30 and skewness has a magnitude above 1. 

Nevertheless, we will further investigate the ticker with highest kurtosis out of the sample, as the one to be the furthest away from a normal distribution. This is because kurtosis signals fat tails - extreme events happen more frequently, meanwhile negative skew (what we see in most stocks) simply suggests that most of the density is in a negative area.

### 4. Normality

We identify `FE` to be the ticker with highest leptokurtic properties (45.2).

- Alpha: tail heaviness 
- Beta: skewness
- Gamma: scale (similar to sd)
- Delta: location (similar to mean)

The stable distribution parameters indicate significant tail risk, slight negative skewness and a location of near zero.

It is evident that using a normal distribution to model `FE`'s stock returns would be greatly inappropriate. The probability of an extreme negative shock to the stock price is much larger than the normal distribution predicts. This can have large implications on portfolio risk management. If the normal distribution is used to model a portfolio return distribution with large kurtosis (and negative skewness), risk measures such as Value at Risk and Expected Shortfall could be largely understated. Failing to appropriately account for tail risk could have devastating consequences. A clearer image of the left tail can be seen below.

The fitted stable distribution has $\alpha$ < 2, which implies a theoretically infinate variance. As such, in practice it comes at a cost. Risk measurement requires some sort of finate second moments.

## Part 2

### 1.

We can see that all the series cover approximately same time periods (Jan 2019 - Dec 2025) with only 1 day differences in the Start Date. All tickers have around the same number of observations, ranging from 1749 to 1758. Because of the removed bad data points for `CVX` ticker in Part 1, there is a noticeable difference in the number of observations for this stock. However, it is only 9 missing trading days for `CVX` which is not a lot due to the dataset having overall of 1,758 observations and missing days making up only less than 1% of total observations.

After joining all the series, we've obtained 1733 common trading days for all the stocks, ranging from 04.01.2019 to 30.12.2025. The merge uses an inner join, therefore any date where even one ticker is not present gets removed. By doing this, we ensure that the computation of the cross-sectional mean is always done for the same list of stocks.

We see tiny losses across all the series with the number of rows dropped ranging from 16 to 25. The only stock to pay attention at is `CVX` that has the biggest gap but due to the difference being small, we move forward with all 18 series.

The mean return is roughly zero which expected and aligned with financial literature. The standard deviation (~0.014) is observed to be lower than that of the individual stocks due to the averaging (diversification) all 18 series which reduces idiosyncratic volatility. There's a slighly negative skewness (similar to the return distribution of mutual fund returns) in the distribution and it's also leptokurtic (kurtosis > 3). This shows that while diversification reduces tail risk, economy-wide shocks (systematic risk, such as around the Covid-19 crisis) can still produce extreme returns even in diversified portfolios (even though the degree of diversification of the portfolio at hand is not closely examined here). As such, all stocks are affected by systematic shocks in the entire market and these shocks persist in the cross-sectional average.

### 2.

Comparison parameters:

- Alpha: There is a slightly greater alpha (1.573) in the mean returns than in FE (1.559) which means slightly "lighter" tails. Although this difference is small, it indicates that although an average over 18 stocks will reduce idiosyncratic tail risks, it will have only a minor impact on alpha, and both are still much lower than 2, indicating heavy tailed characteristics exist in the cross sectional mean.
- Beta: The skewness parameter has decreased from -0.219 (FE) to -0.141 (mean returns) which means less negative skewness exists in the data. It would be logical to expect that the negative skewness that existed in each of the 18 individual stocks, would cancel out when they were averaged. However, there is a residual negative skewness remaining due to market wide declines that affect all of the stocks at the same time.
- Gamma: Has decreased from 0.00726 (FE) to 0.00637 (mean returns). A gamma value acts as a scale factor, so the reduction in gamma is reflective of the decline in dispersion from averaging.
- Delta: Delta values are similar for both FE (0.00161) and mean returns (0.00078) and should be near zero since daily returns, and are centered about zero regardless if looking at one stock or the portfolio averages.

In total, the cross-sectional mean appears to be slightly more normally distributed (greater alpha, less skewness, smaller scale) but the changes are minimal. Both distributions are clearly non-gaussian and exhibit heavy-tailed characteristics ($\alpha$ < 2), and therefore confirm that diversification can reduce, but will not completely remove heavy-tail characteristics.

### 3.

This is consistent with the parameter estimates and the histogram shown above; the red line representing the stable distribution matches the blue line representing the normal distribution, yet the stable distribution fits the data much better. And it explains why we see a high peak near zero and why we observe heaver tails on both sides, whereas the normal distribution is too flat around the middle, and overestimates density around 0.02. Also, it underestimates the probability of both large and small returns. 

A slight asymmetry towards the left tail is observable, and is consistent with the negative beta (-0.141) estimated by the stable fit. As compared to the FE histogram from Part 1, this shape is generally more narrow, and has a higher concentration of observations around zero due to the lower volatility observed when averaging the 18 stocks included in the sample. Nonetheless, the gap between the normal and stable fit clearly demonstrates that even after diversification, a Gaussian model would not be capable of accurately modeling the true return distribution.

### 4.

Comparative analysis of `CS_MEAN` vs. Individual Stocks:

SD - `CS_MEAN` (0.0137) is lower than all individual stocks. `MDLZ` is the least volatile stock at 0.0134; however, most stocks have SDs of 0.017-0.032. Thus, averaging across 18 assets reduces volatility, because the idiosyncratic movements in individual stocks will partially offset one another.

Extreme values - The cross-sectional mean's min/max values of -0.163, 0.124 were relatively moderate when compared to the individual stock's worst cases:`QRVO` Min = -0.319, `WHR` Max = 0.259. Stock-specific shocks are diluted when averaged.

Skewness - `CS_MEAN` had a skewness of -1.16, which is even more negative than for the majority of individual stocks. This implies that on days where the market drops, the majority of stocks drop together and the common crash effect is magnified in the average. The positive skewness of individual stocks are also eliminated.

Kurtosis - `CS_MEAN` (23.3) was greater than many individual stocks (`GM = 6.6`), but lower than the most extreme (`XOM = 36.4`). The high kurtosis in the average is due to market-wide extreme days that impact all stocks at the same time.

In summary, diversification successfully reduced volatility and reduced individual extremes, however it also amplified the relative impact of market wide shocks.

## Problem 2.

We create 500 simulations of random walks without drift, each with 1000 steps, defined by

$$
X_t = X_{t-1} + \varepsilon_t,
$$

where

$$
\varepsilon_t \sim N(0, \sigma^2), \qquad X_0 = 0.
$$

In addition, we repeat the simulation for two different levels of volatility: a low-variance case with

$$
\sigma = 0.01
$$

and a high-variance case with

$$
\sigma = 0.15
$$

This allows us to compare how the variance of the random walk increases over time under different disturbance variances.

The plots show that the paths of a random walk fan out over time. As time progresses, the distance between the paths becomes larger, which reflects the increasing uncertainty of the process. Since there is no force pulling the process back toward zero, the paths can continue to drift farther away from the starting point.

In addition, the shaded interquartile range (IQR) band starts narrow and gradually widens, which is consistent with the fact that

$$
\operatorname{Var}(X_t) = \sigma^2 t.
$$

The dashed theoretical bounds,

$$
\pm 2\sigma\sqrt{t},
$$

provide a good approximation of the dispersion in the simulated data, since most of the simulated paths remain within these limits.

Comparing the two plots, the case with

$$
\sigma = 0.15
$$

shows substantially wider dispersion than the case with

$$
\sigma = 0.01
$$

This is expected, because the variability of the random walk increases with $\sigma$. Since there is no drift term, the median path in both cases remains close to zero over time.

The main conclusion is that the uncertainty of a random walk grows without bound as the forecast horizon increases. The further into the future we try to predict, the wider the confidence interval becomes.