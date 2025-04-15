---
title: "A Practical Primer on Bayesian Statistics"
author: "Sarah Urbut, MD PhD"
date: "March 29, 2025"
format: 
  revealjs:
    theme: simple
    slide-number: true
    incremental: false
    transition: slide
    code-fold: true
    code-tools: true
    highlight-style: github

editor: 
  markdown: 
    wrap: 72
---

```{r setup, include=FALSE}
# Load necessary packages
library(tidyverse)
library(ggplot2)
library(reshape2)
library(viridis)
library(gtools)     # For Dirichlet distribution
library(gridExtra)  # For arranging plots

# Set a clean theme for all plots
theme_set(theme_minimal(base_size = 12) + 
          theme(plot.title = element_text(hjust = 0.5),
                plot.subtitle = element_text(hjust = 0.5)))

# Set seed for reproducibility
set.seed(42)
```

## Overview

In this seminar, we'll (attempt to) cover key Bayesian concepts critical
for modern genomics:

1.  **P-values vs. Posterior Probabilities**: Why Bayesian thinking
    helps avoid misinterpretations\
2.  **Conjugate Models**: Elegant solutions for population genetic
    inference\
3.  **Mixture Models**: Powerful tools for complex genomic data\
4.  **Bayesian Clinical & Adaptive Designs**: Learning and adapting as
    data accumulates

# 1. The P-value Paradox

## Lindley's Paradox

> "A result that is statistically significant may not be scientifically
> significant" - Dennis Lindley (1957)

::: callout-note
Lindley's 1957 paper demonstrated how p-values and Bayes factors can
lead to contradictory conclusions [@lindley1957]
:::

## The Evidence Paradox

Sometimes a result can be unlikely under the null hypothesis but even
more unlikely under the alternative!

## Example

```{r}
# Create example of evidence paradox
z <- seq(-5, 5, length.out = 1000)
null_density <- dnorm(z, 0, 1)
alt_density <- dnorm(z, 5, 1)  # Alternative with larger variance

# Create example point
z_obs <- 2.5  # A "significant" observation
null_prob <- dnorm(z_obs, 0, 1)
alt_prob <- dnorm(z_obs, 6, 1)

# Create data frame for plotting
paradox_data <- data.frame(
    z = z,
    Null = null_density,
    Alternative = alt_density
)

# Plot
ggplot() +
    geom_line(data = paradox_data, aes(x = z, y = Null, color = "Null"), size = 2) +
    geom_line(data = paradox_data, aes(x = z, y = Alternative, color = "Alternative"), size = 2) +
    geom_vline(xintercept = z_obs, linetype = "dashed") +
    geom_point(aes(x = z_obs, y = null_prob), color = "red", size = 5) +
    geom_point(aes(x = z_obs, y = alt_prob), color = "blue", size = 5) +
    scale_color_manual(values = c("Null" = "red", "Alternative" = "blue")) +
    annotate("text", x = z_obs - 1.5, y = null_prob+0.1, 
             label = sprintf("p(z|H_0) = %.3f", null_prob), size = 4) +
    annotate("text", x = z_obs +1.5, y = alt_prob+0.1, 
             label = sprintf("p(z|H_1) = %.3f", alt_prob), size =4 ) +
    labs(title = "The Evidence Paradox",
         subtitle = "A result can be unlikely under H0 but even more unlikely under H1",
         x = "Z-score",
         y = "Density") +
    theme_minimal(base_size = 20) +
    theme(legend.position = "bottom",
          legend.text = element_text(size = 16),
          legend.title = element_text(size = 18),
          axis.text = element_text(size = 18),
          axis.title = element_text(size = 18),
          plot.title = element_text(size = 22),
          plot.subtitle = element_text(size = 12))
```

::: notes
This paradox shows why we need to consider both the null and alternative
hypotheses: - A small p-value only tells us the result is unlikely under
$H_0$ - But for real evidence, we need the result to be more likely
under $H_1$ than $H_0$ - This is why Bayes factors (likelihood ratios)
are more informative than p-values
:::

## The P-value Fallacy

What we want: P(Hypothesis\|Data)\
What we get: P(Data\|Null Hypothesis)

Question for the class: What is a P value?

Prepare to be amazed: Frequentists are all Bayesians! (under some
qualifications)

## Probabilistic Interpretation of Estimates

::::: columns
::: {.column width="50%"}
In the Bayesian framework:

-   **Parameters are random variables** with distributions, not fixed
    values
-   **Uncertainty is represented directly** through probability
    distributions
-   **All evidence is integrated coherently** within a probability
    framework
-   **Natural quantification of uncertainty** *without* hypothetical
    repeated sampling
-   **Interpretation is direct and intuitive** for researchers and
    clinicians
:::

::: {.column width="50%"}
```{r}
# Create example data for frequentist vs Bayesian comparison
x <- seq(0.2, 0.8, length = 1000)

# Bayesian posterior (beta distribution)
post_y <- dbeta(x, 70, 30)

# Create data frame for plotting
plot_data <- data.frame(
  x = x,
  y = post_y
)

# Point estimate
point_est <- 0.7
ci_lower <- 0.61
ci_upper <- 0.79
cred_lower <- qbeta(0.025, 70, 30)
cred_upper <- qbeta(0.975, 70, 30)

# Get maximum y value for annotation positioning
max_y_val <- max(plot_data$y)

# Plot
ggplot(plot_data, aes(x = x, y = y)) +
  geom_line(size = 1.2, color = "darkblue") +
  geom_vline(xintercept = point_est, color = "red", linetype = "dashed") +
  geom_segment(aes(x = ci_lower, xend = ci_upper, y = max_y_val/10, yend = max_y_val/10), 
               color = "darkred", size = 2) +
  geom_segment(aes(x = cred_lower, xend = cred_upper, y = max_y_val/5, yend = max_y_val/5), 
               color = "darkblue", size = 2) +
  annotate("text", x = point_est + 0.05, y = max_y_val/1.5, 
           label = "Point Estimate", color = "red") +
  annotate("text", x = ci_lower - 0.05, y = max_y_val/10, 
           label = "95% CI", color = "darkred") +
  annotate("text", x = cred_upper + 0.05, y = max_y_val/5, 
           label = "95% Credible Interval", color = "darkblue") +
  labs(title = "Bayesian Posterior Distribution",
       subtitle = "Directly interpretable probability statements about parameters",
       x = "Parameter Value", 
       y = "Posterior Density") +
  theme_minimal()
```
:::
:::::

## Bayesian vs. Frequentist Intervals

| Bayesian Credible Interval | Frequentist Confidence Interval |
|----------------------------------|--------------------------------------|
| "95% probability the parameter is between a and b" | "If we repeated the experiment many times, 95% of intervals constructed would contain the true parameter" |
| Directly interpretable as probability statement about the parameter | Cannot be interpreted as probability statement about the parameter |
| Incorporates prior information | No mechanism to incorporate prior information (why would you run?) |
| Can be asymmetric, reflecting asymmetric uncertainty | Typically symmetric by construction |
| Conditioning on the observed data | Based on hypothetical repeated (theoretical) sampling |

## Bayes' Theorem - The Core Idea

$$P(H|D) = \frac{P(D|H) \times P(H)}{P(D)}$$

Where:

-   $P(H|D)$ is the **posterior probability** - what we want to know
-   $P(D|H)$ is the **likelihood** - how probable the data is under our
    hypothesis
-   $P(H)$ is the **prior probability** - what we knew before
-   $P(D)$ is the **evidence** - a normalizing constant

Simply: **Posterior ∝ Likelihood × Prior**

## Bayesian Updating: Visual Intuition

```{r bayesian-updating}
# Create data for three distributions
x <- seq(0.001, 0.999, length = 1000)
prior <- data.frame(x = x, y = dbeta(x, 2, 3), Distribution = "Prior: Beta(2,3)")
likelihood <- data.frame(x = x, y = dbeta(x, 7, 3), Distribution = "Likelihood (Data)")
posterior <- data.frame(x = x, y = dbeta(x, 9, 6), Distribution = "Posterior: Beta(9,6)")

# Combine data
all_distributions <- rbind(prior, likelihood, posterior)

# Plot all three distributions
ggplot(all_distributions, aes(x = x, y = y, color = Distribution)) +
  geom_line(size = 1.2) +
  scale_color_manual(values = c("darkgreen", "purple", "red")) +
  labs(title = "Bayesian Updating of Allele Frequency Estimate",
       subtitle = "Combining prior knowledge with new data",
       x = "Allele Frequency", 
       y = "Density") +
  theme(legend.position = "bottom")
```

# P-values vs. Posterior Probabilities

## The Question

As scientists, we want to know:

> "What is the probability that my hypothesis is true, given my data?"

But traditional p-values answer a different question:

> "What is the probability of observing data this extreme or more
> extreme, if the null hypothesis is true?"

This mismatch causes persistent misinterpretations.

## P-values vs. Bayes Factors: Definitions

**P-value**:\
- $P(data|H_0)$ - probability of data given null hypothesis\
- Measures compatibility of data with null hypothesis\
- Does not directly measure evidence for alternative

**Bayes Factor**:\
- $BF_{10} = \frac{P(data|H_1)}{P(data|H_0)}$ - ratio of likelihoods

\- $BF_{01} = \frac{P(data|H_0)}{P(data|H_1)}$ - ratio of likelihoods\
- Directly compares evidence for alternative vs. null OR null vs
alternative\
- Tells you how much to update your beliefs

## The P-value Fallacy

**Scenario**: Testing a SNP for disease association

**Traditional approach**:\
- Obtain p = 0.001\
- Declare "significant association"\
- Publish result

**The fallacy**:\
- p = 0.001 means "1 in 1000 chance of seeing this data if no
association exists"\
- NOT "999 in 1000 chance the association is real"

## Visualize

```{r}
# Parameters
prior_prob <- 1/1000  # Prior probability of true association
p_value <- 0.001      # Observed p-value

# Convert p-value to z-score
z <- qnorm(p_value/2, lower.tail = FALSE)

# Calculate Bayes factor (approximate)
bf <- exp(z^2/2)

# Calculate posterior probability
posterior <- (prior_prob * bf) / (prior_prob * bf + (1 - prior_prob))

# Create data for visualization
df <- data.frame(
  Stage = factor(c("Prior", "p-value", "Posterior"), 
                levels = c("Prior", "p-value", "Posterior")),
  Probability = c(prior_prob, 1-p_value, posterior),
  Label = c(paste0(round(prior_prob*100, 2), "%"), 
           paste0(round((1-p_value)*100, 1), "%"), 
           paste0(round(posterior*100, 1), "%"))
)

# Create plot
ggplot(df, aes(x = Stage, y = Probability)) +
  geom_bar(stat = "identity", fill = c("lightblue", "orange", "darkgreen"), width = 0.6) +
  geom_text(aes(label = Label), vjust = -0.5, size = 5) +
  ylim(0, 1) +
  labs(title = "The p-value Fallacy",
       subtitle = "p = 0.001 doesn't mean 99.9% chance of true association (^app)",
       x = "", y = "Probability") +
  theme_minimal(base_size = 14)
```

