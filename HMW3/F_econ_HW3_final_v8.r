#packages
library(fst)
library(highfrequency)
library(xts)
library(rugarch)

#load timeframe file
#setwd()
periods <- read.csv("students_HW3/73267075_periods_HW_3.csv")
periods

#func to extract periods
get_period <- function(ticker){
    row <- periods[periods$Ticker==ticker, ]
    list(start=paste0(row$Start, "-01-01"), #add start and end including month-day
        end=paste0(row$End, "-12-31"))
}

#load stock files
BAC <- read_fst("HW_3_data/HW_3_BAC_1min.fst")
MSFT <- read_fst("HW_3_data/HW_3_MSFT_1min.fst")
XOM <- read_fst("HW_3_data/HW_3_XOM_1min.fst")

head(BAC)
str(BAC)
str(MSFT)
str(XOM)

#convert stock dfs to xts
BAC_xts <- xts(BAC$V1, order.by=BAC$index)
MSFT_xts <- xts(MSFT$V1, order.by=MSFT$index)
XOM_xts <- xts(XOM$V1, order.by=XOM$index)


#filter to our given periods
p_BAC <- get_period("BAC")
p_MSFT <- get_period("MSFT")
p_XOM <- get_period("XOM")

BAC_xts <- BAC_xts[paste0(p_BAC$start, "/", p_BAC$end)] #xts subsetting based on dates given
MSFT_xts <- MSFT_xts[paste0(p_MSFT$start, "/", p_MSFT$end)]
XOM_xts <- XOM_xts[paste0(p_XOM$start, "/", p_XOM$end)]


#filter hours of interest
BAC_xts <- BAC_xts[format(index(BAC_xts), "%H:%M:%S") >= "07:00:00" &
                   format(index(BAC_xts), "%H:%M:%S") <= "18:00:00"]
MSFT_xts <- MSFT_xts[format(index(MSFT_xts), "%H:%M:%S") >= "07:00:00" &
                     format(index(MSFT_xts), "%H:%M:%S") <= "18:00:00"]
XOM_xts <- XOM_xts[format(index(XOM_xts), "%H:%M:%S") >= "07:00:00" &
                   format(index(XOM_xts), "%H:%M:%S") <= "18:00:00"]


#plot prices for overview 
options(repr.plot.height=8, repr.plot.width=18)
par(mfrow=c(3,1))
plot.xts(BAC_xts)
plot.xts(MSFT_xts)
plot.xts(XOM_xts)

#check OHLC around the suspicious period
to.daily(BAC_xts)["2016-11-17/2016-11-28"] #on daily basis

BAC_xts["2016-11-22"][BAC_xts["2016-11-22"] > 19.9] #check the highest values on that day

plot.xts(BAC_xts["2016-11-18/2016-11-28"]) 

#check the price graph of that day post-anomaly removal
BAC_xts <- BAC_xts[index(BAC_xts)!=as.POSIXct("2016-11-22 09:05:00", tz="UTC")]
plot.xts(BAC_xts["2016-11-18/2016-11-28"]) 


summary(BAC_xts)
summary(MSFT_xts)
summary(XOM_xts)

#subset price data by day
BAC_ret <- do.call(rbind, lapply(
    split(BAC_xts, as.Date(index(BAC_xts))), #split on per-day basis
    function(intraday){diff(log(intraday))}))  #calculate log-returns within each day

MSFT_ret <- do.call(rbind, lapply(
    split(MSFT_xts, as.Date(index(MSFT_xts))),
    function(intraday){diff(log(intraday))}))

XOM_ret <- do.call(rbind, lapply(
    split(XOM_xts, as.Date(index(XOM_xts))),
    function(intraday){diff(log(intraday))}))

#convert back to xts
BAC_ret <- as.xts(BAC_ret)
MSFT_ret <- as.xts(MSFT_ret)
XOM_ret <- as.xts(XOM_ret)

head(BAC_ret)

#plot log returns for each stock for visual overview
par(mfrow=c(3,1)) 
plot.xts(BAC_ret)
plot.xts(MSFT_ret)
plot.xts(XOM_ret)

#RV from prices, makeReturns=TRUE -> overnight returns are actually not included
#rCov computes returns on per.day-basis: elaborated on later in the notebook
BAC_price_RV <- rCov(BAC_xts, makeReturns=TRUE)
MSFT_price_RV <- rCov(MSFT_xts, makeReturns=TRUE)
XOM_price_RV <- rCov(XOM_xts, makeReturns=TRUE)

#RV from log returns, makeReturns=FALSE -> overnight returns are excluded manually
BAC_ret_RV <- rCov(BAC_ret, makeReturns=FALSE)
MSFT_ret_RV <- rCov(MSFT_ret, makeReturns=FALSE)
XOM_ret_RV <- rCov(XOM_ret, makeReturns=FALSE)

options(repr.plot.height=10, repr.plot.width=12)
par(mfrow=c(3,1))
plot.zoo(BAC_price_RV-BAC_ret_RV, main="BAC: Difference in RV computed from prices vs returns", col="blue")
plot.zoo(MSFT_price_RV-MSFT_ret_RV, main="MSFT: Difference in RV computed from prices vs returns", col="darkgreen")
plot.zoo(XOM_price_RV-XOM_ret_RV, main="XOM: Difference in RV computed from prices vs returns", col="red")

#getAnywhere(rCov)

#make a function to reduce manual coding
filter_hours <- function(data, start, end){
    data[format(index(data), "%H:%M:%S") >= start &
         format(index(data), "%H:%M:%S") <= end] #keep only the rows where the condition is true (xts)
}

#BAC: calculate intraday RV (using manually calc. returns)
BAC_RV1 <- rCov(filter_hours(BAC_ret, "07:00:00", "09:29:00"), makeReturns=FALSE)
BAC_RV2 <- rCov(filter_hours(BAC_ret, "09:30:00", "10:59:00"), makeReturns=FALSE)
BAC_RV3 <- rCov(filter_hours(BAC_ret, "11:00:00", "14:29:00"), makeReturns=FALSE)
BAC_RV4 <- rCov(filter_hours(BAC_ret, "14:30:00", "15:59:00"), makeReturns=FALSE)
BAC_RV5 <- rCov(filter_hours(BAC_ret, "16:00:00", "18:00:00"), makeReturns=FALSE)

#MSFT RV
MSFT_RV1 <- rCov(filter_hours(MSFT_ret, "07:00:00", "09:29:00"), makeReturns=FALSE)
MSFT_RV2 <- rCov(filter_hours(MSFT_ret, "09:30:00", "10:59:00"), makeReturns=FALSE)
MSFT_RV3 <- rCov(filter_hours(MSFT_ret, "11:00:00", "14:29:00"), makeReturns=FALSE)
MSFT_RV4 <- rCov(filter_hours(MSFT_ret, "14:30:00", "15:59:00"), makeReturns=FALSE)
MSFT_RV5 <- rCov(filter_hours(MSFT_ret, "16:00:00", "18:00:00"), makeReturns=FALSE)

#XOM RV
XOM_RV1 <- rCov(filter_hours(XOM_ret, "07:00:00", "09:29:00"), makeReturns=FALSE)
XOM_RV2 <- rCov(filter_hours(XOM_ret, "09:30:00", "10:59:00"), makeReturns=FALSE)
XOM_RV3 <- rCov(filter_hours(XOM_ret, "11:00:00", "14:29:00"), makeReturns=FALSE)
XOM_RV4 <- rCov(filter_hours(XOM_ret, "14:30:00", "15:59:00"), makeReturns=FALSE)
XOM_RV5 <- rCov(filter_hours(XOM_ret, "16:00:00", "18:00:00"), makeReturns=FALSE)

options(repr.plot.height=14, repr.plot.width=14)
par(mfrow=c(3,1))

#BAC
plot.zoo(BAC_RV1, main="BAC: Intraday Realized Variance by sub-period")
lines(zoo(BAC_RV2), col="red")
lines(zoo(BAC_RV3), col="green")
lines(zoo(BAC_RV4), col="blue")
lines(zoo(BAC_RV5), col="lightblue")
legend(x="top", legend=c("7:00-9:29", "9:30-10:59", "11:00-14:29", "14:30-15:59", "16:00-18:00"),
    col=c("black", "red", "green", "blue", "lightblue"), lwd=1, bty="n", horiz=TRUE)

#MSFT
plot.zoo(MSFT_RV1, main="MSFT: Intraday Realized Variance by sub-period")
lines(zoo(MSFT_RV2), col="red")
lines(zoo(MSFT_RV3), col="#0ad00a")
lines(zoo(MSFT_RV4), col="blue")
lines(zoo(MSFT_RV5), col="lightblue")
legend(x="top", legend=c("7:00-9:29", "9:30-10:59", "11:00-14:29", "14:30-15:59", "16:00-18:00"),
    col=c("black", "red", "green", "blue", "lightblue"), lwd=1, bty="n", horiz=TRUE)

#XOM
plot.zoo(XOM_RV1, main="XOM: Intraday Realized Variance by sub-period")
lines(zoo(XOM_RV2), col="red")
lines(zoo(XOM_RV3), col="green")
lines(zoo(XOM_RV4), col="blue")
lines(zoo(XOM_RV5), col="lightblue")
legend(x="top", legend=c("7:00-9:29", "9:30-10:59", "11:00-14:29", "14:30-15:59", "16:00-18:00"),
    col=c("black", "red", "green", "blue", "lightblue"), lwd=1, bty="n", horiz=TRUE)

#BAC: difference in daily vs sum of intraday RV
BAC_daily_RV <- rCov(BAC_ret, makeReturns=FALSE) #calculate daily RV
index(BAC_daily_RV) <- as.Date(index(BAC_daily_RV)) #keep only the date, no timestamp -> align all series

index(BAC_RV1) <- as.Date(index(BAC_RV1)) #drop timestamps for all - only dates left
index(BAC_RV2) <- as.Date(index(BAC_RV2))
index(BAC_RV3) <- as.Date(index(BAC_RV3))
index(BAC_RV4) <- as.Date(index(BAC_RV4))
index(BAC_RV5) <- as.Date(index(BAC_RV5))
BAC_RV_sum <- BAC_RV1 + BAC_RV2 + BAC_RV3 + BAC_RV4 + BAC_RV5 #sum intraday RV


#MSFT
MSFT_daily_RV <- rCov(MSFT_ret, makeReturns=FALSE)
index(MSFT_daily_RV) <- as.Date(index(MSFT_daily_RV))

index(MSFT_RV1) <- as.Date(index(MSFT_RV1)) 
index(MSFT_RV2) <- as.Date(index(MSFT_RV2))
index(MSFT_RV3) <- as.Date(index(MSFT_RV3))
index(MSFT_RV4) <- as.Date(index(MSFT_RV4))
index(MSFT_RV5) <- as.Date(index(MSFT_RV5))
MSFT_RV_sum <- MSFT_RV1 + MSFT_RV2 + MSFT_RV3 + MSFT_RV4 + MSFT_RV5


#XOM
XOM_daily_RV <- rCov(XOM_ret, makeReturns=FALSE)
index(XOM_daily_RV) <- as.Date(index(XOM_daily_RV))

index(XOM_RV1) <- as.Date(index(XOM_RV1)) 
index(XOM_RV2) <- as.Date(index(XOM_RV2))
index(XOM_RV3) <- as.Date(index(XOM_RV3))
index(XOM_RV4) <- as.Date(index(XOM_RV4))
index(XOM_RV5) <- as.Date(index(XOM_RV5))
XOM_RV_sum <- XOM_RV1 + XOM_RV2 + XOM_RV3 + XOM_RV4 + XOM_RV5

