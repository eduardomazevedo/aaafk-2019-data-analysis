import csv
import os
import sys

with open("./intermediate-data/globals_for_py_code.csv") as globalfile:
    reader = csv.DictReader(globalfile)
    globs  = dict()
    for row in list(reader):
        globs[row['name']]=row['content']

print("Compiling unions of antibodies...")
antib_list = dict()
non_union_fields = ['abo','a1','a2','b1','b2','dr1','dr2','abo_don','da1','da2','db1','db2','ddr1','ddr2']
#with open("./intermediate-data/star-histo-pre-union.csv", mode='r') as infile:
with open(globs['star_histo_pre_union'], mode='r') as infile:
    reader = csv.DictReader(infile)
    union_fields = ['locusa','locusb','locusc','locusdq','locusdr','locusbw']
    i=0
    rows = list(reader)
    denom = str(len(rows))
    for row in rows:
        if row['wl_id_code'] not in antib_list.keys():
            antib_list[row['wl_id_code']]           = dict()
        for f in non_union_fields:
            antib_list[row['wl_id_code']][f]     = row[f]
        for f in union_fields:
            if f not in antib_list[row['wl_id_code']].keys():
                antib_list[row['wl_id_code']][f] = set()
            temp = [int(ant) for ant in set(row[f].strip().split(',')) if ant!='']
            antib_list[row['wl_id_code']][f] = antib_list[row['wl_id_code']][f].union(set(temp))
        i+=1
        if i%100==0:
            sys.stdout.write('\r'+str(i)+'/'+denom)
            sys.stdout.flush()
sys.stdout.write('\r'+denom+'/'+denom+'\n')
sys.stdout.flush()

print("Exporting unions to file...")
# Write csv
#with open('intermediate-data/star-histo-data.csv','w') as csvfile:
with open(globs['star_histo'],'w') as csvfile:
    csvfile.write('wl_id_code,'+",".join(non_union_fields)+','+','.join(union_fields)+'\n')
    for wlid in sorted([int(k) for k in antib_list.keys()]):    
        csvfile.write(str(wlid))
        for f in non_union_fields:
            csvfile.write(','+antib_list[str(wlid)][f])
        for f in union_fields:
            csvfile.write(','+'|'.join( [ str(ant) for ant in sorted(antib_list[str(wlid)][f]) ] ) )
        csvfile.write('\n')
