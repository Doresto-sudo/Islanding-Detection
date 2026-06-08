# Dataset

This directory describes the data used to train and evaluate the islanding
detection model. The full dataset is **not committed** to keep the repository
lightweight and because it is generated rather than collected — see below for
how to regenerate it. A small representative sample is provided under
[`sample/`](sample/) so the code in `src/` runs end to end.

## Overview

The data consists of **three-phase voltage measurements** sampled cycle by cycle
from a simulated power grid containing distributed generation (solar PV). Each
record corresponds to one three-phase voltage cycle and is labelled as either:

- **Islanding** — the distributed generation unit continues energising a section
  of the grid that has been disconnected from the main supply, or
- **Non-islanding** — normal operation or a non-islanding disturbance (for
  example a load change or a fault elsewhere on the network).

| Property                 | Value                                   |
|--------------------------|-----------------------------------------|
| Total cycles             | 27,495                                  |
| Signal type              | Three-phase voltage                     |
| Label classes            | Islanding / Non-islanding               |
| Features per cycle       | 108 (after extraction)                  |
| Source                   | Simulink PV grid model (see `simulink/`)|

<!-- Update the numbers above and the split below to match your actual setup -->

## How the Data Was Generated

The raw voltage cycles come from a high-fidelity Simulink model of a PV-connected
power grid, extended with a configurable four-block fault subsystem and
steady-state initialisation for batch event generation. By varying the simulated
conditions (irradiance, load, fault timing, and network configuration), many
labelled islanding and non-islanding events were produced. Full details of the
model are in [`../simulink/README.md`](../simulink/README.md).

## From Raw Signals to Features

The model in this repository does not learn from raw voltage samples directly.
Each three-phase cycle is passed through the feature extraction pipeline in
[`../src/feature_extraction.py`](../src/feature_extraction.py), which applies a
Symlet-4 Discrete Wavelet Transform and computes statistical descriptors across
the wavelet coefficients, producing **108 features per cycle**. These features
are what the classifiers are trained on.

## The Sample Provided Here

`sample/` contains a small subset of cycles — enough to run feature extraction,
training, and benchmarking end to end so the pipeline can be verified without the
full dataset.

<!-- Describe the sample files precisely once you add them, e.g.: -->
<!-- - sample/sample_signals.csv  — N labelled three-phase voltage cycles -->
<!-- - column layout: phase A, phase B, phase C samples + a 'label' column -->

It is **not** large enough to reproduce the headline accuracy figures; it exists
to demonstrate that the code works. To reproduce the published results you need
the full dataset.

## Regenerating the Full Dataset

1. Open the Simulink model described in [`../simulink/README.md`](../simulink/README.md).
2. Configure the fault subsystem and sweep the simulation conditions to generate
   labelled events.
3. Export the three-phase voltage cycles to the format expected by
   `src/feature_extraction.py`.

<!-- If you have an export script, name it here so others can follow exactly. -->

## A Note on Data Files

Large data and generated files are excluded via `.gitignore`. If you add your own
data, keep raw signal dumps and any files above a few megabytes out of version
control, and document their structure here instead.
