	;; ============================================================
	;; IRQ handler sub-routines
	;; ============================================================

	;; Setup raster IRQ
setupirq:
	sei
	ldbimm $7f, ci1icr
	ldbimm 1, irqmsk
	ldbimm $1b, scroly
	ldbimm raslin, raster
	ldwimm procirq, cinv
	cli
	rts

	;; IRQ handler. Here we implement logic for:
	;;  - Pac-Man's movement (player controlled but we need to update distance
	;;    remaining, set next target on reaching target node, etc.)
	;;  - Pac-Man's death & remaining lives
	;;  - Ghosts (scatter, chase, fright, and eaten modes)
	;;  - Fruit (appearance and disappearance)
procirq:
	lda pacrem
	beq setnsrc
	lda pacdir
	cmp #w
	bne chkpde
	dec sp0x
	jmp decrem
chkpde:	cmp #e
	bne chkpdn
	inc sp0x
	jmp decrem
chkpdn:	cmp #n
	bne pdsouth
	dec sp0y
	jmp decrem
pdsouth:
	inc sp0y
decrem:	dec pacrem
	lda pacrem
	beq setnsrc
	jmp finirq
setnsrc:
	cpbyt pactar, pacsrc	;set target node as new source node
	ldx #irqblki
	jsr nodeadr		;load node address into irqwrd1
	ldbptr irqwrd1, 0, sp0x	;store node x loc into sp0x
	ldbptr irqwrd1, 1, sp0y	;store node y loc into sp0y
	ldy pacnxd
	beq chkcon
	lda (irqwrd1),y
	cmp #$ff
	beq chkcon
	sta pactar
	sty pacdir
	jsr setnodis
	jmp finirq
chkcon:	ldy pacdir
	lda (irqwrd1),y
	cmp #$ff
	beq finirq
	sta pactar
	jsr setnodis
finirq:	ldbimm 0, pacnxd
	ldbimm 1, vicirq	;acknowledge VIC IRQ
	jmp sysirq