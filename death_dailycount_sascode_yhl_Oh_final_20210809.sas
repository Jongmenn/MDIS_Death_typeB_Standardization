/********************************************************************************************************************/
/********************************************************************************************************************/

/*작업공간 */
libname a 'F:\2020projects\bae\KEITI\research\2.사망\B형 사망자료(2010-2019)\outdata';

/*사망자료 b형*/
libname b 'F:\2020projects\bae\KEITI\research\2.사망\B형 사망자료(2010-2019)';

/*data 저장 위치 이름 지정해서 가져오기, CSV만  */
data b1;
keep fname;
rc=filename("mydir","F:\2020projects\bae\KEITI\research\2.사망\B형 사망자료(2010-2019)\deathdata");
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
call symput('file',trim(cats('F:\2020projects\bae\KEITI\research\2.사망\B형 사망자료(2010-2019)\deathdata\',fname,"")));run;
proc import out=y&i datafile="&file" DBMS=CSV;  RUN;
%end;
%mend;

%importFile;
/********************************************************************************************************************/
/********************************************************************************************************************/
/*자료 merge */
data a.all; set y1-y10; run; /*2010-2019*/

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
RETAIN var7 var4 SGG var6 var9 var14 ;  /*변수순서: 사망년월일 시도 시군구 성별 연령그룹 사망원인103 */
LENGTH SGG $5; /*시군구 5자리 */
set A.all;

/*label 변경 */
RENAME VAR4=SIDO  VAR6=SEX VAR7=DEATHDATE VAR9=AGE_GROUP VAR14=DEATH103 ;

/*시군구 5자리 */
SGG=var4*1000+var5; 

/*사망 년 월 일 */
YEAR   =SUBSTR(LEFT(VAR7),1,4);
MONTH=SUBSTR(LEFT(VAR7),5,2);
DAY    =SUBSTR(LEFT(VAR7),7,2);

/*연령 그룹 분류*/
KEEP  VAR4 SGG VAR6 VAR7 VAR9 VAR14 YEAR MONTH DAY AGE_GROUP;
run;

proc freq data=a.all_r noprint; table sgg*year*age_group /out=myfreq2; run; 
 

/********************************************************************************************************************/
/********************************************************************************************************************/


/*통계청 사망원인통계 A형 자료 연령 missing 제외한 자료랑  전체 사망(all-cause) N수 동일 n=2,749,704 */
DATA A.ALL_R2; SET A.ALL_R;
/*연령 그룹 99 제외 (MISSING)*/
IF AGE_GROUP^=99;
 
iF AGE_GROUP=1 THEN  AG=0;  /*연령 그룹 0세 */
ELSE IF AGE_GROUP>=2 & AGE_GROUP<5 THEN AG=1;   /*연령 그룹 2~14세 */
ELSE IF AGE_GROUP>=5 & AGE_GROUP<15 THEN AG=2;  /*연령 그룹 15~64세 */
ELSE AG=3;/*연령 그룹 65세+ */

/* 0-4세 다르게 정의 */ 
if age_group in (1, 2) then age_group2=2; /* 0-4세*/
else age_group2=age_group;  					/*나머지는 동일 */

/*시군구 2019년 기준으로 맞춰주기 (젤마지막 연도로 ) N=261 -> N250*/
/*레코드에 없는 시군구 존재(N=11): 
33040 통합청주시  
34010 천안시 
35010 전주시  
37010 포항시  
38110 통합창원시 
31010 수원시 
31020 성남시 
31040 안양시 
31090 평택시 
31100 고양시 
31190 용인시*/

/*변경 시군구 */ 
/*추후 검토 */
SGG_RAW=SGG;
IF SGG=23030 THEN SGG=23090; ELSE SGG=SGG;  /*미추홀구(남구)*/
IF SGG=34320 THEN SGG=29010; ELSE SGG=SGG; /*연기군   ->세종시 */
IF SGG=34390 THEN SGG=34080; ELSE SGG=SGG; /*당진군   ->당진시*/

IF SGG=31320 THEN SGG=31280; ELSE SGG=SGG; /*여주군 -> 여주시*/
IF SGG=33010 THEN SGG=33040; ELSE SGG=SGG; /*청주시   ->청주시*/
IF SGG=33310 THEN SGG=33044; ELSE SGG=SGG; /*청원군-> 청원구*/
IF SGG=33011 THEN SGG=33041; ELSE SGG=SGG; /*청주시 상당구 코드명만 변경*/
IF SGG=33012 THEN SGG=33043; ELSE SGG=SGG; /*청주시 흥덕구 코드명만 변경*/
IF SGG=31051 THEN SGG=31050; ELSE SGG=SGG; /*부천시 원미구 ->부천시 통합*/
IF SGG=31052 THEN SGG=31050; ELSE SGG=SGG; /*부천시 소사구 ->부천시 통합*/
IF SGG=31053 THEN SGG=31050; ELSE SGG=SGG;  /*부천시 오정구 ->부천시 통합*/

/*시군구 한개 기준년도로 변경 후 MERGE 키 만들기 (사망년월일+시군구)*/
KEY=COMPRESS(DEATHDATE)||("-")||COMPRESS(SGG);
DROP DEATH56 ;
RUN;  

proc freq data=a.all_r2 (where=(age_group2=16)) noprint; table year*sgg /out=myfreq; run; 
proc freq data=myfreq; table sgg; run;


PROC FREQ DATA= A.ALL_R2 noprint ; TABLES SGG/ out=mysgg; RUN;


/*주요 변수 결측 있나 확인 : 시도 시군구 성별 연령그룹 사망원인*/
PROC FREQ DATA=A.ALL_R2; TABLES SIDO SGG SEX AGE_GROUP AGE_GROUP2 DEATH103 AG; RUN;

/********************************************************************************************************************/
/********************************************************************************************************************/

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
if DEATH103=71 then othercvd=1; else othercvd=0;                   /*나머지 순환계통 질환*/
if DEATH103=68 then otherheart=1; else otherheart=0;                /*기타 심장 질환(Other heart diseases) */

if DEATH103 >=73 & DEATH103 <=77 then resp=1; else resp=0;  /*전체호흡기 */
if DEATH103>=74 & DEATH103<=75 then alri=1; else alri=0;	        /*하부호흡기감염 */
if DEATH103=73 then infl=1; else infl=0;				                   /*인플루엔자 */
if DEATH103=76 then lrd=1; else lrd=0;                                    /*만성 하기도 질환(Chronic lower respiratory diseases)*/
if DEATH103=77 then otherresp=1; else otherresp=0;                 /*나머지 호흡계통 질환 */

if DEATH103=34 then lungc=1; else lungc=0;				               /*폐암*/
if DEATH103=31 then livc=1; else livc=0;				                   /*간암 */

if DEATH103=93 then cano=1;else cano=0;				               /*선천 기형, 변형 및 염색체이상*/
if DEATH103=88 then misc=1;else misc=0;				               /*유산*/

if DEATH103=60 then alz=1; else alz=0;  				                   /*알츠하이머병(Alzheimer's disease) */
if DEATH103=61 then othernerv=1; else othernerv=0;                 /*나머지 신경계통 질환*/

if DEATH103=65 then rheum=1; else rheum=0;                         /*급성 류마티스열 및 만성 류마티스 심장 질환*/
if DEATH103=63 then ear=1; else ear=0;  				                   /*귀 및 유돌의 질환 (Diseases of the ear and mastoid process)*/
if DEATH103=62 then eye=1; else eye=0;  				               /*눈 및 눈부속기의 질환 (Diseases of the eye and adnexa) */

if DEATH103=52 then dm=1; else dm=0; 					               /*당뇨병(Diabetes mellitus) */
if DEATH103=54 then endo=1; else endo=0;  			 	           /*나머지 내분비, 영양 및 대사 질환 */

if DEATH103=85 then kidney=1; else kidney=0;                         /*사구체 질환 및 세뇨관-간질 질환 */
if DEATH103=86 then otherkidney=1; else otherkidney=0;            /*나머지 비뇨생식계통 질환 */

if DEATH103=56 then mental=1; else mental=0;                         /*정신활성물질 사용에 의한 정신 및 행동장애*/
if DEATH103=57 then othermental=1; else othermental=0;            /*나머지 정신 및 행동 장애*/

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
sum(endo) as endo, sum(eye) as eye, sum(htn) as htn, sum(ihd) as ihd, sum(kidney) as kidney, sum(lrd) as lrd, sum(mental) as mental, sum(othercvd) as othercvd, 
sum(otherheart) as otherheart, sum(otherkidney) as otherkidney, sum(othermental) as othermental, sum(othernerv) as othernerv, sum(otherresp) as otherresp, sum(rheum) as rheum from
a.DEATH GROUP BY YEAR; QUIT;

/*전체 합계  */
proc sql; create table z_TOT as select sum(tot) as tot, sum(non_acc) as non_acc , sum(resp) as resp, sum(alri) as alri, sum(infl) as infl, sum(cvd) as cvd, sum(cano) as cano,
sum(misc) as misc, sum(lungc) as lungc, sum(livc) as livc, sum(suid) as suid, sum(alz) as alz, sum(ather) as ather, sum(cerbv) as cerbv, sum(dm) as dm, sum(ear) as ear,
sum(endo) as endo, sum(eye) as eye, sum(htn) as htn, sum(ihd) as ihd, sum(kidney) as kidney, sum(lrd) as lrd, sum(mental) as mental, sum(othercvd) as othercvd, 
sum(otherheart) as otherheart, sum(otherkidney) as otherkidney, sum(othermental) as othermental, sum(othernerv) as othernerv, sum(otherresp) as otherresp, sum(rheum) as rheum from
a.DEATH ; QUIT;

/*위 두개 테이블 결합 */
DATA ZZ; SET Z_YEAR Z_TOT;
IF YEAR="" THEN YEAR="Total"; ELSE YEAR=YEAR;run;
/********************************************************************************************************************/
/********************************************************************************************************************/

/*날짜 자료 만들기*/
/*기준연도랑 기준연도에 해당하는 시군구 조합해서 시군구별 날짜 생성하기 */


/*원래 자료에서 기준연도에 해당하는 시군구만 가져오기  */
DATA A.SGG; SET A.DEATH; KEEP SGG; RUN; 

/*고유 시군구만 남기기  */
PROC SORT DATA= A.SGG NODUPKEY ; BY SGG; RUN;

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
proc sql; create table a.SGGDATE as select * from a.ddate cross join  a.sgg; quit;

/*KEY값 만 남기기 KEY=날짜+시군구  (날짜와 시군구 조합별 일자 계산, 3652일 * 250 =913000) */
DATA a.Sggdate; SET a.Sggdate; KEY=COMPRESS(DATE2)||("-")||COMPRESS(SGG); KEEP KEY; RUN;


/* 사망원인별 연도별 카운트 자료 만드는 매크로 */
%MACRO DEATH(CAUSE);

/*사망 원시자료에서 연도 추출 하고 필요변수만 추출  */
DATA A.Z1 ; SET A.DEATH;
RENAME &CAUSE=D; /*DISEASE(사망원인 지정할 변수)*/
KEEP KEY DEATHDATE SIDO SGG SEX   YEAR AG age_group2 &CAUSE.; 
RUN;

/*위에서 정리한 자료에서 성, 연령, 성*연령 조합 구분 */
DATA A.Z2; SET A.Z1;

/*성별 */
IF SEX=1 & D=1 THEN &CAUSE._SEX_M=1; ELSE &CAUSE._SEX_M=0;
IF SEX=2 & D=1 THEN &CAUSE._SEX_F=1; ELSE &CAUSE._SEX_F=0;

/*연령 그룹별 0:0세 1:1~14세 2:15-64세, 3: 65세 이상 */
IF AG=0 & D=1 THEN &CAUSE._AG00=1   ; ELSE &CAUSE._AG00=0;
IF AG in (0, 1) & D=1 THEN &CAUSE._AG0014=1; ELSE &CAUSE._AG0014=0;
IF AG=2 & D=1 THEN &CAUSE._AG1564=1; ELSE &CAUSE._AG1564=0;
IF AG=3 & D=1 THEN &CAUSE._AG65=1;    ELSE &CAUSE._AG65=0;

/*남성 * 연령 그룹별  */
IF SEX=1 & AG=0 & D=1 THEN &CAUSE._AG00_M=1; ELSE &CAUSE._AG00_M=0;
IF SEX=1 & AG in (0, 1) & D=1 THEN &CAUSE._AG0014_M=1; ELSE &CAUSE._AG0014_M=0;
IF SEX=1 & AG=2 & D=1 THEN &CAUSE._AG1564_M=1; ELSE &CAUSE._AG1564_M=0;
IF SEX=1 & AG=3 & D=1 THEN &CAUSE._AG65_M=1; ELSE &CAUSE._AG65_M=0;

/*여성 * 연령 그룹별  */
IF SEX=2 & AG=0 & D=1 THEN &CAUSE._AG00_F=1; ELSE &CAUSE._AG00_F=0;
IF SEX=2 & AG in (0, 1) & D=1 THEN &CAUSE._AG0014_F=1; ELSE &CAUSE._AG0014_F=0;
IF SEX=2 & AG=2 & D=1 THEN &CAUSE._AG1564_F=1; ELSE &CAUSE._AG1564_F=0;
IF SEX=2 & AG=3 & D=1 THEN &CAUSE._AG65_F=1; ELSE &CAUSE._AG65_F=0;


/*** 표준화사망률 계산용 성연령 */
/*남성 * 연령 그룹별  */
IF SEX=1 & Age_group2=2  & D=1 THEN &CAUSE._Age_group2_02_M=1; ELSE &CAUSE._Age_group2_02_M=0; /*0-4세 남 */
IF SEX=1 & Age_group2=3  & D=1 THEN &CAUSE._Age_group2_03_M=1; ELSE &CAUSE._Age_group2_03_M=0; /*5-9세 남 */
IF SEX=1 & Age_group2=4  & D=1 THEN &CAUSE._Age_group2_04_M=1; ELSE &CAUSE._Age_group2_04_M=0; /*10-14세 남 */
IF SEX=1 & Age_group2=5  & D=1 THEN &CAUSE._Age_group2_05_M=1; ELSE &CAUSE._Age_group2_05_M=0; /*15-19세 남 */
IF SEX=1 & Age_group2=6  & D=1 THEN &CAUSE._Age_group2_06_M=1; ELSE &CAUSE._Age_group2_06_M=0; /*20-24세 남 */
IF SEX=1 & Age_group2=7  & D=1 THEN &CAUSE._Age_group2_07_M=1; ELSE &CAUSE._Age_group2_07_M=0; /*25-29세 남 */
IF SEX=1 & Age_group2=8  & D=1 THEN &CAUSE._Age_group2_08_M=1; ELSE &CAUSE._Age_group2_08_M=0; /*30-34세 남 */
IF SEX=1 & Age_group2=9  & D=1 THEN &CAUSE._Age_group2_09_M=1; ELSE &CAUSE._Age_group2_09_M=0; /*35-39세 남 */
IF SEX=1 & Age_group2=10 & D=1 THEN &CAUSE._Age_group2_10_M=1; ELSE &CAUSE._Age_group2_10_M=0; /*40-44세 남 */
IF SEX=1 & Age_group2=11 & D=1 THEN &CAUSE._Age_group2_11_M=1; ELSE &CAUSE._Age_group2_11_M=0; /*45-49세 남 */
IF SEX=1 & Age_group2=12 & D=1 THEN &CAUSE._Age_group2_12_M=1; ELSE &CAUSE._Age_group2_12_M=0; /*50-54세 남 */
IF SEX=1 & Age_group2=13 & D=1 THEN &CAUSE._Age_group2_13_M=1; ELSE &CAUSE._Age_group2_13_M=0; /*55-59세 남 */
IF SEX=1 & Age_group2=14 & D=1 THEN &CAUSE._Age_group2_14_M=1; ELSE &CAUSE._Age_group2_14_M=0; /*60-64세 남 */
IF SEX=1 & Age_group2=15 & D=1 THEN &CAUSE._Age_group2_15_M=1; ELSE &CAUSE._Age_group2_15_M=0; /*65-69세 남 */
IF SEX=1 & Age_group2=16 & D=1 THEN &CAUSE._Age_group2_16_M=1; ELSE &CAUSE._Age_group2_16_M=0; /*70-74세 남 */
IF SEX=1 & Age_group2=17 & D=1 THEN &CAUSE._Age_group2_17_M=1; ELSE &CAUSE._Age_group2_17_M=0; /*75-79세 남 */
IF SEX=1 & Age_group2=18 & D=1 THEN &CAUSE._Age_group2_18_M=1; ELSE &CAUSE._Age_group2_18_M=0; /*80-84세 남 */
IF SEX=1 & Age_group2=19 & D=1 THEN &CAUSE._Age_group2_19_M=1; ELSE &CAUSE._Age_group2_19_M=0; /*85+세 남 */


/*여성 * 연령 그룹별  */
IF SEX=2 & Age_group2=2  & D=1 THEN &CAUSE._Age_group2_02_F=1; ELSE &CAUSE._Age_group2_02_F=0; /*0-4세 여 */
IF SEX=2 & Age_group2=3  & D=1 THEN &CAUSE._Age_group2_03_F=1; ELSE &CAUSE._Age_group2_03_F=0; /*5-9세 여 */
IF SEX=2 & Age_group2=4  & D=1 THEN &CAUSE._Age_group2_04_F=1; ELSE &CAUSE._Age_group2_04_F=0; /*10-14세 여 */
IF SEX=2 & Age_group2=5  & D=1 THEN &CAUSE._Age_group2_05_F=1; ELSE &CAUSE._Age_group2_05_F=0; /*15-19세 여 */
IF SEX=2 & Age_group2=6  & D=1 THEN &CAUSE._Age_group2_06_F=1; ELSE &CAUSE._Age_group2_06_F=0; /*20-24세 여 */
IF SEX=2 & Age_group2=7  & D=1 THEN &CAUSE._Age_group2_07_F=1; ELSE &CAUSE._Age_group2_07_F=0; /*25-29세 여 */
IF SEX=2 & Age_group2=8  & D=1 THEN &CAUSE._Age_group2_08_F=1; ELSE &CAUSE._Age_group2_08_F=0; /*30-34세 여 */
IF SEX=2 & Age_group2=9  & D=1 THEN &CAUSE._Age_group2_09_F=1; ELSE &CAUSE._Age_group2_09_F=0; /*35-39세 여 */
IF SEX=2 & Age_group2=10 & D=1 THEN &CAUSE._Age_group2_10_F=1; ELSE &CAUSE._Age_group2_10_F=0; /*40-44세 여 */
IF SEX=2 & Age_group2=11 & D=1 THEN &CAUSE._Age_group2_11_F=1; ELSE &CAUSE._Age_group2_11_F=0; /*45-49세 여 */
IF SEX=2 & Age_group2=12 & D=1 THEN &CAUSE._Age_group2_12_F=1; ELSE &CAUSE._Age_group2_12_F=0; /*50-54세 여 */
IF SEX=2 & Age_group2=13 & D=1 THEN &CAUSE._Age_group2_13_F=1; ELSE &CAUSE._Age_group2_13_F=0; /*55-59세 여 */
IF SEX=2 & Age_group2=14 & D=1 THEN &CAUSE._Age_group2_14_F=1; ELSE &CAUSE._Age_group2_14_F=0; /*60-64세 여 */
IF SEX=2 & Age_group2=15 & D=1 THEN &CAUSE._Age_group2_15_F=1; ELSE &CAUSE._Age_group2_15_F=0; /*65-69세 여 */
IF SEX=2 & Age_group2=16 & D=1 THEN &CAUSE._Age_group2_16_F=1; ELSE &CAUSE._Age_group2_16_F=0; /*70-74세 여 */
IF SEX=2 & Age_group2=17 & D=1 THEN &CAUSE._Age_group2_17_F=1; ELSE &CAUSE._Age_group2_17_F=0; /*75-79세 여 */
IF SEX=2 & Age_group2=18 & D=1 THEN &CAUSE._Age_group2_18_F=1; ELSE &CAUSE._Age_group2_18_F=0; /*80-84세 여 */
IF SEX=2 & Age_group2=19 & D=1 THEN &CAUSE._Age_group2_19_F=1; ELSE &CAUSE._Age_group2_19_F=0; /*85+세 여 */

/*위에서 정리한 변수에 대해서 카운트 자료 산출 -> 즉 이자료는 사망에 대한  시군구별 데일리 카운트 (사망원인 B형) (연도별) */
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



/*데일리 카운트 한 자료를 연도별 시군구 자료랑 merge하기 
  (missing값 채워주기 위해서)*/
/*위에서 먼저 생성한 시군구+날짜 자료를 기준으로 LEFT JOIN */
PROC SQL; CREATE TABLE A.&CAUSE._Daily_Count AS SELECT * FROM A.SGGDATE AS A  LEFT JOIN A.&CAUSE. AS B ON A.KEY=B.KEY; QUIT;

/*MISSING VALUE 0으로 채워주기 */
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



/*날짜 및 시도, 시군구 수정 */
DATE=SUBSTR(KEY,1,8);
YEAR=SUBSTR(KEY,1,4);
MONTH=SUBSTR(KEY,5,2);
DAY =SUBSTR(KEY,7,2);
SIDO=SUBSTR(KEY,10,2);
SGG=SUBSTR(KEY,10,5); /*시군구 원자료 */
RUN;
%MEND;

/*시군구별 데일리 사망 자료 -질환별로 */
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

/*시군구 체크 전체랑 CVD만 */
PROC FREQ DATA=A.TOT_R; TABLES SGG; RUN;
PROC FREQ DATA=A.CVD_R; TABLES SGG; RUN;

/*전체 카운트 비교 */
%MACRO CNT(CAUSE);
/*질환에 대한 사망 총 합계 */
PROC SQL; CREATE TABLE A.&CAUSE._COUNT AS SELECT SUM(&CAUSE.) AS &CAUSE. , SUM(&CAUSE._SEX_M) AS &CAUSE._SEX_M , 
SUM(&CAUSE._SEX_F) AS &CAUSE._SEX_F , SUM(&CAUSE._AG00) AS &CAUSE._AG00,
SUM(&CAUSE._AG0014) AS &CAUSE._AG0014, SUM(&CAUSE._AG1564) AS &CAUSE._AG1564, SUM(&CAUSE._AG65) AS &CAUSE._AG65,

SUM(&CAUSE._AG00_M) AS &CAUSE._AG00_M       ,  SUM(&CAUSE._AG0014_M) AS &CAUSE._AG0014_M , 
SUM(&CAUSE._AG1564_M) AS &CAUSE._AG1564_M ,  SUM(&CAUSE._AG65_M) AS &CAUSE._AG65_M , 
SUM(&CAUSE._AG00_F) AS &CAUSE._AG00_F        ,  SUM(&CAUSE._AG0014_F) AS &CAUSE._AG0014_F , 
SUM(&CAUSE._AG1564_F) AS &CAUSE._AG1564_F ,  SUM(&CAUSE._AG65_F) AS &CAUSE._AG65_F  FROM A.&CAUSE._Daily_Count  ; QUIT;

/*시군구별 질환에 대한 사망 합계  */
PROC SQL; CREATE TABLE A.&CAUSE._SGG_Count AS SELECT SGG, SUM(&CAUSE.) AS &CAUSE. , SUM(&CAUSE._SEX_M) AS &CAUSE._SEX_M , 
SUM(&CAUSE._SEX_F) AS &CAUSE._SEX_F , SUM(&CAUSE._AG00) AS &CAUSE._AG00,
SUM(&CAUSE._AG0014) AS &CAUSE._AG0014, SUM(&CAUSE._AG1564) AS &CAUSE._AG1564, SUM(&CAUSE._AG65) AS &CAUSE._AG65,
SUM(&CAUSE._AG00_M) AS &CAUSE._AG00_M ,  SUM(&CAUSE._AG0014_M) AS &CAUSE._AG0014_M , 
SUM(&CAUSE._AG1564_M) AS &CAUSE._AG1564_M ,  SUM(&CAUSE._AG65_M) AS &CAUSE._AG65_M , 
SUM(&CAUSE._AG00_F) AS &CAUSE._AG00_F ,  SUM(&CAUSE._AG0014_F) AS &CAUSE._AG0014_F , 
SUM(&CAUSE._AG1564_F) AS &CAUSE._AG1564_F ,  SUM(&CAUSE._AG65_F) AS &CAUSE._AG65_F  FROM A.&CAUSE._Daily_Count  GROUP BY SGG ; QUIT;

/*연도별 질환에 대한 사망  합계 */
PROC SQL; CREATE TABLE A.&CAUSE._YEAR_Count AS SELECT YEAR, SUM(&CAUSE.) AS &CAUSE. , SUM(&CAUSE._SEX_M) AS &CAUSE._SEX_M , 
SUM(&CAUSE._SEX_F) AS &CAUSE._SEX_F , SUM(&CAUSE._AG00) AS &CAUSE._AG00,
SUM(&CAUSE._AG0014) AS &CAUSE._AG0014, SUM(&CAUSE._AG1564) AS &CAUSE._AG1564, SUM(&CAUSE._AG65) AS &CAUSE._AG65,
SUM(&CAUSE._AG00_M) AS &CAUSE._AG00_M ,  SUM(&CAUSE._AG0014_M) AS &CAUSE._AG0014_M , 
SUM(&CAUSE._AG1564_M) AS &CAUSE._AG1564_M ,  SUM(&CAUSE._AG65_M) AS &CAUSE._AG65_M , 
SUM(&CAUSE._AG00_F) AS &CAUSE._AG00_F ,  SUM(&CAUSE._AG0014_F) AS &CAUSE._AG0014_F , 
SUM(&CAUSE._AG1564_F) AS &CAUSE._AG1564_F ,  SUM(&CAUSE._AG65_F) AS &CAUSE._AG65_F  FROM A.&CAUSE._Daily_Count GROUP BY YEAR ; QUIT;

/*연도별*시군구별  질환에 대한 사망  합계 */
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
/*질환별 전체 시군구별, 연도별, 시군구별 연도별 카운트*/
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

/*연도별 시군구 자료에서 특정 시군구 하나만 보기 */

data z; set a.Tot_yy_sgg_count;
if sgg=11010; run;

/* 연도별 시군구 연도별 성연령별 */ 

/* 인구 읽어오기 */

/*연도별 인구*/
PROC IMPORT OUT= WORK.pop 
            DATAFILE= "F:\2020projects\bae\KEITI\research\2.사망\B형 사망자료(2010-2019)\연앙인구_시군구_final.csv" 
            DBMS=CSV REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
RUN;

/*연도별 인구 */ 
data pop2; 
	set pop; 
	if sex="남자"; 
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
if age_group='0 - 4세' then age_group2=2; 
if age_group='5 - 9세' then age_group2=3; 
if age_group='10 - 14세' then age_group2=4; 
if age_group='15 - 19세' then age_group2=5; 
if age_group='20 - 24세' then age_group2=6; 
if age_group='25 - 29세' then age_group2=7; 
if age_group='30 - 34세' then age_group2=8; 
if age_group='35 - 39세' then age_group2=9; 
if age_group='40 - 44세' then age_group2=10; 
if age_group='45 - 49세' then age_group2=11; 
if age_group='50 - 54세' then age_group2=12; 
if age_group='55 - 59세' then age_group2=13; 
if age_group='60 - 64세' then age_group2=14; 
if age_group='65 - 69세' then age_group2=15; 
if age_group='70 - 74세' then age_group2=16; 
if age_group='75 - 79세' then age_group2=17; 
if age_group='80 - 84세' then age_group2=18; 
if age_group='85세 이상' then age_group2=19; 

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
 
/*여자 */ 

data pop2; 
	set pop; 
	if sex="여자"; 
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
if age_group='0 - 4세' then age_group2=2; 
if age_group='5 - 9세' then age_group2=3; 
if age_group='10 - 14세' then age_group2=4; 
if age_group='15 - 19세' then age_group2=5; 
if age_group='20 - 24세' then age_group2=6; 
if age_group='25 - 29세' then age_group2=7; 
if age_group='30 - 34세' then age_group2=8; 
if age_group='35 - 39세' then age_group2=9; 
if age_group='40 - 44세' then age_group2=10; 
if age_group='45 - 49세' then age_group2=11; 
if age_group='50 - 54세' then age_group2=12; 
if age_group='55 - 59세' then age_group2=13; 
if age_group='60 - 64세' then age_group2=14; 
if age_group='65 - 69세' then age_group2=15; 
if age_group='70 - 74세' then age_group2=16; 
if age_group='75 - 79세' then age_group2=17; 
if age_group='80 - 84세' then age_group2=18; 
if age_group='85세 이상' then age_group2=19; 

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
 

/*표준 인구 */ 
/* 시도합한 값만 불러 읽기 */
PROC IMPORT OUT= WORK.pop 
            DATAFILE= "F:\2020projects\bae\KEITI\research\2.사망\B형 사망자료(2010-2019)\연앙인구_시도_final.csv" 
            DBMS=CSV REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
RUN;


data pop2; 
	set pop; 
	if sex="남자"; 
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
if age_group='0 - 4세' then age_group2=2; 
if age_group='5 - 9세' then age_group2=3; 
if age_group='10 - 14세' then age_group2=4; 
if age_group='15 - 19세' then age_group2=5; 
if age_group='20 - 24세' then age_group2=6; 
if age_group='25 - 29세' then age_group2=7; 
if age_group='30 - 34세' then age_group2=8; 
if age_group='35 - 39세' then age_group2=9; 
if age_group='40 - 44세' then age_group2=10; 
if age_group='45 - 49세' then age_group2=11; 
if age_group='50 - 54세' then age_group2=12; 
if age_group='55 - 59세' then age_group2=13; 
if age_group='60 - 64세' then age_group2=14; 
if age_group='65 - 69세' then age_group2=15; 
if age_group='70 - 74세' then age_group2=16; 
if age_group='75 - 79세' then age_group2=17; 
if age_group='80 - 84세' then age_group2=18; 
if age_group='85세 이상' then age_group2=19; 

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
 
/*여자 */ 

data pop2; 
	set pop; 
	if sex="여자"; 
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
if age_group='0 - 4세' then age_group2=2; 
if age_group='5 - 9세' then age_group2=3; 
if age_group='10 - 14세' then age_group2=4; 
if age_group='15 - 19세' then age_group2=5; 
if age_group='20 - 24세' then age_group2=6; 
if age_group='25 - 29세' then age_group2=7; 
if age_group='30 - 34세' then age_group2=8; 
if age_group='35 - 39세' then age_group2=9; 
if age_group='40 - 44세' then age_group2=10; 
if age_group='45 - 49세' then age_group2=11; 
if age_group='50 - 54세' then age_group2=12; 
if age_group='55 - 59세' then age_group2=13; 
if age_group='60 - 64세' then age_group2=14; 
if age_group='65 - 69세' then age_group2=15; 
if age_group='70 - 74세' then age_group2=16; 
if age_group='75 - 79세' then age_group2=17; 
if age_group='80 - 84세' then age_group2=18; 
if age_group='85세 이상' then age_group2=19; 

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

/***********표준화사망률 계산 *****************/


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
	
	mr(k) = death(k)/pop(k) *stdpop(k);  /*연령별 사망률 * 표준인구*/
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
	
		mr(k) = death(k)/pop(k) *stdpop(k);  /*연령별 사망률 * 표준인구*/
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
            OUTFILE= "F:\2020projects\bae\KEITI\research\2.사망\B형 사망자료(2010-2019)\outdata\send\&dis._daily_count.csv" 
            DBMS=CSV REPLACE;
     PUTNAMES=YES;
	RUN;

	PROC EXPORT DATA= A.&dis._yy_sgg_smr2 
            OUTFILE= "F:\2020projects\bae\KEITI\research\2.사망\B형 사망자료(2010-2019)\outdata\send\&dis._yy_sgg_smr.csv" 
            DBMS=CSV REPLACE;
     PUTNAMES=YES;
	RUN;

	PROC EXPORT DATA= A.&dis._yy_sgg_smr_pop 
            OUTFILE= "F:\2020projects\bae\KEITI\research\2.사망\B형 사망자료(2010-2019)\outdata\send\&dis._yy_sgg_smr_pop.csv" 
            DBMS=CSV REPLACE;
     PUTNAMES=YES;
	RUN;



	PROC EXPORT DATA= A.&dis._yy_sgg_smr_pop_ageonly
            OUTFILE= "F:\2020projects\bae\KEITI\research\2.사망\B형 사망자료(2010-2019)\outdata\send\&dis._yy_sgg_smr_pop_ageonly.csv" 
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

