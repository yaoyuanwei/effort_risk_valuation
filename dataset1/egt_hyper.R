# Set parameters for the hyperbolic discounting model for effort-based gambling
# It is based on the hBayesDM template
# July 29, 2023, Yuanwei Yao
#
egt_hyper <- hBayesDM_egt(

  # Task name
  task_name       = "egt",

  # Model name
  model_name      = "hyper",

  # Model type, not necessary here
  model_type      = "",

  # Name of the required columns
  data_columns    = c("subjID", "gain", "loss", "cost", "choice"),

  # Range and searching step for free parameters
  parameters      = list(
    "k" = c(0, 1, 50),
    "rho" = c(0, 0.1, 1),
    "lambda" = c(0, 0.5, 5),
    "beta" = c(0, 1, 20)
  ),

  # Regressors of interest will be defined outside
  regressors      = NULL,

  # If the posterior prediction is required
  postpreds       = c("y_pred"))
