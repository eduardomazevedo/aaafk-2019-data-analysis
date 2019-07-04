# Compatibility dictionaries
# Fields should be a subset of abo, mp_strict, mp_weak, mp_strict_noabo, mp_weak_noabo
def recipientMP(recipient, donor_pool,fields):  
    # Inititalize
    for field in fields:
        recipient[field] = 0
    # Compute Compatibility
    for donor in donor_pool:
        compatible = isCompatible(recipient,donor,fields)
        for field in fields:
            recipient[field] += int(compatible[field])
    # Match Power
    for field in fields:
        recipient[field] = float(recipient[field])/float(len(donor_pool))
    return recipient

def donorMP(donor, recipient_pool,fields):
    # Inititalize
    for field in fields:
        donor[field] = 0
    # Compute Compatibility
    for recipient in recipient_pool:
        compatible = isCompatible(recipient,donor,fields)
        for field in fields:
            donor[field] += int(compatible[field])
    # Match Power
    for field in fields:
        donor[field] = float(donor[field])/float(len(recipient_pool))
    return donor

# Compatibility function
def isCompatible(recipient, donor,fields):  
    compatible = dict()
    compatible['bloodtype'] = isAboCompatible(recipient, donor)

    # Weak Compatibility
    tuples = [('a1',  'antia'),  
              ('a2',  'antia'),
              ('b1',  'antib'),
              ('b2',  'antib'),
              ('dr1', 'antidr'),
              ('dr2', 'antidr')]

    compatible['weak_noabo'] = isCompatiblenoAbo(recipient, donor,tuples)
    compatible['weak'] = compatible['bloodtype']*compatible['weak_noabo']
    # May not need to compute strict version
    if 'strict' in fields or 'strict_noabo' in fields:
        tuples = [('bw1', 'antibw'),
                  ('bw2', 'antibw'),
                  ('bw4', 'antibw4'),
                  ('Bw6', 'antibw6'),
                  ('cw1', 'anticw'),
                  ('cw2', 'antiCw'),
                  ('drw1', 'antidrw'),
                  ('drw2', 'antidrw'),
                  ('dpa1', 'antidpa'),
                  ('dpa2', 'antidpa'),
                  ('dqa1', 'antidqa'),
                  ('dqa2', 'antidqa'),
                  ('dqb1', 'antidqb'),
                  ('dqb2', 'antidqb'),
                  ('dr51', 'antidr51'),
                  ('dr52', 'antidr52'),
                  ('dr53', 'antidr53')] 

        compatible['strict_noabo'] = isCompatiblenoAbo(recipient, donor,tuples)
        compatible['strict_noabo'] = compatible['strict_noabo']*compatible['weak_noabo']
        compatible['strict'] = compatible['bloodtype']*compatible['strict_noabo']
    return compatible

# Compatibility of ABO
def isAboCompatible(recipient, donor):
    #print "DONOR"
    #print donor
    #print "RECIPIENT"
    #print recipient
    if donor['bloodtype'] == 'O':
        return 1
    if donor['bloodtype'] == 'A':        
        if recipient['bloodtype'] in ['A','AB']:
            return 1
    if donor['bloodtype'] == 'B':        
        if recipient['bloodtype'] in ['B','AB']:
            return 1
    if donor['bloodtype'] == 'AB' and recipient['bloodtype'] == 'AB':        
        return 1
    return 0

# Compatibility without abo, weak (only ABDR)
def isCompatiblenoAbo(recipient, donor,tuples):
    for (antigen, antibody) in tuples:
        if antigen in donor.keys() and antibody in recipient.keys():
            if (donor[antigen] in recipient[antibody].split('|')) and (donor[antigen]!=''):
                return 0

    return 1
