# Financial Econometrics I - Homework 3
#### **Authors:** Maxim Milde (`73267075`), Zahid Pashayev (`54520099`)
**Individual contributions**: Maxim Milde (Problem 1), Zahid Pashayev (Problem 2); cross-revision, refinement and elaboration by both students on all parts.

**AI tool usage**: Claude.ai was used for coding assistance (syntax - if not found in the seminars, debugging, R package usage) and as a discussion partner for improvement of concept understanding. All interpretation, reasoning, and written analysis is fully composed by the students.

**Data used**: `73267075`

---

## Problem 1

### 1. Data Preparation

### 2. Restrict data

Abnormal spike in BAC's price close to end of period. Needs investigation.

Abnormal price level on 2016-11-22.

09:05:00 - note timestamp.

This ~20% 1-minute price increase appears to be a data error as the surrounding it prices remain around $19.5-$19.8. The economic mechanics behind such a trade also appear unrealistic (very large buy-sell trades (liquid stock) within the same minute that first spike and then return the price directly to its previous level). The anomaly can be clearly seen in the graph above.

We conclude this is a data error and as such, this observation is removed.

Notice scale. Issue fixed. Result - loss of 1 intraday observation that could otherwise skew analysis unreasonably.

No strange outliers appear anymore in any of the stocks.

### 3. Intraday 1-minute returns

`Clarification`: The use of the abbreviation "RV" in this notebook stands for Realized Variance.

Volatility clustering appears as expected. Memory seems to be more pronounced in XOM, where volatility tends to persist for longer. It should be noted that the period examined across each stock is different. XOM has the longest timespan. Y-scale is similar across stocks.

### 4. Realized Variance: highfrequency package comparison

We find no difference between the two methods of calculation of Realized Variance. As such, we conclude that makeReturns=TRUE from prices does not take into account overnight returns. This is confirmed by the source code of the function, where rCov calls `apply.daily` when RV is calculated with prices: makeReturns=TRUE.

### 5. Realized Variance: intraday sub-period comparison

The most obvious tendency which can be seen from the graphs above is that overall, volatility during 16:00-18:00 appears to be the highest: general trend. This however is more apparent in XOM and MSFT, while for BAC, this trend is not as strong - other trading hours are often as volatile. Regarding XOM, this late-trading-hours volatility appears to taper off around 2014 and then starts to spike back up.

### 6. Daily RV vs Sum or Intraday RV

While the graphs may appear volatile, notice the y-axis scale. The difference between the two metrics must be floating point noise (rounding errors) in the calculation. We conclude this is the case because both Daily and Intraday-sum are calculated over the same hours and without the inclusion of overnight returns. Since the differences are so miniscule (and of equal magnitude across all stocks), only software rounding in the calculations could be responsible.

### 7. % share of individual intraday RV

From the box plot, we establish that for BAC, the proportion of volatility during 09:30-10:59 is largest throughout the sample. Nevetheless, 16:00-18:00 appears to have the largest amount and magnitude of outliers. This means that volatility (specifically in those late trading hours (and also early ones - 7:00-9:29)) is itself quite volatile in comparison to the other sub-periods.

MSFT: Early and late trading hours sometimes account for close to 100% of the daily RV (outliers). In general, The widest and highest interquartile range is during the latest hours in the sample, which means that we see a large share of the day's RV happen in that timeframe. Maximum RV share also occurs in the late trading hours subperiod. Nevertheless, 9:30-10:59 subperiod has the highest median.

XOM: Similarly to the other stocks the late trading hours have the widest IQR and highest upper whisker. The median of late and 9:30-10:59 percentage of total volatility daily share is similar. Early hours have a number of outlier observations.

Overall, the sub-periods with highest ranges and highest share of total daily volatility are similar across stock. The general pattern that emerges from out sample universe appears to be the following (from highest to lowest range of subperiod RV as a share of daily RV): 16:00-18:00 > 9:30-10:59 > 7:00-9:29 (high number of outliers across socks) > 11:00-14:29 > 14:30-15:59.

Indeed, trading hours do appear to matter with respect to volatility (volume traded).

