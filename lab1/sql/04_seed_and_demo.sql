USE SportEventsDb;
GO

INSERT INTO dbo.Roles (Name) VALUES (N'Admin'), (N'Organizer'), (N'Customer');

INSERT INTO dbo.Users (RoleId, Email, PasswordHash, FullName, Phone) VALUES
 (1, N'admin@sportevents.ua',     N'hash_admin',     N'Олена Адміненко',   N'+380501112233'),
 (2, N'organizer@sportevents.ua', N'hash_organizer', N'Андрій Організатор', N'+380671234567'),
 (3, N'fan@gmail.com',            N'hash_fan',       N'Ігор Вболівальник', NULL);

INSERT INTO dbo.Sports (Name, IsTeamSport, Description) VALUES
 (N'Футбол',    1, N'Командна гра 11 на 11'),
 (N'Баскетбол', 1, N'Командна гра 5 на 5');

INSERT INTO dbo.Venues (Name, City, Address, Capacity, UpdatedBy) VALUES
 (N'Стадіон «Центральний»',  N'Київ',  N'вул. Спортивна, 1',  1500, 1),
 (N'Палац спорту «Юність»',  N'Львів', N'вул. Стрийська, 45',  550, 1);

INSERT INTO dbo.VenueSectors (VenueId, Name, RowsCount, SeatsPerRow, PriceMultiplier) VALUES
 (1, N'A',      20, 30, 1.00),
 (1, N'B',      20, 30, 1.00),
 (1, N'VIP',     5, 10, 2.50),
 (2, N'Партер', 15, 20, 1.20),
 (2, N'Балкон', 10, 25, 0.80);

INSERT INTO dbo.Tournaments (SportId, Name, Season, StartDate, EndDate, Status, UpdatedBy) VALUES
 (1, N'Кубок міста з футболу',     N'2026', '2026-09-01', '2026-12-15', N'Ongoing', 2),
 (2, N'Студентська ліга баскетболу', N'2026/27', '2026-10-01', '2027-04-30', N'Planned', 2);

INSERT INTO dbo.Teams (SportId, Name, City, FoundedYear, UpdatedBy) VALUES
 (1, N'Сокіл',          N'Київ',   1998, 2),
 (1, N'Вітер',          N'Львів',  2004, 2),
 (1, N'Буревій',        N'Одеса',  2010, 2),
 (1, N'Дніпрові Леви',  N'Дніпро', 2001, 2),
 (2, N'Політехнік',     N'Львів',  1985, 2),
 (2, N'Університет',    N'Київ',   1990, 2);

INSERT INTO dbo.Athletes (FirstName, LastName, BirthDate, Gender, Nationality, UpdatedBy) VALUES
 (N'Максим',  N'Коваленко', '2000-03-14', 'M', N'Україна', 2),
 (N'Денис',   N'Шевчук',    '1999-07-02', 'M', N'Україна', 2),
 (N'Олег',    N'Бондар',    '2001-11-20', 'M', N'Україна', 2),
 (N'Артем',   N'Ткаченко',  '1998-01-09', 'M', N'Україна', 2),
 (N'Богдан',  N'Мельник',   '2002-05-30', 'M', N'Україна', 2),
 (N'Сергій',  N'Кравець',   '2000-09-17', 'M', N'Україна', 2),
 (N'Роман',   N'Олійник',   '1997-12-25', 'M', N'Україна', 2),
 (N'Віталій', N'Лисенко',   '2001-04-11', 'M', N'Україна', 2);

INSERT INTO dbo.TeamMembers (TeamId, AthleteId, JerseyNumber, Position, JoinedAt) VALUES
 (1, 1, 10, N'Нападник',   '2024-07-01'),
 (1, 2,  1, N'Воротар',    '2023-07-01'),
 (2, 3,  9, N'Нападник',   '2024-01-15'),
 (2, 4,  5, N'Захисник',   '2022-08-01'),
 (3, 5,  7, N'Півзахисник','2025-02-01'),
 (3, 6,  4, N'Захисник',   '2024-07-01'),
 (4, 7, 11, N'Нападник',   '2023-07-01'),
 (4, 8, 23, N'Воротар',    '2024-07-01');

INSERT INTO dbo.Coaches (TeamId, FirstName, LastName, LicenseNumber, IsHeadCoach) VALUES
 (1, N'Василь',   N'Петренко', N'UEFA-PRO-0012', 1),
 (2, N'Микола',   N'Гнатюк',   N'UEFA-A-0345',   1),
 (3, N'Юрій',     N'Савчук',   N'UEFA-A-0789',   1),
 (4, N'Олександр',N'Руденко',  N'UEFA-B-1101',   1);

