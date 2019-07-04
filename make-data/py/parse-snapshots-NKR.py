#!/usr/bin/env python

# ***********************************************************************************
# 1. Reads input files from raw-files/nkr -- set raw-files/nkr to symbolic link with file location
# 2. Generates NKRHistoricalData
#
#
# ***********************************************************************************

# Parses the snapshot files

# Import
import glob, os
import datetime
import csv
import snapshot_parse_lib as splib
import shutil
from   pra_lib   import PRA
from   pra_lib   import Personel
import pdb
import iscompatible as isComp
from   pprint    import pprint
from   itertools import chain

# Get filenames from load-globals.do.  This makes the Stata and the python codebases look to the 
# same place for filenames that are shared between them.
with open("./intermediate-data/globals_for_py_code.csv") as globalfile:
    reader = csv.DictReader(globalfile)
    globs  = dict()
    for row in list(reader):
        globs[row['name']]=row['content']

# To do list
# 1. Track Altruistic donors to construct chain length

# NKR Historical Data Fieldnames for output file
fieldnames = ['id',            'index',       'extended_id',    'famID',            'tx_id',            'regtype',         'chip',            'arr_date_min',
              'arr_date_max',  'dep_date_max','dep_date_min',   'Registered',       'age',              'sex',             'race',            'weight',
              'height','type', 'isdonor',     'alias',          'bloodType',        'alt',              'center',          'center_star',     'minWeight',       'donorRelation',
              'maxAgeForDonor','minHLApoints','exchangeProgram','A1',               'A2',               'B1',              'B2',              'DR1',
              'DR2',           'Bw1',         'Bw2',            'Bw4',              'Bw6',              'Cw1',             'Cw2',             'DRw1',
              'DRw2',          'DPA1',        'DPA2',           'DPB1',             'DPB2',             'DQA1',            'DQA2',            'DQB1',
              'DQB2',          'DR51',        'DR52',           'DR53',             'antiA',            'antiB',           'antiDR',          'antiDR51',
              'antiDR52',      'antiDR53',    'antiBw',         'antiCw',           'antiDRw',          'antiBw4',         'antiBw6',         'antiDPa',
              'antiDPb',       'antiDQa',     'antiDQb',        'pra',              'DonorASubtype',    'Recipient_Non_A1','transplanteddate',
              'transplanted',  'badData',     'missingPatient', 'insnapshots',      'fromTransplantIDS','transplant_index','tx_chain',        'tx_cycle', 
              'Related Donors','dialysisstartdate','unoslistdate','unpaired','hard_blocked_donors']
#             'cPRA', 'Related Donors','mp_strict',   'mp_strict_noabo', 'mp_weak', 'mp_weak_noabo', 'dialysisstartdate','unoslistdate','unpaired','hard_blocked_donors']

# Add the map from snapshot field names to NKR Historical Data fieldnames here

# nkr_* -- names for the output file
# ss_* -- names for the snapshot file
# xp_* -- names for the transplant file

# These are antigen names that all files agree on
hlalist     = ['A1','A2','B1','B2','DR1','DR2','Bw1','Bw2','Cw1','Cw2','DQ1','DQ2']
# These are antigen names whose name varies from file to file
nkr_hlalist = ['DR51', 'DR52', 'DR53', 'Bw4', 'Bw6', 'DRw1','DRw2','DQA1','DQA2','DPA1','DPA2','DPB1','DPB2','DQA1','DQA2','DQB1','DQB2']
ss_hlalist  = ['DR-51','DR-52','DR-53','miss','miss','miss','miss','miss','miss','miss','miss','DP1', 'DP2', 'DQa1','DQa2','DQ1', 'DQ2']
xp_hlalist  = ['DR5-1','DR5-2','miss', 'miss','miss','miss','miss','miss','miss','miss','miss','DP1', 'DP2', 'miss','miss','DQ1', 'DQ2']

