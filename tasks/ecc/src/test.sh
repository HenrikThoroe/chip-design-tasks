#!/bin/bash

iverilog -o simv top.v top_tb.v
vvp simv