options(repr.plot.height=10, repr.plot.width=14)
par(mfrow=c(3,1))
plot.zoo(BAC_daily_RV - BAC_RV_sum, main="BAC: Daily RV - Sum of Intraday RV")
plot.zoo(MSFT_daily_RV - MSFT_RV_sum, main="MSFT: Daily RV - Sum of Intraday RV", col="darkgreen")
plot.zoo(XOM_daily_RV - XOM_RV_sum, main="XOM: Daily RV - Sum of Intraday RV", col="red")

BAC_pct1 <- BAC_RV1 / BAC_daily_RV * 100 #7:00−9:29
BAC_pct2 <- BAC_RV2 / BAC_daily_RV * 100 #9:30−10:59
BAC_pct3 <- BAC_RV3 / BAC_daily_RV * 100 #11:00−14:29
BAC_pct4 <- BAC_RV4 / BAC_daily_RV * 100 #14:30−15:59
BAC_pct5 <- BAC_RV5 / BAC_daily_RV * 100 #16:00−18:00

MSFT_pct1 <- MSFT_RV1 / MSFT_daily_RV * 100
MSFT_pct2 <- MSFT_RV2 / MSFT_daily_RV * 100
MSFT_pct3 <- MSFT_RV3 / MSFT_daily_RV * 100
MSFT_pct4 <- MSFT_RV4 / MSFT_daily_RV * 100
MSFT_pct5 <- MSFT_RV5 / MSFT_daily_RV * 100

XOM_pct1 <- XOM_RV1 / XOM_daily_RV * 100
XOM_pct2 <- XOM_RV2 / XOM_daily_RV * 100
XOM_pct3 <- XOM_RV3 / XOM_daily_RV * 100
XOM_pct4 <- XOM_RV4 / XOM_daily_RV * 100
XOM_pct5 <- XOM_RV5 / XOM_daily_RV * 100

options(repr.plot.height=12, repr.plot.width=16)
par(mfrow=c(2,1))

#BAC line graph
plot.zoo(BAC_pct1, main="BAC: Intraday RV % share of daily RV over time", ylab="%") #to visualise variation over time, although hard to read
lines(zoo(BAC_pct2), col="red")
lines(zoo(BAC_pct3), col="green")
lines(zoo(BAC_pct4), col="blue")
lines(zoo(BAC_pct5), col="lightblue")
legend(x="topleft", legend=c("7:00-9:29", "9:30-10:59", "11:00-14:29", "14:30-15:59", "16:00-18:00"),
    col=c("black", "red", "green", "blue", "lightblue"), lwd=1, bty="n", horiz=TRUE, text.width=70)

BAC_pct_df <- data.frame( #prepare dataframe for boxplot
    "7:00-9:29" = as.numeric(BAC_pct1),
    "9:30-10:59" = as.numeric(BAC_pct2),
    "11:00-14:29" = as.numeric(BAC_pct3),
    "14:30-15:59" = as.numeric(BAC_pct4),
    "16:00-18:00" = as.numeric(BAC_pct5),
    check.names=FALSE)
boxplot(BAC_pct_df, main="BAC: Intraday RV % share of daily RV", ylab="%",
    col=c("black", "red", "green", "blue", "lightblue"))

#same procedure for MSFT with a small tweak for df alignment
par(mfrow=c(2,1))

plot.zoo(MSFT_pct1, main="MSFT: Intraday RV % share of daily RV over time", ylab="%")
lines(zoo(MSFT_pct2), col="red")
lines(zoo(MSFT_pct3), col="green")
lines(zoo(MSFT_pct4), col="blue")
lines(zoo(MSFT_pct5), col="lightblue")
legend(x="topleft", legend=c("7:00-9:29", "9:30-10:59", "11:00-14:29", "14:30-15:59", "16:00-18:00"),
    col=c("black", "red", "green", "blue", "lightblue"), lwd=1, bty="n", horiz=TRUE, text.width=70
)

#need to merge MSFT pcts first, because pct5 has different number of obs than the rest (754 vs 756) (error regarding alignment otherwise)
MSFT_pct_merged <- cbind(MSFT_pct1, MSFT_pct2, MSFT_pct3, MSFT_pct4, MSFT_pct5)
MSFT_pct_df <- as.data.frame(MSFT_pct_merged)
colnames(MSFT_pct_df) <- c("7:00-9:29", "9:30-10:59", "11:00-14:29", "14:30-15:59", "16:00-18:00")

boxplot(MSFT_pct_df, main="MSFT: Intraday RV % share of daily RV", ylab="%",
    col=c("black", "red", "green", "blue", "lightblue"))

#XOM: same treatment as MSFT
par(mfrow=c(2,1))

plot.zoo(XOM_pct1, main="XOM: Intraday RV % share of daily RV over time", ylab="%")
lines(zoo(XOM_pct2), col="red")
lines(zoo(XOM_pct3), col="green")
lines(zoo(XOM_pct4), col="blue")
lines(zoo(XOM_pct5), col="lightblue")
legend(x="topleft", legend=c("7:00-9:29", "9:30-10:59", "11:00-14:29", "14:30-15:59", "16:00-18:00"),
    col=c("black", "red", "green", "blue", "lightblue"), lwd=1, bty="n", horiz=TRUE, text.width=200
)

XOM_pct_merged <- cbind(XOM_pct1, XOM_pct2, XOM_pct3, XOM_pct4, XOM_pct5)
XOM_pct_df <- as.data.frame(XOM_pct_merged)
colnames(XOM_pct_df) <- c("7:00-9:29", "9:30-10:59", "11:00-14:29", "14:30-15:59", "16:00-18:00")

boxplot(XOM_pct_df, main="XOM: Intraday RV % share of daily RV", ylab="%",
    col=c("black", "red", "green", "blue", "lightblue"))

#We would like to see whether each sub-period has enough price observations to create a return

stocks <- list(BAC=BAC_xts, MSFT=MSFT_xts, XOM=XOM_xts) #list of stock price series
period_list <- list(c("07:00:00","09:29:00"), c("09:30:00","10:59:00"), #list of intraday periods
                    c("11:00:00","14:29:00"), c("14:30:00","15:59:00"),c("16:00:00","18:00:00"))

for (ticker in names(stocks)){ #for each stock
    for (i in 1:5){ #for each intraday period
        filtered <- filter_hours(stocks[[ticker]], period_list[[i]][1], period_list[[i]][2]) #custom function from earlier - xts subsetting for each intraday period
        obs_per_day <- table(as.Date(index(filtered))) #count how many observations we have each day in a given sub-period
        single_obs_days <- sum(obs_per_day==1) #count number of days have a single price obs in a given sub-period
        if (single_obs_days>0) cat(ticker, "period", i, "has", single_obs_days, "days with 1 price obs.\n")
    }
}


#create a function which would remove days with insufficient price obs -> can calculate returns

filter_min_obs <- function(data, start, end, min_obs=2){
    filtered <- filter_hours(data, start, end) #xts subset custom func. from earlier
    obs_per_day <- table(as.Date(index(filtered)))
    valid_days <- names(obs_per_day[obs_per_day >= min_obs]) #get the names (the dates) of days satisfying the min obs condition
    filtered[as.Date(index(filtered)) %in% as.Date(valid_days)] #subset 'filtered' to keep only observations from valid_days
}

# BAC: intraday RV from prices
BAC_price_RV1 <- rCov(filter_min_obs(BAC_xts, "07:00:00", "09:29:00"), makeReturns=TRUE) #use only valid days
BAC_price_RV2 <- rCov(filter_min_obs(BAC_xts, "09:30:00", "10:59:00"), makeReturns=TRUE)
BAC_price_RV3 <- rCov(filter_min_obs(BAC_xts, "11:00:00", "14:29:00"), makeReturns=TRUE)
BAC_price_RV4 <- rCov(filter_min_obs(BAC_xts, "14:30:00", "15:59:00"), makeReturns=TRUE)
BAC_price_RV5 <- rCov(filter_min_obs(BAC_xts, "16:00:00", "18:00:00"), makeReturns=TRUE)

# MSFT
MSFT_price_RV1 <- rCov(filter_min_obs(MSFT_xts, "07:00:00", "09:29:00"), makeReturns=TRUE)
MSFT_price_RV2 <- rCov(filter_min_obs(MSFT_xts, "09:30:00", "10:59:00"), makeReturns=TRUE)
MSFT_price_RV3 <- rCov(filter_min_obs(MSFT_xts, "11:00:00", "14:29:00"), makeReturns=TRUE)
MSFT_price_RV4 <- rCov(filter_min_obs(MSFT_xts, "14:30:00", "15:59:00"), makeReturns=TRUE)
MSFT_price_RV5 <- rCov(filter_min_obs(MSFT_xts, "16:00:00", "18:00:00"), makeReturns=TRUE)

# XOM
XOM_price_RV1 <- rCov(filter_min_obs(XOM_xts, "07:00:00", "09:29:00"), makeReturns=TRUE)
XOM_price_RV2 <- rCov(filter_min_obs(XOM_xts, "09:30:00", "10:59:00"), makeReturns=TRUE)
XOM_price_RV3 <- rCov(filter_min_obs(XOM_xts, "11:00:00", "14:29:00"), makeReturns=TRUE)
XOM_price_RV4 <- rCov(filter_min_obs(XOM_xts, "14:30:00", "15:59:00"), makeReturns=TRUE)
XOM_price_RV5 <- rCov(filter_min_obs(XOM_xts, "16:00:00", "18:00:00"), makeReturns=TRUE)

head(BAC_price_RV1, 1)

#keep only the date
index(BAC_price_RV1) <- as.Date(index(BAC_price_RV1))
index(BAC_price_RV2) <- as.Date(index(BAC_price_RV2))
index(BAC_price_RV3) <- as.Date(index(BAC_price_RV3))
index(BAC_price_RV4) <- as.Date(index(BAC_price_RV4))
index(BAC_price_RV5) <- as.Date(index(BAC_price_RV5))

index(MSFT_price_RV1) <- as.Date(index(MSFT_price_RV1))
index(MSFT_price_RV2) <- as.Date(index(MSFT_price_RV2))
index(MSFT_price_RV3) <- as.Date(index(MSFT_price_RV3))
index(MSFT_price_RV4) <- as.Date(index(MSFT_price_RV4))
index(MSFT_price_RV5) <- as.Date(index(MSFT_price_RV5))

index(XOM_price_RV1) <- as.Date(index(XOM_price_RV1))
index(XOM_price_RV2) <- as.Date(index(XOM_price_RV2))
index(XOM_price_RV3) <- as.Date(index(XOM_price_RV3))
index(XOM_price_RV4) <- as.Date(index(XOM_price_RV4))
index(XOM_price_RV5) <- as.Date(index(XOM_price_RV5))

#plots
options(repr.plot.height=14, repr.plot.width=14)
par(mfrow=c(3,1))

plot.zoo(BAC_price_RV1, main="BAC: Intraday RV (prices) by sub-period")
lines(zoo(BAC_price_RV2), col="red")
lines(zoo(BAC_price_RV3), col="green")
lines(zoo(BAC_price_RV4), col="blue")
lines(zoo(BAC_price_RV5), col="lightblue")
legend(x="top", legend=c("7:00-9:29", "9:30-10:59", "11:00-14:29", "14:30-15:59", "16:00-18:00"),
       col=c("black","red","green","blue","lightblue"), lwd=1, bty="n", horiz=TRUE)

