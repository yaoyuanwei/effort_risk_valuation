# Set parameters for the two-parameter power discounting model

edt_power <- hBayesDM_edt(
  task_name       = "edt",
  model_name      = "power",
  model_type      = "",
  data_columns    = c("subjID", "cost_one", "amount_one", "cost_two", "amount_two", "choice"),
  parameters      = list(
    "k"    = c(0, 5, 100),
    "p"    = c(0, 0.5, 5),
    "rho"  = c(0, 0.1, 1),
    "beta" = c(0, 1, 20)
  ),
  regressors      = NULL,
  postpreds       = c("y_pred"))
