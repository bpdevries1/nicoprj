generate-Typeperf-from-template.pl conf.tsv template-directory output-directory [looptag]
	Kopieert de bestanden in template-directory naar de output-directory
	regels die beginnen met 'LOOP: ' worden vervangen door een rij regels waarin variabelen worden vervangen door waarden uit conf.tsv
	De optie looptag is een reguliere expressie die regels markeert ter vervanging. Default = '^LOOP: '
	De namen in de eerste regel van conf.tsv worden gebruikt als variabelen.			

Stappen
	aanpassen generate-...
		- eerste regel: locatie van de Perl executable
	aanmaken van batch scripts
		- check per server:
			welke netdrives zijn beschikbaar
			wat is een geschikte directory om vanuit te werken
		- vul tsv in
			zie als voorbeeld Connect-servers.tsv
		- generate...
		- voeg pskill toe aan de output-directory
	voorbereiding
		- cd output-directory
		- connect-drives
		- getcounters
		- selecteer counters uit counters-XXX en voeg toe aan typeperf-XXX.cf
			zie voorbeeld typeperf-BA13-0301.cf
		- install-mon
	uitvoering
		- start-mon [sample interval]
			optie bij startmon: sample interval, default 15
		- stop-mon
		- get-mon
