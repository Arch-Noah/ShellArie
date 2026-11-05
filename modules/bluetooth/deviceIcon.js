.pragma library

// Icône BlueZ (« audio-headset », « input-mouse »…) → nom d'icône Material Symbols.
function deviceIcon(icon) {
    const i = (icon || "").toLowerCase();
    if (i.indexOf("headset") >= 0 || i.indexOf("headphone") >= 0)
        return "headphones";
    if (i.indexOf("audio") >= 0 || i.indexOf("speaker") >= 0)
        return "speaker";
    if (i.indexOf("keyboard") >= 0)
        return "keyboard";
    if (i.indexOf("mouse") >= 0)
        return "mouse";
    if (i.indexOf("gaming") >= 0 || i.indexOf("joystick") >= 0)
        return "sports_esports";
    if (i.indexOf("tablet") >= 0)
        return "tablet";
    if (i.indexOf("phone") >= 0)
        return "smartphone";
    if (i.indexOf("computer") >= 0 || i.indexOf("laptop") >= 0)
        return "computer";
    if (i.indexOf("watch") >= 0)
        return "watch";
    if (i.indexOf("display") >= 0 || i.indexOf("video") >= 0)
        return "tv";
    if (i.indexOf("printer") >= 0)
        return "print";
    if (i.indexOf("camera") >= 0)
        return "photo_camera";
    return "bluetooth";
}

// Un appareil sans nom a pour nom son adresse (« 7F-92-03-79-A2-90 »)
function isAddressName(name) {
    return /^([0-9A-Fa-f]{2}[-:]){5}[0-9A-Fa-f]{2}$/.test(name || "");
}
