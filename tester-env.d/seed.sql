-- Deterministic business data for the Kimai tester environment.
--
-- Theme: "Northwind Studio", a small Berlin web studio tracking client work.
-- Applied by ./tester-env seed after deploy (fresh schema + admin user).
-- Users are created by the CLI (kimai:user:create, --ignore-existing) before
-- this file; every reference here resolves them by username.
--
-- Idempotent: every seeded entity uses a fixed id in the 1001+ range and is
-- deleted before re-inserting, so a second seed reproduces the same rows
-- without touching records created elsewhere.
--
-- Dates are frozen in 2026-10-05 .. 2026-11-20 (UTC). Nothing here uses NOW()
-- or random values; see DEPLOY-SMA.md for the expected counts and sums.

SET NAMES utf8mb4;

-- ---------------------------------------------------------------------------
-- Wipe seed-owned rows (children first, FK-safe)
-- ---------------------------------------------------------------------------
DELETE FROM kimai2_timesheet_tags WHERE timesheet_id BETWEEN 1001 AND 1099;
DELETE FROM kimai2_timesheet WHERE id BETWEEN 1001 AND 1099;
DELETE FROM kimai2_activities_teams WHERE team_id = 1001;
DELETE FROM kimai2_projects_teams WHERE team_id = 1001;
DELETE FROM kimai2_customers_teams WHERE team_id = 1001;
DELETE FROM kimai2_activities_rates WHERE activity_id BETWEEN 1001 AND 1099;
DELETE FROM kimai2_projects_rates WHERE project_id BETWEEN 1001 AND 1099;
DELETE FROM kimai2_customers_rates WHERE customer_id BETWEEN 1001 AND 1099;
DELETE FROM kimai2_activities WHERE id BETWEEN 1001 AND 1099;
DELETE FROM kimai2_projects WHERE id BETWEEN 1001 AND 1099;
DELETE FROM kimai2_customers WHERE id BETWEEN 1001 AND 1099;
DELETE FROM kimai2_tags WHERE id BETWEEN 1001 AND 1099;
DELETE FROM kimai2_users_teams WHERE team_id = 1001;
DELETE FROM kimai2_teams WHERE id BETWEEN 1001 AND 1099;

-- ---------------------------------------------------------------------------
-- Customers (3) - all visible, EUR, Berlin, fixed numbers
-- ---------------------------------------------------------------------------
INSERT INTO kimai2_customers
    (id, name, number, comment, visible, company, contact, address, country, currency, phone, email, homepage, timezone, color, time_budget, budget, budget_type, billable, created_at, address_line1, postcode, city, language)
VALUES
    (1001, 'Harborline Media', '0101', 'Digital publisher, retainer client since 2024.', 1, 'Harborline Media GmbH', 'Katrin Vogt', 'Chausseestrasse 12', 'DE', 'EUR', '+49 30 5550101', 'invoices@harborline.example', 'https://harborline.example', 'UTC', '#0a58ca', 0, 0, NULL, 1, '2026-09-28 09:00:00', 'Chausseestrasse 12', '10115', 'Berlin', 'en'),
    (1002, 'Northstar Logistics', '0102', 'Freight operator, portal project with fixed budget.', 1, 'Northstar Logistics AG', 'Ralf Boehm', 'Hafenstrasse 5', 'DE', 'EUR', '+49 30 5550102', 'billing@northstar.example', 'https://northstar.example', 'UTC', '#1d4ed8', 0, 0, NULL, 1, '2026-09-28 09:10:00', 'Hafenstrasse 5', '20457', 'Hamburg', 'en'),
    (1003, 'Copperline Bakery', '0103', 'Family bakery, brand refresh engagement.', 1, 'Copperline Bakery e.K.', 'Ines Albers', 'Marktplatz 3', 'DE', 'EUR', '+49 30 5550103', 'hello@copperline.example', 'https://copperline.example', 'UTC', '#b45309', 0, 0, NULL, 1, '2026-09-28 09:20:00', 'Marktplatz 3', '10178', 'Berlin', 'en');

