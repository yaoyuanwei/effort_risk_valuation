# Main behavioral modeling script for effort-based gambling
# July 30, 2023, Yuanwei Yao

# Required packages
library(scales)
library(dplyr)
library(hBayesDM)

# Parallel computing allowed
options(mc.cores = parallel::detectCores())

# Set working directory
setwd("~/Desktop/project/ERGT/analyses")

# Load data
dat_all <- read.csv(file = 'data_egt_allsub.csv')

# Specify 2 types of missing values
dat_all$response[dat_all$response==0] <- NA
dat_all$response[dat_all$response=='NaN'] <- NA

# Concatenate trials of differen runs
dat_all$trial <- dat_all$trial + (dat_all$run-1)*36

# Recode the responses: 1-2 as reject, and 3-4 as accept
dat_all <- within(dat_all,{
  choice <- NA
  choice[response <= 2] <- 0
  choice[response >= 3] <- 1
})

# Task type: effort = 1, risk = 2
dat_egt <- dat_all[dat_all$Effort1_Risk2 == 1,]
dat_rgt <- dat_all[dat_all$Effort1_Risk2 == 2,]

# Change effort levels to proportions
dat_egt <- within(dat_egt,{
  rawcost <- NA
  rawcost[effort_risk == 1] <- 0.3
  rawcost[effort_risk == 2] <- 0.4
  rawcost[effort_risk == 3] <- 0.5
  rawcost[effort_risk == 4] <- 0.6
  rawcost[effort_risk == 5] <- 0.7
})

# Change risk levels to proportions
dat_rgt <- within(dat_rgt,{
  rawcost <- NA
  rawcost[effort_risk == 1] <- 0.1
  rawcost[effort_risk == 2] <- 0.3
  rawcost[effort_risk == 3] <- 0.5
  rawcost[effort_risk == 4] <- 0.7
  rawcost[effort_risk == 5] <- 0.9
})

# Select the useful variables for effort-based decision-making
dat_egt = dat_egt[c("sub","trial","reward", "loss", "rawcost", "choice")]

# Rename some variables
dat_egt = rename(dat_egt, subjID=sub, gain=reward, cost=rawcost)

# Exclude outliers 
dat_egt = filter(dat_egt, !subjID %in% c(24))

# Select the useful variables for risky decision-making
dat_rgt = dat_rgt[c("sub","trial","reward", "loss", "rawcost", "choice")]

# Rename some variables
dat_rgt = rename(dat_rgt, subjID=sub, gain=reward, cost=rawcost)

# Exclude outliers 
dat_rgt = filter(dat_rgt, !subjID %in% c(29,35))

# Initiate modified hBayesDM code
source("hBayesDM_egt.R")

############### Models for effort-based gambling ############### 

# Linear model
source("egt_linear.R")
fit_e_linear <- egt_linear(data = dat_egt, niter=2000, nwarmup=1000, nchain=4, ncore=4)

# Hyperbolic model
source("egt_hyper.R")
fit_e_hyper <- egt_hyper(data = dat_egt, niter=2000, nwarmup=1000, nchain=4, ncore=4)

# Parabolic model
source("egt_parab.R")
fit_e_parab <- egt_parab(data = dat_egt, niter=2000, nwarmup=1000, nchain=4, ncore=4)

# Two-parameter power
source("egt_power.R")
fit_e_power <- egt_power(data = dat_egt, niter=2000, nwarmup=1000, nchain=4, ncore=4)

# Sigmoidal model
source("egt_sigm.R")
fit_e_sigm <- egt_sigm(data = dat_egt, niter=2000, nwarmup=1000, nchain=4, ncore=4)

# Model comparison based on LOOIC
printFit(fit_e_linear, fit_e_hyper, fit_e_parab, fit_e_power, fit_e_sigm)

############### Models for risky gambling ############### 

# Cumulative prospect theory (CPT)
source("egt_cpt.R")
fit_r_cpt <- egt_cpt(data = dat_rgt, niter=2000, nwarmup=1000, nchain=4, ncore=4)

# Original prospect theory
source("egt_pt.R")
fit_r_pt <- egt_pt(data = dat_rgt, niter=2000, nwarmup=1000, nchain=4, ncore=4)

# Model comparison based on LOOIC
printFit(fit_r_cpt, fit_r_pt)

############### Save fitted parameters for the winning model ###############

# Two-parameter power model for effort-based gambling
bestfit_e <- fit_e_power$allIndPars
write.csv(bestfit_e,'egt_power_fit.csv')

# CPT for risky gambling
bestfit_r <- fit_r_power$allIndPars
write.csv(bestfit_r,'rgt_cpt_fit.csv')
