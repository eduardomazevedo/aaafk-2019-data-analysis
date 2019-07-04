
# coding: utf-8

# In[8]:


import numpy as np
import pandas as pd
import csv
import sys
from collections import defaultdict
import os
import math 
from datetime import datetime

#Assumes the code is in the same directory as the data
path = os.getcwd()


# ## Read the new data into dataframes

# In[9]:


cand     = pd.read_csv('KPD_CANDIDATES_INPUT_DATA.csv')
donor    = pd.read_csv('KPD_DONORS_INPUT_DATA.csv')
match    = pd.read_csv('KPD_MATCHES_DATA.csv')
outcomes = pd.read_csv('KPD_MATCH_OUTCOMES_DATA.csv')
old      = pd.read_csv('NKRHistoricalDataAll-sans-MP-cPRA.csv')
centers  = pd.read_csv('Center_Code.csv')


# ## Fields that we leave blank

# In[10]:


#Store all the fields that are in the original CSV that we aren't interested in/ won't take from the new csv
ignoreCand = set(['chip', 'sex', 'weight', 'height', 'type', 'alias', 'alt',                 'minWeight', 'minHLApoints', 'exchangeProgram',                   'DonorASubtype', 'Recipient_Non_A1', 'badData', 'missingPatient',                  'fromTransplantIDS', 'Related Donors',                  'dialysisstartdate', 'unoslistdate', 'unpaired',                   'hard_blocked_donors', 'Cw1', 'Cw2', 'DRw1', 'DRw2',                  'DPA1', 'DPA2', 'DPB1', 'DPB2', 'DQA1', 'DQA2', 'DQB1',                  'DQB2', 'DR51', 'DR52', 'DR53', 'Bw1', 'Bw2', 'Bw4',                  'Bw6', 'donorRelation', 'Missing Candidate'])

ignoreDon = set(['chip', 'sex', 'weight', 'height', 'type', 'alias',                  'minWeight', 'maxAgeForDonor', 'minHLApoints', 'exchangeProgram',                   'DonorASubtype', 'Recipient_Non_A1', 'badData', 'missingPatient',                  'fromTransplantIDS', 'Related Donors', 'WL-ID', 'DONORID',                  'dialysisstartdate', 'unoslistdate', 'unpaired',                   'hard_blocked_donors', 'antiA', 'antiB', 'antiDR', 'antiDR51', 'antiDR52',                 'antiDR53','antiBw','antiCw','antiDRw','antiBw4','antiBw6','antiDPa',                'antiDPb', 'antiDQa', 'antiDQb', 'pra','insnapshots',                  'DRw1', 'DRw2', 'DPA1', 'DPA2', 'DQA1', 'DQA2'])


# In[11]:


#create the trr_id mappings
"""This section loops through the MATCH_OUTCOMES file and pulls out relevant statistics:
trr_id - TRR_ID_CODE
trr_cand - for a given donor - what is the candidate that it is transplanted with
trr_don - for a given candidate - what is the donot that it is transplanted with
chain - whether the transplant was part of a chain
cycle - whether the transplant was part of a cyle
missing_cand- the list of donors for which the candidate entry is missing
tx_date - transplant dat"""
trr_id = {}
trr_cand = {}
trr_don = {}
donor_id = {}
chain = set()
cycle = set()
missing_cand = set()
tx_date = {}
seen = set()
for i in range(len(outcomes['mr_date'])):
    c = outcomes['KPD_REG_CODE_CAND'][i] 
    d = outcomes['KPD_REG_CODE_DON'][i]
    code = outcomes['TRR_ID_CODE'][i]
    donorid = outcomes['DONOR_ID'][i]
    
    #add c and d to the dict
    #first we need to make sure there was a transplant
    #i.e. that the TRR__ID_CODE was not nan
    if not isinstance(code, float):
        trr_id[c] = outcomes['TRR_ID_CODE'][i]
        trr_id[d] = outcomes['TRR_ID_CODE'][i]
        tx_date[c] = outcomes['TX_DATE'][i]
        tx_date[d] = outcomes['TX_DATE'][i]
        trr_cand[d] = c
        trr_don[c] = d
        seen.add(c)
        seen.add(d)
        #if the transplant was part of a chain or cycle, add to the respective set
        if outcomes['match_cycle'][i][:5] == 'chain':
            if not np.isnan(c):
                chain.add(c)
            if not np.isnan(d):
                chain.add(d)
        if outcomes['match_cycle'][i][:5] == 'cycle':
            if not np.isnan(c):
                cycle.add(c)
            if not np.isnan(d):
                cycle.add(d)
    if not np.isnan(donorid) and not np.isnan(c):
        donor_id[c] = donorid
    if np.isnan(c) and not np.isnan(d):
        missing_cand.add(d)


