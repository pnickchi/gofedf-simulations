# gofedf Simulation Studies

This repository contains Monte Carlo simulation studies for goodness-of-fit tests implemented in the [`gofedf`](https://cran.r-project.org/package=gofedf) R package.

The goal is to study the finite-sample behavior of the tests under the null model, with a focus on the empirical distribution of p-values and estimated type-I error rates.

## Simulation studies

The current simulations include:

* IID Normal simulations using `gofedf::testNormal()`
* IID Gamma simulations using `gofedf::testGamma()`
* Linear model normal-error simulations using `gofedf::testLMNormal()`
* Gamma GLM simulations using `gofedf::testGLMGamma()`

For each setting, the tests are applied using:

* Cramér-von Mises statistic
* Anderson-Darling statistic
* discretized covariance approximation
* non-discretized covariance approximation

The sample sizes considered are:

```r
c(25, 50, 100, 250)
```

## Repository structure

```text
.
├── scripts/      # R scripts used to run the simulations
├── results/      # Saved simulation outputs, mainly p-values
├── reports/      # Quarto files used to summarize results
├── docs/         # Rendered website files
├── Makefile      # Commands for running simulations and rendering reports
└── _quarto.yml   # Quarto website configuration
```

## Running the simulations

To run all simulations and render the website:

```bash
make all
```

This runs the simulation scripts in the following order:

```text
1. IID Normal
2. IID Gamma
3. Linear model normal errors
4. Gamma GLM
5. Quarto reports
```

To run only one simulation:

```bash
make normal
make gamma
make lm-normal
make glm-gamma
```

To render only the reports:

```bash
make reports
```

To clean previous simulation outputs and rendered reports:

```bash
make clean
```

To clean and rerun a specific simulation, for example Gamma:

```bash
make clean-gamma gamma
```

## Reproducibility

Each Monte Carlo repetition uses a deterministic seed based on the repetition index. This means that each simulated data set can be regenerated from its repetition number.

The simulations save p-values as `.rds` files in the `results/` folder. The reports read these saved outputs and compute:

* p-value histograms
* empirical type-I error rates at level 0.05

The GitHub Actions workflow only renders the Quarto website. It does not rerun the simulations.

## Website

The rendered simulation reports are available as a Quarto website:

```text
https://pnickchi.github.io/gofedf-simulations
```

Replace this with the actual GitHub Pages URL after deployment.

## Requirements

The simulations require R and the following R packages:

```r
install.packages(c(
  "gofedf",
  "glm2",
  "ggplot2",
  "dplyr",
  "purrr",
  "tibble",
  "tidyr",
  "knitr",
  "quarto"
))
```

You also need Quarto installed on your system to render the reports.

## Notes

Large Monte Carlo simulations can take time to run. For development and testing, reduce the number of Monte Carlo repetitions in the simulation scripts before running the full study.

The simulation results in `results/` are used by the Quarto reports. Therefore, if the result files are removed, the reports must be regenerated after rerunning the simulations.