### 8. RV using 1-minute prices

Previously when we computed RV over subperiods, we used pre-computed intraday returns (over the whole day) and segmented them by subperiods. As such, until this point, we are unaware whether every sub-period of interest contains enough price observations to calculate returns from within the sub-period.

Now however, we are using prices directly and calculating returns from within the sub-period. Thus, we need to ensure that every sub-period contains enough price observations within itself to calculate returns.

If this is not dealt with, rCov causes `subscript out of bounds` error.

The most evident difference between these three sub-period RV Plots and the former ones is BAC. When calculating RV from returns, an RV obsevation around 2016/04 gets assigned to the 7:00-9:29 subperiod (black), while when RV is computed from prices, that same observation gets assigned to the 9:30-10:59 subperiod (red). This shift in timing can be attributed to where we assign the boundary value. In Step 5, we computed all of our returns for the entire trading session before computing the variance of those returns. Therefore, a return timestamped at 09:30 (i.e. log(P_09:30)-log(P_09:29)), by default would fall into the 09:30-10:59 time bucket. With rCov(makeReturns=TRUE) seeing only prices in the 07:00-09:29 time window, it uses the last available price up to 09:29 to compute the last return; therefore, that return will remain within the earlier time bucket.

For MSFT and XOM, part of the small difference comes from removing days that had too few price observations in a sub-period (5 and 14 days respectively). But the bigger reason — and the one clearly visible in BAC — is that when we feed prices into rCov(makeReturns=TRUE) separately for each sub-period, the return that straddles the boundary between two blocks simply never gets computed. The 7:00–9:29 block ends at P_9:29 with no next price to form a return from, and the 9:30–10:59 block starts at P_9:30 using it only as the base for its first return. So the log(P_9:30) − log(P_9:29) return falls through the gap. With 5 sub-periods there are 4 such boundaries, meaning 4 returns go missing from the sum — while the daily RV, computed over the full unbroken day, picks all of them up. This is the key takeaway: RV is not simply additive across sub-periods when computed directly from prices, because splitting the price series creates gaps at the boundaries. This issue doesn't come up in steps 5–7 where we pre-computed returns over the whole day and only split them afterwards — there, every return gets counted exactly once no matter how we partition them.

We find no differences worth mentioning here in comparison to part 7.

### 9. BPV and MedRV comparison to RV

Here we assume the assignment does not ask for computation of the noise-robust BPV because we will compare the differences from microstructure noise between 1 and 5-minute data in Problem 2.

Before looking at the graphs, we should expect RVol to provide the highest variance values, since BPV and MedRV (continuous volatility estimators) are robust to jumps (RV includes jumps). Therefore, RV - BPV (or RV - MedRV) should equal the jump component. 

While it is difficult to get a clear picture from the graphs above since lines overlap heavily, one can see the tendency of the blue lines (RV, left graphs) to disappear in the right graphs. This suggests that including the jump component ensures that the sum of integrated variance estimate + jump variance estimate is at least as large as RV.

One can get a clearer picture of the difference in estimates from the graphs above, which represent the magnitude of significant jump components (jump variance) depending on the respective JumpTest (BPV and MedRV). 

While the identification of significant jumps between BPV and MedRV JumpTests is close to identical, it can be clearly seen that MedRV tends to consistently underestimate the magnitude of integrated variance: since RV - MedRV results in negative values across most of the sample period. This result is contratian to what we would expect: RV = MedRV + J -> (estimation error).

From the graphs above, it can be seen that across stocks, the BPV JumpTests tend to attribute a larger proportion of the total variance (RV) to jumps, while MedRV tends to overestimate continuous variance (RV - MedRV = negative ->  smaller estimated jump component than BPV.)

Note: The two methods of continuous variance estimation do not always flag the same shocks as significant jumps.

Note: MedRV often gives result to negative magnitude jump variation: can be seen in BAC (estimation error)

### 10. ARMA(0,0)-GARCH(1,1)

