# readcycles.py

import networkx as nx
import numpy as np
import time
import sys

"""Python module demonstrates passing MATLAB types to Python functions"""
def readcycles(cyclelist,TimeOut):
    t0 = time.time()
    cycles = list()
    timed_out = False
    # Read all the cycles and append them to a list
    for cycle in cyclelist:
        if len(cycle) > 3:
            cycles.append(cycle)
            timed_out = time.time() > t0 + TimeOut
            if timed_out:                
                break

                # End
    t = time.time() - t0
    return (cycles,timed_out,t)