# In[12]:


#Create center codes
center_code = {}
for i in range(len(centers['Code'])):
    word = centers['Center'][i]
    if centers['Code'][i] != 'Unknown':
        if word[len(word) - 1] == '1':
            word = word[:len(word) - 1]
        center_code[int(centers['Code'][i])] = word


# In[13]:


#For each patient, we loop through the antibodies to get them in a string format
#The list is ordered so that more complicated strings precede their simpler counterparts, this is important
#e.g. DQA is before DQ
def get_antibodies(index):
    prefixes =['A', 'DQA', 'DQB', 'BW', 'B', 'CW', 'DR', 'DQ', 'DPW', 'DP']
    sets = set()
    antiMap = defaultdict(str)
    antibodies = cand['UNACCEPTABLE_ANTIGENS'][index]
    if not isinstance(antibodies, basestring):
        return ''
    antibodies = antibodies.split()
    for a in antibodies:
        antiMap[a] = '1'
        for pr in prefixes:
             if a[0:len(pr)] == pr:
                if a[len(pr):] == 'W':
                    print a
                sets.add(a)
                if len(antiMap[pr]) == 0:
                    antiMap[pr] += a[len(pr):]
                else:
                    antiMap[pr] += '|' + a[len(pr):]
                break
    return antiMap


# In[14]:


#returns true if curr is earlier than prev
def earlier_than(curr, prev):
    curr = curr.split('/')
    prev = prev.split('/')
    currdate = datetime(int(curr[2]), int(curr[0]), int(curr[1]))
    prevdate = datetime(int(prev[2]), int(prev[0]), int(prev[1]))
    return currdate < prevdate


# In[15]:


#get the earliest and latest dates
arrCand = {}
depCand = {}
for i in range(len(cand['MR_DATE'])):
    candidate = cand['KPD_REG_CODE_CAND'][i]
    date = cand['MR_DATE'][i]
    #if we haven't seen this candidate before, add the date for the candidate
    if not candidate in arrCand:
        arrCand[candidate] = date
        depCand[candidate] = date 
    else:
        if earlier_than(date, arrCand[candidate]):
            arrCand[candidate] = date
        if not earlier_than(date, depCand[candidate]):
            depCand[candidate] = date
            
arrDon = {}
depDon = {}
for i in range(len(donor['MR_DATE'])):
    don = donor['KPD_REG_CODE_DON'][i]
    date = donor['MR_DATE'][i]
    if not don in arrDon:
        arrDon[don] = date
        depDon[don] = date 
    else:
        if earlier_than(date, arrDon[don]):
            arrDon[don] = date
        if not earlier_than(date, depDon[don]):
            depDon[don] = date


# In[16]:


"""
This is the section that writes the new CSV. How it works is as follows:
We loop through the candidate dataset, for each row i, we then loop through all the fields that 
will be in new_dataset.csv. For each entry we fill it in with the relevant entry from the dataset.
If an field in new_dataset.csv is in ignore_cand or ignore_don (defined near the top)
we skip that field.
"""