The biggest differences between the two volatility estimates which can be observed from the graphs above are the following:
- GARCH tends to be smoother and updates slowly - because volatility is latent and GARCH has to estimate it from daily squared returns (1 observation per day), meanwhile RV uses multiple intraday observations to estimate volatility. This makes it more reactive to intraday price movements.
- The smoothness of GARCH comes from the fact that it is designed to model volatility persistence, while RV directly reacts to what happens at time t (no smoothing).
- This smoothness can lead GARCH to estimate higher volatility than RV when going from a high vol period into low vol period as it lags behind (for almost all obs RVol > sigma GARCH).
- RVol appears to be higher than GARCH sigma for most days because RV sums all squared intraday returns (the higher the sampling frequency, the higher the RV -> more microstructure noise). GARCH is unaffected by sampling frequency - uses daily returns. As 1-min return frequency is not optimised to minimize microstructure noise, GARCH and 1-min RV are not directly comparable.

# Problem 2

## Part A: Repeat Problem 1 analysis at 5-minute frequency

### 1. Data conversion to 5-minute prices

### 2. Sanity check and intraday returns

The 5-minute data has been restricted to the same hours as the original 1-minute data; that is 7:00 - 18:00. It also retains the date restrictions of the 1-minute data which we determined in Problem 1. Since we have already verified in Problem 1 that all observations for this anomaly were deleted from the 1-minute data set; none of those anomalies will be present in the 5-minute data set either.

### 3. Realized Variance: makeReturns comparison (5-min)

Same results as in Problem 1; the difference is nearly zero across all stocks. This verifies that rCov handles overnight returns correctly regardless of sampling frequency.

### 4–5. Sub-period RV and daily vs sum (5-min returns)

The picture looks very similar to the 1-minute results. The open and close sub-periods (9:30-10:59 & 16:00-18:00) are still dominant across all three stocks. Individual spikes are less sharp at a five minute sample rate due to the averaging (reduction) of microstructure noise, and therefore slightly lower volatility.

### 6. Daily RV vs sum and percentage shares (5-min returns)

Again same as Problem 1, the difference is just floating point noise. When we use pre-computed returns, daily rv and the sum of sub-period RVs are identical up to rounding since we're just dividing the same set of square return into groups and adding them back up. This holds true for both 1 minute and 5 minutes.

### 7. Percentage share interpretation (5-min returns)

Sub-period share breaks down similarly to Problem 1. Open and Close periods drive the most variance in shares, and they are also the largest number of outlier values; Midday periods show little movement and a relatively constant percent of total shares. Both time frames exhibit this trend whether you’re using 1-minute or 5-minute frequency data, which indicates this is an actual trading behavior of these stocks rather than a result of your decision on what time frame to use to sample the trades.

The price-based RV sub-periods were calculated similarly to the return-based RV sub-periods described earlier. Any minor difference in the results could come from how you assign returns to each period as explained in Step 8 of Problem 1.

### 8. Repeat with 5-minute prices

Similar to what was seen in Problem 1, Daily RV from prices will always be greater than the sum of RVs from prices that correspond to the sub-periods. This is due to returning prices at the sub-period boundaries causing some returns to fall across multiple boundaries (i.e., log(P_9:30) - log(P_9:29)) thus being missed when calculating the sum. At four boundaries there are four returns that get lost in the sum but none of them are lost in the whole day RV calculation. This is a desired outcome and should not be considered an error.

Using five minute intervals instead of one minute intervals resulted in a larger gap than seen in Problem 1. Individual 5-minute returns are larger because prices tend to fluctuate more over longer time periods, and therefore the four boundary returns that get lost in the sum are each larger. However, there are still only four such returns regardless of the time interval used. As noted previously, the overall trend remains the same as observed in Problem 1.

Although the distributional characteristics appear similar to those seen for return-based measures of volatility, since both sub-period price RVs are less than their respective boundary return values, the sum of the shares adds up to just shy of 100%, and that is exactly as expected based upon the missing cross-period returns.

### 9. BPV, MedRV, and jump tests (5-min)

Again, at 5-minute frequencies, we find that RV > BPV or MedRV. However, there is an approximate gap in the magnitude between MedRV and BPV. As was found previously, BPV tends to assign more to jumps than does MedRV.

