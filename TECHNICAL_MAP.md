# Техническая схема существующей игры

Не устанавливать эти системы повторно: они уже находятся внутри полной карты. `script-manifest.json` содержит пути всех 67 экспортированных скриптов, их классы и настройки запуска. Файлы `src/` повторяют содержимое из Studio и не подключены к автоматической синхронизации.

## Основные модули

| Путь в Explorer | Роль |
|---|---|
| ServerScriptService.SandPrototype | Входная точка; атрибут PersonalPlotsEnabled включает режим отдельных участков |
| ServerScriptService.SandPrototypePlots | Жизненный цикл участков, загрузка, доступ, совместная добыча, начальная миграция |
| ServerScriptService.SandPrototypeWorld | Рабочая гора: добыча, Terrain, состояние участка, существующие взаимодействия |
| ServerScriptService.SandPrototypeEconomy | Состояния денег и контейнеров, публикация данных интерфейса |
| ServerScriptService.ProgressionAccount | Аккаунт, миграции и проверки переходов |
| ServerScriptService.ProgressionData | Валидация schemaVersion=4, учёт LifetimeDug, запрет самопроизвольного восстановления |
| ServerScriptService.UpgradeTransactions | Серверные покупки, выбор, загрузка и расчёты |
| ServerScriptService.UpgradeService | Проверка запросов автомата и близости игрока |
| ServerScriptService.ProgressionToolService | Выдача выбранного инструмента |
| ServerScriptService.FollowCart | Следящая тачка, её включение и парковка |
| ServerScriptService.ConveyorService | Секции, загрузка, доставка и автоматическая добыча |
| ServerScriptService.SandPrototypeSaveSession | Атомарная запись, lease, revision, защита от параллельных сессий |
| ServerScriptService.SandPrototypeSaveCodec | Упаковка/распаковка сохранений |
| ServerScriptService.SandPrototypeSnapshot / PlotData / CoopData / FindData | Геометрия сохранений, миграции и существующий совместный/коллекционный учёт |
| ReplicatedStorage.SandPrototypeGeometry / SandPrototypeVoxelField / SandPrototypeTerrainGrid | Геометрия и компактное представление песка |
| ReplicatedStorage.UpgradeConfig | Единственный актуальный источник цен, уровней и параметров инструментов/техники |
| ReplicatedStorage.UpgradeToolAppearance / UpgradeToolTemplates | Модели восьми инструментов |
| ReplicatedStorage.UpgradeMachineAppearance / UpgradeMachineRefinement | Внешний вид автомата улучшений |
| ReplicatedStorage.SandPrototypeCartAppearance / CartPose | Внешний вид и поза тачки |
| ReplicatedStorage.DigMotion / GameAudio | Визуальное движение инструмента и аудио |
| ServerScriptService.MountainSlideServer | Серверные условия спуска, права и запрет добычи во время спуска |
| StarterPlayer.StarterPlayerScripts.MountainSlideClient | Управление доской, наклоны, следы, оформление и обзор |
| StarterPlayer.StarterPlayerScripts.SandPrototypeShovelController / ToolHandling / DigPolishClient | Управление инструментом, хват и эффекты |
| StarterPlayer.StarterPlayerScripts.UpgradeUI | Интерфейс улучшений и запросы на сервер |
| StarterPlayer.StarterPlayerScripts.SandPrototypeHUD / Visits / Feedback | Состояние, подсказки, участки и подтверждённые эффекты |
| ReplicatedStorage.ExcavationJourney / ExcavationLedgerAppearance | Существующая навигация прогресса и оформление архива |

## Сохранения

Основной DataStore: **DigMountainPlots_v1**, ключ игрока **player_<UserId>**. Старый **DigMountainPrototype_v1**, ключ **shared_world_v1**, участвует в прежней миграции. Не переименовывать их и не создавать новый кошелёк «для исправления загрузки».

Современный профиль имеет schemaVersion=4; конверт и сжатие обрабатывают SaveSession/SaveCodec. Сохраняются совместимые legacy-поля и миграционные резервные данные. Lease ограничивает параллельную запись; revision контролирует последовательность. `ProgressionData.Advances` запрещает изменение Cycles и уменьшение прогресса. Наличие старого термина cycle в коде не означает работающую регенерацию.

Сам RBXL содержит игру и её шаблоны, но не выгрузку реальных аккаунтов DataStore. Для прежнего прогресса нужно продолжать ту же Roblox-игру / UniverseId. Новый аккаунт Codex не должен создавать новую Roblox-вселенную вместо текущей.

## Пространство карты

