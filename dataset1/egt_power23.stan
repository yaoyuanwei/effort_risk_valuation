data {
  int<lower=1> N;
  int<lower=1> T;
  int<lower=1, upper=T> Tsubj[N];
  real<lower=0> gain[N, T];
  real<lower=0> loss[N, T];
  real<lower=0> coste[N, T];
  real<lower=0> costr[N, T];
  int<lower=-1, upper=1> choice[N, T]; // 0 for small reward, 1 for large reward
}

transformed data {
}

parameters {
// Declare all parameters as vectors for vectorizing
  // Hyper(group)-parameters
  vector[6] mu_pr;
  vector<lower=0>[6] sigma;

  // Subject-level raw parameters (for Matt trick)
  vector[N] k_pr;
  vector[N] p1_pr;
  vector[N] p2_pr;
  vector[N] rho_pr;
  vector[N] lambda_pr;
  vector[N] beta_pr;
}

transformed parameters {
  // Transform subject-level raw parameters
  vector<lower=0, upper=50>[N] k;
  vector<lower=0, upper=5>[N] p1;
  vector<lower=0, upper=5>[N] p2;
  vector<lower=0, upper=1>[N] rho;
  vector<lower=0, upper=5>[N] lambda;
  vector<lower=0, upper=20>[N] beta;

  for (i in 1:N) {
    k[i]      = Phi_approx(mu_pr[1] + sigma[1] * k_pr[i]) * 50;
    p1[i]     = Phi_approx(mu_pr[2] + sigma[2] * p1_pr[i]) * 5;
    p2[i]     = Phi_approx(mu_pr[3] + sigma[3] * p2_pr[i]) * 5;
    rho[i]    = Phi_approx(mu_pr[4] + sigma[4] * rho_pr[i]);
    lambda[i] = Phi_approx(mu_pr[5] + sigma[5] * lambda_pr[i]) * 5;
    beta[i]   = Phi_approx(mu_pr[6] + sigma[6] * beta_pr[i]) * 20;
  }
}

model {
// Hyperbolic function
  // Hyperparameters
  mu_pr  ~ normal(0, 1);
  sigma  ~ normal(0, 0.2);

  // individual parameters
  k_pr      ~ normal(0, 1);
  p1_pr     ~ normal(0, 1);
  p2_pr     ~ normal(0, 1);
  rho_pr    ~ normal(0, 1);
  lambda_pr ~ normal(0, 1);
  beta_pr   ~ normal(0, 1);

  for (i in 1:N) {
    // Define values
    real c_effort;
    real c_risk;
    real c_gamble;
    real sv_gamble;

    for (t in 1:(Tsubj[i])) {
      c_effort  = k[i] * pow(coste[i, t], p1[i]);
      c_risk    = k[i] * pow(costr[i, t], p2[i]);
      c_gamble  = c_effort + c_risk;
      sv_gamble = pow(gain[i, t], rho[i]) - lambda[i] * pow(loss[i, t], rho[i]) - c_gamble;
      choice[i, t] ~ bernoulli_logit(beta[i] * sv_gamble);
    }
  }
}
generated quantities {
  // For group level parameters
  real<lower=0, upper=50> mu_k;
  real<lower=0, upper=5> mu_p1;
  real<lower=0, upper=5> mu_p2;
  real<lower=0, upper=1> mu_rho;
  real<lower=0, upper=5> mu_lambda;
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

  mu_k      = Phi_approx(mu_pr[1]) * 50;
  mu_p1     = Phi_approx(mu_pr[2]) * 5;
  mu_p2     = Phi_approx(mu_pr[3]) * 5;
  mu_rho    = Phi_approx(mu_pr[4]);
  mu_lambda = Phi_approx(mu_pr[5]) * 5;
  mu_beta   = Phi_approx(mu_pr[6]) * 20;

  { // local section, this saves time and space
    for (i in 1:N) {
      // Define values
      real c_effort;
      real c_risk;
      real c_gamble;
      real sv_gamble;

      log_lik[i] = 0;

      for (t in 1:(Tsubj[i])) {
        c_effort  = k[i] * pow(coste[i, t], p1[i]);
        c_risk    = k[i] * pow(costr[i, t], p2[i]);
        c_gamble  = c_effort + c_risk;
        sv_gamble = pow(gain[i, t], rho[i]) - lambda[i] * pow(loss[i, t], rho[i]) - c_gamble;
        log_lik[i] += bernoulli_logit_lpmf(choice[i, t] | beta[i] * sv_gamble);

        // generate posterior prediction for current trial
        y_pred[i, t] = bernoulli_rng(inv_logit(beta[i] * sv_gamble));
      }
    }
  }
}