-- ---------------------------------------------------------------------------
-- Projects (5) - budgets: 100h time, 40h time, 12000 EUR, one ended project
-- ---------------------------------------------------------------------------
INSERT INTO kimai2_projects
    (id, customer_id, name, order_number, comment, visible, budget, color, time_budget, order_date, start, end, timezone, budget_type, billable, global_activities, number, created_at)
VALUES
    (1001, 1001, 'Website Relaunch', 'PO-4471', 'New public site and booking flow.', 1, 0, '#0a58ca', 360000, '2026-09-15 00:00:00', '2026-10-01 00:00:00', NULL, 'UTC', NULL, 1, 1, '2026-01', '2026-09-28 10:00:00'),
    (1002, 1001, 'Monthly Retainer', 'PO-4488', 'Support and maintenance retainer, 40 hours per quarter.', 1, 0, '#2563eb', 144000, '2026-07-01 00:00:00', '2026-07-01 00:00:00', NULL, 'UTC', NULL, 1, 1, '2026-02', '2026-09-28 10:10:00'),
    (1003, 1003, 'Brand Refresh', 'PO-4501', 'Logo, packaging and storefront identity.', 1, 0, '#b45309', 0, '2026-09-20 00:00:00', '2026-10-01 00:00:00', NULL, 'UTC', NULL, 1, 1, '2026-03', '2026-09-28 10:20:00'),
    (1004, 1002, 'Fleet Portal', 'PO-4512', 'Driver tracking and dispatch portal, fixed price.', 1, 12000, '#1d4ed8', 0, '2026-09-10 00:00:00', '2026-10-08 00:00:00', NULL, 'UTC', NULL, 1, 1, '2026-04', '2026-09-28 10:30:00'),
    (1005, 1002, 'Warehouse Audit', 'PO-4390', 'Completed stocktake audit, kept for reporting.', 1, 0, '#64748b', 0, '2026-08-01 00:00:00', '2026-08-03 00:00:00', '2026-09-30 00:00:00', 'UTC', NULL, 1, 1, '2026-05', '2026-09-28 10:40:00');

-- ---------------------------------------------------------------------------
-- Activities (11) - project activities plus one global activity
-- ---------------------------------------------------------------------------
INSERT INTO kimai2_activities
    (id, project_id, name, comment, visible, color, time_budget, budget, budget_type, billable, number, created_at)
VALUES
    (1001, 1001, 'Development', 'Frontend and backend implementation.', 1, '#0a58ca', 0, 0, NULL, 1, NULL, '2026-09-28 11:00:00'),
    (1002, 1001, 'Design', 'UI design for the relaunch.', 1, '#d63384', 72000, 0, NULL, 1, NULL, '2026-09-28 11:01:00'),
    (1003, 1001, 'Code Review', 'Pull request reviews.', 1, '#fd7e14', 0, 1500, NULL, 1, NULL, '2026-09-28 11:02:00'),
    (1004, 1002, 'Support', 'Retainer support requests.', 1, '#0d6efd', 0, 0, NULL, 1, NULL, '2026-09-28 11:03:00'),
    (1005, 1002, 'Project Management', 'Retainer coordination.', 1, '#6f42c1', 0, 0, NULL, 1, NULL, '2026-09-28 11:04:00'),
    (1006, 1003, 'Design', 'Brand and packaging design.', 1, '#d63384', 0, 0, NULL, 1, NULL, '2026-09-28 11:05:00'),
    (1007, 1003, 'Content Writing', 'Website and packaging copy.', 1, '#b45309', 0, 0, NULL, 1, NULL, '2026-09-28 11:06:00'),
    (1008, 1004, 'Development', 'Portal implementation.', 1, '#1d4ed8', 0, 0, NULL, 1, NULL, '2026-09-28 11:07:00'),
    (1009, 1004, 'Support', 'Portal support and incidents.', 1, '#20c997', 0, 0, NULL, 1, NULL, '2026-09-28 11:08:00'),
    (1010, NULL, 'Internal Meeting', 'Global activity for internal meetings.', 1, '#64748b', 0, 0, NULL, 1, NULL, '2026-09-28 11:09:00'),
    (1011, 1005, 'Audit Preparation', 'Stocktake preparation.', 1, '#64748b', 0, 0, NULL, 1, NULL, '2026-09-28 11:10:00');

