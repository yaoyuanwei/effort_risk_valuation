library(dplyr)
library(hBayesDM)
options(mc.cores = parallel::detectCores())

setwd("~/Desktop/project/Effort_risk/analyses")

## read effort task
dat_edt <- read.csv(file = 'Data_EDT_DVD.csv')
# rename data
dat_edt = rename(dat_edt, subjID=SubID, trial=TrialOrder, amount_one=LargeReward,
                 amount_two=SmallReward, choice=Decision)

## read risk task
dat_rdt <- read.csv(file = 'Data_RDT_DVD.csv')
# rename data
dat_rdt = rename(dat_rdt, subjID=SubID, trial=TrialOrder, amount_one=LargeReward,
                 amount_two=SmallReward, choice=Decision)

#initiate rstan
source("hBayesDM_edt.R")

# linear model
source("edt_linear2.R")
fit_e_linear2 <- edt_linear2(data = dat_edt, niter=3000, nwarmup=1000, nchain=4, ncore=4)
fit_r_linear2 <- edt_linear2(data = dat_rdt, niter=3000, nwarmup=1000, nchain=4, ncore=4)

# hyperbolic model
source("edt_hyper2.R")
fit_e_hyper2 <- edt_hyper2(data = dat_edt, niter=3000, nwarmup=1000, nchain=4, ncore=4)
fit_r_hyper2 <- edt_hyper2(data = dat_rdt, niter=3000, nwarmup=1000, nchain=4, ncore=4)

# parabolic model
source("edt_parab2.R")
fit_e_parab2 <- edt_parab2(data = dat_edt, niter=3000, nwarmup=1000, nchain=4, ncore=4)
fit_r_parab2 <- edt_parab2(data = dat_rdt, niter=3000, nwarmup=1000, nchain=4, ncore=4)

# 2-parameter power
source("edt_power2.R")
fit_e_power2 <- edt_power2(data = dat_edt, niter=3000, nwarmup=1000, nchain=4, ncore=4)
fit_r_power2 <- edt_power2(data = dat_rdt, niter=3000, nwarmup=1000, nchain=4, ncore=4)

# sigmoid model
source("edt_sigm2.R")
fit_e_sigm2 <- edt_sigm2(data = dat_edt, niter=3000, nwarmup=1000, nchain=4, ncore=4)
fit_r_sigm2 <- edt_sigm2(data = dat_rdt, niter=3000, nwarmup=1000, nchain=4, ncore=4)

# cumulative prospect theory (CPT)
source("edt_cpt1.R")
fit_e_cpt1 <- edt_cpt1(data = dat_edt, niter=3000, nwarmup=1000, nchain=4, ncore=4)
fit_r_cpt1 <- edt_cpt1(data = dat_rdt, niter=3000, nwarmup=1000, nchain=4, ncore=4)


# model comparison based on looic
printFit(fit_e_linear1, fit_e_exp, fit_e_hyper, fit_e_parab, fit_e_linear1rho)
printFit(fit_r_linear1, fit_r_exp, fit_r_hyper, fit_r_parab, fit_r_linear1rho)

# save the fitted values
bestfit_e <- fit_e_power$allIndPars
write.csv(bestfit_e,'edt_fit_power.csv')

bestfit_r <- fit_r_power$allIndPars
write.csv(bestfit_r,'rdt_fit_power.csv')


