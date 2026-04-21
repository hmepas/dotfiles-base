#!/usr/bin/env zsh

# Safari Tab Switcher - быстрое переключение между вкладками Safari с использованием fzf
# Модульная архитектура с разделением логики и сайд-эффектов

# Конфигурация для fzf (можно переопределить через переменные окружения)
FZF_SAFARI_PROMPT="${FZF_SAFARI_PROMPT:-Search Safari tabs: }"
FZF_SAFARI_HEADER="${FZF_SAFARI_HEADER:-Type to filter, Enter to switch.}"
FZF_SAFARI_HEIGHT="${FZF_SAFARI_HEIGHT:-50%}"

# Режим отладки: если =1, печатать диагностические сообщения в stderr
SAFARI_SWITCHER_DEBUG="${SAFARI_SWITCHER_DEBUG:-0}"

_log_debug() {
    if [[ "$SAFARI_SWITCHER_DEBUG" == "1" ]]; then
        print -u2 -- "[safari-switcher][DEBUG] $*"
    fi
}

# Экранирование строки для встраивания в AppleScript литерал
_escape_applescript_string() {
    local s="$1"
    # Заменяем " на \"; перевод строки удаляем
    s="${s//\"/\\\"}"
    s="${s//$'\n'/ }"
    print -- "$s"
}

# Вспомогательная функция: Получение всех открытых вкладок Safari
# Возвращает таб-делимитированный формат строк для каждой вкладки:
#   "WindowIndex_TabIndex\tTitle\tURL\tWindowID\tTabIndex"
_get_safari_tabs() {
    osascript <<'EOF' | tr '\r' '\n'
tell application "Safari"
    set tabsInfo to ""
    set windowIndex to 1
    
    repeat with w in windows
        set tabIndex to 1
        repeat with t in tabs of w
            set tabName to name of t
            set tabURL to ""
            try
                if URL of t is not missing value then set tabURL to URL of t
            end try

            set winId to id of w

            -- Формат: idx_idx[TAB]Title[TAB]URL[TAB]windowId[TAB]tabIndex
            set delim to ASCII character 9
            set tabInfo to (windowIndex as string) & "_" & (tabIndex as string) & delim & tabName & delim & tabURL & delim & (winId as string) & delim & (tabIndex as string)
            
            if tabsInfo is not "" then
                set tabsInfo to tabsInfo & return & tabInfo
            else
                set tabsInfo to tabInfo
            end if
            
            set tabIndex to tabIndex + 1
        end repeat
        set windowIndex to windowIndex + 1
    end repeat
    
    return tabsInfo
end tell
EOF
}

# Вспомогательная функция: Переключение на вкладку по позиционным индексам
# Аргументы: $1 - ID вкладки в формате "WindowIndex_TabIndex"
_switch_safari_tab() {
    local tab_id="$1"
    
    if [[ -z "$tab_id" ]]; then
        echo "Error: Tab ID is required" >&2
        return 1
    fi
    
    # Парсинг tab_id на window_index и tab_index
    local window_index="${tab_id%_*}"
    local tab_index="${tab_id#*_}"
    
    if [[ -z "$window_index" || -z "$tab_index" ]]; then
        echo "Error: Invalid tab ID format. Expected: WindowIndex_TabIndex" >&2
        return 1
    fi
    
    _log_debug "Switch by index: window_index=$window_index tab_index=$tab_index"

    osascript <<EOF
tell application "Safari"
    activate
    set current tab of window $window_index to tab $tab_index of window $window_index
    set index of window $window_index to 1
end tell
EOF
}

# Вспомогательная функция: Переключение на вкладку по window_id и позиционному tab_index
# Аргументы: $1 - window_id, $2 - tab_index
_switch_safari_tab_by_window_and_index() {
    local window_id="$1"
    local tab_index="$2"

    if [[ -z "$window_id" || -z "$tab_index" ]]; then
        echo "Error: Window ID and Tab index are required" >&2
        return 1
    fi

    _log_debug "Switch by window+index: window_id=$window_id tab_index=$tab_index"

    osascript <<EOF
tell application "Safari"
    try
        set targetWindow to first window whose id is $window_id
        set index of targetWindow to 1
        activate
        delay 0.05
        set current tab of targetWindow to tab $tab_index of targetWindow
        delay 0.05
        activate
    on error errMsg number errNum
        error "Switch by window+index failed: " & errMsg
    end try
end tell
EOF
}