A more interesting observation is made when looking at MedRV. Throughout Problem 1, we were finding that RV - MedRV < 0. This should be impossible theoretically; however, at 5-minute time intervals, this phenomenon appears to dissipate. We interpret this to mean that at 1-minute intervals, micro-structural noise and finite sample size issues cause the two estimation techniques to operate in opposing ways - noise increases RV directly (i.e., positively), whereas MedRV responds differently due to the use of the median operator. At 5-minute intervals, much if not all of this noise has dissipated and the two estimation techniques appear to act more similarly to how they would have been expected

The two are very close but not always identical. A minor discrepancy may occur if the opening or closing 5-minute bar price does not exactly coincide with the corresponding 1 min value for the day. However, such discrepancies will be extremely minimal and should never impact your ability to obtain a good fit using GARCH.

### 10. ARMA(0,0)-GARCH(1,1) comparison (5-min)

The same thing occurred as in problem one. GARCH produces smoother estimates with slower reactions to the events of the day than RVol which has quicker reactions to actual events during the day. The only major difference from Problem One is the gap between the two is significantly reduced by using a sampling frequency of 5 minutes. It would make sense that this would be the case because at 1 minute sampling frequencies the amount of micro-structure noise added to RV greatly exceeds the actual variance (sigma) of the GARCH model. Therefore, when you move to a 5 minute sampling frequency almost all of the micro-structure noise is eliminated and therefore RVol is now much closer to GARCH sigma. This is also why 5 minute is the most commonly used time frequency in empirical research on volatility estimation, because it provides a clean measure of volatility without sacrificing too many degrees of freedom.

### Part B: Comparison of 1-minute vs 5-minute results

### Consolidated comparison

1. RV level
The plots and comparison table show that 1 minute RV levels are consistently higher than those of 5 min RV over all three stock portfolios. As expected from microstructure noise, at the 1 minute time scale, bid-ask bounce and price rounding in reported prices generate artificial variability that is captured by RV. By averaging these two measures into 5 min RV levels, much of this artificial variability should be smoothed away, and we will have a measure of the actual underlying variance. For this very reason, the sample period of 5 min has been adopted throughout the literature as a sensible compromise.
2. Volatility dynamics
The two time-series move very similarly. When the volatility is high on one scale (i.e., a large number), it is also high on the other. And they have similar patterns of clusters.
There is clearly some commonality to the data on both scales. The main differences appear to be due to varying amounts of "noise."
3. RVol vs GARCH
For almost all of the sample period, 1-minute RVol lies significantly higher than GARCH Sigma. For most of the sample, however, 5-minute RVol lies close to GARCH Sigma and follows its movement fairly closely. Because GARCH is based solely on the sample's daily returns and therefore is not affected by intra-day noise, it provides a base line which 5-minute RVol approaches as the amount of intra-day noise declines. This is consistent with the observation that 1-minute RV is recording equal parts 'true' variance and 'noise'.
4. Jump detection
At a 5-minute sampling interval there are fewer samples that will be identified by the BNS test as having significant jumps. A spike in noise can easily appear as an actual jump at 1-minute sampling intervals; this increases the sample size of what the BNS identifies as possible jump occurrences. Only significant changes in price would pass the threshold of the BNS test at a 5-minute sampling interval, thus providing a better estimate of the number of times there was actually a price jump
5. MedRV behaviour
The RV - MedRV < 0 problem from Problem 1 is almost entirely eliminated when we go to sample at 5 minutes. This is due to a noise artefact -- not because there is some other structural feature of volatility processes which causes this phenomenon.


Overall
The 5 minute data behaves exactly as one would have expected the one minute data to behave for all important dimensions: the intraday volatility pattern; volatility clustering; whether GARCH or RVol is correct; and how many jumps occur. In addition, the quantifiable differences (lower RV estimates; fewer jumps; well behaved MedRV) can be attributed to micro-structure noise being significantly less of an issue when you sample at 5 minute intervals. Therefore, if one's primary interest is in estimation issues, then sampling at 5 minute intervals is likely preferable.