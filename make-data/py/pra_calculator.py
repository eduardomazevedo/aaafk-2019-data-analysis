#!/usr/bin/python
#-*- coding: utf-8 -*-

# Imports =====================================================================

import csv
from utils import MultiDimList

# PRA Class ===================================================================

class PRA(object):

    A = 1
    B = 2
    DR = 3
    DQ = 4

    BW4 = 949494
    BW6 = 969696

    antigens = {
        'A': 1,
        'B': 2,
        'DR': 3,
        'DQ': 4
    }

    # -------------------------------------------------------------------------

    def __init__(self):
        self.frequencies = {}
        self.equivalences = {}

        frequency = {
            'A': {
                'filename': "raw-files/PRAcalculation/CPRA_current_frequenciesA.csv",
                'array': MultiDimList((85, 4)),
                'antigen': 'A',
                'types': [self.A]
            },
            'B': {
                'filename': "raw-files/PRAcalculation/CPRA_current_frequenciesB.csv",
                'array': MultiDimList((85, 4)),
                'antigen': 'B',
                'types': [self.B]
            },
            'DR': {
                'filename': "raw-files/PRAcalculation/CPRA_current_frequenciesDR.csv",
                'array': MultiDimList((20, 4)),
                'antigen': 'DR',
                'types': [self.DR]
            },
            'DQ': {
                'filename': "raw-files/PRAcalculation/CPRA_current_frequenciesDQ.csv",
                'array': MultiDimList((10, 4)),
                'antigen': 'DQ',
                'types': [self.DQ]
            },
            'AB': {
                'filename': "raw-files/PRAcalculation/CPRA_current_frequenciesAB.csv",
                'array': MultiDimList((85, 85, 4)),
                'antigen': 'A',
                'types': [self.A, self.B]
            },
            'ADR': {
                'filename': "raw-files/PRAcalculation/CPRA_current_frequenciesADR.csv",
                'array': MultiDimList((85, 20, 4)),
                'antigen': 'A',
                'types': [self.A, self.DR]
            },
            'ADQ': {
                'filename': "raw-files/PRAcalculation/CPRA_current_frequenciesADQ.csv",
                'array': MultiDimList((85, 10, 4)),
                'antigen': 'A',
                'types': [self.A, self.DQ],
            },
            'BDR': {
                'filename': "raw-files/PRAcalculation/CPRA_current_frequenciesBDR.csv",
                'array': MultiDimList((85, 20, 4)),
                'antigen': 'B',
                'types': [self.B, self.DR]
            },
            'BDQ': {
                'filename': "raw-files/PRAcalculation/CPRA_current_frequenciesBDQ.csv",
                'array': MultiDimList((85, 10, 4)),
                'antigen': 'B',
                'types': [self.B, self.DQ]
            },
            'DRDQ': {
                'filename': "raw-files/PRAcalculation/CPRA_current_frequenciesDRDQ.csv",
                'array': MultiDimList((85, 85, 4)),
                'antigen': 'D',
                'types': [self.DR, self.DQ]
            },
            'ABDR': {
                'filename': "raw-files/PRAcalculation/CPRA_current_frequenciesABDR.csv",
                'array': MultiDimList((85, 85, 20, 4)),
                'antigen': 'A',
                'types': [self.A, self.B, self.DR]
            },
            'ABDQ': {
                'filename': "raw-files/PRAcalculation/CPRA_current_frequenciesABDQ.csv",
                'array': MultiDimList((85, 85, 10, 4)),
                'antigen': 'A',
                'types': [self.A, self.B, self.DQ]
            },
            'ADRDQ': {
                'filename': "raw-files/PRAcalculation/CPRA_current_frequenciesADRDQ.csv",
                'array': MultiDimList((85, 20, 10, 4)),
                'antigen': 'A',
                'types': [self.A, self.DR, self.DQ]
            },
            'BDRDQ': {
                'filename': "raw-files/PRAcalculation/CPRA_current_frequenciesBDRDQ.csv",
                'array': MultiDimList((85, 20, 10, 4)),
                'antigen': 'B',
                'types': [self.B, self.DR, self.DQ]
            },
            'ABDRDQ': {
                'filename': "raw-files/PRAcalculation/CPRA_current_frequenciesABDRDQ.csv",
                'array': MultiDimList((85, 85, 20, 10, 4)),
                'antigen': 'A',
                'types': [self.A, self.B, self.DR, self.DQ]
            }
        }

        for combination, kwargs in frequency.iteritems():
            self.load_frequency_file(
                kwargs['filename'],
                kwargs['array'],
                kwargs['antigen'],
                kwargs['types']
            )
            self.frequencies[combination] = kwargs['array']
            
        self.init_equivalences()

    # -------------------------------------------------------------------------

    def init_equivalences(self):
        equivalences_files = {
            'A': 'raw-files/PRAcalculation/Aequivalent.csv',
            'B': 'raw-files/PRAcalculation/Bequivalent.csv',
            'DR': 'raw-files/PRAcalculation/DRequivalent.csv',
            'DQ': 'raw-files/PRAcalculation/DQequivalent.csv'
        }
        for antibody, filename in equivalences_files.iteritems():
            data = self.load_equivalence_file(filename)
            self.equivalences.update({self.antigens[antibody]: data})

    # -------------------------------------------------------------------------

    def equivalent(self, antibodies, antigen):
        antilist = antibodies
        for antibody in antibodies:
            index = self.get_equivalence_index(antibody, antigen)
            if index:
                for antigen in self.equivalences[antigen][index].equivalences:
                    if antigen not in antilist:
                        antilist.append(antigen)

        return antilist

    # -------------------------------------------------------------------------

    def equivalentof(self, antibodies, antigen, antibody):
        antilist = antibodies
        index = self.get_equivalence_index(antigen, antibody)
        if index:
            for antigen in self.equivalences[antigen][index].equivalences:
                if antigen not in antilist:
                    antilist.append(antigen)

        return antilist

    # -------------------------------------------------------------------------

    def get_equivalence_index(self, antibody, antigen):
        for index, equivalence in enumerate(self.equivalences[antibody]):
            if equivalence.main == int(antigen):
                return index

        return -1

    # -------------------------------------------------------------------------

    def calculate(self, m_antiA, m_antiB, m_antiDR,m_antiDQb):
        S1 = [0.0] * 4
        S2 = [0.0] * 4
        S3 = [0.0] * 4
        S4 = [0.0] * 4

        if m_antiA:
            for a in xrange(len(m_antiA)):
                typeA =  self.get_equivalence_index(self.A, m_antiA[a])
                if typeA > 20:
                   continue
                for j in xrange(4):
					S1[j] += self.frequencies['A'][typeA, j]

                if m_antiDQb:
                    for dq in xrange(len(m_antiDQb)):
                        typeDQ = self.get_equivalence_index(self.DQ, m_antiDQb[dq])
                        if typeDQ > 10:
                            continue
                        for j in xrange(4):
                            S2[j] += self.frequencies['ADQ'][typeA, typeDQ, j]

                if m_antiDR:
                    for dr in xrange(len(m_antiDR)):
                        typeDR =  self.get_equivalence_index(self.DR, m_antiDR[dr])
                        if typeDR > 20:
                            continue
                        for j in xrange(4):
                            S2[j] +=  self.frequencies['ADR'][typeA, typeDR, j]
                        if m_antiDQb:
                            for dq in xrange(len(m_antiDQb)):
                                typeDQ = self.get_equivalence_index(self.DQ, m_antiDQb[dq])
                                if typeDQ > 10:
                                    continue
                                for j in xrange(4):
                                    S3[j] +=  self.frequencies['ADRDQ'][typeA, typeDR, typeDQ, j]

                if m_antiB:
                    for b in xrange(len(m_antiB)):
                        typeB = self.get_equivalence_index(self.B, m_antiB[b])
                        if typeB > 85:
                            continue
                        for j in xrange(4):
                            S2[j] +=  self.frequencies['AB'][typeA, typeB, j]

                        if m_antiDQb:
                            for dq in xrange(len(m_antiDQb)):
                                typeDQ = self.get_equivalence_index(self.DQ, m_antiDQb[dq])
                                if typeDQ > 10:
                                    continue
                                for j in xrange(4):
                                    S3[j] +=  self.frequencies['ABDQ'][typeA, typeB, typeDQ, j]

                        if m_antiDR:
                            for dr in xrange(len(m_antiDR)):
                                typeDR = self.get_equivalence_index(self.DR, m_antiDR[dr])
                                if typeDR > 20:
                                    continue
                                for j in xrange(4):
                                    S3[j] +=  self.frequencies['ABDR'][typeA, typeB, typeDR, j]
                                if m_antiDQb:
                                    for dq in xrange(len(m_antiDQb)):
                                        typeDQ = self.get_equivalence_index(self.DQ, m_antiDQb[dq])
                                        if typeDQ > 10:
                                            continue
                                        for j in xrange(4):
                                            S4[j] +=  self.frequencies['ABDRDQ'][typeA, typeB, typeDR, typeDQ, j]

        if m_antiB:
            for b in xrange(len(m_antiB)):
                typeB = self.get_equivalence_index(self.B, m_antiB[b])
                if typeB > 85:
                    continue
                for j in xrange(4):
                    S1[j] +=  self.frequencies['B'][typeB, j]

                if m_antiDQb:
                    for dq in xrange(len(m_antiDQb)):
                        typeDQ = self.get_equivalence_index(self.DQ, m_antiDQb[dq])
                        if typeDQ > 10:
                            continue
                        for j in xrange(4):
                            S2[j] +=  self.frequencies['BDQ'][typeB, typeDQ, j]

                if m_antiDR:
                    for dr in xrange(len(m_antiDR)):
                        typeDR = self.get_equivalence_index(self.DR, m_antiDR[dr])
                        if typeDR > 20:
                            continue
                        for j in xrange(4):
                            S2[j] +=  self.frequencies['BDR'][typeB, typeDR, j]
                        if m_antiDQb:
                            for dq in xrange(len(m_antiDQb)):
                                typeDQ = self.get_equivalence_index(self.DQ, m_antiDQb[dq])
                                if typeDQ > 10:
                                    continue
                                for j in xrange(4):
                                    S3[j] +=  self.frequencies['BDRDQ'][typeB, typeDR, typeDQ, j]

        if m_antiDR:
            for dr in xrange(len(m_antiDR)):
                typeDR = self.get_equivalence_index(self.DR, m_antiDR[dr])
                if typeDR > 20:
                    continue
                for j in xrange(4):
                    S1[j] +=  self.frequencies['DR'][typeDR, j]
                if m_antiDQb:
                    for dq in xrange(len(m_antiDQb)):
                        typeDQ = self.get_equivalence_index(self.DQ, m_antiDQb[dq])
                        if typeDQ > 10:
                            continue
                        for j in xrange(4):
                            S2[j] +=  self.frequencies['DRDQ'][typeDR, typeDQ, j]

        if m_antiDQb:
            for dq in xrange(len(m_antiDQb)):
                typeDQ = self.get_equivalence_index(self.DQ, m_antiDQb[dq])
                if typeDQ > 10:
                    continue
                for j in xrange(4):
                    S1[j] +=  self.frequencies['DQ'][typeDQ, j]

        calculated_pra = [0.0] * 4
        for i in xrange(4):
            calculated_pra[i] = 1 - S1[i] + S2[i] - S3[i] + S4[i]
            calculated_pra[i] = 1 - pow(calculated_pra[i], 2)

        #return calculated_pra
        return round(100 * (calculated_pra[0] * 0.689 + calculated_pra[1] * 0.146 + calculated_pra[2] * 0.142 + calculated_pra[3] * 0.023), 1)

    # -------------------------------------------------------------------------

    @classmethod
    def get_antigen_index(cls, antigen_type, number):
        if number < 0:
            return 0
        elif antigen_type == cls.antigens['B'] and number == 4005:
            return 83
        elif antigen_type == cls.antigens['DR'] and number == 103:
            return 19

        return number

    # -------------------------------------------------------------------------

    @classmethod
    def load_equivalence_file(cls, filename):
        equivalent = []
        with open(filename, "r") as ifile:
            reader = csv.reader(ifile)

            for row in reader:
                if row[0].startswith("Bw4"):
                    antigen = cls.BW4
                elif row[0].startswith("Bw6"):
                    antigen = cls.BW6
                else:
                    antigen = int(row[0])
                equivalence = Equivalence(antigen)
                if len(row) > 1:
                    for value in row[1:]:
                        equivalence.add(value, antigen)
                equivalent.append(equivalence)

        return equivalent

    # -------------------------------------------------------------------------

    @classmethod
    def load_frequency_file(cls, filename, array, antigen, types):
        with open(filename, "r") as ifile:
            reader = csv.reader(ifile)

            for row in reader:
                if row[0] == "111":
                    break

                if row[0].startswith(antigen):
                    continue

                antigens = []
                for i in xrange(len(types)):
                    antigen_index = cls.get_antigen_index(types[i], int(row[i]))
                    antigens.append(antigen_index)

                for j in xrange(4):
                    coordinates = antigens + [j]
                    array[coordinates] = float(row[j + len(antigens)])

    # -------------------------------------------------------------------------

    @staticmethod
    def weighted_pra(pra):
        return round(100 * (pra[0] * 0.689 + pra[1] * 0.146 + pra[2] * 0.142 + pra[3] * 0.023), 1)


# Equivalence Class ===========================================================

class Equivalence(object):

    # -------------------------------------------------------------------------

    def __init__(self, main):
        self.main = main
        self.equivalences = [main]

    # -------------------------------------------------------------------------

    def add(self, antibodies, main):
        if self.main != main:
            return

        antibody = -1
        for each in antibodies.split(','):
            if each.startswith("Bw4"):
                antibody = PRA.BW4
            elif each.startswith("Bw6"):
                antibody = PRA.BW6
            else:
                antibody = int(each)

            if antibody not in self.equivalences:
                self.equivalences.append(antibody)

	# -------------------------------------------------------------------------

	def __repr__(self):
		return "{main}: {equivalences}".format(
			main=self.main,
			equivalences=self.equivalences
		)

# END =========================================================================
