from util import parseInputData, tukey_all
import math


# --------------------------------------------------------------------------------
# Input-Dateiname:
input_filename = "rawDataMerge.tsv"
# Output-Dateiname:
output_filename = "matching_3.lst"

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
					
		if dataLine["mt.rt"]  != "":
			alleRTO.append(int(dataLine["mt.rt"]))
			VPrto.append(int(dataLine["mt.rt"]))
		
	(grenzenVP[vpNr], q1VP[vpNr], q3VP[vpNr]) = tukey_all(VPrto, grenze_type, vpNr)


print("-----------------------------------------------")
print("Werte über alle VPs ")
print("-----------------------------------------------")
grenze = tukey_all(alleRTO, grenze_type)
#print(grenze)

# -------------------------------------------------------------------------
# Werte in Datei schreiben
print("Subject Tukey_MT age sex handedness imRTmean imACC imRTsum fmRTmean fmACC fmRTsum inRTmean inACC inRTsum fnRTmean fnACC fnRTsum imER fmER inER fnER", file = outputfile)			
			
			
for vpNr in sorted(inputdata.keys()):
	print(vpNr, end = " " , file = outputfile)
	print(grenzenVP[vpNr], end = " " , file = outputfile)

	#print(q1VP[vpNr], end = " " , file = outputfile)
	#print(q3VP[vpNr], end = " " , file = outputfile)

	#print(q3VP[vpNr])


	mi = []
	ni = []
	mf = []
	nf = []
	
	
	for dataLine in inputdata[vpNr]:
		
		#TVP:
		if dataLine["mt.rt"]  != "" and int(dataLine["mt.rt"]) > 200 and int(dataLine["mt.rt"]) < grenzenVP[vpNr] and dataLine["mt.acc"] == "1":
						
				if dataLine["match"] == "match" and dataLine["label"] == "Ich":
					mi.append(int(dataLine["mt.rt"]))
					miart = (round(sum(mi) / len(mi)))
				if dataLine["match"] == "nonmatch" and dataLine["label"] == "Ich":
					ni.append(int(dataLine["mt.rt"]))
					niart = (round(sum(ni) / len(ni)))
				if dataLine["match"] == "match" and dataLine["label"] == "Fremder":
					mf.append(int(dataLine["mt.rt"]))
					mfart = (round(sum(mf) / len(mf)))
				if dataLine["match"] == "nonmatch" and dataLine["label"] == "Fremder":
					nf.append(int(dataLine["mt.rt"]))
					nfart = (round(sum(nf) / len(nf)))

					
		

	print ((dataLine["age"]), end = " ", file = outputfile)
	print ((dataLine["sex"]), end = " ", file = outputfile)
	print ((dataLine["handedness"]), end = " ", file = outputfile)
	
	print(miart, len(mi), sum(mi), file = outputfile, end = " " )
	print(mfart, len(mf), sum(mf), file = outputfile, end = " " )
	print(niart, len(ni), sum(ni), file = outputfile, end = " " )
	print(nfart, len(nf), sum(nf), file = outputfile, end = " " )
	
	mie = 0
	mfe = 0
	nie = 0
	nfe = 0

	for dataLine in inputdata[vpNr]:
		if dataLine["match"] == "match" and dataLine["label"] == "Ich" and dataLine["mt.acc"] == "0":
			mie = mie+1
		if dataLine["match"] == "match" and dataLine["label"] == "Fremder" and dataLine["mt.acc"] == "0":
			mfe = mfe+1
		if dataLine["match"] == "nonmatch" and dataLine["label"] == "Ich" and dataLine["mt.acc"] == "0":
			nie = nie+1
		if dataLine["match"] == "nonmatch" and dataLine["label"] == "Fremder" and dataLine["mt.acc"] == "0":
			nfe = nfe+1
	
	print(mie, file = outputfile, end = " " )
	print(mfe, file = outputfile, end = " " )
	print(nie, file = outputfile, end = " " )
	print(nfe, file = outputfile, end = " " )	
	
	print("",file = outputfile)
	
	
	
outputfile.close()





