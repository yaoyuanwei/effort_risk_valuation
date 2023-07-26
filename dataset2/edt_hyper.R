# Set parameters for the hyperbolic discounting model

edt_hyper <- hBayesDM_edt(
  task_name       = "edt",
  model_name      = "hyper",
  model_type      = "",
  data_columns    = c("subjID", "cost_one", "amount_one", "cost_two", "amount_two", "choice"),
  parameters      = list(
    "k"     = c(0, 5, 50),
    "rho"   = c(0, 0.1, 1),
    "beta"  = c(0, 1, 20)
  ),
  regressors      = NULL,
  postpreds       = c("y_pred"))