# The following field names have pipe delmited lists
# To be accumulated over the various snapshots
nkr_listfields = ['anti' + s        for s in ['A', 'B', 'DR','Bw','Cw','DQb','DPb','DR-51','DR-52','DR-53']] + ['Related Donors']
ss_listfields  = ['Avoids ' + s     for s in ['A', 'B', 'DR','Bw','Cw','DQ', 'DP', 'DR51', 'DR52', 'DR53' ]] + ['Related Donors']
xp_listfields  = [s + ' Antibodies' for s in ['A', 'B', 'DR','Bw','Cw','DQ', 'DP', 'miss', 'miss', 'miss' ]] + ['miss']


# The following field names will have single value in the NKR file, should be static
nkr_fieldnames = ['center',         'alias',              'regtype',             'Registered',    'sex',                     'race',            'bloodType',
                  'weight',         'height',             'minWeight',           'maxAgeForDonor','minHLApoints',            'DonorASubtype',   'Recipient_Non_A1',
                  'Birth Year',     'dialysisstartdate',  'unoslistdate'] + \
                   hlalist + nkr_hlalist
ss_fieldnames  = ['Center',         'ID',                 'Type',                'Registered',    'Gender',                  'Race',            'Blood Type',
                  'Weight (kilos)', 'Height (cm)',        'Minimum Donor Weight','Max Donor Age', 'Minimum HLA Match Points','Donor A Subtype', 'Recipient Non-A1 Titer',
                  'Birth Year',     'missing',    'missing'] + \
                 ['HLA ' + s for s in hlalist    ] + \
                 ['HLA ' + s for s in ss_hlalist ]
xp_fieldnames =  ['Center',         'ID',                 'Type',                'Registered',    'Gender',                  'Race',            'Blood Type',
                  'Weight (kilos)', 'Height (cm)',        'Min. Donor Weight',   'Max Donor Age', 'Min Match Points',        'A1',              'Anti-A1',
                  'Birthdate',      'Dialysis Start Date','UNOS List Date'] + \
                 ['HLA ' + s for s in hlalist] + \
                 [s + ' Donor Antigen' for s in xp_hlalist]


# The following types of match powers will be computed. Pick from weak, weak_noabo, strict, strict_noabo
mp_fieldnames = ['strict','strict_noabo','weak','weak_noabo']

# The errors.txt file contains a list of errors produced by this file.
f1 = open('intermediate-data/errors.txt','w')

print("Gathering snapshot information...")

# Dictionary that will contain the NKR Data: keys are NKR ids and values are dictionaries whose keys are field names
# This will be the data structure that is outputted at the end.
nkr_data = dict()

# Construct a list of snapshot dates and sort them
date_list = list()
for file in os.listdir("raw-files/nkr/snapshots/"):
    if file.endswith("bm1-0.csv"):
        file_date = datetime.datetime.strptime(file[0:11],'%d-%b-%Y')    # first datetime is the module, the second is the class within that module
        date_list.append(file_date)
date_list.sort()

# Read the files -- get a list of all snapshots where this ID is present.  Keys are NKR IDs and values are a list of dates.
ss_dates = dict()

# This line is for debugging: adding an integer like "10" after the colon makes the file run much more quickly.
date_list = date_list[0:]  

