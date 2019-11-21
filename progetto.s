#Autori
#Pierpaolo DAngelo
.data

ascii: .space 256
fileMessaggio: .asciiz "messaggio.txt"
fileMessaggioC: .asciiz "messaggioCifrato.txt"
fileMessaggioD: .asciiz "messaggioDecifrato.txt"
fileChiave: .asciiz "chiave.txt"
chiave: .space 5
messaggio: .space 71680
output: .space 71680
.text

.globl main
main:
	addi $sp, $sp, -20
	sw $ra, 0($sp)			
	sw $s3, 4($sp)				#I registri $s3, $s4, $s6, $s7 vengono preservati dato che saranno utilizzati
	sw $s5, 8($sp)
	sw $s6, 12($sp)
	sw $s7, 16($sp)
#FILE INPUT
	# APRI FILE
	li $v0, 13
	la $a0, fileMessaggio
	li $a1, 0
	li $a2, 0
	syscall
	move $t6, $v0
	
	#LEGGI FILE
	li $v0, 14
	move $a0, $t6
	la $a1, messaggio
	li $a2, 71680
	syscall
	
	li $v0, 16
	move $a0, $t6
	syscall
#FILE CHIAVE	
	# APRI FILE
	li $v0, 13
	la $a0, fileChiave
	li $a1, 0
	li $a2, 0
	syscall
	move $t6, $v0
	
	#LEGGI FILE
	li $v0, 14
	move $a0, $t6
	la $a1, chiave
	li $a2, 4
	syscall
	
	li $v0, 16
	move $a0, $t6
	syscall

	li $s3, 0
	la $s5, messaggio
	la $s6, output
	la $s7, chiave
	la $t0, chiave

lunghezzaChiave:				#Viene calcolata la lunghezza della chiave 
	lb $t1, 0($t0)
	beqz $t1, inizioCod
	addi $t0, $t0, 1
	addi $s3, $s3, 1			#In $s3 e contenuta la lunghezza della chiave
	j lunghezzaChiave
	
#INIZIO FASE DI CODIFICA

loopCod:					
	addi $s7, $s7, 1		
	addi, $s3, $s3, -1		
	beqz $s3, salvaCod			#Quando il messaggio e stato codificato con tutti gli algoritmi della chiave si passa al salvataggio
inizioCod:						#su file
	lb $s4, 0($s7)
	move $a0, $s5
	move $a1, $s6
	
ca: 							#Scelta dell'algoritmo da applicare
	li $t0, 65
	bne $s4, $t0, cb
	jal codA
	j loopCod

cb:	li $t0, 66
	bne $s4, $t0, cc
	jal codB
	j loopCod

cc:	li $t0, 67
	bne $s4, $t0, cd
	jal codC
	j loopCod
	
cd:	li $t0, 68
	bne $s4, $t0, ce
	jal codD
	j loopCod

ce:
	jal codE                   #Vengono scambiati gli indirizzi contenuti in $s5 ed $s6, cosi da fare diventare l'ultimo output
	move $t0, $s5			   #dell'algoritmo di codifica E l'input del prossimo algoritmo di codifica.	
	move $t1, $s6
	move $s6, $t0
	move $s5, $t1
	
	move $a1, $s6
	move $t0, $a1
	
loopResetP:						#Riscritto con tutti 0 l'ultimo buffer utilizzato come input.
	lb $t1, 0($t0)
	beqz $t1, fineResetP
	sb $zero, 0($t0)
	addi $t0, $t0, 1
	j loopResetP
fineResetP:
	j loopCod
salvaCod:
	move $a1, $s5
	la $a0, fileMessaggioC
	jal write
invertChiave:					#Viene applicato l'algoritmo di codifica D alla chiave cosi da poter procedere
	la $s7, chiave              #alla decodifica.
	move $a0, $s7
	jal codD
	la $s7, chiave
	j inizioDec
loopDec:
	addi $s7, $s7, 1
	lb $s4, 0($s7)
	beqz $s4, salvaDec

inizioDec:						#Scelta dell'algoritmo da applicare
	lb $s4, 0($s7)
	move $a0, $s5
	move $a1, $s6
da: 
	li $t0, 65
	bne $s4, $t0, db
	jal decA
	j loopDec