# Фолбэк: переключение на вкладку по URL/Title в конкретном окне
# Аргументы: $1 - window_id, $2 - expected_url, $3 - expected_title
_switch_safari_tab_by_title_or_url() {
    local window_id="$1"
    local expected_url="$2"
    local expected_title="$3"
    local url_esc title_esc
    url_esc=$(_escape_applescript_string "$expected_url")
    title_esc=$(_escape_applescript_string "$expected_title")

    _log_debug "Switch by title/url: window_id=$window_id title='$expected_title' url='$expected_url'"

    osascript <<EOF
tell application "Safari"
  try
    set targetWindow to first window whose id is $window_id
    set index of targetWindow to 1
    activate
    delay 0.05
    set foundIndex to 0
    set tabsList to tabs of targetWindow
    set totalTabs to count of tabsList
    set i to 1
    repeat while i ≤ totalTabs
      set t to tab i of targetWindow
      set tTitle to name of t
      set tURL to ""
      try
        if URL of t is not missing value then set tURL to URL of t
      end try
      if tURL is "$url_esc" then
        set foundIndex to i
        exit repeat
      else if tTitle is "$title_esc" then
        set foundIndex to i
        exit repeat
      else if tURL contains "$url_esc" and "$url_esc" is not "" then
        set foundIndex to i
        exit repeat
      else if tTitle contains "$title_esc" and "$title_esc" is not "" then
        set foundIndex to i
        exit repeat
      end if
      set i to i + 1
    end repeat
    if foundIndex is not 0 then
      set current tab of targetWindow to tab foundIndex of targetWindow
      delay 0.05
      activate
    else
      error "No matching tab by title/url"
    end if
  on error errMsg number errNum
    error "Switch by title/url failed: " & errMsg
  end try
end tell
EOF
}

# Получить активный window/tab Safari в TSV: window_index\ttab_index\twindow_id\ttitle\turl
_get_active_tab_tsv() {
    osascript <<'EOF' | tr '\r' '\n'
try
  tell application "Safari"
    if (count of windows) is 0 then return "\t\t\t\t"
    set frontWindow to front window
    set winIndex to (index of frontWindow) as integer
    set winId to id of frontWindow
    set activeTab to current tab of frontWindow
    set tabIdx to (index of activeTab) as integer
    set tabTitle to name of activeTab
    set tabURL to ""
    try
      if URL of activeTab is not missing value then set tabURL to URL of activeTab
    end try
    set delim to ASCII character 9
    return (winIndex as string) & delim & (tabIdx as string) & delim & (winId as string) & delim & tabTitle & delim & tabURL
  end tell
on error errMsg number errNum
  return "ERROR\t\t\t" & errNum & "\t" & errMsg
end try
EOF
}