- Основная гора: центр/начало TerrainOrigin около (-34, 2, -214), 36 слоёв, 67525 ячеек. В Edit — 455 деталей предпросмотра, в Play — рабочий Terrain.
- Рабочий шаблон Ground около 400×432; шаг между участками 480.
- Спавн около (3, .5, -2), SellPad около (19, .5, -22), UpgradeMachine около (29.65, 5.35, -22), WheelbarrowPad около (23.5, .2, -34). Это ориентиры, не команда перемещать объекты.
- Декоративный ограничитель зоны добычи в построителе: x[-200,132], z[-380,-48]. Новое плоское покрытие обрезано с дополнительным запасом. Реальная runtime-защита вычисляется по геометрии участка.
- Две свободные задние площадки: центры (-145,0,-490), (75,0,-490), размер 58×46.
- Исходный фон: Workspace.DTM_Environment, DTM_Decor и Terrain. Их не заменять при работе над садом.
- Пять прежних деталей рамки участка WestBorder / EastBorder / NorthBorder / SouthBorderLeft / SouthBorderRight намеренно удалены.

## Сад: две стадии построения

1. `ReplicatedStorage.QuarryGardenBuilder` создаёт базовое окружение. В Edit `Workspace.QuarryGarden` — preview; в Play `ServerScriptService.QuarryGardenEnvironment` создаёт `Workspace.QuarryGarden.Site_<UserId>` с нужным смещением.
2. `ServerScriptService.QuarryTransit.BuildRoads`, запущенный через TransitBootstrap после атрибута Ready, дорабатывает существующие WestPromenade / EastPromenade под транспорт. Только изменение базового preview не гарантирует тот же вид в Play.

`StarterPlayer.StarterPlayerScripts.QuarryGardenMotion` двигает только отмеченные кроны и декоративную рябь, с ограничением дальности и числа активных объектов. Не переносить эту анимацию на сервер.

У базового сада есть отдельные группы: CampGardenTransition, LawnKnolls, GardenReflectingPool, WestPromenade/EastPromenade, Meadow, Planting, ServiceGarden, ParkRestDetails, QuarryFootDetails и другие. Код старой беседки сохранён, но по умолчанию её создание отключено. Модели мебели находятся в `ServerStorage.QuarryGardenFurnitureArchive`.

При изменении базового сада нельзя запускать старый исходник `QuarryGardenBuilder.with-furniture-v5.lua`: он вернёт удалённую мебель и не отражает последующие дороги. Использовать текущий `src/ReplicatedStorage/QuarryGardenBuilder.lua`.

## Парковый транспорт

`ServerScriptService.QuarryTransit`:

- **Route** — замкнутый сплайн, касательная, длина и WithOffset для каждого участка. VehicleOffset=-5.2, RootHeight=1.5; путь машины примерно 1584.66 studs.
- **BuildRoads** — итоговые полосы 15+9 studs и одна посадочная площадка.
- **TransitBootstrap** — ожидание готовности сада, доработка дороги, создание транспорта каждого участка.
- **TransitController** — движение, стоянка, пассажиры, выход, руление, кузов и свет.
- **CartTemplate** — настоящая актуальная модель для запуска; обновлять её вместе с предпросмотром.

Edit preview: `Workspace.QuarryParkCart`. Runtime: `Workspace.QuarryTransitVehicles.QuarryParkCart_<UserId>`. Клиент: `StarterPlayer.StarterPlayerScripts.QuarryTransitRider`. RemoteEvent: `ReplicatedStorage.QuarryTransitRequests.ExitRide`.

Исходные дорожные детали сохранены в `ServerStorage.QuarryTransitOriginalRoads`; это не вторая активная дорога.

Атрибуты CartTemplate: CruiseSpeed=12, StopSeconds=4, Acceleration=3.5, Braking=4.5, JerkLimit=6, WheelRadius=1.1, Wheelbase=11.1, DesignVersion=2. Chassis движется AlignPosition / AlignOrientation; сервер владеет физикой. ApplyAtCenterOfMass=false. Пять пассажирских Seat используют настоящие SeatWeld. BodyPivot.SuspensionMotor отвечает за мягкий наклон кузова; RollingAxle — за колёса; SteeringMotor — за руль.

Стекло Coachwork.PanoramicWindshield: позиция (0,3.76,-5.84) относительно BodyPivot, угол X=+6.37°, размер (5.55,4.3,.055).

ExitRide: `JumpExit` — немедленная высадка; `ToggleExit` — заказ/отмена выхода на площадке; `Exit` — выход на стоянке. Сервер проверяет пассажира и отправляет QueueStatus либо character/CFrame. Сохранять порядок снятия SeatWeld, временного серверного владения персонажем, согласования позиции с клиентом и возврата обычного управления.

## Экономика: только справочные параметры

SellPrice=1, ShopDistance=12. Инструменты: shovel, turbo, crystal, vortex, lava, gravity, abyss, reality, по пять уровней. Вместимость обычной лопаты 20/40/60/80/100; остальные параметры читать в UpgradeConfig. Тачка: цена 2000, улучшение 5000, вместимость 500/1500. Четыре секции конвейера: 500/1000/1500/2000. Автоматическая добыча предусмотрена на уровнях 4/5. Эти данные не являются разрешением менять баланс.
