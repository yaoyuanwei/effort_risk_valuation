
egt_hyper <- hBayesDM_egt(
  task_name       = "egt",
  model_name      = "hyper",
  model_type      = "",
  data_columns    = c("subjID", "gain", "loss", "cost", "choice"),
  parameters      = list(
    "k" = c(0, 1, 50),
    "rho" = c(0, 0.1, 1),
    "lambda" = c(0, 0.5, 5),
    "beta" = c(0, 1, 20)
  ),
  regressors      = NULL,
  postpreds       = c("y_pred"))
