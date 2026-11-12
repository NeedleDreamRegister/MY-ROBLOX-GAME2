# Восстановление GitHub

**Обновление13ноября:** подключённый GitHub-плагин сейчас успешно видит `NeedleDreamRegister/MY-ROBLOX-GAME2` с правом push. `origin` добавлен, fetch/ls-remote работают. Обычный HTTPS push на этом ПК пока не авторизован (GCM без аккаунта, SSH отсутствует). Пользователь разрешил загрузку кода для передачи: текущий snapshot передаётся через плагин в отдельную ветку; статус и границы истории — в корневом `HANDOFF.md`. Описание403 ниже — историческое, не результат сегодняшней проверки.

12 ноября плагин GitHub на запрос списка репозиториев повторно вернул HTTP 403: `Sorry. Your account was suspended`. Это серверное ограничение аккаунта; переустановка навыков, Git или плагина не снимает его. В Git Credential Manager на компьютере GitHub-аккаунты не обнаружены.

Владелец аккаунта должен открыть https://docs.github.com/en/site-policy/acceptable-use-policies/github-appeal-and-reinstatement и перейти в GitHub Appeal and Reinstatement form. Если вход недоступен, на этой странице есть путь обращения через подтверждение почты. Текст ниже подготовлен, но не отправлен.

> Hello GitHub Support. My connected GitHub account receives HTTP 403 with the message "Sorry. Your account was suspended" when listing repositories through the GitHub integration. I would like to understand the reason for the restriction and request a review and reinstatement if appropriate. I use GitHub to collaborate on a Roblox game project, Dig the Mountain. Please let me know what information or corrective action is required from me. Thank you.

После восстановления: повторить список репозиториев через плагин, определить общий репозиторий и только затем добавить/проверить remote. Не отправлять код без отдельного поручения. Не публиковать резервные записи игроков.
