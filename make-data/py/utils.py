#-*- coding: utf-8 -*-

# Imports =====================================================================

import copy

# MultiDimList Class ==========================================================
    
class MultiDimList(object):

	# -------------------------------------------------------------------------
	
    def __init__(self, shape, value=0):
        self.shape = shape
        self.data = self._create_n_list(shape, value)
		
	# -------------------------------------------------------------------------

    def __getitem__(self, coordinates):
        if len(coordinates) != len(self.shape): 
            raise IndexError()
        pointer = self.data
        for coordinate in coordinates[:-1]:
            pointer = pointer[coordinate]
        return pointer[coordinates[-1]]
		
	# -------------------------------------------------------------------------

    def __setitem__(self, coordinates, value):
        if len(coordinates) != len(self.shape): 
            raise IndexError()
        pointer = self.data
        for coordinate in coordinates[:-1]:
            pointer = pointer[coordinate]
        pointer[coordinates[-1]] = value
		
	# -------------------------------------------------------------------------

    def _create_n_list(self, shape, value=0):
        dp = value
        for x in reversed(shape):
            dp = [copy.deepcopy(dp) for _ in xrange(x)]
        return dp
		
	# -------------------------------------------------------------------------

    def __repr__(self):
        return repr(self.data)
		
# END =========================================================================