# loop through the snapshots files for all dates
# changes will be a set of IDs that have fields change from snapshot to snapshot
changes = list()
changefields = list()
# Loop through the snapshot dates
for this_date in date_list:
    # For the given date, construct the snapshot filename
    filename = this_date.strftime('%d-%b-%Y') + '  bm1-0.csv'
    with open("raw-files/nkr/snapshots/" + filename , mode='r') as infile:
        reader = csv.DictReader(infile)
        # loop through the rows of the snapshots file.  (almost) Each row is an agent.
        for row in reader:        
            # continue until the end of file marker has been reached.  Everything below the `--YMXX_o_XXMY--' is garbage.
            if row['Center']=='--YMXX_o_XXMY--':
                break

            # skip the lines whose ID field indicates they are "placeholders", i.e. lines that do not represent real agents.
            if ('PLC'    in row['ID'] or 
                'END'    in row['ID'] or 
                'FILLER' in row['ID'] or 
                'filler' in row['ID']):
                if (row['HLA A1']  == '-1' or row['HLA A1']  == '') and (row['HLA A2']  == '-1' or row['HLA A2']  == ''):
                    continue
                if (row['HLA B1']  == '-1' or row['HLA B1']  == '') and (row['HLA B2']  == '-1' or row['HLA B2']  == ''):
                    continue
                if (row['HLA DR1'] == '-1' or row['HLA DR1'] == '') and (row['HLA DR2'] == '-1' or row['HLA DR2'] == ''):
                    continue

            # Add this_date to the ss_dates entry for this row's ID
            ID = splib.alias2ID(row['ID'])
            if ID not in ss_dates.keys():
                ss_dates[ID] = []
            ss_dates[ID].append(this_date)    

            # Initialize a dictionary to hold the data for this row of the snapshot
            ss_entry = dict()
            
            # Add all the other columns that we would like to add here            
            # extended_id contains the extra D/R at the front
            ss_entry['id']          = ID[1:]
            ss_entry['extended_id'] = ID
            # appendfields simply overwrites the field with whatever is in the latest snapshot.  appendlist appends the contents 
            # of a pipe-delimited list from the latest snapshot
            ss_entry                = splib.appendfields(ss_entry,row,ss_fieldnames,nkr_fieldnames)
            if ID in nkr_data.keys():
                ss_entry                = splib.appendlist(nkr_data[ID],ss_entry,row,ss_listfields,nkr_listfields)
            else:
                ss_entry                = splib.appendlist(ss_entry,ss_entry,row,ss_listfields,nkr_listfields)
            if row['CHIP'] == 'Yes':
                ss_entry['chip']    = 1 
            else:
                ss_entry['chip']    = 0
            ss_entry['insnapshots'] = 1
          
            # Are the fields we expect to be static actually static?
            # Has this ID already been entered?  
            if (ID in nkr_data.keys()):
                nkrdict = dict((k,nkr_data[ID][k]) for k in nkr_fieldnames if k in nkr_data[ID])
                ssdict  = dict((k,ss_entry[k])     for k in nkr_fieldnames if k in nkr_data[ID])
                if (nkrdict!=ssdict):
                    interesting_change=1
                    newchange = dict()
                    newchange["ID"] = ID
                    newchange["date"] = this_date
                    for k in nkrdict.keys():
                        if nkrdict[k]!=ssdict[k]:
                            # here we only mark "interesting" changes, that is, ones where a value genuinely changes (as opposed to 
                            # a blank being replaced with data or vice-versa) and the field is one we care about.
                            if not ((k in ["alias",      "weight",    "height", "maxAgeForDonor", "DonorASubtype", "regtype",
                                           "Birth Year", "minWeight", "race",   "sex",            "minHLApoints"             ]) or 
                                    (nkrdict[k]=="") or
                                    (ssdict[k]=="")):
                                # changefields is used below to ensure that the output csv of changes only includes columns for fields that actually change.
                                if k+" OLD" not in changefields:
                                    changefields = changefields + [k+" OLD",k+" NEW"]
                                newchange[k+" OLD"]=nkrdict[k]
                                newchange[k+" NEW"]=ssdict[k]

                            # When a blank is replaced by something, the default "most recent snapshot overwrites previous snapshot" works fine
                            # When something is replaced by a blank, however, we have to take action to ensure that the data isn't destroyed.
                            if ((nkrdict[k]!="" and ssdict[k]=="") or 
                                (nkrdict[k]!="-1" and ssdict[k]=="-1") or 
                                (k == "regtype" and nkrdict[k]=="Donor Incompatible" and ssdict[k]=="Donor Non Directed") or
                                (k == 'chip' and nkrdict[k]=='1' and ssdict[k]=='0')):
                                ss_entry[k]==nkr_data[ID][k]
                    if len(newchange)>2:        
                        changes.append(newchange)
              
            # Get the list of hard-blocked donors
            donor_list = filter(bool,row['Hard Blocked Donors'].split("|"))
            # One random recipient has a 'D' only listed
            ss_entry['hard_blocked_donors'] = set([splib.alias2ID(x) for x in donor_list if x!='D' and '_' in x])
            # Add previously blocked donors to ss_entry
            if ID in nkr_data.keys():
                if 'hard_blocked_donors' in nkr_data[ID].keys():
                    ss_entry['hard_blocked_donors'] = ss_entry['hard_blocked_donors'].union(nkr_data[ID]['hard_blocked_donors'])

            nkr_data[ID] = ss_entry

