
edt_cpt <- hBayesDM_edt(
  task_name       = "edt",
  model_name      = "cpt",
  model_type      = "",
  data_columns    = c("subjID", "cost_one", "amount_one", "cost_two", "amount_two", "choice"),
  parameters      = list(
    "rho" = c(0, 0.1, 1),
    "gamma" = c(0, 0.1, 1),
    "delta1" = c(0, 0.5, 5),
    "beta" = c(0, 1, 20)
  ),
  regressors      = NULL,
  postpreds       = c("y_pred"))