db:	li $t0, 66
	bne $s4, $t0, dc
	jal decB
	j loopDec

dc:	li $t0, 67
	bne $s4, $t0, dd
	jal decC
	j loopDec
	
dd:	li $t0, 68
	bne $s4, $t0, de
	jal codD
	j loopDec
de:
	jal decE
	move $t0, $s5				#Vengono scambiati gli indirizzi contenuti in $s5 ed $s6, cosi da fare diventare l'ultimo output
	move $t1, $s6				#dell'algoritmo di decodifica E l'input del prossimo algoritmo di decodifica.
	move $s6, $t0
	move $s5, $t1
	move $a1, $s6
	move $t0, $a1
	
loopResetP1:					#Riscritto con tutti 0 l'ultimo buffer utilizzato come input.
	lb $t1, 0($t0)
	beqz $t1, fineResetP1
	sb $zero, 0($t0)
	addi $t0, $t0, 1
	j loopResetP1
fineResetP1:
	j loopDec
salvaDec:
	move $a1, $s5
	la $a0, fileMessaggioD

	jal write


	lw $ra, 0($sp)
	lw $s3, 4($sp)
	lw $s5, 8($sp)
	lw $s6, 12($sp)
	lw $s7, 16($sp)
	addi $sp, $sp, 20
	jr $ra
	syscall
#Write File
write:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	li $v0, 13
	li $a1, 1
	li $a2, 0
	
	syscall
	move $t1, $v0
	
	li $v0, 15
	move $a0, $t1
	move $a1, $s5
	li $a2, 71680
	syscall
#Close File
	li $v0, 16
	move $a0, $t1
	syscall
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
#CIFRARI, PER CODIFICA
#ALGORITMO A
codA:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	move $t1, $a0				#$t1 contiene l'indirizzo del buffer di input
loopA:
	li $t3, 256
	lbu $t2, 0($t1)
	addi $t2, $t2, 4			
	blt $t2, $t3, moduloA       #Se $t2 + 4 e piu grande di 256, allora ($t2+ 4) - 256
	sub $t2, $t2, $t3
moduloA:
	sb $t2, 0($t1)
	addi $t1, $t1, 1
	lbu $t2, 0($t1)
	bne $t2, $zero, loopA       #Controllo fine buffer
	
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
#ALGORITMO B
codB:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	move $t1, $a0				#$t1 contiene l'indirizzo del buffer di input
loopB:
	li $t3, 256
	lbu $t2, 0($t1)
	addi $t2, $t2, 4
	blt $t2, $t3, moduloB       #Se $t2 + 4 e piu grande di 256, allora ($t2+ 4) - 256
	sub $t2, $t2, $t3
moduloB:
	sb $t2, 0($t1)
	addi $t1, $t1, 1			#$t1 viene incrementato due volte cosi da applicare l'algoritmo solo ai caratteri in posizione pari
	lbu $t2, 0($t1)
	beq $t2, $zero, fineB      #Controllo fine buffer
	addi $t1, $t1, 1
	lbu $t2, 0($t1)
	beq $t2, $zero, fineB      #Controllo fine buffer
	j loopB
fineB:
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

#ALGORITMO C
codC:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	move $t1, $a0			#$t1 contiene l'indirizzo del buffer di input	
	addi $t1, $t1, 1		#Ci si sposta subito in posizione dipari
loopC:
	li $t3, 256
	lbu $t2, 0($t1)
	addi $t2, $t2, 4
	blt $t2, $t3, moduloC   #Se $t2 + 4 e piu grande di 256, allora ($t2+ 4) - 256
	blt $t2, $t3, moduloC   #Se $t2 + 4 e piu grande di 256, allora ($t2+ 4) - 256
	sub $t2, $t2, $t3
moduloC:
	sb $t2, 0($t1)
	addi $t1, $t1, 1		#$t1 viene incrementato due volte cosi da applicare l'algoritmo solo ai caratteri in posizione pari
	lbu $t2, 0($t1)
	beq $t2, $zero, fineC   #Controllo fine buffer
	addi $t1, $t1, 1
	lbu $t2, 0($t1)
	beq $t2, $zero, fineC   #Controllo fine buffer
	j loopC
fineC:
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

#ALGORITMO D