plot.zoo(MSFT_price_RV1, main="MSFT: Intraday RV (prices) by sub-period")
lines(zoo(MSFT_price_RV2), col="red")
lines(zoo(MSFT_price_RV3), col="green")
lines(zoo(MSFT_price_RV4), col="blue")
lines(zoo(MSFT_price_RV5), col="lightblue")
legend(x="top", legend=c("7:00-9:29", "9:30-10:59", "11:00-14:29", "14:30-15:59", "16:00-18:00"),
       col=c("black","red","green","blue","lightblue"), lwd=1, bty="n", horiz=TRUE)

plot.zoo(XOM_price_RV1, main="XOM: Intraday RV (prices) by sub-period")
lines(zoo(XOM_price_RV2), col="red")
lines(zoo(XOM_price_RV3), col="green")
lines(zoo(XOM_price_RV4), col="blue")
lines(zoo(XOM_price_RV5), col="lightblue")
legend(x="top", legend=c("7:00-9:29", "9:30-10:59", "11:00-14:29", "14:30-15:59", "16:00-18:00"),
       col=c("black","red","green","blue","lightblue"), lwd=1, bty="n", horiz=TRUE)

#difference between daily RV and sum of intraday RV

#sub-period sum of RV
BAC_price_RV_sum <- BAC_price_RV1 + BAC_price_RV2 + BAC_price_RV3 + BAC_price_RV4 + BAC_price_RV5
MSFT_price_RV_sum <- MSFT_price_RV1 + MSFT_price_RV2 + MSFT_price_RV3 + MSFT_price_RV4 + MSFT_price_RV5
XOM_price_RV_sum <- XOM_price_RV1 + XOM_price_RV2 + XOM_price_RV3 + XOM_price_RV4 + XOM_price_RV5

options(repr.plot.height=10, repr.plot.width=14)
par(mfrow=c(3,1))
plot.zoo(BAC_daily_RV-BAC_price_RV_sum, main="BAC: Daily RV - Sum of Intraday RV (prices)")
plot.zoo(MSFT_daily_RV-MSFT_price_RV_sum, main="MSFT: Daily RV - Sum of Intraday RV (prices)", col="darkgreen")
plot.zoo(XOM_daily_RV-XOM_price_RV_sum, main="XOM: Daily RV - Sum of Intraday RV (prices)", col="red")

#percentage share of individual subperiod intraday RV on total daily RV

BAC_price_pct1 <- BAC_price_RV1 / BAC_daily_RV * 100
BAC_price_pct2 <- BAC_price_RV2 / BAC_daily_RV * 100
BAC_price_pct3 <- BAC_price_RV3 / BAC_daily_RV * 100
BAC_price_pct4 <- BAC_price_RV4 / BAC_daily_RV * 100
BAC_price_pct5 <- BAC_price_RV5 / BAC_daily_RV * 100

MSFT_price_pct1 <- MSFT_price_RV1 / MSFT_daily_RV * 100
MSFT_price_pct2 <- MSFT_price_RV2 / MSFT_daily_RV * 100
MSFT_price_pct3 <- MSFT_price_RV3 / MSFT_daily_RV * 100
MSFT_price_pct4 <- MSFT_price_RV4 / MSFT_daily_RV * 100
MSFT_price_pct5 <- MSFT_price_RV5 / MSFT_daily_RV * 100

XOM_price_pct1 <- XOM_price_RV1 / XOM_daily_RV * 100
XOM_price_pct2 <- XOM_price_RV2 / XOM_daily_RV * 100
XOM_price_pct3 <- XOM_price_RV3 / XOM_daily_RV * 100
XOM_price_pct4 <- XOM_price_RV4 / XOM_daily_RV * 100
XOM_price_pct5 <- XOM_price_RV5 / XOM_daily_RV * 100

options(repr.plot.height=10, repr.plot.width=16)
par(mfrow=c(2,1))

plot.zoo(BAC_price_pct1, main="BAC: Intraday RV % share of daily RV over time (prices)", ylab="%")
lines(zoo(BAC_price_pct2), col="red")
lines(zoo(BAC_price_pct3), col="green")
lines(zoo(BAC_price_pct4), col="blue")
lines(zoo(BAC_price_pct5), col="lightblue")
legend(x="topleft", legend=c("7:00-9:29", "9:30-10:59", "11:00-14:29", "14:30-15:59", "16:00-18:00"),
    col=c("black", "red", "green", "blue", "lightblue"), lwd=1, bty="n", horiz=TRUE, text.width=70)

BAC_pct_df <- data.frame(
    "7:00-9:29" = as.numeric(BAC_price_pct1),
    "9:30-10:59" = as.numeric(BAC_price_pct2),
    "11:00-14:29" = as.numeric(BAC_price_pct3),
    "14:30-15:59" = as.numeric(BAC_price_pct4),
    "16:00-18:00" = as.numeric(BAC_price_pct5),
    check.names=FALSE)
boxplot(BAC_pct_df, main="BAC: Intraday RV % share of daily RV", ylab="%",
    col=c("black", "red", "green", "blue", "lightblue"))

#MSFT
par(mfrow=c(2,1))

plot.zoo(MSFT_price_pct1, main="MSFT: Intraday RV % share of daily RV over time (prices)", ylab="%")
lines(zoo(MSFT_price_pct2), col="red")
lines(zoo(MSFT_price_pct3), col="green")
lines(zoo(MSFT_price_pct4), col="blue")
lines(zoo(MSFT_price_pct5), col="lightblue")
legend(x="topleft", legend=c("7:00-9:29", "9:30-10:59", "11:00-14:29", "14:30-15:59", "16:00-18:00"),
    col=c("black", "red", "green", "blue", "lightblue"), lwd=1, bty="n", horiz=TRUE, text.width=70
)


#same treatment as in task 7
MSFT_price_pct_merged <- cbind(MSFT_price_pct1, MSFT_price_pct2, MSFT_price_pct3, MSFT_price_pct4, MSFT_price_pct5)
MSFT_price_pct_df <- as.data.frame(MSFT_price_pct_merged)
colnames(MSFT_price_pct_df) <- c("7:00-9:29", "9:30-10:59", "11:00-14:29", "14:30-15:59", "16:00-18:00")

boxplot(MSFT_price_pct_df, main="MSFT: Intraday RV % share of daily RV (prices)", ylab="%",
    col=c("black", "red", "green", "blue", "lightblue"))

#XOM
par(mfrow=c(2,1))

plot.zoo(XOM_price_pct1, main="XOM: Intraday RV % share of daily RV over time (prices)", ylab="%")
lines(zoo(XOM_price_pct2), col="red")
lines(zoo(XOM_price_pct3), col="green")
lines(zoo(XOM_price_pct4), col="blue")
lines(zoo(XOM_price_pct5), col="lightblue")
legend(x="topleft", legend=c("7:00-9:29", "9:30-10:59", "11:00-14:29", "14:30-15:59", "16:00-18:00"),
    col=c("black", "red", "green", "blue", "lightblue"), lwd=1, bty="n", horiz=TRUE, text.width=200
)

XOM_price_pct_merged <- cbind(XOM_price_pct1, XOM_price_pct2, XOM_price_pct3, XOM_price_pct4, XOM_price_pct5)
XOM_price_pct_df <- as.data.frame(XOM_price_pct_merged)
colnames(XOM_price_pct_df) <- c("7:00-9:29", "9:30-10:59", "11:00-14:29", "14:30-15:59", "16:00-18:00")

boxplot(XOM_price_pct_df, main="XOM: Intraday RV % share of daily RV (prices)", ylab="%",
    col=c("black", "red", "green", "blue", "lightblue"))

#BPV from 1min prices (full day)
BAC_BPV <- rBPCov(rData=BAC_xts, makeReturns=TRUE)
MSFT_BPV <- rBPCov(rData=MSFT_xts, makeReturns=TRUE)
XOM_BPV <- rBPCov(rData=XOM_xts, makeReturns=TRUE)

#MedRV from 1min prices (full day)
BAC_MedRV <- rMedRVar(rData=BAC_xts, makeReturns=TRUE)
MSFT_MedRV <- rMedRVar(rData=MSFT_xts, makeReturns=TRUE)
XOM_MedRV <- rMedRVar(rData=XOM_xts, makeReturns=TRUE)


#reindex for alignment purposes (ex. BAC_daily_RV - BAC_BPV): drop timestamp
index(BAC_BPV) <- as.Date(index(BAC_BPV))
index(MSFT_BPV) <- as.Date(index(MSFT_BPV))
index(XOM_BPV) <- as.Date(index(XOM_BPV))

index(BAC_MedRV) <- as.Date(index(BAC_MedRV))
index(MSFT_MedRV) <- as.Date(index(MSFT_MedRV))
index(XOM_MedRV) <- as.Date(index(XOM_MedRV))

#testing for jumps (JT = jump test)
#BPV
BAC_BPV_JT <- BNSjumpTest(BAC_xts, IVestimator="BV", IQestimator="TP", makeReturns=TRUE)
MSFT_BPV_JT <- BNSjumpTest(MSFT_xts, IVestimator="BV", IQestimator="TP", makeReturns=TRUE)
XOM_BPV_JT <- BNSjumpTest(XOM_xts, IVestimator="BV", IQestimator="TP", makeReturns=TRUE)


#MedRV
BAC_MedRV_JT <- BNSjumpTest(BAC_xts, IVestimator="rMedRVar", IQestimator="rMedRQuar", makeReturns=TRUE)
MSFT_MedRV_JT <- BNSjumpTest(MSFT_xts, IVestimator="rMedRVar", IQestimator="rMedRQuar", makeReturns=TRUE)
XOM_MedRV_JT <- BNSjumpTest(XOM_xts, IVestimator="rMedRVar", IQestimator="rMedRQuar", makeReturns=TRUE)

head(BAC_MedRV_JT, 3)

#create a jump indicator I (1 = signif. jump, 0 = not)
#BPV
BAC_BPV_I <- BAC_BPV_JT[, "p.value"] < 0.05 #take the signif p-values
MSFT_BPV_I <- MSFT_BPV_JT[, "p.value"] < 0.05
XOM_BPV_I <- XOM_BPV_JT[, "p.value"] < 0.05

index(BAC_BPV_I) <- as.Date(index(BAC_BPV_I)) #drop the timestamp - needed for difference step (identific of jumps)
index(MSFT_BPV_I) <- as.Date(index(MSFT_BPV_I))
index(XOM_BPV_I) <- as.Date(index(XOM_BPV_I))

#MedRV
BAC_MedRV_I <- BAC_MedRV_JT[, "p.value"] < 0.05
MSFT_MedRV_I <- MSFT_MedRV_JT[, "p.value"] < 0.05
XOM_MedRV_I <- XOM_MedRV_JT[, "p.value"] < 0.05

index(BAC_MedRV_I) <- as.Date(index(BAC_MedRV_I))
index(MSFT_MedRV_I) <- as.Date(index(MSFT_MedRV_I))
index(XOM_MedRV_I) <- as.Date(index(XOM_MedRV_I))

#identify significant jumps
#BPV
BAC_BPV_J <- (BAC_daily_RV - BAC_BPV) * BAC_BPV_I #xts of signif jump magnitude or 0s
MSFT_BPV_J <- (MSFT_daily_RV - MSFT_BPV) * MSFT_BPV_I
XOM_BPV_J <- (XOM_daily_RV - XOM_BPV) * XOM_BPV_I
head(BAC_BPV_J)

