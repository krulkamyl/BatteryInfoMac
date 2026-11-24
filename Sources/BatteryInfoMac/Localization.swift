import Foundation

// MARK: - Supported Languages

enum AppLanguage: String, CaseIterable, Codable, Identifiable, Sendable {
    case system = "system"
    case en = "en"
    case pl = "pl"
    case de = "de"
    case es = "es"
    case fr = "fr"
    case it = "it"
    case uk = "uk"
    case ja = "ja"

    var id: String { rawValue }

    var nativeName: String {
        switch self {
        case .system: return "Auto (System)"
        case .en: return "English"
        case .pl: return "Polski"
        case .de: return "Deutsch"
        case .es: return "Español"
        case .fr: return "Français"
        case .it: return "Italiano"
        case .uk: return "Українська"
        case .ja: return "日本語"
        }
    }

    /// Resolves `.system` to the best supported concrete language based on macOS `Locale.preferredLanguages`.
    var resolved: ResolvedLanguage {
        switch self {
        case .en: return .en
        case .pl: return .pl
        case .de: return .de
        case .es: return .es
        case .fr: return .fr
        case .it: return .it
        case .uk: return .uk
        case .ja: return .ja
        case .system:
            for preferred in Locale.preferredLanguages {
                let code = preferred.lowercased().prefix(2)
                switch code {
                case "pl": return .pl
                case "de": return .de
                case "es": return .es
                case "fr": return .fr
                case "it": return .it
                case "uk": return .uk
                case "ja": return .ja
                case "en": return .en
                default: continue
                }
            }
            return .en
        }
    }
}

enum ResolvedLanguage: String, Sendable {
    case en, pl, de, es, fr, it, uk, ja
}

// MARK: - Localization Dictionary

enum L10n {
    private static func pick(
        _ lang: AppLanguage,
        en: String,
        pl: String,
        de: String,
        es: String,
        fr: String,
        it: String,
        uk: String,
        ja: String
    ) -> String {
        switch lang.resolved {
        case .en: return en
        case .pl: return pl
        case .de: return de
        case .es: return es
        case .fr: return fr
        case .it: return it
        case .uk: return uk
        case .ja: return ja
        }
    }

    // MARK: App & Headers

    static func appTitle(_ l: AppLanguage) -> String {
        pick(l,
             en: "Bluetooth Battery",
             pl: "Bateria Bluetooth",
             de: "Bluetooth-Batterie",
             es: "Batería Bluetooth",
             fr: "Batterie Bluetooth",
             it: "Batteria Bluetooth",
             uk: "Батарея Bluetooth",
             ja: "Bluetooth バッテリー")
    }

    static func back(_ l: AppLanguage) -> String {
        pick(l, en: "Back", pl: "Wróć", de: "Zurück", es: "Atrás", fr: "Retour", it: "Indietro", uk: "Назад", ja: "戻る")
    }

    static func add(_ l: AppLanguage) -> String {
        pick(l, en: "Add", pl: "Dodaj", de: "Hinzufügen", es: "Añadir", fr: "Ajouter", it: "Aggiungi", uk: "Додати", ja: "追加")
    }

    static func settings(_ l: AppLanguage) -> String {
        pick(l, en: "Settings", pl: "Ustawienia", de: "Einstellungen", es: "Ajustes", fr: "Réglages", it: "Impostazioni", uk: "Налаштування", ja: "設定")
    }

    static func configuration(_ l: AppLanguage) -> String {
        pick(l, en: "Configuration", pl: "Konfiguracja", de: "Konfiguration", es: "Configuración", fr: "Configuration", it: "Configurazione", uk: "Конфігурація", ja: "設定")
    }

    static func quit(_ l: AppLanguage) -> String {
        pick(l, en: "Quit", pl: "Zakończ", de: "Beenden", es: "Salir", fr: "Quitter", it: "Esci", uk: "Вийти", ja: "終了")
    }

    static func quitApp(_ l: AppLanguage) -> String {
        pick(l, en: "Quit BatteryInfoMac", pl: "Zakończ BatteryInfoMac", de: "BatteryInfoMac beenden", es: "Salir de BatteryInfoMac", fr: "Quitter BatteryInfoMac", it: "Esci da BatteryInfoMac", uk: "Вийти з BatteryInfoMac", ja: "BatteryInfoMac を終了")
    }

    static func refreshNow(_ l: AppLanguage) -> String {
        pick(l, en: "Refresh Now", pl: "Odśwież teraz", de: "Jetzt aktualisieren", es: "Actualizar ahora", fr: "Actualiser maintenant", it: "Aggiorna ora", uk: "Оновити зараз", ja: "今すぐ更新")
    }

