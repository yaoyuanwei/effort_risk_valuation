# Main behavioral modeling script for effort-based decision-making
# July 30, 2023, Yuanwei Yao

# Required packages
library(dplyr)
library(hBayesDM)

# Parallel computing allowed
options(mc.cores = parallel::detectCores())

# Set working directory
setwd("~/Desktop/project/Effort_risk/analyses")

# Read effortful task
dat_edt <- read.csv(file = 'Data_EDT_DVD.csv')

# Exclude NA
dat_edt <- dat_edt[!is.na(dat_edt$choice_rt),]

# Select useful variables
dat_edt <- dat_edt[c("subjID","trial","cost_one","amount_one",
                     "cost_two","amount_two","choice")]

# Read riskt task
dat_rdt <- read.csv(file = 'Data_RDT_DVD.csv')

# Exclude NA
dat_rdt <- dat_rdt[!is.na(dat_rdt$choice_rt),]

# Select useful variables
dat_rdt <- dat_rdt[c("subjID","trial","cost_one","amount_one",
                     "cost_two","amount_two","choice")]

# Initiate modified hBayesDM code
source("hBayesDM_edt.R")

############### Models for effort-based decision-making ############### 

# Linear model
source("edt_linear.R")
fit_e_linear <- edt_linear(data = dat_edt, niter=2000, nwarmup=1000, nchain=4, ncore=4)

# Hyperbolic model
source("edt_hyper.R")
fit_e_hyper <- edt_hyper(data = dat_edt, niter=2000, nwarmup=1000, nchain=4, ncore=4)

# Parabolic model
source("edt_parab.R")
fit_e_parab <- edt_parab(data = dat_edt, niter=2000, nwarmup=1000, nchain=4, ncore=4)

# Two-parameter power
source("edt_power.R")
fit_e_power <- edt_power(data = dat_edt, niter=2000, nwarmup=1000, nchain=4, ncore=4)

# Sigmoid model
source("edt_sigm.R")
fit_e_sigm <- edt_sigm(data = dat_edt, niter=2000, nwarmup=1000, nchain=4, ncore=4)

# Model comparison based on LOOIC
printFit(fit_e_linear, fit_e_hyper, fit_e_parab, fit_e_power, fit_e_sigm)

############### Models for risky decision-making ############### 

# Cumulative prospect theory (CPT)
source("edt_cpt.R")
fit_r_cpt <- edt_cpt(data = dat_rdt, niter=2000, nwarmup=1000, nchain=4, ncore=4)

# Original prospect theory
source("edt_pt.R")
fit_r_pt <- edt_pt(data = dat_rdt, niter=2000, nwarmup=1000, nchain=4, ncore=4)

# Model comparison based on LOOIC
printFit(fit_r_cpt, fit_r_pt)

############### Save fitted parameters for the winning model ###############

# Two-parameter power model effort-based decision-making
bestfit_e <- fit_e_power$allIndPars
write.csv(bestfit_e,'edt_fit_power.csv')

# CPT for risky decision-making
bestfit_r <- fit_r_cpt$allIndPars
write.csv(bestfit_r,'rdt_fit_cpt.csv')
