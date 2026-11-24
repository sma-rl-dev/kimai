-- Headless neutralisation of Kimai's first-login wizard.
--
-- src/EventSubscriber/WizardSubscriber.php redirects every authenticated
-- request to the first wizard step whose id is not in the user's
-- `__wizards__` preference (App\Wizard\WizardManager registers `intro` and
-- `profile`). `kimai:user:create` cannot mark them seen and the prod image has
-- no fixtures bundle, so `./tester-env deploy` applies this after the DB is up.
INSERT INTO kimai2_user_preferences (user_id, name, value)
SELECT u.id, '__wizards__', 'intro,profile'
FROM kimai2_users u
WHERE NOT EXISTS (
    SELECT 1 FROM kimai2_user_preferences p
    WHERE p.user_id = u.id AND p.name = '__wizards__'
);

-- Additive for users who already saw one step (e.g. after opening the wizard
-- once): append the missing ids so no step can trigger a redirect. Never
-- overwrite the value, which may also list step ids from plugins.
UPDATE kimai2_user_preferences
SET value = CONCAT_WS(',', NULLIF(value, ''), 'intro')
WHERE name = '__wizards__' AND FIND_IN_SET('intro', value) = 0;

UPDATE kimai2_user_preferences
SET value = CONCAT_WS(',', NULLIF(value, ''), 'profile')
WHERE name = '__wizards__' AND FIND_IN_SET('profile', value) = 0;

-- Global switch (src/Configuration/SystemConfiguration::isUserWizardActive):
-- keeps the wizard off for regular users created later. Insufficient alone -
-- super admins are redirected even with the switch off.
INSERT INTO kimai2_configuration (name, value)
SELECT 'user.wizard', '0'
WHERE NOT EXISTS (SELECT 1 FROM kimai2_configuration WHERE name = 'user.wizard');