    static func openConfigPanel(_ l: AppLanguage) -> String {
        pick(l, en: "Open Configuration", pl: "Otwórz panel konfiguracji", de: "Konfiguration öffnen", es: "Abrir configuración", fr: "Ouvrir la configuration", it: "Apri configurazione", uk: "Відкрити налаштування", ja: "設定パネルを開く")
    }

    static func cancel(_ l: AppLanguage) -> String {
        pick(l, en: "Cancel", pl: "Anuluj", de: "Abbrechen", es: "Cancelar", fr: "Annuler", it: "Annulla", uk: "Скасувати", ja: "キャンセル")
    }

    static func save(_ l: AppLanguage) -> String {
        pick(l, en: "Save", pl: "Zapisz", de: "Speichern", es: "Guardar", fr: "Enregistrer", it: "Salva", uk: "Зберегти", ja: "保存")
    }

    static func delete(_ l: AppLanguage) -> String {
        pick(l, en: "Delete", pl: "Usuń", de: "Löschen", es: "Eliminar", fr: "Supprimer", it: "Elimina", uk: "Видалити", ja: "削除")
    }

    // MARK: Device List

    static func connectedBluetooth(_ l: AppLanguage) -> String {
        pick(l,
             en: "Connected Bluetooth",
             pl: "Połączone Bluetooth",
             de: "Verbunden (Bluetooth)",
             es: "Bluetooth conectados",
             fr: "Bluetooth connectés",
             it: "Bluetooth connessi",
             uk: "Підключені Bluetooth",
             ja: "接続中の Bluetooth")
    }

    static func disconnectedHidden(_ l: AppLanguage) -> String {
        pick(l,
             en: "Disconnected (hidden in menu bar)",
             pl: "Rozłączone (ukryte na pasku)",
             de: "Getrennt (in Menüleiste ausgeblendet)",
             es: "Desconectados (ocultos en la barra)",
             fr: "Déconnectés (masqués dans la barre)",
             it: "Disconnessi (nascosti nella barra)",
             uk: "Відключені (сховані на панелі)",
             ja: "未接続（メニューバー非表示）")
    }

    static func noConnectedTitle(_ l: AppLanguage) -> String {
        pick(l,
             en: "No connected Bluetooth devices",
             pl: "Brak połączonych urządzeń Bluetooth",
             de: "Keine Bluetooth-Geräte verbunden",
             es: "No hay dispositivos Bluetooth conectados",
             fr: "Aucun appareil Bluetooth connecté",
             it: "Nessun dispositivo Bluetooth connesso",
             uk: "Немає підключених пристроїв Bluetooth",
             ja: "接続中の Bluetooth デバイスがありません")
    }

    static func noConnectedSubtitle(_ l: AppLanguage) -> String {
        pick(l,
             en: "When you connect a Bluetooth keyboard, mouse, or headphones, its battery level will automatically appear in the menu bar.",
             pl: "Gdy podłączysz klawiaturę, myszkę lub słuchawki Bluetooth, ich poziom baterii pojawi się automatycznie na pasku górnym.",
             de: "Sobald du eine Bluetooth-Tastatur, Maus oder Kopfhörer verbindest, erscheint der Akkustand automatisch in der Menüleiste.",
             es: "Cuando conectes un teclado, ratón o auriculares Bluetooth, su batería aparecerá automáticamente en la barra superior.",
             fr: "Dès que vous connectez un clavier, une souris ou des écouteurs Bluetooth, leur batterie apparaîtra dans la barre des menus.",
             it: "Quando connetti una tastiera, un mouse o delle cuffie Bluetooth, la batteria apparirà automaticamente nella barra dei menu.",
             uk: "Коли ви підключите клавіатуру, мишу чи навушники Bluetooth, їхній заряд автоматично з'явиться на верхній панелі.",
             ja: "Bluetooth キーボード、マウス、ヘッドフォンを接続すると、バッテリー残量が自動的にメニューバーに表示されます。")
    }

    static func updatedAt(_ time: String, _ l: AppLanguage) -> String {
        let prefix = pick(l, en: "Updated:", pl: "Aktualizacja:", de: "Aktualisiert:", es: "Actualizado:", fr: "Mis à jour :", it: "Aggiornato:", uk: "Оновлено:", ja: "更新:")
        return "\(prefix) \(time)"
    }

    static func scanningBluetooth(_ l: AppLanguage) -> String {
        pick(l, en: "Scanning Bluetooth...", pl: "Skanowanie Bluetooth...", de: "Bluetooth wird gescannt...", es: "Escaneando Bluetooth...", fr: "Analyse Bluetooth...", it: "Scansione Bluetooth...", uk: "Сканування Bluetooth...", ja: "Bluetooth をスキャン中...")
    }

