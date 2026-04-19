#packages
library(fst)
library(highfrequency)
library(xts)

#load timeframe
periods <- read.csv("students_HW3/73267075_periods_HW_3.csv")
periods

#func to extract periods
get_period <- function(ticker){
    row <- periods[periods$Ticker==ticker, ]
    list(start=paste0(row$Start, "-01-01"), #returns start and end
        end=paste0(row$End, "-12-31"))
}

#setwd()

#load stocks
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

BAC_xts <- BAC_xts[paste0(p_BAC$start, "/", p_BAC$end)] #xts subsetting
MSFT_xts <- MSFT_xts[paste0(p_MSFT$start, "/", p_MSFT$end)]
XOM_xts <- XOM_xts[paste0(p_XOM$start, "/", p_XOM$end)]


#filter hours of interest
BAC_xts <- BAC_xts[format(index(BAC_xts), "%H:%M:%S") >= "07:00:00" &
                   format(index(BAC_xts), "%H:%M:%S") <= "18:00:00"]
MSFT_xts <- MSFT_xts[format(index(MSFT_xts), "%H:%M:%S") >= "07:00:00" &
                     format(index(MSFT_xts), "%H:%M:%S") <= "18:00:00"]
XOM_xts <- XOM_xts[format(index(XOM_xts), "%H:%M:%S") >= "07:00:00" &
                   format(index(XOM_xts), "%H:%M:%S") <= "18:00:00"]


#plot prices
options(repr.plot.height=8, repr.plot.width=18)
par(mfrow=c(3,1))
plot.xts(BAC_xts)
plot.xts(MSFT_xts)
plot.xts(XOM_xts)

to.daily(BAC_xts)["2016-11-17/2016-11-28"] #check OHLC around the suspicious period

BAC_xts["2016-11-22"][BAC_xts["2016-11-22"] > 19.9] #check the highest values on that day

plot.xts(BAC_xts["2016-11-18/2016-11-28"]) 

BAC_xts <- BAC_xts[index(BAC_xts)!=as.POSIXct("2016-11-22 09:05:00", tz="UTC")]
plot.xts(BAC_xts["2016-11-18/2016-11-28"]) 


summary(BAC_xts)
summary(MSFT_xts)
summary(XOM_xts)

BAC_ret <- do.call(rbind, lapply(
    split(BAC_xts, as.Date(index(BAC_xts))), #split on per-day basis
    function(intraday){diff(log(intraday))}))  #calculate returns within a day

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


par(mfrow=c(3,1)) #log returns for each stock
plot.xts(BAC_ret)
plot.xts(MSFT_ret)
plot.xts(XOM_ret)

#RV from prices, makeReturns=TRUE -> overnight returns are actually not included
#rCov computes returns on per.day-basis
BAC_price_RV <- rCov(BAC_xts, makeReturns=TRUE)
MSFT_price_RV <- rCov(MSFT_xts, makeReturns=TRUE)
XOM_price_RV <- rCov(XOM_xts, makeReturns=TRUE)

#RV from log returns, makeReturns=FALSE -> overnight returns are excluded
BAC_ret_RV <- rCov(BAC_ret, makeReturns=FALSE)
MSFT_ret_RV <- rCov(MSFT_ret, makeReturns=FALSE)
XOM_ret_RV <- rCov(XOM_ret, makeReturns=FALSE)

options(repr.plot.height=10, repr.plot.width=12)
par(mfrow=c(3,1))
plot.zoo(BAC_price_RV-BAC_ret_RV, main="BAC: Difference in RV computed from prices vs returns", col="blue")
plot.zoo(MSFT_price_RV-MSFT_ret_RV, main="MSFT: Difference in RV computed from prices vs returns", col="darkgreen")
plot.zoo(XOM_price_RV-XOM_ret_RV, main="XOM: Difference in RV computed from prices vs returns", col="red")

#getAnywhere(rCov)

#a function to reduce manual coding
filter_hours <- function(data, start, end){
    data[format(index(data), "%H:%M:%S") >= start &
         format(index(data), "%H:%M:%S") <= end] #keep only the rows where the condition is true (xts)
}

