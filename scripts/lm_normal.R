#
# This script runs the Monte Carlo simulation study for the linear-model
# residual normality goodness-of-fit test implemented in `gofedf::testLMNormal()`.
# For each sample size, data are generated from a linear regression model with
# normally distributed errors. A linear model is fitted to each simulated data
# set, and `testLMNormal()` is used to assess whether the model errors are
# consistent with normality. The test is applied using the Cramér-von Mises and
# Anderson-Darling methods, with both discretized and non-discretized covariance
# approximations. The resulting p-values are saved and later used to assess
# whether the empirical type-I error rate is close to the nominal level.
#

library(gofedf)
library(parallel)

# Set the possible sample sizes
n <- c(25, 50, 100, 250)

# Number of regressors in the linear model
k <- c(2, 5, 10)

# Number of Monte Carlo repetitions
MC <- 100000

# Number of workers for parallel computation
n_workers <- max(1, detectCores() - 1)

cat("Using", n_workers, "parallel workers.\n")


#
# Helper function to run a Monte Carlo simulation for the linear-model normal
# error setting. For each repetition, generate a response from a linear model
# with normal errors, fit the linear model, apply gofedf::testLMNormal(), and
# store the resulting CvM and AD p-values.
# Note: k is the number of independent variables in the linear model
#
run_lm_normal_simulation <- function(sample_size, k = 2, discretize = FALSE, MC = 10000, n_workers = 1) {
  
  # Force inputs to the expected types before passing them to parallel workers.
  sample_size <- as.integer(sample_size)
  k           <- as.integer(k)
  discretize  <- as.logical(discretize)
  MC          <- as.integer(MC)
  n_workers   <- as.integer(n_workers)
  
  cl <- makeCluster(n_workers)
  on.exit(stopCluster(cl), add = TRUE)
  
  pval <- parLapply(cl, 1:MC, function(i) {
    
    # Set the seed for reproducibility
    set.seed(i)
    
    # Generate regressors
    X <- matrix(
      data = rnorm(sample_size * k),
      nrow = sample_size,
      ncol = k
    )
    
    colnames(X) <- paste0("x", seq_len(k))
    
    # Generate regression coefficients
    beta <- runif(k)
    
    # Generate normal errors
    e <- rnorm(sample_size, mean = 0, sd = 1)
    
    # Generate response from the linear model
    y <- as.vector(X %*% beta + e)
    
    # Put data into a data frame for lm()
    dat <- data.frame(y = y, X)
    
    # Fit linear model
    model_fit <- lm(y ~ ., data = dat, x = TRUE, y = TRUE)
    
    # Run CvM test
    tmp_cvm <- gofedf::testLMNormal(
      fit = model_fit,
      method = "cvm",
      discretize = discretize
    )
    
    # Run AD test
    tmp_ad <- gofedf::testLMNormal(
      fit = model_fit,
      method = "ad",
      discretize = discretize
    )
    
    # Store p-values
    c(
      cvm = tmp_cvm$pvalue,
      ad = tmp_ad$pvalue
    )
  })
  
  return(pval)
}


dir.create("results/lm_normal", recursive = TRUE, showWarnings = FALSE)

for(i in n){
  for(j in k){
    for(disc in c(FALSE, TRUE)){
    
      cat("Simulation for LM Normal: n =", i, ", k =", k, ", discretize =", disc, "\n")
    
      pvalue <- run_lm_normal_simulation(
        sample_size = i,
        k = j,
        discretize = disc,
        MC = MC,
        n_workers = n_workers
      )
    
      saveRDS(
        object = pvalue,
        file = paste0(
          "results/lm_normal/lm_normal_n", i,
          "_k", j,
          "_discretize_", disc,
          "_pvalues.rds"
        )
      )
    }
  }
}