codD:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	li $t0, 0    			#Lunghezza array
	move $t1, $a0			#$t1 contiene l'indirizzo del buffer di input
	
lengloop:
	lbu $t2, 0($t1)
	beqz $t2, endleng       #Controllo fine buffer
	addi $t0, $t0, 1
	addi $t1, $t1, 1
	j lengloop
endleng:

	move $t2, $a0			#$t2 contiene l'indirizzo del buffer di input
	add $t2, $t2, $t0 
	addi $t2, $t2, -1		#$t2 viene spostato sull'ultimo carattere del buffer
	li $t3, 2
	div $t0, $t3			#La lunghezza del buffer viene divisa per due cosi da poter funzionare da contatore per il ciclo
	mflo $t0
	move $t1, $a0

	
loop:
	lbu $t3, 0($t1)			
	lbu $t4, 0($t2)
	sb $t3, 0($t2)			#I caratteri in posizione $t1 e $t2 vengono scambiati
	sb $t4, 0($t1)
	addi $t1, $t1, 1		
	addi $t2, $t2, -1
	addi $t0, $t0, -1		
	blez $t0, fineD         #Quando $t0 arrivera a 0, gli ultimi due caratteri saranno stati invertiti e quindi avremo ottenuto
	j loop                	#la stringa invertita
fineD:
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
#ALGORITMO E

codE:
	addi $sp, $sp, -12	
	sw $ra, 0($sp)		
	sw $s0, 4($sp)				#I registri $s0 ed $s1 vengono preservati dato che saranno utilizzati
	sw $s1, 8($sp)
	li $s0, 45
	li $s1, 32
	la $t0, ascii           
	move $t1, $a0
	move $t3, $a1
	li $t9, 0  					#t9 tiene conto della posizione del carattere analizzato.
	j loopE
fineRicerca:
	addi $t3, $t3, 1			#Incrementa di uno il contatore di output			
	sb $s1, 0($t3)				#Salva ' ' nella posizione corrente di output
	addi $t3, $t3, 1			#Incrementa di uno il contatore di output
	
comparso:
	addi $t1, $t1, 1			#Incrementa di uno il contatore di messaggio
	addi $t9, $t9, 1			#Incrementa di uno $t9

loopE:
	lbu $t4, 0($t1)				#Carica in $t4 valore corrente di messaggio(input)
	beqz $t4, fineE				#Controlla se l'array  e giunto al termine, in caso positivo conclude
	add $t0, $t0, $t4			#Porta ascii in posizione $t4
	lbu $t5, 0($t0)
	sub $t0, $t0, $t4			#Carica il valore corrente di ascii in $t5
	bnez $t5, comparso			#Se $t5  e diverso da 0 il carattere  e gia comparso quindi si passa al prossimo carattere 
	add $t0, $t0, $t4			
	sb $t4, 0($t0)				#Mettiamo $t4 in ascii per segnalare che  e comparso
	sub $t0, $t0, $t4			#Riporta Ascii in posizione originale
	sb $t4, 0($t3)				#Essendo quindi la sua prima apparizione salva il carattere in output
	addi $t3, $t3, 1			
	sb $s0, 0($t3)

	move $a2, $t3
	move $a1, $t9
	addi $sp, $sp, -16
	sw $t0, 0($sp)				#Tutti i registri che si intende riutilizzare dopo la procedura vengono salvati nello stack
	sw $t1, 4($sp)
	sw $t4, 8($sp)
	sw $t9, 12($sp)

	jal separatorePos

	move $t3, $v0
	lw $t0, 0($sp)
	lw $t1, 4($sp)
	lw $t4, 8($sp)
	lw $t9, 12($sp)
	addi $sp, $sp, 16
	
	move $t2, $t1				#Carica l'indirizzo di messaggio in $t2
	move $t8, $t9

