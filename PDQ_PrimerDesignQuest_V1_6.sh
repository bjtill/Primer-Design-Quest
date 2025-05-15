#!/bin/bash
#BT Feb 20, 2025
#Primer design quest 

#######February 4, 2025  Comparison_Code_ISAG_VT1_1.sh becomes GCT Genotype Comparison Tool

#Note that included regions start and lenght either needs to be two columns on the BED file or potentially a separate file for FASTA entry.  
#Version T1.1 modification to add blast values to report, adding bed-ish input with checking for included regions. 
#Version T1.2: fix log, add vcf input
#Version 1.3: Fix extra file issue found in version 1.2  
#Versions 1.4 and 1.5 addition of fai checks for positional errors. Modified amplicon blast. 
#Version 1.6 fixes nomenclature of sequence target in output files 

curl https://raw.githubusercontent.com/bjtill/Primer-Design-Quest/refs/heads/main/PDQ_Details_Images/PDQ_long.jpg > pdqlogo1.jpeg

YADINPUT=$(yad --width=1000 --title="Primer Design Quest (PDQ)" --image=pdqlogo1.jpeg --text="Version 1.6

ABOUT: A tool to design primers from input sequences or chromosomal positions. The program performs BLAST alignments on input sequences and the resulting amplicon sequence to aid in selecting primers/regions that are unique. Click the details button for more inforamation.   


DEPENDENCIES:  Bash, zenity, yad, ncbi-blast+, primer3, bedtools, samtools, curl
VERSION INFORMATION: May 8, 2025 BT" --form --field="CLICK FOR PROGRAM DETAILS:FBTN" 'xdg-open https://github.com/bjtill/Primer-Design-Quest/blob/main/PDQ_Details_Images/PDQ_Details_05142025.pdf' --field="Your Initials for the log file" "Enter" --field="Name for new directory. CAUTION-No spaces or symbols" "Enter" --field="MODE:CB" 'CHOOSE!VCF!GTF!FASTA!ChromPos' --field="Optimal Tm - click box to manually edit:CBE" '60!65!58!55' --field="Optimal Primer Size - click box to manually edit:CBE" '20!25!15' --field="Min Primer Size - click box to manually edit:CBE" '18!20!22!16' --field="Max Primer Size - click box to manually edit:CBE" '22!25!20' --field="Product Size Low - click box to manually edit:CBE" '450!400!500' --field="Product Size High - click box to manually edit:CBE" '600!650!500' --field="BLAST pident retain threshold- click box to manually edit:CBE" '0!80!85' --field="Select reference genome file:FL" --field="Select GTF file (blank if none):FL" --field="Select one column list of GTF gene names (blank if none):FL" --field="Select ChromPos file (blank if none):FL" --field="Select FASTA file (blank if none):FL" --field="VCF file (blank if none):FL" --field="Optional Notes" "Enter" ) 


echo $YADINPUT |  tr '|' '\t' | datamash transpose | head -n -1  > pchparm1
a=$(awk 'NR==3 {if ($1=="Enter") print "MISSING"}' pchparm1)
cp pchparm1 ${a}.diranswer
b=$(awk 'NR==4 {if ($1=="CHOOSE") print "MISSING"}' pchparm1)
cp pchparm1 ${b}.typeanswer

if [ -f "MISSING.diranswer" ] || [ -f "MISSING.typeanswer" ] ; 
then
zenity --width 1200 --warning --text='<span font="32" foreground="red">You forgot to enter a directory name or analysis type. You might have forgotten something else.</span> \n Click OK to end program and try again' --title="MISSING INFORMATION"
exit
rm *.diranswer *.typeanswer pdqlogo1.jpeg 
fi 
rm *.diranswer *.typeanswer pdqlogo1.jpeg 

###########################MAKE DIRECTORY and MOVE##########################################################################

c=$(awk 'NR==3 {print $1}' pchparm1)
mkdir ${c}
mv pchparm1 ./${c}/

cd ${c} 


exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>PCHt.log 2>&1
now=$(date)  
echo "PDQ Version 1.6
Program Started $now." 
#Get yad logo before starting program

curl https://raw.githubusercontent.com/bjtill/Primer-Design-Quest/refs/heads/main/PDQ_Details_Images/PDQ_Square.jpg > pdqlogo2.jpeg

{
#(#Start
echo "# Starting"; sleep 2



echo "# Checking if existing blastdb for ref genome and making one if not."; sleep 2 
e=$(awk 'NR==12{print $1}' pchparm1) #ref genome

if [ ! -f $e.ndb ] || [ ! -f $e.nhr ] || [ ! -f $e.nin ] || [ ! -f $e.nog ] || [ ! -f $e.nos ] || [ ! -f $e.not ] || [ ! -f $e.nsq ] || [ ! -f $e.ntf ] || [ ! -f $e.nto ] ; 
then 

makeblastdb -in ${e} -parse_seqids -dbtype nucl

fi 

#NOTE THAT THIS IS CURRENTLY CODED TO ONLY WORK WITH GTF AND GENE LIST. CONDITIONALS WILL BE ADDED AS NECESSARY


echo "# Checking selected mode."; sleep 2 
r=$(awk 'NR==4{print $1}' pchparm1)
#Check that blastdb is present  TO DO 
#start by converting FASTA and getting lenghts, and then half and then /6 
if [ $r == "FASTA" ] ; 
then
echo "# FASTA mode selected."; sleep 2 
a=$(awk 'NR==16 {print $1}' pchparm1)
bb=$(awk 'NR==5 {print $1}' pchparm1)
bc=$(awk 'NR==6 {print $1}' pchparm1)
bd=$(awk 'NR==7 {print $1}' pchparm1)
be=$(awk 'NR==8 {print $1}' pchparm1)
bf=$(awk 'NR==9 {print $1}' pchparm1)
bg=$(awk 'NR==10 {print $1}' pchparm1)


#lenght/2 centers primer design on 
tr ' ' '_' < ${a} | tr '\t' '_' | awk '/^>/ {if(NR>1) printf("\n"); printf("%s\t", substr($0,2))} !/^>/ {printf("%s", $0)} END {printf("\n")}' | awk -v var=$bb -v var1=$bc -v var2=$bd -v var3=$be -v var4=$bf '{print $1, $2, "SEQUENCE_ID="$1,  "SEQUENCE_TEMPLATE="$2, "PRIMER_OPT_TM="var, "PRIMER_OPT_SIZE="var1, "PRIMER_MIN_SIZE="var2, "PRIMER_MAX_SIZE="var3, "PRIMER_PRODUCT_SIZE_RANGE="var4"-"length($2),  "SEQUENCE_TARGET="int(length($2)/2)","int((length($2)/2)/6), "PRIMER_PICK_LEFT_PRIMER=1", "PRIMER_PICK_INTERNAL_OLIGO=0", "PRIMER_PICK_RIGHT_PRIMER=1", "PRIMER_NUM_RETURN=1", "="}' | tr ' ' '\t' > PrimerInfoFull 


awk '{print $1}' PrimerInfoFull | awk '!visited[$1]++' > FastNames

echo "# FASTA MODE: Designing primers and aligning sequences (this may take a while)."; sleep 2 
while IFS= read -r line; do
e=$(echo "$line" | awk '{print $1}' | awk '!visited[$1]++')  
awk -v var=${e} '{if ($1==var) print ">"$1, $2}' PrimerInfoFull | tr ' ' '\t' | datamash transpose > ${e}.seq1
awk -v var=${e} '{if ($1==var) print $0}' PrimerInfoFull | cut -f3- | tr ' ' '\t' | datamash transpose > ${e}.primer3_template
i=$(awk 'NR==12{print $1}' pchparm1) #ref genom
blastn -db ${i} -query ${e}.seq1 -out ${e}.BLAST_FullSeq_Fullhit -outfmt 6
#Make the template
q=$(date +"%m_%d_%y_at_%H_%M")
awk '{print $0}' ${e}.BLAST_FullSeq_Fullhit >> BLASTOUTPUTS_INPUT_PDQ_FASTAmode.txt


ff=$(awk 'NR==11{print $1}' pchparm1) #BLAST percent identity cutoff
f=$(awk -v var=$ff '{if ($3>=var) print $0}' ${e}.BLAST_FullSeq_Fullhit | wc -l | awk '{print $1}' ) 

#Extract amplicon and blast 

primer3_core ${e}.primer3_template | awk 'NR==1 {print}' | sed 's/SEQUENCE_ID=//g' | awk '{print ">"$1}' > ${e}.tmpname #name


bb=$(primer3_core ${e}.primer3_template | awk 'NR==38 {print}' | sed 's/PRIMER_PAIR_0_PRODUCT_SIZE=//g' ) #length
bc=$(primer3_core ${e}.primer3_template | awk 'NR==22 {print}' | sed 's/PRIMER_LEFT_0=//g' | awk -F, '{print $1}') #left start
bd=$(primer3_core ${e}.primer3_template | awk 'NR==23 {print}' | sed 's/PRIMER_RIGHT_0=//g' | awk -F, '{print $1}') #right start
be=$(awk -v var1=$bc -v var2=$bd 'NR==1{if (var1<var2) print var1; else print var2}' pchparm1) #start
primer3_core ${e}.primer3_template | awk 'NR==2{print $1}' | sed 's/SEQUENCE_TEMPLATE=//g' > ${e}.tmpseq
awk -v var=$be -v var2=$bb '{print substr($1, var, var2)}' ${e}.tmpseq | cat ${e}.tmpname - > ${e}.seq1b
bf=$(awk -v var=$be -v var2=$bb '{print substr($1, var, var2)}' ${e}.tmpseq | awk '{print $1}' )

blastn -db ${i} -query ${e}.seq1b -out ${e}.BLAST_AmpliconSeq_Fullhit -outfmt 6


ff=$(awk 'NR==11{print $1}' pchparm1) #BLAST percent identity cutoff
fg=$(awk -v var=$ff '{if ($3>=var) print $0}' ${e}.BLAST_AmpliconSeq_Fullhit | wc -l | awk '{print $1}' ) 


primer3_core ${e}.primer3_template | awk 'NR==1 || NR==2 || NR==20 || NR==21 || NR==24 || NR==25 || NR==38 {print}' | datamash transpose | sed 's/SEQUENCE_ID=//g' | sed 's/SEQUENCE_TEMPLATE=//g' | sed 's/PRIMER_LEFT_0_SEQUENCE=//g' | sed 's/PRIMER_RIGHT_0_SEQUENCE=//g' | sed 's/PRIMER_LEFT_0_TM=//g' | sed 's/PRIMER_RIGHT_0_TM=//g' | sed 's/PRIMER_PAIR_0_PRODUCT_SIZE=//g' | awk -v var=$f -v var2=$fg -v var4=$bf '{print $1, $3, $5, $4, $6, $7, $2, var4, var, var2}' >> tmppickedprimers


done < FastNames

awk '{if ($4!="") print $0}' tmppickedprimers > tmppickedprimers2


q=$(date +"%m_%d_%y_at_%H_%M")

awk '{if ($4=="") print $0}' tmppickedprimers | awk 'BEGIN{print "Name", "InputSequence", "Number_BlastHits"}1'> FailedPrimerDesign_${q}.txt

cat tmppickedprimers2 | awk 'BEGIN{print "Name", "LeftPrimer", "LeftPrimer_Tm", "RightPrimer", "RightPrimer_Tm", "Product_Size", "InputSequence", "AmpliconSequence", "Number_BlastHits_Input_Pident", "Number_BlastHits_Amplicon_Pident"}1' | tr ' ' ',' | tr '\t' ',' > PDQ_Primers_FASTAmode_${q}.csv 


echo "# END FASTA MODE: Tidying."; sleep 2 
mv BLASTOUTPUTS_INPUT_PDQ_FASTAmode.txt BLASTOUTPUTS_INPUT_PDQ_FASTAmode_${q}.txt
cat *AmpliconSeq_Fullhit > BLASTOUTPUTS_AMPLICON_PDQ_GTFmode_${q}.txt
rm *.primer3_template *.seq1 PrimerInfoFull *.BLAST_FullSeq_Fullhit tmppickedprimers tmppickedprimers2 FastNames
rm *AmpliconSeq_Fullhit 
rm *.tmpseq *.seq1b *.tmpname 

fi

#end FASTA mode



r=$(awk 'NR==4{print $1}' pchparm1)
if [ $r == "GTF" ] ; 
then
#Get samples list 
d=$(awk 'NR==14{print $1}' pchparm1)
cp ${d} Genes

#build the non-variable parts of the primer tempate here
#printf 'PRIMER_TASK=generic \n' > task
printf 'PRIMER_PICK_LEFT_PRIMER=1 \nPRIMER_PICK_INTERNAL_OLIGO=0 \nPRIMER_PICK_RIGHT_PRIMER=1 \nPRIMER_NUM_RETURN=1 \n=' > BottomTemplate

awk 'NR==9 || NR==10 {print}' pchparm1 | datamash transpose | tr '\t' '-' | awk '{print "PRIMER_PRODUCT_SIZE_RANGE="$1}' > range


printf 'PRIMER_OPT_TM= \nPRIMER_OPT_SIZE= \nPRIMER_MIN_SIZE= \nPRIMER_MAX_SIZE=' > tmpmid
awk 'NR==5 || NR==6 || NR==7 || NR==8 {print}' pchparm1 | paste tmpmid - | tr '\t' '&' | tr ' ' '&' | sed 's/&//g' > mid
rm tmpmid

echo "10"

echo "# GTF MODE: Designing primers and running BLAST (This may take a while)."; sleep 2 

#issue with exon versus CDS as agouti-signaling in FD GTF has no exon in column 3
s=$(awk 'NR==12{print $0".fai"}' pchparm1)
if [ ! -f $s ] ; 
then 
t=$(awk 'NR==12{print $0}' pchparm1)
samtools faidx $t   #no multi-threading with this tool 
s=$(awk 'NR==12{print $0".fai"}' pchparm1)  #fai file : use column 2 for the size
fi 



while IFS= read -r line; do
e=$(echo "$line" | awk '{print $1}' | awk '!visited[$1]++')  #Gene:  An issue if there is a space.  
#echo "$line" | awk '{print $0}' | awk '!visited[$1]++' > ${e}.line
f=$(awk 'NR==13{print $1}' pchparm1) #gtf
grep -w $e $f > ${e}.tmpa
#prioritize exons but if none then cds
awk '{if ($3=="exon") print $1, $4, $5, $10}' ${e}.tmpa | sed 's/"//g' | sed 's/;//g' | awk '{if ($2<$3) print $0, "forward"; else print $0, "reverse"}' | awk '{if ($5=="forward") print $0, $3-$2}' | sort -nrk6 | head -1 > ${e}.tmp1
find . -name ${e}.tmp1 -type f -empty -delete
if [ ! -f ${e}.tmp1 ]; 
then
awk '{if ($3=="CDS") print $1, $4, $5, $10}' ${e}.tmpa | sed 's/"//g' | sed 's/;//g' | awk '{if ($2<$3) print $0, "forward"; else print $0, "reverse"}' | awk '{if ($5=="forward") print $0, $3-$2}' | sort -nrk6 | head -1 > ${e}.tmp1
fi
g=$(awk 'NR==FNR{a[$1,$2,$3]=1;next} ($1,$4,$5) in a{split($0,b,"exon_number \""); split(b[2],c,"\""); print $1, $4, $5, "exon_number_"c[1]}' ${e}.tmp1 ${f} | awk 'NR==1{print $4}')
#awk -v var=$g '{print $0, var}' tmp1 > tmp2
h=$(awk 'NR==10{print $1}' pchparm1) #max amplicon size 
#awk -v var=$g '{print $0, var}' tmp1 | awk -v var2=$h '{if ($6<2*var2 && $5=="forward") print $0, ($2-((var2*2)-$6)/2), ($3+((var2*2)-$6)/2); else if ($6<2*var2 && $5=="reverse") print $0, ($2+((var2*2)-$6)/2), ($3-((var2*2)-$6)/2); else print $0, $2, $3}' > FullData

s=$(awk 'NR==12{print $0".fai"}' pchparm1) #add FAI check in GTF mode

awk -v var=$g '{print $0, var}' ${e}.tmp1 | awk -v var2=$h '{if ($6<2*var2 && $5=="forward") print $1, ($2-((var2*2)-$6)/2), ($3+((var2*2)-$6)/2); else if ($6<2*var2 && $5=="reverse") print $1, ($2+((var2*2)-$6)/2), ($3-((var2*2)-$6)/2); else print $1, $2, $3}' | awk '{printf "%s\t%.0f\t%.0f\n", $1, $2, $3}' |  awk '{if ($2<0) print $1, 0, $3; else print $0}' | awk 'NR==FNR{a[$1]=$2;next}{if (a[$1]) print $0, a[$1]}' ${s} - | awk '{if ($3>$4) print $1, $2, $4; else print $1, $2, $3}' | tr ' ' '\t' > SelectedBed

#Now make annotated bed file that will use with tmppickedprimers so that we have exons 
awk -v var=$g '{print $0, var}' ${e}.tmp1 | awk -v var2=$h '{if ($6<2*var2 && $5=="forward") print $1, ($2-((var2*2)-$6)/2), ($3+((var2*2)-$6)/2); else if ($6<2*var2 && $5=="reverse") print $1, ($2+((var2*2)-$6)/2), ($3-((var2*2)-$6)/2); else print $1, $2, $3}' | awk '{printf "%s\t%.0f\t%.0f\n", $1, $2, $3}' | awk '{if ($2<0) print $1, 0, $3; else print $0}' | awk 'NR==FNR{a[$1]=$2;next}{if (a[$1]) print $0, a[$1]}' ${s} - | awk '{if ($3>$4) print $1, $2, $4; else print $1, $2, $3}' | tr ' ' '\t' | awk -v var1=$e -v var2=$g '{print var1, $0, var2}' > ${e}.SelectedRegioninfo

i=$(awk 'NR==12{print $1}' pchparm1) #ref genome
bedtools getfasta -fi ${i} -bed SelectedBed > seq1
awk 'NR==2{print $1}' seq1 > seq2
blastn -db ${i} -query seq1 -out ${e}.BLAST_FullSeq_Fullhit -outfmt 6
#Make the template
q=$(date +"%m_%d_%y_at_%H_%M")
awk '{print $0}' ${e}.BLAST_FullSeq_Fullhit >> BLASTOUTPUTS_INPUT_PDQ_GTFmode.txt
awk -v var=${e} 'NR==1{print "SEQUENCE_ID="var}' pchparm1 > top
awk '{print "SEQUENCE_TEMPLATE="$1}' seq2 > second
cat top second mid range BottomTemplate > ${e}.primer3_template

#Version beta 1.1: add percent identity threshold 

ff=$(awk 'NR==11{print $1}' pchparm1) #BLAST percent identity cutoff
f=$(awk -v var=$ff '{if ($3>=var) print $0}' ${e}.BLAST_FullSeq_Fullhit | wc -l | awk '{print $1}' ) 

#Extract amplicon and blast 

primer3_core ${e}.primer3_template | awk 'NR==1 {print}' | sed 's/SEQUENCE_ID=//g' | awk '{print ">"$1}' > ${e}.tmpname #name


bb=$(primer3_core ${e}.primer3_template | awk 'NR==37 {print}' | sed 's/PRIMER_PAIR_0_PRODUCT_SIZE=//g' ) #length
bc=$(primer3_core ${e}.primer3_template | awk 'NR==21 {print}' | sed 's/PRIMER_LEFT_0=//g' | awk -F, '{print $1}') #left start
bd=$(primer3_core ${e}.primer3_template | awk 'NR==22 {print}' | sed 's/PRIMER_RIGHT_0=//g' | awk -F, '{print $1}') #right start
be=$(awk -v var1=$bc -v var2=$bd 'NR==1{if (var1<var2) print var1; else print var2}' pchparm1) #start
primer3_core ${e}.primer3_template | awk 'NR==2{print $1}' | sed 's/SEQUENCE_TEMPLATE=//g' > ${e}.tmpseq
awk -v var=$be -v var2=$bb '{print substr($1, var, var2)}' ${e}.tmpseq | cat ${e}.tmpname - > ${e}.seq1b
bf=$(awk -v var=$be -v var2=$bb '{print substr($1, var, var2)}' ${e}.tmpseq | awk '{print $1}' )

blastn -db ${i} -query ${e}.seq1b -out ${e}.BLAST_AmpliconSeq_Fullhit -outfmt 6

ff=$(awk 'NR==11{print $1}' pchparm1) #BLAST percent identity cutoff
fg=$(awk -v var=$ff '{if ($3>=var) print $0}' ${e}.BLAST_AmpliconSeq_Fullhit | wc -l | awk '{print $1}' ) 


primer3_core ${e}.primer3_template | awk 'NR==1 || NR==2 || NR==19 || NR==20 || NR==23 || NR==24 || NR==37 {print}' | datamash transpose | sed 's/SEQUENCE_ID=//g' | sed 's/SEQUENCE_TEMPLATE=//g' | sed 's/PRIMER_LEFT_0_SEQUENCE=//g' | sed 's/PRIMER_RIGHT_0_SEQUENCE=//g' | sed 's/PRIMER_LEFT_0_TM=//g' | sed 's/PRIMER_RIGHT_0_TM=//g' | sed 's/PRIMER_PAIR_0_PRODUCT_SIZE=//g' | awk -v var=$f -v var2=$fg -v var4=$bf '{print $1, $3, $5, $4, $6, $7, $2, var4, var, var2}' >> tmppickedprimers



done < Genes

#need to compare and annotate with exon
cat *.SelectedRegioninfo > reginfo 


awk '{if ($4!="") print $0}' tmppickedprimers > tmppickedprimers2


q=$(date +"%m_%d_%y_at_%H_%M")
awk '{if ($4=="") print $0}' tmppickedprimers | awk 'BEGIN{print "Name", "InputSequence", "Number_BlastHits"}1'> FailedPrimerDesign_${q}.txt

awk 'NR==FNR{a[$1]=$2" "$3" "$4" "$5;next}{if (a[$1]) print $0, a[$1]; else print $0, "ERROR"}' reginfo tmppickedprimers2 | awk 'BEGIN{print "Name", "LeftPrimer", "LeftPrimer_Tm", "RightPrimer", "RightPrimer_Tm", "Product_Size", "InputSequence", "AmpliconSequence", "Number_BlastHits_Input_Pident", "Number_BlastHits_Amplicon_Pident", "Chrom", "InputStart", "InputEnd", "GeneModelInfo"}1' | tr ' ' ',' | tr '\t' ',' > PDQ_Primers_GTFmode_${q}.csv 

mv BLASTOUTPUTS_INPUT_PDQ_GTFmode.txt BLASTOUTPUTS_INPUT_PDQ_GTFmode_${q}.txt
cat *AmpliconSeq_Fullhit > BLASTOUTPUTS_AMPLICON_PDQ_GTFmode_${q}.txt

echo "80"

echo "# END GTF MODE: Tidying."; sleep 2 

rm *.SelectedRegioninfo mid range reginfo second tmppickedprimers top *AmpliconSeq_Fullhit *.BLAST_FullSeq_Fullhit *.primer3_template *.tmp1 *.tmpa BottomTemplate SelectedBed seq1 seq2 
rm *.tmpseq *.seq1b *.tmpname Genes tmppickedprimers2



fi 


if [ $r == "ChromPos" ] ; 
then


printf 'PRIMER_PICK_LEFT_PRIMER=1 \nPRIMER_PICK_INTERNAL_OLIGO=0 \nPRIMER_PICK_RIGHT_PRIMER=1 \nPRIMER_NUM_RETURN=1 \n=' > BottomTemplate

awk 'NR==9 || NR==10 {print}' pchparm1 | datamash transpose | tr '\t' '-' | awk '{print "PRIMER_PRODUCT_SIZE_RANGE="$1}' > range


printf 'PRIMER_OPT_TM= \nPRIMER_OPT_SIZE= \nPRIMER_MIN_SIZE= \nPRIMER_MAX_SIZE=' > tmpmid
awk 'NR==5 || NR==6 || NR==7 || NR==8 {print}' pchparm1 | paste tmpmid - | tr '\t' '&' | tr ' ' '&' | sed 's/&//g' > mid
rm tmpmid
 

d=$(awk 'NR==15{print $1}' pchparm1)
cp ${d} chrompos #name, chrom start, end, include position, length 
awk '{print $1}' chrompos > names
h=$(awk 'NR==10{print $1}' pchparm1) #max amplicon size 

while IFS= read -r line; do
e=$(echo "$line" | awk '{print $1}' | awk '!visited[$1]++')  #Gene:  An issue if there is a space.  
awk -v var=${e} '{if ($1==var) print $2, $3, $4}' chrompos | tr ' ' '\t' > tmpbed

i=$(awk 'NR==12{print $1}' pchparm1) #ref genome
bedtools getfasta -fi ${i} -bed tmpbed > seq1
awk 'NR==2{print $1}' seq1 > seq2
blastn -db ${i} -query seq1 -out ${e}.BLAST_FullSeq_Fullhit -outfmt 6
#Make the template
q=$(date +"%m_%d_%y_at_%H_%M")
awk '{print $0}' ${e}.BLAST_FullSeq_Fullhit >> BLASTOUTPUTS_INPUT_PDQ_ChromPosmode.txt
awk -v var=${e} 'NR==1{print "SEQUENCE_ID="var}' pchparm1 > top
awk '{print "SEQUENCE_TEMPLATE="$1}' seq2 > second
#need to add in the includsion and length here if they exist with an empty delete thingy
awk -v var=${e} '{if ($1==var && 5!="" && $6!="") print "SEQUENCE_TARGET="$5","$6}' chrompos > tmpinclude

find . -name "tmpinclude" -type f -empty -delete
if [ -f "tmpinclude" ]; 
then


cat top second mid range tmpinclude BottomTemplate > ${e}.primer3_template
else 
cat top second mid range BottomTemplate > ${e}.primer3_template
fi 

ff=$(awk 'NR==11{print $1}' pchparm1) #BLAST percent identity cutoff
f=$(awk -v var=$ff '{if ($3>=var) print $0}' ${e}.BLAST_FullSeq_Fullhit | wc -l | awk '{print $1}' ) 

#attempt to get a second bed of just amplicon and re-blast.  

primer3_core ${e}.primer3_template | awk 'NR==1 {print}' | sed 's/SEQUENCE_ID=//g' | awk '{print ">"$1}' > ${e}.tmpname #name


bb=$(primer3_core ${e}.primer3_template | awk 'NR==38 {print}' | sed 's/PRIMER_PAIR_0_PRODUCT_SIZE=//g' ) #length
bc=$(primer3_core ${e}.primer3_template | awk 'NR==22 {print}' | sed 's/PRIMER_LEFT_0=//g' | awk -F, '{print $1}') #left start
bd=$(primer3_core ${e}.primer3_template | awk 'NR==23 {print}' | sed 's/PRIMER_RIGHT_0=//g' | awk -F, '{print $1}') #right start
be=$(awk -v var1=$bc -v var2=$bd 'NR==1{if (var1<var2) print var1; else print var2}' pchparm1) #start
primer3_core ${e}.primer3_template | awk 'NR==2{print $1}' | sed 's/SEQUENCE_TEMPLATE=//g' > ${e}.tmpseq
awk -v var=$be -v var2=$bb '{print substr($1, var, var2)}' ${e}.tmpseq | cat ${e}.tmpname - > ${e}.seq1b
bf=$(awk -v var=$be -v var2=$bb '{print substr($1, var, var2)}' ${e}.tmpseq | awk '{print $1}' )

blastn -db ${i} -query ${e}.seq1b -out ${e}.BLAST_AmpliconSeq_Fullhit -outfmt 6

ff=$(awk 'NR==11{print $1}' pchparm1) #BLAST percent identity cutoff
fg=$(awk -v var=$ff '{if ($3>=var) print $0}' ${e}.BLAST_AmpliconSeq_Fullhit | wc -l | awk '{print $1}' ) 

ff=$(awk 'NR==11{print $1}' pchparm1) #BLAST percent identity cutoff
fg=$(awk -v var=$ff '{if ($3>=var) print $0}' ${e}.BLAST_AmpliconSeq_Fullhit | wc -l | awk '{print $1}' ) 


primer3_core ${e}.primer3_template | awk 'NR==1 || NR==2 || NR==20 || NR==21 || NR==24 || NR==25 || NR==38 {print}' | datamash transpose | sed 's/SEQUENCE_ID=//g' | sed 's/SEQUENCE_TEMPLATE=//g' | sed 's/PRIMER_LEFT_0_SEQUENCE=//g' | sed 's/PRIMER_RIGHT_0_SEQUENCE=//g' | sed 's/PRIMER_LEFT_0_TM=//g' | sed 's/PRIMER_RIGHT_0_TM=//g' | sed 's/PRIMER_PAIR_0_PRODUCT_SIZE=//g' | awk -v var=$f -v var2=$fg -v var4=$bf '{print $1, $3, $5, $4, $6, $7, $2, var4, var, var2}' >> tmppickedprimers


done < names

#at this stage you can have cases where primer3 won't find anything.  These are primer design failures and should get dumped elsewhere
#if you dont get primer3, columns are messed up and 4 is blank)
awk '{if ($4!="") print $0}' tmppickedprimers > tmppickedprimers2


q=$(date +"%m_%d_%y_at_%H_%M")

awk '{if ($4=="") print $0}' tmppickedprimers | awk 'BEGIN{print "Name", "InputSequence", "Number_BlastHits"}1'> FailedPrimerDesign_${q}.txt

awk 'NR==FNR{a[$1]=$2" "$3" "$4" "$5" "$6;next}{if (a[$1]) print $0, a[$1]; else print $0, "ERROR"}' chrompos tmppickedprimers2 | awk 'BEGIN{print "Name", "LeftPrimer", "LeftPrimer_Tm", "RightPrimer", "RightPrimer_Tm", "Product_Size", "InputSequence", "AmpliconSequence", "Number_BlastHits_Input_Pident", "Number_BlastHits_Amplicon_Pident", "Chrom", "InputStart", "InputEnd", "SeqTarget", "Length"}1' | tr ' ' ',' | tr '\t' ',' > PDQ_Primers_ChromPosmode_${q}.csv 
mv BLASTOUTPUTS_INPUT_PDQ_ChromPosmode.txt BLASTOUTPUTS_INPUT_PDQ_ChromPosmode_${q}.txt
cat *AmpliconSeq_Fullhit > BLASTOUTPUTS_AMPLICON_PDQ_ChromPosmode_${q}.txt
rm BottomTemplate mid range second tmppickedprimers top tmppickedprimers2
rm *.BLAST_FullSeq_Fullhit *.primer3_template seq1 seq2 names chrompos tmpbed tmpinclude *AmpliconSeq_Fullhit
rm *.tmpname *.tmpseq *.seq1b

echo "# END CHROMPOS MODE: Tidying."; sleep 2
fi  

if [ $r == "VCF" ] ; 
then

s=$(awk 'NR==12{print $0".fai"}' pchparm1)
if [ ! -f $s ] ; 
then 
t=$(awk 'NR==12{print $0}' pchparm1)
samtools faidx $t   #no multi-threading with this tool 
s=$(awk 'NR==12{print $0".fai"}' pchparm1)  #fai file : use column 2 for the size
fi 
s=$(awk 'NR==12{print $0".fai"}' pchparm1)


v=$(awk 'NR==17 {print $1}' pchparm1) #vcfpath (doesn't matter if .gz or not)
#build a chrompos file 
echo "# VCF MODE: Designing primers and running BLAST (This may take a while)."; sleep 2
h=$(awk 'NR==10{print $1}' pchparm1) #max amplicon size 
i=$(awk 'NR==10{print $1}' pchparm1 | awk '{print $1/6}') #lenght to include surrounding the variant position
#fix for chromosome ends here: remove any left end of chrom minus positions and then correct for right end of chrom errors. 
bcftools query -f '%CHROM\t%POS\n' ${v} | awk -v var=$h -v var2=$i '{print $1"_"$2, $1, $2-var, $2+var, var+1, var2}' | tr ' ' '\t' | awk '{if ($3<0) print $2, $1, $2, 0, $4, $5, $6; else print $2, $0}' |  awk 'NR==FNR{a[$1]=$2;next}{if (a[$1]) print $0, a[$1]}' ${s} - | cut -d " " -f2- | awk '{if ($7<$4) print $1, $2, $3, $7, $5, $6; else print $0}' | tr ' ' '\t' > chrompos


#Main processing part 

printf 'PRIMER_PICK_LEFT_PRIMER=1 \nPRIMER_PICK_INTERNAL_OLIGO=0 \nPRIMER_PICK_RIGHT_PRIMER=1 \nPRIMER_NUM_RETURN=1 \n=' > BottomTemplate

awk 'NR==9 || NR==10 {print}' pchparm1 | datamash transpose | tr '\t' '-' | awk '{print "PRIMER_PRODUCT_SIZE_RANGE="$1}' > range


printf 'PRIMER_OPT_TM= \nPRIMER_OPT_SIZE= \nPRIMER_MIN_SIZE= \nPRIMER_MAX_SIZE=' > tmpmid
awk 'NR==5 || NR==6 || NR==7 || NR==8 {print}' pchparm1 | paste tmpmid - | tr '\t' '&' | tr ' ' '&' | sed 's/&//g' > mid
rm tmpmid
 

#d=$(awk 'NR==15{print $1}' pchparm1)
#cp ${d} chrompos #name, chrom start, end, include position, length 
awk '{print $1}' chrompos > names
h=$(awk 'NR==10{print $1}' pchparm1) #max amplicon size 

while IFS= read -r line; do
e=$(echo "$line" | awk '{print $1}' | awk '!visited[$1]++')  #Gene:  An issue if there is a space.  
awk -v var=${e} '{if ($1==var) print $2, $3, $4}' chrompos | tr ' ' '\t' > tmpbed

i=$(awk 'NR==12{print $1}' pchparm1) #ref genome
bedtools getfasta -fi ${i} -bed tmpbed > seq1
awk 'NR==2{print $1}' seq1 > seq2
blastn -db ${i} -query seq1 -out ${e}.BLAST_FullSeq_Fullhit -outfmt 6
#Make the template
q=$(date +"%m_%d_%y_at_%H_%M")
awk '{print $0}' ${e}.BLAST_FullSeq_Fullhit >> BLASTOUTPUTS_INPUT_PDQ_VCFmode.txt
awk -v var=${e} 'NR==1{print "SEQUENCE_ID="var}' pchparm1 > top
awk '{print "SEQUENCE_TEMPLATE="$1}' seq2 > second
#need to add in the includsion and length here if they exist with an empty delete thingy
awk -v var=${e} '{if ($1==var && 5!="" && $6!="") print "SEQUENCE_TARGET="$5","$6}' chrompos > tmpinclude

find . -name "tmpinclude" -type f -empty -delete
if [ -f "tmpinclude" ]; 
then


cat top second mid range tmpinclude BottomTemplate > ${e}.primer3_template
else 
cat top second mid range BottomTemplate > ${e}.primer3_template
fi 

ff=$(awk 'NR==11{print $1}' pchparm1) #BLAST percent identity cutoff
f=$(awk -v var=$ff '{if ($3>=var) print $0}' ${e}.BLAST_FullSeq_Fullhit | wc -l | awk '{print $1}' ) 

#attempt to get a second bed of just amplicon and re-blast.  

primer3_core ${e}.primer3_template | awk 'NR==1 {print}' | sed 's/SEQUENCE_ID=//g' | awk '{print ">"$1}' > ${e}.tmpname #name


bb=$(primer3_core ${e}.primer3_template | awk 'NR==38 {print}' | sed 's/PRIMER_PAIR_0_PRODUCT_SIZE=//g' ) #length
bc=$(primer3_core ${e}.primer3_template | awk 'NR==22 {print}' | sed 's/PRIMER_LEFT_0=//g' | awk -F, '{print $1}') #left start
bd=$(primer3_core ${e}.primer3_template | awk 'NR==23 {print}' | sed 's/PRIMER_RIGHT_0=//g' | awk -F, '{print $1}') #right start
be=$(awk -v var1=$bc -v var2=$bd 'NR==1{if (var1<var2) print var1; else print var2}' pchparm1) #start
primer3_core ${e}.primer3_template | awk 'NR==2{print $1}' | sed 's/SEQUENCE_TEMPLATE=//g' > ${e}.tmpseq
awk -v var=$be -v var2=$bb '{print substr($1, var, var2)}' ${e}.tmpseq | cat ${e}.tmpname - > ${e}.seq1b
bf=$(awk -v var=$be -v var2=$bb '{print substr($1, var, var2)}' ${e}.tmpseq | awk '{print $1}' )

blastn -db ${i} -query ${e}.seq1b -out ${e}.BLAST_AmpliconSeq_Fullhit -outfmt 6

ff=$(awk 'NR==11{print $1}' pchparm1) #BLAST percent identity cutoff
fg=$(awk -v var=$ff '{if ($3>=var) print $0}' ${e}.BLAST_AmpliconSeq_Fullhit | wc -l | awk '{print $1}' ) 

ff=$(awk 'NR==11{print $1}' pchparm1) #BLAST percent identity cutoff
fg=$(awk -v var=$ff '{if ($3>=var) print $0}' ${e}.BLAST_AmpliconSeq_Fullhit | wc -l | awk '{print $1}' ) 


primer3_core ${e}.primer3_template | awk 'NR==1 || NR==2 || NR==20 || NR==21 || NR==24 || NR==25 || NR==38 {print}' | datamash transpose | sed 's/SEQUENCE_ID=//g' | sed 's/SEQUENCE_TEMPLATE=//g' | sed 's/PRIMER_LEFT_0_SEQUENCE=//g' | sed 's/PRIMER_RIGHT_0_SEQUENCE=//g' | sed 's/PRIMER_LEFT_0_TM=//g' | sed 's/PRIMER_RIGHT_0_TM=//g' | sed 's/PRIMER_PAIR_0_PRODUCT_SIZE=//g' | awk -v var=$f -v var2=$fg -v var4=$bf '{print $1, $3, $5, $4, $6, $7, $2, var4, var, var2}' >> tmppickedprimers



done < names

#at this stage you can have cases where primer3 won't find anything.  These are primer design failures and should get dumped elsewhere
#if you dont get primer3, columns are messed up and 4 is blank)
awk '{if ($4!="") print $0}' tmppickedprimers > tmppickedprimers2


q=$(date +"%m_%d_%y_at_%H_%M")

awk '{if ($4=="") print $0}' tmppickedprimers | awk 'BEGIN{print "Name", "InputSequence", "Number_BlastHits"}1'> FailedPrimerDesign_${q}.txt

awk 'NR==FNR{a[$1]=$2" "$3" "$4" "$5" "$6;next}{if (a[$1]) print $0, a[$1]; else print $0, "ERROR"}' chrompos tmppickedprimers2 | awk 'BEGIN{print "Name", "LeftPrimer", "LeftPrimer_Tm", "RightPrimer", "RightPrimer_Tm", "Product_Size", "InputSequence", "AmpliconSequence", "Number_BlastHits_Input_Pident", "Number_BlastHits_Amplicon_Pident", "Chrom", "InputStart", "InputEnd", "SeqTarget", "Length"}1' | tr ' ' ',' | tr '\t' ',' > PDQ_Primers_VCFmode_${q}.csv 
mv BLASTOUTPUTS_INPUT_PDQ_VCFmode.txt BLASTOUTPUTS_INPUT_PDQ_VCFmode_${q}.txt
cat *AmpliconSeq_Fullhit > BLASTOUTPUTS_AMPLICON_PDQ_VCFmode_${q}.txt
rm BottomTemplate mid range second tmppickedprimers top tmppickedprimers2 *AmpliconSeq_Fullhit
rm *.BLAST_FullSeq_Fullhit *.primer3_template seq1 seq2 names chrompos tmpbed tmpinclude

echo "# END VCF MODE: Tidying."; sleep 2
rm *.tmpname *.tmpseq *.seq1b

fi  

printf '\nUser initials: \nDirectory Name: \nMode: \nOptimal Tm: \nOptimal primer len: \nMin primer len: \nMax primer len: \nMin amplicon size: \nMax amplicon size: \nBLAST percent identity threshold: \nRef genome path: \nGTF file: \nGene names: \nChromPos file path: \nFASTA file path: \nVCF file path: \nNotes: ' > par1head
# ) | zenity --width 800 --title "GTC PROGRESS" --progress --auto-close
} | yad --progress --image=pdqlogo2.jpeg --title "PROGRESS" --text "Primer Design Quest Version 1.6\n\n\n" --width=700 --pulsate --button=EXIT --auto-kill --ltr --auto-close
now=$(date)
echo "Program Finished $now."
p=$(date +"%m_%d_%Y") 
paste par1head pchparm1 | cat PCHt.log - > PDQ_${p}.log 
rm PCHt.log par1head pchparm1 pdqlogo2.jpeg


##### END OF PROGRAM ###########################################################################################################################

