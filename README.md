# Stheno

[![Build Status](https://github.com/willtebbutt/Stheno.jl/workflows/CI/badge.svg)](https://github.com/willtebbutt/Stheno.jl/actions)
[![codecov.io](http://codecov.io/github/willtebbutt/Stheno.jl/coverage.svg?branch=master)](http://codecov.io/github/willtebbutt/Stheno.jl?branch=master)
[![](https://img.shields.io/badge/docs-blue.svg)](https://willtebbutt.github.io/Stheno.jl/dev)
[![Code Style: Blue](https://img.shields.io/badge/code%20style-blue-4495d1.svg)](https://github.com/invenia/BlueStyle)
[![ColPrac: Contributor's Guide on Collaborative Practices for Community Packages](https://img.shields.io/badge/ColPrac-Contributor's%20Guide-blueviolet)](https://github.com/SciML/ColPrac)

Stheno is designed to make doing non-standard things with Gaussian processes straightforward. It has an intuitive modeling syntax, is inherently able to handle both multi-input and multi-output problems, and trivially supports interdomain pseudo-point approximations. We call this Gaussian process Probabilistic Programming (GPPP).

[We also have a Python version of the package](https://github.com/wesselb/stheno)

Please open issues liberally -- if there's anything that's unclear or doesn't work, we would very much like to know about it.

__Installation__ - `] add Stheno`.

[JuliaCon 2019 Talk](https://www.youtube.com/watch?v=OO3BBkGEMV8)

[Go faster with TemporalGPs.jl](https://github.com/willtebbutt/TemporalGPs.jl/)

## A Couple of Examples

The primary sources of information regarding this package are the [documentation](https://willtebbutt.github.io/Stheno.jl/stable) and the examples folder, but here are a couple of flashy examples to get started with.

Please raise an issue immediately if either of these examples don't work -- they're not currently included in CI, so there's always a higher chance that they'll be outdated than the internals of the package.

In this first example we define a simple Gaussian process, make observations of different bits of it, and visualise the posterior. We are trivially able to condition on both observations of both `f₁` _and_ `f₃`, which is a very non-standard capability.
```julia

#
# We'll get going by setting up our model, generating some toy observations, and
# constructing the posterior processes produced by conditioning on these observations.
#

using Stheno, Random, Plots
using Stheno: @model

# Create a pseudo random number generator for reproducibility.
rng = MersenneTwister(123456);

# Define a distribution over f₁, f₂, and f₃, where f₃(x) = f₁(x) + f₂(x).
@model function model()
    f₁ = GP(randn(rng), EQ())
    f₂ = GP(EQ())
    f₃ = f₁ + f₂
    return f₁, f₂, f₃
end
f₁, f₂, f₃ = model();

# Sample `N₁` / `N₂` locations at which to measure `f₁` / `f₃`.
N₁, N₃ = 10, 11;
X₁, X₃ = rand(rng, N₁) * 10, rand(rng, N₃) * 10;

# Sample toy observations of `f₁` / `f₃` at `X₁` / `X₃`.
σ² = 1e-2
ŷ₁, ŷ₃ = rand(rng, [f₁(X₁, σ²), f₃(X₃, σ²)]);

# Compute the posterior processes. `f₁′`, `f₂′`, `f₃′` are just new processes.
(f₁′, f₂′, f₃′) = (f₁, f₂, f₃) | (f₁(X₁, σ²)←ŷ₁, f₃(X₃, σ²)←ŷ₃);



#
# The are various things that we can do with a Stheno model.
#

# Sample jointly from the posterior over each process.
Np, S = 500, 25;
Xp = range(-2.5, stop=12.5, length=Np);
f₁′Xp, f₂′Xp, f₃′Xp = rand(rng, [f₁′(Xp, 1e-9), f₂′(Xp, 1e-9), f₃′(Xp, 1e-9)], S);

# Compute posterior marginals.
ms1 = marginals(f₁′(Xp));
ms2 = marginals(f₂′(Xp));
ms3 = marginals(f₃′(Xp));

# Pull and mean and std of each posterior marginal.
μf₁′, σf₁′ = mean.(ms1), std.(ms1);
μf₂′, σf₂′ = mean.(ms2), std.(ms2);
μf₃′, σf₃′ = mean.(ms3), std.(ms3);

# Compute the logpdf of the observations.
l = logpdf([f₁(X₁, σ²), f₃(X₃, σ²)], [ŷ₁, ŷ₃])

# Compute the ELBO of the observations, with pseudo-points at the same locations as the
# observations. Could have placed them anywhere we fancy, even in f₂.
l ≈ elbo([f₁(X₁, σ²), f₃(X₃, σ²)], [ŷ₁, ŷ₃], [f₁(X₁), f₃(X₃)])



#
# Stheno has some convenience plotting functionality for GPs with 1D inputs:
#

# Instantiate plot and chose backend.
plotly();
posterior_plot = plot();

# Plot posteriors.
plot!(posterior_plot, f₁′(Xp); samples=S, color=:red, label="f1");
plot!(posterior_plot, f₂′(Xp); samples=S, color=:green, label="f2");
plot!(posterior_plot, f₃′(Xp); samples=S, color=:blue, label="f3");

# Plot observations.
scatter!(posterior_plot, X₁, ŷ₁;
    markercolor=:red,
    markershape=:circle,
    markerstrokewidth=0.0,
    markersize=4,
    markeralpha=0.7,
    label="");
scatter!(posterior_plot, X₃, ŷ₃;
    markercolor=:blue,
    markershape=:circle,
    markerstrokewidth=0.0,
    markersize=4,
    markeralpha=0.7,
    label="");

display(posterior_plot);
```
![](https://github.com/willtebbutt/stheno_models/blob/master/exact/process_decomposition.png)

In the above figure, we have visualised the posterior distribution of all of the processes. Bold lines are posterior means, and shaded areas are three posterior standard deviations from these means. Thin lines are samples from the posterior processes.

This example can also be found in `examples/basic_gppp/process_decomposition.jl`, which also contains other toy examples of GPPP in action.

In this next example we make observations of two different noisy versions of the same latent process. Again, this is just about doable in existing GP packages if you know what you're doing, but isn't straightforward.

```julia
using Stheno, Random, Plots
using Stheno: @model, Noise

# Create a pseudo random number generator for reproducibility.
rng = MersenneTwister(123456);

@model function model()

    # Define a smooth latent process that we wish to infer.
    f = GP(EQ())

    # Define the two noise processes described.
    noise1 = sqrt(1e-2) * GP(Noise()) + (x->sin.(x) .- 5.0 .+ sqrt.(abs.(x)))
    noise2 = sqrt(1e-1) * GP(3.5, Noise())

    # Define the processes that we get to observe.
    y1 = f + noise1
    y2 = f + noise2

    return f, noise1, noise2, y1, y2
end
f, noise₁, noise₂, y₁, y₂ = model();

# Generate some toy observations of `y1` and `y2`.
X₁, X₂ = rand(rng, 3) * 10, rand(rng, 10) * 10;
ŷ₁, ŷ₂ = rand(rng, [y₁(X₁), y₂(X₂)]);

# Compute the posterior processes.
(f′, y₁′, y₂′) = (f, y₁, y₂) | (y₁(X₁)←ŷ₁, y₂(X₂)←ŷ₂);

# Sample jointly from the posterior processes and compute posterior marginals.
Xp = range(-2.5, stop=12.5, length=500);
f′Xp, y₁′Xp, y₂′Xp = rand(rng, [f′(Xp, 1e-9), y₁′(Xp, 1e-9), y₂′(Xp, 1e-9)], 100);

ms1 = marginals(f′(Xp));
ms2 = marginals(y₁′(Xp));
ms3 = marginals(y₂′(Xp));

μf′, σf′ = mean.(ms1), std.(ms1);
μy₁′, σy₁′ = mean.(ms2), std.(ms2);
μy₂′, σy₂′ = mean.(ms3), std.(ms3);

# Instantiate plot and chose backend
plotly();
posterior_plot = plot();

# Plot posteriors
plot!(posterior_plot, y₁′(Xp); samples=S, sample_seriestype=:scatter, color=:red, label="");
plot!(posterior_plot, y₂′(Xp); samples=S, sample_seriestype=:scatter, color=:green, label="");
plot!(posterior_plot, f′(Xp); samples=S, color=:blue, label="Latent Function");

# Plot observations
scatter!(posterior_plot, X₁, ŷ₁;
    markercolor=:red,
    markershape=:circle,
    markerstrokewidth=0.0,
    markersize=4,
    markeralpha=0.8,
    label="Sensor 1");
scatter!(posterior_plot, X₂, ŷ₂;
    markercolor=:green,
    markershape=:circle,
    markerstrokewidth=0.0,
    markersize=4,
    markeralpha=0.8,
    label="Sensor 2");

display(posterior_plot);
```
![](https://github.com/willtebbutt/stheno_models/blob/master/exact/simple_sensor_fusion.png)

As before, we visualise the posterior distribution through its marginal statistics and joint samples. Note that the posterior samples over the unobserved process are (unsurprisingly) smooth, whereas the posterior samples over the noisy processes still look uncorrelated and noise-like.

As before, this example can also be found in `examples/basic_gppp/process_decomposition.jl`.

## Hyperparameter learning and inference

Fortunately, there is really no need for this package to explicitly provide support for hyperparameter optimisation as the functionality is already available elsewhere -- it's sufficient that it plays nicely with other fantastic packages in the ecosystem such as [Zygote.jl](https://github.com/FluxML/Zygote.jl/) (reverse-mode algorithmic differentiation), [Optim.jl](https://github.com/JuliaNLSolvers/Optim.jl) (non-linear optimisation), [AdvancedHMC.jl](https://github.com/TuringLang/AdvancedHMC.jl/) (Hamiltonian Monte Carlo / NUTS), and [Soss.jl](https://github.com/cscherrer/Soss.jl/) (a probabilistic programming framework that provides some very helpful glue). For concrete examples of the use of each of these packages in conjunction with Stheno, see the `Getting Started` section of the [(dev) docs](https://willtebbutt.github.io/Stheno.jl/dev).


## Non-Gaussian problems

Stheno doesn't currently have support for non-Gaussian likelihoods, and as such they're on the up-for-grabs list below. If you would like to see these in this package, please do get in touch (open an issue so that we can discuss where to get started, or open a PR if you're feeling ambitious).


## GPs + Deep Learning

The plan is not to support the combination of GPs and Deep Learning explicitly, but rather to ensure that Stheno and [Flux.jl](https://github.com/FluxML/Flux.jl) play nicely with one another. Both packages now work with [Zygote.jl](https://github.com/FluxML/Zygote.jl), so you can use that to sort out gradient information.


## Things that are up for grabs
Obviously, improvements to code documentation are always welcome, and if you want to write some more unit / integration tests, please feel free. In terms of larger items that require some attention, here are some thoughts:
- An implementation of SVI from [Gaussian Processes for Big Data](https://arxiv.org/abs/1309.6835).
- Kronecker-factored matrices: this is quite a general issue which might be best be addressed by the creation of a separate package. It would be very helpful to have an implementation of the `AbstractMatrix` interface which implements multiplication, inversion, eigenfactorisation etc, which can then be utilised in Stheno.
- Primitives for multi-output GPs: although Stheno does fundamentally have support for multi-output GPs, in the same way that it's helpful to implement so-called "fat" nodes in Automatic Differentiation systems, it may well be helpful to implement specialised multi-output processes in Stheno for performance's sake.
- Some decent benchmarks: development has not focused on performance so far, but it would be extremely helpful to have a wide range of benchmarks so that we can begin to ensure that time is spent optimally. This would involve comparing against [GaussianProcesses.jl](https://github.com/STOR-i/GaussianProcesses.jl), but also some other non-Julia packages.
- Non-Gaussian likelihoods: there are a _lot_ of approximate inference schemes that have been developed for GPs in particular contexts. [GPML](https://gitlab.com/hnickisch/gpml-matlab) probably has the most mature set of these, and would be a good place to start the transfer from. There's also [Natural Gradients in Practice](https://arxiv.org/abs/1803.09151) that might be a good startin point for a Monte Carlo approximation to natural gradient varitional inference. A good place to start with these would be to just make them for `GP`s, as opposed to any `AbstractGP`, as this is the simplest case.

If you are interested in any of the above, please either open an issue or PR. Better still, if there's something not listed here that you think would be good to see, please open an issue to start a discussion regarding it.
