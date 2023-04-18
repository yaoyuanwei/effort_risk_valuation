# power 2 model with same k and different p

edt_power23 <- hBayesDM_edt2(
  task_name       = "edt",
  model_name      = "power23",
  model_type      = "",
  data_columns    = c("subjID", "cost_e", "cost_r", "amount_one", "amount_two", "choice"),
  parameters      = list(
    "k"    = c(0, 5, 50),
    "p1"   = c(0, 1, 5),
    "p2"   = c(0, 1, 5),
    "rho"  = c(0, 0.1, 1),
    "beta" = c(0, 1, 20)
  ),
  regressors      = NULL,
  postpreds       = c("y_pred"))
