library(dplyr)

setwd("~/Desktop/project/Effort_project/Effort_risk/analyses")

## read effort task
dat_edt <- read.csv(file = 'Data_EDT_DVD.csv')
dat_edt$cost_two <- 0
dat_edt <- within(dat_edt,{
  cost_one <- NA
  cost_one[EffortReq == 50]   <- 0.5
  cost_one[EffortReq == 65]   <- 0.65
  cost_one[EffortReq == 80]   <- 0.8
  cost_one[EffortReq == 95]   <- 0.95})
dat_edt <- dat_edt[c("SubID","TrialOrder","cost_one","LargeReward",
                     "cost_two","SmallReward","Decision")]
dat_edt = filter(dat_edt, !SubID %in% c(303, 311, 319, 322, 335, 337))

## read risk task
dat_rdt <- read.csv(file = 'Data_RDT_DVD.csv')
dat_rdt$cost_two <- 0
dat_rdt <- within(dat_rdt,{
  cost_one <- NA
  cost_one[Risk == 10]     <- 0.1
  cost_one[Risk == 30]     <- 0.3
  cost_one[Risk == 50]     <- 0.5
  cost_one[Risk == 70]     <- 0.7})
dat_rdt <- dat_rdt[c("SubID","TrialOrder","cost_one","LargeReward",
                     "cost_two","SmallReward","Decision")]
dat_rdt = filter(dat_rdt, !SubID %in% c(303, 311, 322, 335, 337))

setwd("~/Desktop/project/Effort_project/Effort_risk/analyses/github")

write.csv(dat_edt, "Data_EDT_DVD.csv")
write.csv(dat_rdt, "Data_RDT_DVD.csv")


