# Set parameters for the parabolic discounting model

edt_parab <- hBayesDM_edt(
  task_name       = "edt",
  model_name      = "parab",
  model_type      = "",
  data_columns    = c("subjID", "cost_one", "amount_one", "cost_two", "amount_two", "choice"),
  parameters      = list(
    "k"    = c(0, 5, 100),
    "rho"  = c(0, 0.1, 1),
    "beta" = c(0, 1, 20)
  ),
  regressors      = NULL,
  postpreds       = c("y_pred"))
