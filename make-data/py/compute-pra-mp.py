#!/usr/bin/env python

# Import
from   pra_lib      import PRA
from   pra_lib      import Personel
import iscompatible as     isComp
from   pprint       import pprint
import csv
import sys

#
# mp_fieldnames can contain 'bloodType' 'weak','weak_noabo', 'strict', and 'strict_noabo'
#
# Notes on these compatibility types 
#
#   bloodType:    Just ABO compatibility, as advertised.  Requires each row to contain
#                 a field called bloodType whose values are "A","B,"O", or "AB".
#
#   weak_noabo:   Weak tissue-type compatibility (ignoring ABO).  
#                 Donor rows must contain fields 
#                   A1, A2, B1, B2, DR1, and DR2   
#                 Recipient rows must contain fields 
#                   antiA, antiB, and antiDR
#                 The recipient antibody fields should have codes that...  
#                   ...agree with those in the donor antigen fields
#                   ...are pipe-delimited
#
#   strict_noabo: Strong tissue-type compatibility (ignoring ABO).  
#                 Donor rows must, in addition to containing the fields required for weak_noabo, also
#                 contain fields 
#                   Bw1,  Bw2,  Bw4,  Bw6,  Cw1,  Cw2,  DRw1, DRw2, DPA1, 
#                   DPA2, DQA1, DQA2, DQB1, DQB2, DR51, DR52, DR53
#                 Recipient rows must, in addition to containing the fields required for weak_noabo, also
#                 contain fields 
#                   antiBw,  antiBw4, antiBw6,  antiCw,   antiDRw, antiDPa, 
#                   antiDQa, antiDQb, antiDR51, antiDR52, antiDR53
#                 The receipient antibody fields should have codes that...  
#                   ...agree with those in the recipient antigen fields
#                   ...are pipe-delimited
#
#   strict/weak:  Must be both strict/weak tissue-type compatible and blood-type compatible.
#

mp_fieldnames = ['weak','weak_noabo', 'strict', 'strict_noabo']

# Gets global filenames from an external file
with open("./intermediate-data/globals_for_py_code.csv") as globalfile:
    reader = csv.DictReader(globalfile)
    globs  = dict()
    for row in list(reader):
        globs[row['name']]=row['content']

####
# Load NKR donor and recipient pool.

print 'Loading NKR donor and recipient pool.'

# donor_pool and recipient_pool remain the same for the other clearinghouses as well -- we always 
# compute match-power relative to the NKR population.
donor_pool     = list()
recipient_pool = list()

nkr_data       = dict()

with open(globs['nkr_file_sans_MP_cPRA'], mode='r') as infile:
    reader = csv.DictReader(infile)
    nkr_fieldnames = reader.fieldnames
    for row in reader:
        ID = row['extended_id']
        nkr_data[ID] = row
        # Generate Donor and Recipient Pool
        if ID[0]=='D':
            donor_pool.append(    nkr_data[ID])
        else:
            recipient_pool.append(nkr_data[ID])

###
# NKR

if "NKR" in sys.argv:
    # Calculate Match Power and PRA
    print 'Calculating Match Power and PRA for NKR'
    pra = PRA()
    i=0
    denom=str(len(nkr_data.keys()))
    for ID in nkr_data.keys():
        # isComp.(donor|recipient)MP adds an entry to nkr_data[ID] for each of the match-power fieldnames.
        if   ID[0]=='D':
            nkr_data[ID] = isComp.donorMP(    nkr_data[ID],recipient_pool,mp_fieldnames)
        elif ID[0]=='R':
            nkr_data[ID] = isComp.recipientMP(nkr_data[ID],donor_pool,    mp_fieldnames)

            # Calculate cPRA for patients
            # the filter-bool bit ensures that blanks, ' ', and the like aren't fed into the routine.
            params = {
             'anti_a'  : filter(bool,nkr_data[ID]['antia'  ].split('|')),
             'anti_b'  : filter(bool,nkr_data[ID]['antib'  ].split('|')),
             'anti_dqb': filter(bool,nkr_data[ID]['antidqb'].split('|')),
             'anti_dr' : filter(bool,nkr_data[ID]['antidr' ].split('|'))
            }
            # The ** syntax, when unpacked, merely calls Personel(anti_a = [4,5], anti_b=[7,54],...)
            # Besides that, the PRA package is pretty opaque. Hopefully everything is working...
            personel = Personel(**params)
            nkr_data[ID]['cpra'] = pra.calculate(personel)
        # Rename fields
        for field in mp_fieldnames:
            nkr_data[ID]['mp_' + field] = nkr_data[ID][field]
        i+=1
        if i%100==0:
            sys.stdout.write('\r'+str(i)+'/'+denom)
            sys.stdout.flush()
    sys.stdout.write('\r'+denom+'/'+denom+'\n')
    sys.stdout.flush()

    with open(globs['nkr_pra_mp'],'w') as csvfile:
        headers = ['cpra','mp_weak',  'mp_weak_noabo','mp_strict','mp_strict_noabo']
        csvfile.write('extended_id,')
        csvfile.write(','.join(headers))
        csvfile.write('\n')
        for ID in nkr_data.keys():
            csvfile.write(ID)
            for h in headers:
                csvfile.write(',')
                if h in nkr_data[ID].keys():
                    csvfile.write(str(nkr_data[ID][h]))
            csvfile.write('\n')

