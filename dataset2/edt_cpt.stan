data {
  int<lower=1> N;
  int<lower=1> T;
  int<lower=1, upper=T> Tsubj[N];
  real<lower=0> cost_one[N, T];
  real<lower=0> amount_one[N, T];
  real<lower=0> cost_two[N, T];
  real<lower=0> amount_two[N, T];
  int<lower=-1, upper=1> choice[N, T]; // 0 for small reward, 1 for large reward
}

transformed data {
}

parameters {
// Declare all parameters as vectors for vectorizing
  // Hyper(group)-parameters
  vector[4] mu_pr;
  vector<lower=0>[4] sigma;

  // Subject-level raw parameters (for Matt trick)
  vector[N] rho_pr;
  vector[N] gamma_pr;
  vector[N] delta1_pr;
  vector[N] beta_pr;
}

transformed parameters {
  // Transform subject-level raw parameters
  vector<lower=0, upper=1>[N] rho;
  vector<lower=0, upper=1>[N] gamma;
  vector<lower=0, upper=5>[N] delta1;
  vector<lower=0, upper=20>[N] beta;

  for (i in 1:N) {
    rho[i]    = Phi_approx(mu_pr[1] + sigma[1] * rho_pr[i]);
    gamma[i]  = Phi_approx(mu_pr[2] + sigma[2] * gamma_pr[i]);
    delta1[i] = Phi_approx(mu_pr[3] + sigma[3] * delta1_pr[i]) * 5;
    beta[i]   = Phi_approx(mu_pr[4] + sigma[4] * beta_pr[i]) * 10;
  }
}

model {
// Cumulative prospect theory (CPT)
  // Hyperparameters
  mu_pr  ~ normal(0, 1);
  sigma  ~ normal(0, 0.2);

  // individual parameters
  rho_pr    ~ normal(0, 1);
  gamma_pr  ~ normal(0, 1);
  delta1_pr ~ normal(0, 1);
  beta_pr   ~ normal(0, 1);

  for (i in 1:N) {
    // Define values
    real p_one;
    real p_two;
    real w_one;
    real w_two;
    real sv_one;
    real sv_two;

    for (t in 1:(Tsubj[i])) {
      p_one   = (1-cost_one[i, t]);
      p_two   = (1-cost_two[i, t]);
      w_one   = (delta1[i] * pow(p_one, gamma[i]))/(delta1[i] * pow(p_one, gamma[i]) + pow((1-p_one), gamma[i]));
      w_two   = (delta1[i] * pow(p_two, gamma[i]))/(delta1[i] * pow(p_two, gamma[i]) + pow((1-p_two), gamma[i]));

      // Subjective values of the two options
      sv_one  = w_one * (pow(amount_one[i, t], rho[i]));
      sv_two  = w_two * (pow(amount_two[i, t], rho[i]));

      // Generate choices based subjective values
      choice[i, t] ~ bernoulli_logit(beta[i] * (sv_one - sv_two));
    }
  }
}
generated quantities {
  // For group level parameters
  real<lower=0, upper=1>  mu_rho;
  real<lower=0, upper=1>  mu_gamma;
  real<lower=0, upper=5>  mu_delta1;
  real<lower=0, upper=20> mu_beta;

  // For log likelihood calculation
  real log_lik[N];

  // For posterior predictive check
  real y_pred[N, T];

  // Set all posterior predictions to 0 (avoids NULL values)
  for (i in 1:N) {
    for (t in 1:T) {
      y_pred[i, t] = -1;
    }
  }

  mu_rho    = Phi_approx(mu_pr[1]);
  mu_gamma  = Phi_approx(mu_pr[2]);
  mu_delta1 = Phi_approx(mu_pr[3]) * 5;
  mu_beta   = Phi_approx(mu_pr[4]) * 20;

  { // local section, this saves time and space
    for (i in 1:N) {
      // Define values
      real p_one;
      real p_two;
      real w_one;
      real w_two;
      real sv_one;
      real sv_two;

      log_lik[i] = 0;

      for (t in 1:(Tsubj[i])) {
        p_one   = (1-cost_one[i, t]);
        p_two   = (1-cost_two[i, t]);
        w_one   = (delta1[i] * pow(p_one, gamma[i]))/(delta1[i] * pow(p_one, gamma[i]) + pow((1-p_one), gamma[i]));
        w_two   = (delta1[i] * pow(p_two, gamma[i]))/(delta1[i] * pow(p_two, gamma[i]) + pow((1-p_two), gamma[i]));
        sv_one  = w_one * (pow(amount_one[i, t], rho[i]));
        sv_two  = w_two * (pow(amount_two[i, t], rho[i]));
        log_lik[i] += bernoulli_logit_lpmf(choice[i, t] | beta[i] * (sv_one - sv_two));

        // generate posterior prediction for current trial
        y_pred[i, t] = bernoulli_rng(inv_logit(beta[i] * (sv_one - sv_two)));
      }
    }
  }
}