    static func connectedNoBattery(_ l: AppLanguage) -> String {
        pick(l, en: "Connected • no battery report", pl: "Połączone • brak raportu baterii", de: "Verbunden • kein Akkustatus", es: "Conectado • sin nivel de batería", fr: "Connecté • batterie non signalée", it: "Connesso • batteria non disponibile", uk: "Підключено • немає даних батареї", ja: "接続済み・バッテリー情報なし")
    }

    static func connected(_ l: AppLanguage) -> String {
        pick(l, en: "Connected", pl: "Połączone", de: "Verbunden", es: "Conectado", fr: "Connecté", it: "Connesso", uk: "Підключено", ja: "接続済み")
    }

    static func disconnected(_ l: AppLanguage) -> String {
        pick(l, en: "Disconnected", pl: "Rozłączone", de: "Getrennt", es: "Desconectado", fr: "Déconnecté", it: "Disconnesso", uk: "Відключено", ja: "未接続")
    }

    static func noData(_ l: AppLanguage) -> String {
        pick(l, en: "no data", pl: "brak danych", de: "keine Daten", es: "sin datos", fr: "aucune donnée", it: "nessun dato", uk: "немає даних", ja: "データなし")
    }

    static func charging(_ l: AppLanguage) -> String {
        pick(l, en: "Charging", pl: "Ładowanie", de: "Lädt", es: "Cargando", fr: "En charge", it: "In carica", uk: "Заряджається", ja: "充電中")
    }

    static func emptyMenuBarTooltip(_ l: AppLanguage) -> String {
        pick(l,
             en: "No connected Bluetooth devices (click to configure)",
             pl: "Brak połączonych urządzeń Bluetooth (kliknij, aby skonfigurować)",
             de: "Keine verbundenen Bluetooth-Geräte (zum Konfigurieren klicken)",
             es: "Sin dispositivos Bluetooth conectados (clic para configurar)",
             fr: "Aucun appareil Bluetooth connecté (cliquez pour configurer)",
             it: "Nessun dispositivo Bluetooth connesso (clicca per configurare)",
             uk: "Немає підключених пристроїв Bluetooth (натисніть для налаштування)",
             ja: "接続中の Bluetooth デバイスなし（クリックして設定）")
    }

    static func bluetoothDeviceFallback(_ l: AppLanguage) -> String {
        pick(l, en: "Bluetooth Device", pl: "Urządzenie Bluetooth", de: "Bluetooth-Gerät", es: "Dispositivo Bluetooth", fr: "Appareil Bluetooth", it: "Dispositivo Bluetooth", uk: "Пристрій Bluetooth", ja: "Bluetooth デバイス")
    }

    // MARK: Tooltips & Actions

    static func helpRefresh(_ l: AppLanguage) -> String {
        pick(l, en: "Refresh Bluetooth devices", pl: "Odśwież status urządzeń Bluetooth", de: "Bluetooth-Geräte aktualisieren", es: "Actualizar dispositivos Bluetooth", fr: "Actualiser les appareils Bluetooth", it: "Aggiorna dispositivi Bluetooth", uk: "Оновити пристрої Bluetooth", ja: "Bluetooth デバイスを更新")
    }

    static func helpAdd(_ l: AppLanguage) -> String {
        pick(l, en: "Add Bluetooth device", pl: "Dodaj urządzenie Bluetooth", de: "Bluetooth-Gerät hinzufügen", es: "Añadir dispositivo Bluetooth", fr: "Ajouter un appareil Bluetooth", it: "Aggiungi dispositivo Bluetooth", uk: "Додати пристрій Bluetooth", ja: "Bluetooth デバイスを追加")
    }

    static func helpMoveLeft(_ l: AppLanguage) -> String {
        pick(l, en: "Move left in menu bar", pl: "Przesuń w lewo na pasku", de: "In Menüleiste nach links", es: "Mover a la izquierda en la barra", fr: "Déplacer à gauche dans la barre", it: "Sposta a sinistra nella barra", uk: "Перемістити ліворуч на панелі", ja: "メニューバーで左に移動")
    }

    static func helpMoveRight(_ l: AppLanguage) -> String {
        pick(l, en: "Move right in menu bar", pl: "Przesuń w prawo na pasku", de: "In Menüleiste nach rechts", es: "Mover a la derecha en la barra", fr: "Déplacer à droite dans la barre", it: "Sposta a destra nella barra", uk: "Перемістити праворуч на панелі", ja: "メニューバーで右に移動")
    }

    static func helpHideInBar(_ l: AppLanguage) -> String {
        pick(l, en: "Hide in menu bar", pl: "Ukryj na pasku górnym", de: "In Menüleiste ausblenden", es: "Ocultar en la barra superior", fr: "Masquer dans la barre", it: "Nascondi nella barra", uk: "Сховати на верхній панелі", ja: "メニューバーから非表示")
    }

