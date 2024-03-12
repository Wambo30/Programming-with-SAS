/*
Wahid Far, Okhtay 870485
Muhammet Can, Öz 876287
Bieber, Okan 874666	
*/



/***************	Aufgabe a)	  *****************/
DATA gruppeA;
	DO i=1 TO 25;
		Gruppe='A';
		alter=ROUND(RAND('Normal',27,5));
		OUTPUT;
	END;
	KEEP alter Gruppe i;
RUN;

DATA gruppeB;
	DO i=26 TO 50;
		Gruppe='B';
		alter=ROUND(RAND('Normal',30,5));
		OUTPUT;
	END;
	KEEP alter Gruppe i;
RUN;

PROC SQL;
	CREATE TABLE beideGruppen AS
		SELECT *
		FROM gruppeA
		
		OUTER UNION CORR
		
		SELECT * 
		FROM gruppeB
		;
QUIT;

/***************	Aufgabe b)	  *****************/
*erster t-Test des Projekts.
 die Daten sind hier ;
PROC TTEST DATA=WORK.BEIDEGRUPPEN SIDES=2 PLOTS=none  ;
	CLASS Gruppe;
	VAR alter;
RUN;
/***************	Aufgabe c)	  *****************/
DATA zufallZahlen;
	CALL STREAMINIT(5557);
	DO i=1 TO 50;
		x=RAND('UNIFORM');
		OUTPUT;
	END;
RUN;

PROC SQL;
	CREATE TABLE sortieren AS 
	SELECT * FROM work.beidegruppen AS l
	FULL JOIN zufallzahlen AS r
			ON l.i=r.i
	ORDER BY x ;
QUIT;

DATA zaehler;
	DO j=1 TO 50;
		OUTPUT;
	END;
RUN;

*Zählervariable für die Makroschleife;
DATA sortiert;
	MERGE work.sortieren zaehler;
	DROP i;
RUN;

/* in 1er schritten auf missing setzen*/
%MACRO test();
	%DO i=1 %TO 25;
		
		*Hier wird auf Missing gesetzt;
		DATA plot_sortiertTTest&i;
			SET sortiert;
			DO laufVar=0 TO &i.;
				IF j < laufVar THEN alter =.;
			END;
			DROP laufVar j;
		RUN;
		
		**ods trace on;
		
		*t-Test;
		ODS OUTPUT ConfLimits=KIntervall;
		ODS OUTPUT TTests=p_wert;
		PROC TTEST DATA=plot_sortiertTTest&i  SIDES=2 PLOTS=none ;
			CLASS Gruppe;
			VAR alter;
		RUN;
		
		
		*In diesem SQL Block werden dem t-Test die informationen entnommen;
		PROC SQL;
				CREATE TABLE plot_011 AS
				SELECT Mean AS MeanA, LowerCLMean AS LCLA, 	UpperCLMean AS UCLA ,variable   
				FROM KIntervall As a
				WHERE Class='A';
				
				CREATE TABLE plot_022 AS
				SELECT Mean AS MeanB, LowerCLMean AS LCLB, 	UpperCLMean AS UCLB ,variable 
				FROM KIntervall AS b
				WHERE Class='B';
				
				CREATE TABLE plot_033 AS
				SELECT Mean AS MeanDiff, variable 
				FROM KIntervall 
				WHERE Variances='Gleich';
				
				CREATE TABLE plot_011_022 AS
				SELECT *  
				FROM plot_011 AS a
				LEFT JOIN plot_022 AS b ON a.variable=b.variable;
				
				CREATE TABLE plot_all AS
				SELECT *  
				FROM plot_011_022 
				AS c
				LEFT JOIN plot_033 AS d ON c.variable=d.variable;
				
				CREATE TABLE p_wert_plot AS 
				SELECT Probt AS p, variable FROM p_wert;
				
				CREATE TABLE komplett_plot AS 
				SELECT * FROM plot_all AS e
				LEFT JOIN p_wert_plot AS f ON e.variable=f.variable;
		QUIT;
		
		*endtabelle damit nur eine zeile;
		DATA test;
			x=1; OUTPUT;
			x=2; OUTPUT;
		RUN;
	
		DATA blabla;
			MERGE  komplett_plot test;
		RUN;
		
		PROC SQL;
			CREATE TABLE end_daten&i AS 
			SELECT * FROM blabla WHERE x=1;
		QUIT;
		
	%END;
%MEND test;
%test();

*Alle relevanten Informationen 
werden in eine Tabelle übertragen;
DATA all;
	SET end_daten:;
	DROP x Variable;
RUN;	

DATA ident;
	DO id=1 TO 25;
		OUTPUT;
	END;
RUN;

*Alle Werte mit Zählervariable;
DATA all_id_zw;
	MERGE all ident;
RUN;


/***************	Aufgabe d)	  *****************/
PROC SGPLOT DATA=all_id_zw;

TITLE Mittelwerte mit Konfidenzintervall;

*Graphische Darstellung der p-Werte;
SERIES X=id Y=p / Y2AXIS MARKERS LINEATTRS=(THICKNESS = 2) COLORMODEL=black;

*Darstellung des Konfidenzintervalls Der Gruppe B;
SCATTER X=id Y=meanA /
YERRORLOWER=LCLA YERRORUPPER=UCLA ERRORBARATTRS=(COLOR=green THICKNESS = 1)
MARKERFILLATTRS=(COLOR= green)
MARKERATTRS=(COLOR=green SIZE=10 symbol=circlefilled);

*Darstellung des Konfidenzintervalls Der Gruppe B;
SCATTER X=id Y=meanB /
YERRORLOWER=LCLB YERRORUPPER=UCLB ERRORBARATTRS=(COLOR=red THICKNESS= 1)
MARKERFILLATTRS=(COLOR= red)
MARKERATTRS=(COLOR=red SIZE=10 symbol=circlefilled);

*Plot manipulation;
YAXIS LABEL= "ALTER";
XAXIS LABEL="OBS";
Y2AXIS LABEL="p-Werte";
REFLINE 0.05/ AXIS=y2;

RUN;

/***************	Aufgabe e)	  *****************/

*Konfidenzintervallzeile hinzufügen;
DATA all_id_e;
	SET all_id_zw;
	UCLDiff=UCLA-UCLB;
	LCLDiff=LCLA-LCLB;
RUN;

*eigentlicher Plot;
PROC SGPLOT DATA=all_id_e;
TITLE Differenz der Mittelwerte und Konfidenzintervall ;

*p-Werte plotten;
SERIES X=id Y=p / Y2AXIS MARKERS LINEATTRS=(THICKNESS = 2);	 

*Differenz der Durchschnitte;
SCATTER X=id Y=meanDiff /
YERRORLOWER=LCLDiff YERRORUPPER=UCLDiff ERRORBARATTRS=(COLOR=green THICKNESS = 1)
MARKERFILLATTRS=(COLOR= green)
MARKERATTRS=(COLOR=green SIZE=10 symbol=circlefilled);

*Plot manipulation;
YAXIS LABEL= "meanDiff";
REFLINE 0/ AXIS=y;
XAXIS LABEL="OBS";
Y2AXIS LABEL="p-Werte";
RUN;




