library(scales)
library(dplyr)
library(hBayesDM)
options(mc.cores = parallel::detectCores())

setwd("~/Desktop/project/ERGT/analyses")

# load data
dat_all <- read.csv(file = 'data_egt_allsub.csv')
# 2 types of missing values
dat_all$response[dat_all$response==0] <- NA
dat_all$response[dat_all$response=='NaN'] <- NA
dat_all$trial <- dat_all$trial + (dat_all$run-1)*36
dat_all <- within(dat_all,{
  choice <- NA
  choice[response <= 2] <- 0
  choice[response >= 3] <- 1
})
# effort and risk task
dat_egt <- dat_all[dat_all$Effort1_Risk2 == 1,]
dat_rgt <- dat_all[dat_all$Effort1_Risk2 == 2,]

# raw cost:
dat_egt <- within(dat_egt,{
  rawcost <- NA
  rawcost[effort_risk == 1] <- 0.3
  rawcost[effort_risk == 2] <- 0.4
  rawcost[effort_risk == 3] <- 0.5
  rawcost[effort_risk == 4] <- 0.6
  rawcost[effort_risk == 5] <- 0.7
})

dat_rgt <- within(dat_rgt,{
  rawcost <- NA
  rawcost[effort_risk == 1] <- 0.1
  rawcost[effort_risk == 2] <- 0.3
  rawcost[effort_risk == 3] <- 0.5
  rawcost[effort_risk == 4] <- 0.7
  rawcost[effort_risk == 5] <- 0.9
})

## select the useful variables
dat_egt = dat_egt[c("sub","trial","reward", "loss", "rawcost", "choice")]
dat_egt = rename(dat_egt, subjID=sub, gain=reward, cost=rawcost)
# exclude outliers 
dat_egt = filter(dat_egt, !subjID %in% c(24))

dat_rgt = dat_rgt[c("sub","trial","reward", "loss", "rawcost", "choice")]
dat_rgt = rename(dat_rgt, subjID=sub, gain=reward, cost=rawcost)
dat_rgt = filter(dat_rgt, !subjID %in% c(29,35))

# initiate rstan
source("hBayesDM_egt.R")

#linear
source("egt_linear14.R")
fit_e_linear <- egt_linear(data = dat_egt, niter=3000, nwarmup=1000, nchain=4, ncore=4)
fit_r_linear <- egt_linear(data = dat_rgt, niter=3000, nwarmup=1000, nchain=4, ncore=4)

# hyperbolic
source("egt_hyper12.R")
fit_e_hyper <- egt_hyper(data = dat_egt, niter=3000, nwarmup=1000, nchain=4, ncore=4)
fit_r_hyper <- egt_hyper(data = dat_rgt, niter=3000, nwarmup=1000, nchain=4, ncore=4)

# parabolic model
source("egt_parab14.R")
fit_e_parab <- egt_parab(data = dat_egt, niter=3000, nwarmup=1000, nchain=4, ncore=4)
fit_r_parab <- egt_parab14(data = dat_rgt, niter=3000, nwarmup=1000, nchain=4, ncore=4)

# Power2
source("egt_power14.R")
fit_e_power <- egt_power(data = dat_egt, niter=3000, nwarmup=1000, nchain=4, ncore=4)
fit_r_power <- egt_power(data = dat_rgt, niter=3000, nwarmup=1000, nchain=4, ncore=4)

# sigmoidal model
source("egt_sigm12.R")
fit_e_sigm <- egt_sigm(data = dat_egt, niter=3000, nwarmup=1000, nchain=4, ncore=4)
fit_r_sigm <- egt_sigm(data = dat_rgt, niter=3000, nwarmup=1000, nchain=4, ncore=4)

# cumulative prospect theory
source("egt_cpt1.R")
fit_r_cpt <- egt_cpt(data = dat_rgt, niter=3000, nwarmup=1000, nchain=4, ncore=4)
fit_e_cpt <- egt_cpt(data = dat_egt, niter=3000, nwarmup=1000, nchain=4, ncore=4)

# model comparison based on looic
printFit(fit_e_linear, fit_e_hyper, fit_e_parab, fit_e_power, fit_e_sigm1, fit_e_cpt)
printFit(fit_r_linear, fit_r_hyper, fit_r_parab, fit_r_power, fit_r_sigm1, fit_r_cpt)

# save the fitted values for model-based fMRI
bestfit_e <- fit_e_power$allIndPars
write.csv(bestfit_e,'egt_power_fit.csv')

bestfit_r <- fit_r_power$allIndPars
write.csv(bestfit_r,'rgt_power_fit.csv')


# compare power2 models with same or different k and p across tasks
# combine data of the 2 tasks
dat_egt2 = rename(dat_egt, coste = cost)
dat_rgt2 = rename(dat_rgt, costr = cost)
dat_egt2$costr  = 0
dat_rgt2$coste  = 0

dat_comb = rbind(dat_egt2,dat_rgt2)
dat_comb = 
  dat_comb %>% relocate(costr, .after = coste)

source("hBayesDM_egt2.R")
# same k and p
source("egt_power21.R")
fit_c_power21 <- egt_power21(data = dat_comb, niter=3000, nwarmup=1000, nchain=4, ncore=4)
# different k and same p
source("egt_power22.R")
fit_c_power22 <- egt_power22(data = dat_comb, niter=3000, nwarmup=1000, nchain=4, ncore=4)
# same k and different p
source("egt_power23.R")
fit_c_power23 <- egt_power23(data = dat_comb, niter=3000, nwarmup=1000, nchain=4, ncore=4)
# different k and p
source("egt_power24.R")
fit_c_power24 <- egt_power24(data = dat_comb, niter=3000, nwarmup=1000, nchain=4, ncore=4)

printFit(fit_c_power21, fit_c_power22, fit_c_power23, fit_c_power24)
