from util import parseInputData, tukey_all
import math


# --------------------------------------------------------------------------------
# Input-Dateiname:
input_filename = "rawData_merged.tsv"
# Output-Dateiname:
output_filename = "DIS.lst"

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
		if dataLine["disp.rt"]  != "":
			alleRTO.append(int(dataLine["disp.rt"]))
			VPrto.append(int(dataLine["disp.rt"]))
		if dataLine["diss.rt"]  != "":
			alleRTO.append(int(dataLine["diss.rt"]))
			VPrto.append(int(dataLine["diss.rt"]))
		
	(grenzenVP[vpNr], q1VP[vpNr], q3VP[vpNr]) = tukey_all(VPrto, grenze_type, vpNr)


print("-----------------------------------------------")
print("Werte über alle VPs ")
print("-----------------------------------------------")
grenze = tukey_all(alleRTO, grenze_type)
#print(grenze)

# -------------------------------------------------------------------------
# Werte in Datei schreiben
print("Subject Tukey_DIS liRTmean_DIS liACC_DIS liRTsum_DIS lfRTmean_DIS lfACC_DIS lfRTsum_DIS piRTmean_DIS piACC_DIS piRTsum_DIS pfRTmean_DIS pfACC_DIS pfRTsum_DIS siRTmean_DIS siACC_DIS siRTsum_DIS sfRTmean_DIS sfACC_DIS sfRTsum_DIS liER_DIS lfER_DIS piER_DIS pfER_DIS siER_DIS sfER_DIS", file = outputfile)
			
			
for vpNr in sorted(inputdata.keys()):
	print(vpNr, end = " " , file = outputfile)
	print(grenzenVP[vpNr], end = " " , file = outputfile)

	#print(q1VP[vpNr], end = " " , file = outputfile)
	#print(q3VP[vpNr], end = " " , file = outputfile)

	#print(q3VP[vpNr])


#p = pair, l = label, s = shape
	li = []
	lf = []
	pi = []
	pf = []
	si = []
	sf = []
#cond = association (latin square)
	cond=0
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

		if dataLine["disp.rt"]  != "" and int(dataLine["disp.rt"]) > 200 and int(dataLine["disp.rt"]) < grenzenVP[vpNr] and dataLine["disp.acc"] == "1":
						
				if dataLine["targlocation"] == "ich":
					pi.append(int(dataLine["disp.rt"]))
					piart = (round(sum(pi) / len(pi)))					
				if dataLine["targlocation"] == "fremder" and dataLine["disp.acc"] == "1":
					pf.append(int(dataLine["disp.rt"]))
					pfart = (round(sum(pf) / len(pf)))

		if dataLine["diss.rt"]  != "" and int(dataLine["diss.rt"]) > 200 and int(dataLine["diss.rt"]) < grenzenVP[vpNr] and dataLine["diss.acc"] == "1":
						
				if dataLine["targlocation"] == "ich":
					si.append(int(dataLine["diss.rt"]))
					siart = (round(sum(si) / len(si)))
					
				if dataLine["targlocation"] == "fremder" and dataLine["diss.acc"] == "1":
					sf.append(int(dataLine["diss.rt"]))
					sfart = (round(sum(sf) / len(sf)))
					
		

	#print ((dataLine["condition"]), end = " ", file = outputfile)
	
	#if inputdata[vpNr][0]["sex"] == "female":
		#print("0", end = " ", file = outputfile)
	#else:
		#print("1", end = " ", file = outputfile)
	#print ((dataLine["handedness"]), end = " ", file = outputfile)
	print(liart, len(li), sum(li), file = outputfile, end = " " )
	print(lfart, len(lf), sum(lf), file = outputfile, end = " " )
	print(piart, len(pi), sum(pi), file = outputfile, end = " " )
	print(pfart, len(pf), sum(pf), file = outputfile, end = " " )
	print(siart, len(si), sum(si), file = outputfile, end = " " )
	print(sfart, len(sf), sum(sf), file = outputfile, end = " " )

	
	lie = 0
	lfe = 0
	pie = 0
	pfe = 0
	sie = 0
	sfe = 0

	for dataLine in inputdata[vpNr]:
		if dataLine["targlocation"] == "ich" and dataLine["disl.acc"] == "0":
			lie = lie+1
		if dataLine["targlocation"] == "fremder" and dataLine["disl.acc"] == "0":
			lfe = lfe+1
		if dataLine["targlocation"] == "ich" and dataLine["disp.acc"] == "0":
			pie = pie+1
		if dataLine["targlocation"] == "fremder" and dataLine["disp.acc"] == "0":
			pfe = pfe+1
		if dataLine["targlocation"] == "ich" and dataLine["diss.acc"] == "0":
			sie = sie+1
		if dataLine["targlocation"] == "fremder" and dataLine["diss.acc"] == "0":
			sfe = sfe+1
	
	print(lie, file = outputfile, end = " " )
	print(lfe, file = outputfile, end = " " )
	print(pie, file = outputfile, end = " " )
	print(pfe, file = outputfile, end = " " )
	print(sie, file = outputfile, end = " " )
	print(sfe, file = outputfile, end = " " )
	
	
	print("",file = outputfile)
	
	
	
outputfile.close()