    static func helpShowInBar(_ l: AppLanguage) -> String {
        pick(l, en: "Show in menu bar", pl: "Pokaż na pasku górnym", de: "In Menüleiste anzeigen", es: "Mostrar en la barra superior", fr: "Afficher dans la barre", it: "Mostra nella barra", uk: "Показати на верхній панелі", ja: "メニューバーに表示")
    }

    static func helpEdit(_ l: AppLanguage) -> String {
        pick(l, en: "Edit symbol & settings", pl: "Edytuj symbol i konfigurację", de: "Symbol & Einstellungen bearbeiten", es: "Editar símbolo y configuración", fr: "Modifier l'icône et les réglages", it: "Modifica simbolo e impostazioni", uk: "Редагувати символ і налаштування", ja: "アイコンと設定を編集")
    }

    // MARK: Add Device Screen

    static func addDeviceTitle(_ l: AppLanguage) -> String {
        pick(l, en: "Add Bluetooth Device", pl: "Dodaj urządzenie Bluetooth", de: "Bluetooth-Gerät hinzufügen", es: "Añadir dispositivo Bluetooth", fr: "Ajouter un appareil", it: "Aggiungi dispositivo", uk: "Додати пристрій Bluetooth", ja: "Bluetooth デバイスを追加")
    }

    static func addManualTitle(_ l: AppLanguage) -> String {
        pick(l, en: "Add manually (name or MAC address)", pl: "Dodaj ręcznie (nazwa lub adres MAC)", de: "Manuell hinzufügen (Name oder MAC)", es: "Añadir manualmente (nombre o MAC)", fr: "Ajouter manuellement (nom ou MAC)", it: "Aggiungi manualmente (nome o MAC)", uk: "Додати вручну (назва або MAC)", ja: "手動で追加（名前または MAC）")
    }

    static func addManualSubtitle(_ l: AppLanguage) -> String {
        pick(l, en: "Configure any Bluetooth device with a custom symbol", pl: "Skonfiguruj dowolne urządzenie Bluetooth z własnym symbolem", de: "Beliebiges Bluetooth-Gerät mit eigenem Symbol einrichten", es: "Configura cualquier dispositivo Bluetooth con tu propio símbolo", fr: "Configurez n'importe quel appareil Bluetooth avec son icône", it: "Configura qualsiasi dispositivo Bluetooth con un simbolo", uk: "Налаштуйте будь-який пристрій Bluetooth зі своїм символом", ja: "任意の Bluetooth デバイスをカスタムアイコンで設定")
    }

    static func detectedPairedSection(_ l: AppLanguage) -> String {
        pick(l, en: "Detected / paired Bluetooth devices", pl: "Wykryte / sparowane urządzenia Bluetooth", de: "Erkannte / gekoppelte Bluetooth-Geräte", es: "Dispositivos Bluetooth detectados", fr: "Appareils Bluetooth détectés / jumelés", it: "Dispositivi Bluetooth rilevati / abbinati", uk: "Виявлені / спарені пристрої Bluetooth", ja: "検出 / ペアリング済みのデバイス")
    }

    static func allDetectedAddedTitle(_ l: AppLanguage) -> String {
        pick(l, en: "All detected devices are already added", pl: "Wszystkie wykryte urządzenia są już dodane", de: "Alle erkannten Geräte wurden hinzugefügt", es: "Todos los dispositivos ya están añadidos", fr: "Tous les appareils détectés sont déjà ajoutés", it: "Tutti i dispositivi rilevati sono già aggiunti", uk: "Усі виявлені пристрої вже додано", ja: "検出されたデバイスはすべて追加済みです")
    }

    static func allDetectedAddedSubtitle(_ l: AppLanguage) -> String {
        pick(l, en: "You can add another manually above or refresh after pairing a new device in System Settings.", pl: "Możesz dodać kolejne ręcznie powyżej lub odświeżyć listę po sparowaniu nowego urządzenia w Ustawieniach systemowych.", de: "Du kannst oben ein weiteres manuell hinzufügen oder nach dem Koppeln aktualisieren.", es: "Puedes añadir otro manualmente arriba o actualizar tras emparejar uno nuevo.", fr: "Ajoutez-en un manuellement ci-dessus ou actualisez après un nouveau jumelage.", it: "Puoi aggiungerne un altro manualmente sopra o aggiornare dopo l'abbinamento.", uk: "Ви можете додати пристрій вручну вище або оновити список після спарювання.", ja: "上から手動で追加するか、システム設定でペアリング後に更新してください。")
    }

    // MARK: Edit Device Screen

