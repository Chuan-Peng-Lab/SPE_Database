from util import parseInputData, tukey_all
import math


# --------------------------------------------------------------------------------
# Input-Dateiname:
input_filename = "rawDataMerge.tsv"
# Output-Dateiname:
output_filename = "dotprobe_3.lst"

# Rückgabewert festlegen: eine Zeile festlegen , alle anderen Zeilen auskommentieren
#grenze_type = "grenze1_5_oben"
grenze_type = "grenze3_oben"
#grenze_type = "grenze1_5_unten"
#grenze_type = "grenze3_unten"
#
# --------------------------------------------------------------------------------


# -------------------------------------------------------------------------
# Werte einlesen
inputdata = parseInputData(input_filename)

# -------------------------------------------------------------------------
# Name der Ausgabedatei
outputfile = open(output_filename,"w")

alleRTO = []
grenzenVP = {}
q1VP = {}
q3VP = {}

print("-----------------------------------------------")
print("Werte pro VP ")
print("-----------------------------------------------")

for vpNr in inputdata:

	VPrto =[]

	for dataLine in inputdata[vpNr]:
					
		if dataLine["disl.rt"]  != "":
			alleRTO.append(int(dataLine["disl.rt"]))
			VPrto.append(int(dataLine["disl.rt"]))
		if dataLine["disw.rt"]  != "":
			alleRTO.append(int(dataLine["disw.rt"]))
			VPrto.append(int(dataLine["disw.rt"]))

		
	(grenzenVP[vpNr], q1VP[vpNr], q3VP[vpNr]) = tukey_all(VPrto, grenze_type, vpNr)


print("-----------------------------------------------")
print("Werte über alle VPs ")
print("-----------------------------------------------")
grenze = tukey_all(alleRTO, grenze_type)
#print(grenze)

# -------------------------------------------------------------------------
# Werte in Datei schreiben
print("Subject Tukey_DOT liRTmean_DOT liACC_DOT liRTsum_DOT lfRTmean_DOT lfACC_DOT lfRTsum_DOT niRTmean_DOT niACC_DOT niRTsum_DOT nfRTmean_DOT nfACC_DOT nfRTsum_DOT liER_DOT lfER_DOT niER_DOT nfER_DOT", file = outputfile)
			
			
for vpNr in sorted(inputdata.keys()):
	print(vpNr, end = " " , file = outputfile)
	print(grenzenVP[vpNr], end = " " , file = outputfile)

	#print(q1VP[vpNr], end = " " , file = outputfile)
	#print(q3VP[vpNr], end = " " , file = outputfile)

	#print(q3VP[vpNr])


#l = label, n = nonword
	li = []
	lf = []
	ni = []
	nf = []
#cond = association (latin square)
	#cond=0
	#sex=0
	#cond=0
	
	for dataLine in inputdata[vpNr]:
		
		#TVP:
		if dataLine["disl.rt"]  != "" and int(dataLine["disl.rt"]) > 200 and int(dataLine["disl.rt"]) < grenzenVP[vpNr] and dataLine["disl.acc"] == "1":
						
				if dataLine["targlocation"] == "ich":
					li.append(int(dataLine["disl.rt"]))
					liart = (round(sum(li) / len(li)))
				if dataLine["targlocation"] == "fremder":
					lf.append(int(dataLine["disl.rt"]))
					lfart = (round(sum(lf) / len(lf)))

		if dataLine["disw.rt"]  != "" and int(dataLine["disw.rt"]) > 200 and int(dataLine["disw.rt"]) < grenzenVP[vpNr] and dataLine["disw.acc"] == "1":
						
				if dataLine["targlocation"] == "ich":
					ni.append(int(dataLine["disw.rt"]))
					niart = (round(sum(ni) / len(ni)))					
				if dataLine["targlocation"] == "fremder" and dataLine["disw.acc"] == "1":
					nf.append(int(dataLine["disw.rt"]))
					nfart = (round(sum(nf) / len(nf)))


		

	#print ((dataLine["condition"]), end = " ", file = outputfile)
	
	#if inputdata[vpNr][0]["sex"] == "female":
		#print("0", end = " ", file = outputfile)
	#else:
		#print("1", end = " ", file = outputfile)
	#print ((dataLine["handedness"]), end = " ", file = outputfile)

	print(liart, len(li), sum(li), file = outputfile, end = " " )
	print(lfart, len(lf), sum(lf), file = outputfile, end = " " )
	print(niart, len(ni), sum(ni), file = outputfile, end = " " )
	print(nfart, len(nf), sum(nf), file = outputfile, end = " " )

	
	lie = 0
	lfe = 0
	nie = 0
	nfe = 0


	for dataLine in inputdata[vpNr]:
		if dataLine["targlocation"] == "ich" and dataLine["disl.acc"] == "0":
			lie = lie+1
		if dataLine["targlocation"] == "fremder" and dataLine["disl.acc"] == "0":
			lfe = lfe+1
		if dataLine["targlocation"] == "ich" and dataLine["disw.acc"] == "0":
			nie = nie+1
		if dataLine["targlocation"] == "fremder" and dataLine["disw.acc"] == "0":
			nfe = nfe+1

	
	print(lie, file = outputfile, end = " " )
	print(lfe, file = outputfile, end = " " )
	print(nie, file = outputfile, end = " " )
	print(nfe, file = outputfile, end = " " )
	
	
	print("",file = outputfile)
	
	
	
outputfile.close()