#############
# UNOS-KPD

if "UNOS" in sys.argv:
    print 'Calculating Match Power and PRA for UNOS-KPD'

    unos_data       = dict()

    with open(globs['unos_file_sans_MP_cPRA'], mode='r') as infile:
        reader = csv.DictReader(infile)
        unos_fieldnames = reader.fieldnames
        for row in reader:
            ID = row['extended_id']
            unos_data[ID] = row

    # Calculate Match Power and PRA

    pra = PRA()
    i=0
    denom=str(len(unos_data.keys()))
    for ID in unos_data.keys():
        if   ID[0]=='D':
            #print ID
            unos_data[ID] = isComp.donorMP(    unos_data[ID],recipient_pool,mp_fieldnames)
            #print unos_data[ID]['strict_noabo']
        elif ID[0]=='R':
            unos_data[ID] = isComp.recipientMP(unos_data[ID],donor_pool,    mp_fieldnames)

            # Calculate cPRA for patients
            params = {
             'anti_a'  : filter(bool,unos_data[ID]['antia'  ].split('|')),
             'anti_b'  : filter(bool,unos_data[ID]['antib'  ].split('|')),
             'anti_dqb': filter(bool,unos_data[ID]['antidqb'].split('|')),
             'anti_dr' : filter(bool,unos_data[ID]['antidr' ].split('|'))
            }
            personel = Personel(**params)
            unos_data[ID]['cpra'] = pra.calculate(personel)
    # Rename fields
        for field in mp_fieldnames:
            unos_data[ID]['mp_' + field] = unos_data[ID][field]
        i+=1
        if i%100==0:
            sys.stdout.write('\r'+str(i)+'/'+denom)
            sys.stdout.flush()
    sys.stdout.write('\r'+denom+'/'+denom+'\n')
    sys.stdout.flush()

    with open(globs['unos_pra_mp'],'w') as csvfile:
        headers = ['cpra','mp_weak',  'mp_weak_noabo','mp_strict','mp_strict_noabo']
        csvfile.write('extended_id,')
        csvfile.write(','.join(headers))
        csvfile.write('\n')
        for ID in unos_data.keys():
            csvfile.write(ID)
            for h in headers:
                csvfile.write(',')
                if h in unos_data[ID].keys():
                    csvfile.write(str(unos_data[ID][h]))
            csvfile.write('\n')


#############
# APD

