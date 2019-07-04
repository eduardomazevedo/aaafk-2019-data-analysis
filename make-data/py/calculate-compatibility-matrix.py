#!/usr/bin/env python

# Start
import csv
from tqdm import tqdm
from iscompatible import isCompatible

with open("./intermediate-data/globals_for_py_code.csv") as globalfile:
    reader = csv.DictReader(globalfile)
    globs  = dict()
    for row in list(reader):
        globs[row['name']]=row['content']

# Open data
donorDict = dict()
recipDict = dict()
indexDict = dict()
#with open("intermediate-data/nkr/NKRHistoricalDataAll.csv", mode='r') as infile:
with open(globs["nkr_file_csv"], mode='r') as infile:
    reader = csv.DictReader(infile)
    for row in reader:
        index = int(row['index'])
        if index not in indexDict.keys():
            indexDict[index] = dict()
            indexDict[index]['donor'] = []
            indexDict[index]['recip'] = []
        if row['isdonor'] == '1':
            donorDict[row['id']] = row
            indexDict[index]['donor'].append(row['id'])
        else:
            recipDict[row['id']] = row
            indexDict[index]['recip'] = row['id']
            indexDict[index]['hard_blocked_donors'] = row['hard_blocked_donors'].split("|")

# Number of indices
n = len(indexDict.keys())
initial_hard_block_file = open(globs["initial_hard_block_file"],'w')
weak_file               = open(globs["weak_file"],              'w')
strict_file             = open(globs["compat_matrix"],          'w')
exclusion_crit_file     = open(globs["exclusion_crit_file"],    'w')

# Debug with 10
# n = 10

# Main loop
for ii in tqdm(range(1,n+1)):
    # Read the recipient
    if len(indexDict[ii]['recip'])>0:
        recip = recipDict[indexDict[ii]['recip']]

    # Loop over indices to compute compatibility
    for jj in range(1,n+1):
        strict_comp_list = []
        weak_comp_list   = []
        hard_block_list  = []
        excluded_list    = []

        # Only iterate if the ii-th index is a recipient and the jj-th index has a donor
        if len(indexDict[ii]['recip'])>0 and len(indexDict[jj]['donor'])>0:
            # A recipient is compatible with another if she is compatible with any donor
            for donID in indexDict[jj]['donor']:
                donor = donorDict[donID]
                compatible = isCompatible(recip,donor,['strict'])

                # Exclusion based on age/weight criterion
                if int(recip['maxagefordonor'])<int(donor['age']) and float(recip['minweight'])>float(donor['weight']):
                    excluded_list.append(1)
                else:
                    excluded_list.append(0)
                    
                # Hard Blocked Donors
                if 'D' + donID not in indexDict[ii]['hard_blocked_donors']:
                    hard_block_list.append(0)
                else:
                    hard_block_list.append(1)

                # Tissue-type compatibility checks
                # Weak -- Only ABDR
                # Strict -- Included DP, DQ etc...
                strict_comp_list.append(compatible['strict'])
                weak_comp_list.append(compatible['weak'])

            # Look at any compatible, any excluded and any hard_blocked
            strict_comp = max(strict_comp_list)
            weak_comp   = max(weak_comp_list)
            excluded    = max(excluded_list)
            hard_block  = max(hard_block_list)
            # But, overwrite excluded = 0 and hard_block = 0
            # if any compatible donor is not excluded or blocked
            for kk in range(1,len(strict_comp_list)):
                if strict_comp_list[kk] == 1:
                    if excluded_list[kk] == 0:
                        excluded = 0
                    if hard_block_list[kk] == 0:
                        hard_block = 0

        # If the ii-th entry is not a recipient or the jj-th entry does not have a donor
        else:
            strict_comp = 0
            weak_comp = 0
            excluded = 0
            hard_block = 0

        # Write an entry
        weak_file.write(str(weak_comp)+' ')
        strict_file.write(str(strict_comp) + ' ')
        initial_hard_block_file.write(str(hard_block) + ' ')
        exclusion_crit_file.write(str(excluded) + ' ')

    # Append a row in the files
    weak_file.write('\n')
    strict_file.write('\n')
    initial_hard_block_file.write('\n')
    exclusion_crit_file.write('\n')

# Close the files
weak_file.close()
strict_file.close()
initial_hard_block_file.close()
exclusion_crit_file.close()

#print "Python done."