search:							#Inizia a cercare caratteri uguali a quello appena comparso
	addi $t2, $t2, 1			
	addi $t8, $t8, 1
	lbu $t5, 0($t2)
	beqz $t5, fineRicerca
	bne $t4, $t5, search		#Se il carattere contenuto in $t4 e quello in $t5 sono diversi continua a cercare
	addi $t3, $t3, 1			#Incrementa il contatore di output
	sb $s0, 0($t3)				#Inserisce '-' in output

	move $a1, $t8
	move $a2, $t3

	addi $sp, $sp, -24
	sw $t0, 0($sp)				#Tutti i registri che si intende riutilizzare dopo la procedura vengono salvati nello stack
	sw $t1, 4($sp)
	sw $t4, 8($sp)
	sw $t9, 12($sp)
	sw $t2, 16($sp)
	sw $t8, 20($sp)

	jal separatorePos

	move $t3, $v0
	lw $t0, 0($sp)
	lw $t1, 4($sp)
	lw $t4, 8($sp)
	lw $t9, 12($sp)
	lw $t2, 16($sp)
	lw $t8, 20($sp)
	addi $sp, $sp, 24
	j search

fineE:
	li $t5, 0	
	li $t6, 0
	li $t7, 256
resetAscii:						#il buffer ascii viene sovrascritto con tutti 0 in caso di successivi utilizzi
	beq $t6, $t7, fineReset
	sb $t5, 0($t0)
	addi $t6, $t6, 1
	addi $t0, $t0, 1
	j resetAscii
fineReset:
	addi $t0, $t0, -256
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	addi $sp, $sp, 12
	jr $ra
	
separatorePos:
	move $t3, $a2				#In $t3 abbiamo l'indirizzo del buffer di output
	move $t7, $a1				#In $t7 abbiamo la posizione dell'occorrenza del carattere nel messaggio di input
	li $t6, 0					#Contatore delle cifre che compongono la posizione
prossimoNum:
	addi $t6, $t6, 1
	div $t7, $t7, 10			 
	mfhi $t7
	addi $sp, $sp, -4
	sb $t7, 0($sp)				#$t7%10 viene salvato nello stack
	mflo $t7					#$t7/10 viene salvato in $t7
	bnez $t7, prossimoNum
salvaNum:						#Le cifre ottenute precedentemente vengono salvate nell'array di output
	lbu $t7, 0($sp)
	addi $sp, $sp, 4
	addi $t7, $t7, 48			#Si somma 48 alla cifra per ottenere il codice ASCII corrispondente
	addi $t3, $t3, 1
	sb $t7, 0($t3)
	addi $t6, $t6, -1
	bnez $t6, salvaNum
	

	move $v0, $t3
	jr $ra
	
#CIFRARI, PER DECODIFICA

#ALGORITMO A
decA:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	move $t1, $a0				#$t1 contiene l'indirizzo del buffer di input
loopDecA:
	li $t3, 3
	lbu $t2, 0($t1)
	bgt $t2, $t3, moduloDecA	#Se $t2 < 4 allora $t2 + 256
	addi $t2, $t2, 256
moduloDecA:
	addi $t2, $t2, -4			# $t2 - 4
	sb $t2, 0($t1)
	addi $t1, $t1, 1
	lbu $t2, 0($t1)
	bne $t2, $zero, loopDecA	#Controllo fine buffer
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
#ALGORITMO B
decB:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	move $t1, $a0				#$t1 contiene l'indirizzo del buffer di input
loopDecB:
	li $t3, 3
	lbu $t2, 0($t1)
	bgt $t2, $t3, moduloDecB	#Se $t2 < 4 allora $t2 + 256
	addi $t2, $t2, 256
moduloDecB:
	addi $t2, $t2, -4			# $t2 - 4
	sb $t2, 0($t1)
	addi $t1, $t1, 1			#$t1 viene incrementato due volte cosi da applicare l'algoritmo solo ai caratteri in posizione pari
	lbu $t2, 0($t1)
	beq $t2, $zero, fineDecB	#Controllo fine buffer
	addi $t1, $t1, 1
	lbu $t2, 0($t1)
	beq $t2, $zero, fineDecB	#Controllo fine buffer
	j loopDecB
fineDecB:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

#ALGORITMO C
decC:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	move $t1, $a0				#$t1 contiene l'indirizzo del buffer di input
	addi $t1, $t1, 1			#Ci si sposta subito in posizione dipari
loopDecC:
	li $t3, 3
	lbu $t2, 0($t1)
	bgt $t2, $t3, moduloDecC	#Se $t2 < 4 allora $t2 + 256
	addi $t2, $t2, 256