changes = sorted(changes, key=lambda row: row["ID"]+str(row["date"]))

#with open('ss_changes.csv','w') as csvfile:
#    writer = csv.DictWriter(csvfile, fieldnames=["ID","date"]+changefields)
#    writer.writerow( dict((f,f) for f in writer.fieldnames) )
#    writer.writerows(changes)
print("Looking at last xplanted file...")
# Get the information on all transplanted individuals from the last xplanted file
# No need to look at previous xplanted files, as they are cumulative
filenames = ["raw-files/nkr/snapshots/" + date_list[-1].strftime('%d-%b-%Y') + '  bm1-0xplanted.csv', 
             "raw-files/nkr/additional-xplanted.csv"]
# Dictionary whose keys are values are "Cross match in progress" and whose values are dictionaries of transplant info.
tx_dict = dict()
print(filenames)
for filename in filenames:
    with open(filename , mode='r') as infile:
        # Remove leading space in variable names
        header = [h.lstrip() for h in infile.next().split(',')]
        reader = csv.DictReader(infile, fieldnames = header)
        for row in reader:
            # continue until the end of file marker has been reached.  Everything below the `--YMXX_o_XXMY--' is garbage.
            if row['Center']=='--YMXX_o_XXMY--':
                break
            # skip the lines whose ID field indicates they are "placeholders", i.e. lines that do not represent real agents.
            if ('PLC'    in row['ID'] or 
                'END'    in row['ID'] or 
                'FILLER' in row['ID'] or 
                'filler' in row['ID']):
                if (row['HLA A1']  == '-1' or row['HLA A1']  == '') and (row['HLA A2']  == '-1' or row['HLA A2']  == ''):
                    continue
                if (row['HLA B1']  == '-1' or row['HLA B1']  == '') and (row['HLA B2']  == '-1' or row['HLA B2']  == ''):
                    continue
                if (row['HLA DR1'] == '-1' or row['HLA DR1'] == '') and (row['HLA DR2'] == '-1' or row['HLA DR2'] == ''):
                    continue

            # Basically, drop everything past the "_" in the ID.
            ID = splib.alias2ID(row['ID'])

            # If the agent was in the snapshots, then we just pull the snapshot entry.  If not, we construct a snapshot entry from the tx entry.
            if ID in nkr_data.keys():
                ss_entry = nkr_data[ID]            
            else:
                # Need to combine the code for pulling the variables
                ss_entry                = dict()
                ss_entry['id']          = ID[1:]            
                ss_entry['extended_id'] = ID
                ss_entry                = splib.appendfields(ss_entry,row,xp_fieldnames,nkr_fieldnames)
                # Since ID is not a part of nkr_data, we enter ss_entry
                ss_entry                = splib.appendlist(ss_entry,ss_entry,row,xp_listfields,nkr_listfields)
                ss_entry['insnapshots'] = 0            
                ss_entry['Related Donors'] = []
                
                if filename == "raw-files/nkr/additional-xplanted.csv":
                    if row['IsInCHIP\n'] == '1':
                        ss_entry['chip']    = 1 
                    else:                        
                        ss_entry['chip']    = 0
                else:
                    if row['IsInCHIP\r\n'] == '1':
                        ss_entry['chip']    = 1 
                    else:
                        ss_entry['chip']    = 0

            # Now, we add the agents to the tx_list
            # "Cross match in Progress" is unique for each transplant.
            tx_id = row['Cross Match in Progress']

            # The tx_id might already be in the tx_dict because each row in the the transplants file represents an agent, 
            # so we might be processing the recipient after the donor has already been processed.
            if tx_id in tx_dict.keys():
                tx_entry = tx_dict[tx_id]
            else:
                tx_entry = dict()
                # Record whether this transplant is a cycle or a chain.  This is marked in the data by the first part of the pipe-delimited 
                # list in "Cross match in progress"
                tx_entry['crossmatch']       = tx_id.split('|')
                tx_entry['transplant_index'] = tx_entry['crossmatch'][0]
                if tx_entry['transplant_index']!='':
                    if int(tx_entry['transplant_index'])>=500:
                        tx_entry['tx_cycle'] = 1
                        tx_entry['tx_chain'] = 0
                    else:
                        tx_entry['tx_cycle'] = 0
                        tx_entry['tx_chain'] = 1
            # Only the recipient rows have "transplanted date"s
            if row['Type'] == 'Recipient':
                tx_entry['recID'] = ID
                tx_entry['transplanteddate'] = datetime.datetime.strptime(row['Transplanted Date'],'%m/%d/%Y')
            else:
                tx_entry['donID'] = ID

            tx_dict[tx_id] = tx_entry

            # Get the transplanted date -- only the recipients have these entries
            if row['Transplanted Date']!='':
                ss_entry['transplanteddate'] = datetime.datetime.strptime(row['Transplanted Date'],'%m/%d/%Y')

            # Write to data
            nkr_data[ID] = ss_entry