seen = set()
new = list(old) + ['WL-ID', 'DONORID', 'bloodTypeExtended', 'Missing Candidate']
with open('new_dataset.csv', 'w') as csvfile:
    csvwriter = csv.writer(csvfile)
    csvwriter.writerow(new)
    for i in range(len(cand['MR_DATE'])):
        if cand['KPD_REG_CODE_CAND'][i] in seen:
            continue
        output = []
        antib = get_antibodies(i)
        for string in new:
            if string in ignoreCand:
                output.append('')
            elif string in ['id', 'index', 'famID']:
                output.append(cand['KPD_REG_CODE_CAND'][i])
            elif string in ['arr_date_min', 'arr_date_max']:
                output.append(arrCand[cand['KPD_REG_CODE_CAND'][i]])
            elif string in ['dep_date_max', 'dep_date_min']:
                output.append(depCand[cand['KPD_REG_CODE_CAND'][i]])
            elif string in ['Registered']:
                output.append(cand['KPD_ADD_DATE_CAND'][i])
            elif string == 'extended_id':
                output.append(cand['PT_CODE_CAND'][i])
            elif string == 'WL-ID':
                output.append(cand['WL_ID_CODE'][i])
            elif string == 'regtype':
                output.append('Recipient')
            elif string == 'age':
                output.append(str(int(cand['AGE_AT_ADD_CAND'][i]) + 2017 - int(cand['KPD_ADD_DATE_CAND'][i].split('/')[2])))
            elif string == 'race':
                if not np.isnan(cand['ETHCAT_CAND'][i]):
                    output.append(cand['ETHCAT_CAND'][i])
                else:
                    output.append('')
            elif string == 'isdonor':
                output.append('0')
            elif string == 'bloodType':
                blood = cand['ABO_CAND'][i]
                for k in range(10):
                    blood = blood.replace(str(k), '')
                output.append(blood)
            elif string == 'bloodTypeExtended':
                output.append(cand['ABO_CAND'][i])
            elif string in ['center', 'center_star']:
                if cand['KPD_LISTING_CTR_CODE_CAND'][i] in center_code:
                    output.append(center_code[cand['KPD_LISTING_CTR_CODE_CAND'][i]])
                else:
                    output.append(cand['KPD_LISTING_CTR_CODE_CAND'][i])
            elif string in ['maxAgeForDonor']:
                output.append(cand['MAX_DONOR_AGE'][i])
            elif string in ['A1', 'A2', 'B1', 'B2', 'DR1', 'DR2']:
                #look for na values
                output.append(cand['C' + string][i])
            elif string == 'pra':
                output.append(cand['CPRA_AT_MATCH_RUN'][i])
            elif string[0:4] == 'anti':
                word = string[4:].upper()
                word = ('DQ' if word == 'DQB' else word)
                word = ('DP' if word == 'DPB' else word)
                if word in antib and word != '':
                    output.append(str(antib[word]))
                elif word in antib and word != '':
                    output.append(str(antib[word]))
                else:
                    output.append('')
            elif string == 'tx_id':
                if cand['KPD_REG_CODE_CAND'][i] in trr_id:
                    output.append(trr_id[cand['KPD_REG_CODE_CAND'][i]])
                else:
                    output.append('')
            elif string == 'transplanteddate':
                if cand['KPD_REG_CODE_CAND'][i] in tx_date:
                    output.append(tx_date[cand['KPD_REG_CODE_CAND'][i]])
                else:
                    output.append('')
            elif string == 'transplanted':
                if cand['KPD_REG_CODE_CAND'][i] in trr_id:
                    output.append('1')
                else:
                    output.append('0')
            elif string == 'insnapshots':
                output.append('TBD')
            elif string == 'transplant_index':
                if cand['KPD_REG_CODE_CAND'][i] in trr_don:
                    output.append(trr_don[cand['KPD_REG_CODE_CAND'][i]])
                else:
                    output.append('')
            elif string == 'WL-ID':
                output.append(cand['WL_ID_CODE'][i])
            elif string == 'DONORID':
                if cand['KPD_REG_CODE_CAND'][i] in donor_id:
                    output.append(donor_id[cand['KPD_REG_CODE_CAND'][i]])
                else:
                    output.append('')
            elif string == 'tx_cycle':
                if cand['KPD_REG_CODE_CAND'][i] in cycle:
                    output.append('1')
                else:
                    output.append('')
            elif string == 'tx_chain':
                if cand['KPD_REG_CODE_CAND'][i] in chain:
                    output.append('1')
                else:
                    output.append('')
            else:
                output.append('TBD')
            
        seen.add(cand['KPD_REG_CODE_CAND'][i])
        csvwriter.writerow(output)
        
        
    #DONOR    
    for i in range(len(donor['MR_DATE'])):
        output = []
        if donor['KPD_REG_CODE_DON'][i] in seen:
            continue
        for string in list(new):
            if string in ignoreDon:
                output.append('')
            elif string in ['id', 'index']:
                output.append(donor['KPD_REG_CODE_DON'][i])
            elif string in ['famID']:
                if not np.isnan(donor['KPD_REG_CODE_CAND'][i]):
                    output.append(donor['KPD_REG_CODE_CAND'][i])
                else:
                    output.append('')
            elif string in ['arr_date_min', 'arr_date_max']:
                output.append(arrDon[donor['KPD_REG_CODE_DON'][i]])
            elif string in ['dep_date_max', 'dep_date_min']:
                output.append(depDon[donor['KPD_REG_CODE_DON'][i]])
            elif string in ['Registered']:
                output.append(donor['KPD_DON_ADD_DATE'][i])
            elif string == 'extended_id':
                output.append(donor['PT_CODE_DON'][i])
            elif string == 'regtype':
                if donor['NON_DIRECTED_DONOR'][i] == 'Y':
                    output.append('Donor Non Directed')
                else:
                    output.append('Donor Incompatible')
            elif string == 'alt':
                if donor['NON_DIRECTED_DONOR'][i] == 'Y':
                    output.append('1')
                else:
                    output.append('0')
            elif string == 'age':
                output.append(str(int(donor['AGE_AT_ADD_DON'][i]) + 2017 - int(donor['KPD_DON_ADD_DATE'][i].split('/')[2])))
            elif string == 'race':
                if not isinstance(donor['ETHCAT_DON'][i], float):
                    output.append(donor['ETHCAT_DON'][i])
                else:
                    output.append('')
            elif string == 'isdonor':
                output.append('0')
            elif string == 'bloodType':
                blood = donor['ABO_DON'][i]
                for k in range(10):
                    blood = blood.replace(str(k), '')
                output.append(blood)
            elif string == 'bloodTypeExtended':
                output.append(donor['ABO_DON'][i])
            elif string in ['center', 'center_star']:
                if donor['KPD_LISTING_CTR_CODE_DON'][i] in center_code:
                    output.append(center_code[donor['KPD_LISTING_CTR_CODE_DON'][i]])
                else:
                    output.append(donor['KPD_LISTING_CTR_CODE_DON'][i])
            elif string in ['A1', 'A2', 'B1', 'B2', 'DR1', 'DR2']:
                if not np.isnan(donor['D' + string][i]):
                    output.append(donor['D' + string][i])
                else:
                    output.append('')
            elif string == 'donorRelation':
                if not np.isnan(donor['KPD_REG_CODE_CAND'][i]):
                    output.append(donor['KPD_REG_CODE_CAND'][i])
                else:
                    output.append('')
            elif string == 'tx_id':
                if donor['KPD_REG_CODE_DON'][i] in trr_id:
                    output.append(trr_id[donor['KPD_REG_CODE_DON'][i]])
                else:
                    output.append('')
            elif string == 'transplanteddate':
                if donor['KPD_REG_CODE_DON'][i] in tx_date:
                    output.append(tx_date[donor['KPD_REG_CODE_DON'][i]])
                else:
                    output.append('')
            elif string == 'transplanted':
                if donor['KPD_REG_CODE_DON'][i] in trr_id:
                    output.append('1')
                else:
                    output.append('0')
            elif string == 'insnapshots':
                output.append('TBD')
            elif string == 'transplant_index':
                if donor['KPD_REG_CODE_DON'][i] in trr_cand:
                    output.append(trr_cand[donor['KPD_REG_CODE_DON'][i]])
                elif donor['KPD_REG_CODE_DON'][i] in missing_cand:
                    output.append('-10')
                else:
                    output.append('')
            elif string[0:3] == 'DR5':
                if donor['D' + string][i] == 'Positive':
                    output.append('1')
                elif donor['D' + string][i] == 'Negative':
                    output.append('-1')
            elif string in ['DPB1', 'DQB1', 'DPB2', 'DQB2']:
                if not np.isnan(donor['D' + string[0:2] + string[3]][i]):
                    output.append(donor['D' + string[0:2] + string[3]][i])
                else:
                    output.append('')
            elif string == 'Bw1':
                if donor['DBW4'][i] == 'Positive':
                    output.append('4')
                else:
                    output.append('-1')
            elif string == 'Bw2':
                if donor['DBW6'][i] == 'Positive':
                    output.append('6')
                else:
                    output.append('-1')
            elif string == 'Bw4':
                if donor['DBW4'][i] == 'Positive':
                    output.append('1')
                else:
                    output.append('-1')         
            elif string == 'Bw6':
                if donor['DBW6'][i] == 'Positive':
                    output.append('1')
                else:
                    output.append('-1')
            elif string[0:2] == 'Cw':
                if not np.isnan(donor['D' + string.upper()][i]):
                    output.append(donor['D' + string.upper()][i])
                else:
                    output.append('')
            elif string == 'tx_cycle':
                if donor['KPD_REG_CODE_DON'][i] in cycle:
                    output.append('1')
                else:
                    output.append('')
            elif string == 'tx_chain':
                if donor['KPD_REG_CODE_DON'][i] in chain:
                    output.append('1')
                else:
                    output.append('')
            elif string == 'Missing Candidate':
                if donor['KPD_REG_CODE_DON'][i] in missing_cand:
                    output.append('WL')
                else:
                    output.append('')
            else:
                output.append('TBD')
        seen.add(donor['KPD_REG_CODE_DON'][i])    
        csvwriter.writerow(output)
        

