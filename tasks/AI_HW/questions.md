# 2) Impact of `(max_depth, n_estimators)`

`max_depth` sets the maximum lenght of a path from the root node to a leaf node in a (single) decision tree. 
A larger tree leads to usage of more hardware and higher power consumption for the benefit of higher accuracy.

`n_estimators` sets the numner of trees generated for the forest, acting as a multiplicator of the hardware used for one single tree.

# 3) Bins

A larger number of bins allows for more classification detail, at the expense of accuracy. 

# 4) Paramters

We use 2 Bins specified through `(2, 6.5, 8)`. 
We use `max_depth = 3` and `n_estimators = 1`.