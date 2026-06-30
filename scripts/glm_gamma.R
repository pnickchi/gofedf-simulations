#
# This script runs the Monte Carlo simulation study for the Gamma GLM
# goodness-of-fit test implemented in `gofedf::testGLMGamma()`. For each sample
# size, data are generated from a Gamma generalized linear model with a log link.
# A Gamma GLM is fitted to each simulated data set, and `testGLMGamma()` is used
# to assess whether the fitted Gamma GLM is consistent with the data-generating
# mechanism. The test is applied using the Cramér-von Mises and Anderson-Darling
# methods, with both discretized and non-discretized covariance approximations.
# The resulting p-values are saved and later used to assess whether the empirical
# type-I error rate is close to the nominal level.
#

library(gofedf)
library(parallel)

# Set the possible sample sizes
n <- c(25, 50, 100, 250)

# Set the possible number of regressors
k_values <- c(2, 5, 10)

# Gamma shape parameter used in the data-generating model
gamma_shape <- c(1, 7, 50)

# Number of Monte Carlo repetitions
MC <- 100000

# Number of workers for parallel computation
n_workers <- max(1, detectCores() - 1)

cat("Using", n_workers, "parallel workers.\n")


#
# Helper function to run a Monte Carlo simulation for the Gamma GLM setting.
# For each repetition, generate a response from a Gamma GLM with log link, fit
# the Gamma GLM, apply gofedf::testGLMGamma(), and store the resulting CvM and
# AD p-values. The seed is set using the repetition index so that each simulated
# data set can be reproduced.
#
run_glm_gamma_simulation <- function(sample_size, k = 2, gamma_shape,
                                     discretize = FALSE, MC = 10000,
                                     n_workers = 1) {
  
  # Force inputs to the expected types before passing them to parallel workers.
  sample_size <- as.integer(sample_size)
  k           <- as.integer(k)
  gamma_shape <- as.numeric(gamma_shape)
  discretize  <- as.logical(discretize)
  MC          <- as.integer(MC)
  n_workers   <- as.integer(n_workers)
  
  # Use at most MC workers
  n_workers <- min(n_workers, MC)
  
  # simulate random values for explanatory variable
  set.seed(1)
  X          <- matrix(data = rnorm(sample_size * k, mean = 2, sd = 0.1), nrow = sample_size, ncol = k)
  
  # Randomly generate some coefficients
  set.seed(2)
  beta <- runif(n = k, min = 1.5, max = 2.5) 

  # Set the initial values for glm.control() function
  control <- glm.control(epsilon = 1e-08, maxit = 100, trace = F)

  cl <- makeCluster(n_workers)
  on.exit(stopCluster(cl), add = TRUE)
  
  pval <- parLapply(cl, 1:MC, function(i) {

      # Set the seed for reproducibility
      set.seed(i)
    
      # Generate some error terms from Gamma dist
      e          <- rgamma(sample_size, shape = gamma_shape)

      # Compute value of y
      y          <- exp(X %*% beta) * e
      
      # Fit generalized linear model with log link function
      fm  <- Gamma(link = 'log')
      model_fit <- glm2::glm2(y ~ X, family = fm, x = TRUE, start = c(mean(e), beta), control = control)

      # Run CvM test
      tmp_cvm <- gofedf::testGLMGamma(
        fit = model_fit,
        method = "cvm",
        discretize = discretize
      )
      
      # Run AD test
      tmp_ad <- gofedf::testGLMGamma(
        fit = model_fit,
        method = "ad",
        discretize = discretize
      )
      
      # Store p-values
      c(cvm = tmp_cvm$pvalue, ad = tmp_ad$pvalue)

  })
  
  return(pval)
}


dir.create("results/glm_gamma", recursive = TRUE, showWarnings = FALSE)

for(i in n){
  for(j in k_values){
    for(a in gamma_shape){
      for(disc in c(FALSE, TRUE)){
      
        cat(
          "Simulation for GLM Gamma: n =", i,
          ", k =", j,
          ", gamma_shape =", a,
          ", discretize =", disc,
          "\n"
        )
        
        pvalue <- run_glm_gamma_simulation(
          sample_size = i,
          k = j,
          gamma_shape = a,
          discretize = disc,
          MC = MC,
          n_workers = n_workers
        )
        
        saveRDS(
          object = pvalue,
          file = paste0(
            "results/glm_gamma/glm_gamma_n", i,
            "_k", j,
            "_shape", a,
            "_discretize_", disc,
            "_pvalues.rds"
          )
        )
    }
  }
  }
}
