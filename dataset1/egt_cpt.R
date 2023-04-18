egt_cpt <- hBayesDM_egt(
  task_name       = "egt",
  model_name      = "cpt",
  model_type      = "",
  data_columns    = c("subjID", "gain", "loss", "cost", "choice"),
  parameters      = list(
    "rho"     = c(0, 0.1, 1),
    "lambda"  = c(0, 1, 5),
    "gamma"   = c(0, 0.1, 1),
    "delta1"  = c(0, 1, 5),
    "delta2"  = c(0, 1, 5),
    "beta"    = c(0, 1, 20)
  ),
  regressors      = NULL,
  postpreds       = c("y_pred"))
