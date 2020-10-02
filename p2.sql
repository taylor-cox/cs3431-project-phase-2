-- Question 1
create or replace view NoCurator as
select l.locationID, s.accountName from Staff s, StaffPosition sp, Location l
where s.accountName = sp.accountName
and l.locationID = s.locationID
and sp.positionID != 'CURATOR';

select locationID, count(*) as CNT from NoCurator
group by locationID;

-- Question 2
create or replace procedure StaffInOffice (locationID_in varchar2) IS
  countInOffice number;
  maxocp number;
begin
  countInOffice := -1;
  maxocp := -1;
  select maxOccupancy, cnt into maxocp, countInOffice
  from Office o,
  (select locationID, count(*) as cnt
  from
    (select distinct s.accountName, l.locationID
    from Staff s,
    StaffPosition sp,
    Location l
    where s.accountName = sp.accountName and l.locationID = s.locationID and locationID_in = l.locationID)
    group by locationID) x
  where o.locationID = x.locationID;
  dbms_output.put_line('Office ' || locationID_in || ': ' || countInOffice || ' assigned, ' || maxocp || ' max occupancy.');
end;
/

-- Question 3
create or replace trigger NoSameStartEnd
  before
  insert
  on edge
  for each row
begin
  if (:NEW.startingID = :NEW.endingID) then
    RAISE_APPLICATION_ERROR(-20004, 'Cannot insert edge with same starting and ending location.');
  end if;
end;
/

-- Question 4
create or replace trigger OnlyStaircases
  before
  insert
  on edge
  for each row
declare
  floor1 number;
  floor2 number;
begin
  select floor into floor1 from Location where :NEW.startingID = locationID;
  select floor into floor2 from Location where :NEW.endingID = locationID;
  if (floor2 = floor1) then
    RAISE_APPLICATION_ERROR(-20004, 'Cannot insert a staircase edge where both locations are on the same floor.');
  end if;
end;
/

-- Question 5
create or replace trigger MustBeOffice
 before
 update or insert
 on Office
 for each row
declare
 locType varchar(50);
 cursor c1 is select locationType into locType from Location where :new.locationId = locationId;
begin
  if(locType != 'Office') then
   RAISE_APPLICATION_ERROR(-20004, 'Cannot add office to a non-office location');
  end if;
  
  for record in c1
  loop
  if(record.locationType != 'Office') then
   RAISE_APPLICATION_ERROR(-20004, 'Cannot add office to a non-office location');
  end if;
  end loop;
end;
/

-- Question 6
create or replace trigger JobLimit
 before
 update or insert
 on StaffPosition
declare
 jobAmount number;
 cursor c2 is select count(*) as CNT into jobAmount from StaffPosition group by accountName;
begin
 open c2;
 loop
  fetch c2 into jobAmount;
  if(jobAmount > 3) then
   RAISE_APPLICATION_ERROR(-20004, 'Cannot give a StaffMember more than 3 Positions.');
  end if;
 end loop;
 close c2;
end;
/
