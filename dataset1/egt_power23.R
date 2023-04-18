# power 2 function with same k and different p


egt_power23 <- hBayesDM_egt2(
  task_name       = "egt",
  model_name      = "power23",
  model_type      = "",
  data_columns    = c("subjID", "gain", "loss", "coste", "costr", "choice"),
  parameters      = list(
    "k" = c(0, 5, 50),
    "p1" = c(0, 0.5, 5),
    "p2" = c(0, 0.5, 5),
    "rho" = c(0, 0.1, 1),
    "lambda" = c(0, 0.5, 5),
    "beta" = c(0, 1, 20)
  ),
  regressors      = NULL,
  postpreds       = c("y_pred"))
