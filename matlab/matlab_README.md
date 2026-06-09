# MATLAB Feature Extraction

This directory contains a **MATLAB reimplementation** of the feature extraction
pipeline that is written primarily in Python under
[`../src/feature_extraction.py`](../src/feature_extraction.py).

## Why a Second Implementation?

The feature extractor was implemented twice — once in Python and once in MATLAB —
and the two were checked against each other to confirm they produce numerically
equivalent features from the same input cycles. This **cross-environment
validation** serves two purposes:

1. It confirms the Symlet-4 Discrete Wavelet Transform and the statistical
   feature calculations are correct, since an independent implementation in a
   different environment agrees with the original.
2. It allows the pipeline to be used inside a MATLAB/Simulink workflow, keeping
   feature extraction in the same environment as the power grid model when that
   is convenient.

## Contents

<!-- Update these to match your actual file names -->
- `feature_extraction.m` — MATLAB implementation of the Symlet-4 DWT feature
  pipeline (108 features per three-phase voltage cycle).

## Verifying Equivalence

The Python and MATLAB extractors were run on the same set of voltage cycles and
their outputs compared feature by feature to confirm they match within numerical
tolerance.

<!-- If you have a comparison script or a saved comparison result, describe it: -->
<!-- e.g. "Run compare_features.m to reproduce the equivalence check; differences -->
<!-- were within 1e-9 across all 108 features." -->

## Requirements

- MATLAB
- Wavelet Toolbox (for the Symlet-4 Discrete Wavelet Transform)

<!-- Adjust the toolbox list / MATLAB version if needed. -->