#MedRV
BAC_MedRV_J <- (BAC_daily_RV - BAC_MedRV) * BAC_MedRV_I
MSFT_MedRV_J <- (MSFT_daily_RV - MSFT_MedRV) * MSFT_MedRV_I
XOM_MedRV_J <- (XOM_daily_RV - XOM_MedRV) * XOM_MedRV_I


#Comparison of RV estimates (without jumps vs with jumps)
options(repr.plot.height=14, repr.plot.width=20)
par(mfrow=c(3,2))

# BAC
plot.zoo(BAC_daily_RV, main="BAC: RV vs BPV vs MedRV (no jumps)", col="blue")
lines(zoo(BAC_MedRV), col="red")
lines(zoo(BAC_BPV), col="green")
legend("top", legend=c("RV", "BPV", "MedRV"), col=c("blue", "green", "red"),
    lwd=2, bty="n", horiz=TRUE, cex=1.2, text.width=70)

plot.zoo(BAC_daily_RV, main="BAC: RV vs BPV vs MedRV (with jumps)", col="blue")
lines(zoo(BAC_MedRV + BAC_MedRV_J), col="red")
lines(zoo(BAC_BPV + BAC_BPV_J), col="green")
legend("top", legend=c("RV", "BPV", "MedRV"), col=c("blue", "green", "red"),
    lwd=2, bty="n", horiz=TRUE, cex=1.2, text.width=70)


# MSFT
plot.zoo(MSFT_daily_RV, main="MSFT: RV vs BPV vs MedRV (no jumps)", col="blue")
lines(zoo(MSFT_MedRV), col="red")
lines(zoo(MSFT_BPV), col="green")
legend("top", legend=c("RV", "BPV", "MedRV"), col=c("blue", "green", "red"),
    lwd=2, bty="n", horiz=TRUE, cex=1.2, text.width=70)

plot.zoo(MSFT_daily_RV, main="MSFT: RV vs BPV vs MedRV (with jumps)", col="blue")
lines(zoo(MSFT_MedRV + MSFT_MedRV_J), col="red")
lines(zoo(MSFT_BPV + MSFT_BPV_J), col="green")
legend("top", legend=c("RV", "BPV", "MedRV"), col=c("blue", "green", "red"),
    lwd=2, bty="n", horiz=TRUE, cex=1.2, text.width=70)


# XOM
plot.zoo(XOM_daily_RV, main="XOM: RV vs BPV vs MedRV (no jumps)", col="blue")
lines(zoo(XOM_MedRV), col="red")
lines(zoo(XOM_BPV), col="green")
legend("top", legend=c("RV", "BPV", "MedRV"), col=c("blue", "green", "red"),
    lwd=2, bty="n", horiz=TRUE, cex=1.2, text.width=70)

plot.zoo(XOM_daily_RV, main="XOM: RV vs BPV vs MedRV (with jumps)", col="blue")
lines(zoo(XOM_MedRV + XOM_MedRV_J), col="red")
lines(zoo(XOM_BPV + XOM_BPV_J), col="green")
legend("top", legend=c("RV", "BPV", "MedRV"), col=c("blue", "green", "red"),
    lwd=2, bty="n", horiz=TRUE, cex=1.2, text.width=70)

#Comparison of the differences: RV - BPV and RV - MedRV
par(mfrow=c(3,1))

plot.zoo(BAC_daily_RV - BAC_BPV, main="BAC: RV - BPV vs RV - MedRV", ylim=c(-0.003, 0.0025))
lines(zoo(BAC_daily_RV - BAC_MedRV), col="red", lwd=1)
legend("top", legend=c("RV - BPV", "RV - MedRV"),
       col=c("black", "red"), lwd=2, bty="n", horiz=TRUE)

plot.zoo(MSFT_daily_RV - MSFT_BPV, main="MSFT: RV - BPV vs RV - MedRV", ylim=c(-0.003, 0.0025))
lines(zoo(MSFT_daily_RV - MSFT_MedRV), col="red", lwd=1)
legend("top", legend=c("RV - BPV", "RV - MedRV"),
       col=c("black", "red"), lwd=2, bty="n", horiz=TRUE)

plot.zoo(XOM_daily_RV - XOM_BPV, main="XOM: RV - BPV vs RV - MedRV", ylim=c(-0.003, 0.0025))
lines(zoo(XOM_daily_RV - XOM_MedRV), col="red", lwd=1)
legend("top", legend=c("RV - BPV", "RV - MedRV"),
       col=c("black", "red"), lwd=2, bty="n", horiz=TRUE)

#visualisation of significant jump variance 

par(mfrow=c(3,1))

plot.zoo(BAC_BPV_J, main="BAC: Significant Jumps")
lines(zoo(BAC_MedRV_J), col="red", lwd=1)
legend("top", legend=c("BPV jumps", "MedRV jumps"),
       col=c("black", "red"), lwd=2, bty="n", horiz=TRUE)

plot.zoo(MSFT_BPV_J, main="MSFT: Significant Jumps")
lines(zoo(MSFT_MedRV_J), col="red", lwd=1)
legend("top", legend=c("BPV jumps", "MedRV jumps"),
       col=c("black", "red"), lwd=2, bty="n", horiz=TRUE)

plot.zoo(XOM_BPV_J, main="XOM: Significant Jumps")
lines(zoo(XOM_MedRV_J), col="red", lwd=1)
legend("top", legend=c("BPV jumps", "MedRV jumps"),
       col=c("black", "red"), lwd=2, bty="n", horiz=TRUE)

#We calculate daily returns by summing intraday log returns

BAC_daily_ret <- xts(unlist( #xts needs a vector
    lapply(split(BAC_ret, as.Date(index(BAC_ret))), sum)), #split returns per day and sum
    order.by=unique(as.Date(index(BAC_ret))) #order result by days, not intraday timestamps
)

MSFT_daily_ret <- xts(
    unlist(lapply(split(MSFT_ret, as.Date(index(MSFT_ret))), sum)), 
    order.by=unique(as.Date(index(MSFT_ret)))
)

XOM_daily_ret <- xts(
    unlist(lapply(split(XOM_ret, as.Date(index(XOM_ret))), sum)), 
    order.by=unique(as.Date(index(XOM_ret)))
)

head(BAC_daily_ret, 3)

#fitting the GARCH models
garchspec <- ugarchspec(
    mean.model=list(armaOrder=c(0,0)), 
    variance.model=list(garchOrder=c(1,1))
)

BAC_garch <- ugarchfit(garchspec, BAC_daily_ret)
MSFT_garch <- ugarchfit(garchspec, MSFT_daily_ret)
XOM_garch <- ugarchfit(garchspec, XOM_daily_ret)


#plot daily RVol vs Sigma GARCH
options(repr.plot.height=10, repr.plot.width=10)
par(mfrow=c(3,1))

#BAC
plot.zoo(sqrt(BAC_daily_RV), main="BAC: RVol vs GARCH(1,1) cond. vola", col="black")
lines(zoo(sigma(BAC_garch)), col="red")
legend("top", legend=c("RVol", "GARCH(1,1)"), col=c("black", "red"), lwd=1, bty="n", horiz=TRUE)

#MSFT
plot.zoo(sqrt(MSFT_daily_RV), main="MSFT: RVol vs GARCH(1,1) cond. vola", col="black")
lines(zoo(sigma(MSFT_garch)), col="red")
legend("top", legend=c("RVol", "GARCH(1,1)"), col=c("black", "red"), lwd=1, bty="n", horiz=TRUE)

#XOM
plot.zoo(sqrt(XOM_daily_RV), main="XOM: RVol vs GARCH(1,1) cond. vola", col="black")
lines(zoo(sigma(XOM_garch)), col="red")
legend("top", legend=c("RVol", "GARCH(1,1)"), col=c("black", "red"), lwd=1, bty="n", horiz=TRUE)

#convert the 1-minute prices to 5-minute prices using last price 
#observed at each interval

ep_BAC <- endpoints(BAC_xts, on="minutes", k=5)
ep_MSFT <- endpoints(MSFT_xts, on="minutes", k=5)
ep_XOM <- endpoints(XOM_xts, on="minutes", k=5)

BAC_5min <- period.apply(BAC_xts, INDEX=ep_BAC, 
                         FUN=function(x) tail(x, 1))
MSFT_5min <- period.apply(MSFT_xts, INDEX=ep_MSFT, 
                          FUN=function(x) tail(x, 1))
XOM_5min <- period.apply(XOM_xts, INDEX=ep_XOM, 
                         FUN=function(x) tail(x, 1))

#quick check that the conversion looks reasonable
head(BAC_5min)
head(MSFT_5min)
head(XOM_5min)

#the hours should still be 07:00-18:00 since these are derived from
#the 1-minute data after filtering
range(format(index(BAC_5min), "%H:%M:%S"))
range(format(index(MSFT_5min), "%H:%M:%S"))
range(format(index(XOM_5min), "%H:%M:%S"))

#plot to get a feel for the 5-min price series
options(repr.plot.height=8, repr.plot.width=18)
par(mfrow=c(3,1))
plot.xts(BAC_5min, main="BAC 5-min prices")
plot.xts(MSFT_5min, main="MSFT 5-min prices")
plot.xts(XOM_5min, main="XOM 5-min prices")

#calculate intraday log-returns on a day-to-day basis (same logic as Problem 1)
#this avoids treating overnight price changes as intraday returns
BAC_ret5 <- do.call(rbind, lapply(split(BAC_5min, as.Date(index(BAC_5min))),
    function(intraday){diff(log(intraday))}))

MSFT_ret5 <- do.call(rbind, lapply(split(MSFT_5min, as.Date(index(MSFT_5min))),
    function(intraday){diff(log(intraday))}))

XOM_ret5 <- do.call(rbind, lapply(split(XOM_5min, as.Date(index(XOM_5min))),
    function(intraday){diff(log(intraday))}))

BAC_ret5 <- as.xts(BAC_ret5)
MSFT_ret5 <- as.xts(MSFT_ret5)
XOM_ret5 <- as.xts(XOM_ret5)

#plot 5-min returns
par(mfrow=c(3,1))
plot.xts(BAC_ret5, main="BAC 5-min intraday returns")
plot.xts(MSFT_ret5, main="MSFT 5-min intraday returns")
plot.xts(XOM_ret5, main="XOM 5-min intraday returns")

#compare RV from prices vs RV from returns at 5-min frequency
#same analysis is performed as Problem 1 step 4

BAC_price_RV_5 <- rCov(BAC_5min, makeReturns=TRUE)
MSFT_price_RV_5 <- rCov(MSFT_5min, makeReturns=TRUE)
XOM_price_RV_5 <- rCov(XOM_5min, makeReturns=TRUE)

BAC_ret_RV_5 <- rCov(BAC_ret5, makeReturns=FALSE)
MSFT_ret_RV_5 <- rCov(MSFT_ret5, makeReturns=FALSE)
XOM_ret_RV_5 <- rCov(XOM_ret5, makeReturns=FALSE)

options(repr.plot.height=10, repr.plot.width=12)
par(mfrow=c(3,1))
plot.zoo(BAC_price_RV_5 - BAC_ret_RV_5, main="BAC 5-min: RV(prices) - RV(returns)", col="blue")
plot.zoo(MSFT_price_RV_5 - MSFT_ret_RV_5, main="MSFT 5-min: RV(prices) - RV(returns)", col="darkgreen")
plot.zoo(XOM_price_RV_5 - XOM_ret_RV_5, main="XOM 5-min: RV(prices) - RV(returns)", col="red")

#compute sub-period RV from 5-minute returns using the same time blocks as previously

