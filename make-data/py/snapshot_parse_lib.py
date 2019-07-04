# Python Library For Parsing Snapshots

# Turn aliases to IDs.  Basically, drop everything past the underscore.
def alias2ID(alias):
    usPos = alias.index('_')
    ID = alias[0:usPos]        
    return ID

# Append a list of fields
# Puts the data from row (a dictionary that maps field names to their values) into ss_entry (a dictionary of the 
# same sort).  Two issues make this more complicated: 1) the two dictionaries use different keys for the same fields 
# and 2) we don't want all the fields of row to go into ss_entry.  fieldlist contains the fields to be transferred 
# from row to ss_entry, while fieldnames contains the "translation" of those field names into the keys used in ss_entry.
def appendfields(ss_entry,row,fieldlist,fieldnames):
    for index in range(len(fieldlist)):
        # Do not attempt writing missing fieldnames
        if fieldlist[index] in row.keys():
            ss_entry[fieldnames[index]] = row[fieldlist[index]]
    return ss_entry

# Add to the current list of antibodies
# Does the same thing as "appendfields", but for fields that contain pipe-delimited lists.  These lists are appended 
# to the already existing entries in ss_entry.
def appendlist(nkr_data_ID,ss_entry,row,ssfields,nkrfields):
    for index in range(len(ssfields)):
        # Do not attemp writing missing fieldnames
        if ssfields[index] in row.keys():
            if nkrfields[index] in nkr_data_ID.keys():
                ss_entry[nkrfields[index]] = nkr_data_ID[nkrfields[index]] + row[ssfields[index]].split('|')
            else:
                ss_entry[nkrfields[index]] = row[ssfields[index]].split('|')
    return ss_entry

# Create a pipe-delimited list with unique entries
def uniquepipelist(ss_entry,fields):
    for index in range(len(fields)):
        set = {}
        if fields[index] in ss_entry.keys():
            map(set.__setitem__, ss_entry[fields[index]], [])
        ss_entry[fields[index]] = '|'.join(map(str,set.keys()))
    return ss_entry

# Arrival and Departure Dates
def arr_dep_dates(ss_entry, this_id_dates, date_list):
    # Find the min arrival date -- Initialize
    ss_entry['arr_date_max'] = this_id_dates[0]
    ss_entry['arr_date_min'] = date_list[0]

    ss_entry['dep_date_max'] = date_list[-1]
    ss_entry['dep_date_min'] = this_id_dates[-1]

    # Loop through date_list
    for date in date_list:
        if date<this_id_dates[0]:
            ss_entry['arr_date_min'] = date
        if date>this_id_dates[-1]:
            ss_entry['dep_date_max'] = date
            break

    return ss_entry
