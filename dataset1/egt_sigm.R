
egt_sigm <- hBayesDM_egt(
  task_name       = "egt",
  model_name      = "sigm",
  model_type      = "",
  data_columns    = c("subjID", "gain", "loss", "cost", "choice"),
  parameters      = list(
    "k" = c(0, 5, 100),
    "p" = c(0, 0.1, 1),
    "rho" = c(0, 0.1, 1),
    "lambda" = c(0, 0.5, 5),
    "beta" = c(0, 1, 20)
  ),
  regressors      = NULL,
  postpreds       = c("y_pred"))