#BAC
BAC_RV1_5 <- rCov(filter_hours(BAC_ret5, "07:00:00", "09:29:00"), 
                  makeReturns=FALSE)
BAC_RV2_5 <- rCov(filter_hours(BAC_ret5, "09:30:00", "10:59:00"), 
                  makeReturns=FALSE)
BAC_RV3_5 <- rCov(filter_hours(BAC_ret5, "11:00:00", "14:29:00"), 
                  makeReturns=FALSE)
BAC_RV4_5 <- rCov(filter_hours(BAC_ret5, "14:30:00", "15:59:00"), 
                  makeReturns=FALSE)
BAC_RV5_5 <- rCov(filter_hours(BAC_ret5, "16:00:00", "18:00:00"), 
                  makeReturns=FALSE)

#MSFT
MSFT_RV1_5 <- rCov(filter_hours(MSFT_ret5, "07:00:00", "09:29:00"), 
                   makeReturns=FALSE)
MSFT_RV2_5 <- rCov(filter_hours(MSFT_ret5, "09:30:00", "10:59:00"), 
                   makeReturns=FALSE)
MSFT_RV3_5 <- rCov(filter_hours(MSFT_ret5, "11:00:00", "14:29:00"), 
                   makeReturns=FALSE)
MSFT_RV4_5 <- rCov(filter_hours(MSFT_ret5, "14:30:00", "15:59:00"), 
                   makeReturns=FALSE)
MSFT_RV5_5 <- rCov(filter_hours(MSFT_ret5, "16:00:00", "18:00:00"), 
                   makeReturns=FALSE)

#XOM
XOM_RV1_5 <- rCov(filter_hours(XOM_ret5, "07:00:00", "09:29:00"), 
                  makeReturns=FALSE)
XOM_RV2_5 <- rCov(filter_hours(XOM_ret5, "09:30:00", "10:59:00"), 
                  makeReturns=FALSE)
XOM_RV3_5 <- rCov(filter_hours(XOM_ret5, "11:00:00", "14:29:00"), 
                  makeReturns=FALSE)
XOM_RV4_5 <- rCov(filter_hours(XOM_ret5, "14:30:00", "15:59:00"), 
                  makeReturns=FALSE)
XOM_RV5_5 <- rCov(filter_hours(XOM_ret5, "16:00:00", "18:00:00"), 
                  makeReturns=FALSE)

#plot the five RV blocks together for each stock
options(repr.plot.height=14, repr.plot.width=14)
par(mfrow=c(3,1))

plot.zoo(BAC_RV1_5, main="BAC 5-min: Intraday RV by sub-period")
lines(zoo(BAC_RV2_5), col="red")
lines(zoo(BAC_RV3_5), col="green")
lines(zoo(BAC_RV4_5), col="blue")
lines(zoo(BAC_RV5_5), col="lightblue")
legend("top", legend=c("7:00-9:29","9:30-10:59","11:00-14:29","14:30-15:59","16:00-18:00"),
    col=c("black","red","green","blue","lightblue"), lwd=1, bty="n", horiz=TRUE)

plot.zoo(MSFT_RV1_5, main="MSFT 5-min: Intraday RV by sub-period")
lines(zoo(MSFT_RV2_5), col="red")
lines(zoo(MSFT_RV3_5), col="green")
lines(zoo(MSFT_RV4_5), col="blue")
lines(zoo(MSFT_RV5_5), col="lightblue")
legend("top", legend=c("7:00-9:29","9:30-10:59","11:00-14:29","14:30-15:59","16:00-18:00"),
    col=c("black","red","green","blue","lightblue"), lwd=1, bty="n", horiz=TRUE)

plot.zoo(XOM_RV1_5, main="XOM 5-min: Intraday RV by sub-period")
lines(zoo(XOM_RV2_5), col="red")
lines(zoo(XOM_RV3_5), col="green")
lines(zoo(XOM_RV4_5), col="blue")
lines(zoo(XOM_RV5_5), col="lightblue")
legend("top", legend=c("7:00-9:29","9:30-10:59","11:00-14:29","14:30-15:59","16:00-18:00"),
    col=c("black","red","green","blue","lightblue"), lwd=1, bty="n", horiz=TRUE)

#daily RV from 5 min returns
BAC_daily_RV_5 <- rCov(BAC_ret5, makeReturns=FALSE)
MSFT_daily_RV_5 <- rCov(MSFT_ret5, makeReturns=FALSE)
XOM_daily_RV_5 <- rCov(XOM_ret5, makeReturns=FALSE)

#keep only the date so the daily and sub-period series align
index(BAC_daily_RV_5) <- as.Date(index(BAC_daily_RV_5))
index(MSFT_daily_RV_5) <- as.Date(index(MSFT_daily_RV_5))
index(XOM_daily_RV_5) <- as.Date(index(XOM_daily_RV_5))

index(BAC_RV1_5) <- as.Date(index(BAC_RV1_5))
index(BAC_RV2_5) <- as.Date(index(BAC_RV2_5))
index(BAC_RV3_5) <- as.Date(index(BAC_RV3_5))
index(BAC_RV4_5) <- as.Date(index(BAC_RV4_5))
index(BAC_RV5_5) <- as.Date(index(BAC_RV5_5))

index(MSFT_RV1_5) <- as.Date(index(MSFT_RV1_5))
index(MSFT_RV2_5) <- as.Date(index(MSFT_RV2_5))
index(MSFT_RV3_5) <- as.Date(index(MSFT_RV3_5))
index(MSFT_RV4_5) <- as.Date(index(MSFT_RV4_5))
index(MSFT_RV5_5) <- as.Date(index(MSFT_RV5_5))

index(XOM_RV1_5) <- as.Date(index(XOM_RV1_5))
index(XOM_RV2_5) <- as.Date(index(XOM_RV2_5))
index(XOM_RV3_5) <- as.Date(index(XOM_RV3_5))
index(XOM_RV4_5) <- as.Date(index(XOM_RV4_5))
index(XOM_RV5_5) <- as.Date(index(XOM_RV5_5))

#sum up the five sub-period RVs per stock
BAC_RV_sum_5 <- BAC_RV1_5 + BAC_RV2_5 + BAC_RV3_5 + BAC_RV4_5 + BAC_RV5_5
MSFT_RV_sum_5 <- MSFT_RV1_5 + MSFT_RV2_5 + MSFT_RV3_5 + MSFT_RV4_5 + MSFT_RV5_5
XOM_RV_sum_5 <- XOM_RV1_5 + XOM_RV2_5 + XOM_RV3_5 + XOM_RV4_5 + XOM_RV5_5

#plot the difference - should be floating point noise only (same as Problem 1 step 6)
options(repr.plot.height=10, repr.plot.width=14)
par(mfrow=c(3,1))
plot.zoo(BAC_daily_RV_5 - BAC_RV_sum_5,
    main="BAC 5-min: Daily RV - Sum of Intraday RV (returns)")
plot.zoo(MSFT_daily_RV_5 - MSFT_RV_sum_5,
    main="MSFT 5-min: Daily RV - Sum of Intraday RV (returns)", col="darkgreen")
plot.zoo(XOM_daily_RV_5 - XOM_RV_sum_5,
    main="XOM 5-min: Daily RV - Sum of Intraday RV (returns)", col="red")

#each sub-period's share of daily RV: same calculation as Problem 1 step 7
BAC_pct1_5 <- BAC_RV1_5 / BAC_daily_RV_5 * 100
BAC_pct2_5 <- BAC_RV2_5 / BAC_daily_RV_5 * 100
BAC_pct3_5 <- BAC_RV3_5 / BAC_daily_RV_5 * 100
BAC_pct4_5 <- BAC_RV4_5 / BAC_daily_RV_5 * 100
BAC_pct5_5 <- BAC_RV5_5 / BAC_daily_RV_5 * 100

MSFT_pct1_5 <- MSFT_RV1_5 / MSFT_daily_RV_5 * 100
MSFT_pct2_5 <- MSFT_RV2_5 / MSFT_daily_RV_5 * 100
MSFT_pct3_5 <- MSFT_RV3_5 / MSFT_daily_RV_5 * 100
MSFT_pct4_5 <- MSFT_RV4_5 / MSFT_daily_RV_5 * 100
MSFT_pct5_5 <- MSFT_RV5_5 / MSFT_daily_RV_5 * 100

XOM_pct1_5 <- XOM_RV1_5 / XOM_daily_RV_5 * 100
XOM_pct2_5 <- XOM_RV2_5 / XOM_daily_RV_5 * 100
XOM_pct3_5 <- XOM_RV3_5 / XOM_daily_RV_5 * 100
XOM_pct4_5 <- XOM_RV4_5 / XOM_daily_RV_5 * 100
XOM_pct5_5 <- XOM_RV5_5 / XOM_daily_RV_5 * 100

#BAC: time series + boxplot
options(repr.plot.height=12, repr.plot.width=16)
par(mfrow=c(2,1))
plot.zoo(BAC_pct1_5, main="BAC 5-min: Intraday RV % share of daily RV over time", ylab="%")
lines(zoo(BAC_pct2_5), col="red")
lines(zoo(BAC_pct3_5), col="green")
lines(zoo(BAC_pct4_5), col="blue")
lines(zoo(BAC_pct5_5), col="lightblue")
legend("topleft", legend=c("7:00-9:29","9:30-10:59","11:00-14:29","14:30-15:59","16:00-18:00"),
    col=c("black","red","green","blue","lightblue"), lwd=1, bty="n", horiz=TRUE, text.width=70)

BAC_pct_df_5 <- data.frame(
    "7:00-9:29" = as.numeric(BAC_pct1_5),
    "9:30-10:59" = as.numeric(BAC_pct2_5),
    "11:00-14:29" = as.numeric(BAC_pct3_5),
    "14:30-15:59" = as.numeric(BAC_pct4_5),
    "16:00-18:00" = as.numeric(BAC_pct5_5),
    check.names=FALSE)
boxplot(BAC_pct_df_5, main="BAC 5-min: Intraday RV % share of daily RV", ylab="%",
    col=c("black","red","green","blue","lightblue"))

#MSFT
par(mfrow=c(2,1))
plot.zoo(MSFT_pct1_5, main="MSFT 5-min: Intraday RV % share of daily RV over time", ylab="%")
lines(zoo(MSFT_pct2_5), col="red")
lines(zoo(MSFT_pct3_5), col="green")
lines(zoo(MSFT_pct4_5), col="blue")
lines(zoo(MSFT_pct5_5), col="lightblue")
legend("topleft", legend=c("7:00-9:29","9:30-10:59","11:00-14:29","14:30-15:59","16:00-18:00"),
    col=c("black","red","green","blue","lightblue"), lwd=1, bty="n", horiz=TRUE, text.width=70)

#combine the five series first so the boxplot uses aligned observations
MSFT_pct_merged_5 <- cbind(MSFT_pct1_5, MSFT_pct2_5, MSFT_pct3_5, MSFT_pct4_5, MSFT_pct5_5)
MSFT_pct_df_5 <- as.data.frame(MSFT_pct_merged_5)
colnames(MSFT_pct_df_5) <- c("7:00-9:29","9:30-10:59","11:00-14:29","14:30-15:59","16:00-18:00")
boxplot(MSFT_pct_df_5, main="MSFT 5-min: Intraday RV % share of daily RV", ylab="%",
    col=c("black","red","green","blue","lightblue"))