-- ---------------------------------------------------------------------------
-- Rates: customer defaults, one project override, two activity overrides
-- (activity beats project beats customer, as in Kimai's rate scoring)
-- ---------------------------------------------------------------------------
INSERT INTO kimai2_customers_rates (user_id, customer_id, rate, fixed, internal_rate) VALUES
    (NULL, 1001, 95.00, 0, NULL),
    (NULL, 1002, 110.00, 0, NULL),
    (NULL, 1003, 75.00, 0, NULL);

INSERT INTO kimai2_projects_rates (user_id, project_id, rate, fixed, internal_rate) VALUES
    (NULL, 1004, 115.00, 0, NULL);

INSERT INTO kimai2_activities_rates (user_id, activity_id, rate, fixed, internal_rate) VALUES
    (NULL, 1002, 85.00, 0, NULL),
    (NULL, 1003, 95.00, 0, NULL),
    (NULL, 1007, 75.00, 0, NULL);

-- ---------------------------------------------------------------------------
-- Tags (6)
-- ---------------------------------------------------------------------------
INSERT INTO kimai2_tags (id, name, color, visible) VALUES
    (1001, 'frontend', '#0d6efd', 1),
    (1002, 'backend', '#6f42c1', 1),
    (1003, 'design', '#d63384', 1),
    (1004, 'code-review', '#fd7e14', 1),
    (1005, 'maintenance', '#20c997', 1),
    (1006, 'client-meeting', '#ffc107', 1);

-- ---------------------------------------------------------------------------
-- Team "Delivery" with the four seeded users; mara is teamlead.
-- All seeded customers/projects/activities belong to the team so regular
-- users see the data (Kimai hides teamless entities from non-admins).
-- ---------------------------------------------------------------------------
INSERT INTO kimai2_teams (id, name, color) VALUES (1001, 'Delivery', '#1d4ed8');

UPDATE kimai2_users SET registration_date = '2026-09-01 08:00:00' WHERE username = 'admin';
UPDATE kimai2_users SET alias = 'Lena Fischer', color = '#36b9cc', registration_date = '2026-09-15 08:00:00' WHERE username = 'lena';
UPDATE kimai2_users SET alias = 'Mara Hoffmann', color = '#4e73df', registration_date = '2026-09-15 08:05:00' WHERE username = 'mara';
UPDATE kimai2_users SET alias = 'Jonas Weber', color = '#1cc88a', registration_date = '2026-09-15 08:10:00' WHERE username = 'jonas';
UPDATE kimai2_users SET alias = 'Priya Nair', color = '#e74a3b', registration_date = '2026-09-15 08:15:00' WHERE username = 'priya';

INSERT INTO kimai2_users_teams (user_id, team_id, teamlead)
SELECT id, 1001, 0 FROM kimai2_users WHERE username IN ('lena', 'jonas', 'priya');
INSERT INTO kimai2_users_teams (user_id, team_id, teamlead)
SELECT id, 1001, 1 FROM kimai2_users WHERE username = 'mara';

INSERT INTO kimai2_customers_teams (customer_id, team_id) VALUES
    (1001, 1001), (1002, 1001), (1003, 1001);
INSERT INTO kimai2_projects_teams (project_id, team_id) VALUES
    (1001, 1001), (1002, 1001), (1003, 1001), (1004, 1001), (1005, 1001);
INSERT INTO kimai2_activities_teams (activity_id, team_id)
SELECT id, 1001 FROM kimai2_activities WHERE id BETWEEN 1001 AND 1099;

-- ---------------------------------------------------------------------------
-- Timesheets: 48 stopped entries, 2026-10-05 .. 2026-11-20 (UTC).
-- 45 billable / 3 non-billable; 115:00 total; 10,925.00 EUR total rate.
-- rate = hourly_rate * duration/3600 (all durations are whole/half hours).
-- ---------------------------------------------------------------------------
INSERT INTO kimai2_timesheet
    (id, `user`, activity_id, project_id, start_time, end_time, duration, description, rate, fixed_rate, hourly_rate, exported, timezone, internal_rate, billable, category, modified_at, date_tz, break)
VALUES
    (1001, (SELECT id FROM kimai2_users WHERE username='jonas'), 1001, 1001, '2026-10-05 09:00:00', '2026-10-05 12:00:00', 10800, 'Homepage hero rebuild', 285.00, NULL, 95.00, 0, 'UTC', NULL, 1, 'work', NULL, '2026-10-05', NULL),
    (1002, (SELECT id FROM kimai2_users WHERE username='jonas'), 1001, 1001, '2026-10-05 13:00:00', '2026-10-05 15:00:00', 7200, 'Responsive navigation menu', 190.00, NULL, 95.00, 0, 'UTC', NULL, 1, 'work', NULL, '2026-10-05', NULL),
    (1003, (SELECT id FROM kimai2_users WHERE username='jonas'), 1001, 1001, '2026-10-06 09:00:00', '2026-10-06 12:00:00', 10800, 'Booking form validation', 285.00, NULL, 95.00, 0, 'UTC', NULL, 1, 'work', NULL, '2026-10-06', NULL),
    (1004, (SELECT id FROM kimai2_users WHERE username='jonas'), 1003, 1001, '2026-10-07 10:00:00', '2026-10-07 12:00:00', 7200, 'Review booking flow pull request', 190.00, NULL, 95.00, 0, 'UTC', NULL, 1, 'work', NULL, '2026-10-07', NULL),
    (1005, (SELECT id FROM kimai2_users WHERE username='admin'), 1001, 1001, '2026-10-08 09:00:00', '2026-10-08 13:00:00', 14400, 'CMS template integration', 380.00, NULL, 95.00, 0, 'UTC', NULL, 1, 'work', NULL, '2026-10-08', NULL),
    (1006, (SELECT id FROM kimai2_users WHERE username='jonas'), 1001, 1001, '2026-10-09 09:00:00', '2026-10-09 11:00:00', 7200, 'Sprint 41 bug fixes', 190.00, NULL, 95.00, 0, 'UTC', NULL, 1, 'work', NULL, '2026-10-09', NULL),
    (1007, (SELECT id FROM kimai2_users WHERE username='jonas'), 1008, 1004, '2026-10-13 09:00:00', '2026-10-13 12:00:00', 10800, 'Dispatch API client', 345.00, NULL, 115.00, 0, 'UTC', NULL, 1, 'work', NULL, '2026-10-13', NULL),
    (1008, (SELECT id FROM kimai2_users WHERE username='jonas'), 1008, 1004, '2026-10-14 09:00:00', '2026-10-14 12:00:00', 10800, 'Vehicle lookup endpoints', 345.00, NULL, 115.00, 0, 'UTC', NULL, 1, 'work', NULL, '2026-10-14', NULL),
    (1009, (SELECT id FROM kimai2_users WHERE username='jonas'), 1008, 1004, '2026-10-15 09:00:00', '2026-10-15 10:30:00', 5400, 'Fix tracking event ordering', 172.50, NULL, 115.00, 0, 'UTC', NULL, 1, 'work', NULL, '2026-10-15', NULL),
    (1010, (SELECT id FROM kimai2_users WHERE username='jonas'), 1008, 1004, '2026-10-21 09:00:00', '2026-10-21 12:00:00', 10800, 'Route planner data model', 345.00, NULL, 115.00, 0, 'UTC', NULL, 1, 'work', NULL, '2026-10-21', NULL),
    (1011, (SELECT id FROM kimai2_users WHERE username='admin'), 1008, 1004, '2026-10-22 13:00:00', '2026-10-22 16:00:00', 10800, 'Driver tracking map', 345.00, NULL, 115.00, 0, 'UTC', NULL, 1, 'work', NULL, '2026-10-22', NULL),
    (1012, (SELECT id FROM kimai2_users WHERE username='jonas'), 1009, 1004, '2026-10-28 09:00:00', '2026-10-28 12:00:00', 10800, 'Production incident triage', 345.00, NULL, 115.00, 0, 'UTC', NULL, 1, 'work', NULL, '2026-10-28', NULL),
    (1013, (SELECT id FROM kimai2_users WHERE username='admin'), 1001, 1001, '2026-11-03 09:00:00', '2026-11-03 12:00:00', 10800, 'Contact form spam protection', 285.00, NULL, 95.00, 0, 'UTC', NULL, 1, 'work', NULL, '2026-11-03', NULL),
    (1014, (SELECT id FROM kimai2_users WHERE username='jonas'), 1003, 1001, '2026-11-05 09:00:00', '2026-11-05 11:00:00', 7200, 'Review checkout refactor', 190.00, NULL, 95.00, 0, 'UTC', NULL, 1, 'work', NULL, '2026-11-05', NULL),
    (1015, (SELECT id FROM kimai2_users WHERE username='admin'), 1008, 1004, '2026-11-10 09:00:00', '2026-11-10 12:00:00', 10800, 'Warehouse slot allocation', 345.00, NULL, 115.00, 0, 'UTC', NULL, 1, 'work', NULL, '2026-11-10', NULL),
    (1016, (SELECT id FROM kimai2_users WHERE username='admin'), 1001, 1001, '2026-11-12 09:00:00', '2026-11-12 12:00:00', 10800, 'Search index integration', 285.00, NULL, 95.00, 0, 'UTC', NULL, 1, 'work', NULL, '2026-11-12', NULL),
    (1017, (SELECT id FROM kimai2_users WHERE username='admin'), 1008, 1004, '2026-11-17 09:00:00', '2026-11-17 12:00:00', 10800, 'Delivery window calculation', 345.00, NULL, 115.00, 0, 'UTC', NULL, 1, 'work', NULL, '2026-11-17', NULL),
    (1018, (SELECT id FROM kimai2_users WHERE username='jonas'), 1010, 1001, '2026-11-19 09:00:00', '2026-11-19 11:00:00', 7200, 'Sprint 42 planning', 190.00, NULL, 95.00, 0, 'UTC', NULL, 0, 'work', NULL, '2026-11-19', NULL),
    (1019, (SELECT id FROM kimai2_users WHERE username='priya'), 1006, 1003, '2026-10-05 09:00:00', '2026-10-05 12:00:00', 10800, 'Bakery logo exploration', 255.00, NULL, 85.00, 0, 'UTC', NULL, 1, 'work', NULL, '2026-10-05', NULL),
    (1020, (SELECT id FROM kimai2_users WHERE username='priya'), 1006, 1003, '2026-10-06 09:00:00', '2026-10-06 12:00:00', 10800, 'Packaging mockups', 255.00, NULL, 85.00, 0, 'UTC', NULL, 1, 'work', NULL, '2026-10-06', NULL),
    (1021, (SELECT id FROM kimai2_users WHERE username='priya'), 1002, 1001, '2026-10-12 09:00:00', '2026-10-12 11:00:00', 7200, 'Component library audit', 170.00, NULL, 85.00, 0, 'UTC', NULL, 1, 'work', NULL, '2026-10-12', NULL),
    (1022, (SELECT id FROM kimai2_users WHERE username='priya'), 1006, 1003, '2026-10-14 09:00:00', '2026-10-14 12:00:00', 10800, 'Storefront banner concepts', 255.00, NULL, 85.00, 0, 'UTC', NULL, 1, 'work', NULL, '2026-10-14', NULL),
    (1023, (SELECT id FROM kimai2_users WHERE username='priya'), 1007, 1003, '2026-10-20 09:00:00', '2026-10-20 12:00:00', 10800, 'Website copy for launch', 225.00, NULL, 75.00, 0, 'UTC', NULL, 1, 'work', NULL, '2026-10-20', NULL),
    (1024, (SELECT id FROM kimai2_users WHERE username='priya'), 1002, 1001, '2026-10-27 09:00:00', '2026-10-27 12:00:00', 10800, 'Icon set cleanup', 255.00, NULL, 85.00, 0, 'UTC', NULL, 1, 'work', NULL, '2026-10-27', NULL),
    (1025, (SELECT id FROM kimai2_users WHERE username='priya'), 1006, 1003, '2026-11-02 09:00:00', '2026-11-02 12:00:00', 10800, 'Menu board layout', 255.00, NULL, 85.00, 0, 'UTC', NULL, 1, 'work', NULL, '2026-11-02', NULL),
    (1026, (SELECT id FROM kimai2_users WHERE username='priya'), 1002, 1001, '2026-11-04 09:00:00', '2026-11-04 11:00:00', 7200, 'Colour palette review', 170.00, NULL, 85.00, 0, 'UTC', NULL, 1, 'work', NULL, '2026-11-04', NULL),
    (1027, (SELECT id FROM kimai2_users WHERE username='priya'), 1007, 1003, '2026-11-06 09:00:00', '2026-11-06 12:00:00', 10800, 'Bakery product descriptions', 225.00, NULL, 75.00, 0, 'UTC', NULL, 1, 'work', NULL, '2026-11-06', NULL),
    (1028, (SELECT id FROM kimai2_users WHERE username='priya'), 1002, 1001, '2026-11-11 09:00:00', '2026-11-11 12:00:00', 10800, 'Accessibility pass on hero', 255.00, NULL, 85.00, 0, 'UTC', NULL, 1, 'work', NULL, '2026-11-11', NULL),
    (1029, (SELECT id FROM kimai2_users WHERE username='priya'), 1006, 1003, '2026-11-13 09:00:00', '2026-11-13 11:00:00', 7200, 'Print-ready brand sheet', 170.00, NULL, 85.00, 0, 'UTC', NULL, 1, 'work', NULL, '2026-11-13', NULL),
    (1030, (SELECT id FROM kimai2_users WHERE username='priya'), 1002, 1001, '2026-11-16 09:00:00', '2026-11-16 12:00:00', 10800, 'Design system documentation', 255.00, NULL, 85.00, 0, 'UTC', NULL, 1, 'work', NULL, '2026-11-16', NULL),
    (1031, (SELECT id FROM kimai2_users WHERE username='priya'), 1007, 1003, '2026-11-18 09:00:00', '2026-11-18 12:00:00', 10800, 'Newsletter copy', 225.00, NULL, 75.00, 0, 'UTC', NULL, 1, 'work', NULL, '2026-11-18', NULL),
    (1032, (SELECT id FROM kimai2_users WHERE username='priya'), 1010, 1001, '2026-11-20 09:00:00', '2026-11-20 12:00:00', 10800, 'Quarterly team retro', 285.00, NULL, 95.00, 0, 'UTC', NULL, 0, 'work', NULL, '2026-11-20', NULL),
    (1033, (SELECT id FROM kimai2_users WHERE username='mara'), 1005, 1001, '2026-10-06 13:00:00', '2026-10-06 14:00:00', 3600, 'Sprint planning', 95.00, NULL, 95.00, 0, 'UTC', NULL, 1, 'work', NULL, '2026-10-06', NULL),
    (1034, (SELECT id FROM kimai2_users WHERE username='mara'), 1005, 1001, '2026-10-13 13:00:00', '2026-10-13 15:00:00', 7200, 'Client status call', 190.00, NULL, 95.00, 0, 'UTC', NULL, 1, 'work', NULL, '2026-10-13', NULL),
    (1035, (SELECT id FROM kimai2_users WHERE username='mara'), 1004, 1002, '2026-10-20 13:00:00', '2026-10-20 15:00:00', 7200, 'Retainer support queue', 190.00, NULL, 95.00, 0, 'UTC', NULL, 1, 'work', NULL, '2026-10-20', NULL),
    (1036, (SELECT id FROM kimai2_users WHERE username='mara'), 1005, 1002, '2026-10-27 13:00:00', '2026-10-27 14:00:00', 3600, 'Retainer invoicing review', 95.00, NULL, 95.00, 0, 'UTC', NULL, 1, 'work', NULL, '2026-10-27', NULL),
    (1037, (SELECT id FROM kimai2_users WHERE username='mara'), 1005, 1001, '2026-11-03 13:00:00', '2026-11-03 15:00:00', 7200, 'Client status call', 190.00, NULL, 95.00, 0, 'UTC', NULL, 1, 'work', NULL, '2026-11-03', NULL),
    (1038, (SELECT id FROM kimai2_users WHERE username='mara'), 1004, 1002, '2026-11-10 13:00:00', '2026-11-10 14:30:00', 5400, 'Support queue triage', 142.50, NULL, 95.00, 0, 'UTC', NULL, 1, 'work', NULL, '2026-11-10', NULL),
    (1039, (SELECT id FROM kimai2_users WHERE username='mara'), 1005, 1002, '2026-11-17 13:00:00', '2026-11-17 15:00:00', 7200, 'Retainer planning', 190.00, NULL, 95.00, 0, 'UTC', NULL, 1, 'work', NULL, '2026-11-17', NULL),
    (1040, (SELECT id FROM kimai2_users WHERE username='mara'), 1005, 1001, '2026-11-19 13:00:00', '2026-11-19 15:00:00', 7200, 'Client status call', 190.00, NULL, 95.00, 0, 'UTC', NULL, 1, 'work', NULL, '2026-11-19', NULL),
    (1041, (SELECT id FROM kimai2_users WHERE username='lena'), 1004, 1002, '2026-10-07 13:00:00', '2026-10-07 15:00:00', 7200, 'Support queue triage', 190.00, NULL, 95.00, 0, 'UTC', NULL, 1, 'work', NULL, '2026-10-07', NULL),
    (1042, (SELECT id FROM kimai2_users WHERE username='lena'), 1004, 1002, '2026-10-14 13:00:00', '2026-10-14 15:00:00', 7200, 'Retainer request review', 190.00, NULL, 95.00, 0, 'UTC', NULL, 1, 'work', NULL, '2026-10-14', NULL),
    (1043, (SELECT id FROM kimai2_users WHERE username='lena'), 1005, 1001, '2026-10-21 13:00:00', '2026-10-21 15:00:00', 7200, 'Internal planning', 190.00, NULL, 95.00, 0, 'UTC', NULL, 0, 'work', NULL, '2026-10-21', NULL),
    (1044, (SELECT id FROM kimai2_users WHERE username='lena'), 1004, 1002, '2026-10-28 13:00:00', '2026-10-28 15:00:00', 7200, 'Support queue triage', 190.00, NULL, 95.00, 0, 'UTC', NULL, 1, 'work', NULL, '2026-10-28', NULL),
    (1045, (SELECT id FROM kimai2_users WHERE username='lena'), 1004, 1002, '2026-11-04 13:00:00', '2026-11-04 15:00:00', 7200, 'Customer onboarding call notes', 190.00, NULL, 95.00, 0, 'UTC', NULL, 1, 'work', NULL, '2026-11-04', NULL),
    (1046, (SELECT id FROM kimai2_users WHERE username='lena'), 1004, 1002, '2026-11-11 13:00:00', '2026-11-11 14:00:00', 3600, 'Support queue triage', 95.00, NULL, 95.00, 0, 'UTC', NULL, 1, 'work', NULL, '2026-11-11', NULL),
    (1047, (SELECT id FROM kimai2_users WHERE username='lena'), 1004, 1002, '2026-11-18 13:00:00', '2026-11-18 15:00:00', 7200, 'Monthly retainer reconciliation', 190.00, NULL, 95.00, 0, 'UTC', NULL, 1, 'work', NULL, '2026-11-18', NULL),
    (1048, (SELECT id FROM kimai2_users WHERE username='lena'), 1004, 1002, '2026-11-20 13:00:00', '2026-11-20 14:00:00', 3600, 'Support queue triage', 95.00, NULL, 95.00, 0, 'UTC', NULL, 1, 'work', NULL, '2026-11-20', NULL);

-- ---------------------------------------------------------------------------
-- Tag links (32 entries tagged, 16 untagged)
-- ---------------------------------------------------------------------------
INSERT INTO kimai2_timesheet_tags (timesheet_id, tag_id) VALUES
    (1001, 1001), (1002, 1001), (1003, 1002), (1004, 1004), (1005, 1002),
    (1007, 1002), (1008, 1002), (1009, 1002), (1010, 1002), (1011, 1001),
    (1012, 1005), (1013, 1001), (1014, 1004), (1015, 1002), (1016, 1001),
    (1017, 1002), (1018, 1006),
    (1019, 1003), (1020, 1003), (1021, 1003), (1022, 1003), (1024, 1003),
    (1025, 1003), (1026, 1003), (1028, 1003), (1029, 1003), (1030, 1003),
    (1032, 1006),
    (1033, 1006), (1034, 1006), (1037, 1006), (1040, 1006);