    static func newDeviceTitle(_ l: AppLanguage) -> String {
        pick(l, en: "New Device", pl: "Nowe urządzenie", de: "Neues Gerät", es: "Nuevo dispositivo", fr: "Nouvel appareil", it: "Nuovo dispositivo", uk: "Новий пристрій", ja: "新しいデバイス")
    }

    static func editDeviceTitle(_ l: AppLanguage) -> String {
        pick(l, en: "Edit Device", pl: "Edytuj urządzenie", de: "Gerät bearbeiten", es: "Editar dispositivo", fr: "Modifier l'appareil", it: "Modifica dispositivo", uk: "Редагувати пристрій", ja: "デバイスを編集")
    }

    static func menuBarPreview(_ l: AppLanguage) -> String {
        pick(l, en: "Menu bar preview:", pl: "Podgląd na pasku:", de: "Menüleisten-Vorschau:", es: "Vista previa en barra:", fr: "Aperçu barre des menus :", it: "Anteprima barra:", uk: "Попередній перегляд:", ja: "メニューバーのプレビュー:")
    }

    static func btMatchNameLabel(_ l: AppLanguage) -> String {
        pick(l, en: "Bluetooth device name (to match)", pl: "Nazwa urządzenia Bluetooth (do dopasowania)", de: "Bluetooth-Gerätename (zur Zuordnung)", es: "Nombre Bluetooth (para coincidencia)", fr: "Nom Bluetooth (pour correspondance)", it: "Nome Bluetooth (per corrispondenza)", uk: "Назва Bluetooth (для зіставлення)", ja: "Bluetooth デバイス名（照合用）")
    }

    static func btMatchNamePlaceholder(_ l: AppLanguage) -> String {
        pick(l, en: "e.g. Magic Keyboard, MX Master 4", pl: "np. Magic Keyboard, MX Master 4", de: "z. B. Magic Keyboard, MX Master 4", es: "ej. Magic Keyboard, MX Master 4", fr: "ex. Magic Keyboard, MX Master 4", it: "es. Magic Keyboard, MX Master 4", uk: "напр. Magic Keyboard, MX Master 4", ja: "例: Magic Keyboard, MX Master 4")
    }

    static func customLabelField(_ l: AppLanguage) -> String {
        pick(l, en: "Custom display label (optional)", pl: "Własna etykieta (opcjonalna)", de: "Eigene Bezeichnung (optional)", es: "Etiqueta personalizada (opcional)", fr: "Nom personnalisé (facultatif)", it: "Etichetta personalizzata (opzionale)", uk: "Власна назва (необов'язково)", ja: "カスタム表示名（任意）")
    }

    static func customLabelPlaceholder(_ l: AppLanguage) -> String {
        pick(l, en: "e.g. Work Keyboard", pl: "np. Klawiatura biuro", de: "z. B. Büro-Tastatur", es: "ej. Teclado oficina", fr: "ex. Clavier bureau", it: "es. Tastiera ufficio", uk: "напр. Клавіатура офіс", ja: "例: 仕事用キーボード")
    }

    static func macAddressField(_ l: AppLanguage) -> String {
        pick(l, en: "Bluetooth MAC address (optional)", pl: "Adres MAC Bluetooth (opcjonalny)", de: "Bluetooth-MAC-Adresse (optional)", es: "Dirección MAC Bluetooth (opcional)", fr: "Adresse MAC Bluetooth (facultative)", it: "Indirizzo MAC Bluetooth (opzionale)", uk: "MAC-адреса Bluetooth (необов'язково)", ja: "Bluetooth MAC アドレス（任意）")
    }

    static func macAddressPlaceholder(_ l: AppLanguage) -> String {
        pick(l, en: "e.g. AA:BB:CC:DD:EE:FF", pl: "np. AA:BB:CC:DD:EE:FF", de: "z. B. AA:BB:CC:DD:EE:FF", es: "ej. AA:BB:CC:DD:EE:FF", fr: "ex. AA:BB:CC:DD:EE:FF", it: "es. AA:BB:CC:DD:EE:FF", uk: "напр. AA:BB:CC:DD:EE:FF", ja: "例: AA:BB:CC:DD:EE:FF")
    }

    static func menuBarSymbol(_ l: AppLanguage) -> String {
        pick(l, en: "Menu bar symbol:", pl: "Symbol na pasku górnym:", de: "Menüleisten-Symbol:", es: "Símbolo en la barra:", fr: "Icône dans la barre :", it: "Simbolo nella barra:", uk: "Символ на панелі:", ja: "メニューバーのアイコン:")
    }

    static func toggleShowWhenConnected(_ l: AppLanguage) -> String {
        pick(l, en: "Show in menu bar (when connected)", pl: "Pokazuj na pasku górnym (gdy połączone)", de: "In Menüleiste anzeigen (wenn verbunden)", es: "Mostrar en barra (si está conectado)", fr: "Afficher dans la barre (si connecté)", it: "Mostra nella barra (se connesso)", uk: "Показувати на панелі (коли підключено)", ja: "接続時にメニューバーに表示")
    }

