# Readme

Welcome!
Thanks for checking out my paper.
I hope it is useful to you.

## Getting Started

There are two ways to use the repository:
1. Open the notebook and follow along with the paper.
2. Use the full API client directly.

Option 2 is plug and play; from within your SAS program, simply
    %include "code/full_client.sas";

Option 1 requires that you set up Jupyterlab and SASpy.

### Setting up the Notebook
First, install the python dependencies.
In Windows:
    py -m venv .venv; .venv/Scripts/Activate; pip install -r requirements.txt

And in Linux:
    python -m venv .venv & .venv/bin/activate & pip install -r requirements.txt

You will then need to configure the provided sascfg.py according to your specific system.
For details about all of your options, refer to https://sassoftware.github.io/saspy/configuration.html
