# Set parameters for the original perspective theory

edt_pt <- hBayesDM_edt(
  task_name       = "edt",
  model_name      = "pt",
  model_type      = "",
  data_columns    = c("subjID", "cost_one", "amount_one", "cost_two", "amount_two", "choice"),
  parameters      = list(
    "rho" = c(0, 0.1, 1),
    "beta" = c(0, 1, 20)
  ),
  regressors      = NULL,
  postpreds       = c("y_pred"))
