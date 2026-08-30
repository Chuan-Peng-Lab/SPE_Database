from util import parseInputData, tukey_all
import math


# --------------------------------------------------------------------------------
# Input-Dateiname:
input_filename = "wentura.tsv"
# Output-Dateiname:
output_filename = "wenturaDET.lst"

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
					
		if dataLine["detl.rt"]  != "":
			alleRTO.append(int(dataLine["detl.rt"]))
			VPrto.append(int(dataLine["detl.rt"]))
		if dataLine["detp.rt"]  != "":
			alleRTO.append(int(dataLine["detp.rt"]))
			VPrto.append(int(dataLine["detp.rt"]))
		if dataLine["dets.rt"]  != "":
			alleRTO.append(int(dataLine["dets.rt"]))
			VPrto.append(int(dataLine["dets.rt"]))
		
	(grenzenVP[vpNr], q1VP[vpNr], q3VP[vpNr]) = tukey_all(VPrto, grenze_type, vpNr)


print("-----------------------------------------------")
print("Werte über alle VPs ")
print("-----------------------------------------------")
grenze = tukey_all(alleRTO, grenze_type)
#print(grenze)

# -------------------------------------------------------------------------
# Werte in Datei schreiben
print("Subject Tukey_DET liRTmean_DET liACC_DET liRTsum_DET lfRTmean_DET lfACC_DET lfRTsum_DET piRTmean_DET piACC_DET piRTsum_DET pfRTmean_DET pfACC_DET pfRTsum_DET siRTmean_DET siACC_DET siRTsum_DET sfRTmean_DET sfACC_DET sfRTsum_DET liER_DET lfER_DET piER_DET pfER_DET siER_DET sfER_DET", file = outputfile)
			
			
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
		if dataLine["detl.rt"]  != "" and int(dataLine["detl.rt"]) > 200 and int(dataLine["detl.rt"]) < grenzenVP[vpNr] and dataLine["detl.acc"] == "1":
						
				if dataLine["targlocation"] == "ich":
					li.append(int(dataLine["detl.rt"]))
					liart = (round(sum(li) / len(li)))
				if dataLine["targlocation"] == "fremder":
					lf.append(int(dataLine["detl.rt"]))
					lfart = (round(sum(lf) / len(lf)))

		if dataLine["detp.rt"]  != "" and int(dataLine["detp.rt"]) > 200 and int(dataLine["detp.rt"]) < grenzenVP[vpNr] and dataLine["detp.acc"] == "1":
						
				if dataLine["targlocation"] == "ich":
					pi.append(int(dataLine["detp.rt"]))
					piart = (round(sum(pi) / len(pi)))					
				if dataLine["targlocation"] == "fremder" and dataLine["detp.acc"] == "1":
					pf.append(int(dataLine["detp.rt"]))
					pfart = (round(sum(pf) / len(pf)))

		if dataLine["dets.rt"]  != "" and int(dataLine["dets.rt"]) > 200 and int(dataLine["dets.rt"]) < grenzenVP[vpNr] and dataLine["dets.acc"] == "1":
						
				if dataLine["targlocation"] == "ich":
					si.append(int(dataLine["dets.rt"]))
					siart = (round(sum(si) / len(si)))
					
				if dataLine["targlocation"] == "fremder" and dataLine["dets.acc"] == "1":
					sf.append(int(dataLine["dets.rt"]))
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
		if dataLine["targlocation"] == "ich" and dataLine["detl.acc"] == "0":
			lie = lie+1
		if dataLine["targlocation"] == "fremder" and dataLine["detl.acc"] == "0":
			lfe = lfe+1
		if dataLine["targlocation"] == "ich" and dataLine["detp.acc"] == "0":
			pie = pie+1
		if dataLine["targlocation"] == "fremder" and dataLine["detp.acc"] == "0":
			pfe = pfe+1
		if dataLine["targlocation"] == "ich" and dataLine["dets.acc"] == "0":
			sie = sie+1
		if dataLine["targlocation"] == "fremder" and dataLine["dets.acc"] == "0":
			sfe = sfe+1
	
	print(lie, file = outputfile, end = " " )
	print(lfe, file = outputfile, end = " " )
	print(pie, file = outputfile, end = " " )
	print(pfe, file = outputfile, end = " " )
	print(sie, file = outputfile, end = " " )
	print(sfe, file = outputfile, end = " " )
	
	
	print("",file = outputfile)
	
	
	
outputfile.close()