# Append Related Donors, starting with PairsIDsOriginallyFromNKR, non-type-100, and then moving to best match pairs
filelist = ['raw-files/nkr/PairsIDsOriginallyFromNKR.csv', 'raw-files/nkr/non-type100.csv'] +  \
           ['raw-files/nkr/snapshots/' +  x.strftime('%d-%b-%Y') + 'best_match_pairs.csv' for x in date_list]
for filename in filelist:
    with open(filename, mode='r') as infile:
        reader = csv.reader(infile)
        for row in reader:        
            recID = 'R' + row[0]
            donID = 'D' + row[1]
            if recID in nkr_data.keys():            
                nkr_data[recID]['Related Donors'].append(donID + '_')

# Read Transplants from the TransplantIDS.csv file
with open("raw-files/nkr/TransplantIDS.csv", mode='r') as infile:
    reader = csv.DictReader(infile)
    for row in reader:        
        recID = 'R' + row['recpId']
        donID = 'D' + row['DonorId']
        if recID in nkr_data.keys() and donID in nkr_data.keys():
            nkr_data[recID]['tx_id']             = donID
            nkr_data[donID]['tx_id']             = recID
            nkr_data[recID]['transplanteddate']  = datetime.datetime.strptime(row['recpTransplantDate'],'%Y-%m-%d')
            nkr_data[donID]['transplanteddate']  = datetime.datetime.strptime(row['recpTransplantDate'],'%Y-%m-%d')
            nkr_data[donID]['fromTransplantIDS'] = 1
            nkr_data[recID]['fromTransplantIDS'] = 1
            

