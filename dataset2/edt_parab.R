# Set parameters for the parabolic discounting model for effort-based decision-making
# It is based on the hBayesDM template
# July 29, 2023, Yuanwei Yao
#
edt_parab <- hBayesDM_edt(

  # Task name
  task_name       = "edt",

  # Model name
  model_name      = "parab",

  # Model type, not necessary here
  model_type      = "",

  # Name of the required columns
  data_columns    = c("subjID", "cost_one", "amount_one", "cost_two", "amount_two", "choice"),

  # Range and searching step for free parameters
  parameters      = list(
    "k"    = c(0, 5, 50),
    "rho"  = c(0, 0.1, 1),
    "beta" = c(0, 1, 20)
  ),

  # Regressors of interest will be defined outside
  regressors      = NULL,

  # If the posterior prediction is required
  postpreds       = c("y_pred"))
