#
# This script runs the Monte Carlo simulation study for the IID Gamma
# goodness-of-fit test implemented in `gofedf::testGamma()`. For each sample
# size, data are generated from a Gamma distribution with different values for
# the shape parameter and scale = 1. The test is applied using the
# Cramér-von Mises and Anderson-Darling methods, with both discretized and
# non-discretized covariance approximations. The resulting p-values are saved
# and later used to assess whether the empirical type-I error rate is close to
# the nominal level.
#

library(gofedf)
library(parallel)

# Set the possible sample sizes
n <- c(25, 50, 100, 250)

# Set the possible shape values
shape_values <- c(1, 7, 50)

# Number of Monte Carlo repetitions
MC <- 100000

# Number of workers for parallel computation
n_workers <- max(1, detectCores() - 1)

cat("Using", n_workers, "parallel workers.\n")


#
# Helper function to run a Monte Carlo simulation for the IID Gamma(shape, 1)
# setting. For each repetition, generate a sample of size `sample_size`, apply
# gofedf::testGamma() using both the CvM and AD test statistics, and store the
# resulting p-values. The seed is set using the repetition index so that each
# simulated dataset can be reproduced.
#
run_gamma_iid_simulation <- function(sample_size, shape, discretize = FALSE, MC = 10000, n_workers) {
  
  # Force function arguments before sending work to parallel workers.
  sample_size <- as.integer(sample_size)
  shape <- as.numeric(shape)
  discretize <- as.logical(discretize)
  MC <- as.integer(MC)
  n_workers <- as.integer(n_workers)
  
  cl <- parallel::makeCluster(n_workers)
  on.exit(parallel::stopCluster(cl), add = TRUE)
  
  pval <- parallel::parLapply(cl, 1:MC, function(i) {
    
    # Set the seed for reproducibility
    set.seed(i)
    
    # Generate sample from Gamma(shape, 1)
    x <- rgamma(n = sample_size, shape = shape, scale = 1)
    
    # Run CvM test
    tmp_cvm <- gofedf::testGamma(
      x = x,
      method = "cvm",
      discretize = discretize
    )
    
    # Run AD test
    tmp_ad <- gofedf::testGamma(
      x = x,
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


dir.create("results/gamma", recursive = TRUE, showWarnings = FALSE)

for(j in n){
  for(k in shape_values){
    for(disc in c(FALSE, TRUE)){
      
      cat(
        "Simulation for Gamma: n =", j,
        ", shape =", k,
        ", scale = 1",
        ", discretize =", disc,
        "\n"
      )
      
      pvalue <- run_gamma_iid_simulation(
        sample_size = j,
        shape = k,
        discretize = disc,
        MC = MC,
        n_workers = n_workers
      )
      
      saveRDS(
        object = pvalue,
        file = paste0(
          "results/gamma/gamma_iid_n", j,
          "_shape", k,
          "_discretize_", disc,
          "_pvalues.rds"
        )
      )
    }
  }
}