    static func toggleShowShortLabel(_ l: AppLanguage) -> String {
        pick(l, en: "Show short name next to symbol", pl: "Pokazuj krótką nazwę obok symbolu", de: "Kurzen Namen neben Symbol anzeigen", es: "Mostrar nombre corto junto al símbolo", fr: "Afficher le nom court à côté de l'icône", it: "Mostra nome breve accanto al simbolo", uk: "Показувати коротку назву біля символу", ja: "アイコンの横に短い名前を表示")
    }

    static func toggleCustomThreshold(_ l: AppLanguage) -> String {
        pick(l, en: "Custom low-battery threshold", pl: "Własny próg niskiej baterii", de: "Eigener Schwellenwert für niedrigen Akku", es: "Umbral personalizado de batería baja", fr: "Seuil personnalisé de batterie faible", it: "Soglia batteria scarica personalizzata", uk: "Власний поріг низького заряду", ja: "カスタム低バッテリーしきい値")
    }

    static func warnBelow(_ l: AppLanguage) -> String {
        pick(l, en: "Highlight below:", pl: "Ostrzegaj poniżej:", de: "Warnen unter:", es: "Resaltar por debajo de:", fr: "Alerter sous :", it: "Evidenzia sotto:", uk: "Попереджати нижче:", ja: "以下で強調表示:")
    }

    // MARK: Settings Screen

    static func sectionMenuBar(_ l: AppLanguage) -> String {
        pick(l, en: "Menu Bar", pl: "Pasek górny", de: "Menüleiste", es: "Barra de menús", fr: "Barre des menus", it: "Barra dei menu", uk: "Верхня панель", ja: "メニューバー")
    }

    static func autoShowDetected(_ l: AppLanguage) -> String {
        pick(l, en: "Automatically show detected Bluetooth devices", pl: "Automatycznie pokazuj wykryte urządzenia Bluetooth", de: "Erkannte Bluetooth-Geräte automatisch anzeigen", es: "Mostrar automáticamente dispositivos detectados", fr: "Afficher automatiquement les appareils détectés", it: "Mostra automaticamente dispositivi rilevati", uk: "Автоматично показувати виявлені пристрої", ja: "検出した Bluetooth デバイスを自動表示")
    }

    static func displayFormat(_ l: AppLanguage) -> String {
        pick(l, en: "Display format", pl: "Format wyświetlania", de: "Anzeigeformat", es: "Formato", fr: "Format d'affichage", it: "Formato", uk: "Формат відображення", ja: "表示形式")
    }

    static func iconSpacing(_ l: AppLanguage) -> String {
        pick(l, en: "Item spacing", pl: "Odstęp między ikonami", de: "Abstand", es: "Espaciado", fr: "Espacement", it: "Spaziatura", uk: "Інтервал", ja: "間隔")
    }

    static func showChargingBolt(_ l: AppLanguage) -> String {
        pick(l, en: "Show charging bolt icon", pl: "Pokazuj ikonę ładowania (błyskawica)", de: "Ladesymbol (Blitz) anzeigen", es: "Mostrar icono de carga (rayo)", fr: "Afficher l'icône de charge (éclair)", it: "Mostra icona di ricarica (fulmine)", uk: "Показувати іконку заряджання (блискавка)", ja: "充電アイコン（稲妻）を表示")
    }

    static func sectionLowBattery(_ l: AppLanguage) -> String {
        pick(l, en: "Low Battery", pl: "Niski poziom baterii", de: "Niedriger Akkustand", es: "Batería baja", fr: "Batterie faible", it: "Batteria scarica", uk: "Низький заряд", ja: "バッテリー残量低下")
    }

    static func colorizeLowBattery(_ l: AppLanguage) -> String {
        pick(l, en: "Colorize low battery in menu bar", pl: "Koloruj niski poziom na pasku", de: "Niedrigen Akku in Menüleiste färben", es: "Colorear batería baja en la barra", fr: "Colorer la batterie faible dans la barre", it: "Colora batteria scarica nella barra", uk: "Підсвічувати низький заряд на панелі", ja: "残量低下時に色分け表示")
    }

    static func defaultThreshold(_ l: AppLanguage) -> String {
        pick(l, en: "Default warning threshold", pl: "Domyślny próg ostrzegania", de: "Standard-Warnschwelle", es: "Umbral predeterminado", fr: "Seuil d'alerte par défaut", it: "Soglia predefinita", uk: "Поріг за замовчуванням", ja: "デフォルトの警告しきい値")
    }