#XOM
par(mfrow=c(2,1))
plot.zoo(XOM_pct1_5, main="XOM 5-min: Intraday RV % share of daily RV over time", ylab="%")
lines(zoo(XOM_pct2_5), col="red")
lines(zoo(XOM_pct3_5), col="green")
lines(zoo(XOM_pct4_5), col="blue")
lines(zoo(XOM_pct5_5), col="lightblue")
legend("topleft", legend=c("7:00-9:29","9:30-10:59","11:00-14:29","14:30-15:59","16:00-18:00"),
    col=c("black","red","green","blue","lightblue"), lwd=1, bty="n", horiz=TRUE, text.width=200)

XOM_pct_merged_5 <- cbind(XOM_pct1_5, XOM_pct2_5, XOM_pct3_5, XOM_pct4_5, XOM_pct5_5)
XOM_pct_df_5 <- as.data.frame(XOM_pct_merged_5)
colnames(XOM_pct_df_5) <- c("7:00-9:29","9:30-10:59","11:00-14:29","14:30-15:59","16:00-18:00")
boxplot(XOM_pct_df_5, main="XOM 5-min: Intraday RV % share of daily RV", ylab="%",
    col=c("black","red","green","blue","lightblue"))

#compute sub-period RV directly from 5-minute prices

#days with only one price inside a block have to be removed,
#otherwise returns cannot be formed within that block

#BAC
BAC_price_RV1_5 <- rCov(filter_min_obs(BAC_5min, "07:00:00", "09:29:00"), makeReturns=TRUE)
BAC_price_RV2_5 <- rCov(filter_min_obs(BAC_5min, "09:30:00", "10:59:00"), makeReturns=TRUE)
BAC_price_RV3_5 <- rCov(filter_min_obs(BAC_5min, "11:00:00", "14:29:00"), makeReturns=TRUE)
BAC_price_RV4_5 <- rCov(filter_min_obs(BAC_5min, "14:30:00", "15:59:00"), makeReturns=TRUE)
BAC_price_RV5_5 <- rCov(filter_min_obs(BAC_5min, "16:00:00", "18:00:00"), makeReturns=TRUE)

#MSFT
MSFT_price_RV1_5 <- rCov(filter_min_obs(MSFT_5min, "07:00:00", "09:29:00"), makeReturns=TRUE)
MSFT_price_RV2_5 <- rCov(filter_min_obs(MSFT_5min, "09:30:00", "10:59:00"), makeReturns=TRUE)
MSFT_price_RV3_5 <- rCov(filter_min_obs(MSFT_5min, "11:00:00", "14:29:00"), makeReturns=TRUE)
MSFT_price_RV4_5 <- rCov(filter_min_obs(MSFT_5min, "14:30:00", "15:59:00"), makeReturns=TRUE)
MSFT_price_RV5_5 <- rCov(filter_min_obs(MSFT_5min, "16:00:00", "18:00:00"), makeReturns=TRUE)

#XOM
XOM_price_RV1_5 <- rCov(filter_min_obs(XOM_5min, "07:00:00", "09:29:00"), makeReturns=TRUE)
XOM_price_RV2_5 <- rCov(filter_min_obs(XOM_5min, "09:30:00", "10:59:00"), makeReturns=TRUE)
XOM_price_RV3_5 <- rCov(filter_min_obs(XOM_5min, "11:00:00", "14:29:00"), makeReturns=TRUE)
XOM_price_RV4_5 <- rCov(filter_min_obs(XOM_5min, "14:30:00", "15:59:00"), makeReturns=TRUE)
XOM_price_RV5_5 <- rCov(filter_min_obs(XOM_5min, "16:00:00", "18:00:00"), makeReturns=TRUE)

#drop timestamps for index alignment
index(BAC_price_RV1_5) <- as.Date(index(BAC_price_RV1_5))
index(BAC_price_RV2_5) <- as.Date(index(BAC_price_RV2_5))
index(BAC_price_RV3_5) <- as.Date(index(BAC_price_RV3_5))
index(BAC_price_RV4_5) <- as.Date(index(BAC_price_RV4_5))
index(BAC_price_RV5_5) <- as.Date(index(BAC_price_RV5_5))

index(MSFT_price_RV1_5) <- as.Date(index(MSFT_price_RV1_5))
index(MSFT_price_RV2_5) <- as.Date(index(MSFT_price_RV2_5))
index(MSFT_price_RV3_5) <- as.Date(index(MSFT_price_RV3_5))
index(MSFT_price_RV4_5) <- as.Date(index(MSFT_price_RV4_5))
index(MSFT_price_RV5_5) <- as.Date(index(MSFT_price_RV5_5))

index(XOM_price_RV1_5) <- as.Date(index(XOM_price_RV1_5))
index(XOM_price_RV2_5) <- as.Date(index(XOM_price_RV2_5))
index(XOM_price_RV3_5) <- as.Date(index(XOM_price_RV3_5))
index(XOM_price_RV4_5) <- as.Date(index(XOM_price_RV4_5))
index(XOM_price_RV5_5) <- as.Date(index(XOM_price_RV5_5))

#sum the five sub-period price-based RVs
BAC_price_RV_sum_5  <- BAC_price_RV1_5 + BAC_price_RV2_5  + BAC_price_RV3_5  + BAC_price_RV4_5  + BAC_price_RV5_5
MSFT_price_RV_sum_5 <- MSFT_price_RV1_5 + MSFT_price_RV2_5 + MSFT_price_RV3_5 + MSFT_price_RV4_5 + MSFT_price_RV5_5
XOM_price_RV_sum_5 <- XOM_price_RV1_5 + XOM_price_RV2_5 + XOM_price_RV3_5 + XOM_price_RV4_5 + XOM_price_RV5_5

#plot sub-period RV from prices (5-min)
options(repr.plot.height=14, repr.plot.width=14)
par(mfrow=c(3,1))

plot.zoo(BAC_price_RV1_5, main="BAC 5-min: Intraday RV (prices) by sub-period")
lines(zoo(BAC_price_RV2_5), col="red")
lines(zoo(BAC_price_RV3_5), col="green")
lines(zoo(BAC_price_RV4_5), col="blue")
lines(zoo(BAC_price_RV5_5), col="lightblue")
legend("top", legend=c("7:00-9:29","9:30-10:59","11:00-14:29","14:30-15:59","16:00-18:00"),
    col=c("black","red","green","blue","lightblue"), lwd=1, bty="n", horiz=TRUE)

plot.zoo(MSFT_price_RV1_5, main="MSFT 5-min: Intraday RV (prices) by sub-period")
lines(zoo(MSFT_price_RV2_5), col="red")
lines(zoo(MSFT_price_RV3_5), col="green")
lines(zoo(MSFT_price_RV4_5), col="blue")
lines(zoo(MSFT_price_RV5_5), col="lightblue")
legend("top", legend=c("7:00-9:29","9:30-10:59","11:00-14:29","14:30-15:59","16:00-18:00"),
    col=c("black","red","green","blue","lightblue"), lwd=1, bty="n", horiz=TRUE)

plot.zoo(XOM_price_RV1_5, main="XOM 5-min: Intraday RV (prices) by sub-period")
lines(zoo(XOM_price_RV2_5), col="red")
lines(zoo(XOM_price_RV3_5), col="green")
lines(zoo(XOM_price_RV4_5), col="blue")
lines(zoo(XOM_price_RV5_5), col="lightblue")
legend("top", legend=c("7:00-9:29","9:30-10:59","11:00-14:29","14:30-15:59","16:00-18:00"),
    col=c("black","red","green","blue","lightblue"), lwd=1, bty="n", horiz=TRUE)

#compare daily RV (from prices) with the sum of the price-based sub-period RVs
#using price-based daily RV for consistency with the sub-period price-based RVs

#align price-based daily RV to Date index
index(BAC_price_RV_5) <- as.Date(index(BAC_price_RV_5))
index(MSFT_price_RV_5) <- as.Date(index(MSFT_price_RV_5))
index(XOM_price_RV_5) <- as.Date(index(XOM_price_RV_5))

options(repr.plot.height=10, repr.plot.width=14)
par(mfrow=c(3,1))
plot.zoo(BAC_price_RV_5 - BAC_price_RV_sum_5,
    main="BAC 5-min: Daily RV(prices) - Sum of Intraday RV(prices)")
plot.zoo(MSFT_price_RV_5 - MSFT_price_RV_sum_5,
    main="MSFT 5-min: Daily RV(prices) - Sum of Intraday RV(prices)", col="darkgreen")
plot.zoo(XOM_price_RV_5 - XOM_price_RV_sum_5,
    main="XOM 5-min: Daily RV(prices) - Sum of Intraday RV(prices)", col="red")

#share of each sub-period price-based RV in total daily price-based RV
BAC_price_pct1_5 <- BAC_price_RV1_5 / BAC_price_RV_5 * 100
BAC_price_pct2_5 <- BAC_price_RV2_5 / BAC_price_RV_5 * 100
BAC_price_pct3_5 <- BAC_price_RV3_5 / BAC_price_RV_5 * 100
BAC_price_pct4_5 <- BAC_price_RV4_5 / BAC_price_RV_5 * 100
BAC_price_pct5_5 <- BAC_price_RV5_5 / BAC_price_RV_5 * 100

MSFT_price_pct1_5 <- MSFT_price_RV1_5 / MSFT_price_RV_5 * 100
MSFT_price_pct2_5 <- MSFT_price_RV2_5 / MSFT_price_RV_5 * 100
MSFT_price_pct3_5 <- MSFT_price_RV3_5 / MSFT_price_RV_5 * 100
MSFT_price_pct4_5 <- MSFT_price_RV4_5 / MSFT_price_RV_5 * 100
MSFT_price_pct5_5 <- MSFT_price_RV5_5 / MSFT_price_RV_5 * 100

XOM_price_pct1_5 <- XOM_price_RV1_5 / XOM_price_RV_5 * 100
XOM_price_pct2_5 <- XOM_price_RV2_5 / XOM_price_RV_5 * 100
XOM_price_pct3_5 <- XOM_price_RV3_5 / XOM_price_RV_5 * 100
XOM_price_pct4_5 <- XOM_price_RV4_5 / XOM_price_RV_5 * 100
XOM_price_pct5_5 <- XOM_price_RV5_5 / XOM_price_RV_5 * 100

#BAC price based boxplot
options(repr.plot.height=12, repr.plot.width=16)
par(mfrow=c(2,1))

plot.zoo(BAC_price_pct1_5, main="BAC 5-min: Intraday RV % share (prices) over time", ylab="%")
lines(zoo(BAC_price_pct2_5), col="red")
lines(zoo(BAC_price_pct3_5), col="green")
lines(zoo(BAC_price_pct4_5), col="blue")
lines(zoo(BAC_price_pct5_5), col="lightblue")
legend("topleft", legend=c("7:00-9:29","9:30-10:59","11:00-14:29","14:30-15:59","16:00-18:00"),
    col=c("black","red","green","blue","lightblue"), lwd=1, bty="n", horiz=TRUE, text.width=70)

BAC_price_pct_df_5 <- data.frame(
    "7:00-9:29" = as.numeric(BAC_price_pct1_5),
    "9:30-10:59" = as.numeric(BAC_price_pct2_5),
    "11:00-14:29" = as.numeric(BAC_price_pct3_5),
    "14:30-15:59" = as.numeric(BAC_price_pct4_5),
    "16:00-18:00" = as.numeric(BAC_price_pct5_5),
    check.names=FALSE)
boxplot(BAC_price_pct_df_5, main="BAC 5-min: Intraday RV % share (prices)", ylab="%",
    col=c("black","red","green","blue","lightblue"))