INSERT INTO dbo.Referees (SportId, FirstName, LastName, Category) VALUES
 (1, N'Тарас',   N'Ковальчук', N'Національна'),
 (1, N'Павло',   N'Зінченко',  N'Перша'),
 (1, N'Євген',   N'Марченко',  N'Перша');

INSERT INTO dbo.Sponsors (Name, Website, ContactEmail) VALUES
 (N'СпортМаркет', N'https://sportmarket.example', N'partners@sportmarket.example'),
 (N'Банк Злагода', N'https://zlagoda-bank.example', N'pr@zlagoda-bank.example');

INSERT INTO dbo.TournamentSponsors (TournamentId, SponsorId, Amount, Tier) VALUES
 (1, 1, 250000, N'Title'),
 (1, 2, 100000, N'Gold');
GO

DECLARE @e1 INT, @e2 INT, @e3 INT, @e4 INT, @order INT, @ticket INT, @payment INT;

EXEC dbo.sp_Tournament_RegisterTeam @TournamentId = 1, @TeamId = 1, @GroupName = N'A';
EXEC dbo.sp_Tournament_RegisterTeam @TournamentId = 1, @TeamId = 2, @GroupName = N'A';
EXEC dbo.sp_Tournament_RegisterTeam @TournamentId = 1, @TeamId = 3, @GroupName = N'A';
EXEC dbo.sp_Tournament_RegisterTeam @TournamentId = 1, @TeamId = 4, @GroupName = N'A';

EXEC dbo.sp_Event_Create 1, 1, 1, 2, '2026-10-10T18:00:00', 150, 2, @e1 OUTPUT;
EXEC dbo.sp_Event_Create 1, 1, 3, 4, '2026-10-11T18:00:00', 150, 2, @e2 OUTPUT;
EXEC dbo.sp_Event_Create 1, 1, 1, 3, '2026-11-20T19:00:00', 200, 2, @e3 OUTPUT;
EXEC dbo.sp_Event_Create 1, 1, 2, 4, '2026-11-21T19:00:00', 200, 2, @e4 OUTPUT;

INSERT INTO dbo.EventReferees (EventId, RefereeId, Role) VALUES
 (@e1, 1, N'Main'), (@e1, 2, N'Assistant'),
 (@e2, 2, N'Main'), (@e2, 3, N'Assistant'),
 (@e3, 1, N'Main'), (@e3, 3, N'VAR');

EXEC dbo.sp_EventResult_Set @EventId = @e1, @HomeScore = 2, @AwayScore = 1, @ChangedBy = 2;
EXEC dbo.sp_EventResult_Set @EventId = @e2, @HomeScore = 0, @AwayScore = 0, @ChangedBy = 2;

EXEC dbo.sp_Ticket_Purchase @UserId = 3, @EventId = @e3, @SectorId = 1, @RowNumber = 5, @SeatNumber = 12,
     @OrderId = @order OUTPUT, @TicketId = @ticket OUTPUT;
EXEC dbo.sp_Order_Pay @OrderId = @order, @Method = N'Card', @TransactionRef = N'TX-0001', @PaymentId = @payment OUTPUT;

EXEC dbo.sp_Ticket_Purchase 3, @e3, 3, 1, 1, @order OUTPUT, @ticket OUTPUT;
EXEC dbo.sp_Order_Cancel @OrderId = @order, @ChangedBy = 3;
GO

SELECT * FROM dbo.vw_ActiveEvents ORDER BY StartTime;
GO
EXEC dbo.sp_Tournament_GetStandings @TournamentId = 1;
GO
SELECT * FROM dbo.vw_EventSales;
GO
SELECT * FROM dbo.vw_TeamRoster ORDER BY TeamId, JerseyNumber;
GO
SELECT * FROM dbo.fn_GetTeamSchedule(1, '2026-01-01', '2027-01-01');
GO
SELECT dbo.fn_GetAvailableSeats(3)  AS FreeSeatsEvent3,
       dbo.fn_GetTicketPrice(3, 3)  AS VipPriceEvent3,
       dbo.fn_GetTeamPoints(1, 1)   AS SokilPoints;
GO

EXEC sys.sp_set_session_context @key = N'UserId', @value = 1;
DELETE FROM dbo.Events WHERE EventId = 4;
SELECT * FROM dbo.vw_DeletedEvents;
SELECT COUNT(*) AS StillInTable FROM dbo.Events WHERE EventId = 4;
GO

EXEC dbo.sp_Event_Restore @EventId = 4, @ChangedBy = 1;
EXEC dbo.sp_Audit_GetHistory @TableName = N'Events', @RecordId = 4;
GO