**Key insight**: With a realistic prior of 1/1000, a "significant"
p-value of 0.001 only gives \~18% posterior probability of true
association! (app interlude) [Shiny
P!](https://surbut.shinyapps.io/shinypval/)

## The Mathematical Connection

Under certain conditions, p-values can be converted to minimum Bayes
factors:

$$BF_{min} ≈ -e \times p \times \log(p)$$

Meaning even the most favorable interpretation of a p-value provides
less evidence than typically assumed:

| p-value | Minimum Bayes Factor |
|---------|----------------------|
| 0.05    | 0.37                 |
| 0.01    | 0.084                |
| 0.001   | 0.0083               |

## What is the Minimum Bayes Factor?

The Minimum Bayes Factor is calculated as:\
$\text{MBF} \approx -e \times p \times \log(p)$

This formula (derived by Sellke, Bayarri, and Berger) represents the
**smallest possible Bayes factor** that could correspond to a given
p-value, regardless of the specific alternative hypothesis being tested
(i.e p(D\|H0)/p(D/H1))

------------------------------------------------------------------------

## Why "Minimum"?

It's called "minimum" because:

-   It assumes the most favorable conditions for the alternative
    hypothesis\
-   It represents the strongest possible evidence against the null that
    could be derived from a p-value\
-   It's the smallest value the Bayes factor could take (stronger
    evidence against null = smaller Bayes factor)

## Interpretation

The MBF represents the ratio of likelihoods:\
$\text{MBF} = \frac{P(\text{data}|H_0)}{P(\text{data}|H_1)}$

For example, with p = 0.05: MBF = 0.37 This means the data are at most
1/0.37 ≈ 2.7 times more likely under the alternative than the null\
Even with the most optimistic assumptions, the evidence against the null
is modest

## Why This Conversion Matters

This conversion from p-values to MBF is important because:

-   It provides a more calibrated interpretation of statistical
    evidence\
-   It shows that conventional "statistical significance" (p \< 0.05)
    actually represents fairly modest evidence\
-   It helps researchers avoid overinterpreting p-values\
-   It establishes a link between frequentist and Bayesian approaches

## p-values systematically overstate the evidence against the null hypothesis.

When converted to the Bayes factor scale, even a seemingly impressive
p-value often translates to much more moderate evidence against the null
hypothesis than most researchers would expect.

## P-values vs. Bayes Factors in Genomics

```{r}
# Create data
p_values <- 10^seq(-8, -2, 0.5)
log10_p <- -log10(p_values)
min_bf <- -exp(1) * p_values * log(p_values)
log10_min_bf <- -log10(min_bf)

# Create plot data
plot_data <- data.frame(
  log10_p = log10_p,
  log10_min_bf = log10_min_bf
)

# Plot
ggplot(plot_data, aes(x = log10_p, y = log10_min_bf)) +
  geom_line(size = 1.5, color = "blue") +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "red") +
  geom_vline(xintercept = -log10(5e-8), linetype = "dotted", color = "darkgreen") +
  annotate("text", x = 8, y = 4, label = "GWAS significance\nthreshold", color = "darkgreen") +
  labs(title = "Strength of Evidence: P-values vs. Bayes Factors",
       x = "-log10(p-value)",
       y = "-log10(Minimum Bayes Factor)") +
  theme_minimal(base_size = 14)
```

The GWAS significance threshold of p \< 5×10⁻⁸ corresponds to much
stronger evidence than p = 0.05.

::: callout-note
Berger and Sellke (1987) showed that p-values systematically overstate
evidence against the null [@berger1987]
:::

## Interpreting Bayes Factors

Bayes factors have a natural interpretation:

| Bayes Factor ($BF_{10}$) | Evidence for H1         |
|--------------------------|-------------------------|
| 1 - 3                    | Barely worth mentioning |
| 3 - 10                   | Substantial             |
| 10 - 30                  | Strong                  |
| 30 - 100                 | Very strong             |
| \> 100                   | Extreme                 |

A $BF_{10} = 10$ means the data are 10 times more likely under H1 than
H0.

## From Bayes Factor to Posterior Probability

Bayes' theorem connects all the pieces:

$$P(H_1|data) = \frac{P(data|H_1)P(H_1)}{P(data|H_1)P(H_1) + P(data|H_0)P(H_0)}$$

This can be rewritten using the Bayes factor:

$$P(H_1|data) = \frac{BF_{10} \times P(H_1)}{BF_{10} \times P(H_1) + P(H_0)}$$

## Posterior Odds Formulation

A simplified version:

$$\text{Posterior Odds} = \text{Bayes Factor} \times \text{Prior Odds}$$

Or:

$$\frac{P(H_1|data)}{P(H_0|data)} = BF_{10} \times \frac{P(H_1)}{P(H_0)}$$

This clearly shows how Bayes factors calibrate our prior beliefs (and we
can use this on the wards!).

## Benefits of Bayes Factors for Genomics

1.  **Calibrated evidence**: Direct measure of evidence strength\
2.  **Multiple testing**: Naturally incorporates prior odds\
3.  **Replication**: Coherent framework for combining evidence across
    studies\
4.  **Diverse hypotheses**: Can compare non-nested models\
5.  **Positive evidence**: Can support null hypothesis, not just reject
    it\
6.  **Study design**: Allows stopping when evidence is sufficient

## Key Takeaways

1.  P-values answer a different question than most scientists ask\
2.  Bayes factors directly compare competing hypotheses\
3.  Even "significant" p-values provide weaker evidence than typically
    assumed\
4.  Bayes factors have a natural interpretation as evidence strength\
5.  Converting to posterior probabilities requires considering prior
    odds\
6.  In genomics, this perspective helps manage false discovery rates

## The Fallacy of P-values

::: incremental
-   P-values answer a **counterfactual question**: "If there were no
    effect, how surprising would these data be?"

-   But researchers want to know: "**What is the probability this
    association is real?**"

-   This disconnect leads to systematic misinterpretation
:::

## 2. The Multiple Testing Challenge

Modern genomics routinely tests **thousands to millions** of hypotheses:

-   20,000+ genes in differential expression\
-   Millions of variants in GWAS\
-   Billions of potential interactions

**The consequence**: Many "significant" findings are actually false
positives.

## The Traditional Approach

When testing m hypotheses at significance level α:

-   Expected number of false positives: m × α\
-   With m = 1,000,000 and α = 0.05: **50,000 false positives!**

**Frequentist solutions**:\
- Bonferroni correction: α/m\
- False Discovery Rate (FDR) control (Benjamini-Hochberg)\
- Family-wise error rate (FWER) control (Drawing time)?)

## Visualizing Multiple Hypothesis Testing

```{r}
# Set parameters
set.seed(123)
m <- 10000  # Total number of tests
pi0 <- 0.7  # True proportion of null hypotheses
alpha <- 0.05  # Significance threshold

# Generate p-values
# From null hypotheses
n_null <- round(m * pi0)
p_null <- runif(n_null)

# From alternative hypotheses
n_alt <- m - n_null
p_alt <- rbeta(n_alt, 0.3, 8)  # This creates p-values that tend to be small

# Combine p-values
p_values <- c(p_null, p_alt)

# Calculate key quantities
D_p <- sum(p_values <= alpha)  # Number of significant tests
FP_p <- pi0 * m * alpha       # Expected number of false positives
FDR_p <- FP_p / D_p           # False discovery rate

# Create data frame for plotting
df <- data.frame(
  p_value = p_values,
  significant = p_values <= alpha
)

# Create plot
ggplot(df, aes(x = p_value, fill = significant)) +
  geom_histogram(bins = 50, boundary = 0) +
  geom_hline(yintercept = pi0 * m/50, linetype = "dashed", color = "red") +  # Line at pi0
  annotate("text", x = 0.5, y = pi0 * m/40, 
           label = paste("π₀ =", pi0), color = "red") +
  annotate("text", x = 0.7, y = max(hist(df$p_value, breaks = 50, plot = FALSE)$counts) * 0.8,
           label = paste("D(", alpha, ") =", D_p)) +
  annotate("text", x = 0.7, y = max(hist(df$p_value, breaks = 50, plot = FALSE)$counts) * 0.7,
           label = paste("FP(", alpha, ") =", round(FP_p))) +
  annotate("text", x = 0.7, y = max(hist(df$p_value, breaks = 50, plot = FALSE)$counts) * 0.6,
           label = paste("FDR(", alpha, ") =", round(FDR_p, 3))) +
  scale_fill_manual(values = c("grey70", "blue")) +
  labs(title = "Distribution of P-values",
       subtitle = paste0("m = ", m, " tests, π0 = ", pi0, " null proportion"),
       x = "p-value",
       y = "Count",
       fill = "Significant") +
  theme_minimal() +
  theme(legend.position = "bottom")

```

The challenge: Separating true signals (blue) from noise (gray) when
true effects are rare. The Bayesian solutions ...

## Local False Discovery Rate (LFDR)

The key insight from Matthew Stephens' work:

Instead of controlling the overall FDR, we can calculate the probability
that each individual test is a false discovery:

$$\text{LFDR}(z) = P(H_0|z) = \frac{(1-\pi_1)f_0(z)}{f(z)}$$

Where:

\- $\pi_1$ = proportion of true effects

\- $f_0(z)$ = null distribution

\- $f(z)$ = observed distribution

## plotting

```{r,echo=TRUE}

set.seed(123)
n_tests <- 10000
pi1 <- 0.10  # 10% true effects
sigma <- 4    # Effect size parameter

# Generate true and null effects
n_true <- round(n_tests * pi1)
n_null <- n_tests - n_true

# Null effects
z_null <- rnorm(n_null, 0, 1)
# True effects
z_true <- rnorm(n_true, 0, sqrt(1 + sigma^2))

# Calculate LFDR for each z-score
calc_lfdr <- function(z, pi1=0.10, sigma=4) {  # Match the parameters used to generate data
  f0 <- dnorm(z, 0, 1)
  f1 <- dnorm(z, 0, sqrt(1 + sigma^2))
  f <- (1-pi1)*f0 + pi1*f1
  (1-pi1)*f0/f
}

# Create data frame
plot_data <- data.frame(
  z_score = c(z_null, z_true),
  is_true = factor(c(rep(0, n_null), rep(1, n_true))),
  lfdr = c(
    calc_lfdr(z_null),
    calc_lfdr(z_true)
  )
)

# Plot with some improvements
ggplot(plot_data, aes(x = z_score, y = lfdr, color = is_true)) +
  geom_point(alpha = 0.2, size = 0.5) +  # Smaller points, more transparency
  geom_hline(yintercept = 0.1, linetype = "dashed", color = "darkgreen") +
  scale_color_manual(values = c("0" = "gray70", "1" = "blue"),
                    labels = c("Null", "True Effect"),
                    name = "Truth") +
  labs(title = "Local False Discovery Rate",
       subtitle = paste0("π₁ = ", pi1, ", σ = ", sigma),
       x = "Z-score", 
       y = "LFDR") +
  theme_minimal(base_size = 16) +
  coord_cartesian(xlim = c(-6, 6))  # F
```