    static func sectionGeneral(_ l: AppLanguage) -> String {
        pick(l, en: "General", pl: "Ogólne", de: "Allgemein", es: "General", fr: "Général", it: "Generali", uk: "Загальні", ja: "一般")
    }

    static func languageLabel(_ l: AppLanguage) -> String {
        pick(l, en: "Language", pl: "Język", de: "Sprache", es: "Idioma", fr: "Langue", it: "Lingua", uk: "Мова", ja: "言語")
    }

    static func refreshEvery(_ l: AppLanguage) -> String {
        pick(l, en: "Refresh interval", pl: "Odświeżanie co", de: "Aktualisierung alle", es: "Actualizar cada", fr: "Actualiser toutes les", it: "Aggiorna ogni", uk: "Оновлювати кожні", ja: "更新間隔")
    }

    static func seconds(_ n: Int, _ l: AppLanguage) -> String {
        switch l.resolved {
        case .en: return "\(n) seconds"
        case .pl: return "\(n) sekund"
        case .de: return "\(n) Sekunden"
        case .es: return "\(n) segundos"
        case .fr: return "\(n) secondes"
        case .it: return "\(n) secondi"
        case .uk: return "\(n) секунд"
        case .ja: return "\(n) 秒"
        }
    }

    static func minutes(_ n: Int, _ l: AppLanguage) -> String {
        switch l.resolved {
        case .en: return "\(n) minutes"
        case .pl: return "\(n) minuty"
        case .de: return "\(n) Minuten"
        case .es: return "\(n) minutos"
        case .fr: return "\(n) minutes"
        case .it: return "\(n) minuti"
        case .uk: return "\(n) хвилини"
        case .ja: return "\(n) 分"
        }
    }

    static func launchAtLogin(_ l: AppLanguage) -> String {
        pick(l, en: "Launch at login", pl: "Uruchamiaj przy starcie macOS", de: "Bei Anmeldung starten", es: "Abrir al iniciar sesión", fr: "Lancer à l'ouverture de session", it: "Avvia al login", uk: "Запускати при вході в macOS", ja: "ログイン時に起動")
    }

    static func bluetoothOnlyFootnote(_ l: AppLanguage) -> String {
        pick(l,
             en: "Monitors Bluetooth devices only. Disconnected devices are automatically hidden from the top menu bar.",
             pl: "Aplikacja monitoruje wyłącznie urządzenia Bluetooth. Odłączone urządzenia są automatycznie ukrywane na pasku górnym.",
             de: "Überwacht nur Bluetooth-Geräte. Getrennte Geräte werden automatisch aus der Menüleiste ausgeblendet.",
             es: "Supervisa solo dispositivos Bluetooth. Los desconectados se ocultan automáticamente de la barra superior.",
             fr: "Surveille uniquement les appareils Bluetooth. Les appareils déconnectés sont masqués automatiquement.",
             it: "Monitora solo dispositivi Bluetooth. I dispositivi disconnessi vengono nascosti automaticamente dalla barra.",
             uk: "Відстежує лише пристрої Bluetooth. Відключені пристрої автоматично ховаються з верхньої панелі.",
             ja: "Bluetooth デバイスのみを監視します。未接続のデバイスはメニューバーから自動的に非表示になります。")
    }

    // MARK: Format & Spacing Names

    static func formatName(_ format: MenuBarDisplayFormat, _ l: AppLanguage) -> String {
        switch format {
        case .iconAndPercent:
            return pick(l, en: "Icon + 60%", pl: "Symbol + 60%", de: "Symbol + 60%", es: "Icono + 60%", fr: "Icône + 60%", it: "Icona + 60%", uk: "Символ + 60%", ja: "アイコン + 60%")
        case .iconAndNumber:
            return pick(l, en: "Icon + 60 (compact)", pl: "Symbol + 60 (kompaktowy)", de: "Symbol + 60 (kompakt)", es: "Icono + 60 (compacto)", fr: "Icône + 60 (compact)", it: "Icona + 60 (compatto)", uk: "Символ + 60 (компактно)", ja: "アイコン + 60（コンパクト）")
        case .iconNamePercent:
            return pick(l, en: "Icon + name + 60%", pl: "Symbol + nazwa + 60%", de: "Symbol + Name + 60%", es: "Icono + nombre + 60%", fr: "Icône + nom + 60%", it: "Icona + nome + 60%", uk: "Символ + назва + 60%", ja: "アイコン + 名前 + 60%")
        }
    }

