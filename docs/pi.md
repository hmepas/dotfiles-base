# Pi: общий конфиг Mac и Linux

## Что хранится в репе

На всех машинах, где ставится `stow/claude`, ставить также `pi` и
`agent-skills`. Это не GUI-пакеты, подходят и для headless-хостов.

- `stow/pi/.pi/agent/extensions/`: `ask-user`, `background-terminals`,
  `file-search`, `subagents` и его зависимость `shared/tool-call-timeout.ts`.
- `stow/pi/.pi/agent/prompts/coding.md`: команда `/coding`, не системный промпт.
- `stow/macos-common/.pi/agent/extensions/mac-paste-image.ts`: вставка картинки из буфера macOS по `Ctrl+Shift+V` или `/paste-image-mac`. В общем пакете `pi` расширения нет.
- `stow/agent-skills/.agents/skills/`: личные `zk` и `xlsx`, включая скрипты,
  reference и Poetry lockfile. Отдельный xlsx-репозиторий больше не нужен.
- `stow/claude/.claude/CLAUDE.md`: существующие инструкции Claude.

## Установка и обновление

Нужны GNU Stow, Node.js/npm, установленный Pi. Для xlsx нужен Poetry.

Из корня dotfiles-base:

```bash
stow -n -v --no-folding -t ~ -d stow claude pi agent-skills
stow --no-folding -t ~ -d stow claude pi
./scripts/setup-agent-skills.sh
for ext in ask-user background-terminals file-search subagents; do
  npm --prefix "stow/pi/.pi/agent/extensions/$ext" ci --omit=dev --ignore-scripts || break
done
poetry -C "$HOME/.agents/skills/xlsx/scripts" install
```

`npm ci` выполняется в репе: импорты расширения разрешаются относительно
исходников. Pi предоставляет свои `@earendil-works/*` и `typebox`; отдельно
ставятся runtime dependencies из lockfile. `--ignore-scripts` пропускает
`prepare`, предназначенный для dev-инструментов. Для `file-search` можно
установить `fd` и `ripgrep` через системный пакетный менеджер (на Debian/Ubuntu:
`fd-find` и `ripgrep`).

`--no-folding` обязателен: каталоги приложений остаются настоящими каталогами,
в репу не попадают сессии, credentials и прочие runtime-файлы.
`node_modules`, `.venv` и Python cache исключены из Git и Stow.

При конфликтах сначала сравнить местные файлы с репой. Отличия Linux пока
не исследованы, не затирать их автоматически. Сохранить конфликтующие файлы
в отдельный каталог вне `~/.pi/agent/extensions` и `~/.agents/skills`, затем
повторить dry-run и stow. Не использовать `stow --adopt`: он может заменить
версию в репе местной. Старую ссылку `~/.agents/skills/xlsx` сохранить как
ссылку, не удалять её исходный репозиторий.

Pi и современные версии Codex обнаруживают `~/.agents/skills` сами.
Скрипт создаёт ссылки для Claude. Старые ссылки Codex на те же скиллы можно
оставить, но для новой установки они не нужны. Pi дополнительные ссылки
в `~/.pi/agent/skills` не нужны.

Vault должен быть доступен как `~/zk` на каждой машине. Если его там нет,
создать ссылку на существующий vault. Не заменять уже существующий каталог.

Только на macOS: `stow --no-folding -t ~ -d stow macos-common`. Если
`~/.pi/agent/extensions/mac-paste-image.ts` уже есть, сравнить его с репой и
убрать локальную копию из каталога расширений перед stow, как описано выше.

После установки выполнить `/reload` в Pi, когда нет работающих подагентов.
Проверить `/coding`, `/skill:zk`, `/skill:xlsx` и инструменты `subagent_*`.
После `git pull` повторять stow при добавлении файлов, `npm ci` при изменении
lockfile и `poetry install` при изменении Python-зависимостей.

## Если `subagents` не находит `effect` после Stow

Stow создаёт ссылки, но не ставит npm-зависимости. Выполни из корня
`dotfiles-base`, а не из `~/.pi/agent/extensions`:

```bash
npm --prefix stow/pi/.pi/agent/extensions/subagents ci --omit=dev --ignore-scripts
```

`effect` появится в `stow/pi/.pi/agent/extensions/subagents/node_modules`.
Флаг `--ignore-scripts` пропускает `prepare`, которому нужны dev-зависимости.
После успешной установки выполни `/reload` в Pi.

## Текущие настройки Mac

Снимок при переносе, Pi `1.5.2`. Это документация, не автоматически
применяемый `settings.json`.

Общие настройки-кандидаты для обеих ОС:

```json
{
  "defaultProvider": "openai-codex",
  "defaultModel": "gpt-6-astra",
  "defaultThinkingLevel": "medium",
  "theme": "dark",
  "packages": ["npm:@oddsjam/pi-sandbox"]
}
```

Также в Mac `settings.json`:

- `lastChangelogVersion`: `1.5.2`, служебное состояние, синхронизировать не нужно.
- `extensions`: `/Users/hmepas/tmp/jail/my-pi-setup/extensions/firecrawl-search/index.ts`.
  Непереносимый путь. Не копировать в Linux; сначала решить, нужен ли Firecrawl
  рядом с webserp/Scrapling, и где хранить его код.

Остальные настройки в этом файле не заданы, используются defaults Pi.
Проектные `.pi/settings.json`, CLI и восстановленная сессия могут их менять.
Смена модели через `/model` может изменить пользовательские defaults.

Автообнаруживаемые расширения Mac:

| Расширение | Статус |
|---|---|
| `subagents`, `shared/tool-call-timeout.ts` | В stow |
| `ask-user` | В stow |
| `background-terminals` | В stow |
| `file-search` | В stow |
| `mac-paste-image.ts` | Mac-only, пока локальное |
| `tuios-agent-state.ts` | Пока локальное |

Pi установлен managed-инсталлятором, launcher `~/.pi/agent/bin/pi`, релизы
в `~/.pi/agent/install/releases/`. Инсталляцию и `node_modules` не переносить
между ОС; ставить Pi отдельно. Для Claude/Codex backend подагентов нужны
соответствующие CLI и отдельная локальная авторизация.

`~/.pi/agent/AGENTS.md` пока локальный, отличается от Claude-инструкций.
Содержит правила: сначала исследовать вопросы, уточнять сомнения, отвечать
кратко, не читать `.env` целиком, не подключаться по SSH без явного запроса.
`coding.md` применяется только по `/coding`, не заменяет этот файл.

## Что осталось свести

1. На Linux локально сравнить `settings.json`, `AGENTS.md`, список расширений
   и их версии с этим снимком. SSH для этого переноса не использовался.
2. Согласовать общие defaults и список расширений. Сейчас перенесены только
   запрошенные ресурсы, остальные расширения не унифицированы.
3. Убрать абсолютный Firecrawl-путь либо перенести расширение отдельно.
4. После сравнения решить, хранить ли общий шаблон `settings.json` и общие
   инструкции Pi под stow. Пока настройки обеих машин не перезаписываются.

Не переносить в Git `auth.json`, `sessions`, `trust.json`, sandbox state,
кеши и хранилища моделей. Авторизацию выполнять на каждой машине отдельно.