#BAC: calculate intraday RV
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
BAC_daily_RV <- rCov(BAC_ret, makeReturns=FALSE) #make daily RV
index(BAC_daily_RV) <- as.Date(index(BAC_daily_RV)) #to keep only the date, no timestamp -> align all series

index(BAC_RV1) <- as.Date(index(BAC_RV1)) #drop timestamps for all - only dates left
index(BAC_RV2) <- as.Date(index(BAC_RV2))
index(BAC_RV3) <- as.Date(index(BAC_RV3))
index(BAC_RV4) <- as.Date(index(BAC_RV4))
index(BAC_RV5) <- as.Date(index(BAC_RV5))
BAC_RV_sum <- BAC_RV1 + BAC_RV2 + BAC_RV3 + BAC_RV4 + BAC_RV5 


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

BAC_pct1 <- BAC_RV1 / BAC_daily_RV * 100
BAC_pct2 <- BAC_RV2 / BAC_daily_RV * 100
BAC_pct3 <- BAC_RV3 / BAC_daily_RV * 100
BAC_pct4 <- BAC_RV4 / BAC_daily_RV * 100
BAC_pct5 <- BAC_RV5 / BAC_daily_RV * 100

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

options(repr.plot.height=10, repr.plot.width=16)
par(mfrow=c(2,3))

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

#need to merge MSFT pcts first, because pct5 has different number of obs than the rest (754 vs 756)
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

stocks <- list(BAC=BAC_xts, MSFT=MSFT_xts, XOM=XOM_xts) #list of stock prices
period_list <- list(c("07:00:00","09:29:00"), c("09:30:00","10:59:00"), #list of intraday periods
                    c("11:00:00","14:29:00"), c("14:30:00","15:59:00"),c("16:00:00","18:00:00"))

for (ticker in names(stocks)){
    for (i in 1:5){ #for each intraday period
        filtered <- filter_hours(stocks[[ticker]], period_list[[i]][1], period_list[[i]][2]) #custom function from earlier - xts subsetting for each intraday period
        obs_per_day <- table(as.Date(index(filtered))) #count how many observations we have each day
        single_obs_days <- sum(obs_per_day==1) #count number of days have a single price obs
        if (single_obs_days>0) cat(ticker, "period", i, "has", single_obs_days, "days with 1 price obs.\n")
    }
}


#create a function which would remove days with insufficient price obs -> can calculate returns