# Верификация: проверить что активные window_id и tab_index соответствуют ожидаемым
_verify_switched() {
    local expected_window_id="$1"
    local expected_tab_index="$2"
    local tsv active_win_idx active_tab_idx active_win_id
    tsv=$(_get_active_tab_tsv)
    active_win_idx=${tsv%%$'\t'*}; tsv=${tsv#*$'\t'}
    active_tab_idx=${tsv%%$'\t'*}; tsv=${tsv#*$'\t'}
    active_win_id=${tsv%%$'\t'*}
    _log_debug "Verify active: win_id=$active_win_id tab_idx=$active_tab_idx"
    [[ "$active_win_id" == "$expected_window_id" && "$active_tab_idx" == "$expected_tab_index" ]]
}

# Функция для извлечения позиционного ID вкладки из выбранной строки fzf
# Аргументы: $1 - строка от fzf в формате с TAB разделителем
# Возвращает: ID вкладки в формате "WindowIndex_TabIndex"
_extract_tab_id() {
    local selected_line="$1"
    echo "${selected_line%%$'\t'*}"
}

# Функция для извлечения названия вкладки из выбранной строки fzf
# Аргументы: $1 - строка от fzf в формате с TAB разделителем
# Возвращает: название вкладки
_extract_tab_title() {
    local selected_line="$1"
    # Второе поле (Title)
    echo "$selected_line" | awk -F '\t' '{print $2}'
}

# Извлечение стабильных ID окна и вкладки из строки fzf
# Аргументы: $1 - строка от fzf (TAB-делимитированная)
# Выводит в stdout: "window_id\ttab_id"
_extract_window_and_tab_ids() {
    local selected_line="$1"
    # Поля: 1) idx 2) title 3) url 4) window_id 5) tab_id
    echo "$selected_line" | awk -F '\t' '{print $4"\t"$5}'
}

# Функция проверки доступности fzf
_check_fzf_available() {
    if ! command -v fzf >/dev/null 2>&1; then
        echo "Error: fzf is not installed or not in PATH" >&2
        echo "Install with: brew install fzf" >&2
        return 1
    fi
    return 0
}

# Функция фильтрации списка вкладок по поисковому запросу
# Аргументы: $1 - поисковый запрос, $2 - список вкладок
# Возвращает: отфильтрованный список
_filter_tabs() {
    local search_query="$1"
    local tabs_list="$2"
    
    if [[ -z "$search_query" ]]; then
        echo "$tabs_list"
    else
        echo "$tabs_list" | grep -i "$search_query"
    fi
}

# Основная функция: Safari Tab Switcher
# Аргументы: $1 - необязательная строка поиска
safari_tab_switcher() {
    local search_query="$1"
    local mode_first=0
    local direct_window_id=""
    local direct_tab_index=""
    local title_for_fallback=""
    local url_for_fallback=""

    # Простейший парсер флагов
    if [[ "$1" == "--first" ]]; then
        mode_first=1
        search_query="$2"
    elif [[ "$1" == "--direct" ]]; then
        direct_window_id="$2"
        direct_tab_index="$3"
        if [[ -z "$direct_window_id" || -z "$direct_tab_index" ]]; then
            echo "Usage: $0 --direct WINDOW_ID TAB_INDEX" >&2
            return 1
        fi
    fi
    
    echo "Searching for Safari tabs..."
    
    # Получение списка всех вкладок
    local all_tabs
    all_tabs=$(_get_safari_tabs)
    
    if [[ -z "$all_tabs" ]]; then
        echo "No open Safari tabs found."
        return 0
    fi
    
    # Фильтрация списка по поисковому запросу (если передан)
    local filtered_tabs
    filtered_tabs=$(_filter_tabs "$search_query" "$all_tabs")
    
    if [[ -z "$filtered_tabs" ]]; then
        echo "No tabs match the search query: '$search_query'"
        return 0
    fi
    
    # Режим прямого переключения без fzf
    if [[ -n "$direct_window_id" ]]; then
        if _switch_safari_tab_by_window_and_index "$direct_window_id" "$direct_tab_index"; then
            if _verify_switched "$direct_window_id" "$direct_tab_index"; then
                echo "Successfully switched (direct)"
                return 0
            fi
            echo "Direct switch executed but verification failed" >&2
            return 1
        else
            echo "Direct switch failed" >&2
            return 1
        fi
    fi

    # Неинтерактивный режим: выбрать первую подходящую строку
    local selected_tab
    if [[ $mode_first -eq 1 ]]; then
        selected_tab=$(echo "$filtered_tabs" | head -n1)
    else
        # Проверка доступности fzf
        if ! _check_fzf_available; then
            return 1
        fi
        local fzf_preview_args=()
        if [[ "${FZF_SAFARI_PREVIEW:-0}" == "1" ]]; then
            local preview_script
            preview_script='awk -F "\t" '\''BEGIN{OFS=""} {printf "Window: %s (id=%s)\nTab:    %s (index=%s)\nURL:    %s\n", $1, $4, $2, $5, $3}'\'''
            fzf_preview_args=(--preview-window=down,3,border-top --preview "$preview_script")
        fi
        selected_tab=$(echo "$filtered_tabs" | fzf \
            --no-sort \
            --tac \
            --prompt="$FZF_SAFARI_PROMPT" \
            --header="$FZF_SAFARI_HEADER" \
            --exit-0 \
            --height="$FZF_SAFARI_HEIGHT" \
            --layout=reverse \
            --delimiter=$'\t' \
            --with-nth=2,3 \
            "${fzf_preview_args[@]}" \
            --border)
    fi
    
    if [[ -z "$selected_tab" ]]; then
        echo "No tab selected."
        return 0
    fi
    
    # Извлечение ID и названия выбранной вкладки
    local tab_id tab_title window_and_tab_ids window_id tab_index
    tab_id=$(_extract_tab_id "$selected_tab")
    tab_title=$(_extract_tab_title "$selected_tab")
    window_and_tab_ids=$(_extract_window_and_tab_ids "$selected_tab")
    window_id="${window_and_tab_ids%%$'\t'*}"
    tab_index="${window_and_tab_ids#*$'\t'}"
    # Для фолбэка: вытащим URL (3 поле)
    url_for_fallback=$(echo "$selected_tab" | awk -F '\t' '{print $3}')
    title_for_fallback="$tab_title"

    _log_debug "Selected: tab_id(index)=$tab_id, tab_title='$tab_title', window_id=$window_id, tab_index=$tab_index"

    # Сначала пробуем window_id + tab_index, затем проверяем; если не ок — фолбэк к positional; затем фолбэк по URL/Title
    if _switch_safari_tab_by_window_and_index "$window_id" "$tab_index"; then
        if _verify_switched "$window_id" "$tab_index"; then
            echo "Successfully switched to tab: $tab_title"
            return 0
        fi
        _log_debug "Verification failed after window+index, try positional fallback"
    else
        _log_debug "Switch by window+index failed, try positional fallback"
    fi

    if _switch_safari_tab "$tab_id"; then
        if _verify_switched "$window_id" "$tab_index"; then
            echo "Successfully switched to tab (positional): $tab_title"
            return 0
        fi
        _log_debug "Verification failed after positional, try title/url fallback"
    else
        _log_debug "Positional switch failed, try title/url fallback"
    fi

    if _switch_safari_tab_by_title_or_url "$window_id" "$url_for_fallback" "$title_for_fallback"; then
        if _verify_switched "$window_id" "$tab_index"; then
            echo "Successfully switched to tab (title/url): $tab_title"
            return 0
        fi
        _log_debug "Verification failed after title/url"
    fi

    echo "Failed to switch to tab: $tab_title" >&2
    return 1
}

# Основная функция готова для использования

# Запускать только если скрипт не импортируется через source
if [[ -z "${SAFARI_SWITCHER_NO_AUTORUN:-}" && "${ZSH_EVAL_CONTEXT}" == "toplevel" ]]; then
  safari_tab_switcher "$@"
fi