# ML-Assisted Islanding Detection in Distributed Generation Networks

Real-time machine learning classifier that detects **islanding events** in power grids with distributed generation (solar PV, wind), distinguishing them from normal grid disturbances using wavelet-based feature extraction and ensemble learning.

<!-- Replace with your own results image once added to results/ -->
![Confusion matrix](results/confusion_matrix.png)

## The Problem

When the main grid goes down, any connected solar or wind units must disconnect within milliseconds. If they keep feeding power into a dead section of the grid (an "island"), they endanger maintenance crews and damage equipment. The hard part is telling a true islanding event apart from ordinary voltage fluctuations fast enough and reliably enough to act on. Conventional detection methods struggle under changing environmental conditions, producing false alarms or missed events.

This project builds a machine learning classifier that makes that distinction in real time, trained and validated on a high-fidelity power grid simulation.

## Key Results

- **98.09% overall accuracy** and **95.52% islanding recall** across 27,495 three-phase voltage cycles.
- **Benchmarked 14 classifiers** spanning neural, kernel, ensemble, and instance-based families; the tuned Random Forest **outperformed a 1-D CNN on raw signals by more than 6 percentage points**.
- Quantified **domain shift** through cross-topology testing: when evaluated on a network the model had never seen, overall accuracy dropped to 13.49% but **islanding recall held at 99.32%**, isolating exactly where the model generalises and where it does not.
- Built a reproducible feature pipeline extracting **108 statistical features per three-phase voltage cycle**, with a MATLAB reimplementation verified for numerical equivalence with the Python version.

See [`results/benchmark_table.md`](results/benchmark_table.md) for the full classifier comparison.

## Tech Stack

- **Python** — scikit-learn, NumPy, pandas, PyWavelets, Matplotlib
- **MATLAB** — feature extraction reimplementation and cross-environment validation
- **Simulink** — high-fidelity PV power grid model with a configurable fault subsystem

## How It Works

1. **Signal generation.** A published PV Simulink model was extended with a configurable four-block fault subsystem and steady-state initialisation, allowing batch generation of labelled islanding and non-islanding events under varying conditions.
2. **Feature extraction.** Each three-phase voltage cycle is decomposed using a Symlet-4 Discrete Wavelet Transform. Statistical descriptors are computed across the wavelet coefficients to produce 108 features per cycle.
3. **Classification.** A Random Forest with adaptive thresholding is trained on the extracted features. Thirteen other classifiers were trained on the same data for comparison.
4. **Evaluation.** Models were tested both on held-out data from the same network and on a different network topology to measure how well they generalise beyond their training distribution.

## Repository Structure

```
islanding-detection-ml/
├── src/
│   ├── feature_extraction.py   # Symlet-4 DWT pipeline (108 features/cycle)
│   ├── train.py                # Random Forest + adaptive thresholding
│   ├── benchmark.py            # 14-classifier comparison
│   └── evaluate.py             # cross-topology / domain-shift testing
├── matlab/                     # MATLAB feature extractor + equivalence notes
├── simulink/                   # PV model description and fault subsystem
├── data/
│   ├── README.md               # dataset description
│   └── sample/                 # small runnable sample
├── results/                    # metrics, plots, benchmark table
└── notebooks/                  # optional analysis walkthrough
```

## Getting Started

```bash
git clone https://github.com/YOUR_USERNAME/islanding-detection-ml.git
cd islanding-detection-ml
pip install -r requirements.txt
```

Run the pipeline on the included sample data:

```bash
python src/feature_extraction.py   # extract features from sample cycles
python src/train.py                # train the Random Forest
python src/benchmark.py            # reproduce the classifier comparison
```

> **Note on data:** the full 27,495-cycle dataset is not committed to keep the
> repository lightweight. A small representative sample is provided under
> `data/sample/` so the code runs end to end. See [`data/README.md`](data/README.md)
> for details on the full dataset and how it was generated.

## What I'd Improve Next

The sharp accuracy drop under cross-topology testing shows the model overfits to the specific network it was trained on, even though islanding recall stays high. Future work would focus on topology-invariant features and training across multiple network configurations to close that generalisation gap, moving the model closer to something deployable on a real, unseen grid.

## About

Final-year research project for a B.Sc. in Electrical & Electronics Engineering, Academic City University, Accra, Ghana.

<!-- Optional: add a license note if you include a LICENSE file -->
Licensed under the MIT License.