## Why LFDR is Better

1.  **Test-specific**: Each test gets its own probability of being false
2.  **Direct interpretation**: "This test has 5% chance of being false"
3.  **Natural handling of correlation**: No need for independence
    assumptions
4.  **Flexible**: Can incorporate prior information about effect sizes

## Empirical Bayes Approach

Matthew Stephens' key contributions:

1.  **Estimate from data**: Learn $\pi_1$ and effect size distribution
    from the data
2.  **Adaptive shrinkage**: Stronger shrinkage for uncertain estimates
3.  **Correlation structure**: Account for LD and other dependencies

## Empirical Bayes Approach

```{r}

# Visualization of adaptive shrinkage
set.seed(456)
n_tests <- 1000
pi1 <- 0.1
sigma <- 2

# Generate data
true_effects <- rnorm(n_tests, 0, sigma)
is_null <- rbinom(n_tests, 1, 1-pi1)
true_effects[is_null == 1] <- 0

# Add noise
observed_effects <- true_effects + rnorm(n_tests, 0, 1)

# Calculate posterior means (simplified)
posterior_means <- observed_effects * (1 - calc_lfdr(observed_effects, pi1, sigma))

# Create data frame
shrinkage_data <- data.frame(
  Observed = observed_effects,
  True = true_effects,
  Shrunk = posterior_means
)

# Plot
ggplot(shrinkage_data, aes(x = Observed, y = Shrunk)) +
  geom_point(alpha = 0.5) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed") +
  labs(title = "Adaptive Shrinkage",
       subtitle = "Stronger shrinkage for uncertain estimates",
       x = "Observed Effect", 
       y = "Shrunk Effect") +
  theme_minimal(base_size = 16)  # Increased base size
```

## Practical Implementation

1.  **ashr**: Adaptive shrinkage for effect sizes
2.  **mashr**: Multivariate adaptive shrinkage
3.  **flashier**: Sparse factor analysis (more on aladynoulli to come
    ... )

## The Mathematical Framework

In multiple testing, we have two distributions:

1.  **Null Distribution** ($f_0$): $$f_0(z) = \mathcal{N}(0, se^2)$$
    This is the standard normal distribution for tests where $H_0$ is
    true.

2.  **Alternative Distribution** ($f_1$):
    $$f_1(z) = \mathcal{N}(0, se^2 + \sigma^2)$$ This is a normal
    distribution with increased variance for tests where $H_1$ is true.

3.  **Overall Distribution** ($f$):
    $$f(z) = (1-\pi_1)f_0(z) + \pi_1f_1(z)$$ A mixture of null and
    alternative distributions (estimate posterior probability of
    non-null components) Homework!

```{r, fig.width=15, fig.height=10}
# Create visualization of the distributions
set.seed(123)
z <- seq(-5, 5, length.out = 1000)
pi1 <- 0.05

# Compare different prior variances
sigma1 <- 1
sigma2 <- 2
sigma3 <- 4

# Calculate densities for different prior variances
f0 <- dnorm(z, 0, 1)  # Null distribution
f1_small <- dnorm(z, 0, sqrt(1 + sigma1^2))  # Alternative with small variance
f1_med <- dnorm(z, 0, sqrt(1 + sigma2^2))    # Alternative with medium variance
f1_large <- dnorm(z, 0, sqrt(1 + sigma3^2))  # Alternative with large variance

# Create data frame
dist_data <- data.frame(
  z = rep(z, 4),
  density = c(f0, f1_small, f1_med, f1_large),
  Distribution = factor(rep(c("Null", "Alt (σ²=1)", "Alt (σ²=4)", "Alt (σ²=16)"), 
                          each = length(z)))
)

# Plot with larger size
ggplot(dist_data, aes(x = z, y = density, color = Distribution)) +
  geom_line(size = 2) +
  scale_color_manual(values = c("Null" = "red", 
                               "Alt (σ²=1)" = "blue", 
                               "Alt (σ²=4)" = "darkgreen",
                               "Alt (σ²=16)" = "purple")) +
  labs(title = "Effect of Prior Variance on Alternative Distribution",
       subtitle = "Larger prior variance (σ²) leads to less shrinkage",
       x = "Z-score", 
       y = "Density") +
  theme_minimal(base_size = 20) +  # Increased base font size
  theme(legend.position = "bottom",
        legend.text = element_text(size = 16),
        legend.title = element_text(size = 18),
        axis.text = element_text(size = 16),
        axis.title = element_text(size = 18),
        plot.title = element_text(size = 22),
        plot.subtitle = element_text(size = 18))

```

## Effect of Prior Variance on Shrinkage

The prior variance ($\sigma^2$) directly affects how much we shrink our
estimates:

1.  **Small prior variance** ($\sigma^2$ small):
    -   Alternative distribution is narrow
    -   Strong shrinkage toward zero
    -   Conservative estimates
    -   Higher threshold for calling something significant
2.  **Large prior variance** ($\sigma^2$ large):
    -   Alternative distribution is wide

    -   Less shrinkage toward zero

    -   More willing to accept large effect sizes

    -   Lower threshold for calling something significant

------------------------------------------------------------------------

```{r, fig.width=15, fig.height=10}
# Demonstrate shrinkage with different prior variances
set.seed(456)
n_tests <- 1000
true_effects <- c(rep(0, n_tests * 0.95), rnorm(n_tests * 0.05, 0, 2))
observed_effects <- true_effects + rnorm(n_tests, 0, 1)

# Calculate posterior means with different prior variances
calc_shrinkage <- function(z, pi1, sigma) {
  f0 <- dnorm(z, 0, 1)
  f1 <- dnorm(z, 0, sqrt(1 + sigma^2))
  f <- (1-pi1)*f0 + pi1*f1
  lfdr <- (1-pi1)*f0/f
  z * (1 - lfdr)  # Simplified shrinkage estimate
}

shrunk_small <- calc_shrinkage(observed_effects, 0.05, 1)
shrunk_med <- calc_shrinkage(observed_effects, 0.05, 2)
shrunk_large <- calc_shrinkage(observed_effects, 0.05, 4)

# Create data frame for plotting
shrinkage_data <- data.frame(
  Observed = rep(observed_effects, 3),
  Shrunk = c(shrunk_small, shrunk_med, shrunk_large),
  PriorVar = factor(rep(c("σ²=1", "σ²=4", "σ²=16"), each = n_tests))
)

# Plot with larger size
ggplot(shrinkage_data, aes(x = Observed, y = Shrunk, color = PriorVar)) +
  geom_point(alpha = 0.5, size = 3) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed") +
  scale_color_manual(values = c("σ²=1" = "blue", 
                               "σ²=4" = "darkgreen",
                               "σ²=16" = "purple")) +
  labs(title = "Effect of Prior Variance on Shrinkage",
       subtitle = "Larger prior variance leads to less shrinkage toward zero",
       x = "Observed Effect", 
       y = "Shrunk Effect",
       color = "Prior Variance") +
  theme_minimal(base_size = 20) +
  theme(legend.position = "bottom",
        legend.text = element_text(size = 16),
        legend.title = element_text(size = 18),
        axis.text = element_text(size = 16),
        axis.title = element_text(size = 18),
        plot.title = element_text(size = 22),
        plot.subtitle = element_text(size = 18))
```

------------------------------------------------------------------------

This relationship between prior variance and shrinkage is crucial in
genomics:

-   For rare variants or small studies: Use smaller $\sigma^2$ to be
    conservative
-   For common variants or large studies: Can use larger $\sigma^2$
-   For follow-up studies: Can use previous effect size estimates to
    inform $\sigma^2$

## Multivariate Adaptive Shrinkage (mash)

When we have effects across multiple groups (e.g., tissues, conditions),
we can borrow strength:

$$\begin{align*}
\text{Effects across groups: } & \mathbf{B}_j \sim N(\mathbf{0}, \mathbf{U}_k) \\
\text{Mixture model: } & p(\mathbf{B}_j) = \sum_{k=1}^K \pi_k N(\mathbf{0}, \mathbf{U}_k)
\end{align*}$$

Where $\mathbf{U}_k$ captures different patterns of sharing: - Equal
effects across groups - Group-specific effects - Correlated effects -
Structured patterns

## Understanding Covariance Matrices in Multivariate Normal Distribution

Let's consider a bivariate normal distribution with covariance matrix
U_k:

$$\mathbf{U}\_k =
\begin{pmatrix} 
\sigma^2_1 & \rho\sigma_1\sigma_2 \\
\rho\sigma_1\sigma_2 & \sigma^2_2
\end{pmatrix}$$

where: - $\sigma\^2_1$ and $\sigma\^2_2$ are the variances for each
trait - $\rho$ is the correlation coefficient - $\rho\sigma\_1\sigma\_2$
represents the covariance.

## More math

The multivariate normal density is then:

$$\mathbf{x}\|\mathbf{U}\_k) = \frac{1}{2\pi|\mathbf{U}_k|^{1/2}}
\exp\left(-\frac{1}{2}\mathbf{x}\^T\mathbf{U}\_k\^{-1}\mathbf{x}\right)$$

Different covariance matrices (\mathbf{U}\_k) lead to different shapes:

1.  When ($\rho$ = 0):
    -   Effects are independent
    -   Contours form circles/ellipses aligned with axes
2.  When ($\rho$ $\neq$ 0):
    -   Effects are correlated
    -   Contours form rotated ellipses
    -   Direction of rotation determined by sign of (\rho)

## How would you get a 1:1 line?

```{r,echo=TRUE}
library(MASS)
sig1 =2;sig2=3
cov1=matrix(c(sig1^2,sig1*sig2,sig2*sig1,sig2^2),byrow = TRUE,nrow=2)
m=mvrnorm(10000,mu = rep(0,2),Sigma = cov1)
plot(m[,1],m[,2],xlab="Effect 1",ylab="Effect 2")
abline(c(0,1))
```

------------------------------------------------------------------------

## Bringing it home!