moduloDecC:
	addi $t2, $t2, -4			# $t2 - 4
	sb $t2, 0($t1)
	addi $t1, $t1, 1			#$t1 viene incrementato due volte cosi da applicare l'algoritmo solo ai caratteri in posizione dispari
	lbu $t2, 0($t1)
	beq $t2, $zero, fineDecC	#Controllo fine buffer
	addi $t1, $t1, 1
	lbu $t2, 0($t1)
	beq $t2, $zero, fineDecC	#Controllo fine buffer
	j loopDecC
fineDecC:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

# ALGORTIMO E
decE:
	addi $sp, $sp, -12	
	sw $ra, 0($sp)				
	sw $s0, 4($sp)				#I registri $s0 ed $s1 vengono preservati dato che saranno utilizzati
	sw $s1, 8($sp)	
	li $s0, 45
	li $s1, 32			
	move $t0, $a0				#indirizzo buffer input
	move $t1, $a1				#indirizzo buffer output
	li $t4, 0					#contatore cifre che compongono posizione
	li $t9,10					
	li $t7, 0					#registro che conterra la posizione.
	j iniziode
prossimoCarattere:
	li $t6, 1
salvaInPos:	
	lw $t5, 0($sp)				#Viene prelevata la cifra dallo stack
	addi $sp, $sp, 4	
	addi $t5, $t5, -48			#Passa da ASCII al valore decimale
	mult $t5, $t6				#La cifra viene moltiplicata per $t6(1 alla prima iterazione)
	mflo $t5
	add $t7, $t7, $t5			#Il risultato viene sommato a $t7
	mult $t6, $t9				#$t6 viene moltiplicato per 10
	mflo $t6
	addi $t4, $t4, -1			#Viene decrementato di uno il contatore delle cifre della posizione
	bnez $t4, salvaInPos 		#Fino a quando il contatore non e zero si continua con il ciclo
	
	add $t1, $t1, $t7			#Sposta l'indirizzo del buffer di output nella posizione appena calcolata
	sb $t3, 0($t1)				#Salva il carattere nel buffer 
	sub $t1, $t1, $t7			#L'indirizzo del buffer viene riportato in posizione iniziale
	li $t7, 0
	li $t6, 1
	addi $t0, $t0, 1
iniziode:
	lbu $t3, 0($t0)					#Il carattere corrente viene caricato in $t3
	beqz $t3, fineDecE				#Controllo fine buffer
	addi $t0, $t0, 2				#Ci si sposta di due posizioni saltando il '-'
calcoloPos:							#Ogni cifra incontrata fino al prossimo '-' o ' ' viene salvata nello stack
	lbu $t2, 0($t0) 			
	addi $sp, $sp, -4
	sw $t2, 0($sp)
	addi $t4, $t4, 1				#Si incrementa il contatore delle cifre che comporranno la posizione
	addi $t0, $t0, 1
	lbu $t2, 0($t0)				
	beq $t2, $s1, prossimoCarattere	#Se $t2 e uguale a ' ' si passa a posizionare il prossimo carattere
	bne $t2, $s0, calcoloPos		#Se $t2 non e uguale a '-' abbiamo altre cifre che compongono la posizione

	li $t6, 1
salvaInPos1:
		
	lw $t5, 0($sp)					#Viene prelevata la cifra dallo stack
	addi $sp, $sp, 4
	addi $t5, $t5, -48				#Passa da ASCII al valore decimale
	mult $t5, $t6					#La cifra viene moltiplicata per $t6(1 alla prima iterazione)
	mflo $t5
	add $t7, $t7, $t5				#Il risultato viene sommato a $t7
	mult $t6, $t9					#$t6 viene moltiplicato per 10
	mflo $t6
	addi $t4, $t4, -1				#Viene decrementato di uno il contatore delle cifre della posizione
	bnez $t4, salvaInPos1			#Fino a quando il contatore non e zero si continua con il ciclo
	
	add $t1, $t1, $t7				#Sposta l'indirizzo del buffer di output nella posizione appena calcolata
	sb $t3, 0($t1)					#Salva il carattere nel buffer 
	sub $t1, $t1, $t7				#L'indirizzo del buffer viene riportato in posizione iniziale
	li $t7, 0
	li $t6, 1
	addi $t0, $t0, 1				
	j calcoloPos
	
	
fineDecE:
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	addi $sp, $sp, 12
	jr $ra
	



