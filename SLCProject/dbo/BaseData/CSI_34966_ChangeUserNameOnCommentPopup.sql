use SLCProject
go
-- Customer Support 34966: BSD Cloud contributor user--tracking data on user comments
-- Execute on server 002
drop TABLE IF EXISTS #User;

create table #User (UserId int, FirstName nvarchar(40), LastName nvarchar(40))

INSERT INTO #User
	VALUES (3423, 'David', 'Kilpatrick');
INSERT INTO #User
	VALUES (3528, 'Leonid', 'Makovoz');
INSERT INTO #User
	VALUES (4754, 'Christine', 'Cloutier');
INSERT INTO #User
	VALUES (4770, 'Meghan', 'Morese');
INSERT INTO #User
	VALUES (20415, 'Remi', 'Yasui');
INSERT INTO #User
	VALUES (20550, 'Dean c', 'Geib');
INSERT INTO #User
	VALUES (20967, 'Matthew', 'McKim');
INSERT INTO #User
	VALUES (21010, 'Greg', 'Randle');
INSERT INTO #User
	VALUES (21095, 'Douglas', 'Effenberger');
INSERT INTO #User
	VALUES (21264, 'Kristin', 'Tolentino');
INSERT INTO #User
	VALUES (21279, 'Jeff', 'Flitman');
INSERT INTO #User
	VALUES (21377, 'Dave', 'Trachy');

UPDATE sc
SET sc.userFullName = CONCAT(U.FirstName, ' ', u.LastName)
FROM SegmentComment sc WITH (NOLOCK)
JOIN #User u
	ON sc.CreatedBy = u.UserId
	AND sc.userFullName LIKE 'Customer%';