if "APD" in sys.argv:

    print 'Calculating Match Power and PRA for APD'

    apd_data       = dict()

    with open(globs['apd_file_sans_MP_cPRA'], mode='r') as infile:
        reader = csv.DictReader(infile)
        apd_fieldnames = reader.fieldnames
        for row in reader:
            ID = row['idx']
            apd_data[ID] = row

    # Calculate Match Power and PRA

    pra = PRA()
    i=0
    denom=str(len(apd_data.keys()))
    for ID in apd_data.keys():
        if   ID[0]=='D':
            apd_data[ID] = isComp.donorMP(    apd_data[ID],recipient_pool,mp_fieldnames)
        elif ID[0]=='R':
            apd_data[ID] = isComp.recipientMP(apd_data[ID],donor_pool,    mp_fieldnames)

            # Calculate cPRA for patients
            params = {
             'anti_a'  : filter(bool,apd_data[ID]['antia'  ].split('|')),
             'anti_b'  : filter(bool,apd_data[ID]['antib'  ].split('|')),
             'anti_dqb': filter(bool,apd_data[ID]['antidqb'].split('|')),
             'anti_dr' : filter(bool,apd_data[ID]['antidr' ].split('|'))
            }
            personel = Personel(**params)
            apd_data[ID]['cpra_new'] = pra.calculate(personel)
        # Rename fields
        for field in mp_fieldnames:
            apd_data[ID]['mp_' + field] = apd_data[ID][field]
        i+=1
        if i%100==0:
            sys.stdout.write('\r'+str(i)+'/'+denom)
            sys.stdout.flush()
    sys.stdout.write('\r'+denom+'/'+denom+'\n')
    sys.stdout.flush()

    with open(globs['apd_pra_mp'],'w') as csvfile:
        headers = ['cpra','mp_weak',  'mp_weak_noabo','mp_strict','mp_strict_noabo']
        csvfile.write('idx,')
        csvfile.write(','.join(headers))
        csvfile.write('\n')
        for ID in apd_data.keys():
            csvfile.write(ID)
            for h in headers:
                csvfile.write(',')
                if h in apd_data[ID].keys():
                    csvfile.write(str(apd_data[ID][h]))
            csvfile.write('\n')

#######
# STAR

if "STAR" in sys.argv:

    print 'Calculating Match Power and PRA for STAR'
    star_data = dict()

    with open(globs['star_histo'], mode='r') as infile:
        reader = csv.DictReader(infile)
        for row in reader:
            star_data[row['wl_id_code']] = row

    # Calculate Match Power and PRA

    pra = PRA()
    i=0
    denom=str(len(star_data.keys()))

    for ID in star_data.keys():
        # Calculate cPRA for patients
        params = {
         'anti_a'  : filter(bool,star_data[ID]['locusa' ].split('|')),
         'anti_b'  : filter(bool,star_data[ID]['locusb' ].split('|')),
         'anti_dqb': filter(bool,star_data[ID]['locusdq'].split('|')),
         'anti_dr' : filter(bool,star_data[ID]['locusdr'].split('|'))
        }
        personel = Personel(**params)
        star_data[ID]['cpra'] = pra.calculate(personel)
        # Calculate MP for both donor and recipient
        donor     = {   'antia'     : star_data[ID]['locusa'],
                        'antib'     : star_data[ID]['locusb'],
                        'antidr'    : star_data[ID]['locusdr'],
                        'bloodtype' : star_data[ID]['abo']
                    }
        recipient = {   'a1'        : star_data[ID]['da1'],
                        'a2'        : star_data[ID]['da2'],
                        'b1'        : star_data[ID]['db1'],
                        'b2'        : star_data[ID]['db2'],
                        'dr1'       : star_data[ID]['ddr1'],
                        'dr2'       : star_data[ID]['ddr2'],
                        'bloodtype' : star_data[ID]['abo_don']
                    }

        recipient = isComp.recipientMP(recipient,donor_pool,mp_fieldnames)
        for f in mp_fieldnames:
            star_data[ID]['mp_'+f]=recipient[f]

        if recipient['bloodtype']!='':
            donor = isComp.donorMP(donor,recipient_pool,mp_fieldnames)
            for f in mp_fieldnames:
                star_data[ID]['mp_'+f+'_don']=donor[f]
        
        i+=1
        if i%100==0:
            sys.stdout.write('\r'+str(i)+'/'+denom)
            sys.stdout.flush()
    sys.stdout.write('\r'+denom+'/'+denom+'\n')
    sys.stdout.flush()

    # Write STAR PRAs file

    with open(globs['star_pra_mp'],'w') as csvfile:
        headers = ['cpra','mp_weak',  'mp_weak_noabo','mp_strict','mp_strict_noabo']
        csvfile.write('wl_id_code,')
        csvfile.write(','.join(headers))
        csvfile.write('\n')
        for ID in star_data.keys():
            csvfile.write(ID)
            for h in headers:
                csvfile.write(',')
                if h in star_data[ID].keys():
                    csvfile.write(str(star_data[ID][h]))
            csvfile.write('\n')

            