# Append if not in TransplantIDS file
for crossmatch in tx_dict.keys():
    tx_entry = tx_dict[crossmatch]
    if 'recID' in tx_entry.keys() and 'donID' in tx_entry.keys():
        recID = tx_entry['recID']
        donID = tx_entry['donID']
        if recID in nkr_data.keys() and donID in nkr_data.keys():            
            if 'fromTransplantIDS' not in nkr_data[recID].keys():             
                nkr_data[recID]['tx_id'] = donID
                nkr_data[donID]['tx_id'] = recID                
                nkr_data[donID]['transplanteddate'] = tx_entry['transplanteddate']      
         
                # Append data to nkr_data
                tx_entry['fromTransplantIDS'] = 0
                tx_fields = ['fromTransplantIDS','transplanted','tx_chain','tx_cycle','transplant_index']
                nkr_data[recID] = splib.appendfields(nkr_data[recID],tx_entry,tx_fields,tx_fields)
                nkr_data[donID] = splib.appendfields(nkr_data[donID],tx_entry,tx_fields,tx_fields)
            else:
                if donID==nkr_data[recID]['tx_id']:
                    tx_fields = ['tx_chain','tx_cycle','transplant_index'] 
                    nkr_data[recID] = splib.appendfields(nkr_data[recID],tx_entry,tx_fields,tx_fields)
                    nkr_data[donID] = splib.appendfields(nkr_data[donID],tx_entry,tx_fields,tx_fields)                
                else:
                    # The following transplant errors are hand-checked
                    if not ((recID == 'R1085' and nkr_data[recID]['tx_id'] == 'D3263') or
                            (recID == 'R1084' and nkr_data[recID]['tx_id'] == 'D3234')):
                        print 'Error!'
                        f1.write('**************\n')
                        f1.write('Incompatible Data:\n')
                        f1.write(recID + ' received a kidney from ' + donID + ' according to xplanted, but according to TransplantIDS, ' + nkr_data[recID]['tx_id'] +  ' was the donor\n')

# Manual fixes to the data, based on examining transplant chains
nkr_data['R3607']['Related Donors'] = ['D8496_']
nkr_data['R2511']['Related Donors'] = []
nkr_data['R1022']['Related Donors'] = ['D2752_']
nkr_data['R1091']['Related Donors'] = ['D2854_']
nkr_data['R166']['Related Donors'] = [x for x in nkr_data['R166']['Related Donors'] if 'D2854' not in x]

# Generate famID and isdonor, and related donors
famIDindex = dict()
index = 1;
for ID in nkr_data.keys():
    if ID[0]=='D':
        nkr_data[ID]['isdonor'] = 1
    else:
        nkr_data[ID]['isdonor'] = 0
        # Generate famID
        nkr_data[ID]['famID'] = nkr_data[ID]['id']
        
        # Keep IDs only, purge FILLERS (don't worry since best match pairs will catch the good ones) and only unique entries
        donor_list = [x for x in nkr_data[ID]['Related Donors'] if 'FILLER' not in x]
        donor_list = filter(bool,donor_list)
        donor_list = [splib.alias2ID(x) for x in donor_list]

        # Drop the Related donor if the donor is not in nkr_data
        donor_list = [x for x in donor_list if x in nkr_data.keys()]

        set = {}
        map(set.__setitem__, donor_list, [])
        nkr_data[ID]['Related Donors'] = set.keys()

        # Drop Hard Blocked donors if not in nkr_data
        if 'hard_blocked_donors' in nkr_data[ID].keys():
            hardBlockedDonors = [x for x in nkr_data[ID]['hard_blocked_donors'] if x in nkr_data.keys()]
            set = {}
            map(set.__setitem__, hardBlockedDonors, [])
            nkr_data[ID]['hard_blocked_donors'] = '|'.join(map(str,set.keys()))

        # Generate a recoded unpaired variable
        if len(nkr_data[ID]['Related Donors']) == 0:
            nkr_data[ID]['unpaired'] = 1
        else:
            nkr_data[ID]['unpaired'] = 0

        # Generate type == 22
        if len(nkr_data[ID]['Related Donors'])>0:            
            nkr_data[ID]['type'] = 0
            # Index for the family is the famID
            famIDindex[nkr_data[ID]['id']] = index
        else:
            if nkr_data[ID]['chip'] == 0:
                nkr_data[ID]['type'] = 22
                #print nkr_data[ID]['Related Donors']

        # Append famID
        for don_ID in nkr_data[ID]['Related Donors']:            
            if don_ID in nkr_data.keys():
                nkr_data[don_ID]['famID'] = nkr_data[ID]['id']
                nkr_data[don_ID]['index'] = index
                nkr_data[don_ID]['type'] = 0

        # Add index to the recipient and increment
        nkr_data[ID]['index'] = index
        index += 1 