    static func spacingName(_ spacing: MenuBarSpacing, _ l: AppLanguage) -> String {
        switch spacing {
        case .compact:
            return pick(l, en: "Compact", pl: "Kompaktowy", de: "Kompakt", es: "Compacto", fr: "Compact", it: "Compatto", uk: "Компактний", ja: "狭い")
        case .normal:
            return pick(l, en: "Normal", pl: "Normalny", de: "Normal", es: "Normal", fr: "Normal", it: "Normale", uk: "Звичайний", ja: "標準")
        case .wide:
            return pick(l, en: "Wide", pl: "Szeroki", de: "Breit", es: "Amplio", fr: "Large", it: "Ampio", uk: "Широкий", ja: "広い")
        }
    }

    // MARK: Symbol Display Names

    static func symbolName(_ symbol: DeviceSymbol, _ l: AppLanguage) -> String {
        switch symbol {
        case .keyboard:
            return pick(l, en: "Keyboard", pl: "Klawiatura", de: "Tastatur", es: "Teclado", fr: "Clavier", it: "Tastiera", uk: "Клавіатура", ja: "キーボード")
        case .keyboardFill:
            return pick(l, en: "Keyboard (filled)", pl: "Klawiatura (pełna)", de: "Tastatur (gefüllt)", es: "Teclado (relleno)", fr: "Clavier (plein)", it: "Tastiera (piena)", uk: "Клавіатура (заповнена)", ja: "キーボード（塗り）")
        case .mouse:
            return pick(l, en: "Mouse", pl: "Myszka", de: "Maus", es: "Ratón", fr: "Souris", it: "Mouse", uk: "Миша", ja: "マウス")
        case .mouseFill:
            return pick(l, en: "Mouse (filled)", pl: "Myszka (pełna)", de: "Maus (gefüllt)", es: "Ratón (relleno)", fr: "Souris (pleine)", it: "Mouse (pieno)", uk: "Миша (заповнена)", ja: "マウス（塗り）")
        case .trackpad:
            return pick(l, en: "Trackpad", pl: "Gładzik", de: "Trackpad", es: "Trackpad", fr: "Trackpad", it: "Trackpad", uk: "Трекпад", ja: "トラックパッド")
        case .headphones:
            return pick(l, en: "Headphones", pl: "Słuchawki", de: "Kopfhörer", es: "Auriculares", fr: "Casque", it: "Cuffie", uk: "Навушники", ja: "ヘッドフォン")
        case .airpods:
            return "AirPods"
        case .airpodsPro:
            return "AirPods Pro"
        case .airpodsMax:
            return "AirPods Max"
        case .earbuds:
            return pick(l, en: "Earbuds", pl: "Słuchawki dokanałowe", de: "In-Ear-Kopfhörer", es: "Auriculares intraurales", fr: "Écouteurs", it: "Auricolari", uk: "Вкладиші", ja: "イヤホン")
        case .speaker:
            return pick(l, en: "Speaker", pl: "Głośnik", de: "Lautsprecher", es: "Altavoz", fr: "Enceinte", it: "Altoparlante", uk: "Колонка", ja: "スピーカー")
        case .gamepad:
            return pick(l, en: "Controller", pl: "Kontroler", de: "Controller", es: "Mando", fr: "Manette", it: "Controller", uk: "Геймпад", ja: "コントローラー")
        case .pencil:
            return pick(l, en: "Stylus / Pencil", pl: "Rysik", de: "Stift", es: "Lápiz", fr: "Stylet", it: "Stilo", uk: "Стилус", ja: "スタイラス")
        case .watch:
            return pick(l, en: "Watch", pl: "Zegarek", de: "Uhr", es: "Reloj", fr: "Montre", it: "Orologio", uk: "Годинник", ja: "ウォッチ")
        case .phone:
            return pick(l, en: "Phone", pl: "Telefon", de: "Telefon", es: "Teléfono", fr: "Téléphone", it: "Telefono", uk: "Телефон", ja: "スマートフォン")
        case .tablet:
            return pick(l, en: "Tablet", pl: "Tablet", de: "Tablet", es: "Tableta", fr: "Tablette", it: "Tablet", uk: "Планшет", ja: "タブレット")
        case .generic:
            return "Bluetooth"
        }
    }

    // MARK: Earbuds L / R / Case Abbreviations

    static func leftShort(_ l: AppLanguage) -> String {
        switch l.resolved {
        case .pl: return "L"
        case .es, .it: return "I"
        case .fr: return "G"
        case .uk: return "Л"
        case .ja: return "左"
        default: return "L"
        }
    }

    static func rightShort(_ l: AppLanguage) -> String {
        switch l.resolved {
        case .pl: return "P"
        case .es, .fr, .it: return "D"
        case .uk: return "П"
        case .ja: return "右"
        default: return "R"
        }
    }

    static func caseShort(_ l: AppLanguage) -> String {
        switch l.resolved {
        case .pl: return "E"
        case .uk: return "К"
        case .ja: return "ケース"
        default: return "C"
        }
    }
}
