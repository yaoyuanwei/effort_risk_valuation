# Main behavioral modeling script
# Required packages
library(dplyr)
library(hBayesDM)
options(mc.cores = parallel::detectCores())

setwd("~/Desktop/project/Effort_risk/analyses")

# Read effort task
dat_edt <- read.csv(file = 'Data_EDT_DVD.csv')
# select useful variables
dat_edt <- dat_edt[c("subjID","trial","cost_one","amount_one",
                     "cost_two","amount_two","choice")]

# Read risk task
dat_rdt <- read.csv(file = 'Data_RDT_DVD.csv')
# select useful variables
dat_rdt <- dat_rdt[c("subjID","trial","cost_one","amount_one",
                     "cost_two","amount_two","choice")]

# Initiate rstan
source("hBayesDM_edt.R")

# Models for effort-based decision-making
# linear model
source("edt_linear.R")
fit_e_linear <- edt_linear(data = dat_edt, niter=3000, nwarmup=1000, nchain=4, ncore=4)

# hyperbolic model
source("edt_hyper.R")
fit_e_hyper <- edt_hyper(data = dat_edt, niter=3000, nwarmup=1000, nchain=4, ncore=4)

# parabolic model
source("edt_parab.R")
fit_e_parab <- edt_parab(data = dat_edt, niter=3000, nwarmup=1000, nchain=4, ncore=4)

# 2-parameter power model
source("edt_power.R")
fit_e_power <- edt_power(data = dat_edt, niter=3000, nwarmup=1000, nchain=4, ncore=4)

# sigmoid model
source("edt_sigm.R")
fit_e_sigm <- edt_sigm(data = dat_edt, niter=3000, nwarmup=1000, nchain=4, ncore=4)

# Model comparison based on LOOIC
printFit(fit_e_linear, fit_e_hyper, fit_e_parab, fit_e_power, fit_e_sigm)

# Models for risky decision-making
# Cumulative prospect theory (CPT)
source("edt_cpt.R")
fit_r_cpt <- edt_cpt(data = dat_rdt, niter=3000, nwarmup=1000, nchain=4, ncore=4)

# Original prospect theory
source("edt_pt.R")
fit_r_pt <- edt_pt(data = dat_rdt, niter=3000, nwarmup=1000, nchain=4, ncore=4)

# Model comparison based on LOOIC
printFit(fit_r_cpt, fit_r_pt)

# Save the fitted values for effort-based decision-making
bestfit_e <- fit_e_power$allIndPars
write.csv(bestfit_e,'edt_fit_power.csv')

# Save the fitted values for risky decision-making
bestfit_r <- fit_r_cpt$allIndPars
write.csv(bestfit_r,'rdt_fit_cpt.csv')