# Generate index for altruistic donors
for ID in nkr_data.keys():
    if ID[0]=='D' and 'famID' not in nkr_data[ID].keys():
        nkr_data[ID]['index']=index;
        index += 1

##
print('Reformatting data, and generating other fields')
donor_pool = []
recipient_pool = []

# Find the min and max dates within each ID
for ID in nkr_data.keys():
    # Generate type for altruistic donors
    if ID[0]=='D':
        if 'famID' not in nkr_data[ID].keys():
            nkr_data[ID]['alt'] = 1
            if nkr_data[ID]['regtype'] == 'Donor Incompatible':
                nkr_data[ID]['type'] = 100 

    # Do this only if arrival and departure dates are not known for this ID    
    if ID in ss_dates.keys():
        this_id_dates = ss_dates[ID]
        nkr_data[ID] = splib.arr_dep_dates(nkr_data[ID], this_id_dates, date_list)

    # Calculations above may be redundant for some pairs
    # Flexibly allows us to consider variations of choices below
    if 'Registered' in nkr_data[ID].keys():
        registered_date = datetime.datetime.strptime(nkr_data[ID]['Registered'],'%m/%d/%Y %H:%M')
        nkr_data[ID]['arr_date_max'] = registered_date
        nkr_data[ID]['arr_date_min'] = registered_date

    if 'transplanteddate' in nkr_data[ID].keys():
        nkr_data[ID]['dep_date_max'] = nkr_data[ID]['transplanteddate']
        nkr_data[ID]['dep_date_min'] = nkr_data[ID]['transplanteddate']
        nkr_data[ID]['transplanted'] = 1
 
    # Set missing antigens to -1
    for antigen in hlalist + nkr_hlalist:
        if antigen not in nkr_data[ID].keys():
            nkr_data[ID][antigen] = -1
        elif not nkr_data[ID][antigen]:
            nkr_data[ID][antigen]=-1

    # Check for badData (bad Antigen Data)
    nkr_data[ID]['badData'] = 0
    if nkr_data[ID]['A1'] == -1 and nkr_data[ID]['A2'] == -1:
        nkr_data[ID]['badData'] = 1
    if nkr_data[ID]['B1'] == -1 and nkr_data[ID]['B2'] == -1:
        nkr_data[ID]['badData'] = 1
    if nkr_data[ID]['DR1'] == -1 and nkr_data[ID]['DR2'] == -1:
        nkr_data[ID]['badData'] = 1

    # Turn lists into pipe - delimited fields
    nkr_data[ID] = splib.uniquepipelist(nkr_data[ID],nkr_listfields)

    # Calculate Age -- Use transplanted date, but then move to departure date, ignoring months
    if nkr_data[ID]['Birth Year']!='00/00/0000':
        birthdate = datetime.datetime.strptime(nkr_data[ID]['Birth Year'],'%m/%d/%Y')
        if 'transplanteddate' in nkr_data[ID].keys():
            nkr_data[ID]['age'] = nkr_data[ID]['transplanteddate'].year - birthdate.year 
        elif 'dep_date_max' in nkr_data[ID].keys():
            nkr_data[ID]['age'] = nkr_data[ID]['dep_date_max'].year - birthdate.year 
        else:
            nkr_data[ID]['age'] = date_list[-1].year - birthdate.year

    # Reformat the dates
    nkr_data[ID]['arr_date_max'] = nkr_data[ID]['arr_date_max'].strftime('%m/%d/%Y')
    nkr_data[ID]['arr_date_min'] = nkr_data[ID]['arr_date_min'].strftime('%m/%d/%Y')

    # Donors don't have a transplanted date, and therefore no departure data if they're not in the snapshots
    if nkr_data[ID]['insnapshots'] == 1 or ID[0] == 'R' or 'transplanteddate' in nkr_data[ID].keys():
        nkr_data[ID]['dep_date_max'] = nkr_data[ID]['dep_date_max'].strftime('%m/%d/%Y')
        nkr_data[ID]['dep_date_min'] = nkr_data[ID]['dep_date_min'].strftime('%m/%d/%Y')

    if 'transplanteddate' in nkr_data[ID].keys():
        nkr_data[ID]['transplanteddate'] = nkr_data[ID]['transplanteddate'].strftime('%m/%d/%Y')      
