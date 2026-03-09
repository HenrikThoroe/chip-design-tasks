#!/bin/zsh

gitzip () {
    git archive HEAD -o ../../$1.zip
}

# Bundle AXI task

cd tasks/axi
gitzip axi
cd ../..

# Bundle ECC task

cd tasks/ecc
gitzip ecc
cd ../..

# Bundle random forest task

cd tasks/random-forest
gitzip rf
cd ../..

# Bundle risc-v task

cd tasks/risc-v
gitzip risc
cd ../..

# Bundle FINN task

cd tasks/fpga-nn
zip -r ../../finn.zip REPORT.md README.md pyproject.toml pdm.lock folding_config.json dataflow_build_config.json .python-version .gitignore src/ dist/ cache/
cd ../..