```{r}
library(MASS)  # for mvrnorm
library(patchwork)  # for plot combining

# Simulate data for two groups with different patterns
set.seed(789)
n_effects <- 1000

# Generate true patterns
null_effects <- matrix(0, nrow = n_effects * 0.8, ncol = 2)
shared_effects <- matrix(rnorm(n_effects * 0.1 * 2, 0, 2), ncol = 2)  # Same in both groups
group1_specific <- cbind(rnorm(n_effects * 0.05, 0, 2), rep(0, n_effects * 0.05))
group2_specific <- cbind(rep(0, n_effects * 0.05), rnorm(n_effects * 0.05, 0, 2))

# Combine patterns
true_effects <- rbind(null_effects, shared_effects, group1_specific, group2_specific)
pattern_labels <- c(rep("Null", n_effects * 0.8),
                   rep("Shared", n_effects * 0.1),
                   rep("Group1-specific", n_effects * 0.05),
                   rep("Group2-specific", n_effects * 0.05))

# Add noise
observed_effects <- true_effects + matrix(rnorm(n_effects * 2, 0, 1), ncol = 2)

# Function for bivariate normal density
dbvnorm <- function(x, y, mu1, mu2, sigma1, sigma2, rho) {
    z1 <- (x - mu1)/sigma1
    z2 <- (y - mu2)/sigma2
    exp(-(z1^2 + z2^2 - 2*rho*z1*z2)/(2*(1-rho^2))) / 
        (2*pi*sigma1*sigma2*sqrt(1-rho^2))
}

# Calculate simple shrinkage (univariate - shrinking each group separately)
univ_shrink <- function(x, pi1 = 0.2, sigma = 2) {
    f0 <- dnorm(x, 0, 1)
    f1 <- dnorm(x, 0, sqrt(1 + sigma^2))
    f <- (1-pi1)*f0 + pi1*f1
    lfdr <- (1-pi1)*f0/f
    x * (1 - lfdr)
}

# Univariate shrinkage
shrunk_univ <- cbind(univ_shrink(observed_effects[,1]),
                     univ_shrink(observed_effects[,2]))

# Simulate mash-style shrinkage (simplified)
mash_shrink <- function(x, y, rho = 0.5, pi1 = 0.2, sigma = 2) {
    # Simplified bivariate normal calculations
    null_prob <- (1-pi1) * dnorm(x, 0, 1) * dnorm(y, 0, 1)
    alt_prob <- pi1 * dbvnorm(x, y, 0, 0, sigma, sigma, rho)
    post_weight <- alt_prob / (null_prob + alt_prob)
    return(c(x * post_weight, y * post_weight))
}

# Apply mash-style shrinkage
shrunk_mash <- t(apply(observed_effects, 1, function(x) 
    mash_shrink(x[1], x[2])))

# Create plotting data
plot_data <- data.frame(
    Group1_obs = observed_effects[,1],
    Group2_obs = observed_effects[,2],
    Group1_univ = shrunk_univ[,1],
    Group2_univ = shrunk_univ[,2],
    Group1_mash = shrunk_mash[,1],
    Group2_mash = shrunk_mash[,2],
    Pattern = factor(pattern_labels)
)

# Create plots
p1 <- ggplot(plot_data, aes(x = Group1_obs, y = Group2_obs, color = Pattern)) +
    geom_point(alpha = 0.6, size = 3) +
    scale_color_brewer(palette = "Set1") +
    labs(title = "Observed Effects",
         x = "Group 1", 
         y = "Group 2") +
    theme_minimal(base_size = 20) +
    theme(legend.position = "bottom")

p2 <- ggplot(plot_data, aes(x = Group1_univ, y = Group2_univ, color = Pattern)) +
    geom_point(alpha = 0.6, size = 3) +
    scale_color_brewer(palette = "Set1") +
    labs(title = "Univariate Shrinkage",
         x = "Group 1", 
         y = "Group 2") +
    theme_minimal(base_size = 20) +
    theme(legend.position = "bottom")

p3 <- ggplot(plot_data, aes(x = Group1_mash, y = Group2_mash, color = Pattern)) +
    geom_point(alpha = 0.6, size = 3) +
    scale_color_brewer(palette = "Set1") +
    labs(title = "Multivariate Shrinkage (mash)",
         x = "Group 1", 
         y = "Group 2") +
    theme_minimal(base_size = 20) +
    theme(legend.position = "bottom")

# Combine plots
(p1 | p2 | p3) + 
    plot_annotation(title = "Effect of Different Shrinkage Methods",
                   subtitle = "mash better preserves true patterns of sharing",
                   theme = theme(plot.title = element_text(size = 24),
                               plot.subtitle = element_text(size = 20)))
```

-   Observed Effects are noisy
-   only considering information in one subgroup ignores the hints we
    get from abound
-   sharing is caring!

## Conjugate Priors: Why They're Beautiful

**Definition**: A prior is conjugate when the posterior has the same
distribution family as the prior.

Let's see this mathematically:

## Conjugate Priors: Why They're Beautiful

