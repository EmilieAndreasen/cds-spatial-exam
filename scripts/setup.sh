#!/bin/bash

# Create a virtual environment named 'env'
python3 -m venv env

# Activate the virtual environment
source env/bin/activate

# Install the required packages from requirements.txt
pip install -r requirements.txt

echo "Setup complete. To activate the virtual environment, run 'source env/bin/activate'."
