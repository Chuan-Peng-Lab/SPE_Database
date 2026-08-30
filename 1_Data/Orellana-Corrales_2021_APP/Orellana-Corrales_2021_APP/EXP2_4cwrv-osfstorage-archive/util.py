# --------------------------------------------------------------------------------
# util.py
#
# Historie:
# V0.3 11.02.2016 J.Paulus 
# Funktion mit Parameter zur Auswahl des Rückgabewertes
#
# V0.4 15.02.2016 J.Paulus
# Ausgabe in Datei/Fenster angepasst
#
# V0.5 16.02.2016 J.Paulus
# q3: falls ohne Nachkomma: diese Zahl nehmen und nicht aufrunden
#
# V0.6 22.02.2016 J.Paulus
# split-Funktion entfernte auch tabs am Ende einer Zeile
#  -> jetzt nur noch CR
#
# V0.7 03.03.2016 J-Paulus
# Funktion <parseInputData>
#     Neuer Parameter: Spaltenname Messvariable
#            ist diese <NULL> wird die Zeile nicht übernommen
#     Leerzeichen vor und hinter einem Wert werden gelöscht
#
# Neue Funktionen <setOutputFile>, <filePrint_value>, <filePrint_line>
#
# --------------------------------------------------------------------------------

import math

outputfile = ""

def tukey_all(alleRTO, return_val, vpNr=0):

	#print("tukey_all start -----------------")
	if vpNr != 0:
                print ("subject:", vpNr)
	# print (" return_val:", return_val)

	alleRTO.sort()
	#print(alleRTO)

	anzahl = len(alleRTO)
	print (" TrialCount:", anzahl)
	median = 0
	if anzahl%2 == 0:
		print (" ist gerade")
		median = ((anzahl/2)+(anzahl+1)/2)/2

	else:
		print (" ist ungerade")
		median = (anzahl+1) / 2

	print (" median:", median)
	
	hinge = (median+1)/2
	print (" hinge:", hinge)
	
	if hinge == int(hinge): # ohne nachkomma
		print(" ohne nachkomma")
		q1 = alleRTO[int(hinge)-1]
		q3 = alleRTO[anzahl - int(hinge)]
	else:
		print(" mit nachkomma")
		q1 = (alleRTO[int(hinge)-1] + alleRTO[int(hinge)])/2
		q3 = (alleRTO[anzahl - int(hinge)-1] + alleRTO[anzahl - int(hinge)])/2

	q1 = math.floor(q1) # immer abrunden
	q3 = math.ceil(q3) # immer aufrunden
	
	print (" q1:", q1)
	print (" q3:", q3)

	IQR = q3 - q1
	grenze1_5_oben = q3 + 1.5*IQR
	grenze3_oben = q3 + 3*IQR
	grenze1_5_unten = q1 - 1.5*IQR
	grenze3_unten = q1 - 3*IQR

	grenze = -1 
	if return_val == "IQR":
		grenze = IQR
		
	if return_val == "grenze1_5_oben":
		grenze = grenze1_5_oben
		
	if return_val == "grenze3_oben":
		grenze = grenze3_oben
		
	if return_val == "grenze1_5_unten":
		grenze = grenze1_5_unten
		
	if return_val == "grenze3_unten":
		grenze = grenze3_unten
	
	if return_val != "IQR":
		print (" IQR", ":", IQR)
	print ("", return_val, ":", grenze)
	#print("tukey_all  end -----------------")
	print(" ")
	return (grenze, q1, q3)



# Datei einlesen
def parseInputData(path, notNULLkey="", indexField="subject"):
	resultData = {}
	with open(path) as file:
		header = file.readline()
		header = header.strip()
		headerParts = header.split("\t")
		for line in file:
			parts = (line.strip('\n')).split("\t")
			i=0 # leerzeichen trimmen
			for str in parts: 
                                parts[i] = str.strip(' ')
                                i=i+1
			namedParts = {key.lower():value for key, value in zip(headerParts, parts)}
			if int(namedParts[indexField]) not in resultData:
				resultData[int(namedParts[indexField])] = []
			appendLine = True
			if notNULLkey != "":
				if namedParts[notNULLkey] == "NULL":
					 appendLine = False
			if appendLine == True:
                                resultData[int(namedParts[indexField])].append(namedParts)
	return resultData

        
# Datei zum Schreiben öffnen
def openOutputFile(output_filename):
        global outputfile
        outputfile = open(output_filename,"w")

# Datei schließen
def closeOutputFile():
        outputfile.close()

# Wert(e) in Datei schreiben
# ein Leerzeichen wird eingefügt
def filePrint_value(*val):
        replace_dot = True # (Dezimal)Punkt wird durch ein Komma ersetzt
        for part in val:
                print(str(part).replace('.',',') if replace_dot == True else part, end = " " , file = outputfile)
        
# Zeile in Datei schreiben
def filePrint_line(line):
        print(line, file = outputfile)


# =================================================================================
# test (Joachim Paulus)
#
def test_jp():
	#liste = [1,2,3,4,5,6,7,8,9,10]
	liste = [51,51,56,57,62,62,73,74,89,93]
	print (liste)
	tukey_all(liste, "IQR")
	tukey_all(liste, "grenze1_5_oben")
	tukey_all(liste, "grenze3_oben")
	tukey_all(liste, "grenze1_5_unten")
	tukey_all(liste, "grenze3_unten")

#test_jp()

# test_ende
# =================================================================================