filter_min_obs <- function(data, start, end, min_obs=2){
    filtered <- filter_hours(data, start, end)
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

#percentage share of individual intraday RV on total daily RV

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

#head(BAC_MedRV_JT, 3)

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
#BVP
BAC_BPV_J <- (BAC_daily_RV - BAC_BPV) * BAC_BPV_I #xts of signif jump magnitude or 0s
MSFT_BPV_J <- (MSFT_daily_RV - MSFT_BPV) * MSFT_BPV_I
XOM_BPV_J <- (XOM_daily_RV - XOM_BPV) * XOM_BPV_I

#MedRV
BAC_MedRV_J <- (BAC_daily_RV - BAC_MedRV) * BAC_MedRV_I
MSFT_MedRV_J <- (MSFT_daily_RV - MSFT_MedRV) * MSFT_MedRV_I
XOM_MedRV_J <- (XOM_daily_RV - XOM_MedRV) * XOM_MedRV_I


#Comparison of RVolatility estimates (without jumps)
options(repr.plot.height=14, repr.plot.width=14)
par(mfrow=c(3,1))

#BAC
plot.zoo(sqrt(BAC_daily_RV), main="BAC: RVol vs BPVol vs MedRVol", col="blue")
lines(zoo(sqrt(BAC_BPV)), col="green")
lines(zoo(sqrt(BAC_MedRV)), col="red")
legend("top", legend=c("RVol", "BPVol", "MedRVol"), col=c("blue", "green", "red"),
    lwd=2, bty="n", horiz=TRUE, cex=1.2)

#MSFT
plot.zoo(sqrt(MSFT_daily_RV), main="MSFT: RVol vs BPVol vs MedRVol", col="blue")
lines(zoo(sqrt(MSFT_BPV)), col="green")
lines(zoo(sqrt(MSFT_MedRV)), col="red")
legend("top", legend=c("RVol", "BPVol", "MedRVol"), col=c("blue", "green", "red"),
    lwd=2, bty="n", horiz=TRUE, cex=1.2)


#XOM
plot.zoo(sqrt(XOM_daily_RV), main="XOM: RVol vs BPVol vs MedRVol", col="blue")
lines(zoo(sqrt(XOM_BPV)), col="green")
lines(zoo(sqrt(XOM_MedRV)), col="red")
legend("top", legend=c("RVol", "BPVol", "MedRVol"), col=c("blue", "green", "red"),
    lwd=2, bty="n", horiz=TRUE, cex=1.2)

#Comparison of RVolatility estimates (with jumps)
par(mfrow=c(3,1))
#BAC
plot.zoo(sqrt(BAC_daily_RV), main="BAC: RVol vs BPVol vs MedRVol including jumps", col="blue")
lines(zoo(sqrt(BAC_BPV + BAC_BPV_J)), col="green")
lines(zoo(sqrt(BAC_MedRV + BAC_MedRV_J)), col="red")
legend("top", legend=c("RVol", "BPVol", "MedRVol"), col=c("blue", "green", "red"),
    lwd=2, bty="n", horiz=TRUE, cex=1.2)

#MSFT
plot.zoo(sqrt(MSFT_daily_RV), main="MSFT: RVol vs BPVol vs MedRVol including jumps", col="blue")
lines(zoo(sqrt(MSFT_BPV + MSFT_BPV_J)), col="green")
lines(zoo(sqrt(MSFT_MedRV + MSFT_MedRV_J)), col="red")
legend("top", legend=c("RVol", "BPVol", "MedRVol"), col=c("blue", "green", "red"),
    lwd=2, bty="n", horiz=TRUE, cex=1.2)


#XOM
plot.zoo(sqrt(XOM_daily_RV), main="XOM: RVol vs BPVol vs MedRVol including jumps", col="blue")
lines(zoo(sqrt(XOM_BPV + XOM_BPV_J)), col="green")
lines(zoo(sqrt(XOM_MedRV + XOM_BPV_J)), col="red")
legend("top", legend=c("RVol", "BPVol", "MedRVol"), col=c("blue", "green", "red"),
    lwd=2, bty="n", horiz=TRUE, cex=1.2)

#Comparison of the differences: RVol - BPVol and RVol - MedVol
par(mfrow=c(3,1))

plot.zoo(sqrt(BAC_daily_RV) - sqrt(BAC_BPV), main="BAC: RVol - BPV vs RVol - MedRV")
lines(zoo(sqrt(BAC_daily_RV) - sqrt(BAC_MedRV)), col="red", lwd=1)
legend("top", legend=c("RVol - BPVol", "RVol - MedRVol"),
       col=c("black", "red"), lwd=2, bty="n", horiz=TRUE)

plot.zoo(sqrt(MSFT_daily_RV) - sqrt(MSFT_BPV), main="MSFT: RVol - BPV vs RVol - MedRV")
lines(zoo(sqrt(MSFT_daily_RV) - sqrt(MSFT_MedRV)), col="red", lwd=1)
legend("top", legend=c("RVol - BPVol", "RVol - MedRVol"),
       col=c("black", "red"), lwd=2, bty="n", horiz=TRUE)

plot.zoo(sqrt(XOM_daily_RV) - sqrt(XOM_BPV), main="XOM: RVol - BPV vs RVol - MedRV")
lines(zoo(sqrt(XOM_daily_RV) - sqrt(XOM_MedRV)), col="red", lwd=1)
legend("top", legend=c("RVol - BPVol", "RVol - MedRVol"),
       col=c("black", "red"), lwd=2, bty="n", horiz=TRUE)

#visualisation of significant jumps

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






