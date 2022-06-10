/*작업공간 */
libname a 'C:\Users\User\Desktop\RnD\data\death\std_rate\sido';

/*사망자료 b형*/
libname b 'C:\Users\User\Desktop\RnD\data\death\B';


/*data 저장 위치 이름 지정해서 가져오기, CSV만  */
data b1;
keep fname;
rc=filename("mydir","C:\Users\User\Desktop\RnD\data\death\B");
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
/*_null_ : 데이터 셋 만들지 말라*/
/*_n_ 자동변수 */
/*call symput: 직접 매크로 변수를 입력해서 설정*/
/*매크로 이용해서 csv파일 일괄 불러오기 */
%macro importFile;
%do i=1 %to &n;
data _null_; set b1; 
if _n_=&i; 
call symput('file',trim(cats('C:\Users\User\Desktop\RnD\data\death\B\',fname,"")));run;
proc import out=y&i datafile="&file" DBMS=CSV;  RUN;
%end;
%mend;

%importFile;
/********************************************************************************************************************/
/********************************************************************************************************************/
/*자료 merge */
data a.all; set y14-y23; run; /*2010-2019*/

/* 각 개별 변수
v1: 신고일자 (년)          v2: 신고일자 (월)   v3: 신고일자 (일)
v4: 사망자 주소(시도)
v5: 사망자 주소(시군구)
v6: 성별
v7: 사망연원일            v8: 사망시간
v9: 사망연령(5세단위)
v10: 사망장소
v11: 사망직업
v12: 혼인상태
v13: 교육정도
v14: 사망원인 103 항목
v15: 사망원인 56 항목 
*/

/********************************************************************************************************************/
/********************************************************************************************************************/
/* 시도 변수 
11	서울 21	부산 22	대구 23	인천 24	광주 25	대전 26	울산 29	세종 
31	경기 32	강원 33	충북 34	충남 35	전북 36	전남 37	경북 38	경남 39	제주 */
/********************************************************************************************************************/
/********************************************************************************************************************/
data A.all_r ;  
RETAIN var7 var4 var9 var14 ;  /*변수순서: 사망년월일 시도 성별 연령그룹 사망원인103 */
set A.all;

/*label 변경 */
RENAME VAR4=SIDO  VAR6=SEX VAR7=DEATHDATE VAR9=AGE_GROUP VAR14=DEATH103 ;

/*사망 년 월 일 */
YEAR   =SUBSTR(LEFT(VAR7),1,4);
MONTH=SUBSTR(LEFT(VAR7),5,2);
DAY    =SUBSTR(LEFT(VAR7),7,2);

/*연령 그룹 분류*/
KEEP  VAR4 VAR6 VAR7 VAR9 VAR14 YEAR MONTH DAY;
run;

proc freq data=a.all_r noprint; table sido*year*age_group /out=myfreq2; run; 


/*통계청 사망원인통계 A형 자료 연령 missing 제외한 자료랑  전체 사망(all-cause) N수 동일 n=2,749,704 */
DATA A.ALL_R2; SET A.ALL_R;
/*연령 그룹 99 제외 (MISSING)*/
IF AGE_GROUP^=99;
 

/* 0-4세 다르게 정의 */ 
if age_group in (1, 2) then age_group2=2; /* 0-4세*/
else age_group2=age_group;  					/*나머지는 동일 */

KEY=COMPRESS(YEAR)||("-")||COMPRESS(SIDO);
DROP DEATH56 ;
RUN;  

PROC FREQ DATA= A.ALL_R2 noprint ; TABLES SIDO/ out=mysido; RUN;


/*주요 변수 결측 있나 확인 : 시도 성별 연령그룹 사망원인*/
PROC FREQ DATA=A.ALL_R2; TABLES SIDO SEX AGE_GROUP AGE_GROUP2 DEATH103; RUN;

/*사망원인103항목에 대해서 사망원인별 변수 생성 */
DATA A.DEATH; SET A.ALL_R2;

TOT=1;                                                                              /*총 사망 */
IF DEATH103<=94 THEN NON_ACC=1; ELSE NON_ACC=0;         /*자연사 (비사고 사망) */

if DEATH103>=64 & DEATH103<=71 then cvd=1; else cvd=0;	   /*전체심혈관 */
if DEATH103=67 then ihd=1; else ihd=0; 			        	           /*허혈성 심장 질환*/
if DEATH103=70 then ather=1; else ather=0;  			               /*죽상경화증(Atherosclerosis) */
if DEATH103=69 then cerbv=1; else cerbv=0; 			               /*뇌혈관 질환(Cerebrovascular diseases) */
if DEATH103=66 then htn=1; else htn=0;  				                   /*고혈압성 질환(Hypertensive diseases) */
if DEATH103=67 then ihd=1; else ihd=0;  				                   /*허혈성 심장 질환(Ischaemic heart diseases) */
if DEATH103=71 then OTHcvd=1; else OTHcvd=0;                   /*나머지 순환계통 질환*/
if DEATH103=68 then OTHheart=1; else OTHheart=0;                /*기타 심장 질환(OTH heart diseases) */

if DEATH103 >=73 & DEATH103 <=77 then resp=1; else resp=0;  /*전체호흡기 */
if DEATH103>=74 & DEATH103<=75 then alri=1; else alri=0;	        /*하부호흡기감염 */
if DEATH103=73 then infl=1; else infl=0;				                   /*인플루엔자 */
if DEATH103=76 then lrd=1; else lrd=0;                                    /*만성 하기도 질환(Chronic lower respiratory diseases)*/
if DEATH103=77 then OTHresp=1; else OTHresp=0;                 /*나머지 호흡계통 질환 */

if DEATH103=34 then lungc=1; else lungc=0;				               /*폐암*/
if DEATH103=31 then livc=1; else livc=0;				                   /*간암 */

if DEATH103=93 then cano=1;else cano=0;				               /*선천 기형, 변형 및 염색체이상*/
if DEATH103=88 then misc=1;else misc=0;				               /*유산*/

if DEATH103=60 then alz=1; else alz=0;  				                   /*알츠하이머병(Alzheimer's disease) */
if DEATH103=61 then OTHnerv=1; else OTHnerv=0;                 /*나머지 신경계통 질환*/

if DEATH103=65 then rheum=1; else rheum=0;                         /*급성 류마티스열 및 만성 류마티스 심장 질환*/
if DEATH103=63 then ear=1; else ear=0;  				                   /*귀 및 유돌의 질환 (Diseases of the ear and mastoid process)*/
if DEATH103=62 then eye=1; else eye=0;  				               /*눈 및 눈부속기의 질환 (Diseases of the eye and adnexa) */

if DEATH103=52 then dm=1; else dm=0; 					               /*당뇨병(Diabetes mellitus) */
if DEATH103=54 then endo=1; else endo=0;  			 	           /*나머지 내분비, 영양 및 대사 질환 */

if DEATH103=85 then kidney=1; else kidney=0;                         /*사구체 질환 및 세뇨관-간질 질환 */
if DEATH103=86 then OTHkidney=1; else OTHkidney=0;            /*나머지 비뇨생식계통 질환 */

if DEATH103=56 then mental=1; else mental=0;                         /*정신활성물질 사용에 의한 정신 및 행동장애*/
if DEATH103=57 then OTHmental=1; else OTHmental=0;            /*나머지 정신 및 행동 장애*/

if DEATH103=101 then suid=1; else suid=0;			      	           /*자살 */

RUN;

/*비사고 사망 A형= 2,453,651  비사고 사망 B형= 2,453,686  

   전체 호흡기 A형= 272,072    B형=272,107

35명 차이 why? => A형에는 질환코드 중 U 코드가 포함되어있는데 (n=35)
B형에서는 U코드 구분이 따로 되어있지 않고 다른 항목에 포함된 듯 
전체 심혈관 A형= 591,267 B형= 591,267 (차이 x) */

PROC FREQ DATA=A.DEATH; TABLES TOT NON_ACC RESP cvd  ; RUN;

/********************************************************************************************************************/
/********************************************************************************************************************/

/*연도별 사망 원인별  합계 */
proc sql; create table z_YEAR as select YEAR, sum(tot) as tot, sum(non_acc) as non_acc , sum(resp) as resp, sum(alri) as alri, sum(infl) as infl, sum(cvd) as cvd, sum(cano) as cano,
sum(misc) as misc, sum(lungc) as lungc, sum(livc) as livc, sum(suid) as suid, sum(alz) as alz, sum(ather) as ather, sum(cerbv) as cerbv, sum(dm) as dm, sum(ear) as ear,
sum(endo) as endo, sum(eye) as eye, sum(htn) as htn, sum(ihd) as ihd, sum(kidney) as kidney, sum(lrd) as lrd, sum(mental) as mental, sum(othcvd) as othcvd, 
sum(othheart) as othheart, sum(othkidney) as othkidney, sum(othmental) as othmental, sum(othnerv) as othnerv, sum(othresp) as othresp, sum(rheum) as rheum from
a.DEATH GROUP BY YEAR; QUIT;

/*전체 합계  */
proc sql; create table z_TOT as select sum(tot) as tot, sum(non_acc) as non_acc , sum(resp) as resp, sum(alri) as alri, sum(infl) as infl, sum(cvd) as cvd, sum(cano) as cano,
sum(misc) as misc, sum(lungc) as lungc, sum(livc) as livc, sum(suid) as suid, sum(alz) as alz, sum(ather) as ather, sum(cerbv) as cerbv, sum(dm) as dm, sum(ear) as ear,
sum(endo) as endo, sum(eye) as eye, sum(htn) as htn, sum(ihd) as ihd, sum(kidney) as kidney, sum(lrd) as lrd, sum(mental) as mental, sum(othcvd) as othcvd, 
sum(othheart) as othheart, sum(othkidney) as othkidney, sum(othmental) as othmental, sum(othnerv) as othnerv, sum(othresp) as othresp, sum(rheum) as rheum from
a.DEATH ; QUIT;

/*위 두개 테이블 결합 */
DATA a.year_sum; SET Z_YEAR Z_TOT;
IF YEAR="" THEN YEAR="Total"; ELSE YEAR=YEAR;run;
/********************************************************************************************************************/
/********************************************************************************************************************/

/********************************************************************************************************************/

/*날짜 자료 만들기*/
/*기준연도랑 기준연도에 해당하는 시군구 조합해서 시군구별 날짜 생성하기 */


/*원래 자료에서 기준연도에 해당하는 시도만 가져오기  */
DATA SIDO; SET A.DEATH; KEEP SIDO; RUN; 

/*고유 시군구만 남기기  */
PROC SORT DATA= SIDO NODUPKEY ; BY SIDO; RUN;

/*날짜 자료 먼저 만들기 */
DATA A.DDATE ; 
FORMAT DATE YYMMDD10.;
DO I = 1 to 3652 BY 1;       
DATE=MDY(01,01,2010)+I-1; /* 반복문으로 날짜 만들기 2010년 1월 1일부터 2019년 12월 31일 까지 */
OUTPUT;
END;
DROP I;
RUN;
DATA A.DDATE; SET A.DDATE;
DATE2= PUT(DATE,YYMMDDN8.);RUN; /*날짜 -> 문자로 형식 변경 */

/*위에서 생성한 기준연도 날짜 자료랑 시군구 자료 MERGE하기 (이때 CROSS JOIN)*/
proc sql; create table a.SIDODATE as select * from a.ddate cross join  sido; quit;

/*KEY값 만 남기기 KEY=날짜+시도*/
DATA a.SIDODATE_key; SET a.SIDODATE; 
KEY=COMPRESS(DATE2)||("-")||COMPRESS(SIDO); KEEP KEY; RUN;

DATA a.SIDO_year; SET a.SIDODATE; 
KEY=COMPRESS(substr(DATE2,1,4))||("-")||COMPRESS(SIDO); KEEP KEY; RUN;

PROC SORT DATA= a.sido_year NODUPKEY ; BY key; RUN;

/* 사망원인별 연도별 카운트 자료 만드는 매크로 */
%MACRO DEATH(CAUSE);

/*사망 원시자료에서 연도 추출 하고 필요변수만 추출  */
DATA A.Z1 ; SET A.DEATH;
RENAME &CAUSE=D; /*DISEASE(사망원인 지정할 변수)*/
KEEP KEY DEATHDATE SIDO SEX  YEAR AG age_group2 &CAUSE.; 
RUN;

/*위에서 정리한 자료에서 성, 연령, 성*연령 조합 구분 */
DATA A.Z2; SET A.Z1;

/*성별 */
IF SEX=1 & D=1 THEN &CAUSE._SEX_M=1; ELSE &CAUSE._SEX_M=0;
IF SEX=2 & D=1 THEN &CAUSE._SEX_F=1; ELSE &CAUSE._SEX_F=0;

/*** 표준화사망률 계산용 성연령 */
/*남성 * 연령 그룹별  */
IF SEX=1 & Age_group2=2  & D=1 THEN &CAUSE._Age_group2_0004_M=1; ELSE &CAUSE._Age_group2_0004_M=0; /*0-4세 남 */
IF SEX=1 & Age_group2=3  & D=1 THEN &CAUSE._Age_group2_0509_M=1; ELSE &CAUSE._Age_group2_0509_M=0; /*5-9세 남 */
IF SEX=1 & Age_group2=4  & D=1 THEN &CAUSE._Age_group2_1014_M=1; ELSE &CAUSE._Age_group2_1014_M=0; /*10-14세 남 */
IF SEX=1 & Age_group2=5  & D=1 THEN &CAUSE._Age_group2_1519_M=1; ELSE &CAUSE._Age_group2_1519_M=0; /*15-19세 남 */
IF SEX=1 & Age_group2=6  & D=1 THEN &CAUSE._Age_group2_2024_M=1; ELSE &CAUSE._Age_group2_2024_M=0; /*20-24세 남 */
IF SEX=1 & Age_group2=7  & D=1 THEN &CAUSE._Age_group2_2529_M=1; ELSE &CAUSE._Age_group2_2529_M=0; /*25-29세 남 */
IF SEX=1 & Age_group2=8  & D=1 THEN &CAUSE._Age_group2_3034_M=1; ELSE &CAUSE._Age_group2_3034_M=0; /*30-34세 남 */
IF SEX=1 & Age_group2=9  & D=1 THEN &CAUSE._Age_group2_3539_M=1; ELSE &CAUSE._Age_group2_3539_M=0; /*35-39세 남 */
IF SEX=1 & Age_group2=10 & D=1 THEN &CAUSE._Age_group2_4044_M=1; ELSE &CAUSE._Age_group2_4044_M=0; /*40-44세 남 */
IF SEX=1 & Age_group2=11 & D=1 THEN &CAUSE._Age_group2_4549_M=1; ELSE &CAUSE._Age_group2_4549_M=0; /*45-49세 남 */
IF SEX=1 & Age_group2=12 & D=1 THEN &CAUSE._Age_group2_5054_M=1; ELSE &CAUSE._Age_group2_5054_M=0; /*50-54세 남 */
IF SEX=1 & Age_group2=13 & D=1 THEN &CAUSE._Age_group2_5559_M=1; ELSE &CAUSE._Age_group2_5559_M=0; /*55-59세 남 */
IF SEX=1 & Age_group2=14 & D=1 THEN &CAUSE._Age_group2_6064_M=1; ELSE &CAUSE._Age_group2_6064_M=0; /*60-64세 남 */
IF SEX=1 & Age_group2=15 & D=1 THEN &CAUSE._Age_group2_6569_M=1; ELSE &CAUSE._Age_group2_6569_M=0; /*65-69세 남 */
IF SEX=1 & Age_group2=16 & D=1 THEN &CAUSE._Age_group2_7074_M=1; ELSE &CAUSE._Age_group2_7074_M=0; /*70-74세 남 */
IF SEX=1 & Age_group2=17 & D=1 THEN &CAUSE._Age_group2_7579_M=1; ELSE &CAUSE._Age_group2_7579_M=0; /*75-79세 남 */
IF SEX=1 & Age_group2=18 & D=1 THEN &CAUSE._Age_group2_8084_M=1; ELSE &CAUSE._Age_group2_8084_M=0; /*80-84세 남 */
IF SEX=1 & Age_group2=19 & D=1 THEN &CAUSE._Age_group2_85_M=1; ELSE &CAUSE._Age_group2_85_M=0; /*85+세 남 */


/*여성 * 연령 그룹별  */
IF SEX=2 & Age_group2=2  & D=1 THEN &CAUSE._Age_group2_0004_F=1; ELSE &CAUSE._Age_group2_0004_F=0; /*0-4세 여 */
IF SEX=2 & Age_group2=3  & D=1 THEN &CAUSE._Age_group2_0509_F=1; ELSE &CAUSE._Age_group2_0509_F=0; /*5-9세 여 */
IF SEX=2 & Age_group2=4  & D=1 THEN &CAUSE._Age_group2_1014_F=1; ELSE &CAUSE._Age_group2_1014_F=0; /*10-14세 여 */
IF SEX=2 & Age_group2=5  & D=1 THEN &CAUSE._Age_group2_1519_F=1; ELSE &CAUSE._Age_group2_1519_F=0; /*15-19세 여 */
IF SEX=2 & Age_group2=6  & D=1 THEN &CAUSE._Age_group2_2024_F=1; ELSE &CAUSE._Age_group2_2024_F=0; /*20-24세 여 */
IF SEX=2 & Age_group2=7  & D=1 THEN &CAUSE._Age_group2_2529_F=1; ELSE &CAUSE._Age_group2_2529_F=0; /*25-29세 여 */
IF SEX=2 & Age_group2=8  & D=1 THEN &CAUSE._Age_group2_3034_F=1; ELSE &CAUSE._Age_group2_3034_F=0; /*30-34세 여 */
IF SEX=2 & Age_group2=9  & D=1 THEN &CAUSE._Age_group2_3539_F=1; ELSE &CAUSE._Age_group2_3539_F=0; /*35-39세 여 */
IF SEX=2 & Age_group2=10 & D=1 THEN &CAUSE._Age_group2_4044_F=1; ELSE &CAUSE._Age_group2_4044_F=0; /*40-44세 여 */
IF SEX=2 & Age_group2=11 & D=1 THEN &CAUSE._Age_group2_4549_F=1; ELSE &CAUSE._Age_group2_4549_F=0; /*45-49세 여 */
IF SEX=2 & Age_group2=12 & D=1 THEN &CAUSE._Age_group2_5054_F=1; ELSE &CAUSE._Age_group2_5054_F=0; /*50-54세 여 */
IF SEX=2 & Age_group2=13 & D=1 THEN &CAUSE._Age_group2_5559_F=1; ELSE &CAUSE._Age_group2_5559_F=0; /*55-59세 여 */
IF SEX=2 & Age_group2=14 & D=1 THEN &CAUSE._Age_group2_6064_F=1; ELSE &CAUSE._Age_group2_6064_F=0; /*60-64세 여 */
IF SEX=2 & Age_group2=15 & D=1 THEN &CAUSE._Age_group2_6569_F=1; ELSE &CAUSE._Age_group2_6569_F=0; /*65-69세 여 */
IF SEX=2 & Age_group2=16 & D=1 THEN &CAUSE._Age_group2_7074_F=1; ELSE &CAUSE._Age_group2_7074_F=0; /*70-74세 여 */
IF SEX=2 & Age_group2=17 & D=1 THEN &CAUSE._Age_group2_7579_F=1; ELSE &CAUSE._Age_group2_7579_F=0; /*75-79세 여 */
IF SEX=2 & Age_group2=18 & D=1 THEN &CAUSE._Age_group2_8084_F=1; ELSE &CAUSE._Age_group2_8084_F=0; /*80-84세 여 */
IF SEX=2 & Age_group2=19 & D=1 THEN &CAUSE._Age_group2_85_F=1; ELSE &CAUSE._Age_group2_85_F=0; /*85+세 여 */

/*위에서 정리한 변수에 대해서 카운트 자료 산출 -> 즉 이자료는 사망에 대한  시군구별 데일리 카운트 (사망원인 B형) (연도별) */
PROC SQL; CREATE TABLE A.&CAUSE. AS SELECT KEY, SUM(D) AS &CAUSE., 
SUM(&CAUSE._Age_group2_0004_M) AS &CAUSE._Age_group2_0004_M, 
SUM(&CAUSE._Age_group2_0509_M) AS &CAUSE._Age_group2_0509_M, 
SUM(&CAUSE._Age_group2_1014_M) AS &CAUSE._Age_group2_1014_M, 
SUM(&CAUSE._Age_group2_1519_M) AS &CAUSE._Age_group2_1519_M, 
SUM(&CAUSE._Age_group2_2024_M) AS &CAUSE._Age_group2_2024_M, 
SUM(&CAUSE._Age_group2_2529_M) AS &CAUSE._Age_group2_2529_M, 
SUM(&CAUSE._Age_group2_3034_M) AS &CAUSE._Age_group2_3034_M, 
SUM(&CAUSE._Age_group2_3539_M) AS &CAUSE._Age_group2_3539_M, 
SUM(&CAUSE._Age_group2_4044_M) AS &CAUSE._Age_group2_4044_M, 
SUM(&CAUSE._Age_group2_4549_M) AS &CAUSE._Age_group2_4549_M, 
SUM(&CAUSE._Age_group2_5054_M) AS &CAUSE._Age_group2_5054_M, 
SUM(&CAUSE._Age_group2_5559_M) AS &CAUSE._Age_group2_5559_M, 
SUM(&CAUSE._Age_group2_6064_M) AS &CAUSE._Age_group2_6064_M, 
SUM(&CAUSE._Age_group2_6569_M) AS &CAUSE._Age_group2_6569_M, 
SUM(&CAUSE._Age_group2_7074_M) AS &CAUSE._Age_group2_7074_M, 
SUM(&CAUSE._Age_group2_7579_M) AS &CAUSE._Age_group2_7579_M, 
SUM(&CAUSE._Age_group2_8084_M) AS &CAUSE._Age_group2_8084_M, 
SUM(&CAUSE._Age_group2_85_M) AS &CAUSE._Age_group2_85_M, 
SUM(&CAUSE._Age_group2_0004_F) AS &CAUSE._Age_group2_0004_F, 
SUM(&CAUSE._Age_group2_0509_F) AS &CAUSE._Age_group2_0509_F, 
SUM(&CAUSE._Age_group2_1014_F) AS &CAUSE._Age_group2_1014_F, 
SUM(&CAUSE._Age_group2_1519_F) AS &CAUSE._Age_group2_1519_F, 
SUM(&CAUSE._Age_group2_2024_F) AS &CAUSE._Age_group2_2024_F, 
SUM(&CAUSE._Age_group2_2529_F) AS &CAUSE._Age_group2_2529_F, 
SUM(&CAUSE._Age_group2_3034_F) AS &CAUSE._Age_group2_3034_F, 
SUM(&CAUSE._Age_group2_3539_F) AS &CAUSE._Age_group2_3539_F, 
SUM(&CAUSE._Age_group2_4044_F) AS &CAUSE._Age_group2_4044_F, 
SUM(&CAUSE._Age_group2_4549_F) AS &CAUSE._Age_group2_4549_F, 
SUM(&CAUSE._Age_group2_5054_F) AS &CAUSE._Age_group2_5054_F, 
SUM(&CAUSE._Age_group2_5559_F) AS &CAUSE._Age_group2_5559_F, 
SUM(&CAUSE._Age_group2_6064_F) AS &CAUSE._Age_group2_6064_F, 
SUM(&CAUSE._Age_group2_6569_F) AS &CAUSE._Age_group2_6569_F, 
SUM(&CAUSE._Age_group2_7074_F) AS &CAUSE._Age_group2_7074_F, 
SUM(&CAUSE._Age_group2_7579_F) AS &CAUSE._Age_group2_7579_F, 
SUM(&CAUSE._Age_group2_8084_F) AS &CAUSE._Age_group2_8084_F, 
SUM(&CAUSE._Age_group2_85_F) AS &CAUSE._Age_group2_85_F  FROM A.Z2 GROUP BY KEY;QUIT;

/*데일리 카운트 한 자료를 연도별 시군구 자료랑 merge하기 
  (missing값 채워주기 위해서)*/
/*위에서 먼저 생성한 시군구+날짜 자료를 기준으로 LEFT JOIN */
PROC SQL; CREATE TABLE A.&CAUSE._yy_sido AS SELECT * FROM A.SIDO_year AS A  LEFT JOIN A.&CAUSE. AS B ON A.KEY=B.KEY; QUIT;

/*MISSING VALUE 0으로 채워주기 */
DATA  A.&CAUSE._yy_sido; RETAIN KEY YEAR SIDO; format year 4.;
SET  A.&CAUSE._yy_sido;
IF &CAUSE ='.' THEN &CAUSE=0; 
IF &CAUSE._Age_group2_0004_M  ='.'  THEN &CAUSE._Age_group2_0004_M=0;
IF &CAUSE._Age_group2_0509_M  ='.'  THEN &CAUSE._Age_group2_0509_M=0;
IF &CAUSE._Age_group2_1014_M  ='.'  THEN &CAUSE._Age_group2_1014_M=0;
IF &CAUSE._Age_group2_1519_M  ='.'  THEN &CAUSE._Age_group2_1519_M=0;
IF &CAUSE._Age_group2_2024_M  ='.'  THEN &CAUSE._Age_group2_2024_M=0;
IF &CAUSE._Age_group2_2529_M  ='.'  THEN &CAUSE._Age_group2_2529_M=0;
IF &CAUSE._Age_group2_3034_M  ='.'  THEN &CAUSE._Age_group2_3034_M=0;
IF &CAUSE._Age_group2_3539_M  ='.'  THEN &CAUSE._Age_group2_3539_M=0;
IF &CAUSE._Age_group2_4044_M  ='.'  THEN &CAUSE._Age_group2_4044_M=0;
IF &CAUSE._Age_group2_4549_M  ='.'  THEN &CAUSE._Age_group2_4549_M=0;
IF &CAUSE._Age_group2_5054_M  ='.'  THEN &CAUSE._Age_group2_5054_M=0;
IF &CAUSE._Age_group2_5559_M  ='.'  THEN &CAUSE._Age_group2_5559_M=0;
IF &CAUSE._Age_group2_6064_M  ='.'  THEN &CAUSE._Age_group2_6064_M=0;
IF &CAUSE._Age_group2_6569_M  ='.'  THEN &CAUSE._Age_group2_6569_M=0;
IF &CAUSE._Age_group2_7074_M  ='.'  THEN &CAUSE._Age_group2_7074_M=0;
IF &CAUSE._Age_group2_7579_M  ='.'  THEN &CAUSE._Age_group2_7579_M=0;
IF &CAUSE._Age_group2_8084_M  ='.'  THEN &CAUSE._Age_group2_8084_M=0;
IF &CAUSE._Age_group2_85_M  ='.'  THEN &CAUSE._Age_group2_85_M=0;
IF &CAUSE._Age_group2_0004_F  ='.'  THEN &CAUSE._Age_group2_0004_F=0;
IF &CAUSE._Age_group2_0509_F  ='.'  THEN &CAUSE._Age_group2_0509_F=0;
IF &CAUSE._Age_group2_1014_F  ='.'  THEN &CAUSE._Age_group2_1014_F=0;
IF &CAUSE._Age_group2_1519_F  ='.'  THEN &CAUSE._Age_group2_1519_F=0;
IF &CAUSE._Age_group2_2024_F  ='.'  THEN &CAUSE._Age_group2_2024_F=0;
IF &CAUSE._Age_group2_2529_F  ='.'  THEN &CAUSE._Age_group2_2529_F=0;
IF &CAUSE._Age_group2_3034_F  ='.'  THEN &CAUSE._Age_group2_3034_F=0;
IF &CAUSE._Age_group2_3539_F  ='.'  THEN &CAUSE._Age_group2_3539_F=0;
IF &CAUSE._Age_group2_4044_F  ='.'  THEN &CAUSE._Age_group2_4044_F=0;
IF &CAUSE._Age_group2_4549_F  ='.'  THEN &CAUSE._Age_group2_4549_F=0;
IF &CAUSE._Age_group2_5054_F  ='.'  THEN &CAUSE._Age_group2_5054_F=0;
IF &CAUSE._Age_group2_5559_F  ='.'  THEN &CAUSE._Age_group2_5559_F=0;
IF &CAUSE._Age_group2_6064_F  ='.'  THEN &CAUSE._Age_group2_6064_F=0;
IF &CAUSE._Age_group2_6569_F  ='.'  THEN &CAUSE._Age_group2_6569_F=0;
IF &CAUSE._Age_group2_7074_F  ='.'  THEN &CAUSE._Age_group2_7074_F=0;
IF &CAUSE._Age_group2_7579_F  ='.'  THEN &CAUSE._Age_group2_7579_F=0;
IF &CAUSE._Age_group2_8084_F  ='.'  THEN &CAUSE._Age_group2_8084_F=0;
IF &CAUSE._Age_group2_85_F  ='.'  THEN &CAUSE._Age_group2_85_F=0;

/*날짜 및 시도, 시군구 수정 */
YEAR=SUBSTR(KEY,1,4);
SIDO=SUBSTR(KEY,6,2); 
drop KEY;
RUN;
%MEND;

/*시군구별 데일리 사망 자료 -질환별로 */
%DEATH(TOT);
%DEATH(NON_ACC);
%DEATH(RESP);
%DEATH(CVD);
%DEATH(ALRI);
%DEATH(IHD);


%MACRO CNT(CAUSE);
/*연도별  질환에 대한 사망  합계 */
PROC SQL; CREATE TABLE A.&CAUSE._YY AS SELECT YEAR, SUM(&CAUSE.) AS &CAUSE. , 
SUM(&CAUSE._Age_group2_0004_M) AS &CAUSE._Age_group2_0004_M, 
SUM(&CAUSE._Age_group2_0509_M) AS &CAUSE._Age_group2_0509_M, 
SUM(&CAUSE._Age_group2_1014_M) AS &CAUSE._Age_group2_1014_M, 
SUM(&CAUSE._Age_group2_1519_M) AS &CAUSE._Age_group2_1519_M, 
SUM(&CAUSE._Age_group2_2024_M) AS &CAUSE._Age_group2_2024_M, 
SUM(&CAUSE._Age_group2_2529_M) AS &CAUSE._Age_group2_2529_M, 
SUM(&CAUSE._Age_group2_3034_M) AS &CAUSE._Age_group2_3034_M, 
SUM(&CAUSE._Age_group2_3539_M) AS &CAUSE._Age_group2_3539_M, 
SUM(&CAUSE._Age_group2_4044_M) AS &CAUSE._Age_group2_4044_M, 
SUM(&CAUSE._Age_group2_4549_M) AS &CAUSE._Age_group2_4549_M, 
SUM(&CAUSE._Age_group2_5054_M) AS &CAUSE._Age_group2_5054_M, 
SUM(&CAUSE._Age_group2_5559_M) AS &CAUSE._Age_group2_5559_M, 
SUM(&CAUSE._Age_group2_6064_M) AS &CAUSE._Age_group2_6064_M, 
SUM(&CAUSE._Age_group2_6569_M) AS &CAUSE._Age_group2_6569_M, 
SUM(&CAUSE._Age_group2_7074_M) AS &CAUSE._Age_group2_7074_M, 
SUM(&CAUSE._Age_group2_7579_M) AS &CAUSE._Age_group2_7579_M, 
SUM(&CAUSE._Age_group2_8084_M) AS &CAUSE._Age_group2_8084_M, 
SUM(&CAUSE._Age_group2_85_M) AS &CAUSE._Age_group2_85_M, 
SUM(&CAUSE._Age_group2_0004_F) AS &CAUSE._Age_group2_0004_F, 
SUM(&CAUSE._Age_group2_0509_F) AS &CAUSE._Age_group2_0509_F, 
SUM(&CAUSE._Age_group2_1014_F) AS &CAUSE._Age_group2_1014_F, 
SUM(&CAUSE._Age_group2_1519_F) AS &CAUSE._Age_group2_1519_F, 
SUM(&CAUSE._Age_group2_2024_F) AS &CAUSE._Age_group2_2024_F, 
SUM(&CAUSE._Age_group2_2529_F) AS &CAUSE._Age_group2_2529_F, 
SUM(&CAUSE._Age_group2_3034_F) AS &CAUSE._Age_group2_3034_F, 
SUM(&CAUSE._Age_group2_3539_F) AS &CAUSE._Age_group2_3539_F, 
SUM(&CAUSE._Age_group2_4044_F) AS &CAUSE._Age_group2_4044_F, 
SUM(&CAUSE._Age_group2_4549_F) AS &CAUSE._Age_group2_4549_F, 
SUM(&CAUSE._Age_group2_5054_F) AS &CAUSE._Age_group2_5054_F, 
SUM(&CAUSE._Age_group2_5559_F) AS &CAUSE._Age_group2_5559_F, 
SUM(&CAUSE._Age_group2_6064_F) AS &CAUSE._Age_group2_6064_F, 
SUM(&CAUSE._Age_group2_6569_F) AS &CAUSE._Age_group2_6569_F, 
SUM(&CAUSE._Age_group2_7074_F) AS &CAUSE._Age_group2_7074_F, 
SUM(&CAUSE._Age_group2_7579_F) AS &CAUSE._Age_group2_7579_F, 
SUM(&CAUSE._Age_group2_8084_F) AS &CAUSE._Age_group2_8084_F, 
SUM(&CAUSE._Age_group2_85_F) AS &CAUSE._Age_group2_85_F

FROM A.&CAUSE._yy_sido GROUP BY YEAR ; QUIT;

data a.&cause._yy; set a.&cause._yy; format year 4.; run; 

%MEND;
/*질환별 전체 연도별 카운트*/
%CNT(TOT);
%CNT(NON_ACC);
%CNT(RESP);
%CNT(ALRI);
%CNT(CVD);
%CNT(IHD);

/*인구자료*/
/*연도별 인구*/
PROC IMPORT OUT= WORK.pop 
            DATAFILE= "C:\Users\User\Desktop\RnD\data\읍면동_인구자료\연앙인구_시도_final.csv" 
            DBMS=CSV REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
RUN;

/*연도별 인구 */ 
data pop2; 
	set pop; 
	if sex="남자"; 
	if sido<100; 
	keep sido sex age_group P2010-P2019; 
run; 
proc means data=pop2 noprint sum; 
	class sido age_group;
	var p2010-p2019; 
	output out=pop3 sum(p2010-p2019)=p2010-p2019;
run; 

data pop4; 
	set pop3;
	if _type_=3; 
if age_group='0 - 4세' then age_group2='0004'; 
if age_group='5 - 9세' then age_group2='0509'; 
if age_group='10 - 14세' then age_group2='1014'; 
if age_group='15 - 19세' then age_group2='1519'; 
if age_group='20 - 24세' then age_group2='2024'; 
if age_group='25 - 29세' then age_group2='2529'; 
if age_group='30 - 34세' then age_group2='3034'; 
if age_group='35 - 39세' then age_group2='3539'; 
if age_group='40 - 44세' then age_group2='4044'; 
if age_group='45 - 49세' then age_group2='4549'; 
if age_group='50 - 54세' then age_group2='5054'; 
if age_group='55 - 59세' then age_group2='5559'; 
if age_group='60 - 64세' then age_group2='6064'; 
if age_group='65 - 69세' then age_group2='6569'; 
if age_group='70 - 74세' then age_group2='7074'; 
if age_group='75 - 79세' then age_group2='7579'; 
if age_group='80 - 84세' then age_group2='8084'; 
if age_group='85세 이상' then age_group2='85'; 

drop _type_ _freq_; 
run; 

proc sort data=pop4; by sido age_group2; run; 

PROC TRANSPOSE DATA=Pop4 OUT=pop4_trans prefix=pop_male_; 
	BY sido;
	/*VAR &var. ; */
	ID age_group2; 
RUN;

data pop4_male;
 	retain year; 
	set pop4_trans; 
	by sido; 
	drop _name_; 
	
	if first.sido then year=2010;
	else year=year+1;  
run; 
 
/*여자 */ 

data pop2; 
	set pop; 
	if sex="여자"; 
	if sido<100; 
	keep sido sex age_group P2010-P2019; 
run; 
proc means data=pop2 noprint sum; 
	class sido age_group;
	var p2010-p2019; 
	output out=pop3 sum(p2010-p2019)=p2010-p2019;
run; 

data pop4; 
	set pop3;
	if _type_=3; 
if age_group='0 - 4세' then age_group2='0004'; 
if age_group='5 - 9세' then age_group2='0509'; 
if age_group='10 - 14세' then age_group2='1014'; 
if age_group='15 - 19세' then age_group2='1519'; 
if age_group='20 - 24세' then age_group2='2024'; 
if age_group='25 - 29세' then age_group2='2529'; 
if age_group='30 - 34세' then age_group2='3034'; 
if age_group='35 - 39세' then age_group2='3539'; 
if age_group='40 - 44세' then age_group2='4044'; 
if age_group='45 - 49세' then age_group2='4549'; 
if age_group='50 - 54세' then age_group2='5054'; 
if age_group='55 - 59세' then age_group2='5559'; 
if age_group='60 - 64세' then age_group2='6064'; 
if age_group='65 - 69세' then age_group2='6569'; 
if age_group='70 - 74세' then age_group2='7074'; 
if age_group='75 - 79세' then age_group2='7579'; 
if age_group='80 - 84세' then age_group2='8084'; 
if age_group='85세 이상' then age_group2='85'; 

drop _type_ _freq_; 

run; 

proc sort data=pop4; by sido age_group2; run; 

PROC TRANSPOSE DATA=Pop4 OUT=pop4_trans prefix=pop_female_; 
	BY sido;
	/*VAR &var. ; */
	ID age_group2; 
RUN;

data pop4_female;
 	retain year; 
	set pop4_trans; 
	by sido; 
	drop _name_; 
	
	if first.sido then year=2010;
	else year=year+1;  
run; 
 

/*표준 인구 */ 
/* 시도합한 값만 불러 읽기 */
PROC IMPORT OUT= WORK.pop 
            DATAFILE= "C:\Users\User\Desktop\RnD\data\읍면동_인구자료\연앙인구_시도_final.csv" 
            DBMS=CSV REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
RUN;


data pop2; 
	set pop; 
	if sex="남자"; 
	if sido<100; 
	if P2005 ^=.;
	*keep code_b sex age_group P2005; 
	drop P2010-P2019; 
	KEY=COMPRESS(sigu)||("-")||COMPRESS(sido);
run; 
proc means data=pop2 noprint sum; 
	class age_group;
	var p2005; 
	output out=pop3 sum(p2005)=p2005;
run; 

data pop4; 
	set pop3;
	if _type_=1; 
if age_group='0 - 4세' then age_group2='0004'; 
if age_group='5 - 9세' then age_group2='0509'; 
if age_group='10 - 14세' then age_group2='1014'; 
if age_group='15 - 19세' then age_group2='1519'; 
if age_group='20 - 24세' then age_group2='2024'; 
if age_group='25 - 29세' then age_group2='2529'; 
if age_group='30 - 34세' then age_group2='3034'; 
if age_group='35 - 39세' then age_group2='3539'; 
if age_group='40 - 44세' then age_group2='4044'; 
if age_group='45 - 49세' then age_group2='4549'; 
if age_group='50 - 54세' then age_group2='5054'; 
if age_group='55 - 59세' then age_group2='5559'; 
if age_group='60 - 64세' then age_group2='6064'; 
if age_group='65 - 69세' then age_group2='6569'; 
if age_group='70 - 74세' then age_group2='7074'; 
if age_group='75 - 79세' then age_group2='7579'; 
if age_group='80 - 84세' then age_group2='8084'; 
if age_group='85세 이상' then age_group2='85'; 

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
 
/*여자 */ 

data pop2; 
	set pop; 
	if sex="여자"; 
	if sido<100; 
	if P2005 ^=.;
	*keep code_b sex age_group P2005; 
	drop P2010-P2019; 
	KEY=COMPRESS(sigu)||("-")||COMPRESS(sido);run; 
proc freq data=pop2; table sido; run; 

proc means data=pop2 noprint sum; 
	class age_group;
	var p2005; 
	output out=pop3 sum( p2005)= p2005;
run; 


data pop4; 
	set pop3;
	if _type_=1; 
if age_group='0 - 4세' then age_group2='0004'; 
if age_group='5 - 9세' then age_group2='0509'; 
if age_group='10 - 14세' then age_group2='1014'; 
if age_group='15 - 19세' then age_group2='1519'; 
if age_group='20 - 24세' then age_group2='2024'; 
if age_group='25 - 29세' then age_group2='2529'; 
if age_group='30 - 34세' then age_group2='3034'; 
if age_group='35 - 39세' then age_group2='3539'; 
if age_group='40 - 44세' then age_group2='4044'; 
if age_group='45 - 49세' then age_group2='4549'; 
if age_group='50 - 54세' then age_group2='5054'; 
if age_group='55 - 59세' then age_group2='5559'; 
if age_group='60 - 64세' then age_group2='6064'; 
if age_group='65 - 69세' then age_group2='6569'; 
if age_group='70 - 74세' then age_group2='7074'; 
if age_group='75 - 79세' then age_group2='7579'; 
if age_group='80 - 84세' then age_group2='8084'; 
if age_group='85세 이상' then age_group2='85'; 

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
 
proc sort data=pop4_male ; by year sido; 
proc sort data=pop4_female; by year sido; run; 

data pop6; 
	merge pop4_male pop4_female; 
	by year sido; 
run; 

data stdpop6; 
	merge stdpop4_male stdpop4_female; 
run; 
/*48683039.5*/

data a.pop7; 	
	format key $7.;
	set pop6; 
	if _n_ =1 then set stdpop6; 
	KEY=COMPRESS(year)||("-")||COMPRESS(sido);
	drop year sido; 
run;

/*연도별 인구수 자료*/ 
proc contents data=pop6; run; 

proc sql; create table a.pop_y as select year, sum(pop_male_0004) as pop_male_0004,
sum(pop_male_0509) as pop_male_0509,
sum(pop_male_1014) as pop_male_1014,
sum(pop_male_1519) as pop_male_1519,
sum(pop_male_2024) as pop_male_2024,
sum(pop_male_2529) as pop_male_2529,
sum(pop_male_3034) as pop_male_3034,
sum(pop_male_3539) as pop_male_3539,
sum(pop_male_4044) as pop_male_4044,
sum(pop_male_4549) as pop_male_4549,
sum(pop_male_5054) as pop_male_5054,
sum(pop_male_5559) as pop_male_5559,
sum(pop_male_6064) as pop_male_6064,
sum(pop_male_6569) as pop_male_6569,
sum(pop_male_7074) as pop_male_7074,
sum(pop_male_7579) as pop_male_7579,
sum(pop_male_8084) as pop_male_8084,
sum(pop_male_85) as pop_male_85,
sum(pop_female_0004) as pop_female_0004,
sum(pop_female_0509) as pop_female_0509,
sum(pop_female_1014) as pop_female_1014,
sum(pop_female_1519) as pop_female_1519,
sum(pop_female_2024) as pop_female_2024,
sum(pop_female_2529) as pop_female_2529,
sum(pop_female_3034) as pop_female_3034,
sum(pop_female_3539) as pop_female_3539,
sum(pop_female_4044) as pop_female_4044,
sum(pop_female_4549) as pop_female_4549,
sum(pop_female_5054) as pop_female_5054,
sum(pop_female_5559) as pop_female_5559,
sum(pop_female_6064) as pop_female_6064,
sum(pop_female_6569) as pop_female_6569,
sum(pop_female_7074) as pop_female_7074,
sum(pop_female_7579) as pop_female_7579,
sum(pop_female_8084) as pop_female_8084,
sum(pop_female_85) as pop_female_85 from pop6 group by year; quit; 

proc freq data=a.tot_yy_sido; table sido; run; 

data a.pop_y2; 	format year 4.;
	set pop_y; 
	if _n_ =1 then set stdpop6; 
run;


%macro smr (dis=); 

data dis; 
	format key $7.; 
	set a.&dis._yy_sido ; 
	KEY=COMPRESS(year)||("-")||COMPRESS(sido);
	if sido=. then delete; 
	drop year sido; 
run; 

proc sort data=dis; by key; 
proc sort data=a.pop7; by key; run; 

data dis2; 
	set dis; 
	/*death male+female */ 
		array all(18) &dis._Age_group2_0004_T &dis._Age_group2_0509_T	&dis._Age_group2_1014_T	&dis._Age_group2_1519_T	&dis._Age_group2_2024_T	
								&dis._Age_group2_2529_T	&dis._Age_group2_3034_T	&dis._Age_group2_3539_T	&dis._Age_group2_4044_T	&dis._Age_group2_4549_T	
								&dis._Age_group2_5054_T	&dis._Age_group2_5559_T	&dis._Age_group2_6064_T	&dis._Age_group2_6569_T	&dis._Age_group2_7074_T
								&dis._Age_group2_7579_T	&dis._Age_group2_8084_T	&dis._Age_group2_85_T	;
		array male(18) &dis._Age_group2_0004_M &dis._Age_group2_0509_M	&dis._Age_group2_1014_M	&dis._Age_group2_1519_M	&dis._Age_group2_2024_M	
								&dis._Age_group2_2529_M	&dis._Age_group2_3034_M	&dis._Age_group2_3539_M	&dis._Age_group2_4044_M	&dis._Age_group2_4549_M	
								&dis._Age_group2_5054_M	&dis._Age_group2_5559_M	&dis._Age_group2_6064_M	&dis._Age_group2_6569_M	&dis._Age_group2_7074_M
								&dis._Age_group2_7579_M	&dis._Age_group2_8084_M	&dis._Age_group2_85_M	;
		array female(18) &dis._Age_group2_0004_F &dis._Age_group2_0509_F	&dis._Age_group2_1014_F	&dis._Age_group2_1519_F	&dis._Age_group2_2024_F	
								&dis._Age_group2_2529_F	&dis._Age_group2_3034_F	&dis._Age_group2_3539_F	&dis._Age_group2_4044_F	&dis._Age_group2_4549_F	
								&dis._Age_group2_5054_F	&dis._Age_group2_5559_F	&dis._Age_group2_6064_F	&dis._Age_group2_6569_F	&dis._Age_group2_7074_F
								&dis._Age_group2_7579_F	&dis._Age_group2_8084_F	&dis._Age_group2_85_F	;
		
		do k=1 to 18; 
			all(k)=male(k)+female(k); 
		end; 

data a.pop7_2; 
	set a.pop7; 

	/* populuation male+female */ 
	array allpop(18)pop_all_0004	pop_all_0509	pop_all_1014	pop_all_1519	pop_all_2024	pop_all_2529	pop_all_3034	pop_all_3539	pop_all_4044	pop_all_4549	pop_all_5054	pop_all_5559	pop_all_6064	
							pop_all_6569	pop_all_7074	pop_all_7579	pop_all_8084	pop_all_85 ; 
	array malepop(18) pop_male_0004 pop_male_0509	pop_male_1014	pop_male_1519	pop_male_2024	pop_male_2529	pop_male_3034	pop_male_3539	pop_male_4044	
						pop_male_4549	pop_male_5054	pop_male_5559	pop_male_6064	pop_male_6569	pop_male_7074	pop_male_7579	pop_male_8084	pop_male_85	; 
	array femalepop(18)  pop_female_0004 pop_female_0509	pop_female_1014	pop_female_1519	pop_female_2024	pop_female_2529	pop_female_3034	pop_female_3539	pop_female_4044	
						pop_female_4549	pop_female_5054	pop_female_5559	pop_female_6064	pop_female_6569	pop_female_7074	pop_female_7579	pop_female_8084	pop_female_85	; 
	do k=1 to 18; 
			allpop(k)=malepop(k)+femalepop(k); 
    end; 

	/* std populuation male+female */ 
	array allstdpop(18)stdpop_all_0004	stdpop_all_0509	stdpop_all_1014	stdpop_all_1519	stdpop_all_2024	stdpop_all_2529	stdpop_all_3034	stdpop_all_3539	stdpop_all_4044	stdpop_all_4549	stdpop_all_5054	
							stdpop_all_5559	stdpop_all_6064 stdpop_all_6569	stdpop_all_7074	stdpop_all_7579	stdpop_all_8084	stdpop_all_85 ; 
	array malestdpop(18) stdpop_male_0004 stdpop_male_0509	stdpop_male_1014	stdpop_male_1519	stdpop_male_2024	stdpop_male_2529	stdpop_male_3034	stdpop_male_3539	stdpop_male_4044	
						stdpop_male_4549	stdpop_male_5054	stdpop_male_5559	stdpop_male_6064	stdpop_male_6569	stdpop_male_7074	stdpop_male_7579	stdpop_male_8084	stdpop_male_85	; 
	array femalestdpop(18)  stdpop_female_0004 stdpop_female_0509	stdpop_female_1014	stdpop_female_1519	stdpop_female_2024	stdpop_female_2529	stdpop_female_3034	stdpop_female_3539	stdpop_female_4044	
						stdpop_female_4549	stdpop_female_5054	stdpop_female_5559	stdpop_female_6064	stdpop_female_6569	stdpop_female_7074	stdpop_female_7579	stdpop_female_8084	stdpop_female_85	; 

	do k=1 to 18; 
			allstdpop(k)=malestdpop(k)+femalestdpop(k); 
	end; 
run; 
run; 
data calc; 
	format year 4. sido $2.; 
	merge dis2 a.pop7_2  ; 
	by key; 
	year=substr(key, 1, 4); 
	sido=substr(key, 6, 2); 
run; 

proc contents data=calc out=cont; run;

data calc2; 
	set calc; 
	array death(36) &dis._Age_group2_0004_M &dis._Age_group2_0509_M	&dis._Age_group2_1014_M	&dis._Age_group2_1519_M	&dis._Age_group2_2024_M	
								&dis._Age_group2_2529_M	&dis._Age_group2_3034_M	&dis._Age_group2_3539_M	&dis._Age_group2_4044_M	&dis._Age_group2_4549_M	
								&dis._Age_group2_5054_M	&dis._Age_group2_5559_M	&dis._Age_group2_6064_M	&dis._Age_group2_6569_M	&dis._Age_group2_7074_M
								&dis._Age_group2_7579_M	&dis._Age_group2_8084_M	&dis._Age_group2_85_M	
								&dis._Age_group2_0004_F	&dis._Age_group2_0509_F	&dis._Age_group2_1014_F	&dis._Age_group2_1519_F	&dis._Age_group2_2024_F	
								&dis._Age_group2_2529_F	&dis._Age_group2_3034_F	&dis._Age_group2_3539_F	&dis._Age_group2_4044_F	&dis._Age_group2_4549_F	
								&dis._Age_group2_5054_F	&dis._Age_group2_5559_F	&dis._Age_group2_6064_F	&dis._Age_group2_6569_F	&dis._Age_group2_7074_F	
								&dis._Age_group2_7579_F	&dis._Age_group2_8084_F	&dis._Age_group2_85_F	; 


array pop(36) pop_male_0004 pop_male_0509 pop_male_1014	pop_male_1519	pop_male_2024	pop_male_2529	pop_male_3034	pop_male_3539	pop_male_4044	pop_male_4549	
						pop_male_5054	pop_male_5559	pop_male_6064	pop_male_6569	pop_male_7074	pop_male_7579	pop_male_8084	pop_male_85	
						pop_female_0004	pop_female_0509	pop_female_1014	pop_female_1519	pop_female_2024	pop_female_2529	pop_female_3034	pop_female_3539	pop_female_4044	
						pop_female_4549	pop_female_5054	pop_female_5559	pop_female_6064	pop_female_6569	pop_female_7074	pop_female_7579	pop_female_8084	pop_female_85 ;

array stdpop(36)  stdpop_male_0004 stdpop_male_0509	stdpop_male_1014	stdpop_male_1519	stdpop_male_2024	stdpop_male_2529	stdpop_male_3034	stdpop_male_3539	stdpop_male_4044	
						stdpop_male_4549	stdpop_male_5054	stdpop_male_5559	stdpop_male_6064	stdpop_male_6569	stdpop_male_7074	stdpop_male_7579	stdpop_male_8084	stdpop_male_85	
						stdpop_female_0004	stdpop_female_0509	stdpop_female_1014	stdpop_female_1519	stdpop_female_2024	stdpop_female_2529	stdpop_female_3034	stdpop_female_3539	 stdpop_female_4044
						stdpop_female_4549	stdpop_female_5054	stdpop_female_5559	stdpop_female_6064	stdpop_female_6569	stdpop_female_7074	stdpop_female_7579	stdpop_female_8084	stdpop_female_85 ;

array mr(36) MR_0004_M	MR_0509_M	MR_1014_M	MR_1519_M	MR_2024_M	MR_2529_M	MR_3034_M	MR_3539_M	MR_4044_M	MR_4549_M	MR_5054_M	MR_5559_M	MR_6064_M	
					MR_6569_M	MR_7074_M	MR_7579_M	MR_8084_M	MR_85_M	
					MR_0004_F	MR_0509_F	MR_1014_F	MR_1519_F	MR_2024_F	MR_2529_F	MR_3034_F	MR_3539_F	MR_4044_F	MR_4549_F	MR_5054_F	MR_5559_F	MR_6064_F	
					MR_6569_F	MR_7074_F	MR_7579_F	MR_8084_F	MR_85_F ;



do k = 1 to 36; 
	
	mr(k) = death(k)/pop(k) *stdpop(k);  /*연령별 사망률 * 표준인구*/
end; 

run; 

data a.&dis._yy_sido_SMR_pop;
	set calc2; 
	&dis._smr=sum(of MR_0004_M	MR_0509_M	MR_1014_M	MR_1519_M	MR_2024_M	MR_2529_M	MR_3034_M	MR_3539_M	MR_4044_M	MR_4549_M	MR_5054_M	MR_5559_M	MR_6064_M	
					MR_6569_M	MR_7074_M	MR_7579_M	MR_8084_M	MR_85_M	
					MR_0004_F	MR_0509_F	MR_1014_F	MR_1519_F	MR_2024_F	MR_2529_F	MR_3034_F	MR_3539_F	MR_4044_F	MR_4549_F	MR_5054_F	MR_5559_F	MR_6064_F	
					MR_6569_F	MR_7074_F	MR_7579_F	MR_8084_F	MR_85_F) / 48683040 * 100000; 

&dis._smr0014=sum(of MR_0004_M	MR_0509_M	MR_1014_M	
MR_0004_F	MR_0509_F	MR_1014_F) / 9361682 * 100000; 

&dis._smr65=sum(of MR_6569_M	MR_7074_M	MR_7579_M	MR_8084_M	MR_85_M	
	MR_6569_F	MR_7074_F	MR_7579_F	MR_8084_F	MR_85_F) / 4224735 * 100000; 
	drop k; 
	if &dis._smr^=.; 
run; 

data a.&dis._yy_sido_SMR;
	set a.&dis._yy_sido_SMR_pop;
	drop &dis._Age_group2_0004_M -- MR_85_F	;
run; 


/* age only adjusted smr */


data calc2_ageonly; 
	set calc; 
	array death(18) &dis._Age_group2_0004_T &dis._Age_group2_0509_T	&dis._Age_group2_1014_T	&dis._Age_group2_1519_T	&dis._Age_group2_2024_T	
								&dis._Age_group2_2529_T	&dis._Age_group2_3034_T	&dis._Age_group2_3539_T	&dis._Age_group2_4044_T	&dis._Age_group2_4549_T	
								&dis._Age_group2_5054_T	&dis._Age_group2_5559_T	&dis._Age_group2_6064_T	&dis._Age_group2_6569_T	&dis._Age_group2_7074_T
								&dis._Age_group2_7579_T	&dis._Age_group2_8084_T	&dis._Age_group2_85_T	; 


	array pop(18) pop_all_0004	pop_all_0509	pop_all_1014	pop_all_1519	pop_all_2024	pop_all_2529	pop_all_3034	pop_all_3539	pop_all_4044	pop_all_4549	pop_all_5054	pop_all_5559	pop_all_6064	
							pop_all_6569	pop_all_7074	pop_all_7579	pop_all_8084	pop_all_85 ;
 

	array stdpop(18)  stdpop_all_0004	stdpop_all_0509	stdpop_all_1014	stdpop_all_1519	stdpop_all_2024	stdpop_all_2529	stdpop_all_3034	stdpop_all_3539	stdpop_all_4044	stdpop_all_4549	stdpop_all_5054	
							stdpop_all_5559	stdpop_all_6064	stdpop_all_6569	stdpop_all_7074	stdpop_all_7579	stdpop_all_8084	stdpop_all_85;

	array mr(18) MR_0004_T	MR_0509_T	MR_1014_T	MR_1519_T	MR_2024_T	MR_2529_T	MR_3034_T	MR_3539_T	MR_4044_T	MR_4549_T	MR_5054_T	MR_5559_T	MR_6064_T	MR_6569_T	
							MR_7074_T	MR_7579_T	MR_8084_T	MR_85_T ; 



	do k = 1 to 18; 
	
		mr(k) = death(k)/pop(k) *stdpop(k);  /*연령별 사망률 * 표준인구*/
	end; 

	run; 

data a.&dis._yy_sido_SMR_pop_ageonly;
	set calc2_ageonly; 
	&dis._smr_age=sum(of MR_0004_T	MR_0509_T	MR_1014_T	MR_1519_T	MR_2024_T	MR_2529_T	MR_3034_T	MR_3539_T	MR_4044_T	MR_4549_T	MR_5054_T	
MR_5559_T	MR_6064_T	MR_6569_T	MR_7074_T MR_7579_T	MR_8084_T	MR_85_T)/ 48683040 * 100000; 

&dis._smr0014_age=sum(of MR_0004_T	MR_0509_T	MR_1014_T) / 9361682 * 100000; 

&dis._smr65_age=sum(of MR_6569_T	MR_7074_T MR_7579_T	MR_8084_T	MR_85_T) / 4224735 * 100000; 

	drop k; 
	if &dis._smr_age^=.; 
run; 

data a.&dis._yy_sido_SMR_ageonly;
	set a.&dis._yy_sido_SMR_pop_ageonly;
	drop &dis._Age_group2_0004_T -- MR_85_T	;
run; 

proc sort data=a.&dis._yy_sido_SMR; by key; 
proc sort data=a.&dis._yy_sido_SMR_ageonly ; by key; run; 

data a.&dis._yy_sido_SMR2;
	merge a.&dis._yy_sido_SMR a.&dis._yy_sido_SMR_ageonly (keep=key 	&dis._smr_age &dis._smr0014_age &dis._smr65_age) ;
	by key	;
run; 



%mend smr; 
%smr(dis=TOT); 
%smr(dis=NON_ACC);
%smr(dis=RESP);
%smr(dis=ALRI);
%smr(dis=CVD);
%smr(dis=IHD);

%macro mysum(dis=); 
	/* write out each file to csv */
	PROC EXPORT DATA= A.&dis._YY_SIDO
            OUTFILE= "C:\Users\User\Desktop\RnD\data\death\std_rate\sido\out\yearc\&dis._yy_sido_count.csv" 
            DBMS=CSV REPLACE;
     PUTNAMES=YES;
	RUN;

	PROC EXPORT DATA= A.&dis._yy_sido_smr2(drop=key)
            OUTFILE= "C:\Users\User\Desktop\RnD\data\death\std_rate\sido\out\smr\&dis._yy_sido_smr.csv" 
            DBMS=CSV REPLACE;
     PUTNAMES=YES;
	RUN;

	PROC EXPORT DATA= A.&dis._yy_sido_smr_pop (drop=key)
            OUTFILE= "C:\Users\User\Desktop\RnD\data\death\std_rate\sido\out\pop\&dis._yy_sido_smr_pop.csv" 
            DBMS=CSV REPLACE;
     PUTNAMES=YES;
	RUN;



	PROC EXPORT DATA= A.&dis._yy_sido_smr_pop_ageonly(drop=key)
            OUTFILE= "C:\Users\User\Desktop\RnD\data\death\std_rate\sido\out\pop\&dis._yy_sido_smr_pop_ageonly.csv" 
            DBMS=CSV REPLACE;
     PUTNAMES=YES;
	RUN;

%mend mysum; 
%mysum(dis=TOT); 
%mysum(dis=NON_ACC);
%mysum(dis=RESP);
%mysum(dis=ALRI);
%mysum(dis=CVD);
%mysum(dis=IHD);


%macro smryear (dis=); 

data dis; format year 4.;
	set a.&dis._yy; run; 

proc sort data=dis; by year; 
proc sort data=a.pop_y2; by year; run; 

data dis2; format year 4.;
	set dis; 
	/*death male+female */ 
		array all(18) &dis._Age_group2_0004_T &dis._Age_group2_0509_T	&dis._Age_group2_1014_T	&dis._Age_group2_1519_T	&dis._Age_group2_2024_T	
								&dis._Age_group2_2529_T	&dis._Age_group2_3034_T	&dis._Age_group2_3539_T	&dis._Age_group2_4044_T	&dis._Age_group2_4549_T	
								&dis._Age_group2_5054_T	&dis._Age_group2_5559_T	&dis._Age_group2_6064_T	&dis._Age_group2_6569_T	&dis._Age_group2_7074_T
								&dis._Age_group2_7579_T	&dis._Age_group2_8084_T	&dis._Age_group2_85_T	;
		array male(18) &dis._Age_group2_0004_M &dis._Age_group2_0509_M	&dis._Age_group2_1014_M	&dis._Age_group2_1519_M	&dis._Age_group2_2024_M	
								&dis._Age_group2_2529_M	&dis._Age_group2_3034_M	&dis._Age_group2_3539_M	&dis._Age_group2_4044_M	&dis._Age_group2_4549_M	
								&dis._Age_group2_5054_M	&dis._Age_group2_5559_M	&dis._Age_group2_6064_M	&dis._Age_group2_6569_M	&dis._Age_group2_7074_M
								&dis._Age_group2_7579_M	&dis._Age_group2_8084_M	&dis._Age_group2_85_M	;
		array female(18) &dis._Age_group2_0004_F &dis._Age_group2_0509_F	&dis._Age_group2_1014_F	&dis._Age_group2_1519_F	&dis._Age_group2_2024_F	
								&dis._Age_group2_2529_F	&dis._Age_group2_3034_F	&dis._Age_group2_3539_F	&dis._Age_group2_4044_F	&dis._Age_group2_4549_F	
								&dis._Age_group2_5054_F	&dis._Age_group2_5559_F	&dis._Age_group2_6064_F	&dis._Age_group2_6569_F	&dis._Age_group2_7074_F
								&dis._Age_group2_7579_F	&dis._Age_group2_8084_F	&dis._Age_group2_85_F	;
		
		do k=1 to 18; 
			all(k)=male(k)+female(k); 
		end; 

data a.pop_y3; format year 4.;
	set a.pop_y2; 

	/* populuation male+female */ 
	array allpop(18)pop_all_0004	pop_all_0509	pop_all_1014	pop_all_1519	pop_all_2024	pop_all_2529	pop_all_3034	pop_all_3539	pop_all_4044	pop_all_4549	pop_all_5054	pop_all_5559	pop_all_6064	
							pop_all_6569	pop_all_7074	pop_all_7579	pop_all_8084	pop_all_85 ; 
	array malepop(18) pop_male_0004 pop_male_0509	pop_male_1014	pop_male_1519	pop_male_2024	pop_male_2529	pop_male_3034	pop_male_3539	pop_male_4044	
						pop_male_4549	pop_male_5054	pop_male_5559	pop_male_6064	pop_male_6569	pop_male_7074	pop_male_7579	pop_male_8084	pop_male_85	; 
	array femalepop(18)  pop_female_0004 pop_female_0509	pop_female_1014	pop_female_1519	pop_female_2024	pop_female_2529	pop_female_3034	pop_female_3539	pop_female_4044	
						pop_female_4549	pop_female_5054	pop_female_5559	pop_female_6064	pop_female_6569	pop_female_7074	pop_female_7579	pop_female_8084	pop_female_85	; 
	do k=1 to 18; 
			allpop(k)=malepop(k)+femalepop(k); 
    end; 

	/* std populuation male+female */ 
	array allstdpop(18)stdpop_all_0004	stdpop_all_0509	stdpop_all_1014	stdpop_all_1519	stdpop_all_2024	stdpop_all_2529	stdpop_all_3034	stdpop_all_3539	stdpop_all_4044	stdpop_all_4549	stdpop_all_5054	
							stdpop_all_5559	stdpop_all_6064 stdpop_all_6569	stdpop_all_7074	stdpop_all_7579	stdpop_all_8084	stdpop_all_85 ; 
	array malestdpop(18) stdpop_male_0004 stdpop_male_0509	stdpop_male_1014	stdpop_male_1519	stdpop_male_2024	stdpop_male_2529	stdpop_male_3034	stdpop_male_3539	stdpop_male_4044	
						stdpop_male_4549	stdpop_male_5054	stdpop_male_5559	stdpop_male_6064	stdpop_male_6569	stdpop_male_7074	stdpop_male_7579	stdpop_male_8084	stdpop_male_85	; 
	array femalestdpop(18)  stdpop_female_0004 stdpop_female_0509	stdpop_female_1014	stdpop_female_1519	stdpop_female_2024	stdpop_female_2529	stdpop_female_3034	stdpop_female_3539	stdpop_female_4044	
						stdpop_female_4549	stdpop_female_5054	stdpop_female_5559	stdpop_female_6064	stdpop_female_6569	stdpop_female_7074	stdpop_female_7579	stdpop_female_8084	stdpop_female_85	; 

	do k=1 to 18; 
			allstdpop(k)=malestdpop(k)+femalestdpop(k); 
	end; 
run; 
run; 
data calc; format year 4.; 
	merge dis2 a.pop_y3  ; 
	by year;
run; 

proc contents data=calc out=cont; run;

data calc2; 
	set calc; 
	array death(36) &dis._Age_group2_0004_M &dis._Age_group2_0509_M	&dis._Age_group2_1014_M	&dis._Age_group2_1519_M	&dis._Age_group2_2024_M	
								&dis._Age_group2_2529_M	&dis._Age_group2_3034_M	&dis._Age_group2_3539_M	&dis._Age_group2_4044_M	&dis._Age_group2_4549_M	
								&dis._Age_group2_5054_M	&dis._Age_group2_5559_M	&dis._Age_group2_6064_M	&dis._Age_group2_6569_M	&dis._Age_group2_7074_M
								&dis._Age_group2_7579_M	&dis._Age_group2_8084_M	&dis._Age_group2_85_M	
								&dis._Age_group2_0004_F	&dis._Age_group2_0509_F	&dis._Age_group2_1014_F	&dis._Age_group2_1519_F	&dis._Age_group2_2024_F	
								&dis._Age_group2_2529_F	&dis._Age_group2_3034_F	&dis._Age_group2_3539_F	&dis._Age_group2_4044_F	&dis._Age_group2_4549_F	
								&dis._Age_group2_5054_F	&dis._Age_group2_5559_F	&dis._Age_group2_6064_F	&dis._Age_group2_6569_F	&dis._Age_group2_7074_F	
								&dis._Age_group2_7579_F	&dis._Age_group2_8084_F	&dis._Age_group2_85_F	; 


array pop(36) pop_male_0004 pop_male_0509 pop_male_1014	pop_male_1519	pop_male_2024	pop_male_2529	pop_male_3034	pop_male_3539	pop_male_4044	pop_male_4549	
						pop_male_5054	pop_male_5559	pop_male_6064	pop_male_6569	pop_male_7074	pop_male_7579	pop_male_8084	pop_male_85	
						pop_female_0004	pop_female_0509	pop_female_1014	pop_female_1519	pop_female_2024	pop_female_2529	pop_female_3034	pop_female_3539	pop_female_4044	
						pop_female_4549	pop_female_5054	pop_female_5559	pop_female_6064	pop_female_6569	pop_female_7074	pop_female_7579	pop_female_8084	pop_female_85 ;

array stdpop(36)  stdpop_male_0004 stdpop_male_0509	stdpop_male_1014	stdpop_male_1519	stdpop_male_2024	stdpop_male_2529	stdpop_male_3034	stdpop_male_3539	stdpop_male_4044	
						stdpop_male_4549	stdpop_male_5054	stdpop_male_5559	stdpop_male_6064	stdpop_male_6569	stdpop_male_7074	stdpop_male_7579	stdpop_male_8084	stdpop_male_85	
						stdpop_female_0004	stdpop_female_0509	stdpop_female_1014	stdpop_female_1519	stdpop_female_2024	stdpop_female_2529	stdpop_female_3034	stdpop_female_3539	 stdpop_female_4044
						stdpop_female_4549	stdpop_female_5054	stdpop_female_5559	stdpop_female_6064	stdpop_female_6569	stdpop_female_7074	stdpop_female_7579	stdpop_female_8084	stdpop_female_85 ;

array mr(36) MR_0004_M	MR_0509_M	MR_1014_M	MR_1519_M	MR_2024_M	MR_2529_M	MR_3034_M	MR_3539_M	MR_4044_M	MR_4549_M	MR_5054_M	MR_5559_M	MR_6064_M	
					MR_6569_M	MR_7074_M	MR_7579_M	MR_8084_M	MR_85_M	
					MR_0004_F	MR_0509_F	MR_1014_F	MR_1519_F	MR_2024_F	MR_2529_F	MR_3034_F	MR_3539_F	MR_4044_F	MR_4549_F	MR_5054_F	MR_5559_F	MR_6064_F	
					MR_6569_F	MR_7074_F	MR_7579_F	MR_8084_F	MR_85_F ;



do k = 1 to 36; 
	
	mr(k) = death(k)/pop(k) *stdpop(k);  /*연령별 사망률 * 표준인구*/
end; 

run; 

data a.&dis._yy_SMR_pop;
	set calc2; 
	&dis._smr=sum(of MR_0004_M	MR_0509_M	MR_1014_M	MR_1519_M	MR_2024_M	MR_2529_M	MR_3034_M	MR_3539_M	MR_4044_M	MR_4549_M	MR_5054_M	MR_5559_M	MR_6064_M	
					MR_6569_M	MR_7074_M	MR_7579_M	MR_8084_M	MR_85_M	
					MR_0004_F	MR_0509_F	MR_1014_F	MR_1519_F	MR_2024_F	MR_2529_F	MR_3034_F	MR_3539_F	MR_4044_F	MR_4549_F	MR_5054_F	MR_5559_F	MR_6064_F	
					MR_6569_F	MR_7074_F	MR_7579_F	MR_8084_F	MR_85_F) / 48683040 * 100000; 

&dis._smr0014=sum(of MR_0004_M	MR_0509_M	MR_1014_M	
MR_0004_F	MR_0509_F	MR_1014_F) / 9361682 * 100000; 

&dis._smr65=sum(of MR_6569_M	MR_7074_M	MR_7579_M	MR_8084_M	MR_85_M	
	MR_6569_F	MR_7074_F	MR_7579_F	MR_8084_F	MR_85_F) / 4224735 * 100000; 
	drop k; 
	if &dis._smr^=.; 
run; 

data a.&dis._yy_SMR;
	set a.&dis._yy_SMR_pop;
	drop &dis._Age_group2_0004_M -- MR_85_F	;
run; 


/* age only adjusted smr */


data calc2_ageonly; 
	set calc; 
	array death(18) &dis._Age_group2_0004_T &dis._Age_group2_0509_T	&dis._Age_group2_1014_T	&dis._Age_group2_1519_T	&dis._Age_group2_2024_T	
								&dis._Age_group2_2529_T	&dis._Age_group2_3034_T	&dis._Age_group2_3539_T	&dis._Age_group2_4044_T	&dis._Age_group2_4549_T	
								&dis._Age_group2_5054_T	&dis._Age_group2_5559_T	&dis._Age_group2_6064_T	&dis._Age_group2_6569_T	&dis._Age_group2_7074_T
								&dis._Age_group2_7579_T	&dis._Age_group2_8084_T	&dis._Age_group2_85_T	; 


	array pop(18) pop_all_0004	pop_all_0509	pop_all_1014	pop_all_1519	pop_all_2024	pop_all_2529	pop_all_3034	pop_all_3539	pop_all_4044	pop_all_4549	pop_all_5054	pop_all_5559	pop_all_6064	
							pop_all_6569	pop_all_7074	pop_all_7579	pop_all_8084	pop_all_85 ;
 

	array stdpop(18)  stdpop_all_0004	stdpop_all_0509	stdpop_all_1014	stdpop_all_1519	stdpop_all_2024	stdpop_all_2529	stdpop_all_3034	stdpop_all_3539	stdpop_all_4044	stdpop_all_4549	stdpop_all_5054	
							stdpop_all_5559	stdpop_all_6064	stdpop_all_6569	stdpop_all_7074	stdpop_all_7579	stdpop_all_8084	stdpop_all_85;

	array mr(18) MR_0004_T	MR_0509_T	MR_1014_T	MR_1519_T	MR_2024_T	MR_2529_T	MR_3034_T	MR_3539_T	MR_4044_T	MR_4549_T	MR_5054_T	MR_5559_T	MR_6064_T	MR_6569_T	
							MR_7074_T	MR_7579_T	MR_8084_T	MR_85_T ; 



	do k = 1 to 18; 
	
		mr(k) = death(k)/pop(k) *stdpop(k);  /*연령별 사망률 * 표준인구*/
	end; 

	run; 

data a.&dis._yy_SMR_pop_ageonly;
	set calc2_ageonly; 
	&dis._smr_age=sum(of MR_0004_T	MR_0509_T	MR_1014_T	MR_1519_T	MR_2024_T	MR_2529_T	MR_3034_T	MR_3539_T	MR_4044_T	MR_4549_T	MR_5054_T	
MR_5559_T	MR_6064_T	MR_6569_T	MR_7074_T MR_7579_T	MR_8084_T	MR_85_T)/ 48683040 * 100000; 

&dis._smr0014_age=sum(of MR_0004_T	MR_0509_T	MR_1014_T) / 9361682 * 100000; 

&dis._smr65_age=sum(of MR_6569_T	MR_7074_T MR_7579_T	MR_8084_T	MR_85_T) / 4224735 * 100000; 

	drop k; 
	if &dis._smr_age^=.; 
run; 

data a.&dis._yy_SMR_ageonly;
	set a.&dis._yy_SMR_pop_ageonly;
	drop &dis._Age_group2_0004_T -- MR_85_T	;
run; 

proc sort data=a.&dis._yy_SMR; by year;
proc sort data=a.&dis._yy_SMR_ageonly ; by year; run; 

data a.&dis._yy_SMR2;
	merge a.&dis._yy_SMR a.&dis._yy_SMR_ageonly (keep=year 	&dis._smr_age &dis._smr0014_age &dis._smr65_age) ;
	by year;
run; 



%mend smryear; 
%smryear(dis=TOT); 
%smryear(dis=NON_ACC);
%smryear(dis=RESP);
%smryear(dis=ALRI);
%smryear(dis=CVD);
%smryear(dis=IHD);

%macro mysum2(dis=); 
	/* write out each file to csv */
	PROC EXPORT DATA= A.&dis._YY
            OUTFILE= "C:\Users\User\Desktop\RnD\data\death\std_rate\sido\out\yearc\&dis._yy_count.csv" 
            DBMS=CSV REPLACE;
     PUTNAMES=YES;
	RUN;

	PROC EXPORT DATA= A.&dis._yy_smr2
            OUTFILE= "C:\Users\User\Desktop\RnD\data\death\std_rate\sido\out\smr\&dis._yy_smr.csv" 
            DBMS=CSV REPLACE;
     PUTNAMES=YES;
	RUN;

	PROC EXPORT DATA= A.&dis._yy_smr_pop
            OUTFILE= "C:\Users\User\Desktop\RnD\data\death\std_rate\sido\out\pop\&dis._yy_smr_pop.csv" 
            DBMS=CSV REPLACE;
     PUTNAMES=YES;
	RUN;



	PROC EXPORT DATA= A.&dis._yy_smr_pop_ageonly
            OUTFILE= "C:\Users\User\Desktop\RnD\data\death\std_rate\sido\out\pop\&dis._yy_smr_pop_ageonly.csv" 
            DBMS=CSV REPLACE;
     PUTNAMES=YES;
	RUN;

%mend mysum2; 
%mysum2(dis=TOT); 
%mysum2(dis=NON_ACC);
%mysum2(dis=RESP);
%mysum2(dis=ALRI);
%mysum2(dis=CVD);
%mysum2(dis=IHD);
