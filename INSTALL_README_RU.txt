DIG THE MOUNTAIN: КАК УСТАНОВИТЬ В ОСНОВНОЙ ПРОЕКТ CODEX

1. В приложении Codex открой ОСНОВНОЙ рабочий проект игры, где находится default.project.json (Rojo) и .git. Запомни путь к этой папке; это корень проекта. НЕ путай его с папкой Blender-проекта.
2. В Windows Проводнике открой именно эту папку.
3. Распакуй содержимое ZIP в корень: рядом с default.project.json должен оказаться VISUAL_STYLE_GUIDE.md, а рядом — папка references/Sandforge_Upgrade_Workshop с PNG-файлами. НЕ должно получиться ещё одного вложенного уровня DIG_THE_MOUNTAIN_STYLE_PACK внутри проекта.
4. Если есть AGENTS.md, НЕ заменяй файл. Открой его текстовым редактором и добавь в конец блок из AGENTS_APPEND.txt. Если AGENTS.md отсутствует, можешь создать его и добавить блок.
5. В основном чате Codex отправь: «Прочитай VISUAL_STYLE_GUIDE.md, references/Sandforge_Upgrade_Workshop/REFERENCE_NOTES.md и проверь доступность master PNG. Подтверди реальные пути к файлам. С этого момента учитывай стандарт SANDFORGE INDUSTRIAL для новых визуальных задач. Сейчас ничего в игре не изменяй».
6. Убедись, что Codex подтвердил именно содержимое файлов и путь к изображению. Если проект ведётся через Git, добавь файлы в коммит и отправь на GitHub, чтобы они были доступны на другом ПК и в других рабочих копиях.

ПРИМЕР (НЕ ТВОЙ НАСТОЯЩИЙ ПУТЬ):
DigTheMountain/
  default.project.json
  AGENTS.md
  VISUAL_STYLE_GUIDE.md
  references/
    Sandforge_Upgrade_Workshop/
      00_MASTER_compact_approved_3quarter.png
      01_turnaround_sheet_A.png
      ...
      REFERENCE_NOTES.md

ОГРАНИЧЕНИЕ: изображения являются 2D-концептами; другие виды — приблизительные. Codex/Blender не гарантируют идентичную модель без последующей ручной проверки.
