function clean(item) {
    if (item.length >= 2 && item.indexOf('"') === 0 && item.lastIndexOf('"') === item.length - 1) return item.substring(1, item.length - 1);
    else return item;
}
function match(pat, str) {
    let rgx = new RegExp(clean(pat))
    return rgx.test(str)
}

function sub(str) {
    const appName = activeTaskItem?.appName ?? "";
    const winTitle = activeTaskItem?.title ?? "";
    return str
        .replace("%a", appName)
        .replace("%w", winTitle)
        .replace("%q", fullActivityInfo?.name ?? "")
}

function substitute() {
    let minSize = Math.min(cfg.subsMatchApp.length, cfg.subsReplace.length, cfg.subsMatchTitle.length)

    // Use discoveredAppName first so Chrome/Chromium show "Google Chrome"
    // instead of the active tab title.
    let appName = activeTaskItem?.appName ?? "";
    let title = activeTaskItem?.title ?? "";
    let text = appName === title ? cfg.txtSameFound : cfg.txt

    for (let i = 0; i < minSize; i++) {
        if (match(cfg.subsMatchApp[i], appName) && match(cfg.subsMatchTitle[i], title)) {
            text = clean(cfg.subsReplace[i])
        }
    }
    return sub(text)
}
function altSubstitute() {
    return cfg.altTxt.replace("%q", fullActivityInfo.name)
}
function getText() {
    if (isActiveWindowMaximized) return Tools.substitute()
    else if (cfg.filterByMaximized) return Tools.altSubstitute()
    else if (existsWindowActive) return Tools.substitute()
    else return Tools.altSubstitute()
}
function getIcon() {
    if ((existsWindowActive && !cfg.filterByMaximized) || (cfg.filterByMaximized && isActiveWindowMaximized)) return activeTaskItem.icon
    else if (cfg.noIcon) return ""
    else if (cfg.activityIcon) return fullActivityInfo.icon
    else return cfg.customIcon
}
function getElide(val) {
    switch (val) {
        case 0: return Text.ElideNone
        case 1: return Text.ElideLeft
        case 2: return Text.ElideMiddle
        case 3: return Text.ElideRight
    }
}