#MSFT
par(mfrow=c(2,1))
plot.zoo(MSFT_price_pct1_5, main="MSFT 5-min: Intraday RV % share (prices) over time", ylab="%")
lines(zoo(MSFT_price_pct2_5), col="red")
lines(zoo(MSFT_price_pct3_5), col="green")
lines(zoo(MSFT_price_pct4_5), col="blue")
lines(zoo(MSFT_price_pct5_5), col="lightblue")
legend("topleft", legend=c("7:00-9:29","9:30-10:59","11:00-14:29","14:30-15:59","16:00-18:00"),
    col=c("black","red","green","blue","lightblue"), lwd=1, bty="n", horiz=TRUE, text.width=70)

#cbind first to handle unequal obs across sub-periods
MSFT_price_pct_merged_5 <- cbind(MSFT_price_pct1_5, MSFT_price_pct2_5, MSFT_price_pct3_5, MSFT_price_pct4_5, MSFT_price_pct5_5)
MSFT_price_pct_df_5 <- as.data.frame(MSFT_price_pct_merged_5)
colnames(MSFT_price_pct_df_5) <- c("7:00-9:29","9:30-10:59","11:00-14:29","14:30-15:59","16:00-18:00")
boxplot(MSFT_price_pct_df_5, main="MSFT 5-min: Intraday RV % share (prices)", ylab="%",
    col=c("black","red","green","blue","lightblue"))

#XOM
par(mfrow=c(2,1))
plot.zoo(XOM_price_pct1_5, main="XOM 5-min: Intraday RV % share (prices) over time", ylab="%")
lines(zoo(XOM_price_pct2_5), col="red")
lines(zoo(XOM_price_pct3_5), col="green")
lines(zoo(XOM_price_pct4_5), col="blue")
lines(zoo(XOM_price_pct5_5), col="lightblue")
legend("topleft", legend=c("7:00-9:29","9:30-10:59","11:00-14:29","14:30-15:59","16:00-18:00"),
    col=c("black","red","green","blue","lightblue"), lwd=1, bty="n", horiz=TRUE, text.width=200)

XOM_price_pct_merged_5 <- cbind(XOM_price_pct1_5, XOM_price_pct2_5, XOM_price_pct3_5, XOM_price_pct4_5, XOM_price_pct5_5)
XOM_price_pct_df_5 <- as.data.frame(XOM_price_pct_merged_5)
colnames(XOM_price_pct_df_5) <- c("7:00-9:29","9:30-10:59","11:00-14:29","14:30-15:59","16:00-18:00")
boxplot(XOM_price_pct_df_5, main="XOM 5-min: Intraday RV % share (prices)", ylab="%",
    col=c("black","red","green","blue","lightblue"))

#compute BPV and MedRV from the 5-minute price series
BAC_BPV_5 <- rBPCov(rData=BAC_5min, makeReturns=TRUE)
MSFT_BPV_5 <- rBPCov(rData=MSFT_5min, makeReturns=TRUE)
XOM_BPV_5 <- rBPCov(rData=XOM_5min, makeReturns=TRUE)

BAC_MedRV_5 <- rMedRVar(rData=BAC_5min, makeReturns=TRUE)
MSFT_MedRV_5 <- rMedRVar(rData=MSFT_5min, makeReturns=TRUE)
XOM_MedRV_5 <- rMedRVar(rData=XOM_5min, makeReturns=TRUE)

#drop timestamps
index(BAC_BPV_5) <- as.Date(index(BAC_BPV_5))
index(MSFT_BPV_5) <- as.Date(index(MSFT_BPV_5))
index(XOM_BPV_5) <- as.Date(index(XOM_BPV_5))
index(BAC_MedRV_5) <- as.Date(index(BAC_MedRV_5))
index(MSFT_MedRV_5) <- as.Date(index(MSFT_MedRV_5))
index(XOM_MedRV_5) <- as.Date(index(XOM_MedRV_5))

#BNS jump tests: BPV-based
BAC_BPV_JT_5 <- BNSjumpTest(BAC_5min, IVestimator="BV", 
                            IQestimator="TP", makeReturns=TRUE)
MSFT_BPV_JT_5 <- BNSjumpTest(MSFT_5min, IVestimator="BV", 
                             IQestimator="TP", makeReturns=TRUE)
XOM_BPV_JT_5 <- BNSjumpTest(XOM_5min, IVestimator="BV", 
                            IQestimator="TP", makeReturns=TRUE)

#BNS jump tests: MedRV-based
BAC_MedRV_JT_5 <- BNSjumpTest(BAC_5min, IVestimator="rMedRVar", 
                              IQestimator="rMedRQuar", makeReturns=TRUE)
MSFT_MedRV_JT_5 <- BNSjumpTest(MSFT_5min, IVestimator="rMedRVar", 
                               IQestimator="rMedRQuar", makeReturns=TRUE)
XOM_MedRV_JT_5 <- BNSjumpTest(XOM_5min, IVestimator="rMedRVar", 
                              IQestimator="rMedRQuar", makeReturns=TRUE)

#jump indicators at 5% significance level
BAC_BPV_I_5 <- BAC_BPV_JT_5[, "p.value"] < 0.05
MSFT_BPV_I_5 <- MSFT_BPV_JT_5[, "p.value"] < 0.05
XOM_BPV_I_5 <- XOM_BPV_JT_5[, "p.value"] < 0.05
BAC_MedRV_I_5 <- BAC_MedRV_JT_5[, "p.value"] < 0.05
MSFT_MedRV_I_5 <- MSFT_MedRV_JT_5[, "p.value"] < 0.05
XOM_MedRV_I_5 <- XOM_MedRV_JT_5[, "p.value"] < 0.05

index(BAC_BPV_I_5) <- as.Date(index(BAC_BPV_I_5))
index(MSFT_BPV_I_5) <- as.Date(index(MSFT_BPV_I_5))
index(XOM_BPV_I_5) <- as.Date(index(XOM_BPV_I_5))
index(BAC_MedRV_I_5) <- as.Date(index(BAC_MedRV_I_5))
index(MSFT_MedRV_I_5) <- as.Date(index(MSFT_MedRV_I_5))
index(XOM_MedRV_I_5) <- as.Date(index(XOM_MedRV_I_5))

#significant jump magnitudes: (RV - BPV) * indicator, zeroed out on non-jump days
BAC_BPV_J_5 <- (BAC_daily_RV_5 - BAC_BPV_5) * BAC_BPV_I_5
MSFT_BPV_J_5 <- (MSFT_daily_RV_5 - MSFT_BPV_5) * MSFT_BPV_I_5
XOM_BPV_J_5 <- (XOM_daily_RV_5 - XOM_BPV_5) * XOM_BPV_I_5
BAC_MedRV_J_5 <- (BAC_daily_RV_5 - BAC_MedRV_5) * BAC_MedRV_I_5
MSFT_MedRV_J_5 <- (MSFT_daily_RV_5 - MSFT_MedRV_5) * MSFT_MedRV_I_5
XOM_MedRV_J_5 <- (XOM_daily_RV_5 - XOM_MedRV_5) * XOM_MedRV_I_5

options(repr.plot.height=14, repr.plot.width=20)
par(mfrow=c(3,2))

plot.zoo(BAC_daily_RV_5, main="BAC 5-min: RV vs BPV vs MedRV (no jumps)", col="blue")
lines(zoo(BAC_MedRV_5), col="red"); lines(zoo(BAC_BPV_5), col="green")
legend("top", legend=c("RV","BPV","MedRV"), col=c("blue","green","red"),
    lwd=2, bty="n", horiz=TRUE, cex=1.2, text.width=70)

plot.zoo(BAC_daily_RV_5, main="BAC 5-min: RV vs BPV vs MedRV (with jumps)", col="blue")
lines(zoo(BAC_MedRV_5 + BAC_MedRV_J_5), col="red")
lines(zoo(BAC_BPV_5 + BAC_BPV_J_5), col="green")
legend("top", legend=c("RV","BPV+J","MedRV+J"), col=c("blue","green","red"),
    lwd=2, bty="n", horiz=TRUE, cex=1.2, text.width=70)

plot.zoo(MSFT_daily_RV_5, main="MSFT 5-min: RV vs BPV vs MedRV (no jumps)", col="blue")
lines(zoo(MSFT_MedRV_5), col="red"); lines(zoo(MSFT_BPV_5), col="green")
legend("top", legend=c("RV","BPV","MedRV"), col=c("blue","green","red"),
    lwd=2, bty="n", horiz=TRUE, cex=1.2, text.width=70)

plot.zoo(MSFT_daily_RV_5, main="MSFT 5-min: RV vs BPV vs MedRV (with jumps)", col="blue")
lines(zoo(MSFT_MedRV_5 + MSFT_MedRV_J_5), col="red")
lines(zoo(MSFT_BPV_5 + MSFT_BPV_J_5), col="green")
legend("top", legend=c("RV","BPV+J","MedRV+J"), col=c("blue","green","red"),
    lwd=2, bty="n", horiz=TRUE, cex=1.2, text.width=70)

plot.zoo(XOM_daily_RV_5, main="XOM 5-min: RV vs BPV vs MedRV (no jumps)", col="blue")
lines(zoo(XOM_MedRV_5), col="red"); lines(zoo(XOM_BPV_5), col="green")
legend("top", legend=c("RV","BPV","MedRV"), col=c("blue","green","red"),
    lwd=2, bty="n", horiz=TRUE, cex=1.2, text.width=70)

plot.zoo(XOM_daily_RV_5, main="XOM 5-min: RV vs BPV vs MedRV (with jumps)", col="blue")
lines(zoo(XOM_MedRV_5 + XOM_MedRV_J_5), col="red")
lines(zoo(XOM_BPV_5 + XOM_BPV_J_5), col="green")
legend("top", legend=c("RV","BPV+J","MedRV+J"), col=c("blue","green","red"),
    lwd=2, bty="n", horiz=TRUE, cex=1.2, text.width=70)

#significant jump variance by estimator
par(mfrow=c(3,1))
plot.zoo(BAC_BPV_J_5, main="BAC 5-min: Significant Jumps")
lines(zoo(BAC_MedRV_J_5), col="red")
legend("top", legend=c("BPV jumps","MedRV jumps"), col=c("black","red"), lwd=2, bty="n", horiz=TRUE)

plot.zoo(MSFT_BPV_J_5, main="MSFT 5-min: Significant Jumps")
lines(zoo(MSFT_MedRV_J_5), col="red")
legend("top", legend=c("BPV jumps","MedRV jumps"), col=c("black","red"), lwd=2, bty="n", horiz=TRUE)

plot.zoo(XOM_BPV_J_5, main="XOM 5-min: Significant Jumps")
lines(zoo(XOM_MedRV_J_5), col="red")
legend("top", legend=c("BPV jumps","MedRV jumps"), col=c("black","red"), lwd=2, bty="n", horiz=TRUE)

#how many days had significant jumps at 5-min frequency?
jump_days_5 <- data.frame(
    Stock = c("BAC", "MSFT", "XOM"),
    BPV_jumps = sapply(c("BAC","MSFT","XOM"), function(t){
        i <- get(paste0(t, "_BPV_I_5"))
        paste0(sum(i), "/", nrow(i), " (", round(100*mean(i), 1), "%)")}),
    MedRV_jumps = sapply(c("BAC","MSFT","XOM"), function(t){
        i <- get(paste0(t, "_MedRV_I_5"))
        paste0(sum(i), "/", nrow(i), " (", round(100*mean(i), 1), "%)")})
)
jump_days_5

