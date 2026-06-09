# Simulink Power Grid Model

This directory describes the Simulink model used to generate the labelled
islanding and non-islanding events that the machine learning pipeline is trained
and evaluated on.

## Overview

The model is a high-fidelity simulation of a power grid with distributed
generation (solar PV). It is based on a published PV grid model, **extended with
a configurable four-block fault subsystem and steady-state initialisation** so
that large batches of labelled events can be generated automatically under a
range of operating conditions.

## What the Model Produces

By configuring the fault subsystem and sweeping simulation parameters, the model
generates **three-phase voltage cycles** labelled as islanding or non-islanding.
These cycles are the raw input to the feature extraction pipeline in
[`../src/feature_extraction.py`](../src/feature_extraction.py). See
[`../data/README.md`](../data/README.md) for how the generated signals become
the training dataset.

## Key Components

- **PV distributed generation source** — models the solar unit connected to the grid.
- **Four-block fault subsystem** — configurable to produce islanding and various
  non-islanding disturbance scenarios.
- **Steady-state initialisation** — lets each simulated event start from a settled
  operating point, enabling clean batch generation.

<!-- Add or adjust components to match your actual model. -->

## Contents

<!-- Update to match what you actually commit. If the .slx is too large or you -->
<!-- prefer not to share the extended model, replace it with screenshots and keep -->
<!-- this description as the record. -->
- `pv_islanding_model.slx` — the Simulink model (if committed).
- Screenshots of the model and the fault subsystem (if the `.slx` is not committed).

## Requirements

- MATLAB / Simulink
- Simscape Electrical (or the toolbox your model depends on for power systems blocks)

<!-- Adjust the Simulink version and required toolboxes to match your environment. -->

## Generating Events

1. Open the model in Simulink.
2. Configure the fault subsystem for the scenario you want (islanding vs. a
   specific non-islanding disturbance).
3. Set the simulation conditions (irradiance, load, fault timing, network
   configuration) and run.
4. Export the resulting three-phase voltage cycles for feature extraction.

<!-- If you automated this with a script, name it and describe how to run it. -->