For example, in the Normal-Normal case: \[ \begin{align}
\text{Prior: } & \theta \sim N(\mu_0, \sigma^2_0) \\
\text{Likelihood: } & X|\theta \sim N(\theta, \sigma^2) \\
\text{Posterior: } & \theta|X \sim N\left(\frac{\sigma^2_0 X + \sigma^2\mu_0}{\sigma^2_0 + \sigma^2}, \frac{\sigma^2_0\sigma^2}{\sigma^2_0 + \sigma^2}\right)
\end{align}

The beauty is that: 1. Prior starts as Normal 2. Data comes from Normal
3. Posterior ends up Normal 4. Just with updated parameters!

This makes computation tractable and interpretation intuitive - we're
just updating our beliefs while staying in the same family of
distributions.

## Beta-Binomial: Perfect for Allele Frequencies

**Model**:\
- **Prior**: $\theta \sim \text{Beta}(\alpha, \beta)$\
- **Likelihood**: $X|\theta \sim \text{Binomial}(n, \theta)$\
- **Posterior**: $\theta|X \sim \text{Beta}(\alpha + X, \beta + n - X)$

## Beta-Binomial: Perfect for Allele Frequencies

```{r}
#| fig-height: 5
# Create a visualization of Beta-Binomial for allele frequencies
set.seed(123)

# Parameters
true_af <- 0.3
n_samples <- 20
n_reads_per_sample <- 30

# Generate data
genotypes <- rbinom(n_samples, 2, true_af)
read_counts <- rbinom(n_samples, n_reads_per_sample, genotypes/2)
total_alt <- sum(read_counts)
total_reads <- n_samples * n_reads_per_sample

# Create data for plotting
x <- seq(0, 1, length.out = 200)

# Different priors
priors <- list(
  "Flat" = c(1, 1),
  "Informative" = c(10, 20),
  "Incorrect" = c(20, 5)
)

# Create data frame for plotting
plot_data <- data.frame()

for (prior_name in names(priors)) {
  prior_params <- priors[[prior_name]]
  alpha_prior <- prior_params[1]
  beta_prior <- prior_params[2]
  
  # Prior
  prior_y <- dbeta(x, alpha_prior, beta_prior)
  
  # Posterior
  alpha_post <- alpha_prior + total_alt
  beta_post <- beta_prior + total_reads - total_alt
  posterior_y <- dbeta(x, alpha_post, beta_post)
  
  # Add to data frame
  plot_data <- rbind(plot_data, 
                    data.frame(
                      x = x,
                      y = prior_y,
                      Distribution = "Prior",
                      Prior = prior_name
                    ),
                    data.frame(
                      x = x,
                      y = posterior_y,
                      Distribution = "Posterior",
                      Prior = prior_name
                    ))
}

# Add true value line
plot_data$Distribution <- factor(plot_data$Distribution, 
                               levels = c("Prior", "Posterior"))

# Create plot
  ggplot(plot_data, aes(x = x, y = y, linetype = Distribution, color = as.factor(Prior))) +
  geom_line(size = 1.2) +
  geom_vline(xintercept = true_af, linetype = "dashed", color = "black") +
  #scale_color_manual(values = c("Prior" = "blue", "Posterior" = "red")) +
  labs(title = "Beta-Binomial for Allele Frequency Estimation",
       subtitle = paste0("True AF = ", true_af, ", Observed = ", round(total_alt/total_reads, 3)),
       x = "Allele Frequency", 
       y = "Density") +
  theme(legend.position = "bottom")
```

## Beta-Binomial Conjugacy: Adding Counts Intuition

The $\beta(\alpha, \beta)$ distribution updates by simply adding
successes to ($\alpha$) and failures to ($\beta$)!

$$\begin{align}
\text{Prior: } & \theta \sim \text{Beta}(\alpha_0, \beta_0) \\
\text{Data: } & \text{Observe: } s \text{ successes, } f \text{ failures} \\
\text{Posterior: } & \theta \sim \text{Beta}(\alpha_0 + s, \beta_0 + f)
\end{align}$$

## Simple Example:

Imagine tracking minor allele frequency:

- **Start**: Beta(2, 8) - prior belief allele is rare

- **Observe**: AABB AABB ABBB (5 A's, 7 B's)

- **Updates**: - After 1st group: Beta(4, 10)

- After 2nd group: Beta(6, 12)

- After 3rd group: Beta(7, 15)

## Why this is beautiful:

1.  Each A (success) adds 1 to (\$\alpha\$)
2.  Each B (failure) adds 1 to (\$\beta\$)
3.  ($\alpha$) = prior successes + observed successes
4.  ($\beta$) = prior failures + observed failures
5.  Posterior mean = ($\frac{\alpha}{\alpha + \beta}$)

## Continuous updating

```{r}
#| fig-height: 5
# Create a function to generate conjugate updating visualization
plot_conjugate_updating <- function() {
  # Initial prior
  alpha0 <- 2
  beta0 <- 8
  
  # Data observations (success/failure)
  data <- c(1, 1, 0, 1, 1, 0, 1, 1, 1, 0)
  
  # Create sequence for plotting
  x <- seq(0, 1, length.out = 200)
  
  # Initialize data frame for plotting
  plot_data <- data.frame()
  
  # Initial prior
  prior_y <- dbeta(x, alpha0, beta0)
  plot_data <- rbind(plot_data, data.frame(
    x = x, y = prior_y, 
    step = 0, 
    label = paste0("Prior: Beta(", alpha0, ",", beta0, ")")
  ))
  
  # Update step by step
  alpha <- alpha0
  beta <- beta0
  
  for (i in 1:length(data)) {
    # Update parameters
    if (data[i] == 1) {
      alpha <- alpha + 1
    } else {
      beta <- beta + 1
    }
    
    # Only plot a subset of steps for clarity
    if (i %in% c(1, 3, 5, 10)) {
      posterior_y <- dbeta(x, alpha, beta)
      plot_data <- rbind(plot_data, data.frame(
        x = x, y = posterior_y, 
        step = i, 
        label = paste0("After ", i, " observations: Beta(", alpha, ",", beta, ")")
      ))
    }
  }
  
  # Convert step to factor for proper ordering
  plot_data$step <- factor(plot_data$step, levels = c(0, 1, 3, 5, 10))
  
  # Create plot
  ggplot(plot_data, aes(x = x, y = y, color = step, group = step)) +
    geom_line(size = 1.2) +
    scale_color_brewer(palette = "Set1", 
                      name = "Update Step",
                      labels = c("Prior", "After 1 obs", "After 3 obs", 
                                "After 5 obs", "After 10 obs")) +
    labs(title = "Sequential Updating with Conjugate Prior",
         subtitle = "Beta-Binomial conjugacy for allele frequency estimation",
         x = "Allele Frequency", 
         y = "Density") +
    theme(legend.position = "bottom")
}

# Generate the plot
plot_conjugate_updating()
```

------------------------------------------------------------------------

## Dirichlet-Multinomial: For Multiple Alleles

**Model**:\
- **Prior**: $\vec{\theta} \sim \text{Dirichlet}(\vec{\alpha})$\
- **Likelihood**:
$\vec{X}|\vec{\theta} \sim \text{Multinomial}(n, \vec{\theta})$\
- **Posterior**:
$\vec{\theta}|\vec{X} \sim \text{Dirichlet}(\vec{\alpha} + \vec{X})$

### Key Intuition:

The Dirichlet-Multinomial is just like Beta-Binomial, but for multiple
categories instead of just two!

$\begin{align}
\text{Prior: } & \vec{\theta} \sim \text{Dirichlet}(\alpha_1, \alpha_2, ..., \alpha_K) \\
\text{Data: } & \vec{X} = (x_1, x_2, ..., x_K) \text{ counts in each category} \\
\text{Posterior: } & \vec{\theta} \sim \text{Dirichlet}(\alpha_1 + x_1, \alpha_2 + x_2, ..., \alpha_K + x_K)
\end{align}$

## Simple Example:

Imagine tracking allele frequencies for three alleles (A, B, C):

- **Prior**: Dirichlet(2, 2, 2)

- equally uncertain about all alleles

- **Observe**: 10 A's, 5 B's, 3 C's

- **Posterior**: Dirichlet(12, 7, 5) - just add counts to prior
parameters!

### Why this is beautiful:

1.  Each observation simply adds 1 to its category's parameter
2.  (\$\alpha\_k\$) can be thought of as "pseudo-counts"
3.  Larger prior (\$\alpha\$)'s = stronger prior beliefs
4.  Sum of (\$\alpha\$)'s = sample size of prior belief
5.  Posterior mean for category k:
    (\$\frac{\alpha_k + x_k}{\sum(\alpha_i + x_i)}\$)

## Why this is beautiful:

```{r}
#| fig-height: 5
# Create a visualization of Dirichlet-Multinomial
set.seed(234)

# Function to generate random points from a Dirichlet distribution
rdirichlet_2d <- function(n, alpha) {
  x <- rgamma(n, alpha[1], 1)
  y <- rgamma(n, alpha[2], 1)
  z <- rgamma(n, alpha[3], 1)
  s <- x + y + z
  return(data.frame(x = x/s, y = y/s, z = z/s))
}

# Parameters
prior_alpha <- c(2, 2, 2)  # Symmetric prior
true_props <- c(0.6, 0.3, 0.1)  # True proportions
n_samples <- 50

# Generate data
counts <- rmultinom(1, n_samples, true_props)

# Calculate posterior
posterior_alpha <- prior_alpha + counts

# Generate points for visualization
n_points <- 1000
prior_points <- rdirichlet_2d(n_points, prior_alpha)
posterior_points <- rdirichlet_2d(n_points, posterior_alpha)

# Combine data
prior_points$Distribution <- "Prior"
posterior_points$Distribution <- "Posterior"
all_points <- rbind(prior_points, posterior_points)

# Create ternary plot data
# We'll use a 2D projection since ggtern might not be available
project_ternary <- function(df) {
  # Convert to 2D coordinates
  df$X <- 0.5 * (2 * df$y + df$z) / (df$x + df$y + df$z)
  df$Y <- (sqrt(3)/2) * df$z / (df$x + df$y + df$z)
  return(df)
}

plot_data <- project_ternary(all_points)

# Add true value
true_point <- data.frame(x = true_props[1], y = true_props[2], z = true_props[3],
                        Distribution = "True Value")
true_point <- project_ternary(true_point)

# Create plot
ggplot(plot_data, aes(x = X, y = Y, color = Distribution)) +
  geom_point(alpha = 0.3, size = 1) +
  geom_point(data = true_point, color = "black", size = 5, shape = 8) +
  scale_color_manual(values = c("Prior" = "blue", "Posterior" = "red", "True Value" = "black")) +
  labs(title = "Dirichlet-Multinomial for Multiple Alleles",
       subtitle = paste0("Prior: Dirichlet(", paste(prior_alpha, collapse = ","), 
                       "), Counts: ", paste(counts, collapse = ",")),
       x = "", y = "") +
  theme(legend.position = "bottom",
        axis.text = element_blank(),
        axis.ticks = element_blank()) +
  annotate("text", x = 0, y = 0, label = "A") +
  annotate("text", x = 1, y = 0, label = "B") +
  annotate("text", x = 0.5, y = sqrt(3)/2, label = "C")
```

------------------------------------------------------------------------

## Conjugate Normal-Normal Model

-   One of the most elegant and widely-used conjugate pairs in Bayesian
    statistics\
-   Perfect for analyzing quantitative traits in genomics\
-   Gives us a mathematical shortcut for updating beliefs

## The Setup

When analyzing a continuous parameter $\mu$ (like an effect size):

-   **Prior**: $\mu \sim \mathcal{N}(\mu_0, \sigma_0^2)$\

-   **Likelihood**: $X \sim \mathcal{N}(\mu, \sigma^2)$ where $\sigma^2$
    is known\

-   

    ## **Question**: What is $p(\mu|X)$?

## The Mathematical Magic

The elegance is in the algebraic symmetry:

$$
\begin{align}
p(\mu|X) &\propto p(X|\mu) \times p(\mu)\\
&\propto \exp\left(-\frac{(X-\mu)^2}{2\sigma^2}\right) \times \exp\left(-\frac{(\mu-\mu_0)^2}{2\sigma_0^2}\right)
\end{align}
$$

Notice the beautiful symmetry: $(X-\mu)^2$ in the likelihood and
$(\mu-\mu_0)^2$ in the prior.

## The Key Insight

When we expand these terms:

$$
\begin{align}
p(\mu|X) &\propto \exp\left(-\frac{1}{2}\left[\frac{(X-\mu)^2}{\sigma^2} + \frac{(\mu-\mu_0)^2}{\sigma_0^2}\right]\right)\\
&\propto \exp\left(-\frac{1}{2}\left[\frac{\mu^2 - 2\mu X + X^2}{\sigma^2} + \frac{\mu^2 - 2\mu\mu_0 + \mu_0^2}{\sigma_0^2}\right]\right)
\end{align}
$$

Collecting terms with $\mu^2$ and $\mu$...

## The Posterior Formula

After completing the square, we get:

$$\mu|X \sim \mathcal{N}(\mu_n, \sigma_n^2)$$

Where:

$$\mu_n = \frac{\frac{\mu_0}{\sigma_0^2} + \frac{X}{\sigma^2}}{\frac{1}{\sigma_0^2} + \frac{1}{\sigma^2}} = \frac{\sigma^2\mu_0 + \sigma_0^2 X}{\sigma^2 + \sigma_0^2}$$

$$\frac{1}{\sigma_n^2} = \frac{1}{\sigma_0^2} + \frac{1}{\sigma^2}$$

## A More Intuitive View

The posterior mean is a **precision-weighted average** of the prior mean
and the data:

$$\mu_n = w\mu_0 + (1-w)X$$

Where
$w = \frac{\sigma^2}{\sigma^2 + \sigma_0^2} = \frac{\text{data precision}}{\text{total precision}}$

-   When data is precise (small $\sigma^2$): we trust the data more\
-   When prior is precise (small $\sigma_0^2$): we trust the prior more

## Multiple Observations

With multiple observations $X_1,...,X_n$, we get:

$$\mu|(X_1,...,X_n) \sim \mathcal{N}\left(\frac{\frac{\mu_0}{\sigma_0^2} + \frac{n\bar{X}}{\sigma^2}}{\frac{1}{\sigma_0^2} + \frac{n}{\sigma^2}}, \left(\frac{1}{\sigma_0^2} + \frac{n}{\sigma^2}\right)^{-1}\right)$$

-   The sample mean $\bar{X}$ is a sufficient statistic\
-   More data increases precision linearly

## Genomics Application: eQTL Effect Sizes

In genomics, we might use this model for:

-   **Prior**: Historical effect sizes for similar variants\
-   **Likelihood**: Observed effect in current study\
-   **Posterior**: Updated estimate that balances prior knowledge and
    new data

Example: Effect sizes for expression quantitative trait loci (eQTLs)

## The Power of Conjugate Priors

Advantages of conjugate Normal-Normal:

1.  **Analytical solutions** – no MCMC required\
2.  **Computational efficiency** – critical for genomic scale\
3.  **Interpretable updates** – precision-weighted averages\
4.  **Sequential processing** – can update one observation at a time

## Normal-Normal: Key Takeaways

1.  The posterior is also Normal – that's conjugacy!\
2.  The posterior mean is a weighted average of prior mean and data\
3.  Weights are determined by relative precisions (1/variance)\
4.  The posterior precision is the sum of the prior and data precisions\
5.  This model provides the foundation for many advanced Bayesian
    genomic methods

------------------------------------------------------------------------

## Extension: Empirical Bayes for Normal Means

-   When we don't have a specific prior, we can **estimate it from the
    data**\
-   This approach, known as **Empirical Bayes**, is extremely powerful
    for genomics\
-   Applications include: multiple testing, sparse signal detection, and
    effect size estimation

## Methods Using Normal-Normal Conjugacy

-   **Adaptive Shrinkage (ash)**: Uses a mixture of normals as the
    prior\
-   **Multivariate Adaptive Shrinkage (mash)**: Extends to correlated
    effects across conditions\
-   **False Discovery Rate Control**: Through local false discovery
    rates\
-   **Hierarchical Models**: Building multi-level models with partially
    pooled estimates

------------------------------------------------------------------------

# Mixture Models for Complex Data: What Are Mixture Models?

Mixture models are probabilistic models that represent the presence of
subpopulations within an overall population:

-   **Used when data come from multiple underlying processes**\
-   **Represent heterogeneous populations as mixtures of simpler
    distributions**\
-   **Allow clustering without hard assignments**\
-   **Incorporate uncertainty in group membership**

------------------------------------------------------------------------

## Mixture Model: Mathematical Formulation

A mixture model combines multiple distributions to model complex data:

$$p(x) = \sum_{k=1}^K \pi_k f_k(x|\theta_k)$$

Where:

-   $p(x)$ is the overall probability density\
-   $K$ is the number of components (subpopulations)\
-   $\pi_k$ are the mixing weights ($\sum_{k=1}^K \pi_k = 1$)\
-   $f_k(x|\theta_k)$ are the component densities with parameters
    $\theta_k$

------------------------------------------------------------------------

## A Closer Look at the Components

::::: columns
::: {.column width="50%"}
**Key components**:

1.  **Component distributions** $f_k(x|\theta_k)$
    -   Each represents a subpopulation\
    -   Can be any distribution family\
    -   Common choices: Gaussian, multinomial, beta
2.  **Mixing weights** $\pi_k$
    -   Proportion of data from each component\
    -   Must sum to 1: $\sum_{k=1}^K \pi_k = 1$\
    -   Reflect prior probabilities of group membership
3.  **Latent variables** $z_i$
    -   Unobserved component membership\
    -   $z_i = k$ means data point $i$ came from component $k$
:::

::: {.column width="50%"}
```{r}
#| fig-height: 6
# Create a simple mixture model visualization
set.seed(123)

# Define mixture parameters
means <- c(-2.5, 1.5)
sds <- c(0.7, 1.2)
weights <- c(0.4, 0.6)

# Generate data from mixture
n_samples <- 1000
component <- sample(1:2, n_samples, replace = TRUE, prob = weights)
x <- rnorm(n_samples, mean = means[component], sd = sds[component])

# Create data frame for histogram
hist_data <- data.frame(x = x, component = factor(component))

# Create data for component densities
x_seq <- seq(-6, 6, length.out = 500)
comp1_density <- weights[1] * dnorm(x_seq, mean = means[1], sd = sds[1])
comp2_density <- weights[2] * dnorm(x_seq, mean = means[2], sd = sds[2])
mixture_density <- comp1_density + comp2_density

density_data <- data.frame(
  x = rep(x_seq, 3),
  y = c(comp1_density, comp2_density, mixture_density),
  Component = factor(rep(c("Component 1", "Component 2", "Mixture"), each = length(x_seq)))
)

# Create plot
ggplot() +
  geom_histogram(data = hist_data, aes(x = x, y = after_stat(density), fill = component), 
                bins = 50, alpha = 0.5, position = "identity") +
  geom_line(data = density_data, aes(x = x, y = y, color = Component), size = 1.2) +
  scale_fill_manual(values = c("lightblue", "lightgreen"), name = "True Component") +
  scale_color_manual(values = c("blue", "darkgreen", "red")) +
  labs(title = "Gaussian Mixture Model",
       subtitle = "Two underlying subpopulations create a complex distribution",
       x = "Value", 
       y = "Density") +
  theme(legend.position = "bottom")
```
:::
:::::

------------------------------------------------------------------------

## Likelihood Function for Mixture Models

The likelihood of a mixture model for $n$ independent observations
$x_1, \ldots, x_n$ is:

$$L(\theta, \pi | x_1, \ldots, x_n) = \prod_{i=1}^n p(x_i) = \prod_{i=1}^n \sum_{k=1}^K \pi_k f_k(x_i|\theta_k)$$

**Challenge**: The sum inside the product makes this difficult to
optimize directly

**Solution**: Introduce latent variables $z_i$ and use the EM algorithm

------------------------------------------------------------------------

## The EM Algorithm in Detail

The Expectation-Maximization (EM) algorithm is an iterative method for
finding maximum likelihood estimates:

**E-step**: Calculate "responsibilities" – the posterior probability
that data point $i$ belongs to component $k$:

$$\gamma_{ik} = P(z_i = k | x_i, \theta) = \frac{\pi_k f_k(x_i|\theta_k)}{\sum_{j=1}^K \pi_j f_j(x_i|\theta_j)}$$

**M-step**: Update parameters using weighted maximum likelihood:

$$\pi_k^{new} = \frac{1}{n}\sum_{i=1}^n \gamma_{ik}$$\
$$\theta_k^{new} = \arg\max_{\theta_k} \sum_{i=1}^n \gamma_{ik} \log f_k(x_i|\theta_k)$$

------------------------------------------------------------------------

## EM Algorithm: Step-by-Step Example

```{r}
#| fig-height: 6
# Simplified EM visualization
set.seed(789)

# Generate data from a mixture of two Gaussians
n <- 200
true_means <- c(-2, 2)
true_sds <- c(0.8, 0.8)
true_weights <- c(0.4, 0.6)

z <- sample(1:2, n, replace = TRUE, prob = true_weights)
x <- rnorm(n, mean = true_means[z], sd = true_sds[z])

# Create data for visualization
iterations <- c("Initial", "Iteration 1", "Iteration 3", "Final")
means1 <- c(-1, -1.5, -1.8, -2.0)
means2 <- c(1, 1.4, 1.8, 2.0)
sds1 <- c(1.2, 1.0, 0.9, 0.8)
sds2 <- c(1.2, 1.0, 0.9, 0.8)
weights1 <- c(0.5, 0.45, 0.42, 0.4)
weights2 <- c(0.5, 0.55, 0.58, 0.6)

# Create data frame for plotting
plot_data <- data.frame()
x_seq <- seq(-5, 5, length.out = 200)

for (i in 1:length(iterations)) {
  # Component 1
  comp1 <- data.frame(
    x = x_seq,
    y = weights1[i] * dnorm(x_seq, mean = means1[i], sd = sds1[i]),
    Component = "Component 1",
    Iteration = iterations[i]
  )
  
  # Component 2
  comp2 <- data.frame(
    x = x_seq,
    y = weights2[i] * dnorm(x_seq, mean = means2[i], sd = sds2[i]),
    Component = "Component 2",
    Iteration = iterations[i]
  )
  
  # Mixture
  mixture <- data.frame(
    x = x_seq,
    y = comp1$y + comp2$y,
    Component = "Mixture",
    Iteration = iterations[i]
  )
  
  plot_data <- rbind(plot_data, comp1, comp2, mixture)
}

# Create histogram data
hist_data <- data.frame(x = x, Iteration = "Data")

# Create plot
ggplot() +
  # Add histogram for data
  geom_histogram(data = hist_data, aes(x = x, y = after_stat(density)), 
                bins = 30, fill = "gray80", color = "black", alpha = 0.5) +
  # Add component and mixture densities
  geom_line(data = plot_data, 
           aes(x = x, y = y, color = Component, group = interaction(Component, Iteration)),
           size = 1) +
  # Facet by iteration
  facet_wrap(~ Iteration, ncol = 2) +
  # Customize colors
  scale_color_manual(values = c("Component 1" = "blue", "Component 2" = "green", "Mixture" = "red")) +
  # Add labels
  labs(title = "EM Algorithm Convergence",
       subtitle = "Mixture model fit improves with each iteration",
       x = "Value", 
       y = "Density") +
  theme_minimal() +
  theme(legend.position = "bottom")
```

------------------------------------------------------------------------

## Worked Example: EM Algorithm Step-by-Step

Let's walk through each step of the EM algorithm for a mixture of two
Gaussians:

1.  **Initialize parameters**:
    -   Set initial mixing weights: $\pi_1 = \pi_2 = 0.5$\
    -   Set initial component means: $\mu_1 = -1, \mu_2 = 1$\
    -   Set initial component standard deviations:
        $\sigma_1 = \sigma_2 = 1$
2.  **E-step**: For each data point $x_i$, calculate the responsibility
    of each component:
    -   $\gamma_{i1} = \frac{\pi_1 N(x_i|\mu_1,\sigma_1^2)}{\pi_1 N(x_i|\mu_1,\sigma_1^2) + \pi_2 N(x_i|\mu_2,\sigma_2^2)}$\
    -   $\gamma_{i2} = 1 - \gamma_{i1}$
3.  **M-step**: Update the parameters using the responsibilities:
    -   $\pi_1^{new} = \frac{1}{n}\sum_{i=1}^n \gamma_{i1}$ (similarly
        for $\pi_2^{new}$)\
    -   $\mu_1^{new} = \frac{\sum_{i=1}^n \gamma_{i1}x_i}{\sum_{i=1}^n \gamma_{i1}}$
        (similarly for $\mu_2^{new}$)\
    -   $(\sigma_1^{new})^2 = \frac{\sum_{i=1}^n \gamma_{i1}(x_i-\mu_1^{new})^2}{\sum_{i=1}^n \gamma_{i1}}$
        (similarly for $\sigma_2^{new}$)
4.  **Repeat** until convergence (parameters stop changing
    significantly)

------------------------------------------------------------------------

The EM Algorithm: Mathematical Intuition

Key insight: We're solving a chicken-and-egg problem\
If we knew component assignments, parameter estimation would be easy\
If we knew parameters, component assignments would be easy\
EM iteratively solves both by using expected assignments

E-step (Expectation): Calculate expected component memberships\
$$\gamma_{ik} = P(z_i = k | x_i, \theta^{(t)}) = \frac{\pi_k^{(t)} f_k(x_i|\theta_k^{(t)})}{\sum_{j=1}^K \pi_j^{(t)} f_j(x_i|\theta_j^{(t)})}$$\
Intuition: "How likely is individual i to belong to population k, given
our current parameter estimates?"

M-step (Maximization): Update parameters using weighted averages\
For mixing weights:\
$$\pi_k^{(t+1)} = \frac{1}{n}\sum_{i=1}^n \gamma_{ik}$$\
Intuition: "The new population frequency is the average membership
across all individuals"

For component means (Gaussian case):\
$$\mu_k^{(t+1)} = \frac{\sum_{i=1}^n \gamma_{ik}x_i}{\sum_{i=1}^n \gamma_{ik}}$$\
Intuition: "The new population mean is a weighted average where
individuals are weighted by their probability of belonging to this
population (link interlude <https://surbut.shinyapps.io/shinyP/> )

------------------------------------------------------------------------

## Bayesian Mixture Models

Bayesian mixture models add priors to the parameters:

$p(\theta, \pi | x_1, \ldots, x_n) \propto p(x_1, \ldots, x_n | \theta, \pi) \times p(\theta, \pi)$

Common prior choices:\
- $\pi \sim \text{Dirichlet}(\alpha_1, \ldots, \alpha_K)$ for mixing
weights\
- Component-specific priors for $\theta_k$ (e.g., Normal-Inverse-Gamma
for Gaussian components)

**Advantages**:\
- Handle uncertainty in the number of components (K)\
- Avoid singularities and improve stability\
- Allow for informed priors from previous studies\
- Provide full posterior distribution rather than point estimates (in
full MCMC implementation, but SLOW)

------------------------------------------------------------------------

## Mixture Model Applications in Genomics

**1. Population Structure**\
- Components = ancestral populations\
- Individual genotypes = admixtures of populations\
- Example: STRUCTURE, ADMIXTURE software\
- Used for: demographic history, association studies, conservation

**2. Genetic effect estimation**\
- (e.g., adaptive shrinkage methods like ash/mash for multiple
conditions)

**3. Gene Expression Clustering**\
- Components = cell types/states\
- Expression patterns = signatures of cell types\
- Example: Single-cell RNA-seq clustering\
- Used for: cell type identification, developmental trajectories

```{r}
#| fig-height: 6
# Create a visualization of population structure
set.seed(456)

# Number of individuals and populations
n_ind <- 60
n_pop <- 3

# Create admixture proportions
# First 20 individuals mostly from pop1, etc.
admixture <- matrix(0, nrow = n_ind, ncol = n_pop)
for (i in 1:n_ind) {
  if (i <= 20) {
    admixture[i,] <- c(0.8, 0.1, 0.1) + rnorm(3, 0, 0.05)
  } else if (i <= 40) {
    admixture[i,] <- c(0.1, 0.8, 0.1) + rnorm(3, 0, 0.05)
  } else {
    admixture[i,] <- c(0.1, 0.1, 0.8) + rnorm(3, 0, 0.05)
  }
  # Ensure proportions are positive and sum to 1
  admixture[i,] <- pmax(admixture[i,], 0)
  admixture[i,] <- admixture[i,] / sum(admixture[i,])
}

# Create data frame for plotting
admix_df <- data.frame(
  Individual = rep(1:n_ind, n_pop),
  Population = factor(rep(paste0("Pop", 1:n_pop), each = n_ind)),
  Proportion = c(admixture)
)

# Create barplot
ggplot(admix_df, aes(x = Individual, y = Proportion, fill = Population)) +
  geom_col(width = 1) +
  scale_fill_brewer(palette = "Set1") +
  labs(title = "Population Structure as a Mixture Model",
       subtitle = "Each individual is a mixture of ancestral populations",
       x = "Individual", 
       y = "Ancestry Proportion") +
  theme(axis.text.x = element_blank(),
        axis.ticks.x = element_blank())
```

------------------------------------------------------------------------

## The STRUCTURE Model in Detail

**STRUCTURE**: A Bayesian mixture model for population genetics

**Key components**:\
- Each individual = mixture of $K$ ancestral populations\
- Each population = distinct allele frequencies\
- Goal: Infer ancestry proportions & population frequencies from
observed allele counts

**Bayesian formulation**:\
- **Prior**: $q_{ik} \sim \text{Dirichlet}(\alpha)$ (ancestry
proportions, population level alpha)\
- **Prior**: $f_{kj} \sim \text{Beta}(\lambda)$ (allele frequencies,
population level lambda, f)
- **Likelihood**: $P(X_{ij} | q_i, f_j)$ (genotype probabilities, i.e.,
probability of allele count given individual ancestry and populations
allele frequency)

## Latent Dirichlety Allocation

Topic Models (LDA):

\- Document mixture proportions θ \~ Dirichlet(α)

\- Topic-word distributions φ \~ Dirichlet(β)

\- Words drawn from topics z \~ Multinomial(θ)

STRUCTURE:

\- Individual ancestry proportions q \~ Dirichlet(α)

\- Population allele frequencies p \~ Dirichlet(β)

\- Alleles drawn from populations z \~ Multinomial(q)

## Visualization: If we know the truth

```{r}
#| fig-height: 6
#| fig-width: 6
#| echo: false
#| warning: false
#| message: false

library(ggplot2)
library(viridis)
library(patchwork)

set.seed(567)

n_ind <- 100
n_pop <- 3
n_markers <- 20

pop_freqs <- matrix(rbeta(n_pop * n_markers, 0.5, 0.5), nrow = n_pop)

# Create ancestry proportions
q <- matrix(0, nrow = n_ind, ncol = n_pop)
q[1:40, 1] <- rbeta(40, 10, 1)
q[41:70, 2] <- rbeta(30, 10, 1)
q[71:100, 3] <- rbeta(30, 10, 1)
q <- t(apply(q + 0.05, 1, function(x) x / sum(x)))

# Dataframes
q_df <- data.frame(
  Individual = rep(1:n_ind, n_pop),
  Population = factor(rep(paste0("Pop", 1:n_pop), each = n_ind)),
  Proportion = as.vector(q)
)

freq_df <- data.frame(
  Population = factor(rep(paste0("Pop", 1:n_pop), each = n_markers)),
  Marker = factor(rep(paste0("M", 1:n_markers), times = n_pop)),
  Frequency = c(pop_freqs)
)

# Plots
p1 <- ggplot(q_df, aes(x = Individual, y = Population, fill = Proportion)) +
  geom_tile() +
  scale_fill_viridis() +
  labs(title = "Ancestry Proportions",
       subtitle = "Each individual's genetic ancestry",
       x = "Individual", y = "Ancestral Population") +
  theme_minimal(base_size = 10) +
  theme(axis.text.x = element_blank(), axis.ticks.x = element_blank())

p2 <- ggplot(freq_df, aes(x = Marker, y = Population, fill = Frequency)) +
  geom_tile() +
  scale_fill_viridis() +
  labs(title = "Population Allele Frequencies",
       subtitle = "Each population's genetic profile",
       x = "Genetic Marker", y = "Ancestral Population") +
  theme_minimal(base_size = 10)

p1 / p2  # patchwork layout
```

## STRUCTURE: A Tale of Unknown Ancestries

Our Data (Haploid Genotypes):
Individual M1 M2 M3 
* Ind1: A C A 
* Ind2: G T G 
* Ind3: A T A

We want to find: K=2 ancestral populations

## Key Point: Different Distributions for Different Reasons

$q (ancestry) ~ Dirichlet$ 
- Because proportions sum to 1 across K populations 
- K parameters (one for each population) 
- NOT related to number of allele types

$f (frequencies) ~ Beta $
- Because each marker has 2 possible alleles 
- Two parameters (success/failure for that allele) 
- One Beta distribution per marker per population

## Understanding the q Update (Individual Level)
**Individual 1**: A C A

- Step 1: Calculate Likelihoods
**Population 1 Contributions**: 
- Marker 1 (A): $L_{11} = f_1^A$
- Marker 2 (C): $L_{21} = f_1^C$
- Marker 3 (A): $L_{31} = f_1^A$

Total for Pop1 = $L_{11} + L_{21} + L_{31}$

## Example Data
**Individual 1**: A C A

**Population 2 Contributions**:

- Marker 1 (A): $L_{12} = f_2^A$
- Marker 2 (C): $L_{22} = f_2^C$
- Marker 3 (A): $L_{32} = f_2^A$

Total for Pop2 = $L_{12} + L_{22} + L_{32}$

##  Step 2: Dirichlet Update

$$q_1 \sim \text{Dirichlet}(\alpha + [\text{Sum\_Pop1}, \text{Sum\_Pop2}])$$
where:

*-* Sum_Pop1 = $L_{11} + L_{21} + L_{31}$ (added to $\alpha_1$)
*-* Sum_Pop2 = $L_{12} + L_{22} + L_{32}$ (added to $\alpha_2$)

::: {.callout-note}
The Dirichlet update incorporates likelihood contributions from both populations to estimate how much of Individual 1's ancestry comes from each population.
:::

## Updating Allele Frequencies (f) with Fixed Ancestry (q)

** Marker 1 (Allele A)

**Individual 1's ancestry**: $q_1 = (0.7, 0.3)$

**Population 1**:
- Contribution from Individual 1: 0.7 (from $q_{11}$)
- Update: $f_1^A \sim \text{Beta}(\lambda + 0.7, \lambda + 0.3)$ 

**Population 2**:
- Contribution from Individual 1: 0.3 (from $q_{12}$)
- Update: $f_2^A \sim \text{Beta}(\lambda + 0.3, \lambda + 0.7)$

## Marker 2 (Allele C)

**Population 1**
- Contribution from Individual 1: 0.7 (from $q_{11}$)
- Update: $f_1^C \sim \text{Beta}(\lambda + 0.7, \lambda + 0.3)$

**Population 2**:
- Contribution from Individual 1: 0.3 (from $q_{12}$)
- Update: $f_2^C \sim \text{Beta}(\lambda + 0.3, \lambda + 0.7)$

::: {.callout-note}
Note that each allele contributes fractionally to each population's frequency estimate, weighted by the individual's ancestry proportions.
:::

##  The MCMC Two-Step

1.  Update ancestries given current frequencies: 
$P(q_i \|\text{data}, f) \propto P(\text{data}\|q_i,f)P(q_i)$

2.  Update frequencies given current ancestries:
$P(f_k | \text{data}, q) \propto P(\text{data}|q,f_k)P(f_k)$

### **Effect Size Mixtures in GWAS**

**Problem**: Most variants have no effect, but some do

**Solutions**:\
- **Spike-and-slab prior**: Mixture of point mass at zero and continuous
distribution\
- **Scale mixture**: Mixture of normal distributions with different
variances\
- **Bayesian variable selection**: Latent indicator for whether variant
is causal

**Benefits**:\
- Controls false discovery rate\
- Improves power to detect true associations\
- Provides interpretable posterior probabilities\
- Naturally handles multiple testing

## Sound familiar? Multiple hypothesis testing!

```{r, echo=TRUE}
# Create visualization of effect size mixtures
set.seed(789)

# Parameters
n_variants <- 500
pi0 <- 0.95  # Proportion of null effects

# Generate true effects
is_null <- rbinom(n_variants, 1, pi0)
true_effects <- rep(0, n_variants)
true_effects[is_null == 0] <- rnorm(sum(is_null == 0), 0, 0.5)

# Add noise to create observed effects
observed_effects <- true_effects + rnorm(n_variants, 0, 0.2)

# Create data frame for plotting
effect_df <- data.frame(
  Variant = 1:n_variants,
  TrueEffect = true_effects,
  ObservedEffect = observed_effects,
  IsNull = factor(is_null)
)

# Plot
ggplot(effect_df, aes(x = ObservedEffect, fill = IsNull)) +
  geom_histogram(bins = 40, alpha = 0.7, position = "identity") +
  scale_fill_manual(values = c("red", "gray70"), 
                   labels = c("Causal", "Null"),
                   name = "Variant Type") +
  labs(title = "Mixture of Effect Sizes in GWAS",
       subtitle = "Most variants have no effect (null)",
       x = "Observed Effect Size", 
       y = "Count") +
  theme_minimal() +
  theme(legend.position = "bottom")
```

## Multivariate Normal Mixtures: The mash Approach

**Key idea**: Share information across related conditions

**Mathematical model**:\
- $\hat{\beta}_j \sim N(\beta_j, S_j)$ (observed effects)\
- $\beta_j \sim \sum_{k=1}^K \pi_k N(0, U_k)$ (true effects)

------------------------------------------------------------------------

**Covariance matrices** $U_k$ capture patterns:\
- Shared effects across all conditions\
- Condition-specific effects\
- Structured correlation patterns\
- Data-driven patterns

**Benefits**:\
- Improves effect estimation through sharing\
- Discovers patterns of effect heterogeneity\
- Controls false discovery rate\
- Provides interpretable multivariate posteriors

## Types of shared effects

```{r,echo=TRUE}
#| fig-height: 6
# Create a visualization of multivariate effects
set.seed(345)

# Parameters
n_effects <- 200
n_conditions <- 4

# Create different effect patterns
patterns <- list(
  "Shared" = rep(1, n_conditions),
  "Condition1" = c(1, 0, 0, 0),
  "Condition2" = c(0, 1, 0, 0),
  "Conditions1&2" = c(1, 1, 0, 0),
  "Conditions3&4" = c(0, 0, 1, 1)
)

# Assign effects to patterns
n_per_pattern <- n_effects / length(patterns)
true_effects <- matrix(0, nrow = n_effects, ncol = n_conditions)
colnames(true_effects) <- paste0("Condition", 1:n_conditions)

current_idx <- 1
for (p in 1:length(patterns)) {
  pattern_name <- names(patterns)[p]
  pattern <- patterns[[p]]
  
  for (i in 1:n_per_pattern) {
    effect_size <- rnorm(1, 0, 0.5)
    true_effects[current_idx, ] <- pattern * effect_size
    current_idx <- current_idx + 1
  }
}

# Add noise to create observed effects
observed_effects <- true_effects + matrix(rnorm(n_effects * n_conditions, 0, 0.2),
                                        nrow = n_effects)

# Select a few examples for visualization
example_indices <- c(5, 45, 85, 125, 165)  # One from each pattern
example_data <- data.frame(
  Effect = rep(paste0("Effect", example_indices), each = n_conditions),
  Condition = rep(paste0("Condition", 1:n_conditions), times = length(example_indices)),
  TrueEffect = c(t(true_effects[example_indices, ])),
  ObservedEffect = c(t(observed_effects[example_indices, ]))
)

# Reshape for plotting
example_long <- reshape2::melt(example_data, 
                             id.vars = c("Effect", "Condition"),
                             variable.name = "EffectType",
                             value.name = "Value")

# Create plot
ggplot(example_long, aes(x = Condition, y = Value, color = EffectType, group = EffectType)) +
  geom_point(size = 3) +
  geom_line(size = 1) +
  facet_wrap(~ Effect, ncol = 3) +
  scale_color_manual(values = c("TrueEffect" = "blue", "ObservedEffect" = "red"),
                    labels = c("True Effect", "Observed Effect")) +
  labs(title = "Multivariate Effect Patterns",
       subtitle = "mash identifies and leverages these patterns",
       x = "", 
       y = "Effect Size",
       color = "") +
  theme(legend.position = "bottom")
```

## 4. Bayesian Meta-Analysis: The Mathematical Framework

**Problem**: Combine evidence across heterogeneous studies

**Model formulation**:\
- Let $y_i$ be the observed effect in study $i$\
- Let $\sigma_i^2$ be the variance (often known from standard error)\
- Let $\theta_i$ be the true effect in study $i$

**Hierarchical model**:\
$y_i | \theta_i, \sigma_i^2 \sim N(\theta_i, \sigma_i^2)$\
$\theta_i | \mu, \tau^2 \sim N(\mu, \tau^2)$\
$\mu \sim N(\mu_0, \sigma_0^2)$\
$\tau^2 \sim \text{InvGamma}(a, b)$

Where:\
- $\mu$ is the overall mean effect\
- $\tau^2$ is the between-study heterogeneity\
- $\mu_0, \sigma_0^2, a, b$ are hyperparameters\
---

**Key advantages**:\
- Naturally accounts for heterogeneity\
- Uncertainty in all parameters\
- Shrinkage of extreme estimates toward the mean\
- Robust to outliers with appropriate priors

------------------------------------------------------------------------

## Bayesian Meta-Analysis: Visualization

**Traditional approaches**:\
- Fixed effects (assumes same effect size)\
- Random effects (allows variation in effect size)\
- Often sensitive to outliers

**Bayesian advantages**:\
- Full posterior distribution for all parameters\
- Can incorporate informative priors\
- Naturally handles small studies (shrinkage)\
- Can model outliers explicitly\
- Direct probability statements about effects

**Example interpretation**:\
- Posterior probability of benefit = 98%\
- 95% credible interval for effect size: \[0.1, 0.5\]\
- 90% probability heterogeneity is moderate to high

## Visualization

```{r}
#| fig-height: 6
set.seed(678)

# Parameters
n_studies <- 8
true_effect <- 0.3
heterogeneity <- 0.1
clinically_meaningful <- 0.2  # Define clinically meaningful threshold

# Generate study-specific effects
study_effects <- rnorm(n_studies, true_effect, heterogeneity)
study_effects[n_studies] <- -0.2  # outlier

# Generate observed effects with more informative sample sizes
sample_sizes <- c(150, 200, 300, 400, 450, 200, 150, 100)  # More realistic
standard_errors <- 1 / sqrt(sample_sizes)
observed_effects <- rnorm(n_studies, study_effects, standard_errors)

# Bayesian analysis
# Prior: N(0, 1) - weakly informative
prior_mean <- 0
prior_sd <- 1

# Posterior calculations (using precision-weighted approach)
posterior_precision <- 1/prior_sd^2 + sum(1/standard_errors^2)
posterior_mean <- (prior_mean/prior_sd^2 + sum(observed_effects/standard_errors^2))/posterior_precision
posterior_sd <- sqrt(1/posterior_precision)

# Calculate probability of clinically meaningful effect
prob_meaningful <- 1 - pnorm(clinically_meaningful, posterior_mean, posterior_sd)

# Create data frame for forest plot
meta_df <- data.frame(
  Study = paste0("Study ", 1:n_studies),
  Effect = observed_effects,
  SE = standard_errors,
  LowerCI = observed_effects - 1.96 * standard_errors,
  UpperCI = observed_effects + 1.96 * standard_errors
)

# Add Bayesian results
bayes_df <- data.frame(
  Study = "Bayesian Estimate",
  Effect = posterior_mean,
  SE = posterior_sd,
  LowerCI = posterior_mean - 1.96 * posterior_sd,
  UpperCI = posterior_mean + 1.96 * posterior_sd
)

# Combine data
plot_df <- rbind(meta_df, bayes_df)
plot_df$Group <- ifelse(plot_df$Study == "Bayesian Estimate", "Bayesian", "Individual Studies")
plot_df$Group <- factor(plot_df$Group, levels = c("Individual Studies", "Bayesian"))



# Create two plots side by side
p1 <- ggplot(plot_df, aes(x = Effect, y = Study, color = Group)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "gray") +
  geom_vline(xintercept = clinically_meaningful, linetype = "dotted", color = "darkgreen", 
             size = 1) +
  geom_point(aes(size = 1/SE)) +
  geom_errorbarh(aes(xmin = LowerCI, xmax = UpperCI), height = 0.2) +
  scale_color_manual(values = c("Individual Studies" = "blue", "Bayesian" = "red")) +
  scale_size_continuous(guide = "none") +
  labs(title = "Forest Plot",
       x = "Effect Size", 
       y = "") +
  theme_minimal() +
  theme(legend.position = "bottom")

# Create density plot for posterior
x_range <- seq(posterior_mean - 4*posterior_sd, 
               posterior_mean + 4*posterior_sd, 
               length.out = 1000)
posterior_density <- data.frame(
  x = x_range,
  y = dnorm(x_range, posterior_mean, posterior_sd)
)

p2 <- ggplot(posterior_density, aes(x = x, y = y)) +
  geom_line(color = "red", size = 1.2) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "gray") +
  geom_vline(xintercept = clinically_meaningful, linetype = "dotted", 
             color = "darkgreen", size = 1) +
  geom_area(data = subset(posterior_density, x > clinically_meaningful),
            aes(y = y), fill = "red", alpha = 0.2) +
  labs(title = "Posterior Distribution",
       subtitle = paste0("P(Effect > ", clinically_meaningful, ") = ", 
                        round(prob_meaningful * 100, 1), "%"),
       x = "Effect Size",
       y = "Density") +
  theme_minimal()

# Combine plots
library(patchwork)
p1 + p2 + 
  plot_layout(widths = c(3, 2)) +
  plot_annotation(
    title = "Bayesian Meta-Analysis",
    subtitle = "Forest plot and posterior distribution showing probability of clinically meaningful effect"
  )
```

------------------------------------------------------------------------

## Practical Recommendations for Bayesian Genomics

1.  **Start with informative priors when possible**
    -   Use previous studies\
    -   Incorporate functional annotations\
    -   Consider evolutionary constraints
2.  **Report posterior probabilities, not just p-values**
    -   $P(\text{association} | \text{data})$ is more interpretable than
        $P(\text{data} | \text{no association})$\
    -   Provides direct probability statements about hypotheses
3.  **Use conjugate models for computational efficiency**
    -   Beta-Binomial for allele frequencies\
    -   Dirichlet-Multinomial for haplotype frequencies\
    -   Normal-Normal for quantitative traits
4.  **Consider mixture models for complex data**
    -   Population structure\
    -   Heterogeneous effect sizes\
    -   Multiple causal variants
5.  **Apply decision theory for optimal designs**
    -   Balance false positives and false negatives\
    -   Consider costs of follow-up studies\
    -   Optimize sample allocation

------------------------------------------------------------------------

## Summary: When to Use Bayesian Methods

| Problem | Bayesian Approach | Advantage |
|-------------------|------------------------|-----------------------------|
| Multiple testing | Posterior probabilities | Direct interpretation, no arbitrary thresholds |
| Sparse effects | Mixture priors | Better power, natural sparsity |
| Heterogeneous effects | Hierarchical models | Borrows strength across contexts |
| Sequential data | Adaptive designs | Efficiency, early stopping |
| Prior knowledge integration | Informative priors | Improved accuracy, reduced sample size |
| Complex dependencies | Bayesian networks | Causal inference, missing data handling |

------------------------------------------------------------------------

## Resources for Bayesian Genomics

**Software**:\
- **R packages**: `rstan`, `brms`, `mashr`, '\ashr' `BGLR`, `INLA`\
- **Python**: `PyMC3`, `Stan`, `Edward`\
- **Specialized**: `STRUCTURE`, `ADMIXTURE`, `SNPTEST`

**Books**:\
- "Bayesian Data Analysis" by Gelman et al.\
-- "Understanding Uncertainty", by David Lindley   -- "The Art of
Statistics" David Spiegelhalter\
-- "Bayesian Approaches to Clinical Trials" David Spiegelhalter\
-- "Elements of Statistical Learning" Hastie, Tibshirani et al\
-- "Statistical Rethinking" by McElreath\

## **Online Resources**:

-   [Five Minute Stats](https://stephenslab.github.io/fiveMinuteStats/)\
-   [Stan User Guide](https://mc-stan.org/users/documentation/)\
-   ME! surbut\@mgh.harvard.edu

------------------------------------------------------------------------

## Questions?

Thank you!!

Where would I be without:

-   **Pradeep Natarajan, MD MMSc**
-   **Sasha Gusev, PhD**
-   **Giovanni Parmigiani, PhD**
-   **Matthew Stephens, PhD**
