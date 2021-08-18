/********************************************************************************************************************/
/********************************************************************************************************************/

/*�۾����� */
libname a 'F:\2020projects\bae\KEITI\research\2.���\B�� ����ڷ�(2010-2019)\outdata';

/*����ڷ� b��*/
libname b 'F:\2020projects\bae\KEITI\research\2.���\B�� ����ڷ�(2010-2019)';

/*data ���� ��ġ �̸� �����ؼ� ��������, CSV��  */
data b1;
keep fname;
rc=filename("mydir","F:\2020projects\bae\KEITI\research\2.���\B�� ����ڷ�(2010-2019)\deathdata");
did=dopen("mydir");
nf=dnum(did);

do i=1 to nf;
fname=dread(did,i);
if index (upcase(fname),"CSV")>0 then output;
end;
rc=dclose(did);
run;

data _null_; set b1; call symput("n", strip(_n_)); run;

/********************************************************************************************************************/
/********************************************************************************************************************/
/*_null_ : ������ �� ������ ����*/
/*_n_ �ڵ����� */
/*call symput: ���� ��ũ�� ������ �Է��ؼ� ����*/
/*��ũ�� �̿��ؼ� csv���� �ϰ� �ҷ����� */
%macro importFile;
%do i=1 %to &n;
data _null_; set b1; 
if _n_=&i; 
call symput('file',trim(cats('F:\2020projects\bae\KEITI\research\2.���\B�� ����ڷ�(2010-2019)\deathdata\',fname,"")));run;
proc import out=y&i datafile="&file" DBMS=CSV;  RUN;
%end;
%mend;

%importFile;
/********************************************************************************************************************/
/********************************************************************************************************************/
/*�ڷ� merge */
data a.all; set y1-y10; run; /*2010-2019*/

/* �� ���� ����
v1: �Ű����� (��)          v2: �Ű����� (��)   v3: �Ű����� (��)
v4: ����� �ּ�(�õ�)
v5: ����� �ּ�(�ñ���)
v6: ����
v7: ���������            v8: ����ð�
v9: �������(5������)
v10: ������
v11: �������
v12: ȥ�λ���
v13: ��������
v14: ������� 103 �׸�
v15: ������� 56 �׸� 
*/

/********************************************************************************************************************/
/********************************************************************************************************************/
/* �õ� ���� 
11	���� 21	�λ� 22	�뱸 23	��õ 24	���� 25	���� 26	��� 29	���� 
31	��� 32	���� 33	��� 34	�泲 35	���� 36	���� 37	��� 38	�泲 39	���� */
/********************************************************************************************************************/
/********************************************************************************************************************/
data A.all_r ;  
RETAIN var7 var4 SGG var6 var9 var14 ;  /*��������: �������� �õ� �ñ��� ���� ���ɱ׷� �������103 */
LENGTH SGG $5; /*�ñ��� 5�ڸ� */
set A.all;

/*label ���� */
RENAME VAR4=SIDO  VAR6=SEX VAR7=DEATHDATE VAR9=AGE_GROUP VAR14=DEATH103 ;

/*�ñ��� 5�ڸ� */
SGG=var4*1000+var5; 

/*��� �� �� �� */
YEAR   =SUBSTR(LEFT(VAR7),1,4);
MONTH=SUBSTR(LEFT(VAR7),5,2);
DAY    =SUBSTR(LEFT(VAR7),7,2);

/*���� �׷� �з�*/
KEEP  VAR4 SGG VAR6 VAR7 VAR9 VAR14 YEAR MONTH DAY AGE_GROUP;
run;

proc freq data=a.all_r noprint; table sgg*year*age_group /out=myfreq2; run; 
 

/********************************************************************************************************************/
/********************************************************************************************************************/


/*���û ���������� A�� �ڷ� ���� missing ������ �ڷ��  ��ü ���(all-cause) N�� ���� n=2,749,704 */
DATA A.ALL_R2; SET A.ALL_R;
/*���� �׷� 99 ���� (MISSING)*/
IF AGE_GROUP^=99;
 
iF AGE_GROUP=1 THEN  AG=0;  /*���� �׷� 0�� */
ELSE IF AGE_GROUP>=2 & AGE_GROUP<5 THEN AG=1;   /*���� �׷� 2~14�� */
ELSE IF AGE_GROUP>=5 & AGE_GROUP<15 THEN AG=2;  /*���� �׷� 15~64�� */
ELSE AG=3;/*���� �׷� 65��+ */

/* 0-4�� �ٸ��� ���� */ 
if age_group in (1, 2) then age_group2=2; /* 0-4��*/
else age_group2=age_group;  					/*�������� ���� */

/*�ñ��� 2019�� �������� �����ֱ� (�������� ������ ) N=261 -> N250*/
/*���ڵ忡 ���� �ñ��� ����(N=11): 
33040 ����û�ֽ�  
34010 õ�Ƚ� 
35010 ���ֽ�  
37010 ���׽�  
38110 ����â���� 
31010 ������ 
31020 ������ 
31040 �Ⱦ�� 
31090 ���ý� 
31100 ���� 
31190 ���ν�*/

/*���� �ñ��� */ 
/*���� ���� */
SGG_RAW=SGG;
IF SGG=23030 THEN SGG=23090; ELSE SGG=SGG;  /*����Ȧ��(����)*/
IF SGG=34320 THEN SGG=29010; ELSE SGG=SGG; /*���ⱺ   ->������ */
IF SGG=34390 THEN SGG=34080; ELSE SGG=SGG; /*������   ->������*/

IF SGG=31320 THEN SGG=31280; ELSE SGG=SGG; /*���ֱ� -> ���ֽ�*/
IF SGG=33010 THEN SGG=33040; ELSE SGG=SGG; /*û�ֽ�   ->û�ֽ�*/
IF SGG=33310 THEN SGG=33044; ELSE SGG=SGG; /*û����-> û����*/
IF SGG=33011 THEN SGG=33041; ELSE SGG=SGG; /*û�ֽ� ��籸 �ڵ�� ����*/
IF SGG=33012 THEN SGG=33043; ELSE SGG=SGG; /*û�ֽ� ����� �ڵ�� ����*/
IF SGG=31051 THEN SGG=31050; ELSE SGG=SGG; /*��õ�� ���̱� ->��õ�� ����*/
IF SGG=31052 THEN SGG=31050; ELSE SGG=SGG; /*��õ�� �һ籸 ->��õ�� ����*/
IF SGG=31053 THEN SGG=31050; ELSE SGG=SGG;  /*��õ�� ������ ->��õ�� ����*/

/*�ñ��� �Ѱ� ���س⵵�� ���� �� MERGE Ű ����� (��������+�ñ���)*/
KEY=COMPRESS(DEATHDATE)||("-")||COMPRESS(SGG);
DROP DEATH56 ;
RUN;  

proc freq data=a.all_r2 (where=(age_group2=16)) noprint; table year*sgg /out=myfreq; run; 
proc freq data=myfreq; table sgg; run;


PROC FREQ DATA= A.ALL_R2 noprint ; TABLES SGG/ out=mysgg; RUN;


/*�ֿ� ���� ���� �ֳ� Ȯ�� : �õ� �ñ��� ���� ���ɱ׷� �������*/
PROC FREQ DATA=A.ALL_R2; TABLES SIDO SGG SEX AGE_GROUP AGE_GROUP2 DEATH103 AG; RUN;

/********************************************************************************************************************/
/********************************************************************************************************************/

/*�������103�׸� ���ؼ� ������κ� ���� ���� */
DATA A.DEATH; SET A.ALL_R2;

TOT=1;                                                                              /*�� ��� */
IF DEATH103<=94 THEN NON_ACC=1; ELSE NON_ACC=0;         /*�ڿ��� (���� ���) */

if DEATH103>=64 & DEATH103<=71 then cvd=1; else cvd=0;	   /*��ü������ */
if DEATH103=67 then ihd=1; else ihd=0; 			        	           /*������ ���� ��ȯ*/
if DEATH103=70 then ather=1; else ather=0;  			               /*�׻��ȭ��(Atherosclerosis) */
if DEATH103=69 then cerbv=1; else cerbv=0; 			               /*������ ��ȯ(Cerebrovascular diseases) */
if DEATH103=66 then htn=1; else htn=0;  				                   /*�����м� ��ȯ(Hypertensive diseases) */
if DEATH103=67 then ihd=1; else ihd=0;  				                   /*������ ���� ��ȯ(Ischaemic heart diseases) */
if DEATH103=71 then othercvd=1; else othercvd=0;                   /*������ ��ȯ���� ��ȯ*/
if DEATH103=68 then otherheart=1; else otherheart=0;                /*��Ÿ ���� ��ȯ(Other heart diseases) */

if DEATH103 >=73 & DEATH103 <=77 then resp=1; else resp=0;  /*��üȣ��� */
if DEATH103>=74 & DEATH103<=75 then alri=1; else alri=0;	        /*�Ϻ�ȣ��Ⱘ�� */
if DEATH103=73 then infl=1; else infl=0;				                   /*���÷翣�� */
if DEATH103=76 then lrd=1; else lrd=0;                                    /*���� �ϱ⵵ ��ȯ(Chronic lower respiratory diseases)*/
if DEATH103=77 then otherresp=1; else otherresp=0;                 /*������ ȣ����� ��ȯ */

if DEATH103=34 then lungc=1; else lungc=0;				               /*���*/
if DEATH103=31 then livc=1; else livc=0;				                   /*���� */

if DEATH103=93 then cano=1;else cano=0;				               /*��õ ����, ���� �� ����ü�̻�*/
if DEATH103=88 then misc=1;else misc=0;				               /*����*/

if DEATH103=60 then alz=1; else alz=0;  				                   /*�������̸Ӻ�(Alzheimer's disease) */
if DEATH103=61 then othernerv=1; else othernerv=0;                 /*������ �Ű���� ��ȯ*/

if DEATH103=65 then rheum=1; else rheum=0;                         /*�޼� ����Ƽ���� �� ���� ����Ƽ�� ���� ��ȯ*/
if DEATH103=63 then ear=1; else ear=0;  				                   /*�� �� ������ ��ȯ (Diseases of the ear and mastoid process)*/
if DEATH103=62 then eye=1; else eye=0;  				               /*�� �� ���μӱ��� ��ȯ (Diseases of the eye and adnexa) */

if DEATH103=52 then dm=1; else dm=0; 					               /*�索��(Diabetes mellitus) */
if DEATH103=54 then endo=1; else endo=0;  			 	           /*������ ���к�, ���� �� ��� ��ȯ */

if DEATH103=85 then kidney=1; else kidney=0;                         /*�籸ü ��ȯ �� ������-���� ��ȯ */
if DEATH103=86 then otherkidney=1; else otherkidney=0;            /*������ �񴢻��İ��� ��ȯ */

if DEATH103=56 then mental=1; else mental=0;                         /*����Ȱ������ ��뿡 ���� ���� �� �ൿ���*/
if DEATH103=57 then othermental=1; else othermental=0;            /*������ ���� �� �ൿ ���*/

if DEATH103=101 then suid=1; else suid=0;			      	           /*�ڻ� */

RUN;



/*���� ��� A��= 2,453,651  ���� ��� B��= 2,453,686  

   ��ü ȣ��� A��= 272,072    B��=272,107

35�� ���� why? => A������ ��ȯ�ڵ� �� U �ڵ尡 ���ԵǾ��ִµ� (n=35)
B�������� U�ڵ� ������ ���� �Ǿ����� �ʰ� �ٸ� �׸� ���Ե� �� 
��ü ������ A��= 591,267 B��= 591,267 (���� x) */

PROC FREQ DATA=A.DEATH; TABLES TOT NON_ACC RESP cvd  ; RUN;

/********************************************************************************************************************/
/********************************************************************************************************************/

/*������ ��� ���κ�  �հ� */
proc sql; create table z_YEAR as select YEAR, sum(tot) as tot, sum(non_acc) as non_acc , sum(resp) as resp, sum(alri) as alri, sum(infl) as infl, sum(cvd) as cvd, sum(cano) as cano,
sum(misc) as misc, sum(lungc) as lungc, sum(livc) as livc, sum(suid) as suid, sum(alz) as alz, sum(ather) as ather, sum(cerbv) as cerbv, sum(dm) as dm, sum(ear) as ear,
sum(endo) as endo, sum(eye) as eye, sum(htn) as htn, sum(ihd) as ihd, sum(kidney) as kidney, sum(lrd) as lrd, sum(mental) as mental, sum(othercvd) as othercvd, 
sum(otherheart) as otherheart, sum(otherkidney) as otherkidney, sum(othermental) as othermental, sum(othernerv) as othernerv, sum(otherresp) as otherresp, sum(rheum) as rheum from
a.DEATH GROUP BY YEAR; QUIT;

/*��ü �հ�  */
proc sql; create table z_TOT as select sum(tot) as tot, sum(non_acc) as non_acc , sum(resp) as resp, sum(alri) as alri, sum(infl) as infl, sum(cvd) as cvd, sum(cano) as cano,
sum(misc) as misc, sum(lungc) as lungc, sum(livc) as livc, sum(suid) as suid, sum(alz) as alz, sum(ather) as ather, sum(cerbv) as cerbv, sum(dm) as dm, sum(ear) as ear,
sum(endo) as endo, sum(eye) as eye, sum(htn) as htn, sum(ihd) as ihd, sum(kidney) as kidney, sum(lrd) as lrd, sum(mental) as mental, sum(othercvd) as othercvd, 
sum(otherheart) as otherheart, sum(otherkidney) as otherkidney, sum(othermental) as othermental, sum(othernerv) as othernerv, sum(otherresp) as otherresp, sum(rheum) as rheum from
a.DEATH ; QUIT;

/*�� �ΰ� ���̺� ���� */
DATA ZZ; SET Z_YEAR Z_TOT;
IF YEAR="" THEN YEAR="Total"; ELSE YEAR=YEAR;run;
/********************************************************************************************************************/
/********************************************************************************************************************/

/*��¥ �ڷ� �����*/
/*���ؿ����� ���ؿ����� �ش��ϴ� �ñ��� �����ؼ� �ñ����� ��¥ �����ϱ� */


/*���� �ڷῡ�� ���ؿ����� �ش��ϴ� �ñ����� ��������  */
DATA A.SGG; SET A.DEATH; KEEP SGG; RUN; 

/*���� �ñ����� �����  */
PROC SORT DATA= A.SGG NODUPKEY ; BY SGG; RUN;

/*��¥ �ڷ� ���� ����� */
DATA A.DDATE ; 
FORMAT DATE YYMMDD10.;
DO I = 1 to 3652 BY 1;       
DATE=MDY(01,01,2010)+I-1; /* �ݺ������� ��¥ ����� 2010�� 1�� 1�Ϻ��� 2019�� 12�� 31�� ���� */
OUTPUT;
END;
DROP I;
RUN;
DATA A.DDATE; SET A.DDATE;
DATE2= PUT(DATE,YYMMDDN8.);RUN; /*��¥ -> ���ڷ� ���� ���� */

/*������ ������ ���ؿ��� ��¥ �ڷ�� �ñ��� �ڷ� MERGE�ϱ� (�̶� CROSS JOIN)*/
proc sql; create table a.SGGDATE as select * from a.ddate cross join  a.sgg; quit;

/*KEY�� �� ����� KEY=��¥+�ñ���  (��¥�� �ñ��� ���պ� ���� ���, 3652�� * 250 =913000) */
DATA a.Sggdate; SET a.Sggdate; KEY=COMPRESS(DATE2)||("-")||COMPRESS(SGG); KEEP KEY; RUN;


/* ������κ� ������ ī��Ʈ �ڷ� ����� ��ũ�� */
%MACRO DEATH(CAUSE);

/*��� �����ڷῡ�� ���� ���� �ϰ� �ʿ亯���� ����  */
DATA A.Z1 ; SET A.DEATH;
RENAME &CAUSE=D; /*DISEASE(������� ������ ����)*/
KEEP KEY DEATHDATE SIDO SGG SEX   YEAR AG age_group2 &CAUSE.; 
RUN;

/*������ ������ �ڷῡ�� ��, ����, ��*���� ���� ���� */
DATA A.Z2; SET A.Z1;

/*���� */
IF SEX=1 & D=1 THEN &CAUSE._SEX_M=1; ELSE &CAUSE._SEX_M=0;
IF SEX=2 & D=1 THEN &CAUSE._SEX_F=1; ELSE &CAUSE._SEX_F=0;

/*���� �׷캰 0:0�� 1:1~14�� 2:15-64��, 3: 65�� �̻� */
IF AG=0 & D=1 THEN &CAUSE._AG00=1   ; ELSE &CAUSE._AG00=0;
IF AG in (0, 1) & D=1 THEN &CAUSE._AG0014=1; ELSE &CAUSE._AG0014=0;
IF AG=2 & D=1 THEN &CAUSE._AG1564=1; ELSE &CAUSE._AG1564=0;
IF AG=3 & D=1 THEN &CAUSE._AG65=1;    ELSE &CAUSE._AG65=0;

/*���� * ���� �׷캰  */
IF SEX=1 & AG=0 & D=1 THEN &CAUSE._AG00_M=1; ELSE &CAUSE._AG00_M=0;
IF SEX=1 & AG in (0, 1) & D=1 THEN &CAUSE._AG0014_M=1; ELSE &CAUSE._AG0014_M=0;
IF SEX=1 & AG=2 & D=1 THEN &CAUSE._AG1564_M=1; ELSE &CAUSE._AG1564_M=0;
IF SEX=1 & AG=3 & D=1 THEN &CAUSE._AG65_M=1; ELSE &CAUSE._AG65_M=0;

/*���� * ���� �׷캰  */
IF SEX=2 & AG=0 & D=1 THEN &CAUSE._AG00_F=1; ELSE &CAUSE._AG00_F=0;
IF SEX=2 & AG in (0, 1) & D=1 THEN &CAUSE._AG0014_F=1; ELSE &CAUSE._AG0014_F=0;
IF SEX=2 & AG=2 & D=1 THEN &CAUSE._AG1564_F=1; ELSE &CAUSE._AG1564_F=0;
IF SEX=2 & AG=3 & D=1 THEN &CAUSE._AG65_F=1; ELSE &CAUSE._AG65_F=0;


/*** ǥ��ȭ����� ���� ������ */
/*���� * ���� �׷캰  */
IF SEX=1 & Age_group2=2  & D=1 THEN &CAUSE._Age_group2_02_M=1; ELSE &CAUSE._Age_group2_02_M=0; /*0-4�� �� */
IF SEX=1 & Age_group2=3  & D=1 THEN &CAUSE._Age_group2_03_M=1; ELSE &CAUSE._Age_group2_03_M=0; /*5-9�� �� */
IF SEX=1 & Age_group2=4  & D=1 THEN &CAUSE._Age_group2_04_M=1; ELSE &CAUSE._Age_group2_04_M=0; /*10-14�� �� */
IF SEX=1 & Age_group2=5  & D=1 THEN &CAUSE._Age_group2_05_M=1; ELSE &CAUSE._Age_group2_05_M=0; /*15-19�� �� */
IF SEX=1 & Age_group2=6  & D=1 THEN &CAUSE._Age_group2_06_M=1; ELSE &CAUSE._Age_group2_06_M=0; /*20-24�� �� */
IF SEX=1 & Age_group2=7  & D=1 THEN &CAUSE._Age_group2_07_M=1; ELSE &CAUSE._Age_group2_07_M=0; /*25-29�� �� */
IF SEX=1 & Age_group2=8  & D=1 THEN &CAUSE._Age_group2_08_M=1; ELSE &CAUSE._Age_group2_08_M=0; /*30-34�� �� */
IF SEX=1 & Age_group2=9  & D=1 THEN &CAUSE._Age_group2_09_M=1; ELSE &CAUSE._Age_group2_09_M=0; /*35-39�� �� */
IF SEX=1 & Age_group2=10 & D=1 THEN &CAUSE._Age_group2_10_M=1; ELSE &CAUSE._Age_group2_10_M=0; /*40-44�� �� */
IF SEX=1 & Age_group2=11 & D=1 THEN &CAUSE._Age_group2_11_M=1; ELSE &CAUSE._Age_group2_11_M=0; /*45-49�� �� */
IF SEX=1 & Age_group2=12 & D=1 THEN &CAUSE._Age_group2_12_M=1; ELSE &CAUSE._Age_group2_12_M=0; /*50-54�� �� */
IF SEX=1 & Age_group2=13 & D=1 THEN &CAUSE._Age_group2_13_M=1; ELSE &CAUSE._Age_group2_13_M=0; /*55-59�� �� */
IF SEX=1 & Age_group2=14 & D=1 THEN &CAUSE._Age_group2_14_M=1; ELSE &CAUSE._Age_group2_14_M=0; /*60-64�� �� */
IF SEX=1 & Age_group2=15 & D=1 THEN &CAUSE._Age_group2_15_M=1; ELSE &CAUSE._Age_group2_15_M=0; /*65-69�� �� */
IF SEX=1 & Age_group2=16 & D=1 THEN &CAUSE._Age_group2_16_M=1; ELSE &CAUSE._Age_group2_16_M=0; /*70-74�� �� */
IF SEX=1 & Age_group2=17 & D=1 THEN &CAUSE._Age_group2_17_M=1; ELSE &CAUSE._Age_group2_17_M=0; /*75-79�� �� */
IF SEX=1 & Age_group2=18 & D=1 THEN &CAUSE._Age_group2_18_M=1; ELSE &CAUSE._Age_group2_18_M=0; /*80-84�� �� */
IF SEX=1 & Age_group2=19 & D=1 THEN &CAUSE._Age_group2_19_M=1; ELSE &CAUSE._Age_group2_19_M=0; /*85+�� �� */


/*���� * ���� �׷캰  */
IF SEX=2 & Age_group2=2  & D=1 THEN &CAUSE._Age_group2_02_F=1; ELSE &CAUSE._Age_group2_02_F=0; /*0-4�� �� */
IF SEX=2 & Age_group2=3  & D=1 THEN &CAUSE._Age_group2_03_F=1; ELSE &CAUSE._Age_group2_03_F=0; /*5-9�� �� */
IF SEX=2 & Age_group2=4  & D=1 THEN &CAUSE._Age_group2_04_F=1; ELSE &CAUSE._Age_group2_04_F=0; /*10-14�� �� */
IF SEX=2 & Age_group2=5  & D=1 THEN &CAUSE._Age_group2_05_F=1; ELSE &CAUSE._Age_group2_05_F=0; /*15-19�� �� */
IF SEX=2 & Age_group2=6  & D=1 THEN &CAUSE._Age_group2_06_F=1; ELSE &CAUSE._Age_group2_06_F=0; /*20-24�� �� */
IF SEX=2 & Age_group2=7  & D=1 THEN &CAUSE._Age_group2_07_F=1; ELSE &CAUSE._Age_group2_07_F=0; /*25-29�� �� */
IF SEX=2 & Age_group2=8  & D=1 THEN &CAUSE._Age_group2_08_F=1; ELSE &CAUSE._Age_group2_08_F=0; /*30-34�� �� */
IF SEX=2 & Age_group2=9  & D=1 THEN &CAUSE._Age_group2_09_F=1; ELSE &CAUSE._Age_group2_09_F=0; /*35-39�� �� */
IF SEX=2 & Age_group2=10 & D=1 THEN &CAUSE._Age_group2_10_F=1; ELSE &CAUSE._Age_group2_10_F=0; /*40-44�� �� */
IF SEX=2 & Age_group2=11 & D=1 THEN &CAUSE._Age_group2_11_F=1; ELSE &CAUSE._Age_group2_11_F=0; /*45-49�� �� */
IF SEX=2 & Age_group2=12 & D=1 THEN &CAUSE._Age_group2_12_F=1; ELSE &CAUSE._Age_group2_12_F=0; /*50-54�� �� */
IF SEX=2 & Age_group2=13 & D=1 THEN &CAUSE._Age_group2_13_F=1; ELSE &CAUSE._Age_group2_13_F=0; /*55-59�� �� */
IF SEX=2 & Age_group2=14 & D=1 THEN &CAUSE._Age_group2_14_F=1; ELSE &CAUSE._Age_group2_14_F=0; /*60-64�� �� */
IF SEX=2 & Age_group2=15 & D=1 THEN &CAUSE._Age_group2_15_F=1; ELSE &CAUSE._Age_group2_15_F=0; /*65-69�� �� */
IF SEX=2 & Age_group2=16 & D=1 THEN &CAUSE._Age_group2_16_F=1; ELSE &CAUSE._Age_group2_16_F=0; /*70-74�� �� */
IF SEX=2 & Age_group2=17 & D=1 THEN &CAUSE._Age_group2_17_F=1; ELSE &CAUSE._Age_group2_17_F=0; /*75-79�� �� */
IF SEX=2 & Age_group2=18 & D=1 THEN &CAUSE._Age_group2_18_F=1; ELSE &CAUSE._Age_group2_18_F=0; /*80-84�� �� */
IF SEX=2 & Age_group2=19 & D=1 THEN &CAUSE._Age_group2_19_F=1; ELSE &CAUSE._Age_group2_19_F=0; /*85+�� �� */

/*������ ������ ������ ���ؼ� ī��Ʈ �ڷ� ���� -> �� ���ڷ�� ����� ����  �ñ����� ���ϸ� ī��Ʈ (������� B��) (������) */
PROC SQL; CREATE TABLE A.&CAUSE. AS SELECT KEY, SUM(D) AS &CAUSE., 

SUM(&CAUSE._SEX_M) AS  &CAUSE._SEX_M, 
SUM(&CAUSE._SEX_F) AS &CAUSE._SEX_F, 

SUM(&CAUSE._AG00) AS &CAUSE._AG00, 
SUM(&CAUSE._AG0014) AS &CAUSE._AG0014, 
SUM(&CAUSE._AG1564) AS &CAUSE._AG1564, 
SUM(&CAUSE._AG65) AS &CAUSE._AG65, 

SUM(&CAUSE._AG00_M) AS &CAUSE._AG00_M, 
SUM(&CAUSE._AG0014_M) AS &CAUSE._AG0014_M, 
SUM(&CAUSE._AG1564_M) AS &CAUSE._AG1564_M, 
SUM(&CAUSE._AG65_M) AS &CAUSE._AG65_M, 

SUM(&CAUSE._AG00_F) AS &CAUSE._AG00_F, 
SUM(&CAUSE._AG0014_F) AS &CAUSE._AG0014_F, 
SUM(&CAUSE._AG1564_F) AS &CAUSE._AG1564_F, 
SUM(&CAUSE._AG65_F) AS &CAUSE._AG65_F, 

SUM(&CAUSE._Age_group2_02_M) AS &CAUSE._Age_group2_02_M, 
SUM(&CAUSE._Age_group2_03_M) AS &CAUSE._Age_group2_03_M, 
SUM(&CAUSE._Age_group2_04_M) AS &CAUSE._Age_group2_04_M, 
SUM(&CAUSE._Age_group2_05_M) AS &CAUSE._Age_group2_05_M, 
SUM(&CAUSE._Age_group2_06_M) AS &CAUSE._Age_group2_06_M, 
SUM(&CAUSE._Age_group2_07_M) AS &CAUSE._Age_group2_07_M, 
SUM(&CAUSE._Age_group2_08_M) AS &CAUSE._Age_group2_08_M, 
SUM(&CAUSE._Age_group2_09_M) AS &CAUSE._Age_group2_09_M, 
SUM(&CAUSE._Age_group2_10_M) AS &CAUSE._Age_group2_10_M, 
SUM(&CAUSE._Age_group2_11_M) AS &CAUSE._Age_group2_11_M, 
SUM(&CAUSE._Age_group2_12_M) AS &CAUSE._Age_group2_12_M, 
SUM(&CAUSE._Age_group2_13_M) AS &CAUSE._Age_group2_13_M, 
SUM(&CAUSE._Age_group2_14_M) AS &CAUSE._Age_group2_14_M, 
SUM(&CAUSE._Age_group2_15_M) AS &CAUSE._Age_group2_15_M, 
SUM(&CAUSE._Age_group2_16_M) AS &CAUSE._Age_group2_16_M, 
SUM(&CAUSE._Age_group2_17_M) AS &CAUSE._Age_group2_17_M, 
SUM(&CAUSE._Age_group2_18_M) AS &CAUSE._Age_group2_18_M, 
SUM(&CAUSE._Age_group2_19_M) AS &CAUSE._Age_group2_19_M, 
SUM(&CAUSE._Age_group2_02_F) AS &CAUSE._Age_group2_02_F, 
SUM(&CAUSE._Age_group2_03_F) AS &CAUSE._Age_group2_03_F, 
SUM(&CAUSE._Age_group2_04_F) AS &CAUSE._Age_group2_04_F, 
SUM(&CAUSE._Age_group2_05_F) AS &CAUSE._Age_group2_05_F, 
SUM(&CAUSE._Age_group2_06_F) AS &CAUSE._Age_group2_06_F, 
SUM(&CAUSE._Age_group2_07_F) AS &CAUSE._Age_group2_07_F, 
SUM(&CAUSE._Age_group2_08_F) AS &CAUSE._Age_group2_08_F, 
SUM(&CAUSE._Age_group2_09_F) AS &CAUSE._Age_group2_09_F, 
SUM(&CAUSE._Age_group2_10_F) AS &CAUSE._Age_group2_10_F, 
SUM(&CAUSE._Age_group2_11_F) AS &CAUSE._Age_group2_11_F, 
SUM(&CAUSE._Age_group2_12_F) AS &CAUSE._Age_group2_12_F, 
SUM(&CAUSE._Age_group2_13_F) AS &CAUSE._Age_group2_13_F, 
SUM(&CAUSE._Age_group2_14_F) AS &CAUSE._Age_group2_14_F, 
SUM(&CAUSE._Age_group2_15_F) AS &CAUSE._Age_group2_15_F, 
SUM(&CAUSE._Age_group2_16_F) AS &CAUSE._Age_group2_16_F, 
SUM(&CAUSE._Age_group2_17_F) AS &CAUSE._Age_group2_17_F, 
SUM(&CAUSE._Age_group2_18_F) AS &CAUSE._Age_group2_18_F, 
SUM(&CAUSE._Age_group2_19_F) AS &CAUSE._Age_group2_19_F  FROM A.Z2 GROUP BY KEY;QUIT;



/*���ϸ� ī��Ʈ �� �ڷḦ ������ �ñ��� �ڷ�� merge�ϱ� 
  (missing�� ä���ֱ� ���ؼ�)*/
/*������ ���� ������ �ñ���+��¥ �ڷḦ �������� LEFT JOIN */
PROC SQL; CREATE TABLE A.&CAUSE._Daily_Count AS SELECT * FROM A.SGGDATE AS A  LEFT JOIN A.&CAUSE. AS B ON A.KEY=B.KEY; QUIT;

/*MISSING VALUE 0���� ä���ֱ� */
DATA  A.&CAUSE._Daily_Count; 

RETAIN KEY DATE YEAR MONTH DAY SIDO SGG  &cause. &cause._SEX_M &cause._SEX_F &cause._AG00 &cause._AG0014 &cause._AG1564 &cause._AG65 &cause._AG00_M &cause._AG0014_M 
&cause._AG1564_M &cause._AG65_M &cause._AG00_F &cause._AG0014_F &cause._AG1564_F &cause._AG65_F;

SET  A.&CAUSE._Daily_Count;
IF &CAUSE.="." THEN &CAUSE.=0; 
IF &CAUSE._SEX_M="." THEN &CAUSE._SEX_M=0;
IF &CAUSE._SEX_F="." THEN &CAUSE._SEX_F=0;

IF &CAUSE._AG00="." THEN &CAUSE._AG00=0;
IF &CAUSE._AG0014="." THEN &CAUSE._AG0014=0;
IF &CAUSE._AG1564="." THEN &CAUSE._AG1564=0;
IF &CAUSE._AG65="." THEN &CAUSE._AG65=0;


IF &CAUSE._AG00_M   ="." THEN &CAUSE._AG00_M=0;
IF &CAUSE._AG0014_M="." THEN &CAUSE._AG0014_M=0;
IF &CAUSE._AG1564_M="." THEN &CAUSE._AG1564_M=0;
IF &CAUSE._AG65_M  ="."  THEN &CAUSE._AG65_M=0;

IF &CAUSE._AG00_F   ="." THEN &CAUSE._AG00_F=0;
IF &CAUSE._AG0014_F="." THEN &CAUSE._AG0014_F=0;
IF &CAUSE._AG1564_F="." THEN &CAUSE._AG1564_F=0;
IF &CAUSE._AG65_F  ="."  THEN &CAUSE._AG65_F=0;

IF &CAUSE._Age_group2_02_M  ='.'  THEN &CAUSE._Age_group2_02_M=0;
IF &CAUSE._Age_group2_03_M  ='.'  THEN &CAUSE._Age_group2_03_M=0;
IF &CAUSE._Age_group2_04_M  ='.'  THEN &CAUSE._Age_group2_04_M=0;
IF &CAUSE._Age_group2_05_M  ='.'  THEN &CAUSE._Age_group2_05_M=0;
IF &CAUSE._Age_group2_06_M  ='.'  THEN &CAUSE._Age_group2_06_M=0;
IF &CAUSE._Age_group2_07_M  ='.'  THEN &CAUSE._Age_group2_07_M=0;
IF &CAUSE._Age_group2_08_M  ='.'  THEN &CAUSE._Age_group2_08_M=0;
IF &CAUSE._Age_group2_09_M  ='.'  THEN &CAUSE._Age_group2_09_M=0;
IF &CAUSE._Age_group2_10_M  ='.'  THEN &CAUSE._Age_group2_10_M=0;
IF &CAUSE._Age_group2_11_M  ='.'  THEN &CAUSE._Age_group2_11_M=0;
IF &CAUSE._Age_group2_12_M  ='.'  THEN &CAUSE._Age_group2_12_M=0;
IF &CAUSE._Age_group2_13_M  ='.'  THEN &CAUSE._Age_group2_13_M=0;
IF &CAUSE._Age_group2_14_M  ='.'  THEN &CAUSE._Age_group2_14_M=0;
IF &CAUSE._Age_group2_15_M  ='.'  THEN &CAUSE._Age_group2_15_M=0;
IF &CAUSE._Age_group2_16_M  ='.'  THEN &CAUSE._Age_group2_16_M=0;
IF &CAUSE._Age_group2_17_M  ='.'  THEN &CAUSE._Age_group2_17_M=0;
IF &CAUSE._Age_group2_18_M  ='.'  THEN &CAUSE._Age_group2_18_M=0;
IF &CAUSE._Age_group2_19_M  ='.'  THEN &CAUSE._Age_group2_19_M=0;
IF &CAUSE._Age_group2_02_F  ='.'  THEN &CAUSE._Age_group2_02_F=0;
IF &CAUSE._Age_group2_03_F  ='.'  THEN &CAUSE._Age_group2_03_F=0;
IF &CAUSE._Age_group2_04_F  ='.'  THEN &CAUSE._Age_group2_04_F=0;
IF &CAUSE._Age_group2_05_F  ='.'  THEN &CAUSE._Age_group2_05_F=0;
IF &CAUSE._Age_group2_06_F  ='.'  THEN &CAUSE._Age_group2_06_F=0;
IF &CAUSE._Age_group2_07_F  ='.'  THEN &CAUSE._Age_group2_07_F=0;
IF &CAUSE._Age_group2_08_F  ='.'  THEN &CAUSE._Age_group2_08_F=0;
IF &CAUSE._Age_group2_09_F  ='.'  THEN &CAUSE._Age_group2_09_F=0;
IF &CAUSE._Age_group2_10_F  ='.'  THEN &CAUSE._Age_group2_10_F=0;
IF &CAUSE._Age_group2_11_F  ='.'  THEN &CAUSE._Age_group2_11_F=0;
IF &CAUSE._Age_group2_12_F  ='.'  THEN &CAUSE._Age_group2_12_F=0;
IF &CAUSE._Age_group2_13_F  ='.'  THEN &CAUSE._Age_group2_13_F=0;
IF &CAUSE._Age_group2_14_F  ='.'  THEN &CAUSE._Age_group2_14_F=0;
IF &CAUSE._Age_group2_15_F  ='.'  THEN &CAUSE._Age_group2_15_F=0;
IF &CAUSE._Age_group2_16_F  ='.'  THEN &CAUSE._Age_group2_16_F=0;
IF &CAUSE._Age_group2_17_F  ='.'  THEN &CAUSE._Age_group2_17_F=0;
IF &CAUSE._Age_group2_18_F  ='.'  THEN &CAUSE._Age_group2_18_F=0;
IF &CAUSE._Age_group2_19_F  ='.'  THEN &CAUSE._Age_group2_19_F=0;



/*��¥ �� �õ�, �ñ��� ���� */
DATE=SUBSTR(KEY,1,8);
YEAR=SUBSTR(KEY,1,4);
MONTH=SUBSTR(KEY,5,2);
DAY =SUBSTR(KEY,7,2);
SIDO=SUBSTR(KEY,10,2);
SGG=SUBSTR(KEY,10,5); /*�ñ��� ���ڷ� */
RUN;
%MEND;

/*�ñ����� ���ϸ� ��� �ڷ� -��ȯ���� */
%DEATH(TOT);
%DEATH(NON_ACC);
%DEATH(RESP);
%DEATH(ALRI);
%DEATH(INFL);;
%DEATH(CVD);
%DEATH(CANO);
%DEATH(MISC);
%DEATH(LUNGC);
%DEATH(LIVC);
%DEATH(SUID);
%DEATH(ALZ);
%DEATH(ATHER);
%DEATH(CERBV);
%DEATH(DM);
%DEATH(EAR);
%DEATH(ENDO);
%DEATH(EYE);
%DEATH(HTN);
%DEATH(IHD);
%DEATH(KIDNEY);
%DEATH(LRD);
%DEATH(MENTAL);
%DEATH(OTHERCVD);
%DEATH(OTHERHEART);
%DEATH(OTHERKIDNEY);
%DEATH(OTHERMENTAL);
%DEATH(OTHERNERV);
%DEATH(OTHERRESP);
%DEATH(RHEUM);

/*�ñ��� üũ ��ü�� CVD�� */
PROC FREQ DATA=A.TOT_R; TABLES SGG; RUN;
PROC FREQ DATA=A.CVD_R; TABLES SGG; RUN;

/*��ü ī��Ʈ �� */
%MACRO CNT(CAUSE);
/*��ȯ�� ���� ��� �� �հ� */
PROC SQL; CREATE TABLE A.&CAUSE._COUNT AS SELECT SUM(&CAUSE.) AS &CAUSE. , SUM(&CAUSE._SEX_M) AS &CAUSE._SEX_M , 
SUM(&CAUSE._SEX_F) AS &CAUSE._SEX_F , SUM(&CAUSE._AG00) AS &CAUSE._AG00,
SUM(&CAUSE._AG0014) AS &CAUSE._AG0014, SUM(&CAUSE._AG1564) AS &CAUSE._AG1564, SUM(&CAUSE._AG65) AS &CAUSE._AG65,

SUM(&CAUSE._AG00_M) AS &CAUSE._AG00_M       ,  SUM(&CAUSE._AG0014_M) AS &CAUSE._AG0014_M , 
SUM(&CAUSE._AG1564_M) AS &CAUSE._AG1564_M ,  SUM(&CAUSE._AG65_M) AS &CAUSE._AG65_M , 
SUM(&CAUSE._AG00_F) AS &CAUSE._AG00_F        ,  SUM(&CAUSE._AG0014_F) AS &CAUSE._AG0014_F , 
SUM(&CAUSE._AG1564_F) AS &CAUSE._AG1564_F ,  SUM(&CAUSE._AG65_F) AS &CAUSE._AG65_F  FROM A.&CAUSE._Daily_Count  ; QUIT;

/*�ñ����� ��ȯ�� ���� ��� �հ�  */
PROC SQL; CREATE TABLE A.&CAUSE._SGG_Count AS SELECT SGG, SUM(&CAUSE.) AS &CAUSE. , SUM(&CAUSE._SEX_M) AS &CAUSE._SEX_M , 
SUM(&CAUSE._SEX_F) AS &CAUSE._SEX_F , SUM(&CAUSE._AG00) AS &CAUSE._AG00,
SUM(&CAUSE._AG0014) AS &CAUSE._AG0014, SUM(&CAUSE._AG1564) AS &CAUSE._AG1564, SUM(&CAUSE._AG65) AS &CAUSE._AG65,
SUM(&CAUSE._AG00_M) AS &CAUSE._AG00_M ,  SUM(&CAUSE._AG0014_M) AS &CAUSE._AG0014_M , 
SUM(&CAUSE._AG1564_M) AS &CAUSE._AG1564_M ,  SUM(&CAUSE._AG65_M) AS &CAUSE._AG65_M , 
SUM(&CAUSE._AG00_F) AS &CAUSE._AG00_F ,  SUM(&CAUSE._AG0014_F) AS &CAUSE._AG0014_F , 
SUM(&CAUSE._AG1564_F) AS &CAUSE._AG1564_F ,  SUM(&CAUSE._AG65_F) AS &CAUSE._AG65_F  FROM A.&CAUSE._Daily_Count  GROUP BY SGG ; QUIT;

/*������ ��ȯ�� ���� ���  �հ� */
PROC SQL; CREATE TABLE A.&CAUSE._YEAR_Count AS SELECT YEAR, SUM(&CAUSE.) AS &CAUSE. , SUM(&CAUSE._SEX_M) AS &CAUSE._SEX_M , 
SUM(&CAUSE._SEX_F) AS &CAUSE._SEX_F , SUM(&CAUSE._AG00) AS &CAUSE._AG00,
SUM(&CAUSE._AG0014) AS &CAUSE._AG0014, SUM(&CAUSE._AG1564) AS &CAUSE._AG1564, SUM(&CAUSE._AG65) AS &CAUSE._AG65,
SUM(&CAUSE._AG00_M) AS &CAUSE._AG00_M ,  SUM(&CAUSE._AG0014_M) AS &CAUSE._AG0014_M , 
SUM(&CAUSE._AG1564_M) AS &CAUSE._AG1564_M ,  SUM(&CAUSE._AG65_M) AS &CAUSE._AG65_M , 
SUM(&CAUSE._AG00_F) AS &CAUSE._AG00_F ,  SUM(&CAUSE._AG0014_F) AS &CAUSE._AG0014_F , 
SUM(&CAUSE._AG1564_F) AS &CAUSE._AG1564_F ,  SUM(&CAUSE._AG65_F) AS &CAUSE._AG65_F  FROM A.&CAUSE._Daily_Count GROUP BY YEAR ; QUIT;

/*������*�ñ�����  ��ȯ�� ���� ���  �հ� */
PROC SQL; CREATE TABLE A.&CAUSE._YY_SGG_Count AS SELECT YEAR,SGG, SUM(&CAUSE.) AS &CAUSE. , SUM(&CAUSE._SEX_M) AS &CAUSE._SEX_M , 
SUM(&CAUSE._SEX_F) AS &CAUSE._SEX_F , SUM(&CAUSE._AG00) AS &CAUSE._AG00,
SUM(&CAUSE._AG0014) AS &CAUSE._AG0014, SUM(&CAUSE._AG1564) AS &CAUSE._AG1564, SUM(&CAUSE._AG65) AS &CAUSE._AG65,
SUM(&CAUSE._AG00_M) AS &CAUSE._AG00_M ,  SUM(&CAUSE._AG0014_M) AS &CAUSE._AG0014_M , 
SUM(&CAUSE._AG1564_M) AS &CAUSE._AG1564_M ,  SUM(&CAUSE._AG65_M) AS &CAUSE._AG65_M , 
SUM(&CAUSE._AG00_F) AS &CAUSE._AG00_F ,  SUM(&CAUSE._AG0014_F) AS &CAUSE._AG0014_F , 
SUM(&CAUSE._AG1564_F) AS &CAUSE._AG1564_F ,  SUM(&CAUSE._AG65_F) AS &CAUSE._AG65_F , 

SUM(&CAUSE._Age_group2_02_M) AS &CAUSE._Age_group2_02_M, 
SUM(&CAUSE._Age_group2_03_M) AS &CAUSE._Age_group2_03_M, 
SUM(&CAUSE._Age_group2_04_M) AS &CAUSE._Age_group2_04_M, 
SUM(&CAUSE._Age_group2_05_M) AS &CAUSE._Age_group2_05_M, 
SUM(&CAUSE._Age_group2_06_M) AS &CAUSE._Age_group2_06_M, 
SUM(&CAUSE._Age_group2_07_M) AS &CAUSE._Age_group2_07_M, 
SUM(&CAUSE._Age_group2_08_M) AS &CAUSE._Age_group2_08_M, 
SUM(&CAUSE._Age_group2_09_M) AS &CAUSE._Age_group2_09_M, 
SUM(&CAUSE._Age_group2_10_M) AS &CAUSE._Age_group2_10_M, 
SUM(&CAUSE._Age_group2_11_M) AS &CAUSE._Age_group2_11_M, 
SUM(&CAUSE._Age_group2_12_M) AS &CAUSE._Age_group2_12_M, 
SUM(&CAUSE._Age_group2_13_M) AS &CAUSE._Age_group2_13_M, 
SUM(&CAUSE._Age_group2_14_M) AS &CAUSE._Age_group2_14_M, 
SUM(&CAUSE._Age_group2_15_M) AS &CAUSE._Age_group2_15_M, 
SUM(&CAUSE._Age_group2_16_M) AS &CAUSE._Age_group2_16_M, 
SUM(&CAUSE._Age_group2_17_M) AS &CAUSE._Age_group2_17_M, 
SUM(&CAUSE._Age_group2_18_M) AS &CAUSE._Age_group2_18_M, 
SUM(&CAUSE._Age_group2_19_M) AS &CAUSE._Age_group2_19_M, 
SUM(&CAUSE._Age_group2_02_F) AS &CAUSE._Age_group2_02_F, 
SUM(&CAUSE._Age_group2_03_F) AS &CAUSE._Age_group2_03_F, 
SUM(&CAUSE._Age_group2_04_F) AS &CAUSE._Age_group2_04_F, 
SUM(&CAUSE._Age_group2_05_F) AS &CAUSE._Age_group2_05_F, 
SUM(&CAUSE._Age_group2_06_F) AS &CAUSE._Age_group2_06_F, 
SUM(&CAUSE._Age_group2_07_F) AS &CAUSE._Age_group2_07_F, 
SUM(&CAUSE._Age_group2_08_F) AS &CAUSE._Age_group2_08_F, 
SUM(&CAUSE._Age_group2_09_F) AS &CAUSE._Age_group2_09_F, 
SUM(&CAUSE._Age_group2_10_F) AS &CAUSE._Age_group2_10_F, 
SUM(&CAUSE._Age_group2_11_F) AS &CAUSE._Age_group2_11_F, 
SUM(&CAUSE._Age_group2_12_F) AS &CAUSE._Age_group2_12_F, 
SUM(&CAUSE._Age_group2_13_F) AS &CAUSE._Age_group2_13_F, 
SUM(&CAUSE._Age_group2_14_F) AS &CAUSE._Age_group2_14_F, 
SUM(&CAUSE._Age_group2_15_F) AS &CAUSE._Age_group2_15_F, 
SUM(&CAUSE._Age_group2_16_F) AS &CAUSE._Age_group2_16_F, 
SUM(&CAUSE._Age_group2_17_F) AS &CAUSE._Age_group2_17_F, 
SUM(&CAUSE._Age_group2_18_F) AS &CAUSE._Age_group2_18_F, 
SUM(&CAUSE._Age_group2_19_F) AS &CAUSE._Age_group2_19_F

FROM A.&CAUSE._Daily_Count GROUP BY YEAR,SGG ; QUIT;

%MEND;
/*��ȯ�� ��ü �ñ�����, ������, �ñ����� ������ ī��Ʈ*/
%CNT(TOT);
%CNT(NON_ACC);
%CNT(RESP);
%CNT(ALRI);
%CNT(INFL);;
%CNT(CVD);
%CNT(CANO);
%CNT(MISC);
%CNT(LUNGC);
%CNT(LIVC);
%CNT(SUID);
%CNT(ALZ);
%CNT(ATHER);
%CNT(CERBV);
%CNT(DM);
%CNT(EAR);
%CNT(ENDO);
%CNT(EYE);
%CNT(HTN);
%CNT(IHD);
%CNT(KIDNEY);
%CNT(LRD);
%CNT(MENTAL);
%CNT(OTHERCVD);
%CNT(OTHERHEART);
%CNT(OTHERKIDNEY);
%CNT(OTHERMENTAL);
%CNT(OTHERNERV);
%CNT(OTHERRESP);
%CNT(RHEUM);

/*������ �ñ��� �ڷῡ�� Ư�� �ñ��� �ϳ��� ���� */

data z; set a.Tot_yy_sgg_count;
if sgg=11010; run;

/* ������ �ñ��� ������ �����ɺ� */ 

/* �α� �о���� */

/*������ �α�*/
PROC IMPORT OUT= WORK.pop 
            DATAFILE= "F:\2020projects\bae\KEITI\research\2.���\B�� ����ڷ�(2010-2019)\�����α�_�ñ���_final.csv" 
            DBMS=CSV REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
RUN;

/*������ �α� */ 
data pop2; 
	set pop; 
	if sex="����"; 
	if code_b>100; 
	keep code_b sex age_group P2010-P2019; 
run; 
proc means data=pop2 noprint sum; 
	class code_b age_group;
	var p2010-p2019; 
	output out=pop3 sum(p2010-p2019)=p2010-p2019;
run; 

data pop4; 
	set pop3;
	if _type_=3; 
if age_group='0 - 4��' then age_group2=2; 
if age_group='5 - 9��' then age_group2=3; 
if age_group='10 - 14��' then age_group2=4; 
if age_group='15 - 19��' then age_group2=5; 
if age_group='20 - 24��' then age_group2=6; 
if age_group='25 - 29��' then age_group2=7; 
if age_group='30 - 34��' then age_group2=8; 
if age_group='35 - 39��' then age_group2=9; 
if age_group='40 - 44��' then age_group2=10; 
if age_group='45 - 49��' then age_group2=11; 
if age_group='50 - 54��' then age_group2=12; 
if age_group='55 - 59��' then age_group2=13; 
if age_group='60 - 64��' then age_group2=14; 
if age_group='65 - 69��' then age_group2=15; 
if age_group='70 - 74��' then age_group2=16; 
if age_group='75 - 79��' then age_group2=17; 
if age_group='80 - 84��' then age_group2=18; 
if age_group='85�� �̻�' then age_group2=19; 

rename code_b=sgg; 
drop _type_ _freq_; 
run; 

proc sort data=pop4; by sgg age_group2; run; 

PROC TRANSPOSE DATA=Pop4 OUT=pop4_trans prefix=pop_male_; 
	BY sgg;
	/*VAR &var. ; */
	ID age_group2; 
RUN;

data pop4_male;
 	retain year; 
	set pop4_trans; 
	by sgg; 
	drop _name_; 
	
	if first.sgg then year=2010;
	else year=year+1;  
run; 
 
/*���� */ 

data pop2; 
	set pop; 
	if sex="����"; 
	if code_b>100; 
	keep code_b sex age_group P2010-P2019; 
run; 
proc means data=pop2 noprint sum; 
	class code_b age_group;
	var p2010-p2019; 
	output out=pop3 sum(p2010-p2019)=p2010-p2019;
run; 

data pop4; 
	set pop3;
	if _type_=3; 
if age_group='0 - 4��' then age_group2=2; 
if age_group='5 - 9��' then age_group2=3; 
if age_group='10 - 14��' then age_group2=4; 
if age_group='15 - 19��' then age_group2=5; 
if age_group='20 - 24��' then age_group2=6; 
if age_group='25 - 29��' then age_group2=7; 
if age_group='30 - 34��' then age_group2=8; 
if age_group='35 - 39��' then age_group2=9; 
if age_group='40 - 44��' then age_group2=10; 
if age_group='45 - 49��' then age_group2=11; 
if age_group='50 - 54��' then age_group2=12; 
if age_group='55 - 59��' then age_group2=13; 
if age_group='60 - 64��' then age_group2=14; 
if age_group='65 - 69��' then age_group2=15; 
if age_group='70 - 74��' then age_group2=16; 
if age_group='75 - 79��' then age_group2=17; 
if age_group='80 - 84��' then age_group2=18; 
if age_group='85�� �̻�' then age_group2=19; 

rename code_b=sgg; 
drop _type_ _freq_; 

run; 

proc sort data=pop4; by sgg age_group2; run; 

PROC TRANSPOSE DATA=Pop4 OUT=pop4_trans prefix=pop_female_; 
	BY sgg;
	/*VAR &var. ; */
	ID age_group2; 
RUN;

data pop4_female;
 	retain year; 
	set pop4_trans; 
	by sgg; 
	drop _name_; 
	
	if first.sgg then year=2010;
	else year=year+1;  
run; 
 

/*ǥ�� �α� */ 
/* �õ����� ���� �ҷ� �б� */
PROC IMPORT OUT= WORK.pop 
            DATAFILE= "F:\2020projects\bae\KEITI\research\2.���\B�� ����ڷ�(2010-2019)\�����α�_�õ�_final.csv" 
            DBMS=CSV REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
RUN;


data pop2; 
	set pop; 
	if sex="����"; 
	if code_b<100; 
	if P2005 ^=.;
	*keep code_b sex age_group P2005; 
	drop P2010-P2019; 
	KEY=COMPRESS(sigu)||("-")||COMPRESS(code_b);
run; 
proc means data=pop2 noprint sum; 
	class age_group;
	var p2005; 
	output out=pop3 sum(p2005)=p2005;
run; 

data pop4; 
	set pop3;
	if _type_=1; 
if age_group='0 - 4��' then age_group2=2; 
if age_group='5 - 9��' then age_group2=3; 
if age_group='10 - 14��' then age_group2=4; 
if age_group='15 - 19��' then age_group2=5; 
if age_group='20 - 24��' then age_group2=6; 
if age_group='25 - 29��' then age_group2=7; 
if age_group='30 - 34��' then age_group2=8; 
if age_group='35 - 39��' then age_group2=9; 
if age_group='40 - 44��' then age_group2=10; 
if age_group='45 - 49��' then age_group2=11; 
if age_group='50 - 54��' then age_group2=12; 
if age_group='55 - 59��' then age_group2=13; 
if age_group='60 - 64��' then age_group2=14; 
if age_group='65 - 69��' then age_group2=15; 
if age_group='70 - 74��' then age_group2=16; 
if age_group='75 - 79��' then age_group2=17; 
if age_group='80 - 84��' then age_group2=18; 
if age_group='85�� �̻�' then age_group2=19; 

rename code_b=sgg; 
drop _type_ _freq_; 
run; 

proc sort data=pop4; by age_group2; run; 

PROC TRANSPOSE DATA=Pop4 OUT=pop4_trans prefix=stdpop_male_; 
	ID age_group2; 
RUN;

data stdpop4_male;
	set pop4_trans; 
	drop _name_; 
run; 
 
/*���� */ 

data pop2; 
	set pop; 
	if sex="����"; 
	if code_b<100; 
	if P2005 ^=.;
	*keep code_b sex age_group P2005; 
	drop P2010-P2019; 
	KEY=COMPRESS(sigu)||("-")||COMPRESS(code_b);run; 
proc freq data=pop2; table sido; run; 

proc means data=pop2 noprint sum; 
	class age_group;
	var p2005; 
	output out=pop3 sum( p2005)= p2005;
run; 


data pop4; 
	set pop3;
	if _type_=1; 
if age_group='0 - 4��' then age_group2=2; 
if age_group='5 - 9��' then age_group2=3; 
if age_group='10 - 14��' then age_group2=4; 
if age_group='15 - 19��' then age_group2=5; 
if age_group='20 - 24��' then age_group2=6; 
if age_group='25 - 29��' then age_group2=7; 
if age_group='30 - 34��' then age_group2=8; 
if age_group='35 - 39��' then age_group2=9; 
if age_group='40 - 44��' then age_group2=10; 
if age_group='45 - 49��' then age_group2=11; 
if age_group='50 - 54��' then age_group2=12; 
if age_group='55 - 59��' then age_group2=13; 
if age_group='60 - 64��' then age_group2=14; 
if age_group='65 - 69��' then age_group2=15; 
if age_group='70 - 74��' then age_group2=16; 
if age_group='75 - 79��' then age_group2=17; 
if age_group='80 - 84��' then age_group2=18; 
if age_group='85�� �̻�' then age_group2=19; 

rename code_b=sgg; 
drop _type_ _freq_; 

run; 

proc sort data=pop4; by age_group2; run; 

PROC TRANSPOSE DATA=Pop4 OUT=pop4_trans prefix=stdpop_female_; 
	ID age_group2; 
RUN;

data stdpop4_female;
 	set pop4_trans; 
	drop _name_; 
run; 
 
proc sort data=pop4_male ; by year sgg; 
proc sort data=pop4_female; by year sgg; run; 

data pop6; 
	merge pop4_male pop4_female; 
	by year sgg; 
run; 

data stdpop6; 
	merge stdpop4_male stdpop4_female; 
run; 
/*48683039.5*/

data a.pop7; 	
	format key $25.;
	set pop6; 
	if _n_ =1 then set stdpop6; 
	KEY=COMPRESS(year)||("-")||COMPRESS(sgg);
	drop year sgg; 
run;

/***********ǥ��ȭ����� ��� *****************/


proc freq data=a.tot_yy_sgg_count; table sgg; run; 

%macro smr (dis=); 

data dis; 
	format key $25.; 
	set a.&dis._yy_sgg_count ; 
	KEY=COMPRESS(year)||("-")||COMPRESS(sgg);
	if sgg=. then delete; 
	drop year sgg; 
run; 

proc sort data=dis; by key; 
proc sort data=a.pop7; by key; run; 

data dis2; 
	set dis; 
	/*death male+female */ 
		array all(18) &dis._Age_group2_02_T &dis._Age_group2_03_T	&dis._Age_group2_04_T	&dis._Age_group2_05_T	&dis._Age_group2_06_T	
								&dis._Age_group2_07_T	&dis._Age_group2_08_T	&dis._Age_group2_09_T	&dis._Age_group2_10_T	&dis._Age_group2_11_T	
								&dis._Age_group2_12_T	&dis._Age_group2_13_T	&dis._Age_group2_14_T	&dis._Age_group2_15_T	&dis._Age_group2_16_T
								&dis._Age_group2_17_T	&dis._Age_group2_18_T	&dis._Age_group2_19_T	;
		array male(18) &dis._Age_group2_02_M &dis._Age_group2_03_M	&dis._Age_group2_04_M	&dis._Age_group2_05_M	&dis._Age_group2_06_M	
								&dis._Age_group2_07_M	&dis._Age_group2_08_M	&dis._Age_group2_09_M	&dis._Age_group2_10_M	&dis._Age_group2_11_M	
								&dis._Age_group2_12_M	&dis._Age_group2_13_M	&dis._Age_group2_14_M	&dis._Age_group2_15_M	&dis._Age_group2_16_M
								&dis._Age_group2_17_M	&dis._Age_group2_18_M	&dis._Age_group2_19_M	;
		array female(18) &dis._Age_group2_02_F &dis._Age_group2_03_F	&dis._Age_group2_04_F	&dis._Age_group2_05_F	&dis._Age_group2_06_F	
								&dis._Age_group2_07_F	&dis._Age_group2_08_F	&dis._Age_group2_09_F	&dis._Age_group2_10_F	&dis._Age_group2_11_F	
								&dis._Age_group2_12_F	&dis._Age_group2_13_F	&dis._Age_group2_14_F	&dis._Age_group2_15_F	&dis._Age_group2_16_F
								&dis._Age_group2_17_F	&dis._Age_group2_18_F	&dis._Age_group2_19_F	;
		
		do k=1 to 18; 
			all(k)=male(k)+female(k); 
		end; 

data a.pop7_2; 
	set a.pop7; 

	/* populuation male+female */ 
	array allpop(18) pop_all_2 pop_all_3	pop_all_4	pop_all_5	pop_all_6	pop_all_7	pop_all_8	pop_all_9	pop_all_10	
						pop_all_11	pop_all_12	pop_all_13	pop_all_14	pop_all_15	pop_all_16	pop_all_17	pop_all_18	pop_all_19; 
	array malepop(18) pop_male_2 pop_male_3	pop_male_4	pop_male_5	pop_male_6	pop_male_7	pop_male_8	pop_male_9	pop_male_10	
						pop_male_11	pop_male_12	pop_male_13	pop_male_14	pop_male_15	pop_male_16	pop_male_17	pop_male_18	pop_male_19	; 
	array femalepop(18) pop_female_2 pop_female_3	pop_female_4	pop_female_5	pop_female_6	pop_female_7	pop_female_8	pop_female_9	pop_female_10	
						pop_female_11	pop_female_12	pop_female_13	pop_female_14	pop_female_15	pop_female_16	pop_female_17	pop_female_18	pop_female_19	; 
	do k=1 to 18; 
			allpop(k)=malepop(k)+femalepop(k); 
    end; 

	/* std populuation male+female */ 
	array allstdpop(18) stdpop_all_2 stdpop_all_3	stdpop_all_4	stdpop_all_5	stdpop_all_6	stdpop_all_7	stdpop_all_8	stdpop_all_9	stdpop_all_10	
						stdpop_all_11	stdpop_all_12	stdpop_all_13	stdpop_all_14	stdpop_all_15	stdpop_all_16	stdpop_all_17	stdpop_all_18	stdpop_all_19; 
	array malestdpop(18) stdpop_male_2 stdpop_male_3	stdpop_male_4	stdpop_male_5	stdpop_male_6	stdpop_male_7	stdpop_male_8	stdpop_male_9	stdpop_male_10	
						stdpop_male_11	stdpop_male_12	stdpop_male_13	stdpop_male_14	stdpop_male_15	stdpop_male_16	stdpop_male_17	stdpop_male_18	stdpop_male_19	; 
	array femalestdpop(18) stdpop_female_2 stdpop_female_3	stdpop_female_4	stdpop_female_5	stdpop_female_6	stdpop_female_7	stdpop_female_8	stdpop_female_9	stdpop_female_10	
						stdpop_female_11	stdpop_female_12	stdpop_female_13	stdpop_female_14	stdpop_female_15	stdpop_female_16	stdpop_female_17	stdpop_female_18	stdpop_female_19	; 
	do k=1 to 18; 
			allstdpop(k)=malestdpop(k)+femalestdpop(k); 
	end; 
run; 

run; 
data calc; 
	format year 4. sgg $12.; 
	merge dis2 a.pop7_2  ; 
	by key; 
	year=substr(key, 1, 4); 
	sgg=substr(key, 6, 5); 
run; 

proc contents data=calc out=cont; run;

data calc2; 
	set calc; 
	array death(36) &dis._Age_group2_02_M &dis._Age_group2_03_M	&dis._Age_group2_04_M	&dis._Age_group2_05_M	&dis._Age_group2_06_M	
								&dis._Age_group2_07_M	&dis._Age_group2_08_M	&dis._Age_group2_09_M	&dis._Age_group2_10_M	&dis._Age_group2_11_M	
								&dis._Age_group2_12_M	&dis._Age_group2_13_M	&dis._Age_group2_14_M	&dis._Age_group2_15_M	&dis._Age_group2_16_M
								&dis._Age_group2_17_M	&dis._Age_group2_18_M	&dis._Age_group2_19_M	
								&dis._Age_group2_02_F	&dis._Age_group2_03_F	&dis._Age_group2_04_F	&dis._Age_group2_05_F	&dis._Age_group2_06_F	
								&dis._Age_group2_07_F	&dis._Age_group2_08_F	&dis._Age_group2_09_F	&dis._Age_group2_10_F	&dis._Age_group2_11_F	
								&dis._Age_group2_12_F	&dis._Age_group2_13_F	&dis._Age_group2_14_F	&dis._Age_group2_15_F	&dis._Age_group2_16_F	
								&dis._Age_group2_17_F	&dis._Age_group2_18_F	&dis._Age_group2_19_F	; 


array pop(36) pop_male_2 pop_male_3	pop_male_4	pop_male_5	pop_male_6	pop_male_7	pop_male_8	pop_male_9	pop_male_10	pop_male_11	
						pop_male_12	pop_male_13	pop_male_14	pop_male_15	pop_male_16	pop_male_17	pop_male_18	pop_male_19	
						pop_female_2	pop_female_3	pop_female_4	pop_female_5	pop_female_6	pop_female_7	pop_female_8	pop_female_9	pop_female_10	
						pop_female_11	pop_female_12	pop_female_13	pop_female_14	pop_female_15	pop_female_16	pop_female_17	pop_female_18	pop_female_19; 

array stdpop(36)  stdpop_male_2 stdpop_male_3	stdpop_male_4	stdpop_male_5	stdpop_male_6	stdpop_male_7	stdpop_male_8	stdpop_male_9	stdpop_male_10	
						stdpop_male_11	stdpop_male_12	stdpop_male_13	stdpop_male_14	stdpop_male_15	stdpop_male_16	stdpop_male_17	stdpop_male_18	stdpop_male_19	
						stdpop_female_2	stdpop_female_3	stdpop_female_4	stdpop_female_5	stdpop_female_6	stdpop_female_7	stdpop_female_8	stdpop_female_9	stdpop_female_10	
						stdpop_female_11	stdpop_female_12	stdpop_female_13	stdpop_female_14	stdpop_female_15	stdpop_female_16	stdpop_female_17	stdpop_female_18	
						stdpop_female_19; 

array mr(36) MR_2_M MR_3_M	MR_4_M	MR_5_M	MR_6_M	MR_7_M	MR_8_M	MR_9_M	MR_10_M	MR_11_M	MR_12_M	MR_13_M	MR_14_M	MR_15_M	
					MR_16_M	MR_17_M	MR_18_M	MR_19_M	
					MR_2_F	MR_3_F	MR_4_F	MR_5_F	MR_6_F	MR_7_F	MR_8_F	MR_9_F	MR_10_F	MR_11_F	MR_12_F	MR_13_F	MR_14_F	MR_15_F	
					MR_16_F	MR_17_F	MR_18_F	MR_19_F	; 



do k = 1 to 36; 
	
	mr(k) = death(k)/pop(k) *stdpop(k);  /*���ɺ� ����� * ǥ���α�*/
end; 

run; 

data a.&dis._yy_sgg_SMR_pop;
	set calc2; 
	&dis._smr=sum(of MR_2_M MR_3_M	MR_4_M	MR_5_M	MR_6_M	MR_7_M	MR_8_M	MR_9_M	MR_10_M	MR_11_M	MR_12_M	MR_13_M	MR_14_M	MR_15_M	
					MR_16_M	MR_17_M	MR_18_M	MR_19_M	
					MR_2_F	MR_3_F	MR_4_F	MR_5_F	MR_6_F	MR_7_F	MR_8_F	MR_9_F	MR_10_F	MR_11_F	MR_12_F	MR_13_F	MR_14_F	MR_15_F	
					MR_16_F	MR_17_F	MR_18_F	MR_19_F) / 48683040 * 100000; 
	drop k; 
	if &dis._smr^=.; 
run; 

data a.&dis._yy_sgg_SMR;
	set a.&dis._yy_sgg_SMR_pop;
	drop &dis._Age_group2_02_M -- MR_19_F	;
run; 




/* age only adjusted smr */


data calc2_ageonly; 
	set calc; 
	array death(18) &dis._Age_group2_02_T &dis._Age_group2_03_T	&dis._Age_group2_04_T	&dis._Age_group2_05_T	&dis._Age_group2_06_T	
								&dis._Age_group2_07_T	&dis._Age_group2_08_T	&dis._Age_group2_09_T	&dis._Age_group2_10_T	&dis._Age_group2_11_T	
								&dis._Age_group2_12_T	&dis._Age_group2_13_T	&dis._Age_group2_14_T	&dis._Age_group2_15_T	&dis._Age_group2_16_T
								&dis._Age_group2_17_T	&dis._Age_group2_18_T	&dis._Age_group2_19_T	; 


	array pop(18) pop_all_2 pop_all_3	pop_all_4	pop_all_5	pop_all_6	pop_all_7	pop_all_8	pop_all_9	pop_all_10	pop_all_11	
						pop_all_12	pop_all_13	pop_all_14	pop_all_15	pop_all_16	pop_all_17	pop_all_18	pop_all_19; 

	array stdpop(18)  stdpop_all_2 stdpop_all_3	stdpop_all_4	stdpop_all_5	stdpop_all_6	stdpop_all_7	stdpop_all_8	stdpop_all_9	stdpop_all_10	
						stdpop_all_11	stdpop_all_12	stdpop_all_13	stdpop_all_14	stdpop_all_15	stdpop_all_16	stdpop_all_17	stdpop_all_18	stdpop_all_19; 

	array mr(18) MR_2_T MR_3_T	MR_4_T	MR_5_T	MR_6_T	MR_7_T	MR_8_T	MR_9_T	MR_10_T	MR_11_T	MR_12_T	MR_13_T	MR_14_T	MR_15_T	
					MR_16_T	MR_17_T	MR_18_T	MR_19_T		; 



	do k = 1 to 18; 
	
		mr(k) = death(k)/pop(k) *stdpop(k);  /*���ɺ� ����� * ǥ���α�*/
	end; 

	run; 

data a.&dis._yy_sgg_SMR_pop_ageonly;
	set calc2_ageonly; 
	&dis._smr_ageonly=sum(of MR_2_T MR_3_T	MR_4_T	MR_5_T	MR_6_T	MR_7_T	MR_8_T	MR_9_T	MR_10_T	MR_11_T	MR_12_T	MR_13_T	MR_14_T	MR_15_T	
					MR_16_T	MR_17_T	MR_18_T	MR_19_T	)/ 48683040 * 100000; 
	drop k; 
	if &dis._smr_ageonly^=.; 
run; 

data a.&dis._yy_sgg_SMR_ageonly;
	set a.&dis._yy_sgg_SMR_pop_ageonly;
	drop &dis._Age_group2_02_T -- MR_19_T	;
run; 

proc sort data=a.&dis._yy_sgg_SMR; by key; 
proc sort data=a.&dis._yy_sgg_SMR_ageonly ; by key; run; 

data a.&dis._yy_sgg_SMR2;
	merge a.&dis._yy_sgg_SMR a.&dis._yy_sgg_SMR_ageonly (keep=key 	&dis._smr_ageonly) ;
	by key	;
run; 



%mend smr; 
%smr(dis=TOT); 
%smr(dis=NON_ACC);
%smr(dis=RESP);
%smr(dis=ALRI);
%smr(dis=INFL);;
%smr(dis=CVD);
%smr(dis=CANO);
%smr(dis=MISC);
%smr(dis=LUNGC);
%smr(dis=LIVC);
%smr(dis=SUID);
%smr(dis=ALZ);
%smr(dis=ATHER);
%smr(dis=CERBV);
%smr(dis=DM);
%smr(dis=EAR);
%smr(dis=ENDO);
%smr(dis=EYE);
%smr(dis=HTN);
%smr(dis=IHD);
%smr(dis=KIDNEY);
%smr(dis=LRD);
%smr(dis=MENTAL);
%smr(dis=OTHERCVD);
%smr(dis=OTHERHEART);
%smr(dis=OTHERKIDNEY);
%smr(dis=OTHERMENTAL);
%smr(dis=OTHERNERV);
%smr(dis=OTHERRESP);
%smr(dis=RHEUM);

/** summary table **/
%macro mysum(dis=); 
	proc means data=a.&dis._daily_count; 
		var &dis. &dis._sex_m &dis._sex_f; 
	run; 
	proc freq data=a.&dis._daily_count noprint; table sgg /out=deathsgg; run; 

	proc univariate data=a.&dis._yy_sgg_smr_pop;  
		histogram; var &dis._smr; title "smr &dis."; 
	run; 

	proc freq data=a.&dis._daily_count noprint; table sgg /out=deathsgg; run; 
	proc freq data=deathsgg; table count; run; 
	proc freq data=a.&dis._yy_sgg_smr_pop noprint; table sgg /out=popsgg; run; 
	proc freq data=popsgg; table count; run; 


	/* write out each file to csv */
	PROC EXPORT DATA= A.&dis._DAILY_COUNT (keep=year	date sgg	&dis.	
								&dis._SEX_M	&dis._SEX_F	 
								&dis._AG00 &dis._AG0014	  &dis._AG1564	  &dis._AG65	
								&dis._AG00_M	&dis._AG0014_M	&dis._AG1564_M	&dis._AG65_M	
								&dis._AG00_F	&dis._AG0014_F	&dis._AG1564_F	&dis._AG65_F)
            OUTFILE= "F:\2020projects\bae\KEITI\research\2.���\B�� ����ڷ�(2010-2019)\outdata\send\&dis._daily_count.csv" 
            DBMS=CSV REPLACE;
     PUTNAMES=YES;
	RUN;

	PROC EXPORT DATA= A.&dis._yy_sgg_smr2 
            OUTFILE= "F:\2020projects\bae\KEITI\research\2.���\B�� ����ڷ�(2010-2019)\outdata\send\&dis._yy_sgg_smr.csv" 
            DBMS=CSV REPLACE;
     PUTNAMES=YES;
	RUN;

	PROC EXPORT DATA= A.&dis._yy_sgg_smr_pop 
            OUTFILE= "F:\2020projects\bae\KEITI\research\2.���\B�� ����ڷ�(2010-2019)\outdata\send\&dis._yy_sgg_smr_pop.csv" 
            DBMS=CSV REPLACE;
     PUTNAMES=YES;
	RUN;



	PROC EXPORT DATA= A.&dis._yy_sgg_smr_pop_ageonly
            OUTFILE= "F:\2020projects\bae\KEITI\research\2.���\B�� ����ڷ�(2010-2019)\outdata\send\&dis._yy_sgg_smr_pop_ageonly.csv" 
            DBMS=CSV REPLACE;
     PUTNAMES=YES;
	RUN;

%mend mysum; 
%mysum(dis=TOT); 
%mysum(dis=NON_ACC);
%mysum(dis=RESP);
%mysum(dis=ALRI);
%mysum(dis=INFL);;
%mysum(dis=CVD);
%mysum(dis=CANO);
%mysum(dis=MISC);
%mysum(dis=LUNGC);
%mysum(dis=LIVC);
%mysum(dis=SUID);
%mysum(dis=ALZ);
%mysum(dis=ATHER);
%mysum(dis=CERBV);
%mysum(dis=DM);
%mysum(dis=EAR);
%mysum(dis=ENDO);
%mysum(dis=EYE);
%mysum(dis=HTN);
%mysum(dis=IHD);
%mysum(dis=KIDNEY);
%mysum(dis=LRD);
%mysum(dis=MENTAL);
%mysum(dis=OTHERCVD);
%mysum(dis=OTHERHEART);
%mysum(dis=OTHERKIDNEY);
%mysum(dis=OTHERMENTAL);
%mysum(dis=OTHERNERV);
%mysum(dis=OTHERRESP);
%mysum(dis=RHEUM);

