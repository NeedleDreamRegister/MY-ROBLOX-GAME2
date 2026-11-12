# Первый игровой цикл — результаты Studio

## Что установлено

| Explorer | Файл в проекте |
| --- | --- |
| ServerScriptService.SandPrototypeEconomy (ModuleScript) | src/ServerScriptService/SandPrototypeEconomy.luau |
| ServerScriptService.SandPrototype (Script) | src/ServerScriptService/SandPrototype.server.luau |
| StarterPlayer.StarterPlayerScripts.SandPrototypeHUD (LocalScript) | src/StarterPlayer/StarterPlayerScripts/SandPrototypeHUD.client.luau |
| StarterPack.SandProbe.SandProbeClient (LocalScript) | src/StarterPack/SandProbe.client.luau |
| Workspace.SandPrototypeStation | tools/BuildSandStation.luau (рецепт создания в Edit) |

Станция: зелёная SellPad с SellPrompt (E), синяя UpgradePad с UpgradePrompt (F). Подсказки требуют удержания 0,25 с и доступны в пределах 10 studs. HUD создаётся в PlayerGui.SandPrototypeHUD, а сервер публикует атрибуты в Player.SandPrototypeState. Состояние первично в серверных таблицах, экономические операции не выполняют yield.

## Проверки

- 21 запрос копания через RemoteEvent: приняты ровно 20. CarriedCells=20, CapacityCells=20, XP=20, Coins=0, DugCells=20, RemainingCells=145. Полный запас не удаляет дополнительный песок.
- Продажа через реальное удержание E: CarriedCells=0, Coins=20, XP=20. Повторная продажа не изменила состояние.
- Улучшение через удержание F: CapacityCells=40, CapacityLevel=1, Coins=10. Повторная покупка не изменила состояние.
- Клиент локально установил всем отображаемым атрибутам 9999; сервер сохранил реальные значения. После следующего копания сервер имел CarriedCells=1, CapacityCells=40, Coins=10, XP=21. Некоторые неизменявшиеся атрибуты могут оставаться поддельными в HUD самого нарушителя; это не влияет на серверный учёт.
- Временный тестовый серверный Script вызвал реальные методы продажи/покупки издалека: оба вернули false; CarriedCells=1, Coins=10 не изменились.
- Два клиента заранее сохранили одну и ту же деталь (одинаковый DebugId) и запросили копание: Player2 получил 1 ячейку и 1 XP, Player1 остался с нулями, общая добыча горы выросла только на 1. Локальные HUD показали соответственно 1/20 и 0/20.
- Player2 продал свою ячейку за 1 монету. Player1 с нулём монет не смог купить улучшение. В горе осталось 164, добыто 1; продажа не вернула песок.
- HUD осмотрен на ПК и профиле iPhone 17 Pro (viewport 750×381). Карточка 270×150; все TextLabel.TextFits=true, включая полный запас, полоса заполняется полностью. В профильном Play SandProbe автоматически экипирован.
- В журналах проверенных сессий ошибок не обнаружено. Все тесты остановлены, профиль устройства сброшен в default.

## Установка вручную при восстановлении

1. Открыть Place1.rbxl. Для пустой сцены сначала нужен существующий песчаный прототип с Cells и GridX/GridY/GridZ; эти файлы не создают гору заново.
2. Если станции ещё нет, скопировать tools/BuildSandStation.luau в Command Bar и выполнить в Edit. Рецепт отказывается заменять существующую станцию.
3. Создать ModuleScript SandPrototypeEconomy в ServerScriptService, вставить соответствующий исходник.
4. Обновить Script SandPrototype, LocalScript SandProbeClient внутри Tool SandProbe и создать LocalScript SandPrototypeHUD в StarterPlayerScripts. У Tool RequiresHandle=false.
5. Запустить Play, выбрать SandProbe, копать гору, затем у зелёной площадки удержать E, у синей — F. На телефоне подсказки Roblox работают нажатием; реальный сенсорный опыт ещё не проверен.

## Границы

Параметры 20/40, цена продажи 1, XP 1 и стоимость улучшения 10 — тестовые. Состояние живёт только до конца серверной сессии. Возрождение персонажа в той же сессии не создаёт новую запись игрока. Выход завершает временный запас, а суммарная добыча горы остаётся учтённой в текущем сервере. Прототипный SandPrototypeState — отдельный интерфейс, не миграция будущего постоянного профиля.

Следующий этап — сохранение. Открытая игра пока имеет PlaceId=0 и GameId=0; для настоящего DataStore и проверки повторного входа потребуется выбрать владельца опубликованного проекта и согласовать публикацию. До этого можно подготовить схему и обработку ошибок, но нельзя заявлять о проверенном сохранении между входами.
