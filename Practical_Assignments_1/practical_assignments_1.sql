-- pa1 car service

create table clients (
  clientid   serial primary key,-- унікальний id для клієнта
  fullname   varchar(100) not null,
  phone      varchar(15),
  email      varchar(50),
  city       varchar(50)
);

create table cars (
  carid        serial primary key,
  clientid     int not null,
  brand        varchar(50),
  model        varchar(50),
  year         int,
  licenseplate varchar(15) unique,-- unique, щоб мати унікальний номер
  foreign key (clientid) references clients(clientid)
);

create table mechanics (
  mechanicid   serial primary key,
  fullname     varchar(50) not null,
  specialty    varchar(50),
  hourlyrate   decimal(10, 2)
);

create table services (
  serviceid    serial primary key,
  servicename  varchar(50) not null,
  baseprice    decimal(10, 2),
  durationhrs  decimal(10, 2)
);

create table orders (
  orderid      serial primary key,
  carid        int not null,
  mechanicid   int not null,
  serviceid    int not null,
  orderdate    date not null,
  -- check() забороняє вставити будь яке інше значення
  -- default 'completed' підставиться автоматично 'completed' якщо не вказати status
  status       varchar(20) default 'completed' check (status in ('completed', 'inprogress', 'cancelled')),
  finalprice   decimal(10, 2),
  foreign key (carid)      references cars(carid),
  foreign key (mechanicid) references mechanics(mechanicid),
  foreign key (serviceid)  references services(serviceid)
);

insert into clients (fullname, phone, email, city) values
('Олексій Мельник',   '050-111-2233', 'melnyk@email.com', 'Kyiv'),
('Ірина Ковальчук',   '067-444-5566', 'koval@email.com',  'Kyiv'),
('Дмитро Бондаренко', '073-777-8899', 'bond@email.com',   'Lviv'),
('Світлана Гриценко', '050-321-6547', 'gryts@email.com',  'Kyiv'),
('Артем Шевченко',    '066-654-3210', 'shevch@email.com', 'Odesa');

insert into cars (clientid, brand, model, year, licenseplate) values
(1, 'Toyota',     'Camry',    2018, 'AA1234BB'),
(1, 'Honda',      'Civic',    2020, 'AA5678CC'),
(2, 'Volkswagen', 'Golf',     2019, 'BC9999KA'),
(3, 'BMW',        '3 Series', 2017, 'LV0001AB'),
(4, 'Skoda',      'Octavia',  2021, 'KA2345HH'),
(5, 'Ford',       'Focus',    2016, 'OD8877GG');

insert into mechanics (fullname, specialty, hourlyrate) values
('Василь Кравченко', 'Engine & Transmission', 250.00),
('Петро Іваненко',   'Electrical Systems',    220.00),
('Олег Сидоренко',   'Body & Paint',          200.00),
('Наталя Романенко', 'Diagnostics',           230.00);

insert into services (servicename, baseprice, durationhrs) values
('Oil Change',             500.00, 1.0),
('Brake Pad Replacement', 1200.00, 2.0),
('Engine Diagnostics',     800.00, 1.5),
('Tire Rotation',          400.00, 0.5),
('Full Body Inspection',  1500.00, 3.0),
('AC System Recharge',     900.00, 1.5),
('Transmission Service',  2500.00, 4.0);

insert into orders (carid, mechanicid, serviceid, orderdate, status, finalprice) values
(1, 1, 1, '2024-10-01', 'completed',   500.00),
(1, 4, 3, '2024-10-05', 'completed',   850.00),
(2, 2, 6, '2024-10-08', 'completed',   900.00),
(3, 1, 2, '2024-10-10', 'completed',  1200.00),
(4, 1, 7, '2024-10-12', 'completed',  2500.00),
(4, 4, 3, '2024-10-15', 'completed',   800.00),
(5, 3, 5, '2024-10-18', 'completed',  1500.00),
(6, 2, 6, '2024-10-20', 'completed',   950.00),
(6, 1, 1, '2024-10-22', 'completed',   500.00),
(3, 3, 5, '2024-10-25', 'completed',  1600.00),
(2, 4, 3, '2024-11-01', 'completed',   800.00),
(1, 1, 4, '2024-11-05', 'completed',   400.00),
(5, 2, 2, '2024-11-10', 'inprogress', 1200.00),
(6, 3, 7, '2024-11-12', 'cancelled',     0.00);



-- основний select з join таблицях

select 
c.fullname,
ca.brand,
m.fullname as mechanic,
s.servicename,
o.status,
o.finalprice

from orders o

-- join 1 щоб дізнатись яка машина
join cars ca on o.carid = ca.carid

-- join 2 щоб дізнатись хто власник
join clients c on ca.clientid  = c.clientid

-- join 3 щоб дізнатись що відбувалося
join services s on o.serviceid  = s.serviceid

--join 4: щоб показати який механік хто виконував роботу
join mechanics m  on o.mechanicid = m.mechanicid

where o.status = 'completed' and o.orderdate >= '2024-10-01'



-- використав union all, а не union бо дублікатів тут не може бути фізично і так оптимізованіше отже швидше
union all
select c.fullname,
ca.brand,
m.fullname as mechanic,
s.servicename,
o.status,
o.finalprice

from orders o

join cars ca on o.carid = ca.carid
join clients c on ca.clientid = c.clientid
join services s on o.serviceid = s.serviceid
join mechanics m on o.mechanicid = m.mechanicid
where o.status = 'cancelled'

order by finalprice desc;




-- cte рахує загальний дохід для механіка по 'completed' замовленнях і ранжує їх через rank()
-- використав cte бо це оптимінізованіше і більш читабельно і щоб отримать +1 бал
with mechanic_stats as (
  select 
    m.mechanicid,
    m.fullname as mechanicname,
    m.specialty,
    sum(o.finalprice) as totalrevenue,
    -- rank() присвоєння для кожного механіка порядкового номера
    -- over() означає що всі механіки, відсортовані посумі від більшого до меншого через desc
    rank() over (order by sum(o.finalprice) desc) as revenuerank
  from mechanics m
  join orders o on m.mechanicid = o.mechanicid
  where o.status = 'completed'
  group by m.mechanicid, m.fullname, m.specialty
)
select *
from mechanic_stats
order by revenuerank;

-- показує скільки замовлень у кожного механіка (з having)
select mechanicid, count(*) as totalorders
from orders
group by mechanicid
having count(*) > 1;