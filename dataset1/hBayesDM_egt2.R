# hBayesDM Model Function tailored for two one-option cost-benefit decision-making tasks

hBayesDM_egt2 <- function(task_name,
                           model_name,
                           model_type = "",
                           data_columns,
                           parameters,
                           regressors = NULL,
                           postpreds = "y_pred",
                           stanmodel_arg = NULL) {

  # The resulting hBayesDM model function to be returned
  function(data           = NULL,
           niter          = 2000,
           nwarmup        = 1000,
           nchain         = 4,
           ncore          = 4,
           nthin          = 1,
           inits          = "vb",
           indPars        = "mean",
           modelRegressor = FALSE,
           vb             = FALSE,
           inc_postpred   = FALSE,
           adapt_delta    = 0.95,
           stepsize       = 1,
           max_treedepth  = 10,
           ...) {

    
    # preprocess function for stan
    egt_preprocess_func <- function(raw_data, general_info) {
      # Currently class(raw_data) == "data.table"
      
      # Use general_info of raw_data
      subjs   <- general_info$subjs
      n_subj  <- general_info$n_subj
      t_subjs <- general_info$t_subjs
      t_max   <- general_info$t_max
      
      # Initialize (model-specific) data arrays
      gain    <- array( 0, c(n_subj, t_max))
      loss    <- array( 0, c(n_subj, t_max))
      coste   <- array( 0, c(n_subj, t_max))
      costr   <- array( 0, c(n_subj, t_max))
      choice  <- array(-1, c(n_subj, t_max))
      
      # Write from raw_data to the data arrays
      for (i in 1:n_subj) {
        subj <- subjs[i]
        t <- t_subjs[i]
        DT_subj <- raw_data[raw_data$subjid == subj]
        
        # ignore case and underscores
        gain[i, 1:t]    <- DT_subj$gain
        loss[i, 1:t]    <- DT_subj$loss
        coste[i, 1:t]   <- DT_subj$coste
        costr[i, 1:t]   <- DT_subj$costr
        choice[i, 1:t]  <- DT_subj$choice
      }
      
      # Wrap into a list for Stan
      data_list <- list(
        N             = n_subj,
        T             = t_max,
        Tsubj         = t_subjs,
        gain          = gain,
        loss          = loss,
        coste         = coste,
        costr         = costr,
        choice        = choice
      )
      
      # Returned data_list will directly be passed to Stan
      return(data_list)
    }
    
    ############### Stop checks ###############

    # Check if regressor available for this model
    if (modelRegressor && is.null(regressors)) {
      stop("** Model-based regressors are not available for this model. **\n")
    }

    # Check if postpred available for this model
    if (inc_postpred && is.null(postpreds)) {
      stop("** Posterior predictions are not yet available for this model. **\n")
    }

    if (is.null(data) || is.na(data) || data == "") {
      stop("Invalid input for the 'data' value. ",
           "You should pass a data.frame, or a filepath for a data file,",
           "\"example\" for an example dataset, ",
           "or \"choose\" to choose it in a prompt.")

    } else if ("data.frame" %in% class(data)) {
      # Use the given data object
      raw_data <- data.table::as.data.table(data)

    } else {
      stop("Invalid input for the 'data' value. ",
           "You should pass a data.frame, or a filepath for a data file,",
           "\"example\" for an example dataset, ",
           "or \"choose\" to choose it in a prompt.")
    }

    # Save initial colnames of raw_data for later
    colnames_raw_data <- colnames(raw_data)

    # Check if necessary data columns all exist (while ignoring case and underscores)
    insensitive_data_columns <- tolower(gsub("_", "", data_columns, fixed = TRUE))
    colnames(raw_data) <- tolower(gsub("_", "", colnames(raw_data), fixed = TRUE))
    if (!all(insensitive_data_columns %in% colnames(raw_data))) {
      stop("** Data file is missing one or more necessary data columns. Please check again. **\n",
           "  Necessary data columns are: \"", paste0(data_columns, collapse = "\", \""), "\".\n")
    }

    # Remove only the rows containing NAs in necessary columns
    complete_rows       <- complete.cases(raw_data[, insensitive_data_columns, with = FALSE])
    sum_incomplete_rows <- sum(!complete_rows)
    if (sum_incomplete_rows > 0) {
      raw_data <- raw_data[complete_rows, ]
      cat("\n")
      cat("The following lines of the data file have NAs in necessary columns:\n")
      cat(paste0(head(which(!complete_rows), 100) + 1, collapse = ", "))
      if (sum_incomplete_rows > 100) {
        cat(", ...")
      }
      cat(" (total", sum_incomplete_rows, "lines)\n")
      cat("These rows are removed prior to modeling the data.\n")
    }

    ####################################################
    ##   Prepare general info about the raw data   #####
    ####################################################

    subjs    <- NULL   # List of unique subjects (1D)
    n_subj   <- NULL   # Total number of subjects (0D)

    b_subjs  <- NULL   # Number of blocks per each subject (1D)
    b_max    <- NULL   # Maximum number of blocks across all subjects (0D)

    t_subjs  <- NULL   # Number of trials (per block) per subject (2D or 1D)
    t_max    <- NULL   # Maximum number of trials across all blocks & subjects (0D)

    # To avoid NOTEs by R CMD check
    .N <- NULL
    subjid <- NULL

    if ((model_type == "") || (model_type == "single")) {
      DT_trials <- raw_data[, .N, by = "subjid"]
      subjs     <- DT_trials$subjid
      n_subj    <- length(subjs)
      t_subjs   <- DT_trials$N
      t_max     <- max(t_subjs)
      if ((model_type == "single") && (n_subj != 1)) {
        stop("** More than 1 unique subjects exist in data file,",
             " while using 'single' type model. **\n")
      }
    } else {  # (model_type == "multipleB")
      DT_trials <- raw_data[, .N, by = c("subjid", "block")]
      DT_blocks <- DT_trials[, .N, by = "subjid"]
      subjs     <- DT_blocks$subjid
      n_subj    <- length(subjs)
      b_subjs   <- DT_blocks$N
      b_max     <- max(b_subjs)
      t_subjs   <- array(0, c(n_subj, b_max))
      for (i in 1:n_subj) {
        subj <- subjs[i]
        b <- b_subjs[i]
        t_subjs[i, 1:b] <- DT_trials[subjid == subj]$N
      }
      t_max     <- max(t_subjs)
    }

    general_info <- list(subjs, n_subj, b_subjs, b_max, t_subjs, t_max)
    names(general_info) <- c("subjs", "n_subj", "b_subjs", "b_max", "t_subjs", "t_max")

    #########################################################
    ##   Prepare: data_list                             #####
    ##            pars                                  #####
    ##            model_name                            #####
    #########################################################

    # Preprocess the raw data to pass to Stan
    data_list <- egt_preprocess_func(raw_data, general_info)

    # The parameters of interest for Stan
    pars <- character()
    if (model_type != "single") {
      pars <- c(pars, paste0("mu_", names(parameters)), "sigma")
    }
    pars <- c(pars, names(parameters))
    if ((task_name == "dd") && (model_type == "single")) {
      log_parameter1 <- paste0("log", toupper(names(parameters)[1]))
      pars <- c(pars, log_parameter1)
    }
    pars <- c(pars, "log_lik")
    
    if (modelRegressor) {
      pars <- c(pars, names(regressors))
    }
    if (inc_postpred) {
      pars <- c(pars, postpreds)
    }

    # Full name of model
    if (model_type == "") {
      model <- paste0(task_name, "_", model_name)
    } else {
      model <- paste0(task_name, "_", model_name, "_", model_type)
    }

    # Set number of cores for parallel computing
    if (ncore <= 1) {
      ncore <- 1
    } else {
      local_cores <- parallel::detectCores()
      if (ncore > local_cores) {
        ncore <- local_cores
        warning("Number of cores specified for parallel computing greater than",
                " number of locally available cores. Using all locally available cores.\n")
      }
    }
    options(mc.cores = ncore)

    ############### Print for user ###############
    cat("\n")
    cat("Model name  =", model, "\n")
    if (is.character(data))
      cat("Data file   =", data, "\n")
    cat("\n")
    cat("Details:\n")
    if (vb) {
      cat(" Using variational inference\n")
    } else {
      cat(" # of chains                    =", nchain, "\n")
      cat(" # of cores used                =", ncore, "\n")
      cat(" # of MCMC samples (per chain)  =", niter, "\n")
      cat(" # of burn-in samples           =", nwarmup, "\n")
    }
    cat(" # of subjects                  =", n_subj, "\n")
    if (model_type == "multipleB") {
      cat(" # of (max) blocks per subject  =", b_max, "\n")
    }
    if (model_type == "") {
      cat(" # of (max) trials per subject  =", t_max, "\n")
    } else if (model_type == "multipleB") {
      cat(" # of (max) trials...\n")
      cat("      ...per block per subject  =", t_max, "\n")
    } else {
      cat(" # of trials (for this subject) =", t_max, "\n")
    }

    # Models with additional arguments
    if ((task_name == "choiceRT") && (model_name == "ddm")) {
      RTbound <- list(...)$RTbound
      cat(" `RTbound` is set to            =", ifelse(is.null(RTbound), 0.1, RTbound), "\n")
    }
    if (task_name == "igt") {
      payscale <- list(...)$payscale
      cat(" `payscale` is set to           =", ifelse(is.null(payscale), 100, payscale), "\n")
    }
    if (task_name == "ts") {
      trans_prob <- list(...)$trans_prob
      cat(" `trans_prob` is set to         =", ifelse(is.null(trans_prob), 0.7, trans_prob), "\n")
    }

    # When extracting model-based regressors
    if (modelRegressor) {
      cat("\n")
      cat("**************************************\n")
      cat("**  Extract model-based regressors  **\n")
      cat("**************************************\n")
    }

    # An empty newline before Stan begins
    if (nchain > 1) {
      cat("\n")
    }

    # Designate the Stan model
    if (is.null(stanmodel_arg)) {
        # stan file path
        model_path <- paste0(getwd(), "/", model, ".stan")
        stanmodel_arg <- rstan::stan_model(model_path)
    } else if (is.character(stanmodel_arg)) {
      stanmodel_arg <- rstan::stan_model(stanmodel_arg)
    }

    # Initial values for the parameters
    gen_init <- NULL
    if (inits[1] == "vb") {
      if (vb) {
        cat("\n")
        cat("*****************************************\n")
        cat("** Use random values as initial values **\n")
        cat("*****************************************\n")
        gen_init <- "random"

      } else {
        cat("\n")
        cat("****************************************\n")
        cat("** Use VB estimates as initial values **\n")
        cat("****************************************\n")

        make_gen_init_from_vb <- function() {
          fit_vb <- rstan::vb(object = stanmodel_arg, data = data_list)
          m_vb <- colMeans(as.data.frame(fit_vb))

          function() {
            ret <- list(
              mu_pr = as.vector(m_vb[startsWith(names(m_vb), "mu_pr")]),
              sigma = as.vector(m_vb[startsWith(names(m_vb), "sigma")])
            )

            for (p in names(parameters)) {
              ret[[paste0(p, "_pr")]] <-
                as.vector(m_vb[startsWith(names(m_vb), paste0(p, "_pr"))])
            }

            return(ret)
          }
        }

        gen_init <- tryCatch(make_gen_init_from_vb(), error = function(e) {
          cat("\n")
          cat("******************************************\n")
          cat("** Failed to obtain VB estimates.       **\n")
          cat("** Use random values as initial values. **\n")
          cat("******************************************\n")

          return("random")
        })
      }
    } else if (inits[1] == "random") {
      cat("\n")
      cat("*****************************************\n")
      cat("** Use random values as initial values **\n")
      cat("*****************************************\n")
      gen_init <- "random"
    } else {
      if (inits[1] == "fixed") {
        # plausible values of each parameter
        inits <- unlist(lapply(parameters, "[", 2))
      } else if (length(inits) != length(parameters)) {
        stop("** Length of 'inits' must be ", length(parameters), " ",
             "(= the number of parameters of this model). ",
             "Please check again. **\n")
      }

      if (model_type == "single") {
        gen_init <- function() {
          individual_level        <- as.list(inits)
          names(individual_level) <- names(parameters)
          return(individual_level)
        }
      } else {
        gen_init <- function() {
          primes <- numeric(length(parameters))
          for (i in 1:length(parameters)) {
            lb <- parameters[[i]][1]   # lower bound
            ub <- parameters[[i]][3]   # upper bound
            if (is.infinite(lb)) {
              primes[i] <- inits[i]                             # (-Inf, Inf)
            } else if (is.infinite(ub)) {
              primes[i] <- log(inits[i] - lb)                   # (  lb, Inf)
            } else {
              primes[i] <- qnorm((inits[i] - lb) / (ub - lb))   # (  lb,  ub)
            }
          }
          group_level             <- list(mu_pr = primes,
                                          sigma = rep(1.0, length(primes)))
          individual_level        <- lapply(primes, function(x) rep(x, n_subj))
          names(individual_level) <- paste0(names(parameters), "_pr")
          return(c(group_level, individual_level))
        }
      }
    }


    ############### Fit & extract ###############

    # Fit the Stan model
    if (vb) {
      fit <- rstan::vb(object = stanmodel_arg,
                       data   = data_list,
                       pars   = pars,
                       init   = gen_init)
    } else {
      fit <- rstan::sampling(object  = stanmodel_arg,
                             data    = data_list,
                             pars    = pars,
                             init    = gen_init,
                             chains  = nchain,
                             iter    = niter,
                             warmup  = nwarmup,
                             thin    = nthin)
    }

    # Extract from the Stan fit object
    parVals <- rstan::extract(fit, permuted = TRUE)

    # Trial-level posterior predictive simulations
    if (inc_postpred) {
      for (pp in postpreds) {
        parVals[[pp]][parVals[[pp]] == -1] <- NA
      }
    }

    # Define measurement of individual parameters
    measure_indPars <- switch(indPars, mean = mean, median = median, mode = estimate_mode)

    # Define which individual parameters to measure
    which_indPars <- names(parameters)
    if ((task_name == "dd") && (model_type == "single")) {
      which_indPars <- c(which_indPars, log_parameter1)
    }

    # Measure all individual parameters (per subject)
    allIndPars <- as.data.frame(array(NA, c(n_subj, length(which_indPars))))
    if (model_type == "single") {
      allIndPars[n_subj, ] <- mapply(function(x) measure_indPars(parVals[[x]]), which_indPars)
    } else {
      for (i in 1:n_subj) {
        allIndPars[i, ] <- mapply(function(x) measure_indPars(parVals[[x]][, i]), which_indPars)
      }
    }
    allIndPars <- cbind(subjs, allIndPars)
    colnames(allIndPars) <- c("subjID", which_indPars)

    # Model regressors (for model-based neuroimaging, etc.)
    if (modelRegressor) {
      model_regressor <- list()
      for (r in names(regressors)) {
        model_regressor[[r]] <- apply(parVals[[r]], c(1:regressors[[r]]) + 1, measure_indPars)
      }
    }

    # Give back initial colnames and revert data.table to data.frame
    colnames(raw_data) <- colnames_raw_data
    raw_data <- as.data.frame(raw_data)

    # Wrap up data into a list
    modelData                   <- list()
    modelData$model             <- model
    modelData$allIndPars        <- allIndPars
    modelData$parVals           <- parVals
    modelData$fit               <- fit
    modelData$rawdata           <- raw_data
    if (modelRegressor) {
      modelData$modelRegressor  <- model_regressor
    }

    # Object class definition
    class(modelData) <- "hBayesDM"

    # Inform user of completion
    cat("\n")
    cat("************************************\n")
    cat("**** Model fitting is complete! ****\n")
    cat("************************************\n")

    return(modelData)
  }
}