#build daily returns from the 5-minute intraday returns
BAC_daily_ret_5 <- xts(
    unlist(lapply(split(BAC_ret5, as.Date(index(BAC_ret5))), sum)),
    order.by=unique(as.Date(index(BAC_ret5))))
MSFT_daily_ret_5 <- xts(
    unlist(lapply(split(MSFT_ret5, as.Date(index(MSFT_ret5))), sum)),
    order.by=unique(as.Date(index(MSFT_ret5))))
XOM_daily_ret_5 <- xts(
    unlist(lapply(split(XOM_ret5, as.Date(index(XOM_ret5))), sum)),
    order.by=unique(as.Date(index(XOM_ret5))))

#fit ARMA(0,0)-GARCH(1,1); same spec as Problem 1
garchspec <- ugarchspec(
    mean.model=list(armaOrder=c(0,0)),
    variance.model=list(garchOrder=c(1,1)))
BAC_garch_5 <- ugarchfit(garchspec, BAC_daily_ret_5)
MSFT_garch_5 <- ugarchfit(garchspec, MSFT_daily_ret_5)
XOM_garch_5 <- ugarchfit(garchspec, XOM_daily_ret_5)

par(mfrow=c(3,1))
plot.zoo(sqrt(BAC_daily_RV_5), main="BAC 5-min: RVol vs GARCH(1,1) cond. vola", col="black")
lines(zoo(sigma(BAC_garch_5)), col="red")
legend("top", legend=c("RVol (5-min)","GARCH(1,1)"),
    col=c("black","red"), lwd=1, bty="n", horiz=TRUE)

plot.zoo(sqrt(MSFT_daily_RV_5), main="MSFT 5-min: RVol vs GARCH(1,1) cond. vola", col="black")
lines(zoo(sigma(MSFT_garch_5)), col="red")
legend("top", legend=c("RVol (5-min)","GARCH(1,1)"),
    col=c("black","red"), lwd=1, bty="n", horiz=TRUE)

plot.zoo(sqrt(XOM_daily_RV_5), main="XOM 5-min: RVol vs GARCH(1,1) cond. vola", col="black")
lines(zoo(sigma(XOM_garch_5)), col="red")
legend("top", legend=c("RVol (5-min)","GARCH(1,1)"),
    col=c("black","red"), lwd=1, bty="n", horiz=TRUE)

#check how close the 1-minute and 5-minute daily returns are
#small differences can show up if the first or last 5-minute price
#does not exactly match the 1-minute endpoint
BAC_1m_dret <- xts(unlist(lapply(split(BAC_ret, as.Date(index(BAC_ret))), sum)),
    order.by=unique(as.Date(index(BAC_ret))))
MSFT_1m_dret <- xts(unlist(lapply(split(MSFT_ret, as.Date(index(MSFT_ret))), sum)),
    order.by=unique(as.Date(index(MSFT_ret))))
XOM_1m_dret <- xts(unlist(lapply(split(XOM_ret, as.Date(index(XOM_ret))), sum)),
    order.by=unique(as.Date(index(XOM_ret))))

#find common dates and compare
BAC_cd <- intersect(index(BAC_1m_dret), index(BAC_daily_ret_5))
MSFT_cd <- intersect(index(MSFT_1m_dret), index(MSFT_daily_ret_5))
XOM_cd <- intersect(index(XOM_1m_dret), index(XOM_daily_ret_5))

ret_comparison <- data.frame(
    Stock = c("BAC", "MSFT", "XOM"),
    Max_abs_diff = c(round(max(abs(BAC_1m_dret[BAC_cd] - BAC_daily_ret_5[BAC_cd])), 8),
        round(max(abs(MSFT_1m_dret[MSFT_cd] - MSFT_daily_ret_5[MSFT_cd])), 8),
        round(max(abs(XOM_1m_dret[XOM_cd] - XOM_daily_ret_5[XOM_cd])), 8)),
    Mean_abs_diff = c(round(mean(abs(BAC_1m_dret[BAC_cd] - BAC_daily_ret_5[BAC_cd])), 8),
        round(mean(abs(MSFT_1m_dret[MSFT_cd] - MSFT_daily_ret_5[MSFT_cd])), 8),
        round(mean(abs(XOM_1m_dret[XOM_cd] - XOM_daily_ret_5[XOM_cd])), 8))
)
ret_comparison

#compare daily RV at 1-minute and 5-minute frequency
options(repr.plot.height=12, repr.plot.width=16)
par(mfrow=c(3,1))

plot.zoo(BAC_daily_RV, main="BAC: Daily RV - 1-min vs 5-min", col="black")
lines(zoo(BAC_daily_RV_5), col="red", lwd=1.5)
legend("top", legend=c("RV (1-min)","RV (5-min)"),
    col=c("black","red"), lwd=2, bty="n", horiz=TRUE)

plot.zoo(MSFT_daily_RV, main="MSFT: Daily RV - 1-min vs 5-min", col="black")
lines(zoo(MSFT_daily_RV_5), col="red", lwd=1.5)
legend("top", legend=c("RV (1-min)","RV (5-min)"),
    col=c("black","red"), lwd=2, bty="n", horiz=TRUE)

plot.zoo(XOM_daily_RV, main="XOM: Daily RV - 1-min vs 5-min", col="black")
lines(zoo(XOM_daily_RV_5), col="red", lwd=1.5)
legend("top", legend=c("RV (1-min)","RV (5-min)"),
    col=c("black","red"), lwd=2, bty="n", horiz=TRUE)

#compare realized volatility at both frequencies with GARCH volatility
par(mfrow=c(3,1))

plot.zoo(sqrt(BAC_daily_RV), main="BAC: RVol (1-min vs 5-min) vs GARCH(1,1)", col="black")
lines(zoo(sqrt(BAC_daily_RV_5)), col="red", lwd=1.5)
lines(zoo(sigma(BAC_garch)), col="blue", lwd=1.5)
legend("top", legend=c("RVol 1-min","RVol 5-min","GARCH"),
    col=c("black","red","blue"), lwd=2, bty="n", horiz=TRUE)

plot.zoo(sqrt(MSFT_daily_RV), main="MSFT: RVol (1-min vs 5-min) vs GARCH(1,1)", col="black")
lines(zoo(sqrt(MSFT_daily_RV_5)), col="red", lwd=1.5)
lines(zoo(sigma(MSFT_garch)), col="blue", lwd=1.5)
legend("top", legend=c("RVol 1-min","RVol 5-min","GARCH"),
    col=c("black","red","blue"), lwd=2, bty="n", horiz=TRUE)

plot.zoo(sqrt(XOM_daily_RV), main="XOM: RVol (1-min vs 5-min) vs GARCH(1,1)", col="black")
lines(zoo(sqrt(XOM_daily_RV_5)), col="red", lwd=1.5)
lines(zoo(sigma(XOM_garch)), col="blue", lwd=1.5)
legend("top", legend=c("RVol 1-min","RVol 5-min","GARCH"),
    col=c("black","red","blue"), lwd=2, bty="n", horiz=TRUE)

#compare BPV across the two sampling frequencies
par(mfrow=c(3,1))

plot.zoo(BAC_BPV, main="BAC: BPV - 1-min vs 5-min", col="black")
lines(zoo(BAC_BPV_5), col="red")
legend("top", legend=c("BPV 1-min","BPV 5-min"), col=c("black","red"), lwd=2, bty="n", horiz=TRUE)

plot.zoo(MSFT_BPV, main="MSFT: BPV - 1-min vs 5-min", col="black")
lines(zoo(MSFT_BPV_5), col="red")
legend("top", legend=c("BPV 1-min","BPV 5-min"), col=c("black","red"), lwd=2, bty="n", horiz=TRUE)

plot.zoo(XOM_BPV, main="XOM: BPV - 1-min vs 5-min", col="black")
lines(zoo(XOM_BPV_5), col="red")
legend("top", legend=c("BPV 1-min","BPV 5-min"), col=c("black","red"), lwd=2, bty="n", horiz=TRUE)

#jump detection ratel; expect fewer jumps at 5-min due to less noise inflating the test stat
jump_rates <- data.frame(
    Stock = c("BAC", "MSFT", "XOM"),
    BPV_1min_pct = sapply(c("BAC","MSFT","XOM"), function(t)
        round(mean(get(paste0(t,"_BPV_I")), na.rm=TRUE)*100, 1)),
    BPV_5min_pct = sapply(c("BAC","MSFT","XOM"), function(t)
        round(mean(get(paste0(t,"_BPV_I_5")), na.rm=TRUE)*100, 1))
)
jump_rates

#summary comparison across frequencies

#1.RV magnitude
rv_comparison <- data.frame(
    Stock = c("BAC", "MSFT", "XOM"),
    Mean_Ratio_1m_5m = sapply(c("BAC","MSFT","XOM"), function(ticker){
        rv1 <- get(paste0(ticker, "_daily_RV"))
        rv5 <- get(paste0(ticker, "_daily_RV_5"))
        common <- intersect(index(rv1), index(rv5))
        round(mean(rv1[common] / rv5[common], na.rm=TRUE), 4)}),
    Mean_Diff_1m_5m = sapply(c("BAC","MSFT","XOM"), function(ticker){
        rv1 <- get(paste0(ticker, "_daily_RV"))
        rv5 <- get(paste0(ticker, "_daily_RV_5"))
        common <- intersect(index(rv1), index(rv5))
        round(mean(rv1[common] - rv5[common], na.rm=TRUE), 8)})
)
print(rv_comparison)

#2.jump detection rates
jump_comparison <- data.frame(
    Stock = c("BAC", "MSFT", "XOM"),
    BPV_1min_pct = sapply(c("BAC","MSFT","XOM"), function(t)
        round(100*mean(get(paste0(t,"_BPV_I")), na.rm=TRUE), 1)),
    BPV_5min_pct = sapply(c("BAC","MSFT","XOM"), function(t)
        round(100*mean(get(paste0(t,"_BPV_I_5")), na.rm=TRUE), 1))
)
print(jump_comparison)

#3.median intraday RV share by sub-period
for (ticker in c("BAC","MSFT","XOM")){
    cat(ticker, "\n")
    share_df <- data.frame(
        period = c("7-9:29","9:30-10:59","11-14:29","14:30-15:59","16-18:00"),
        median_1min = sapply(1:5, function(i)
            round(median(get(paste0(ticker,"_pct",i)), na.rm=TRUE), 1)),
        median_5min = sapply(1:5, function(i)
            round(median(get(paste0(ticker,"_pct",i,"_5")), na.rm=TRUE), 1)))
    print(share_df)
}

#4.boundary loss: daily RV minus sum of price-based sub-period RVs
boundary_loss <- data.frame(
    Stock = c("BAC","MSFT","XOM"),
    loss_1min = sapply(c("BAC","MSFT","XOM"), function(ticker){
        rv1 <- get(paste0(ticker,"_daily_RV"))
        s1 <- get(paste0(ticker,"_price_RV_sum"))
        common <- intersect(index(rv1), index(s1))
        round(mean(rv1[common] - s1[common], na.rm=TRUE), 8)}),
    loss_5min = sapply(c("BAC","MSFT","XOM"), function(ticker){
        rv5 <- get(paste0(ticker,"_daily_RV_5"))
        s5 <- get(paste0(ticker,"_price_RV_sum_5"))
        common <- intersect(index(rv5), index(s5))
        round(mean(rv5[common] - s5[common], na.rm=TRUE), 8)})
)
print(boundary_loss)
