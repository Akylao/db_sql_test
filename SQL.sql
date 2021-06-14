---------create table

declare
nCount NUMBER;
v_sql LONG;
begin


SELECT  count(*) into nCount
FROM dba_tables where lower(table_name) = 'tb_users';
IF(nCount <= 0)
THEN
v_sql:='
CREATE TABLE tb_users ( uuid VARCHAR2(40)  NOT NULL
                        PRIMARY KEY , registration_date date, country varchar2(100))';
                        execute immediate (v_sql);
dbms_output.put_line(nCount);
ELSE dbms_output.put_line('TABLE EXIST');
END IF;


SELECT count(*) into nCount
FROM dba_tables where lower(table_name) = 'tb_login';
IF(nCount <= 0)
THEN
v_sql:='
CREATE TABLE tb_login (user_uid VARCHAR2(40)  NOT NULL,
                       login varchar2(50),
                       account_type varchar2(10),
                       FOREIGN KEY (user_uid)
                       REFERENCES tb_users(uuid))';
execute immediate (v_sql);
dbms_output.put_line(nCount);
ELSE dbms_output.put_line('TABLE EXIST');
END IF;

SELECT count(*) into nCount
FROM dba_tables where lower(table_name) = 'tb_operations';
IF(nCount <= 0)
THEN
v_sql:='create table tb_operations(operation_type varchar2(25),
                                   operation_date date,
                                   login varchar2(50),
                                   amount number)';
execute immediate (v_sql);
dbms_output.put_line(nCount);
ELSE dbms_output.put_line('TABLE EXIST');
END IF;


SELECT count(*) into nCount
FROM dba_tables where lower(table_name) = 'tb_orders';
IF(nCount <= 0)
THEN
v_sql:='create table tb_orders (login varchar2(50), order_close_date date )';
execute immediate (v_sql);
dbms_output.put_line(nCount);
ELSE dbms_output.put_line('TABLE EXIST');
END IF;
END;

-------------------------------------------------------------------------------------------------------

--1)  Наверное первое , но я не уверенна , потому как не понимаю.
-- Имеется в виду надо сначало инсертнуть везде данные потом это время разделить на количество итераций.
---Ну и там что то про группировать всех по странам и отсортировать по убыванию .
--- Если что  могу переписать


declare
login  varchar2(100);
amount number ;
operation_date date;
operation_type varchar2(100);
order_close_date date ;
dt date ;
russian_short varchar2(100);
account_type varchar2(20) ;
UUID  varchar2(40) ;
droped_col number ;

begin
for i in 1..50
loop
login :=  dbms_random.string('x',10);
amount :=  DBMS_RANDOM.value(500,2000);

with l as(
SELECT rownum  row_num, TRUNC (SYSDATE - ROWNUM) dt
FROM DUAL l CONNECT BY ROWNUM < 90
)
select l.dt  into dt
from l
where l.row_num = (select trunc(dbms_random.value(1,90)) num from dual);

select sys_guid() into UUID
from dual;

select decode(round(dbms_random.value), 1, 'demo', 'real')
into account_type
from dual;

with s as(
select rownum row_num,
       russian_short
from country
)
select russian_short into russian_short
from s
where  row_num = (select trunc(dbms_random.value(1,190)) num from dual);




with l as(
SELECT rownum  row_num, TRUNC (SYSDATE - ROWNUM) dt
FROM DUAL l CONNECT BY ROWNUM < 90
)
select l.dt  into operation_date
from l
where l.row_num = (select trunc(dbms_random.value(1,90)) num from dual);


with l as(
SELECT rownum  row_num, TRUNC ((SYSDATE +120) -ROWNUM) order_close_date
FROM DUAL l CONNECT BY ROWNUM <90
)
select l.order_close_date  into order_close_date
from l
where l.row_num = (select trunc(dbms_random.value(1,90)) num from dual);


select decode(round(dbms_random.value), 1, 'deposit', 'withdrawal') into operation_type
from dual;

insert into tb_users(uuid,registration_date,country)
select distinct * from (
select UUID,dt, russian_short from dual);
commit ;

insert into tb_login(user_uid , login,  account_type)
select  UUID ,login, account_type from dual ;
commit;



insert into tb_operations (operation_type, operation_date,login,amount)
values (operation_type, operation_date,login,amount);
commit ;


insert into tb_orders (login, order_close_date )
values(login,order_close_date);
commit;



END LOOP;

select trunc(count(*)/3)  into droped_col
from tb_operations;

execute immediate ('delete from tb_operations
where rowid IN ( select rid
from (select operation_type,operation_date,login,amount,rownum rn , rowid rid
from tb_operations)
where rn > 100)');
commit;
END;
-------------------------------------------------------

select country, count(*)
from tb_users u
inner join tb_login t on user_uid =uuid
inner join tb_operations  o on o.login=t.login
inner join tb_orders r on r.login= o.login
where o.operation_date between trunc (SYSDATE-90) and sysdate
and r.order_close_date>SYSDATE
and  lower(t.account_type) ='real'
group by country
order by 2 desc
-------------------------------------------------------
-----3
select  login,operation_date , ROW_NUMBER() OVER (PARTITION BY login ORDER BY operation_date asc)
from (
select distinct  u.uuid, t.login, o.operation_date
from tb_users u
inner join tb_login t on user_uid =uuid
inner join tb_operations  o on o.login=t.login
and o.operation_type like '%deposit%')

----2)
select country, count(*)
from (
select distinct uuid, u.country
from tb_users u
inner join tb_login t on user_uid =uuid
inner join tb_operations  o on o.login=t.login
and o.operation_type like '%deposit%'
and o.amount>=1000
)group by country