'''
    # Generate Donor and Recipient Pool
    if ID[0]=='D':
        donor_pool.append(nkr_data[ID])
    else:
        recipient_pool.append(nkr_data[ID])


# Calculate Match Power and PRA
print 'Calculating Match Power and PRA'        
pra = PRA()
for ID in nkr_data.keys():
    if ID[0]=='D':
        nkr_data[ID] = isComp.donorMP(nkr_data[ID],recipient_pool,mp_fieldnames)

    if ID[0]=='R':
        nkr_data[ID] = isComp.recipientMP(nkr_data[ID],donor_pool,mp_fieldnames)

        # Calculate cPRA for patients
        params = {
            'anti_a': filter(bool,nkr_data[ID]['antiA'].split('|')),
            'anti_b': filter(bool,nkr_data[ID]['antiB'].split('|')),
            'anti_dqb': filter(bool,nkr_data[ID]['antiDQb'].split('|')),
            'anti_dr': filter(bool,nkr_data[ID]['antiDR'].split('|'))
        }
        personel = Personel(**params)            
        nkr_data[ID]['cPRA'] = pra.calculate(personel)

    # Rename fields
    for field in mp_fieldnames:        
        nkr_data[ID]['mp_' + field] = nkr_data[ID][field]
'''

print('Merging in STAR center IDs...')
# Read in the file to add center_nkr to the file
center_dict = dict()
#with open("intermediate-data/nkr-center-dictionary.csv" , mode='r') as infile:
with open(globs['nkr_star_ctr_dict_csv'] , mode='r') as infile:
    reader = csv.DictReader(infile)
    for row in reader:
        center_dict[row['nkr_center_name']]=row['star_center_id'] 

# Add center_nkr to nkr_data
for ID in nkr_data.keys():
    if nkr_data[ID]['center'] in center_dict.keys():
        nkr_data[ID]['center_star'] = center_dict[nkr_data[ID]['center']]
    

print('Writing output...')
# Write NKR Historical Data sans MP or cPRA
#with open('intermediate-data/NKRHistoricalDataAll-sans-MP-cPRA.csv','w') as csvfile:
with open(globs['nkr_file_sans_MP_cPRA'],'w') as csvfile:
    fieldnames = [ f.lower() for f in fieldnames ]
    writer = csv.DictWriter(csvfile, fieldnames = fieldnames, extrasaction = 'ignore')
    # Older versions of python don't have the writeheader() attribute
    writer.writerow(dict((fn,fn) for fn in fieldnames))
    for ID in nkr_data.keys():        
        #writer.writerow(nkr_data[ID])
        writer.writerow(dict( (k.lower(), nkr_data[ID][k]) for k in nkr_data[ID].keys() ) )


print("Length of nkr_data:"+str( len(nkr_data) ) )       
f1.close()


