--[[
    EZRAGOX HUB  •  Türk Troll Scripti  •  v6.6 (Hasan Usta Özel Sürüm)
]]

-- Çakışma önleyici: Önceki çalışan sürümü tamamen temizle
if getgenv then
    if getgenv().EZRAGOX_HUB_CLEANUP then
        pcall(getgenv().EZRAGOX_HUB_CLEANUP)
    end
end

local Players = game:GetService("Players")

while not Players.LocalPlayer do
    task.wait(0.1)
end

local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Stats = game:GetService("Stats")
local GuiService = game:GetService("GuiService")
local HttpService = game:GetService("HttpService")

local DISCORD_URL = "https://discord.gg/gDdP7h5NS"

-- Discord bağlantısı yalnızca ana sayfadaki Premium çağrısına tıklanınca açılır.

local Camera = workspace.CurrentCamera or workspace:FindFirstChildOfClass("Camera")
local GUI_NAME = "EZRAGOX_HUB"

local alive = true
local conns = {}
local function bind(signal, fn)
    local c = signal:Connect(fn)
    conns[#conns + 1] = c
    return c
end

---------------------------------------------------------
-- 0. TEMİZLİK + OTOMATİK KAYIT (CONFIG) SİSTEMİ
---------------------------------------------------------
local function cleanOld(container)
    if not container then return end
    pcall(function()
        for _, n in ipairs({"EZRAGOX_TrollHub", GUI_NAME}) do
            local old = container:FindFirstChild(n)
            if old then old:Destroy() end
        end
    end)
end
cleanOld(CoreGui)
cleanOld(LocalPlayer:FindFirstChildOfClass("PlayerGui"))
if gethui then pcall(function() cleanOld(gethui()) end) end
for _, n in ipairs({"EZRAGOX_Blur", "EZRAGOX_CC"}) do
    local o = Lighting:FindFirstChild(n)
    if o then o:Destroy() end
end

local CONFIG_FILE = "ezragox_hub_config.json"
local Settings = {
    Blur = true,
    Sound = true,
    Scale = 1,
    ToggleKey = Enum.KeyCode.G,
    SpeedVal = 48,
    FlyKey = Enum.KeyCode.F,
    FlySpeed = 50,
    Language = "TR",
    ToggleStates = {},
    SliderValues = {}
}

local function saveConfig()
    pcall(function()
        if writefile then
            local data = {
                Blur = Settings.Blur,
                Sound = Settings.Sound,
                Scale = Settings.Scale,
                ToggleKey = Settings.ToggleKey.Name,
                SpeedVal = Settings.SpeedVal,
                FlyKey = Settings.FlyKey.Name,
                FlySpeed = Settings.FlySpeed,
                Language = Settings.Language,
                ToggleStates = Settings.ToggleStates,
                SliderValues = Settings.SliderValues
            }
            writefile(CONFIG_FILE, HttpService:JSONEncode(data))
        end
    end)
end

local function loadConfig()
    pcall(function()
        if readfile and isfile and isfile(CONFIG_FILE) then
            local data = HttpService:JSONDecode(readfile(CONFIG_FILE))
            if data then
                if data.Blur ~= nil then Settings.Blur = data.Blur end
                if data.Sound ~= nil then Settings.Sound = data.Sound end
                if data.Scale ~= nil then Settings.Scale = data.Scale end
                if data.ToggleKey and Enum.KeyCode[data.ToggleKey] then Settings.ToggleKey = Enum.KeyCode[data.ToggleKey] end
                if data.SpeedVal ~= nil then Settings.SpeedVal = data.SpeedVal end
                if data.FlyKey and Enum.KeyCode[data.FlyKey] then Settings.FlyKey = Enum.KeyCode[data.FlyKey] end
                if data.FlySpeed ~= nil then Settings.FlySpeed = data.FlySpeed end
                if data.Language == "EN" or data.Language == "TR" then Settings.Language = data.Language end
                if type(data.ToggleStates) == "table" then Settings.ToggleStates = data.ToggleStates end
                if type(data.SliderValues) == "table" then Settings.SliderValues = data.SliderValues end
            end
        end
    end)
end
loadConfig()

local listeningForKey = false
local updateKeyTextCallback = nil
local listeningFlyKey = false
local updateFlyKeyTextCallback = nil

-- Dil sistemi: arayüz metinlerini kayıt altında tutar ve seçim değişince yeniler.
local UI_TEXT_OBJECTS = {}
local EN_TEXT = {
    ["Ana Sayfa"]="Home", ["Özellikler"]="Features", ["Troll"]="Troll",
    ["Premium"]="Premium", ["Ayarlar"]="Settings", ["Yönetim"]="Admin",
    ["KONTROL"]="CONTROLS", ["GÖRÜNÜM"]="APPEARANCE", ["SES"]="SOUND", ["DİĞER"]="OTHER",
    ["Menü Tuşu"]="Menu Key", ["Bulanık arka plan"]="Blurred Background",
    ["Menü boyutu"]="Menu Size", ["Ses efektleri"]="Sound Effects",
    ["Menüyü küçült"]="Minimize Menu", ["Arayüzü tamamen kapat"]="Close Interface",
    ["Dil"]="Language", ["Türkçe"]="Turkish", ["İngilizce"]="English",
    ["Tuşa basın..."]="Press a key...", ["menüyü aç / kapat"]="toggle menu",
    ["KARAKTER ÖZELLİKLERİ"]="CHARACTER FEATURES",
    ["👻  Hayalet Modu (Görünmezlik)"]="👻  Ghost Mode (Invisibility)",
    ["🏃‍♂️  Süper Hız Aktif Et"]="🏃‍♂️  Enable Super Speed",
    ["⚡  Süper Hız Değeri"]="⚡  Super Speed Value",
    ["🚀  Süper Zıplama Gücü"]="🚀  Super Jump Power",
    ["🦘  Sınırsız Zıplama (Infinite Jump)"]="🦘  Infinite Jump",
    ["UÇUŞ MODU (FLY)"]="FLIGHT MODE (FLY)",
    ["🛸  Fly (Uçma) Modu"]="🛸  Fly Mode",
    ["Fly Açma/Kapatma Tuşu"]="Fly Toggle Key", ["🚀  Fly Hızı"]="🚀  Fly Speed",
    ["PERFORMANS VE FPS MODLARI"]="PERFORMANCE AND FPS MODES",
    ["📈  FPS Modu (Optimizasyon)"]="📈  FPS Mode (Optimization)",
    ["⚡  Ultra FPS Modu (Maksimum Performans)"]="⚡  Ultra FPS Mode (Maximum Performance)",
    ["ESP (DUVAR ARKASI GÖRÜŞ)"]="ESP (WALL VISION)",
    ["👁️  ESP (Yeşil Çerçeve + Renkli İsim)"]="👁️  ESP (Green Outline + Colored Name)",
    ["HEDEF OYUNCU SEÇİMİ VE ARAMA"]="TARGET PLAYER SELECTION AND SEARCH",
    ["Oyuncu Ara / Seç"]="Find / Select Player",
    ["AKTİF TROLL ÖZELLİKLERİ (14 ADET)"]="ACTIVE TROLL FEATURES (14)",
    ["🔗  1. Seçilen Kişiye Yapış"]="🔗  1. Attach to Selected Player",
    ["📎  1b. Oyuncuyu Kendine Yapıştır"]="📎  1b. Attach Player to You",
    ["🌀  2. Oyuncuyu Döndür (Gerçek Fling)"]="🌀  2. Spin Player (Fling)",
    ["💥  3. Oyuncuya Patlama Efekti"]="💥  3. Explosion Effect on Player",
    ["🎈  4. Oyuncuyu Havaya Uçur (Sky Teleport)"]="🎈  4. Launch Player into Sky",
    ["☄️  5. Kafasına Taş/Blok Düşür"]="☄️  5. Drop Rock/Block on Player",
    ["📌  6. Oyuncuyu Olduğu Yere Sabitle"]="📌  6. Freeze Player in Place",
    ["💃  7. Oyuncuyu Sars / Sallantı Ver"]="💃  7. Shake Player",
    ["🕶️  8. Hedefin Bilgilerini Al"]="🕶️  8. Get Target Information",
    ["🔄  9. Kamera Efekti (FOV Trolling)"]="🔄  9. Camera Effect (FOV Troll)",
    ["💨  10. Sunucudaki Herkesi Zıplat"]="💨  10. Make Everyone Jump",
    ["👁️  11. Seçilen Oyuncuyu İzle"]="👁️  11. Spectate Selected Player",
    ["🚀  12. Seçilen Oyuncunun Yanına Işınlan"]="🚀  12. Teleport to Selected Player",
    ["🎣  13. Seçilen Oyuncuyu Yanıma Çek"]="🎣  13. Pull Selected Player to Me",
    ["🚀  14. Uzaya Fırlat (Maksimum Güç)"]="🚀  14. Launch into Space (Max Power)",
    ["PREMİUM KİLİDİ"]="PREMIUM LOCKED",
    ["🔄  Premium Durumunu Yenile"]="🔄  Refresh Premium Status",
    ["🔑  Premium İste  (Discord Sunucusu)"]="🔑  Request Premium (Discord)",
    ["PREMİUM DURUMU"]="PREMIUM STATUS",
    ["👑  PREMİUM HAREKET"]="👑  PREMIUM MOVEMENT",
    ["👑  PREMİUM GÖRÜNÜM"]="👑  PREMIUM APPEARANCE",
    ["👑  PREMİUM KIYAFET DEĞİŞTİRİCİ"]="👑  PREMIUM OUTFIT CHANGER",
    ["👑  PREMİUM OTO TOPLAYICI"]="👑  PREMIUM AUTO COLLECTOR",
    ["👑  PREMİUM ARAÇLAR"]="👑  PREMIUM TOOLS",
    ["PREMİUM YÖNETİMİ"]="PREMIUM MANAGEMENT",
    ["✅  Premium Ver"]="✅  Grant Premium", ["❌  Premium Kaldır"]="❌  Remove Premium",
    ["📜  Premium Listesini Yükle"]="📜  Load Premium List",
    ["VERİTABANI GİZLİ ANAHTARI  (sadece bu cihazda saklanır)"]="DATABASE SECRET KEY (stored on this device)",
    ["💾  Gizli Anahtarı Kaydet"]="💾  Save Secret Key",
    ["🔒  Yönetimi Kilitle ve Gizle"]="🔒  Lock and Hide Admin",
    ["PREMİUM OLAN HESAPLAR  (tıkla = kaldır)"]="PREMIUM ACCOUNTS (click to remove)",
    ["Menü Tuşu Değiştirildi"]="Menu Key Changed",
    ["Fly Tuşu Değiştirildi"]="Fly Key Changed",
    ["Tuş Bekleniyor"]="Waiting for Key",
    ["Yeni kısayol: "]="New shortcut: ",
    ["Yeni Fly tuşu: "]="New Fly key: ",
    ["Fly Aktif"]="Fly Enabled", ["Uçuş modu açıldı! Tuş: "]="Flight mode enabled! Key: ",
    ["Fly Kapandı"]="Fly Disabled", ["Uçuş modu kapatıldı."]="Flight mode disabled.",
    ["ESP Aktif"]="ESP Enabled", ["ESP Kapandı"]="ESP Disabled",
    ["Oyuncu Seçilmedi"]="No Player Selected",
    ["Önce bir Roblox kullanıcı adı yaz."]="Enter a Roblox username first.",
    ["Kopyalandı"]="Copied", ["Kopyalanamadı"]="Copy Failed",
    ["Premium Gerekli"]="Premium Required", ["Hata"]="Error",
    ["Bekle"]="Please Wait", ["Boş"]="Empty", ["Giriş"]="Login", ["İptal"]="Cancel",
    ["Yapımcı:"]="Creator:", ["Hesap yaşı: "]="Account age: ",
    ["EZRAGOX HUB'a hoş geldin!"]="Welcome to EZRAGOX HUB!",
    ["Menüyü G tuşuyla açıp kapatabilirsin. Yapımcı: Hasan Usta"]="Press G to open or close the menu. Creator: Hasan Usta",
    ["PREMIUM ALMAK İÇİN TIKLA  ›"]="CLICK HERE TO GET PREMIUM  ›",
    ["Davet bağlantısı panoya kopyalandı."]="Invite link copied to clipboard.",
    ["Bağlantı:"]="Link:",
    ["Açılıyor... Açılmazsa bağlantı panoya kopyalandı."]="Opening... If it does not open, the link was copied to the clipboard.",
    ["Açık!"]="Enabled!",
    ["Aktif!"]="Active!",
    ["Uygulandı!"]="Applied!",
    ["Görünüm Kuşanıldı 👕"]="Appearance Equipped 👕",
    ["Kuşanılamadı"]="Could Not Equip",
    ["Oto Toplayıcı"]="Auto Collector",
    ["Oto Toplayıcı Kapandı"]="Auto Collector Disabled",
    ["Tarama Bitti"]="Scan Complete",
    ["Para Bulunamadı"]="No Currency Found",
    ["Liste Alınamadı"]="Could Not Load List",
    ["Liste Boş"]="List Is Empty",
    ["Liste Yüklendi"]="List Loaded",
    ["Bağlantı Hatası"]="Connection Error",
    ["Gizli Anahtar Yok"]="Missing Secret Key",
    ["Veritabanı Yok"]="Database Unavailable",
    ["Işınlandın"]="Teleported",
    ["İzleme Aktif"]="Spectating",
    ["İzleme Kapandı"]="Spectating Stopped",
    ["Hedef Bilgisi"]="Target Information",
    ["Kamera Troll"]="Camera Troll",
    ["Toplu Zıplama"]="Mass Jump",
    ["Yanına Çekildi"]="Pulled to You",
    ["Kısmen Çekildi"]="Partially Pulled",
    ["Çekilemedi"]="Could Not Pull",
    ["Sallantı Bitti"]="Shaking Finished",
    ["Blok Düştü"]="Block Dropped",
    ["Sabitlendi"]="Frozen",
    ["Patlama"]="Explosion",
    ["Tıkla-Işınlan"]="Click Teleport",
    ["Gökkuşağı Aura"]="Rainbow Aura",
    ["Uzaklaşma sınırı kaldırıldı."]="Zoom limit removed.",
}
local EN_REPLACEMENTS = {
    ["TÜRK TROLL SCRİPTİ"] = "TURKISH TROLL SCRIPT",
    ["BAĞLANDI"] = "CONNECTED",
    ["KULLANICI DOĞRULANDI"] = "USER VERIFIED",
    ["Hazır!"] = "Ready!",
    ["Yapımcı"] = "Creator",
    ["Hoş geldin"] = "Welcome",
    ["hoş geldin"] = "welcome",
    ["Hesap yaşı"] = "Account age",
    ["gün"] = "days",
    ["İsim yaz (örn: hasan)"] = "Enter a name (e.g. Alex)",
    ["Eşleşen oyuncu yok"] = "No matching players",
    ["Server İçinde"] = "In This Server",
    ["Genel Kullanıcı"] = "Global User",
    ["İsmin başını yaz, liste süzülür"] = "Type the start of a name to filter the list",
    ["Roblox kullanıcı adı yaz"] = "Enter a Roblox username",
    ["Şifre"] = "Password",
    ["Devam etmek için yönetim şifresini gir."] = "Enter the admin password to continue.",
    ["YÖNETİM GİRİŞİ"] = "ADMIN LOGIN",
    ["Yönetici erişimi ile açık."] = "Open with administrator access.",
    ["premium tanımlı."] = "premium is enabled.",
    ["Kaydedildi"] = "Saved",
    ["Kaydedilemedi"] = "Could Not Save",
    ["Yönetim Kilitlendi"] = "Admin Locked",
    ["Sekme gizlendi."] = "The tab has been hidden.",
    ["Yönetim Açıldı"] = "Admin Unlocked",
    ["Erişim Engellendi"] = "Access Denied",
    ["Şifre Hatalı"] = "Incorrect Password",
    ["Biraz Bekle"] = "Please Wait",
    ["Çok fazla hatalı deneme. Bir süre sonra tekrar dene."] = "Too many incorrect attempts. Try again later.",
    ["3 hatalı deneme. 30 saniye bekle."] = "3 incorrect attempts. Wait 30 seconds.",
    ["Tekrar dene."] = "Try again.",
    ["Dil Türkçe olarak değiştirildi."] = "Language changed to Turkish.",
    ["DİL / LANGUAGE"] = "LANGUAGE",
    ["Dil / Language"] = "Language",
    ["Türkçe"] = "Turkish",
    ["Uygula"] = "Apply",
    ["Seçilen Oyuncuyu Kopyala"] = "Copy Selected Player",
    ["Karakteri Komple Kopyala"] = "Copy Entire Character",
    ["Saç"] = "Hair",
    ["Üst"] = "Top",
    ["Alt"] = "Bottom",
    ["Aksesuar"] = "Accessories",
    ["Önce bir Roblox kullanıcı adı yaz."] = "Enter a Roblox username first.",
    ["Listeden bir oyuncu seç (ya da adını yaz)."] = "Select a player from the list (or enter their name).",
    ["Bu adda bir Roblox hesabı yok: "] = "No Roblox account exists with this name: ",
    ["Kullanıcı Adı Boş"] = "Username Is Empty",
    ["Kullanıcı Bulunamadı"] = "User Not Found",
    ["Oyuncu Seçilmedi"] = "No Player Selected",
    ["Hedef Seçildi"] = "Target Selected",
    ["Hedef Bilgisi"] = "Target Information",
    ["Hesap"] = "Account",
    ["Durum"] = "Status",
    ["Lütfen önce yukarıdan hedef oyuncu seçin!"] = "Select a target player above first!",
    ["Lütfen önce bir hedef oyuncu seçin!"] = "Select a target player first!",
    ["Hedefin karakteri şu an yok veya ölü."] = "The target's character is missing or dead.",
    ["Önceki işlem hâlâ sürüyor."] = "The previous action is still running.",
    ["Kendi karakterin hazır değil."] = "Your character is not ready.",
    ["Oyuncudan ayrıldınız."] = "You detached from the player.",
    ["Oyuncu serbest bırakıldı."] = "The player has been released.",
    ["Efekt yalnızca senin ekranında görünür."] = "The effect is visible only on your screen.",
    ["Blok yalnızca senin ekranında görünür."] = "The block is visible only on your screen.",
    ["Kamera efektleri uygulandı!"] = "Camera effects applied!",
    ["Sunucudaki herkes zıplatıldı!"] = "Everyone in the server was made to jump!",
    ["Hedef oyuncu oyundan ayrıldı."] = "The target player left the game.",
    ["Kamera kendi karakterine döndü."] = "The camera returned to your character.",
    ["Açılıyor... Açılmazsa bağlantı panoya kopyalandı."] = "Opening... If it does not open, the link was copied to your clipboard.",
    ["Önce geçerli bir anahtar gir."] = "Enter a valid key first.",
    ["Aktif! Duvarların içinden geçebilirsin."] = "Enabled! You can move through walls.",
    ["Ctrl basılıyken bir yere sol tıkla."] = "Hold Ctrl and left-click somewhere.",
    ["Karakterin dönmeye başladı!"] = "Your character has started spinning!",
    ["Normal değere döndü."] = "Returned to the normal value.",
    ["Her yer aydınlandı!"] = "Everything is now illuminated!",
    ["Karakterin renk değiştiriyor!"] = "Your character is changing colors!",
    ["Uzaklaşma sınırı kaldırıldı."] = "The zoom-out limit has been removed.",
    ["görünümü uygulandı."] = " outfit applied.",
    ["bilinmiyor"] = "unknown",
    ["Aktif edildi!"] = "Enabled!",
    ["Kapatıldı."] = "Disabled.",
    ["Görünmez oldun!"] = "You are now invisible!",
    ["Görünür hale geldin."] = "You are visible again.",
    ["Hızın artırıldı!"] = "Your speed has been increased!",
    ["Normale döndü."] = "Returned to normal.",
    ["Zıplama gücü artırıldı!"] = "Your jump power has been increased!",
    ["Uçuş modu açıldı! Tuş: "] = "Flight mode enabled! Key: ",
    ["Uçuş modu kapatıldı."] = "Flight mode disabled.",
    ["FPS Optimizasyonu aktif! Gölgeler ve efektler kapatıldı."] = "FPS optimization enabled! Shadows and effects disabled.",
    ["Normal ayarlara dönüldü."] = "Normal settings restored.",
    ["Ultra FPS Modu aktif! Donanım yükü minimuma indirildi."] = "Ultra FPS mode enabled! Hardware load reduced to a minimum.",
    ["Ultra mod kapatıldı."] = "Ultra mode disabled.",
    ["Oyuncular duvar arkasından yeşil renkte görünüyor!"] = "Players are now visible in green through walls!",
    ["Oyuncu işaretleri kaldırıldı."] = "Player markers removed.",
    ["Sunucu ID panoya kopyalandı."] = "Server ID copied to clipboard.",
    ["Oyun ID panoya kopyalandı."] = "Game ID copied to clipboard.",
    ["Executor panoya yazmayı desteklemiyor."] = "The executor does not support copying to the clipboard.",
    ["Aynı sunucuya yeniden bağlanılıyor..."] = "Reconnecting to the same server...",
    ["Aktif! Boşta kalsan da atılmazsın."] = "Enabled! You will not be kicked for being idle.",
    ["En yakın paradan başlayıp tek tek toplanacak."] = "Collecting one by one, starting with the nearest item.",
    ["Şu an eşleşen yok. Yeni spawn olanlar otomatik alınır. İstersen 'Özel İsim' yaz."] = "No matches right now. Newly spawned items will be collected automatically. You can enter a custom name.",
    [" parça toplandı."] = " items collected.",
    ["Hiç bulunamadı. 'Özel İsim' kutusuna paranın adını yaz (örn: Coin)."] = "Nothing found. Enter the item name in the 'Custom Name' box (e.g. Coin).",
    ["Önce veritabanı gizli anahtarını kaydet."] = "Save the database secret key first.",
    ["Veritabanı adresini kontrol et."] = "Check the database URL.",
    ["Henüz premium verilen hesap yok."] = "No accounts have been granted premium yet.",
    [" hesap bulundu."] = " accounts found.",
    ["Gizli anahtarı yapıştır."] = "Paste the secret key.",
    ["Gizli anahtar bu cihaza kaydedildi."] = "The secret key was saved on this device.",
    ["Executor dosya yazmayı desteklemiyor."] = "The executor does not support file writing.",
    ["Premium sunucusuna ulaşılamadı. Tekrar dene."] = "Could not reach the premium server. Try again.",
    ["Hesabın için premium tanımlı, hoş geldin!"] = "Premium is enabled for your account. Welcome!",
    [" hesabında premium tanımlı değil."] = " does not have premium enabled.",
    ["Veritabanına yazılamadı. Adres ve gizli anahtarı kontrol et."] = "Could not write to the database. Check the URL and secret key.",
    ["Listeden elle sil: PREMIUM_NAMES."] = "Remove it manually from the list: PREMIUM_NAMES.",
    ["Satır panoya kopyalandı: dosyadaki PREMIUM_NAMES listesine ekle."] = "The line was copied to the clipboard: add it to the PREMIUM_NAMES list in the file.",
    ["Veritabanından silinemedi."] = "Could not delete from the database.",
    ["Menü için yeni bir klavye tuşuna basın..."] = "Press a new key for the menu...",
    ["Menüyü küçült"] = "Minimize Menu",
    ["Arayüzü tamamen kapat"] = "Close Interface",
    ["İsim"] = "Name",
    ["Ara"] = "Search",
    ["Seç"] = "Select",
    ["Oyuncu"] = "Player",
    ["Aktif"] = "Enabled",
    ["Hedef"] = "Target",
    ["Kullanıcı"] = "User",
    ["Bağlantı Hatası"] = "Connection Error",
    ["Premium Yok"] = "No Premium",
    ["Premium Aktif"] = "Premium Enabled",
    ["Premium Gerekli"] = "Premium Required",
    ["Liste Yüklendi"] = "List Loaded",
    ["Liste Boş"] = "List Is Empty",
    ["Liste Alınamadı"] = "Could Not Load List",
    ["Tarama Bitti"] = "Scan Complete",
    ["Para Bulunamadı"] = "Item Not Found",
    ["Oto Toplayıcı"] = "Auto Collector",
    ["Oto Toplayıcı Kapandı"] = "Auto Collector Disabled",
    ["Anti-AFK"] = "Anti-AFK",
    ["Tıkla-Işınlan"] = "Click to Teleport",
    ["Yerçekimi"] = "Gravity",
    ["Gökkuşağı Aura"] = "Rainbow Aura",
    ["Görünüm Kuşanıldı"] = "Outfit Equipped",
    ["Kuşanılamadı"] = "Could Not Equip",
    ["Veritabanı Yok"] = "Database Unavailable",
    ["Gizli Anahtar Yok"] = "Secret Key Missing",
    ["Premium Verildi"] = "Premium Granted",
    ["Premium Kaldırıldı"] = "Premium Removed",
    ["Yeni kısayol: "] = "New shortcut: ",
    ["Yeni Fly tuşu: "] = "New Fly key: ",
    ["menüyü aç / kapat"] = "toggle menu",
    ["Fling Başarılı"] = "Fling Successful",
    ["Fling Etkisiz"] = "Fling Ineffective",
    ["Havaya Uçuruldu"] = "Launched into the Air",
    ["Sky Etkisiz"] = "Sky Launch Ineffective",
    ["Uzaya Fırlatıldı"] = "Launched into Space",
    ["Etkisiz"] = "Ineffective",
    ["Yanına Çekildi"] = "Pulled to You",
    ["Kısmen Çekildi"] = "Partially Pulled",
    ["Çekilemedi"] = "Could Not Pull",
    ["Sallantı Bitti"] = "Shaking Finished",
    ["Patlama"] = "Explosion",
    ["Blok Düştü"] = "Block Dropped",
    ["Sabitlendi"] = "Frozen",
    ["Toplu Zıplama"] = "Mass Jump",
    ["İzleme Aktif"] = "Spectating Enabled",
    ["İzleme Kapandı"] = "Spectating Disabled",
    ["Işınlandın"] = "Teleported",
    ["Yapışma Aktif"] = "Attachment Enabled",
    ["Yapışma Kapandı"] = "Attachment Disabled",
    ["Yapıştırma Aktif"] = "Player Attachment Enabled",
    ["Yapıştırma Kapandı"] = "Player Attachment Disabled",
    ["Zaten Yakın"] = "Already Nearby",
    ["Fly Aktif"] = "Fly Enabled",
    ["Fly Kapandı"] = "Fly Disabled",
    ["ESP Aktif"] = "ESP Enabled",
    ["ESP Kapandı"] = "ESP Disabled",
    ["Menü Tuşu Değiştirildi"] = "Menu Key Changed",
    ["Fly Tuşu Değiştirildi"] = "Fly Key Changed",
    ["Tuş Bekleniyor"] = "Waiting for Key",
    ["Süper Hız"] = "Super Speed",
    ["Süper Zıplama"] = "Super Jump",
    ["Sınırsız Zıplama"] = "Infinite Jump",
    ["Hayalet Modu"] = "Ghost Mode",
    ["FPS Modu"] = "FPS Mode",
    ["Ultra FPS"] = "Ultra FPS",
    ["Hedef oyuncu"] = "Target player",
    ["Hedefin"] = "Target's",
    ["İzleniyor"] = "Being Spectated",
    ["Discord Sunucusu"] = "Discord Server",
    ["Yönetim şifresi"] = "Admin password",
    ["Menü Tuşu"] = "Menu Key",
    ["Bulanık arka plan"] = "Blurred Background",
    ["Menü boyutu"] = "Menu Size",
    ["Ses efektleri"] = "Sound Effects",
    ["Görünüm"] = "Appearance",
    ["Karakter"] = "Character",
    ["Özellikler"] = "Features",
    ["Ana Sayfa"] = "Home",
    ["Ayarlar"] = "Settings",
    ["Yönetim"] = "Admin",
    ["Premium Durumunu Yenile"] = "Refresh Premium Status",
    ["Premium İste"] = "Request Premium",
    ["Premium Ver"] = "Grant Premium",
    ["Premium Kaldır"] = "Remove Premium",
    ["Premium Listesini Yükle"] = "Load Premium List",
    ["Gizli Anahtarı Kaydet"] = "Save Secret Key",
    ["Yönetimi Kilitle ve Gizle"] = "Lock and Hide Admin",
    ["PREMİUM OLAN HESAPLAR"] = "PREMIUM ACCOUNTS",
    ["VERİTABANI GİZLİ ANAHTARI"] = "DATABASE SECRET KEY",
    ["Sadece bu cihazda saklanır"] = "Stored on this device only",
    ["Yapımcı:"] = "Creator:",
    ["KONTROL"] = "CONTROLS",
    ["DİĞER"] = "OTHER",
    ["👑  EZRAGOX PREMİUM"] = "👑  EZRAGOX PREMIUM",
    ["Noclip • Tıkla-Işınlan • Fullbright • Gökkuşağı Aura • Dönen Karakter • Yerçekimi • FOV • Zoom Kilidi • Gün Saati • Anti-AFK • Rejoin ve daha fazlası. Premium, Roblox hesabına özel tanımlanır."] = "Noclip • Click Teleport • Fullbright • Rainbow Aura • Spin Character • Gravity • FOV • Zoom Lock • Time of Day • Anti-AFK • Rejoin and more. Premium is assigned to your Roblox account.",
    ["👤  Hesabın: "] = "👤  Your Account: ",
    ["Bu hesapta premium tanımlı değil. Premium istemek için Discord sunucusuna gel."] = "Premium is not enabled for this account. Join the Discord server to request Premium.",
    ["PREMİUM AKTİF"] = "PREMIUM ACTIVE",
    ["Hesap: "] = "Account: ",
    ["  •  premium tanımlı."] = "  •  Premium enabled.",
    ["Yönetici erişimi ile açık."] = "Enabled with administrator access.",
    ["👻  Noclip (Duvarlardan Geç)"] = "👻  Noclip (Walk Through Walls)",
    ["🖱️  Tıkla-Işınlan  (Ctrl + Sol Tık)"] = "🖱️  Click Teleport (Ctrl + Left Click)",
    ["🌀  Dönen Karakter (Spin)"] = "🌀  Spin Character",
    ["🌪️  Dönme Hızı"] = "🌪️  Spin Speed",
    ["🪐  Yerçekimi"] = "🪐  Gravity",
    ["♻️  Yerçekimini Normale Döndür"] = "♻️  Reset Gravity",
    ["💡  Fullbright (Her Yer Aydınlık)"] = "💡  Fullbright (Brighten Everything)",
    ["🌈  Gökkuşağı Aura"] = "🌈  Rainbow Aura",
    ["🔭  Görüş Açısı (FOV)"] = "🔭  Field of View (FOV)",
    ["🔍  Kamera Zoom Sınırını Kaldır"] = "🔍  Remove Camera Zoom Limit",
    ["🌙  Gün Saati"] = "🌙  Time of Day",
    ["👑  PREMİUM KIYAFET DEĞİŞTİRİCİ"] = "👑  PREMIUM OUTFIT CHANGER",
    ["🌍  Genel Kullanıcı"] = "🌍  Global User",
    ["🖥️  Server İçinde"] = "🖥️  In This Server",
    ["Genel Kullanıcı"] = "Global User",
    ["Roblox kullanıcı adı yaz"] = "Enter Roblox username",
    ["👑  PREMİUM OTO TOPLAYICI"] = "👑  PREMIUM AUTO COLLECTOR",
    ["Özel İsim"] = "Custom Name",
    ["örn: Coin, Gold  (boş = otomatik bul)"] = "e.g. Coin, Gold (blank = auto-detect)",
    ["👑  PREMİUM ARAÇLAR"] = "👑  PREMIUM TOOLS",
    ["👑  PREMİUM HAREKET"] = "👑  PREMIUM MOVEMENT",
    ["👑  PREMİUM GÖRÜNÜM"] = "👑  PREMIUM APPEARANCE",
    ["PREMİUM KİLİDİ"] = "PREMIUM LOCK",
    ["PREMİUM DURUMU"] = "PREMIUM STATUS",
    ["PREMİUM YÖNETİMİ"] = "PREMIUM MANAGEMENT",
    ["PREMİUM OLAN HESAPLAR  (tıkla = kaldır)"] = "PREMIUM ACCOUNTS (click to remove)",
    ["🛡️  Sadece sana özel"] = "🛡️  Admin Only",
    ["Premium vermek istediğin kişinin Roblox kullanıcı adını yaz. Premium o hesaba tanımlanır; kişi menüyü açınca kendi hesabıyla otomatik premium olur."] = "Enter the Roblox username of the person you want to grant Premium to. Premium will be assigned to that account and activated automatically when they open the menu.",
    ["Kullanıcı"] = "User",
    ["Roblox kullanıcı adı (örn: hasanusta_03)"] = "Roblox username (e.g. player123)",
    ["Gizli Anahtar"] = "Secret Key",
    ["Firebase veritabanı gizli anahtarı"] = "Firebase database secret key",
    ["VERİTABANI GİZLİ ANAHTARI  (sadece bu cihazda saklanır)"] = "DATABASE SECRET KEY (stored on this device only)",
    ["Sadece bu cihazda saklanır"] = "Stored on this device only",
    ["👤  "] = "👤  ",
    ["Kendi Görünümüme Dön"] = "Return to My Outfit",
    ["Görünümünü Kuşan"] = "Equip Outfit",
    ["Oyuncuyu Ara"] = "Search Player",
    ["Oyuncu Bul"] = "Find Player",
    ["Kıyafet"] = "Outfit",
    ["Kıyafet Değiştirici"] = "Outfit Changer",
    ["Karakter Görünümü"] = "Character Appearance",
    ["Oyuncu Listesi"] = "Player List",
    ["Hız"] = "Speed",
    ["Gün Saati"] = "Time of Day",
    ["Yerçekimini Normale Döndür"] = "Reset Gravity",
    ["Aktif! Duvarların içinden geçebilirsin."] = "Enabled! You can walk through walls.",
    ["Ctrl basılıyken bir yere sol tıkla."] = "Hold Ctrl and left-click anywhere.",
    ["Karakterin dönmeye başladı!"] = "Your character has started spinning!",
    ["Her yer aydınlandı!"] = "Everything is now illuminated!",
    ["Karakterin renk değiştiriyor!"] = "Your character is changing colors!",
    ["Uzaklaşma sınırı kaldırıldı."] = "The zoom limit has been removed.",
    ["Normal değere döndü."] = "Returned to normal.",
    ["Bu hesapta premium tanımlı değil."] = "Premium is not enabled for this account.",
    ["Premium istemek için Discord sunucusuna gel."] = "Join the Discord server to request Premium.",
    ["Önce geçerli bir anahtar gir."] = "Enter a valid key first.",
    ["Hesabın için premium tanımlı, hoş geldin!"] = "Premium is enabled for your account. Welcome!",
    [" hesabında premium tanımlı değil."] = " does not have Premium enabled.",
    ["Premium sunucusuna ulaşılamadı. Tekrar dene."] = "Could not reach the Premium server. Try again.",
    ["Henüz premium verilen hesap yok."] = "No accounts have been granted Premium yet.",
    [" hesap bulundu."] = " accounts found.",
    ["Premium verildi"] = "Premium granted",
    ["Premium kaldırıldı"] = "Premium revoked",
    ["premiumu kaldır"] = "revoke Premium",
    ["panoya kopyalandı"] = "copied to clipboard",
    ["panoya kopyalandı."] = "copied to clipboard.",
    ["Önce"] = "First",
    ["önce"] = "first",
    ["Lütfen"] = "Please",
    ["seçin"] = "select",
    ["seçin."] = "select.",
    ["açıldı"] = "enabled",
    ["kapatıldı"] = "disabled",
    ["başladı"] = "started",
    ["bitti"] = "finished",
    ["bulundu"] = "found",
    ["bulunamadı"] = "not found",
    ["kaydedildi"] = "saved",
    ["kaydedilemedi"] = "could not be saved",
    ["kopyalandı"] = "copied",
    ["kopyalanamadı"] = "could not be copied",
    ["hesap bulundu"] = "accounts found",
    ["hesap bulundu."] = "accounts found.",
    ["tuşu ile"] = "with the key",
    ["tuşuna bas"] = "press the key",

}
local function trText(value)
    if type(value) ~= "string" or Settings.Language ~= "EN" then return value end
    if EN_TEXT[value] then return EN_TEXT[value] end
    local result = value
    local keys = {}
    for source in pairs(EN_REPLACEMENTS) do keys[#keys + 1] = source end
    table.sort(keys, function(a, b) return #a > #b end)
    for _, source in ipairs(keys) do
        if string.find(result, source, 1, true) then
            local pattern = source:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
            result = string.gsub(result, pattern, function() return EN_REPLACEMENTS[source] end)
        end
    end
    return result
end

local function setLocalizedProperty(obj, property, value)
    if not obj then return end
    local found = false
    for _, entry in ipairs(UI_TEXT_OBJECTS) do
        if entry.obj == obj and entry.property == property then
            entry.original = value
            found = true
            break
        end
    end
    if not found then
        UI_TEXT_OBJECTS[#UI_TEXT_OBJECTS + 1] = {obj = obj, original = value, property = property}
    end
    pcall(function() obj[property] = trText(value) end)
end

local function setText(obj, value)
    setLocalizedProperty(obj, "Text", value)
end

local function setPlaceholder(obj, value)
    setLocalizedProperty(obj, "PlaceholderText", value)
end

local function applyLanguage()
    for i = #UI_TEXT_OBJECTS, 1, -1 do
        local entry = UI_TEXT_OBJECTS[i]
        local obj = entry.obj
        if obj and obj.Parent then
            pcall(function()
                if entry.property == "PlaceholderText" then
                    obj.PlaceholderText = trText(entry.original)
                else
                    obj.Text = trText(entry.original)
                end
            end)
        else
            table.remove(UI_TEXT_OBJECTS, i)
        end
    end
end

local function new(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props) do
        if (k == "Text" or k == "PlaceholderText") and type(v) == "string" then
            UI_TEXT_OBJECTS[#UI_TEXT_OBJECTS + 1] = {obj = o, original = v, property = k}
            o[k] = trText(v)
        else
            o[k] = v
        end
    end
    if parent then o.Parent = parent end
    return o
end
local function corner(o, r)
    return new("UICorner", {CornerRadius = UDim.new(0, r)}, o)
end
local function pill(o)
    return new("UICorner", {CornerRadius = UDim.new(1, 0)}, o)
end
local function stroke(o, th, col, tr)
    return new("UIStroke", {Thickness = th, Color = col or Color3.new(1, 1, 1), Transparency = tr or 0}, o)
end
local function tween(obj, time, props, style, dir)
    local t = TweenService:Create(obj, TweenInfo.new(time, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
    t:Play()
    return t
end

local function playSound(pitch, volume)
    if not Settings.Sound then return end
    pcall(function()
        local s = Instance.new("Sound")
        s.SoundId = "rbxassetid://4590657391"
        s.Volume = volume or 1
        s.Pitch = pitch or 1.2
        s.Parent = SoundService
        s:Play()
        task.delay(1.5, function() s:Destroy() end)
    end)
end
local function playClickSound() playSound(1.18, 0.42) end

local PALETTE = {
    Color3.fromRGB(255, 28, 48),
    Color3.fromRGB(150, 8, 24),
    Color3.fromRGB(255, 72, 38),
    Color3.fromRGB(70, 5, 14),
}
local function palette(x)
    local n = #PALETTE
    x = x % n
    local i = math.floor(x)
    local f = x - i
    f = f * f * (3 - 2 * f)
    return PALETTE[i + 1]:Lerp(PALETTE[(i + 1) % n + 1], f)
end
local function accentAt(off)
    return palette(os.clock() * 0.7 + (off or 0))
end

local function flowSeq(phase, step)
    local t = os.clock() * 0.7 + (phase or 0)
    step = step or 0.5
    local pts = {}
    for k = 0, 4 do
        pts[k + 1] = ColorSequenceKeypoint.new(k / 4, palette(t - k * step))
    end
    return ColorSequence.new(pts)
end

local UIFlows, UIAccents, Pulsers, Shines = {}, {}, {}, {}
local IntroFlows, IntroAccents = {}, {}
local function regFlow(list, grad, phase, step, spin)
    list[#list + 1] = {grad = grad, phase = phase or 0, step = step or 0.5, spin = spin}
    grad.Color = flowSeq(phase, step)
end
local function track(list, obj, prop, off)
    list[#list + 1] = {obj = obj, prop = prop, off = off or 0}
end

local function typeText(lbl, txt, delay)
    setText(lbl, txt)
    lbl.MaxVisibleGraphemes = 0
    local n = utf8.len(txt) or #txt
    for i = 1, n do
        lbl.MaxVisibleGraphemes = i
        task.wait(delay)
    end
    lbl.MaxVisibleGraphemes = -1
end

local function getScale(baseW, baseH, lo)
    local cam = workspace.CurrentCamera or workspace:FindFirstChildOfClass("Camera")
    if not cam then return 1 end
    local vp = cam.ViewportSize
    if vp.X <= 0 or vp.Y <= 0 then return 1 end
    return math.clamp(math.min(vp.Y / baseH, vp.X / baseW), lo or 0.5, 1)
end

local function makeShine(parent, z)
    local shine = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(-0.6, 0, 0.5, 0),
        Size = UDim2.new(0.35, 0, 2, 0),
        Rotation = 20,
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 0.45,
        BorderSizePixel = 0,
        ZIndex = z,
    }, parent)
    new("UIGradient", {Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.5, 0),
        NumberSequenceKeypoint.new(1, 1),
    })}, shine)
    return shine
end
local function playShine(shine, dur)
    shine.Position = UDim2.new(-0.6, 0, 0.5, 0)
    tween(shine, dur or 0.7, {Position = UDim2.new(1.6, 0, 0.5, 0)}, Enum.EasingStyle.Quad)
end

local blurEffect = new("BlurEffect", {Name = "EZRAGOX_Blur", Size = 0, Enabled = true}, Lighting)
local cc = new("ColorCorrectionEffect", {Name = "EZRAGOX_CC", Saturation = -1, Contrast = 0.15, Brightness = 0}, Lighting)

local ScreenGui = new("ScreenGui", {
    Name = GUI_NAME,
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 999,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})
do
    local ok = pcall(function()
        if gethui then
            ScreenGui.Parent = gethui()
        else
            ScreenGui.Parent = CoreGui
        end
    end)
    if not ok or not ScreenGui.Parent then
        ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
end

---------------------------------------------------------
-- 1. SİNEMATİK GİRİŞ  (v4)
-- Not: Tüm giriş kodu kendi fonksiyonunun içinde çalışır. Böylece ana bölümdeki
-- "local" sayısı 200 sınırının altında kalır ve ek değişken gerekmez.
---------------------------------------------------------
local Intro = (function()
    local I = {}
    local introAlive = true

    -- Tween ile akıcı değişen değerler (vinyet, aura, blur)
    local K = {
        vig = new("NumberValue", {Value = 0}),
        aura = new("NumberValue", {Value = 0}),
        blur = new("NumberValue", {Value = 0}),
    }

    ---------------------------------------------------------
    -- SES MOTORU v4: tatlı mini click'ler + parlak doğrulama sesi
    -- İki ayrı kanal vardır, birbirini bozmaz:
    --   1) CLICK kanalı  (SND.click): minicik, kuru, ~70 ms'lik tıklar. Boot satırları, harfler,
    --      yükleme ilerlemesi, kart vb. Perde yukarı doğru tırmanır, hızı sınırlıdır (karmaşa yok).
    --   2) SES kanalı    (SND.play): tek seferde bir "büyük" ses (açılış dalgası, vuruş, çanlar,
    --      doğrulama jingle'ı). Yeni ses başlarken öncekini yumuşakça kısar.
    -- Final: "ERİŞİM ONAYLANDI" anında üç notalık yükselen DOĞRULAMA sesi çalar (tık + ding-ding-DING).
    --
    -- Genel seviye: SND.master  (0.5 = yarı ses, 1.5 = daha yüksek)
    ---------------------------------------------------------
    local SFX_ID = "rbxassetid://4590657391"
    local SFX_EXTRA = {
        ping = "rbxasset://sounds/electronicpingshort.wav",
        slash = "rbxasset://sounds/swordslash.wav",
    }
    local SND = {
        master = 1,
        has = {ping = true, slash = true},
        root = 0.6,
        voices = {},
        token = 0,
        lastClick = 0,
    }

    local function sfx(o)
        if not Settings.Sound then return nil end
        local vol = (o.vol or 1) * SND.master
        local ok, snd = pcall(function()
            local s = Instance.new("Sound")
            s.SoundId = o.id or SFX_ID
            s.Volume = o.att and 0 or vol
            s.PlaybackSpeed = o.speed or 1
            if o.low or o.mid or o.high then
                local e = Instance.new("EqualizerSoundEffect")
                e.LowGain = o.low or 0
                e.MidGain = o.mid or 0
                e.HighGain = o.high or 0
                e.Parent = s
            end
            if o.reverb then
                local r = Instance.new("ReverbSoundEffect")
                r.DecayTime = o.reverb
                r.Density = 1
                r.Diffusion = 1
                r.DryLevel = -2
                r.WetLevel = o.wet or -6
                r.Parent = s
            end
            s.Parent = SoundService
            s:Play()
            return s
        end)
        if not ok or not snd then return nil end

        -- Zarf: yavaş giriş (att), tepede bekleme (hold), yumuşak çıkış (rel)
        if o.att then
            pcall(function() tween(snd, o.att, {Volume = vol}, Enum.EasingStyle.Sine) end)
        end
        if o.sweep then
            pcall(function()
                tween(snd, o.dur or 1, {PlaybackSpeed = o.sweep}, Enum.EasingStyle.Quad)
            end)
        end
        local life = o.life or 3
        if o.rel then
            local hold = (o.att or 0) + (o.hold or 0)
            task.delay(hold, function()
                pcall(function()
                    tween(snd, o.rel, {Volume = 0}, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
                end)
            end)
            life = hold + o.rel + 0.2
        end
        task.delay(life, function()
            pcall(function() snd:Destroy() end)
        end)
        return snd
    end

    -- Yedek kliplerin gerçekten yüklenip yüklenmediğini arka planda denetle (yoksa ana asset'e düş)
    task.spawn(function()
        local cp = game:GetService("ContentProvider")
        local base = new("Sound", {SoundId = SFX_ID, Volume = 0}, SoundService)
        pcall(function() cp:PreloadAsync({base}) end)
        local probes = {}
        for k, id in pairs(SFX_EXTRA) do
            probes[k] = new("Sound", {SoundId = id, Volume = 0}, SoundService)
        end
        local t0 = os.clock()
        for k, p in pairs(probes) do
            while not p.IsLoaded and os.clock() - t0 < 1.5 do task.wait(0.05) end
            SND.has[k] = (p.IsLoaded and p.TimeLength > 0) and true or false
            p:Destroy()
        end
        base:Destroy()
    end)

    ---------------------------------------------------------
    -- CLICK KANALI: tatlı, kuru, minicik tık (perde = yükseklik, 1.5 yumuşak ... 3 cırtlak-tatlı)
    ---------------------------------------------------------
    function SND.click(pitch, vol)
        if not Settings.Sound then return end
        local now = os.clock()
        if now - SND.lastClick < 0.035 then return end -- arka arkaya sıkışmasın
        SND.lastClick = now
        sfx{speed = pitch or 2, vol = vol or 0.3, low = -12, mid = 0, high = 2, hold = 0.02, rel = 0.05}
    end
    -- "Hazır" anı: iki hızlı, yükselen tık
    function SND.ready()
        SND.click(2.3, 0.4)
        task.delay(0.08, function() SND.click(3.0, 0.4) end)
    end

    ---------------------------------------------------------
    -- SES KANALI: çanlar, hava dalgaları, doğrulama jingle'ı
    ---------------------------------------------------------
    local function bellOpts(n, vol)
        local has = SND.has.ping
        return {
            id = has and SFX_EXTRA.ping or nil,
            speed = SND.root * 2 ^ (n / 12) * (has and 1 or 1.5),
            vol = vol,
            low = -6, mid = 0, high = -3,
            reverb = 1.8, wet = -6,
            life = 3,
        }
    end
    local function bell(n, vol)
        return function() return {{0, bellOpts(n, vol)}} end
    end
    local function air(vol, from, to, dur, att, hold, rel)
        return function()
            local has = SND.has.slash
            local b = has and 1 or 1.8
            return {{0, {
                id = has and SFX_EXTRA.slash or nil,
                speed = from * b, sweep = to * b, dur = dur,
                vol = vol, att = att, hold = hold, rel = rel,
                low = -30, mid = -6, high = 3,
                reverb = 1.6, wet = -8,
            }}}
        end
    end

    -- Her cue: {gecikme_sn, ses_seçenekleri} listesi döndürür
    local CUES = {
        open   = air(0.4, 0.5, 0.9, 1.0, 0.7, 0.1, 0.35),      -- yumuşak açılış dalgası
        core   = function()                                     -- derin, yumuşak tek vuruş
            return {{0, {speed = 0.5, sweep = 0.26, dur = 0.5, vol = 0.8,
                low = 10, mid = -12, high = -40, hold = 0.1, rel = 0.5,
                reverb = 1.2, wet = -10}}}
        end,
        lock   = bell(12, 0.32),                                -- La
        -- HUB yazısı: ince, havadar rüzgar nefesi (hafifçe alçalır) + altında yumuşak bas
        -- İstersen sadece rüzgar için ikinci satırı, sadece bas için birinci satırı sil.
        badge  = function()
            local has = SND.has.slash
            local b = has and 1 or 1.8
            return {
                {0, {id = has and SFX_EXTRA.slash or nil, speed = 1.4 * b, sweep = 0.75 * b, dur = 0.9,
                    vol = 0.4, att = 0.12, hold = 0.12, rel = 0.8,
                    low = -35, mid = -8, high = 5, reverb = 2.2, wet = -5}},
                {0, {speed = 0.42, sweep = 0.3, dur = 0.8, vol = 0.4, att = 0.06, hold = 0.1, rel = 0.9,
                    low = 10, mid = -16, high = -45, reverb = 1.4, wet = -9}},
            }
        end,
        exit   = air(0.4, 0.7, 1.5, 0.6, 0.12, 0.05, 0.45),    -- çıkış süpürmesi
        finale = bell(31, 0.38),                                -- tiz Mi
        -- DOĞRULAMA: yükselen üç nota (La - Do# - Mi), son nota daha belirgin
        verify = function()
            return {
                {0.00, bellOpts(24, 0.40)},
                {0.08, bellOpts(28, 0.40)},
                {0.16, bellOpts(31, 0.50)},
            }
        end,
    }

    local function fadeVoices(t)
        t = t or 0.18
        local list = SND.voices
        SND.voices = {}
        for _, v in ipairs(list) do
            pcall(function() tween(v, t, {Volume = 0}, Enum.EasingStyle.Sine) end)
            task.delay(t + 0.07, function()
                pcall(function() v:Destroy() end)
            end)
        end
    end
    function SND.play(name)
        local build = CUES[name]
        if not build or not Settings.Sound then return end
        fadeVoices(0.18)
        SND.token = SND.token + 1
        local tk = SND.token
        local ok, events = pcall(build)
        if not ok or not events then return end
        for _, ev in ipairs(events) do
            local function go()
                if tk ~= SND.token then return end
                local s = sfx(ev[2])
                if s then SND.voices[#SND.voices + 1] = s end
            end
            if ev[1] <= 0 then go() else task.delay(ev[1], go) end
        end
    end
    function SND.stop(t)
        SND.token = SND.token + 1
        fadeVoices(t or 0.3)
    end

    local IntroGui = new("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 300,
    }, ScreenGui)
    new("UIGradient", {
        Color = ColorSequence.new(Color3.fromRGB(3, 5, 12), Color3.fromRGB(22, 8, 40)),
        Rotation = 90,
    }, IntroGui)

    local IntroContent = new("Frame", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, ZIndex = 300}, IntroGui)

    local Stage = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.4, 0),
        Size = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        ZIndex = 301,
    }, IntroContent)
    new("UIScale", {Scale = getScale(780, 800, 0.5)}, Stage)

    local function makeBar(isTop)
        local bar = new("Frame", {
            AnchorPoint = Vector2.new(0, isTop and 0 or 1),
            Position = UDim2.new(0, 0, isTop and 0 or 1, 0),
            Size = UDim2.new(1, 0, 0, 0),
            BackgroundColor3 = Color3.new(0, 0, 0),
            BorderSizePixel = 0,
            ZIndex = 310,
        }, IntroContent)
        local edge = new("Frame", {
            AnchorPoint = Vector2.new(0, isTop and 1 or 0),
            Position = UDim2.new(0, 0, isTop and 1 or 0, 0),
            Size = UDim2.new(1, 0, 0, 2),
            BorderSizePixel = 0,
            BackgroundColor3 = Color3.new(1, 1, 1),
            ZIndex = 311,
        }, bar)
        regFlow(IntroFlows, new("UIGradient", {}, edge), 0, 0.7)
        return bar
    end
    local BarTop = makeBar(true)
    local BarBottom = makeBar(false)

    local ScanLine = new("Frame", {
        Size = UDim2.new(1, 0, 0, 2),
        BackgroundColor3 = Color3.fromRGB(255, 35, 55),
        BackgroundTransparency = 0.82,
        BorderSizePixel = 0,
        ZIndex = 300,
    }, IntroContent)
    track(IntroAccents, ScanLine, "BackgroundColor3", 0)

    local Rings = {}
    local function makeRing(thickness, speed, size)
        local ring = new("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0, 0, 0, -12),
            Size = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
            ZIndex = 301,
        }, Stage)
        pill(ring)
        local st = stroke(ring, thickness, Color3.fromRGB(255, 35, 55))
        local grad = new("UIGradient", {Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.45, 0.1),
            NumberSequenceKeypoint.new(0.5, 1),
            NumberSequenceKeypoint.new(1, 1),
        })}, st)
        Rings[#Rings + 1] = {frame = ring, stroke = st, grad = grad, speed = speed, size = size}
    end
    makeRing(4, 220, 440)
    makeRing(2.5, -320, 340)
    makeRing(1.5, 480, 250)

    local Rays = {}
    for i = 0, 11 do
        Rays[i + 1] = new("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0, 0, 0, -12),
            Size = UDim2.new(0, 3, 0, 0),
            Rotation = i * 15,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 301,
        }, Stage)
    end
    local function burstRays(color)
        for _, r in ipairs(Rays) do
            r.Size = UDim2.new(0, 3, 0, 0)
            r.BackgroundColor3 = color
            r.BackgroundTransparency = 0.15
            tween(r, 0.75, {Size = UDim2.new(0, 1, 0, 2400), BackgroundTransparency = 1}, Enum.EasingStyle.Quint)
        end
    end

    local function shockwave(x, y, finalSize, dur)
        dur = dur or 0.6
        local f = new("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0, x, 0, y),
            Size = UDim2.new(0, 20, 0, 20),
            BackgroundTransparency = 1,
            ZIndex = 302,
        }, Stage)
        pill(f)
        local st = stroke(f, 5, Color3.new(1, 1, 1), 0)
        tween(f, dur, {Size = UDim2.new(0, finalSize, 0, finalSize)}, Enum.EasingStyle.Quint)
        tween(st, dur, {Transparency = 1, Thickness = 1}, Enum.EasingStyle.Quint)
        task.delay(dur + 0.05, function() f:Destroy() end)
    end

    local Brackets = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 0, 0, 14),
        Size = UDim2.new(0, 1000, 0, 520),
        BackgroundTransparency = 1,
        ZIndex = 303,
    }, Stage)
    local BracketParts = {}
    for _, c in ipairs({{0, 0}, {1, 0}, {0, 1}, {1, 1}}) do
        for _, d in ipairs({{34, 3}, {3, 34}}) do
            local p = new("Frame", {
                AnchorPoint = Vector2.new(c[1], c[2]),
                Position = UDim2.new(c[1], 0, c[2], 0),
                Size = UDim2.new(0, d[1], 0, d[2]),
                BackgroundColor3 = Color3.fromRGB(255, 35, 55),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ZIndex = 303,
            }, Brackets)
            BracketParts[#BracketParts + 1] = p
            track(IntroAccents, p, "BackgroundColor3", 0)
        end
    end

    local LOGO_TEXT = "EZRAGOX"
    local LETTER_W, LETTER_GAP = 60, 4
    local CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789#@$%&?"
    local LETTERS_W = #LOGO_TEXT * (LETTER_W + LETTER_GAP)
    local BADGE_GAP, BADGE_W = 10, 130
    local BADGE_X = LETTERS_W + BADGE_GAP
    local TOTAL_W = BADGE_X + BADGE_W
    local HUB_CX = (BADGE_X + BADGE_W / 2) - TOTAL_W / 2

    local LogoHolder = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 0, 0, -12),
        Size = UDim2.new(0, TOTAL_W, 0, 90),
        BackgroundTransparency = 1,
        ZIndex = 303,
    }, Stage)

    local Layers = {
        {off = -3, trans = 0.5, color = Color3.fromRGB(255, 25, 42), z = 302, labels = {}},
        {off = 3, trans = 0.5, color = Color3.fromRGB(255, 70, 55), z = 302, labels = {}},
        {off = 0, trans = 0, color = Color3.fromRGB(255, 35, 55), z = 304, labels = {}},
    }
    local MainLetters = Layers[3].labels

    for _, L in ipairs(Layers) do
        for i = 1, #LOGO_TEXT do
            local n = math.random(1, #CHARS)
            L.labels[i] = new("TextLabel", {
                Size = UDim2.new(0, LETTER_W, 1, 0),
                Position = UDim2.new(0, (i - 1) * (LETTER_W + LETTER_GAP) + L.off, 0, -160),
                BackgroundTransparency = 1,
                Text = CHARS:sub(n, n),
                TextSize = 72,
                Font = Enum.Font.GothamBlack,
                TextColor3 = L.color,
                TextTransparency = 1,
                ZIndex = L.z,
            }, LogoHolder)
        end
    end

    local function setLetter(i, txt)
        for _, L in ipairs(Layers) do setText(L.labels[i], txt) end
    end
    local function placeLetters()
        for _, L in ipairs(Layers) do
            for i, l in ipairs(L.labels) do
                l.Position = UDim2.new(0, (i - 1) * (LETTER_W + LETTER_GAP) + L.off, 0, 0)
            end
        end
    end

    local HubBadge = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, BADGE_X + BADGE_W / 2, 0, 45),
        Size = UDim2.new(0, BADGE_W, 0, 64),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 305,
    }, LogoHolder)
    corner(HubBadge, 16)
    regFlow(IntroFlows, new("UIGradient", {Rotation = 25}, HubBadge), 1, 0.6, 50)
    local HubScale = new("UIScale", {Scale = 2.6}, HubBadge)
    local HubStroke = stroke(HubBadge, 3, Color3.new(1, 1, 1), 1)
    track(IntroAccents, HubStroke, "Color", 1.5)
    local HubText = new("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "HUB",
        Font = Enum.Font.GothamBlack,
        TextSize = 46,
        TextColor3 = Color3.fromRGB(8, 10, 18),
        TextTransparency = 1,
        ZIndex = 306,
    }, HubBadge)
    local HubShine = makeShine(HubBadge, 307)

    local IntroLine = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 0, 0, 56),
        Size = UDim2.new(0, 0, 0, 2),
        BorderSizePixel = 0,
        BackgroundColor3 = Color3.new(1, 1, 1),
        ZIndex = 303,
    }, Stage)
    regFlow(IntroFlows, new("UIGradient", {}, IntroLine), 0, 0.8)

    local IntroSub = new("TextLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.new(0, 420, 0, 24),
        Position = UDim2.new(0, 0, 0, 80),
        BackgroundTransparency = 1,
        Text = "TÜRK TROLL SCRİPTİ",
        TextColor3 = Color3.fromRGB(170, 190, 225),
        TextSize = 16,
        Font = Enum.Font.GothamBold,
        MaxVisibleGraphemes = 0,
        ZIndex = 303,
    }, Stage)

    local BarBG = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 0, 0, 126),
        Size = UDim2.new(0, 340, 0, 6),
        BackgroundColor3 = Color3.fromRGB(25, 30, 42),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 303,
    }, Stage)
    pill(BarBG)
    local BarFill = new("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BorderSizePixel = 0,
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 1,
        ZIndex = 304,
    }, BarBG)
    pill(BarFill)
    regFlow(IntroFlows, new("UIGradient", {}, BarFill), 0, 0.8)

    local StatusLabel = new("TextLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 0, 0, 148),
        Size = UDim2.new(0, 360, 0, 20),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = Color3.fromRGB(160, 175, 200),
        TextSize = 13,
        Font = Enum.Font.GothamMedium,
        TextTransparency = 1,
        ZIndex = 303,
    }, Stage)

    local Card = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1.5, 0),
        Size = UDim2.new(0, 420, 0, 100),
        BackgroundColor3 = Color3.fromRGB(10, 13, 20),
        BackgroundTransparency = 0.15,
        BorderSizePixel = 0,
        ZIndex = 320,
    }, IntroContent)
    corner(Card, 16)
    new("UIScale", {Scale = math.max(getScale(780, 800, 0.5), 0.7)}, Card)
    local CardStroke = stroke(Card, 2, Color3.new(1, 1, 1))
    regFlow(IntroFlows, new("UIGradient", {}, CardStroke), 0, 0.8, 90)

    local AvatarFrame = new("Frame", {
        Position = UDim2.new(0, 14, 0, 10),
        Size = UDim2.new(0, 80, 0, 80),
        BackgroundColor3 = Color3.fromRGB(20, 26, 38),
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 321,
    }, Card)
    pill(AvatarFrame)
    local AvatarStroke = stroke(AvatarFrame, 2.5, Color3.fromRGB(255, 35, 55))
    track(IntroAccents, AvatarStroke, "Color", 2)

    local Thumb = new("ImageLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 322,
    }, AvatarFrame)
    -- UICorner'ı doğrudan görselin üzerine uygula; yuvarlak kart tek başına
    -- ImageLabel içeriğini dairesel kırpmadığı için bu katman ayrıca yuvarlatılır.
    pill(Thumb)

    local VP = new("ViewportFrame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Ambient = Color3.fromRGB(190, 190, 190),
        LightColor = Color3.new(1, 1, 1),
        ZIndex = 323,
    }, AvatarFrame)
    pill(VP)

    -- Yuvarlak kırmızı çerçeveyi avatarın üst katmanına al.
    -- Böylece karakter görseli çerçevenin üzerinden taşmış gibi görünmez.
    local AvatarRingOverlay = new("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 325,
    }, AvatarFrame)
    pill(AvatarRingOverlay)
    local AvatarRingStroke = stroke(AvatarRingOverlay, 2.5, Color3.fromRGB(255, 35, 55))
    track(IntroAccents, AvatarRingStroke, "Color", 2)

    local WelcomeLabel = new("TextLabel", {
        Position = UDim2.new(0, 108, 0, 14), Size = UDim2.new(1, -125, 0, 16),
        BackgroundTransparency = 1, Text = "", TextColor3 = Color3.fromRGB(160, 175, 200),
        TextSize = 12, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 321,
    }, Card)
    local NameLabel = new("TextLabel", {
        Position = UDim2.new(0, 108, 0, 32), Size = UDim2.new(1, -125, 0, 34),
        BackgroundTransparency = 1, Text = "", TextColor3 = Color3.new(1, 1, 1),
        TextSize = 26, Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 321,
    }, Card)
    track(IntroAccents, NameLabel, "TextColor3", 1)
    local HandleLabel = new("TextLabel", {
        Position = UDim2.new(0, 108, 0, 68), Size = UDim2.new(1, -125, 0, 16),
        BackgroundTransparency = 1, Text = "@" .. LocalPlayer.Name, TextColor3 = Color3.fromRGB(130, 145, 170),
        TextSize = 12, Font = Enum.Font.GothamMedium, TextXAlignment = Enum.TextXAlignment.Left,
        TextTransparency = 1, ZIndex = 321,
    }, Card)
    local OnlinePill = new("TextLabel", {
        Position = UDim2.new(1, -96, 0, 10), Size = UDim2.new(0, 84, 0, 16),
        BackgroundTransparency = 1, Text = "● BAĞLANDI", TextColor3 = Color3.fromRGB(80, 255, 140),
        TextSize = 10, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Right,
        TextTransparency = 1, ZIndex = 321,
    }, Card)

    task.spawn(function()
        -- HeadShot tercih edilir; omuz ve kolların yuvarlak profil çerçevesinin
        -- kenarlarına taşma ihtimali AvatarBust'a göre daha düşüktür.
        for _, thumbType in ipairs({Enum.ThumbnailType.HeadShot, Enum.ThumbnailType.AvatarBust}) do
            local ok, content = pcall(function()
                return Players:GetUserThumbnailAsync(LocalPlayer.UserId, thumbType, Enum.ThumbnailSize.Size150x150)
            end)
            if ok and content and content ~= "" then
                Thumb.Image = content
                return
            end
        end
    end)

    local VPModel, VPBase
    pcall(function()
        local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        if not char then return end
        local wasArch = char.Archivable
        char.Archivable = true
        local clone = char:Clone()
        char.Archivable = wasArch
        if not clone then return end
        for _, d in ipairs(clone:GetDescendants()) do
            if d:IsA("LuaSourceContainer") then d:Destroy() end
        end
        local hrp = clone:FindFirstChild("HumanoidRootPart")
        local head = clone:FindFirstChild("Head")
        if not (hrp and head) then clone:Destroy() return end
        clone.Parent = VP
        local cam = Instance.new("Camera")
        cam.FieldOfView = 30
        -- Avatarı daire içinde tutmak için kadrajı biraz genişlet; kollar çemberin
        -- dışına taşmasın. Bakış noktası baş ve omuzların ortasına yakın.
        local target = head.Position - Vector3.new(0, 0.28, 0)
        local camPos = head.Position + hrp.CFrame.LookVector * 9.2 + Vector3.new(0, 0.12, 0)
        cam.CFrame = CFrame.lookAt(camPos, target)
        cam.Parent = VP
        VP.CurrentCamera = cam
        VPModel = clone
        VPBase = clone:GetPivot()
        Thumb.Visible = false
    end)

    local function spawnParticle()
        local size = math.random(3, 8)
        local p = new("Frame", {
            Size = UDim2.new(0, size, 0, size),
            Position = UDim2.new(math.random(), 0, 1.05, 0),
            BackgroundColor3 = palette(math.random() * 4),
            BackgroundTransparency = math.random(2, 5) / 10,
            BorderSizePixel = 0,
            ZIndex = 300,
        }, IntroContent)
        pill(p)
        local dur = math.random(20, 38) / 10
        tween(p, dur, {
            Position = UDim2.new(p.Position.X.Scale + (math.random() - 0.5) * 0.15, 0, -0.1, 0),
            BackgroundTransparency = 1,
        }, Enum.EasingStyle.Linear)
        task.delay(dur, function() p:Destroy() end)
    end

    local Flash = new("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 400,
    }, IntroGui)

    -- RED NIGHT sinematik HUD katmanı: hedefleme halkası, veri çizgileri ve kenar ışıkları.
    local IntroHUD = new("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ZIndex = 330,
    }, IntroContent)

    local HUDTopLine = new("Frame", {
        Position = UDim2.new(0, 0, 0, 18),
        Size = UDim2.new(0, 0, 0, 2),
        BackgroundColor3 = Color3.fromRGB(255, 35, 55),
        BorderSizePixel = 0,
        ZIndex = 331,
    }, IntroHUD)

    local HUDBottomLine = new("Frame", {
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, 0, 1, -18),
        Size = UDim2.new(0, 0, 0, 2),
        BackgroundColor3 = Color3.fromRGB(255, 35, 55),
        BorderSizePixel = 0,
        ZIndex = 331,
    }, IntroHUD)

    local HUDLeft = new("Frame", {
        Position = UDim2.new(0, 22, 0.5, -70),
        Size = UDim2.new(0, 2, 0, 140),
        BackgroundColor3 = Color3.fromRGB(255, 35, 55),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 331,
    }, IntroHUD)

    local HUDRight = new("Frame", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -22, 0.5, -70),
        Size = UDim2.new(0, 2, 0, 140),
        BackgroundColor3 = Color3.fromRGB(255, 35, 55),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 331,
    }, IntroHUD)

    local HUDStatus = new("TextLabel", {
        Position = UDim2.new(0, 34, 0, 28),
        Size = UDim2.new(0, 230, 0, 18),
        BackgroundTransparency = 1,
        Text = "EZRAGOX  //  SYSTEM INITIALIZING",
        TextColor3 = Color3.fromRGB(255, 75, 88),
        TextTransparency = 1,
        TextSize = 10,
        Font = Enum.Font.Code,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 332,
    }, IntroHUD)

    local HUDReadout = new("TextLabel", {
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -34, 1, -28),
        Size = UDim2.new(0, 240, 0, 18),
        BackgroundTransparency = 1,
        Text = "SECURE CONNECTION  •  RED NIGHT",
        TextColor3 = Color3.fromRGB(190, 55, 68),
        TextTransparency = 1,
        TextSize = 10,
        Font = Enum.Font.Code,
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 332,
    }, IntroHUD)

    local TargetReticle = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.4, 0),
        Size = UDim2.new(0, 34, 0, 34),
        BackgroundTransparency = 1,
        ZIndex = 333,
    }, IntroHUD)
    local ReticleStroke = stroke(TargetReticle, 2, Color3.fromRGB(255, 40, 58), 0.15)
    pill(TargetReticle)
    local ReticleCore = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 4, 0, 4),
        BackgroundColor3 = Color3.fromRGB(255, 65, 75),
        BorderSizePixel = 0,
        ZIndex = 334,
    }, TargetReticle)
    pill(ReticleCore)

    local DataBars = {}
    for i = 1, 18 do
        local bar = new("Frame", {
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.new(0, 34 + (i - 1) * 7, 1, -30),
            Size = UDim2.new(0, 3, 0, math.random(3, 16)),
            BackgroundColor3 = Color3.fromRGB(255, 35, 55),
            BackgroundTransparency = 0.28,
            BorderSizePixel = 0,
            ZIndex = 332,
        }, IntroHUD)
        DataBars[#DataBars + 1] = bar
    end

    local RedFlash = new("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(255, 15, 35),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 390,
    }, IntroGui)

    ---------------------------------------------------------
    -- v4 EK KATMANLAR
    ---------------------------------------------------------
    local function live()
        return introAlive and alive and IntroGui.Parent ~= nil
    end

    -- Efekt durumu (RenderStepped tarafından okunur)
    local introT0, origFOV = os.clock(), 70
    local fovOn, fxOn, rainOn, logoLive = false, false, true, false
    local punch, shakeAmp = 0, 0
    local function impact(p, s)
        punch = math.max(punch, p)
        shakeAmp = math.max(shakeAmp, s)
    end

    HUDReadout.Size = UDim2.new(0, 340, 0, 18)

    -- Kırmızı vinyet: ekran kenarlarında koyu kırmızı gölge, vuruşlarda nabız atar
    local Vig = {}
    do
        local defs = {
            {Vector2.new(0, 0), UDim2.new(0, 0, 0, 0), UDim2.new(0.28, 0, 1, 0), 0},
            {Vector2.new(1, 0), UDim2.new(1, 0, 0, 0), UDim2.new(0.28, 0, 1, 0), 180},
            {Vector2.new(0, 0), UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0.3, 0), 90},
            {Vector2.new(0, 1), UDim2.new(0, 0, 1, 0), UDim2.new(1, 0, 0.3, 0), 270},
        }
        for _, d in ipairs(defs) do
            local f = new("Frame", {
                AnchorPoint = d[1],
                Position = d[2],
                Size = d[3],
                BackgroundColor3 = Color3.fromRGB(90, 0, 14),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ZIndex = 298,
            }, IntroContent)
            new("UIGradient", {
                Rotation = d[4],
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0.1),
                    NumberSequenceKeypoint.new(1, 1),
                }),
            }, f)
            Vig[#Vig + 1] = f
        end
    end

    -- Neon aura: logonun arkasında üst üste binen yumuşak daireler (sahte bloom)
    local Aura = {}
    for _, d in ipairs({{360, 0.93}, {520, 0.955}, {700, 0.972}, {900, 0.985}}) do
        local f = new("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0, 0, 0, -12),
            Size = UDim2.new(0, 0, 0, 0),
            BackgroundColor3 = Color3.fromRGB(255, 35, 55),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 300,
        }, Stage)
        pill(f)
        Aura[#Aura + 1] = {f = f, size = d[1], tr = d[2]}
    end

    -- Dönen ölçek halkası (72 çentik, her 6'da bir uzun)
    local TickRing = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 0, 0, -12),
        Size = UDim2.new(0, 540, 0, 540),
        BackgroundTransparency = 1,
        ZIndex = 301,
    }, Stage)
    local TickScale = new("UIScale", {Scale = 0.05}, TickRing)
    for i = 0, 71 do
        local ang = math.rad(i * 5)
        local long = (i % 6 == 0)
        local len = long and 16 or 7
        local r = 262 - len / 2
        local p = new("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, math.cos(ang) * r, 0.5, math.sin(ang) * r),
            Size = UDim2.new(0, long and 3 or 2, 0, len),
            Rotation = i * 5 - 90,
            BackgroundColor3 = Color3.fromRGB(255, 45, 62),
            BackgroundTransparency = long and 0.1 or 0.55,
            BorderSizePixel = 0,
            ZIndex = 301,
        }, TickRing)
        if long then track(IntroAccents, p, "BackgroundColor3", i * 0.04) end
    end

    -- Dijital yağmur (üstten akan kırmızı karakter sütunları)
    local RAIN_CHARS = "01ABCDEFGHIJKLMNOPQRSTUVWXYZ#$%&@*+<>/=?"
    local function spawnRain()
        local x = math.random()
        local len = math.random(8, 18)
        local chars = {}
        for i = 1, len do
            local n = math.random(1, #RAIN_CHARS)
            chars[i] = RAIN_CHARS:sub(n, n)
        end
        local h = len * 13
        local lbl = new("TextLabel", {
            AnchorPoint = Vector2.new(0.5, 1),
            Position = UDim2.new(x, 0, 0, -10),
            Size = UDim2.new(0, 14, 0, h),
            BackgroundTransparency = 1,
            Text = table.concat(chars, "\n"),
            Font = Enum.Font.Code,
            TextSize = 12,
            TextColor3 = palette(math.random() * 4),
            TextTransparency = 0.35,
            TextYAlignment = Enum.TextYAlignment.Bottom,
            ZIndex = 299,
        }, IntroContent)
        new("UIGradient", {
            Rotation = 90,
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(1, 0),
            }),
        }, lbl)
        local dur = math.random(18, 34) / 10
        tween(lbl, dur, {Position = UDim2.new(x, 0, 1, h + 20)}, Enum.EasingStyle.Linear)
        task.delay(dur + 0.1, function() lbl:Destroy() end)
    end

    -- Boot konsolu (soldaki sistem günlüğü)
    local BootLog = new("TextLabel", {
        Position = UDim2.new(0, 34, 0.5, -70),
        Size = UDim2.new(0, 360, 0, 150),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = Color3.fromRGB(255, 75, 88),
        TextTransparency = 0.1,
        TextSize = 11,
        Font = Enum.Font.Code,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        ZIndex = 332,
    }, IntroHUD)
    local bootLines = {
        "[  OK  ] EZRAGOX çekirdeği yüklendi",
        "[  OK  ] bellek haritası doğrulandı",
        "[  OK  ] arayüz motoru başlatıldı",
        "[ WARN ] gölge protokolü algılandı",
        "[  OK  ] şifreleme katmanı aktif",
        "[  OK  ] troll modülleri hazır",
        "[  OK  ] oyuncu: " .. LocalPlayer.Name,
        "[  GO  ] sistem başlatılıyor...",
    }

    -- Yükleme çubuğunun parlayan ucu
    local BarHead = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(0, 10, 0, 10),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 306,
    }, BarBG)
    pill(BarHead)
    local BarHeadStroke = stroke(BarHead, 3, Color3.fromRGB(255, 35, 55), 1)
    track(IntroAccents, BarHeadStroke, "Color", 0.5)

    -- Kart: parıltı geçişi + avatarın büyüyerek belirmesi
    local CardClip = new("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        ZIndex = 340,
    }, Card)
    corner(CardClip, 16)
    local CardShine = makeShine(CardClip, 341)
    AvatarFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    AvatarFrame.Position = UDim2.new(0, 54, 0, 50)
    local AvatarPop = new("UIScale", {Scale = 0.01}, AvatarFrame)

    -- "ERİŞİM ONAYLANDI" bandı
    local ACCESS_TEXT = "ERİŞİM ONAYLANDI"
    local AccessBand = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.4, -12),
        Size = UDim2.new(0, 0, 0, 2),
        BackgroundColor3 = Color3.fromRGB(6, 0, 3),
        BackgroundTransparency = 0.04,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Visible = false,
        ZIndex = 336,
    }, IntroContent)
    for _, top in ipairs({true, false}) do
        local e = new("Frame", {
            AnchorPoint = Vector2.new(0, top and 0 or 1),
            Position = UDim2.new(0, 0, top and 0 or 1, 0),
            Size = UDim2.new(1, 0, 0, 2),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            ZIndex = 337,
        }, AccessBand)
        regFlow(IntroFlows, new("UIGradient", {}, e), top and 0 or 1.2, 0.7)
    end
    local AccessTitle = new("TextLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, -4),
        Size = UDim2.new(1, 0, 0, 60),
        BackgroundTransparency = 1,
        Text = ACCESS_TEXT,
        TextColor3 = Color3.new(1, 1, 1),
        TextTransparency = 1,
        Font = Enum.Font.GothamBlack,
        TextSize = math.max(18, math.floor(38 * getScale(780, 800, 0.5))),
        ZIndex = 338,
    }, AccessBand)
    local AccessTitleStroke = stroke(AccessTitle, 2.5, Color3.fromRGB(255, 35, 55), 1)
    track(IntroAccents, AccessTitleStroke, "Color", 0)
    local AccessSub = new("TextLabel", {
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, -4),
        Size = UDim2.new(1, 0, 0, 14),
        BackgroundTransparency = 1,
        Text = "● ACCESS GRANTED  //  KULLANICI DOĞRULANDI  //  RED NIGHT",
        TextColor3 = Color3.fromRGB(255, 110, 120),
        TextTransparency = 1,
        Font = Enum.Font.Code,
        TextSize = 10,
        ZIndex = 338,
    }, AccessBand)

    -- Kıvılcım patlaması (Stage koordinatlarında)
    local function sparks(x, y, n, color)
        for _ = 1, n do
            local sz = math.random(2, 5)
            local p = new("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0, x, 0, y),
                Size = UDim2.new(0, sz, 0, sz),
                BackgroundColor3 = color,
                BorderSizePixel = 0,
                ZIndex = 306,
            }, Stage)
            local ang = math.random() * math.pi * 2
            local dist = math.random(35, 120)
            local dur = math.random(35, 70) / 100
            tween(p, dur, {
                Position = UDim2.new(0, x + math.cos(ang) * dist, 0, y + math.sin(ang) * dist * 0.6 + 26),
                BackgroundTransparency = 1,
                Size = UDim2.new(0, 1, 0, 1),
            }, Enum.EasingStyle.Quad)
            task.delay(dur + 0.05, function() p:Destroy() end)
        end
    end

    -- Sert harf çözülmesi (ERİŞİM ONAYLANDI için)
    local function decodeInto(lbl, finalText, steps, stepDelay)
        local chars = {}
        for _, c in utf8.codes(finalText) do chars[#chars + 1] = utf8.char(c) end
        for step = 1, steps do
            local out = {}
            for k, ch in ipairs(chars) do
                if ch == " " then
                    out[k] = " "
                elseif step >= 3 + k * 0.6 then
                    out[k] = ch
                else
                    local n = math.random(1, #CHARS)
                    out[k] = CHARS:sub(n, n)
                end
            end
            setText(lbl, table.concat(out))
            task.wait(stepDelay)
        end
        setText(lbl, finalText)
    end

    ---------------------------------------------------------
    -- HER KARE: renkler, halkalar, aura, vinyet, kamera, sarsıntı
    ---------------------------------------------------------
    bind(RunService.RenderStepped, function(dt)
        if not (introAlive and IntroGui.Parent) then return end
        local t = os.clock()

        for _, a in ipairs(IntroAccents) do a.obj[a.prop] = accentAt(a.off) end
        for _, f in ipairs(IntroFlows) do
            f.grad.Color = flowSeq(f.phase, f.step)
            if f.spin then f.grad.Rotation = (f.grad.Rotation + f.spin * dt) % 360 end
        end
        for idx, r in ipairs(Rings) do
            r.stroke.Color = accentAt(idx * 1.6)
            r.grad.Rotation = r.grad.Rotation + r.speed * dt
        end
        for i, l in ipairs(MainLetters) do
            l.TextColor3 = accentAt(i * 0.35)
        end
        if VPModel and VPModel.Parent and VPBase then
            VPModel:PivotTo(VPBase * CFrame.Angles(0, math.sin(t * 1.4) * 0.55, 0))
        end

        TickRing.Rotation = (t * 14) % 360
        punch = math.max(0, punch - dt * 2.6)

        -- Aura: nefes alır, vuruşlarda parlar
        local ak = K.aura.Value
        for i, a in ipairs(Aura) do
            local sz = a.size * ak * (1 + 0.05 * math.sin(t * 2.2 + i) + 0.1 * punch)
            a.f.Size = UDim2.new(0, sz, 0, sz)
            a.f.BackgroundTransparency = math.clamp(1 - (1 - a.tr) * ak * (1 + punch * 0.8), 0, 1)
            a.f.BackgroundColor3 = accentAt(i * 0.4)
        end

        if fxOn then
            local vt = math.clamp(1 - K.vig.Value * (0.7 + 0.12 * punch), 0, 1)
            for _, f in ipairs(Vig) do f.BackgroundTransparency = vt end
            blurEffect.Size = K.blur.Value + punch * 12
            cc.Contrast = 0.15 + punch * 0.22
        end

        if fovOn then
            local cam = workspace.CurrentCamera
            if cam then
                local z = math.clamp((t - introT0) / 6.5, 0, 1)
                cam.FieldOfView = origFOV - z * 9 - punch * 5
            end
        end

        if shakeAmp > 0.4 then
            IntroContent.Position = UDim2.new(0, (math.random() * 2 - 1) * shakeAmp, 0, (math.random() * 2 - 1) * shakeAmp)
            shakeAmp = shakeAmp * (0.86 ^ (dt * 60))
        elseif shakeAmp > 0 then
            shakeAmp = 0
            IntroContent.Position = UDim2.new(0, 0, 0, 0)
        end
    end)
    ---------------------------------------------------------
    -- SENARYO
    ---------------------------------------------------------
    function I.play(onPeak)
        local cam0 = workspace.CurrentCamera or Camera
        origFOV = (cam0 and cam0.FieldOfView) or 70
        introT0 = os.clock()
        fovOn, fxOn = true, true

        -- Beklenmedik kapanışta (closeAll) sesi ve kamerayı geri al
        task.spawn(function()
            while live() do task.wait(0.15) end
            SND.stop(0.2)
            if fovOn then
                fovOn = false
                pcall(function()
                    local c = workspace.CurrentCamera
                    if c then c.FieldOfView = origFOV end
                end)
            end
        end)

        -- Arka plan döngüleri
        task.spawn(function()
            while live() do
                spawnParticle()
                task.wait(0.06)
            end
        end)
        task.spawn(function()
            while live() do
                ScanLine.Position = UDim2.new(0, 0, 0, 0)
                tween(ScanLine, 1.8, {Position = UDim2.new(0, 0, 1, 0)}, Enum.EasingStyle.Linear)
                task.wait(1.8)
            end
        end)
        task.spawn(function()
            while live() and rainOn do
                spawnRain()
                task.wait(0.07)
            end
        end)
        task.spawn(function()
            while live() do
                setText(HUDReadout, string.format("SECURE CONNECTION  •  0x%04X  •  RED NIGHT", math.random(0, 65535)))
                task.wait(0.09)
            end
        end)
        task.spawn(function()
            while live() do
                tween(TargetReticle, 1.1, {Rotation = TargetReticle.Rotation + 90}, Enum.EasingStyle.Linear)
                task.wait(1.1)
            end
        end)
        task.spawn(function()
            while live() do
                for _, bar in ipairs(DataBars) do
                    if bar.Parent then
                        tween(bar, 0.22, {Size = UDim2.new(0, 3, 0, math.random(3, 18))}, Enum.EasingStyle.Quad)
                    end
                end
                task.wait(0.22)
            end
        end)

        ---------------------------------------------------------
        -- 1) AÇILIŞ: karanlık, şeritler, HUD, boot konsolu, yükselen gerilim
        ---------------------------------------------------------
        SND.play("open")
        tween(IntroGui, 0.5, {BackgroundTransparency = 0.08})
        tween(K.vig, 1.2, {Value = 1}, Enum.EasingStyle.Quad)
        tween(K.blur, 0.6, {Value = 22}, Enum.EasingStyle.Quint)
        tween(cc, 2.5, {Saturation = 0.2, TintColor = Color3.fromRGB(255, 226, 226)})
        tween(HUDTopLine, 0.75, {Size = UDim2.new(1, -44, 0, 2)}, Enum.EasingStyle.Quint)
        tween(HUDBottomLine, 0.75, {Size = UDim2.new(1, -44, 0, 2)}, Enum.EasingStyle.Quint)
        tween(HUDLeft, 0.55, {BackgroundTransparency = 0.12}, Enum.EasingStyle.Quint)
        tween(HUDRight, 0.55, {BackgroundTransparency = 0.12}, Enum.EasingStyle.Quint)
        tween(HUDStatus, 0.5, {TextTransparency = 0})
        tween(HUDReadout, 0.5, {TextTransparency = 0})
        tween(TargetReticle, 0.7, {Size = UDim2.new(0, 150, 0, 150)}, Enum.EasingStyle.Back)
        tween(BarTop, 0.7, {Size = UDim2.new(1, 0, 0.1, 0)}, Enum.EasingStyle.Quint)
        tween(BarBottom, 0.7, {Size = UDim2.new(1, 0, 0.1, 0)}, Enum.EasingStyle.Quint)

        task.spawn(function()
            local shown = {}
            for _, line in ipairs(bootLines) do
                if not live() then return end
                shown[#shown + 1] = line
                if #shown > 9 then table.remove(shown, 1) end
                setText(BootLog, table.concat(shown, "\n"))
                SND.click(1.9 + math.random() * 0.6, 0.22)
                task.wait(0.13)
            end
        end)
        task.wait(1.15)
        if not live() then return end

        ---------------------------------------------------------
        -- 2) ÇARPMA #1: patlama, halkalar, ışınlar, aura
        ---------------------------------------------------------
        impact(1, 16)
        SND.play("core")
        setText(HUDStatus, "EZRAGOX  //  CORE ONLINE")
        burstRays(Color3.fromRGB(255, 35, 55))
        tween(RedFlash, 0.09, {BackgroundTransparency = 0.7})
        task.delay(0.1, function()
            if RedFlash.Parent then tween(RedFlash, 0.4, {BackgroundTransparency = 1}) end
        end)
        shockwave(0, -12, 900, 0.85)
        tween(BootLog, 0.4, {TextTransparency = 1})
        tween(K.blur, 1.2, {Value = 28}, Enum.EasingStyle.Quad)
        tween(K.aura, 1.4, {Value = 1}, Enum.EasingStyle.Quad)
        for i, r in ipairs(Rings) do
            tween(r.frame, 1 + i * 0.15, {Size = UDim2.new(0, r.size, 0, r.size)}, Enum.EasingStyle.Back)
        end
        tween(Brackets, 1, {Size = UDim2.new(0, 660, 0, 200)}, Enum.EasingStyle.Quint)
        for _, p in ipairs(BracketParts) do
            tween(p, 0.6, {BackgroundTransparency = 0})
        end
        tween(TickScale, 1.1, {Scale = 1}, Enum.EasingStyle.Back)
        task.wait(0.55)
        if not live() then return end

        ---------------------------------------------------------
        -- 3) HARFLER: yukarıdan düşer, çözülür, her biri kıvılcım + vuruş sesi çıkarır
        ---------------------------------------------------------
        local scrambleDone = false
        task.spawn(function()
            for step = 1, 30 do
                for i = 1, #LOGO_TEXT do
                    if step >= 8 + i * 2.6 then
                        setLetter(i, LOGO_TEXT:sub(i, i))
                    else
                        local n = math.random(1, #CHARS)
                        setLetter(i, CHARS:sub(n, n))
                    end
                end
                task.wait(0.035)
            end
            for i = 1, #LOGO_TEXT do setLetter(i, LOGO_TEXT:sub(i, i)) end
            scrambleDone = true
        end)

        for i = 1, #LOGO_TEXT do
            for _, L in ipairs(Layers) do
                tween(L.labels[i], 0.6, {
                    Position = UDim2.new(0, (i - 1) * (LETTER_W + LETTER_GAP) + L.off, 0, 0),
                    TextTransparency = L.trans,
                }, Enum.EasingStyle.Back)
            end
            local lx = -TOTAL_W / 2 + (i - 1) * (LETTER_W + LETTER_GAP) + LETTER_W / 2
            task.delay(0.3, function()
                if not live() then return end
                sparks(lx, 24, 7, accentAt(i * 0.35))
                SND.click(1.35 + i * 0.13, 0.38)
                impact(0.25, 3)
            end)
            task.wait(0.075)
        end
        while not scrambleDone do task.wait() end
        if not live() then return end

        ---------------------------------------------------------
        -- 4) ÇİZGİ + GLITCH + neon titremesi
        ---------------------------------------------------------
        tween(IntroLine, 0.5, {Size = UDim2.new(0, TOTAL_W - 30, 0, 2)}, Enum.EasingStyle.Quint)
        SND.play("lock")
        for k = 0, 2 do
            task.delay(k * 0.07, function() SND.click(2.1 + k * 0.35, 0.25) end)
        end
        setText(HUDStatus, "EZRAGOX  //  SIGNAL LOCKED")
        for _ = 1, 10 do
            LogoHolder.Position = UDim2.new(0, math.random(-8, 8), 0, -12 + math.random(-4, 4))
            Layers[1].off = math.random(-12, -3)
            Layers[2].off = math.random(3, 12)
            placeLetters()
            for _, l in ipairs(MainLetters) do
                l.TextTransparency = math.random() < 0.25 and 0.6 or 0
            end
            task.wait(0.035)
        end
        LogoHolder.Position = UDim2.new(0, 0, 0, -12)
        Layers[1].off, Layers[2].off = -3, 3
        placeLetters()
        for _, l in ipairs(MainLetters) do l.TextTransparency = 0 end

        logoLive = true
        task.spawn(function()
            while live() and logoLive do
                task.wait(math.random(35, 95) / 100)
                if not (live() and logoLive) then break end
                local l = MainLetters[math.random(1, #MainLetters)]
                for _ = 1, math.random(2, 4) do
                    l.TextTransparency = 0.75
                    task.wait(0.04)
                    l.TextTransparency = 0
                    task.wait(0.05)
                end
            end
        end)

        ---------------------------------------------------------
        -- 5) HUB ROZETİ ÇAKILIR: büyük vuruş, şok dalgaları, kıvılcım fırtınası
        ---------------------------------------------------------
        SND.play("badge")
        SND.click(1.1, 0.5)
        tween(HubBadge, 0.16, {BackgroundTransparency = 0}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        tween(HubScale, 0.16, {Scale = 1}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        tween(HubText, 0.16, {TextTransparency = 0})
        tween(HubStroke, 0.2, {Transparency = 0.2})
        task.wait(0.16)
        impact(1, 22)
        setText(HUDStatus, "EZRAGOX  //  HUB ENGAGED")
        burstRays(Color3.fromRGB(255, 35, 55))
        tween(RedFlash, 0.08, {BackgroundTransparency = 0.68})
        task.delay(0.09, function()
            if RedFlash.Parent then tween(RedFlash, 0.5, {BackgroundTransparency = 1}) end
        end)
        shockwave(HUB_CX, -12, 520, 0.6)
        shockwave(HUB_CX, -12, 320, 0.38)
        task.delay(0.12, function() shockwave(HUB_CX, -12, 760, 0.8) end)
        sparks(HUB_CX, -12, 18, Color3.fromRGB(255, 120, 90))
        task.spawn(function()
            while live() and logoLive do
                playShine(HubShine, 0.8)
                task.wait(1.1)
            end
        end)

        ---------------------------------------------------------
        -- 6) OYUNCU KARTI + YÜKLEME ÇUBUĞU
        ---------------------------------------------------------
        task.spawn(function()
            if not live() then return end
            SND.click(1.5, 0.3)
            tween(Card, 0.8, {Position = UDim2.new(0.5, 0, 0.9, -6)}, Enum.EasingStyle.Back)
            task.wait(0.45)
            tween(AvatarPop, 0.55, {Scale = 1}, Enum.EasingStyle.Back)
            SND.click(2.2, 0.35)
            playShine(CardShine, 0.9)
            task.wait(0.15)
            tween(OnlinePill, 0.4, {TextTransparency = 0})
            typeText(WelcomeLabel, "HOŞ GELDİN,", 0.03)
            local shown = LocalPlayer.DisplayName
            if not shown or shown == "" then shown = LocalPlayer.Name end
            typeText(NameLabel, shown, 0.04)
            tween(HandleLabel, 0.5, {TextTransparency = 0})
        end)

        tween(BarBG, 0.3, {BackgroundTransparency = 0.2})
        tween(BarFill, 0.3, {BackgroundTransparency = 0})
        tween(BarHead, 0.3, {BackgroundTransparency = 0})
        tween(BarHeadStroke, 0.3, {Transparency = 0.35})
        tween(StatusLabel, 0.3, {TextTransparency = 0})
        task.spawn(function() typeText(IntroSub, "TÜRK TROLL SCRİPTİ", 0.035) end)

        local statuses = {
            {0, "Modüller yükleniyor"},
            {25, "Arayüz hazırlanıyor"},
            {50, "Efektler ayarlanıyor"},
            {75, "Karakter doğrulanıyor"},
            {96, "Hazır!"},
        }
        local steps = 60
        for s = 0, steps do
            if not live() then return end
            local x = s / steps
            local p = math.floor(x * x * (3 - 2 * x) * 100 + 0.5)
            local msg = statuses[1][2]
            for _, st in ipairs(statuses) do
                if p >= st[1] then msg = st[2] end
            end
            setText(StatusLabel, msg .. "  •  " .. p .. "%")
            BarHead.Position = UDim2.new(p / 100, 0, 0.5, 0)
            tween(BarFill, 0.08, {Size = UDim2.new(p / 100, 0, 1, 0)}, Enum.EasingStyle.Linear)
            if s == 22 or s == 41 then
                SND.click(2.6, 0.4)
                impact(0.4, 5)
            end
            if s % 6 == 0 then SND.click(1.6 + x * 1.2, 0.2) end
            task.wait((s == 22 or s == 41) and 0.26 or 0.034)
        end
        setText(StatusLabel, "Hazır!  •  100%")
        SND.ready()
        setText(HUDStatus, "EZRAGOX  //  ALL SYSTEMS GO")
        task.wait(0.25)
        if not live() then return end

        ---------------------------------------------------------
        -- 7) ERİŞİM ONAYLANDI: ekranı kesen sinematik bant
        ---------------------------------------------------------
        local bandH = math.floor(84 * getScale(780, 800, 0.5))
        AccessBand.Visible = true
        AccessBand.Size = UDim2.new(0, 0, 0, 2)
        SND.play("verify")
        tween(AccessBand, 0.16, {Size = UDim2.new(1, 0, 0, 2)}, Enum.EasingStyle.Quint)
        task.wait(0.16)
        tween(AccessBand, 0.22, {Size = UDim2.new(1, 0, 0, bandH)}, Enum.EasingStyle.Back)
        impact(1, 22)
        tween(RedFlash, 0.08, {BackgroundTransparency = 0.6})
        task.delay(0.09, function()
            if RedFlash.Parent then tween(RedFlash, 0.45, {BackgroundTransparency = 1}) end
        end)
        shockwave(0, -12, 1000, 0.7)
        burstRays(Color3.new(1, 1, 1))
        task.wait(0.1)
        tween(AccessTitle, 0.12, {TextTransparency = 0})
        tween(AccessTitleStroke, 0.12, {Transparency = 0.2})
        tween(AccessSub, 0.2, {TextTransparency = 0})
        decodeInto(AccessTitle, ACCESS_TEXT, 14, 0.03)
        task.wait(0.42)
        if not live() then return end

        ---------------------------------------------------------
        -- 8) BÜYÜK ÇIKIŞ: bant kapanır, her şey dağılır, flaş
        ---------------------------------------------------------
        logoLive = false
        SND.play("exit")
        tween(AccessTitle, 0.15, {TextTransparency = 1})
        tween(AccessTitleStroke, 0.15, {Transparency = 1})
        tween(AccessSub, 0.15, {TextTransparency = 1})
        tween(AccessBand, 0.2, {Size = UDim2.new(1, 0, 0, 2)}, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        task.delay(0.2, function()
            tween(AccessBand, 0.15, {Size = UDim2.new(0, 0, 0, 2)}, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        end)
        impact(1, 26)
        burstRays(Color3.new(1, 1, 1))
        for _, r in ipairs(Rings) do
            tween(r.frame, 0.45, {Size = UDim2.new(0, 1800, 0, 1800)}, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        end
        tween(TickScale, 0.45, {Scale = 3}, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        tween(K.aura, 0.4, {Value = 2.2}, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        local center = 3 * (LETTER_W + LETTER_GAP)
        for i = 1, #LOGO_TEXT do
            for _, L in ipairs(Layers) do
                local base = (i - 1) * (LETTER_W + LETTER_GAP)
                tween(L.labels[i], 0.4, {
                    Position = UDim2.new(0, center + (base - center) * 2.2 + L.off, 0, 0),
                    TextTransparency = 1,
                }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
            end
        end
        tween(HubScale, 0.4, {Scale = 2.4}, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        tween(HubBadge, 0.4, {BackgroundTransparency = 1})
        tween(HubText, 0.3, {TextTransparency = 1})
        tween(HubStroke, 0.3, {Transparency = 1})
        tween(IntroLine, 0.3, {Size = UDim2.new(0, 0, 0, 2)})
        tween(Card, 0.4, {Position = UDim2.new(0.5, 0, 1.5, 0)}, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        tween(BarTop, 0.4, {Size = UDim2.new(1, 0, 0, 0)})
        tween(BarBottom, 0.4, {Size = UDim2.new(1, 0, 0, 0)})
        task.wait(0.35)

        tween(Flash, 0.12, {BackgroundTransparency = 0})
        task.wait(0.14)

        -- Flaşın tepe noktası: giriş kalkar, menü patlayarak açılır
        fxOn, fovOn, rainOn = false, false, false
        SND.stop(0.3)
        tween(HUDTopLine, 0.35, {BackgroundTransparency = 1})
        tween(HUDBottomLine, 0.35, {BackgroundTransparency = 1})
        tween(HUDLeft, 0.35, {BackgroundTransparency = 1})
        tween(HUDRight, 0.35, {BackgroundTransparency = 1})
        tween(HUDStatus, 0.25, {TextTransparency = 1})
        tween(HUDReadout, 0.25, {TextTransparency = 1})
        tween(TargetReticle, 0.3, {Size = UDim2.new(0, 360, 0, 360)})
        IntroContent.Visible = false
        IntroGui.BackgroundTransparency = 1
        cc.Brightness = 0.3
        tween(cc, 0.9, {Brightness = 0, Saturation = 0, Contrast = 0, TintColor = Color3.new(1, 1, 1)})
        pcall(function()
            local c = workspace.CurrentCamera
            if c then
                c.FieldOfView = origFOV + 15
                tween(c, 1, {FieldOfView = origFOV}, Enum.EasingStyle.Quint)
            end
        end)
        SND.play("finale")
        SND.click(1.3, 0.45)
        if onPeak then pcall(onPeak) end
        tween(Flash, 0.6, {BackgroundTransparency = 1})

        task.wait(0.95)
        introAlive = false
        pcall(function() cc:Destroy() end)
        IntroGui:Destroy()
    end

    return I
end)()

---------------------------------------------------------
-- 2. ANA MENÜ ÇERÇEVESİ
---------------------------------------------------------
local W, H = 720, 510
local ready = false
local menuOpen = false

local Window = new("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    Size = UDim2.new(0, 0, 0, 0),
    BackgroundTransparency = 1,
    ZIndex = 10,
}, ScreenGui)

local MainFrame = new("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0, 0, 0, 0),
    Size = UDim2.new(0, W, 0, H),
    BackgroundColor3 = Color3.new(1, 1, 1),
    BackgroundTransparency = 0.04,
    BorderSizePixel = 0,
    Active = true,
    Visible = false,
}, Window)
corner(MainFrame, 22)
new("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 8, 13)),
        ColorSequenceKeypoint.new(0.48, Color3.fromRGB(13, 8, 12)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(5, 5, 8)),
    }),
    Rotation = 105,
}, MainFrame)
-- İnce cam katmanı ve üstten gelen yumuşak neon ışık
local ShellGlow = new("Frame", {
    Position = UDim2.new(0, 2, 0, 2), Size = UDim2.new(1, -4, 0, 92),
    BackgroundColor3 = Color3.fromRGB(150, 12, 28), BackgroundTransparency = 0.84,
    BorderSizePixel = 0, ZIndex = 1,
}, MainFrame)
corner(ShellGlow, 20)
new("UIGradient", {Rotation = 90, Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.18), NumberSequenceKeypoint.new(1, 1),
})}, ShellGlow)
local MainScale = new("UIScale", {Scale = 1}, MainFrame)
local MainStroke = stroke(MainFrame, 2, Color3.new(1, 1, 1))
regFlow(UIFlows, new("UIGradient", {}, MainStroke), 0, 0.9, 60)

local GlowFrame = new("Frame", {
    -- Dış neon boşluğu iki tarafta eşit; panel kenarları kırpılmaz.
    Size = UDim2.new(1, 22, 1, 22),
    Position = UDim2.new(0, -11, 0, -11),
    BackgroundTransparency = 1,
    ZIndex = 0,
}, MainFrame)
corner(GlowFrame, 26)
local GlowStroke = stroke(GlowFrame, 8, Color3.new(1, 1, 1), 0.91)
regFlow(UIFlows, new("UIGradient", {}, GlowStroke), 1, 0.9, 60)
-- Koyu kırmızı dış aura; mevcut gradient döngüsüyle sürekli ve hafif hareket eder.
local RedAura = new("Frame", {
    Size = UDim2.new(1, 10, 1, 10),
    Position = UDim2.new(0, -5, 0, -5),
    BackgroundTransparency = 1,
    ZIndex = 0,
}, MainFrame)
corner(RedAura, 25)
local RedAuraStroke = stroke(RedAura, 2, Color3.fromRGB(255, 28, 48), 0.72)
Pulsers[#Pulsers + 1] = {obj = RedAuraStroke, prop = "Transparency", base = 0.72, amp = 0.16, speed = 1.8}

---------------------------------------------------------
-- 3. ÜST BAŞLIK
---------------------------------------------------------
local Header = new("Frame", {Size = UDim2.new(1, 0, 0, 76), BackgroundTransparency = 1, Active = true, ZIndex = 2}, MainFrame)
local HeaderAccent = new("Frame", {
    Position = UDim2.new(0, 18, 1, -2), Size = UDim2.new(1, -36, 0, 2),
    BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 3,
}, Header)
regFlow(UIFlows, new("UIGradient", {}, HeaderAccent), 0, 0.75, 35)

-- Sol üst logo: dairesel kapsayıcı görseli gerçekten yuvarlak kırpar.
local LogoCircle = new("Frame", {
    Position = UDim2.new(0, 20, 0, 16),
    Size = UDim2.new(0, 44, 0, 44),
    BackgroundColor3 = Color3.fromRGB(20, 5, 10),
    BorderSizePixel = 0,
    ClipsDescendants = true,
    ZIndex = 3,
}, Header)
corner(LogoCircle, 999)
local LogoMark = new("ImageLabel", {
    Position = UDim2.new(0, 0, 0, 0),
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Image = "rbxassetid://70705306364149",
    ScaleType = Enum.ScaleType.Crop,
    ImageTransparency = 0,
    ZIndex = 4,
}, LogoCircle)
-- Görselin kendisine de dairesel köşe uygula; böylece kare görüntü kenarı kalmaz.
corner(LogoMark, 999)
task.spawn(function()
    local cp = game:GetService("ContentProvider")
    pcall(function() cp:PreloadAsync({LogoMark}) end)
    if not LogoMark.IsLoaded then
        LogoMark.Image = "rbxthumb://type=Asset&id=70705306364149&w=420&h=420"
        pcall(function() cp:PreloadAsync({LogoMark}) end)
    end
end)

-- Üst marka başlığı
local BrandRow = new("Frame", {
    BackgroundTransparency = 1,
    Size = UDim2.new(1, -190, 0, 30),
    Position = UDim2.new(0, 76, 0, 12),
    ZIndex = 3,
}, Header)
new("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    HorizontalAlignment = Enum.HorizontalAlignment.Left,
    VerticalAlignment = Enum.VerticalAlignment.Center,
    Padding = UDim.new(0, 8),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, BrandRow)

-- Birleşik EZRAGOX HUB logosu: eski ayrı logo ve HUB rozeti kaldırıldı.
local BrandTitle = new("ImageLabel", {
    LayoutOrder = 1,
    Size = UDim2.new(0, 238, 0, 54),
    BackgroundTransparency = 1,
    Image = "rbxassetid://132651627732258",
    ScaleType = Enum.ScaleType.Fit,
    ImageTransparency = 0,
    ZIndex = 3,
}, BrandRow)

-- Logo yükleme; gerekirse küçük resim adresini dene.
task.spawn(function()
    local cp = game:GetService("ContentProvider")
    pcall(function() cp:PreloadAsync({BrandTitle}) end)
    if not BrandTitle.IsLoaded then
        BrandTitle.Image = "rbxthumb://type=Asset&id=132651627732258&w=420&h=420"
        pcall(function() cp:PreloadAsync({BrandTitle}) end)
    end
end)

-- Logonun üzerinden çapraz geçen parlak ışık süzmesi.
local BrandShineClip = new("Frame", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ClipsDescendants = true,
    ZIndex = 5,
}, BrandTitle)
local BrandShine = new("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(-0.35, 0, 0.5, 0),
    Size = UDim2.new(0.22, 0, 1.8, 0),
    Rotation = 24,
    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
    BackgroundTransparency = 0.15,
    BorderSizePixel = 0,
    ZIndex = 6,
}, BrandShineClip)
new("UIGradient", {
    Rotation = 0,
    Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.35, 0.92),
        NumberSequenceKeypoint.new(0.5, 0.18),
        NumberSequenceKeypoint.new(0.65, 0.92),
        NumberSequenceKeypoint.new(1, 1),
    }),
}, BrandShine)
task.spawn(function()
    while BrandTitle.Parent do
        BrandShine.Position = UDim2.new(-0.35, 0, 0.5, 0)
        local tween = game:GetService("TweenService"):Create(BrandShine,
            TweenInfo.new(1.15, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
            {Position = UDim2.new(1.35, 0, 0.5, 0)})
        tween:Play()
        tween.Completed:Wait()
        task.wait(2.4)
    end
end)

local BrandTagline = new("TextLabel", {
    Size = UDim2.new(1, -190, 0, 16),
    Position = UDim2.new(0, 76, 0, 46),
    BackgroundTransparency = 1,
    Text = "TÜRK TROLL SCRİPTİ   /   HİLE İŞİ GÖNÜL İŞİ   •   v6.6",
    TextColor3 = Color3.fromRGB(255, 70, 82),
    TextSize = 11,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd,
    ZIndex = 3,
}, Header)
local TaglineGradient = new("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(135, 12, 28)),
        ColorSequenceKeypoint.new(0.45, Color3.fromRGB(255, 65, 78)),
        ColorSequenceKeypoint.new(0.72, Color3.fromRGB(255, 150, 135)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 10, 28)),
    }),
    Rotation = 0,
}, BrandTagline)
regFlow(UIFlows, TaglineGradient, 0.15, 0.8, 0)
local TaglineStroke = stroke(BrandTagline, 1, Color3.fromRGB(255, 35, 55), 0.78)
Pulsers[#Pulsers + 1] = {
    obj = TaglineStroke,
    prop = "Transparency",
    base = 0.72,
    amp = 0.18,
    speed = 2.2,
}

local function makeIconButton(text, xOff, hoverColor)
    local b = new("TextButton", {
        Size = UDim2.new(0, 32, 0, 32),
        Position = UDim2.new(1, xOff, 0, 21),
        BackgroundColor3 = Color3.fromRGB(28, 10, 16),
        AutoButtonColor = false,
        Text = text,
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 18,
        Font = Enum.Font.GothamBold,
        ZIndex = 4,
    }, Header)
    corner(b, 9)
    bind(b.MouseEnter, function() tween(b, 0.15, {BackgroundColor3 = hoverColor}) end)
    bind(b.MouseLeave, function() tween(b, 0.15, {BackgroundColor3 = Color3.fromRGB(28, 10, 16)}) end)
    return b
end
local MinimizeBtn = makeIconButton("–", -84, Color3.fromRGB(105, 18, 32))
local CloseBtn = makeIconButton("✕", -46, Color3.fromRGB(210, 25, 45))

local Divider = new("Frame", {
    Position = UDim2.new(0, 18, 0, 76), Size = UDim2.new(1, -36, 0, 1),
    BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.55, BorderSizePixel = 0, ZIndex = 2,
}, MainFrame)
regFlow(UIFlows, new("UIGradient", {}, Divider), 0, 0.9)

local function makeDraggable(handle, target)
    local dragging, moved = false, false
    local startPos, startInput
    bind(handle.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging, moved = true, false
            startInput = input.Position
            startPos = target.Position
        end
    end)
    bind(UserInputService.InputChanged, function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - startInput
            if d.Magnitude > 6 then moved = true end
            if moved then
                target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
            end
        end
    end)
    bind(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    return function() return moved end
end
makeDraggable(Header, Window)

---------------------------------------------------------
-- 4. BİLDİRİMLER
---------------------------------------------------------
local ToastHolder = new("Frame", {
    AnchorPoint = Vector2.new(1, 1),
    Position = UDim2.new(1, -16, 1, -16),
    Size = UDim2.new(0, 270, 1, -32),
    BackgroundTransparency = 1,
    ZIndex = 500,
}, ScreenGui)
new("UIListLayout", {
    SortOrder = Enum.SortOrder.LayoutOrder,
    VerticalAlignment = Enum.VerticalAlignment.Bottom,
    Padding = UDim.new(0, 8),
}, ToastHolder)
local toastOrder = 0

local function notify(title, text, duration)
    title = trText(title)
    text = trText(text or "")
    toastOrder = toastOrder + 1
    local t = new("CanvasGroup", {
        LayoutOrder = toastOrder,
        Size = UDim2.new(1, 0, 0, 54),
        BackgroundColor3 = Color3.fromRGB(14, 17, 28),
        BorderSizePixel = 0,
        GroupTransparency = 1,
    }, ToastHolder)
    corner(t, 12)
    local bar = new("Frame", {Size = UDim2.new(0, 4, 1, 0), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0}, t)
    regFlow(UIFlows, new("UIGradient", {Rotation = 90}, bar), 0, 0.8)
    new("TextLabel", {
        Position = UDim2.new(0, 16, 0, 8), Size = UDim2.new(1, -26, 0, 18), BackgroundTransparency = 1,
        Text = title, Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = Color3.new(1, 1, 1),
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
    }, t)
    new("TextLabel", {
        Position = UDim2.new(0, 16, 0, 27), Size = UDim2.new(1, -26, 0, 18), BackgroundTransparency = 1,
        Text = text or "", Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = Color3.fromRGB(150, 163, 195),
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
    }, t)
    tween(t, 0.25, {GroupTransparency = 0})
    task.delay(duration or 3, function()
        if t.Parent then
            tween(t, 0.3, {GroupTransparency = 1})
            task.delay(0.35, function() t:Destroy() end)
        end
    end)
end

---------------------------------------------------------
-- 5. BİLEŞENLER
---------------------------------------------------------
local orders = {}
local function nextOrder(page)
    orders[page] = (orders[page] or 0) + 1
    return orders[page]
end

local function createSection(page, text)
    local holder = new("Frame", {
        LayoutOrder = nextOrder(page),
        Size = UDim2.new(1, 0, 0, 27),
        BackgroundTransparency = 1,
        ZIndex = 3,
    }, page)

    local accent = new("Frame", {
        Position = UDim2.new(0, 1, 0.5, -7),
        Size = UDim2.new(0, 3, 0, 14),
        BackgroundColor3 = Color3.fromRGB(255, 42, 60),
        BorderSizePixel = 0,
        ZIndex = 4,
    }, holder)
    corner(accent, 3)
    local glow = stroke(accent, 2, Color3.fromRGB(255, 35, 55), 0.5)

    local label = new("TextLabel", {
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(1, -16, 1, 0),
        BackgroundTransparency = 1,
        Text = string.upper(text),
        Font = Enum.Font.GothamBlack,
        TextSize = 10,
        TextColor3 = Color3.fromRGB(255, 112, 122),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 3,
    }, holder)
    local headingGradient = new("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(155, 15, 32)),
            ColorSequenceKeypoint.new(0.48, Color3.fromRGB(255, 70, 82)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 165, 145)),
        }),
        Rotation = 0,
    }, label)
    regFlow(UIFlows, headingGradient, 0.2, 0.75, 42)
    Pulsers[#Pulsers + 1] = {
        obj = glow, prop = "Transparency", base = 0.48, amp = 0.2, speed = 2.4,
    }

    local line = new("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 12, 1, -1),
        Size = UDim2.new(0.38, 0, 0, 1),
        BackgroundColor3 = Color3.fromRGB(180, 25, 42),
        BackgroundTransparency = 0.25,
        BorderSizePixel = 0,
        ZIndex = 3,
    }, holder)
    new("UIGradient", {
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.05),
            NumberSequenceKeypoint.new(1, 1),
        }),
    }, line)
    return holder
end

local ROW_BG = Color3.fromRGB(20, 12, 16)
local ROW_BG_HOVER = Color3.fromRGB(48, 12, 22)
local ROW_STROKE = Color3.fromRGB(105, 28, 42)

local function baseRow(page, class, height)
    local row = new(class, {
        LayoutOrder = nextOrder(page),
        Size = UDim2.new(1, 0, 0, height),
        BackgroundColor3 = ROW_BG,
        BackgroundTransparency = 0.05,
        BorderSizePixel = 0,
        ZIndex = 3,
    }, page)
    if class == "TextButton" then
        row.AutoButtonColor = false
        setText(row, "")
    end
    corner(row, 12)
    local rowGradient = new("UIGradient", {
        Rotation = 0,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(43, 13, 21)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(23, 11, 16)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(13, 9, 13)),
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.2),
            NumberSequenceKeypoint.new(1, 0.48),
        }),
    }, row)
    local st = stroke(row, 1, ROW_STROKE, 0.32)
    return row, st
end

local function rowLabel(row, text)
    return new("TextLabel", {
        Size = UDim2.new(1, -70, 0, 20),
        Position = UDim2.new(0, 14, 0, 11),
        BackgroundTransparency = 1,
        Text = text,
        Font = Enum.Font.GothamMedium,
        TextSize = 14,
        TextColor3 = Color3.fromRGB(228, 233, 245),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 4,
    }, row)
end

local function hoverFx(row, st)
    local scale = row:FindFirstChildOfClass("UIScale") or new("UIScale", {Scale = 1}, row)
    bind(row.MouseEnter, function()
        tween(row, 0.2, {BackgroundColor3 = ROW_BG_HOVER}, Enum.EasingStyle.Quint)
        tween(scale, 0.2, {Scale = 1.008}, Enum.EasingStyle.Quint)
        playSound(1.85, 0.055)
        tween(st, 0.22, {
            Color = Color3.fromRGB(255, 42, 58),
            Transparency = 0.02,
        }, Enum.EasingStyle.Quint)
    end)
    bind(row.MouseLeave, function()
        tween(row, 0.24, {BackgroundColor3 = ROW_BG}, Enum.EasingStyle.Quint)
        tween(scale, 0.24, {Scale = 1}, Enum.EasingStyle.Quint)
        tween(st, 0.24, {Color = ROW_STROKE, Transparency = 0.28}, Enum.EasingStyle.Quint)
    end)
end

local function createButton(page, text, callback)
    local btn, st = baseRow(page, "TextButton", 42)
    local sc = new("UIScale", {Scale = 1}, btn)
    local lbl = rowLabel(btn, text)
    lbl.Position = UDim2.new(0, 14, 0, 11)
    new("TextLabel", {
        Size = UDim2.new(0, 30, 1, 0), Position = UDim2.new(1, -36, 0, 0), BackgroundTransparency = 1,
        Text = "›", Font = Enum.Font.GothamBold, TextSize = 22, TextColor3 = Color3.fromRGB(120, 134, 170), ZIndex = 4,
    }, btn)
    hoverFx(btn, st)
    bind(btn.MouseButton1Down, function() tween(sc, 0.08, {Scale = 0.97}) end)
    bind(btn.MouseButton1Up, function() tween(sc, 0.12, {Scale = 1}) end)
    bind(btn.MouseLeave, function() tween(sc, 0.12, {Scale = 1}) end)
    bind(btn.MouseButton1Click, function()
        playClickSound()
        if callback then pcall(callback) end
    end)
    return btn
end

local function createToggle(page, text, default, callback, restoreOnLoad)
    local savedState = Settings.ToggleStates[text]
    local state = default and true or false
    if savedState ~= nil then state = (savedState == true) end
    local row, st = baseRow(page, "TextButton", 42)
    local label = rowLabel(row, text)
    label.Size = UDim2.new(1, -104, 0, 20)

    -- Geniş, cam/neon geçişli premium anahtar.
    local trackF = new("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.new(0, 48, 0, 24),
        BackgroundColor3 = Color3.fromRGB(38, 17, 23),
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 4,
    }, row)
    pill(trackF)
    local trackStroke = stroke(trackF, 1, Color3.fromRGB(130, 55, 65), 0.45)
    local onFill = new("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = state and 0 or 1,
        BorderSizePixel = 0,
        ZIndex = 5,
    }, trackF)
    pill(onFill)
    local onGradient = new("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(95, 5, 18)),
            ColorSequenceKeypoint.new(0.52, Color3.fromRGB(255, 28, 48)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 105, 55)),
        }),
        Rotation = 0,
    }, onFill)
    regFlow(UIFlows, onGradient, 0.15, 0.72, 58)

    local knob = new("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, state and 27 or 3, 0.5, 0),
        Size = UDim2.new(0, 18, 0, 18),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        ZIndex = 6,
    }, trackF)
    pill(knob)
    local knobStroke = stroke(knob, 1, Color3.fromRGB(255, 210, 210), 0.28)
    Pulsers[#Pulsers + 1] = {
        obj = trackStroke, prop = "Transparency", base = 0.28, amp = 0.13, speed = 2.8,
    }

    hoverFx(row, st)

    local obj = {}
    obj.Key = text
    function obj.Set(v, silent, skipSave)
        state = v and true or false
        if not skipSave then Settings.ToggleStates[text] = state end
        tween(onFill, 0.24, {BackgroundTransparency = state and 0 or 1}, Enum.EasingStyle.Quad)
        tween(knob, 0.28, {Position = UDim2.new(0, state and 27 or 3, 0.5, 0)}, Enum.EasingStyle.Quint)
        tween(trackStroke, 0.28, {
            Transparency = state and 0.12 or 0.55,
            Color = state and Color3.fromRGB(255, 45, 65) or Color3.fromRGB(105, 65, 72),
        }, Enum.EasingStyle.Quint)
        tween(knobStroke, 0.22, {
            Transparency = state and 0.05 or 0.28,
            Color = state and Color3.fromRGB(255, 110, 115) or Color3.fromRGB(255, 210, 210),
        }, Enum.EasingStyle.Quad)
        if not silent and callback then pcall(callback, state) end
        if not skipSave then saveConfig() end
    end
    bind(row.MouseButton1Click, function()
        playClickSound()
        obj.Set(not state)
    end)
    if restoreOnLoad ~= false and savedState == true and callback then
        task.defer(function()
            if alive then pcall(callback, true) end
        end)
    end
    return obj
end

local function createSlider(page, text, min, max, default, callback, suffix)
    local savedValue = Settings.SliderValues[text]
    local value = (type(savedValue) == "number") and math.clamp(savedValue, min, max) or default
    local row = baseRow(page, "Frame", 58)
    rowLabel(row, text).Position = UDim2.new(0, 14, 0, 8)
    local valueLabel = new("TextLabel", {
        Size = UDim2.new(0, 70, 0, 20), Position = UDim2.new(1, -84, 0, 8), BackgroundTransparency = 1,
        Text = "", Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = Color3.fromRGB(255, 65, 75),
        TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 4,
    }, row)
    local hit = new("TextButton", {
        Size = UDim2.new(1, -28, 0, 24), Position = UDim2.new(0, 14, 0, 28),
        BackgroundTransparency = 1, Text = "", ZIndex = 5,
    }, row)
    local trackF = new("Frame", {
        AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.new(1, 0, 0, 6),
        BackgroundColor3 = Color3.fromRGB(55, 20, 28), BorderSizePixel = 0, ZIndex = 5,
    }, hit)
    pill(trackF)
    local fill = new("Frame", {Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 6}, trackF)
    pill(fill)
    regFlow(UIFlows, new("UIGradient", {}, fill), 0, 0.7)
    local knob = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.new(0, 14, 0, 14),
        BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 7,
    }, trackF)
    pill(knob)

    local function render()
        local ratio = (value - min) / (max - min)
        fill.Size = UDim2.new(ratio, 0, 1, 0)
        knob.Position = UDim2.new(ratio, 0, 0.5, 0)
        setText(valueLabel, tostring(value) .. (suffix or ""))
    end
    render()

    local dragging = false
    local function setFromX(x)
        local ratio = math.clamp((x - trackF.AbsolutePosition.X) / math.max(trackF.AbsoluteSize.X, 1), 0, 1)
        local v = math.floor(min + (max - min) * ratio + 0.5)
        if v ~= value then
            value = v
            Settings.SliderValues[text] = value
            render()
            if callback then pcall(callback, value) end
            saveConfig()
        end
    end
    bind(hit.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            page.ScrollingEnabled = false
            setFromX(input.Position.X)
        end
    end)
    bind(UserInputService.InputChanged, function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            setFromX(input.Position.X)
        end
    end)
    bind(UserInputService.InputEnded, function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            dragging = false
            page.ScrollingEnabled = true
        end
    end)
    Settings.SliderValues[text] = value
    if savedValue ~= nil and callback then
        task.defer(function()
            if alive then pcall(callback, value) end
        end)
    end
    return row
end

---------------------------------------------------------
-- 6. KENAR ÇUBUĞU + İÇERİK ALANI
---------------------------------------------------------
local Sidebar = new("Frame", {
    Position = UDim2.new(0, 14, 0, 90), Size = UDim2.new(0, 154, 1, -104),
    BackgroundColor3 = Color3.fromRGB(9, 7, 10), BackgroundTransparency = 0.04,
    BorderSizePixel = 0, ZIndex = 2,
}, MainFrame)
corner(Sidebar, 16)
local SidebarStroke = stroke(Sidebar, 1, Color3.fromRGB(135, 28, 42), 0.38)
regFlow(UIFlows, new("UIGradient", {}, SidebarStroke), 1, 0.8, 24)
local SideTopGlow = new("Frame", {
    Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(1, -24, 0, 2),
    BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 3,
}, Sidebar)
regFlow(UIFlows, new("UIGradient", {}, SideTopGlow), 0, 0.7)
local TabList = new("Frame", {Position = UDim2.new(0, 9, 0, 12), Size = UDim2.new(1, -18, 1, -104), BackgroundTransparency = 1, ZIndex = 3}, Sidebar)
new("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6)}, TabList)

-- Yapımcı yazısı + fotoğraf + mavi tik (hareketli yazı, kırmızı aura)
do
local CREATOR_IMAGE_ID = 89633137402865
local TextService = game:GetService("TextService")

local CreatorContainer = new("Frame", {
    AnchorPoint = Vector2.new(0, 1),
    Position = UDim2.new(0, 8, 1, -34),
    Size = UDim2.new(1, -16, 0, 48),
    BackgroundTransparency = 1,
    ZIndex = 3,
}, Sidebar)

local CreatorPhoto = new("ImageLabel", {
    Size = UDim2.new(0, 42, 0, 42),
    Position = UDim2.new(0, 0, 0.5, 0),
    AnchorPoint = Vector2.new(0, 0.5),
    BackgroundColor3 = Color3.fromRGB(24, 30, 46),
    Image = CREATOR_IMAGE_ID ~= 0 and ("rbxassetid://" .. CREATOR_IMAGE_ID) or "",
    ScaleType = Enum.ScaleType.Crop,
    ZIndex = 4,
}, CreatorContainer)
pill(CreatorPhoto)
local CreatorPhotoStroke = stroke(CreatorPhoto, 2, Color3.fromRGB(255, 50, 60))
Pulsers[#Pulsers + 1] = {obj = CreatorPhotoStroke, prop = "Transparency", base = 0.3, amp = 0.25, speed = 3}

-- hasan_usta0 kullanıcısının Roblox avatar fotoğrafı (başarısız olursa yukarıdaki ID kalır)
task.spawn(function()
    local ok, userId = pcall(function()
        return Players:GetUserIdFromNameAsync("hasan_usta0")
    end)
    if ok and userId then
        local ok2, content = pcall(function()
            return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
        end)
        if ok2 and content and content ~= "" then
            CreatorPhoto.Image = content
        end
    end
end)

new("TextLabel", {
    Position = UDim2.new(0, 48, 0, 3),
    Size = UDim2.new(1, -48, 0, 12),
    BackgroundTransparency = 1,
    Text = "Yapımcı:",
    Font = Enum.Font.GothamMedium,
    TextSize = 9,
    TextColor3 = Color3.fromRGB(130, 145, 175),
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 3,
}, CreatorContainer)

-- Harf harf hareketli isim
local NAME_TEXT, NAME_SIZE = "Hasan Usta", 12
local NameHolder = new("Frame", {
    Position = UDim2.new(0, 48, 0, 18),
    Size = UDim2.new(0, 10, 0, 18),
    BackgroundTransparency = 1,
    ZIndex = 4,
}, CreatorContainer)

local nameLetters = {}
local nameW = 0
do
    local idx = 0
    for _, cp in utf8.codes(NAME_TEXT) do
        local ch = utf8.char(cp)
        local ok, size = pcall(function()
            return TextService:GetTextSize(ch, NAME_SIZE, Enum.Font.GothamBlack, Vector2.new(200, 50))
        end)
        local w = (ok and size.X) or 8
        if ch ~= " " then
            local lbl = new("TextLabel", {
                Position = UDim2.new(0, nameW, 0, 0),
                Size = UDim2.new(0, w, 1, 0),
                BackgroundTransparency = 1,
                Text = ch,
                Font = Enum.Font.GothamBlack,
                TextSize = NAME_SIZE,
                TextColor3 = Color3.fromRGB(255, 50, 60),
                ZIndex = 5,
            }, NameHolder)
            -- Harflerin çevresindeki kırmızı kontur kaldırıldı.
            nameLetters[#nameLetters + 1] = {
                lbl = lbl,
                i = idx,
                x = nameW,
                currentY = 0,
                currentColor = Color3.fromRGB(255, 50, 60),
            }
        end
        nameW = nameW + w
        idx = idx + 1
    end
end
NameHolder.Size = UDim2.new(0, nameW, 0, 18)

-- Yazının çevresindeki kırmızı çerçeve/aura kaldırıldı.
-- NameHolder ve harf etiketleri arka plansız kalır.
NameHolder.BackgroundTransparency = 1

-- Mavi tik yerine kullanıcının verdiği özel rozet görseli
local VerifiedBadge = new("ImageLabel", {
    Position = UDim2.new(0, nameW + 5, 0, 1),
    Size = UDim2.new(0, 17, 0, 17),
    BackgroundTransparency = 1,
    Image = "rbxassetid://100936935753681",
    ScaleType = Enum.ScaleType.Fit,
    ZIndex = 6,
}, NameHolder)

-- Hasan Usta yazısı: takılma hissini azaltan yumuşak, sürekli harf dalgası.
local RED_A, RED_B = Color3.fromRGB(225, 55, 65), Color3.fromRGB(255, 125, 125)
local NAME_WAVE_SPEED = 3.0
local NAME_WAVE_SPACING = 0.43
local NAME_WAVE_HEIGHT = 1.65
local NAME_SMOOTHNESS = 13

bind(RunService.RenderStepped, function(dt)
    if not menuOpen then return end
    local t = os.clock()
    -- Kare hızından bağımsız üstel yumuşatma; ani konum sıçramalarını engeller.
    local alpha = 1 - math.exp(-NAME_SMOOTHNESS * math.min(dt, 0.05))
    for _, L in ipairs(nameLetters) do
        local targetY = math.sin(t * NAME_WAVE_SPEED - L.i * NAME_WAVE_SPACING) * NAME_WAVE_HEIGHT
        L.currentY = L.currentY + (targetY - L.currentY) * alpha
        L.lbl.Position = UDim2.new(0, L.x, 0, L.currentY)

        local colorPhase = (math.sin(t * 1.8 - L.i * 0.34) + 1) * 0.5
        local targetColor = RED_A:Lerp(RED_B, colorPhase * 0.48)
        L.currentColor = L.currentColor:Lerp(targetColor, alpha)
        L.lbl.TextColor3 = L.currentColor
    end
end)

-- Yazıdan yukarı doğru saçılan kırmızı aura parçacıkları
task.spawn(function()
    while alive do
        task.wait(0.1)
        if menuOpen and MainFrame.Visible then
            local sz = math.random(2, 4)
            local px = math.random(0, math.max(1, math.floor(nameW)))
            local p = new("Frame", {
                Size = UDim2.new(0, sz, 0, sz),
                Position = UDim2.new(0, px, 0, 8),
                BackgroundColor3 = Color3.fromRGB(205, math.random(35, 65), math.random(45, 70)),
                BackgroundTransparency = 0.55,
                BorderSizePixel = 0,
                ZIndex = 3,
            }, NameHolder)
            pill(p)
            local dur = math.random(8, 15) / 10
            tween(p, dur, {
                Position = UDim2.new(0, px + math.random(-8, 8), 0, -16 - math.random(0, 10)),
                BackgroundTransparency = 1,
                Size = UDim2.new(0, 0, 0, 0),
            }, Enum.EasingStyle.Sine)
            task.delay(dur, function() p:Destroy() end)
        end
    end
end)

end

local SidebarKeyHint = new("TextLabel", {
    AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 8, 1, -4), Size = UDim2.new(1, -16, 0, 22),
    BackgroundTransparency = 1, Text = Settings.ToggleKey.Name .. "  •  menüyü aç / kapat", Font = Enum.Font.GothamMedium,
    TextSize = 10, TextColor3 = Color3.fromRGB(100, 112, 145), TextWrapped = true, ZIndex = 3,
}, Sidebar)

local Content = new("Frame", {
    Position = UDim2.new(0, 180, 0, 90), Size = UDim2.new(1, -194, 1, -104),
    BackgroundColor3 = Color3.fromRGB(9, 13, 25), BackgroundTransparency = 0.18,
    ClipsDescendants = true, BorderSizePixel = 0, ZIndex = 2,
}, MainFrame)
corner(Content, 16)
local ContentStroke = stroke(Content, 1, Color3.fromRGB(55, 70, 105), 0.58)
regFlow(UIFlows, new("UIGradient", {}, ContentStroke), 2, 0.85, -20)
local ContentTopLine = new("Frame", {
    Position = UDim2.new(0, 16, 0, 0), Size = UDim2.new(1, -32, 0, 2),
    BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 4,
}, Content)
regFlow(UIFlows, new("UIGradient", {}, ContentTopLine), 1, 0.7, 28)

local function createPage()
    local page = new("ScrollingFrame", {
        Position = UDim2.new(0, 0, 0, 5),
        Size = UDim2.new(1, 0, 1, -10),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Color3.fromRGB(220, 42, 58),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Visible = false,
        ZIndex = 3,
    }, Content)
    new("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8)}, page)
    -- Tüm sekmelerde içerikleri yatayda eşit iç boşlukla hizala.
    -- Önceden yalnızca sağ boşluk vardı; sol kart kenarı çerçeveye yapışıyordu.
    new("UIPadding", {
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
        PaddingTop = UDim.new(0, 8),
        PaddingBottom = UDim.new(0, 10),
    }, page)
    return page
end

local Tabs, currentTab = {}, nil
local TAB_OFF = Color3.fromRGB(154, 143, 148)
local TAB_RED = Color3.fromRGB(255, 48, 65)

local function selectTab(tab)
    if currentTab == tab then return end
    currentTab = tab
    for _, t in ipairs(Tabs) do
        local on = (t == tab)
        tween(t.btn, 0.22, {
            BackgroundTransparency = on and 0.04 or 1,
            BackgroundColor3 = on and Color3.fromRGB(67, 12, 23) or Color3.fromRGB(20, 10, 14),
        })
        tween(t.label, 0.2, {
            TextColor3 = on and Color3.fromRGB(255, 246, 246) or TAB_OFF,
            TextSize = on and 13 or 12,
        })
        tween(t.iconPlate, 0.22, {
            BackgroundColor3 = on and Color3.fromRGB(190, 18, 42) or Color3.fromRGB(65, 8, 20),
            BackgroundTransparency = on and 0.02 or 0.18,
        })
        if t.iconPlateStroke then
            tween(t.iconPlateStroke, 0.22, {
                Color = on and Color3.fromRGB(255, 115, 125) or Color3.fromRGB(255, 55, 72),
                Transparency = on and 0.12 or 0.34,
            })
        end
        tween(t.iconLabel, 0.22, {
            TextColor3 = on and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(225, 105, 115),
            TextTransparency = on and 0 or 0.12,
        })
        tween(t.ind, 0.25, {Size = UDim2.new(0, 4, 0, on and 27 or 0)}, Enum.EasingStyle.Back)
        tween(t.stroke, 0.22, {
            Transparency = on and 0.22 or 0.78,
            Color = on and Color3.fromRGB(255, 54, 72) or Color3.fromRGB(110, 35, 48),
        })
        if on then
            t.page.Position = UDim2.new(0, 0, 0, 15)
            t.page.Visible = true
            t.page.ScrollBarImageTransparency = 0.45
            tween(t.page, 0.34, {
                Position = UDim2.new(0, 0, 0, 5),
                ScrollBarImageTransparency = 0,
            }, Enum.EasingStyle.Quint)
        else
            t.page.Visible = false
        end
    end
end

local function createTab(name, icon)
    local page = createPage()
    local btn = new("TextButton", {
        LayoutOrder = #Tabs + 1,
        Size = UDim2.new(1, 0, 0, 42),
        BackgroundColor3 = Color3.fromRGB(20, 10, 14),
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        Text = "",
        ZIndex = 3,
    }, TabList)
    corner(btn, 13)

    local btnStroke = stroke(btn, 1, Color3.fromRGB(110, 35, 48), 0.78)
    new("UIGradient", {
        Rotation = 0,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(72, 12, 25)),
            ColorSequenceKeypoint.new(0.55, Color3.fromRGB(39, 10, 17)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(22, 9, 14)),
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.12),
            NumberSequenceKeypoint.new(1, 0.48),
        }),
    }, btn)

    local ind = new("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(0, 4, 0, 0),
        BackgroundColor3 = TAB_RED,
        BorderSizePixel = 0,
        ZIndex = 5,
    }, btn)
    pill(ind)
    local indGlow = stroke(ind, 3, Color3.fromRGB(255, 35, 58), 0.45)

    local iconPlate = new("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 10, 0.5, 0),
        Size = UDim2.new(0, 29, 0, 29),
        BackgroundColor3 = Color3.fromRGB(35, 15, 21),
        BackgroundTransparency = 0.38,
        BorderSizePixel = 0,
        ZIndex = 4,
    }, btn)
    corner(iconPlate, 99)
    local iconPlateStroke = stroke(iconPlate, 1, Color3.fromRGB(255, 55, 72), 0.34)
    local iconPlateGradient = new("UIGradient", {
        Rotation = 35,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(75, 5, 18)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(185, 15, 38)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(45, 7, 15)),
        }),
    }, iconPlate)
    regFlow(UIFlows, iconPlateGradient, 0.18, 0.82, 24)
    Pulsers[#Pulsers + 1] = {
        obj = iconPlateStroke, prop = "Transparency",
        base = 0.34, amp = 0.18, speed = 2.4,
    }

    local iconLabel = new("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = icon,
        Font = Enum.Font.GothamBold,
        TextSize = 15,
        TextColor3 = Color3.fromRGB(225, 105, 115),
        ZIndex = 5,
    }, iconPlate)

    -- Sekme simgeleri ana sayfadaki gibi tek renkli, sade ve net karakterlerdir.
    -- Özellikler: ✦ yıldız, Ayarlar: ☰ liste; Ana Sayfa ⌂ ile aynı sade, tek renkli stil.
    iconLabel.TextColor3 = Color3.fromRGB(255, 75, 85)
    iconLabel.TextSize = (name == "Troll") and 19 or 17

    -- Özellikler ve Ayarlar simgeleri yazı tipinde kutu çıktığı için çizgi çizgi
    -- (UI parçalarıyla) çizilir: Özellikler = parıltı, Ayarlar = dişli.
    local drawnKind = (name == "Özellikler" and "sparkle") or (name == "Ayarlar" and "gear")
        or (name == "Premium" and "crown") or (name == "Yönetim" and "lock") or nil
    if drawnKind then
        setText(iconLabel, "")
        local holder = new("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(0, 20, 0, 20),
            BackgroundTransparency = 1,
            ZIndex = 5,
        }, iconPlate)
        local fills, strokes = {}, {}
        local function bar(w, h, x, y, rot)
            local f = new("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0.5, x, 0.5, y),
                Size = UDim2.new(0, w, 0, h),
                Rotation = rot or 0,
                BackgroundColor3 = iconLabel.TextColor3,
                BorderSizePixel = 0,
                ZIndex = 5,
            }, holder)
            fills[#fills + 1] = f
            return f
        end
        if drawnKind == "sparkle" then
            bar(2, 17, 0, 0, 0)
            bar(17, 2, 0, 0, 0)
            bar(2, 12, 0, 0, 45)
            bar(2, 12, 0, 0, -45)
        elseif drawnKind == "crown" then
            bar(14, 3, 0, 6, 0)
            bar(2, 11, -5, 0, -16)
            bar(2, 13, 0, -1, 0)
            bar(2, 11, 5, 0, 16)
            for _, d in ipairs({{-7, -6}, {0, -8}, {7, -6}}) do
                pill(bar(4, 4, d[1], d[2], 0))
            end
        elseif drawnKind == "lock" then
            local shackle = new("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0.5, 0, 0.5, -4),
                Size = UDim2.new(0, 10, 0, 10),
                BackgroundTransparency = 1,
                ZIndex = 5,
            }, holder)
            pill(shackle)
            strokes[#strokes + 1] = stroke(shackle, 2, iconLabel.TextColor3, 0)
            corner(bar(14, 9, 0, 4, 0), 2)
        else
            local ring = new("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                Size = UDim2.new(0, 12, 0, 12),
                BackgroundTransparency = 1,
                ZIndex = 5,
            }, holder)
            pill(ring)
            strokes[#strokes + 1] = stroke(ring, 2, iconLabel.TextColor3, 0)
            for i = 0, 7 do
                local a = math.rad(i * 45)
                bar(4, 3, math.cos(a) * 8, math.sin(a) * 8, i * 45)
            end
        end
        local function syncDrawnIcon()
            for _, f in ipairs(fills) do
                f.BackgroundColor3 = iconLabel.TextColor3
                f.BackgroundTransparency = iconLabel.TextTransparency
            end
            for _, st in ipairs(strokes) do
                st.Color = iconLabel.TextColor3
                st.Transparency = iconLabel.TextTransparency
            end
        end
        iconLabel:GetPropertyChangedSignal("TextColor3"):Connect(syncDrawnIcon)
        iconLabel:GetPropertyChangedSignal("TextTransparency"):Connect(syncDrawnIcon)
    end


    local label = new("TextLabel", {
        Size = UDim2.new(1, -54, 1, 0),
        Position = UDim2.new(0, 48, 0, 0),
        BackgroundTransparency = 1,
        Text = name,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = TAB_OFF,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 4,
    }, btn)

    local tab = {
        btn = btn, label = label, iconPlate = iconPlate,
        iconLabel = iconLabel, iconPlateStroke = iconPlateStroke,
        ind = ind, stroke = btnStroke, page = page,
    }
    Tabs[#Tabs + 1] = tab
    local tabScale = new("UIScale", {Scale = 1}, btn)

    bind(btn.MouseEnter, function()
        if currentTab ~= tab then
            tween(btn, 0.16, {BackgroundTransparency = 0.55, BackgroundColor3 = Color3.fromRGB(48, 12, 22)})
            tween(tabScale, 0.16, {Scale = 1.025}, Enum.EasingStyle.Quad)
            tween(iconPlate, 0.16, {BackgroundTransparency = 0.12})
            playSound(1.35, 0.1)
        end
    end)
    bind(btn.MouseLeave, function()
        if currentTab ~= tab then
            tween(btn, 0.16, {BackgroundTransparency = 1})
            tween(tabScale, 0.16, {Scale = 1}, Enum.EasingStyle.Quad)
            tween(iconPlate, 0.16, {BackgroundTransparency = 0.38})
        end
    end)
    bind(btn.MouseButton1Click, function()
        playClickSound()
        selectTab(tab)
    end)
    return page, tab
end

---------------------------------------------------------
-- SAĞ DIŞ ALANDA TAM BOY KARAKTER + FAREYİ TAKİP EDEN KAFA
---------------------------------------------------------
local MenuCharViewport = new("ViewportFrame", {
    AnchorPoint = Vector2.new(0, 0.5),
    Position = UDim2.new(1, -22, 0.5, 0),
    Size = UDim2.new(0, 340, 1, 120), -- daha uzun: karakter daha büyük görünür
    BackgroundTransparency = 1,
    Ambient = Color3.fromRGB(200, 200, 200),
    LightColor = Color3.new(1, 1, 1),
    Visible = false,
    Active = true, -- ViewportFrame fare/tıklama girdilerini alabilsin
    ZIndex = 15,
}, MainFrame)

local refreshMenuAvatar = nil
do
local menuCharModel, menuCam = nil, nil
local menuCharBasePivot = nil
local headGroup, armGroup = {}, {}
local neckPos, shoulderPos = nil, nil
local menuHrpRot = CFrame.new()
local headYaw, headPitch = 0, 0
local buildSeq = 0
local onAvatarSwapped = nil

-- plr verilmezse kendi karakterim; verilirse o oyuncunun karakteri gösterilir.
local function buildMenuAvatar(plr)
    plr = plr or LocalPlayer
    buildSeq = buildSeq + 1
    local mySeq = buildSeq
    local clone = nil
    local okBuild, errBuild = pcall(function()
        local char = plr.Character
        if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Head") then
            local wasArch = char.Archivable
            char.Archivable = true
            clone = char:Clone()
            char.Archivable = wasArch
        end
        -- Karakteri yüklü değilse (uzaktaysa) avatarını Roblox'tan oluştur
        if not clone and plr ~= LocalPlayer then
            local okModel, model = pcall(function()
                return Players:CreateHumanoidModelFromUserId(plr.UserId)
            end)
            if okModel then clone = model end
        end
        if not clone then return end
        -- Bu arada daha yeni bir önizleme istendiyse eskisini bırak
        if mySeq ~= buildSeq then clone:Destroy() return end
        for _, d in ipairs(clone:GetDescendants()) do
            -- Humanoid nesnesi kıyafetlerin ve avatar görünümünün ViewportFrame'de
            -- doğru çizilmesi için korunur; yalnızca çalıştırılabilir scriptler silinir.
            if d:IsA("LuaSourceContainer") then d:Destroy() end
        end

        local previewHumanoid = clone:FindFirstChildOfClass("Humanoid")
        if previewHumanoid then
            previewHumanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
            previewHumanoid.AutoRotate = false
            previewHumanoid.BreakJointsOnDeath = false

            -- Klonun oyuncudan kopyalanan koşma/yürüme animasyonlarını durdur.
            local animator = previewHumanoid:FindFirstChildOfClass("Animator")
            if animator then animator:Destroy() end
            pcall(function() previewHumanoid:ChangeState(Enum.HumanoidStateType.Physics) end)
        end

        -- Önce Viewport'a yerleştirip Motor6D pozlarını nötrle; böylece klon,
        -- oyuncunun o anki koşma/zıplama pozunda takılı kalmaz.
        clone.Parent = MenuCharViewport
        for _, joint in ipairs(clone:GetDescendants()) do
            if joint:IsA("Motor6D") then
                joint.Transform = CFrame.identity
            end
        end
        RunService.Heartbeat:Wait()
        if mySeq ~= buildSeq then clone:Destroy() return end

        local hrp = clone:FindFirstChild("HumanoidRootPart")
        local head = clone:FindFirstChild("Head")
        if not (hrp and head) then clone:Destroy() return end

        -- Önizleme karakterini her seferinde aynı dik, öne bakan yöne çevir.
        local rootPosition = hrp.Position
        local targetRoot = CFrame.new(rootPosition)
        local poseCorrection = targetRoot * hrp.CFrame:Inverse()
        clone:PivotTo(poseCorrection * clone:GetPivot())

        local isR15 = clone:FindFirstChild("UpperTorso") ~= nil
        local function motor(name)
            local m = clone:FindFirstChild(name, true)
            return (m and m:IsA("Motor6D")) and m or nil
        end
        local neck = motor("Neck")
        local shoulder = motor("RightShoulder") or motor("Right Shoulder")

        -- Dönme merkezleri (eklem konumları) eklemler silinmeden önce hesaplanır
        local nPos = head.Position - head.CFrame.UpVector * (head.Size.Y * 0.5)
        if neck and neck.Part0 then nPos = (neck.Part0.CFrame * neck.C0).Position end
        local sPos = nil
        if shoulder and shoulder.Part0 then sPos = (shoulder.Part0.CFrame * shoulder.C0).Position end

        local newHead, newArm = {}, {}
        local function addTo(list, part)
            list[#list + 1] = {part = part, cf = part.CFrame}
        end
        addTo(newHead, head)
        for _, acc in ipairs(clone:GetChildren()) do
            if acc:IsA("Accessory") then
                local handle = acc:FindFirstChild("Handle")
                if handle and handle:IsA("BasePart") then
                    local onHead = false
                    for _, j in ipairs(handle:GetChildren()) do
                        if j:IsA("JointInstance") or j:IsA("WeldConstraint") then
                            if j.Part0 == head or j.Part1 == head then
                                onHead = true
                                j:Destroy()
                            end
                        end
                    end
                    if onHead then addTo(newHead, handle) end
                end
            end
        end
        for _, n in ipairs(isR15 and {"RightUpperArm", "RightLowerArm", "RightHand"} or {"Right Arm"}) do
            local p = clone:FindFirstChild(n)
            if p and p:IsA("BasePart") then addTo(newArm, p) end
        end

        -- Eklemleri kaldır: parçaları kendimiz döndüreceğiz (ViewportFrame'de eklemlere güvenilmez)
        if neck then neck:Destroy() end
        if shoulder then shoulder:Destroy() end
        for _, n in ipairs({"RightElbow", "RightWrist"}) do
            local m = motor(n)
            if m then m:Destroy() end
        end
        for _, d in ipairs(clone:GetDescendants()) do
            if d:IsA("BasePart") then d.Anchored = true end
        end

        -- Kamera: karakterin tamamı (baştan ayağa) görünsün
        local bbCF, bbSize = clone:GetBoundingBox()
        -- Sabit ön görünüş: oyuncu oyunda hangi yöne dönük olursa olsun aynı açı.
        local look = Vector3.new(0, 0, -1)

        local fov = 34
        local abs = MenuCharViewport.AbsoluteSize
        local aspect = (abs.Y > 10) and (abs.X / abs.Y) or 0.64
        local halfV = math.rad(fov / 2)
        local halfH = math.atan(math.tan(halfV) * aspect)
        local distH = (bbSize.Y * 0.5 * 1.08) / math.tan(halfV)
        local distW = (2.4 * 1.05) / math.tan(halfH) -- kol kalkınca genişlik payı
        local dist = math.max(distH, distW) + bbSize.Z * 0.5

        local cam = Instance.new("Camera")
        cam.FieldOfView = fov
        cam.CFrame = CFrame.lookAt(bbCF.Position + look * dist, bbCF.Position)
        cam.Parent = MenuCharViewport
        MenuCharViewport.CurrentCamera = cam

        -- Her şey hazır: eski modeli ancak şimdi kaldır, yenisini devreye al
        local oldModel, oldCam = menuCharModel, menuCam
        menuCharModel = clone
        menuCharBasePivot = clone:GetPivot()
        headGroup, armGroup = newHead, newArm
        neckPos, shoulderPos = nPos, sPos
        menuHrpRot = hrp.CFrame - hrp.CFrame.Position
        menuCam = cam
        if oldModel and oldModel ~= clone then pcall(function() oldModel:Destroy() end) end
        if oldCam and oldCam ~= cam then pcall(function() oldCam:Destroy() end) end
        if onAvatarSwapped then onAvatarSwapped() end
    end)
    if not okBuild then
        warn("[EZRAGOX] Önizleme hatası: " .. tostring(errBuild))
        if clone and clone ~= menuCharModel then pcall(function() clone:Destroy() end) end
        if menuCam and menuCam.Parent == MenuCharViewport then
            MenuCharViewport.CurrentCamera = menuCam
        end
    end
end
refreshMenuAvatar = buildMenuAvatar
task.spawn(function()
    if not LocalPlayer.Character then LocalPlayer.CharacterAdded:Wait() end
    buildMenuAvatar()
end)

-- Karakter fareyle sürüklenirken yumuşak döner; hızlı bırakmada ataletle
-- bir süre hızlı dönüp kademeli olarak normal dönüş hızına iner.
local AVATAR_TURN_SPEED = math.rad(32)
local AVATAR_DRAG_SENSITIVITY = 0.012
local AVATAR_SMOOTHNESS = 16
local AVATAR_MAX_DRAG_SPEED = math.rad(720)
local AVATAR_INERTIA_DECAY = 2.8

local avatarTurnAngle = 0
local avatarTargetAngle = 0
local avatarDragging = false
local avatarLastMouseX = nil
local avatarLastInputTime = nil
local avatarDragVelocity = 0
local avatarAngularVelocity = AVATAR_TURN_SPEED

-- Karakter değişince yeni karakter öne bakarak baştan dönmeye başlar.
onAvatarSwapped = function()
    avatarTurnAngle = 0
    avatarTargetAngle = 0
    avatarAngularVelocity = AVATAR_TURN_SPEED
end

-- Menü açıkken her 5 saniyede bir kısa el sallama hareketi.
local AVATAR_WAVE_INTERVAL = 5
local AVATAR_WAVE_DURATION = 1.25
local nextAvatarWaveAt = os.clock() + AVATAR_WAVE_INTERVAL
local avatarWaveStartedAt = nil

local function wrapAngleDelta(a)
    return (a + math.pi) % (math.pi * 2) - math.pi
end

bind(MenuCharViewport.InputBegan, function(input)
    if not menuOpen or not MenuCharViewport.Visible then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        avatarDragging = true
        avatarLastMouseX = input.Position.X
        avatarLastInputTime = os.clock()
        avatarDragVelocity = 0
        avatarAngularVelocity = 0
    end
end)

bind(UserInputService.InputChanged, function(input)
    if not avatarDragging or not menuOpen then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement and avatarLastMouseX then
        local now = os.clock()
        local deltaX = input.Position.X - avatarLastMouseX
        local elapsed = math.max(now - (avatarLastInputTime or now), 1 / 240)
        avatarLastMouseX = input.Position.X
        avatarLastInputTime = now

        -- Pozitif fare hareketi karakteri aynı yönde çevirir.
        local angleDelta = deltaX * AVATAR_DRAG_SENSITIVITY
        avatarTargetAngle = avatarTargetAngle + angleDelta
        local measuredVelocity = math.clamp(angleDelta / elapsed, -AVATAR_MAX_DRAG_SPEED, AVATAR_MAX_DRAG_SPEED)
        avatarDragVelocity = avatarDragVelocity * 0.35 + measuredVelocity * 0.65
    end
end)

bind(UserInputService.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 and avatarDragging then
        avatarDragging = false
        avatarLastMouseX = nil
        avatarLastInputTime = nil
        -- Bırakıldığı andaki hız korunur; RenderStepped bunu yumuşakça azaltır.
        avatarAngularVelocity = math.clamp(avatarDragVelocity, -AVATAR_MAX_DRAG_SPEED, AVATAR_MAX_DRAG_SPEED)
    end
end)

bind(RunService.RenderStepped, function(dt)
    if not menuOpen or not menuCharModel or not menuCharModel.Parent or not menuCharBasePivot then return end
    pcall(function()
        if avatarDragging then
            local difference = wrapAngleDelta(avatarTargetAngle - avatarTurnAngle)
            local alpha = 1 - math.exp(-AVATAR_SMOOTHNESS * dt)
            avatarTurnAngle = avatarTurnAngle + difference * alpha
        else
            -- Atalet hızı normal dönüş hızına doğru üstel olarak yaklaşır.
            local decay = math.exp(-AVATAR_INERTIA_DECAY * dt)
            avatarAngularVelocity = AVATAR_TURN_SPEED + (avatarAngularVelocity - AVATAR_TURN_SPEED) * decay
            avatarTurnAngle = avatarTurnAngle + avatarAngularVelocity * dt
            avatarTargetAngle = avatarTurnAngle
        end

        local currentPivot = menuCharBasePivot * CFrame.Angles(0, avatarTurnAngle, 0)
        menuCharModel:PivotTo(currentPivot)

        -- Kol parçaları, karakterin mevcut dönüş açısı korunarak omuzdan hareket ettirilir.
        if #armGroup > 0 and shoulderPos then
            local now = os.clock()
            if not avatarWaveStartedAt and now >= nextAvatarWaveAt then
                avatarWaveStartedAt = now
                nextAvatarWaveAt = now + AVATAR_WAVE_INTERVAL
            end

            local waveAngle = 0
            local waveWiggle = 0
            if avatarWaveStartedAt then
                local elapsed = now - avatarWaveStartedAt
                if elapsed >= AVATAR_WAVE_DURATION then
                    avatarWaveStartedAt = nil
                else
                    local progress = math.clamp(elapsed / AVATAR_WAVE_DURATION, 0, 1)
                    -- Yumuşak giriş/çıkış; kol belirgin biçimde kalkar ve birkaç kez sallar.
                    local envelope = math.sin(progress * math.pi)
                    waveAngle = math.rad(125) * envelope
                    waveWiggle = math.rad(30) * math.sin(elapsed * 17) * envelope
                end
            end

            local modelDelta = currentPivot * menuCharBasePivot:Inverse()
            local shoulderWorld = modelDelta:PointToWorldSpace(shoulderPos)
            local characterRotation = modelDelta.Rotation * menuHrpRot
            -- Omuz ekseni karakterin yerel Z eksenidir; bilek/kol grubu beraber hareket eder.
            local armRotation = characterRotation
                * CFrame.Angles(0, 0, waveAngle + waveWiggle)
                * characterRotation:Inverse()
            local shoulderTransform = CFrame.new(shoulderWorld) * armRotation * CFrame.new(-shoulderWorld)

            for _, entry in ipairs(armGroup) do
                if entry.part and entry.part.Parent then
                    entry.part.CFrame = shoulderTransform * modelDelta * entry.cf
                end
            end
        end
    end)
end)
end

---------------------------------------------------------
-- 7. MİNİ LOGO
---------------------------------------------------------
-- Küçültülmüş arayüz düğmesinde yalnızca ana logo görseli kullanılır.
local MiniLogo = new("ImageButton", {
    AnchorPoint = Vector2.new(0.5, 0),
    Size = UDim2.new(0, 190, 0, 46),
    Position = UDim2.new(0.5, 0, 0, 24),
    BackgroundTransparency = 1,
    AutoButtonColor = false,
    Image = "rbxassetid://84152160938421",
    ScaleType = Enum.ScaleType.Fit,
    ImageTransparency = 0,
    Visible = false,
    ZIndex = 10,
}, ScreenGui)
local MiniScale = new("UIScale", {Scale = 1}, MiniLogo)
task.spawn(function()
    local cp = game:GetService("ContentProvider")
    pcall(function() cp:PreloadAsync({MiniLogo}) end)
    if not MiniLogo.IsLoaded then
        MiniLogo.Image = "rbxthumb://type=Asset&id=84152160938421&w=420&h=420"
        pcall(function() cp:PreloadAsync({MiniLogo}) end)
    end
end)
local miniMoved = makeDraggable(MiniLogo, MiniLogo)

---------------------------------------------------------
-- 8. MENÜ AÇ / KAPAT & TEMİZLİK YÖNETİMİ
---------------------------------------------------------
local function menuScale()
    -- Ekranın dört kenarında güvenli boşluk bırak; glow dahil panel sığsın.
    return getScale(W + 72, H + 72, 0.42) * Settings.Scale
end

-- Menü ilk kez açıldığında bir kez çalacak karşılama sesi.
-- Menü kapatılıp tekrar açıldığında yeniden tetiklenmez.
local menuIntroSoundPlayed = false
local function playMenuIntroSoundOnce()
    if menuIntroSoundPlayed then return end
    menuIntroSoundPlayed = true

    task.spawn(function()
        local sound
        local ok = pcall(function()
            sound = Instance.new("Sound")
            sound.Name = "EZRAGOX_MenuWelcomeSound"
            sound.SoundId = "rbxassetid://118900643276596"
            sound.Volume = 0.85
            sound.Looped = false
            sound.Parent = SoundService

            game:GetService("ContentProvider"):PreloadAsync({sound})

            local startedAt = os.clock()
            while sound.Parent and not sound.IsLoaded and os.clock() - startedAt < 10 do
                task.wait(0.1)
            end

            if sound.Parent and sound.IsLoaded then
                sound:Play()
                sound.Ended:Connect(function()
                    if sound then sound:Destroy() end
                end)
            else
                warn("[EZRAGOX HUB] Menü karşılama sesi yüklenemedi: 118900643276596")
                sound:Destroy()
            end
        end)

        if not ok then
            if sound then pcall(function() sound:Destroy() end) end
            warn("[EZRAGOX HUB] Menü karşılama sesi başlatılamadı.")
        end
    end)
end

local function setMenu(open)
    if open == menuOpen or not ready then return end
    menuOpen = open
    playClickSound()
    if open then
        MiniLogo.Visible = false
        MainFrame.Visible = true
        MenuCharViewport.Visible = true
        if refreshMenuAvatar then
            task.spawn(function()
                if alive and menuOpen then
                    refreshMenuAvatar()
                end
            end)
        end
        MainScale.Scale = menuScale() * 0.8
        tween(MainScale, 0.48, {Scale = menuScale()}, Enum.EasingStyle.Back)
        if Settings.Blur then
            blurEffect.Enabled = true
            tween(blurEffect, 0.3, {Size = 12})
        end
    else
        MenuCharViewport.Visible = false
        tween(MainScale, 0.26, {Scale = menuScale() * 0.78}, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        tween(blurEffect, 0.2, {Size = 0})
        task.delay(0.2, function()
            if alive and not menuOpen then
                MainFrame.Visible = false
                blurEffect.Enabled = false
                MiniLogo.Visible = true
                MiniScale.Scale = 0.6
                tween(MiniScale, 0.3, {Scale = 1}, Enum.EasingStyle.Back)
            end
        end)
    end
end

local function closeAll()
    if not alive then return end
    alive = false
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    -- ESP işaretlerini (yeşil çerçeve + isimler) temizle
    pcall(function()
        local host = ScreenGui.Parent
        local f = host and host:FindFirstChild("EZRAGOX_ESP")
        if f then f:Destroy() end
    end)
    -- Başka bir oyuncuyu izliyorsak kamerayı kendi karakterimize geri ver
    pcall(function()
        local cam = workspace.CurrentCamera
        local myChar = LocalPlayer.Character
        local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
        if cam and myHum and cam.CameraSubject ~= myHum then
            cam.CameraSubject = myHum
        end
    end)
    tween(MainScale, 0.2, {Scale = 0.05}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    tween(blurEffect, 0.2, {Size = 0})
    task.delay(0.3, function()
        pcall(function() blurEffect:Destroy() end)
        pcall(function() cc:Destroy() end)
        pcall(function() ScreenGui:Destroy() end)
    end)
end

if getgenv then
    getgenv().EZRAGOX_HUB_CLEANUP = closeAll
end

bind(MinimizeBtn.MouseButton1Click, function() setMenu(false) end)
bind(CloseBtn.MouseButton1Click, function()
    playClickSound()
    closeAll()
end)
bind(MiniLogo.Activated, function()
    if miniMoved() then return end
    setMenu(true)
end)

bind(UserInputService.InputBegan, function(input, gpe)
    if gpe or not ready then return end
    if listeningForKey then
        if input.UserInputType == Enum.UserInputType.Keyboard then
            Settings.ToggleKey = input.KeyCode
            listeningForKey = false
            if updateKeyTextCallback then
                updateKeyTextCallback(Settings.ToggleKey.Name)
            end
            setText(SidebarKeyHint, Settings.ToggleKey.Name .. "  •  menüyü aç / kapat")
            saveConfig()
            notify("Menü Tuşu Değiştirildi", "Yeni kısayol: " .. Settings.ToggleKey.Name, 3)
        end
        return
    end

    if listeningFlyKey then
        if input.UserInputType == Enum.UserInputType.Keyboard then
            Settings.FlyKey = input.KeyCode
            listeningFlyKey = false
            if updateFlyKeyTextCallback then
                updateFlyKeyTextCallback(Settings.FlyKey.Name)
            end
            saveConfig()
            notify("Fly Tuşu Değiştirildi", "Yeni Fly tuşu: " .. Settings.FlyKey.Name, 3)
        end
        return
    end

    if input.KeyCode == Settings.ToggleKey then
        setMenu(not menuOpen)
    end
end)

---------------------------------------------------------
-- 9. SAYFALAR
---------------------------------------------------------
local HomePage = createTab("Ana Sayfa", "⌂")
local FeaturesPage = createTab("Özellikler", "")
local TrollPage = createTab("Troll", "ツ")
local PremiumPage, PremiumTab = createTab("Premium", "")
local SettingsPage = createTab("Ayarlar", "")
local AdminPage, AdminTab = createTab("Yönetim", "")

-- ANA SAYFA
do
    local card = new("Frame", {
        LayoutOrder = nextOrder(HomePage), Size = UDim2.new(1, 0, 0, 102),
        BackgroundColor3 = Color3.fromRGB(17, 24, 42), BorderSizePixel = 0, ZIndex = 3,
    }, HomePage)
    corner(card, 14)
    local cs = stroke(card, 1.5, Color3.new(1, 1, 1), 0.25)
    regFlow(UIFlows, new("UIGradient", {}, cs), 2, 0.9, 50)

    local av = new("Frame", {
        Position = UDim2.new(0, 14, 0, 16), Size = UDim2.new(0, 68, 0, 68),
        BackgroundColor3 = Color3.fromRGB(24, 30, 46), BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 4,
    }, card)
    pill(av)
    local avs = stroke(av, 2, Color3.new(1, 1, 1))
    regFlow(UIFlows, new("UIGradient", {}, avs), 0, 0.9, 120)
    local img = new("ImageLabel", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, ZIndex = 5}, av)
    task.spawn(function()
        local ok, content = pcall(function()
            return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
        end)
        if ok and content then img.Image = content end
    end)

    local shown = LocalPlayer.DisplayName
    if not shown or shown == "" then shown = LocalPlayer.Name end
    new("TextLabel", {
        Position = UDim2.new(0, 96, 0, 16), Size = UDim2.new(1, -210, 0, 26), BackgroundTransparency = 1,
        Text = shown, Font = Enum.Font.GothamBlack, TextSize = 20, TextColor3 = Color3.new(1, 1, 1),
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 4,
    }, card)
    new("TextLabel", {
        Position = UDim2.new(0, 96, 0, 46), Size = UDim2.new(1, -110, 0, 16), BackgroundTransparency = 1,
        Text = "@" .. LocalPlayer.Name, Font = Enum.Font.GothamMedium, TextSize = 12,
        TextColor3 = Color3.fromRGB(130, 145, 175), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4,
    }, card)
    new("TextLabel", {
        Position = UDim2.new(0, 96, 0, 68), Size = UDim2.new(1, -110, 0, 16), BackgroundTransparency = 1,
        Text = "Hesap yaşı: " .. tostring(LocalPlayer.AccountAge) .. " gün", Font = Enum.Font.GothamMedium, TextSize = 11,
        TextColor3 = Color3.fromRGB(100, 112, 145), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4,
    }, card)
    new("TextLabel", {
        AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 12), Size = UDim2.new(0, 90, 0, 16),
        BackgroundTransparency = 1, Text = "● BAĞLANDI", Font = Enum.Font.GothamBold, TextSize = 10,
        TextColor3 = Color3.fromRGB(80, 255, 140), TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 4,
    }, card)
end

local FpsValue, PingValue, PlayersValue
local ultraFpsDisplayBoost = false -- Yalnızca ana sayfadaki FPS göstergesi için
do
    local row = new("Frame", {
        LayoutOrder = nextOrder(HomePage), Size = UDim2.new(1, 0, 0, 72), BackgroundTransparency = 1, ZIndex = 3,
    }, HomePage)
    new("UIGridLayout", {
        CellSize = UDim2.new(1 / 3, -7, 1, 0), CellPadding = UDim2.new(0, 10, 0, 0), SortOrder = Enum.SortOrder.LayoutOrder,
    }, row)
    local function statCard(order, title)
        local c = new("Frame", {
            LayoutOrder = order, BackgroundColor3 = ROW_BG, BackgroundTransparency = 0.05, BorderSizePixel = 0, ZIndex = 3,
        }, row)
        corner(c, 12)
        stroke(c, 1, ROW_STROKE, 0.2)
        new("TextLabel", {
            Position = UDim2.new(0, 12, 0, 8), Size = UDim2.new(1, -24, 0, 14), BackgroundTransparency = 1,
            Text = title, Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = Color3.fromRGB(110, 124, 158),
            TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4,
        }, c)
        local v = new("TextLabel", {
            Position = UDim2.new(0, 12, 0, 24), Size = UDim2.new(1, -24, 0, 28), BackgroundTransparency = 1,
            Text = "—", Font = Enum.Font.GothamBlack, TextSize = 22, TextColor3 = Color3.new(1, 1, 1),
            TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4,
        }, c)
        regFlow(UIFlows, new("UIGradient", {}, v), order, 0.5)
        return v
    end
    FpsValue = statCard(1, "FPS")
    PingValue = statCard(2, "PİNG")
    PlayersValue = statCard(3, "OYUNCU")
end

do
    local info = new("Frame", {
        LayoutOrder = nextOrder(HomePage), Size = UDim2.new(1, 0, 0, 92),
        BackgroundColor3 = ROW_BG, BackgroundTransparency = 0.05, BorderSizePixel = 0, ZIndex = 3,
    }, HomePage)
    corner(info, 12)
    stroke(info, 1, ROW_STROKE, 0.2)
    new("TextLabel", {
        Position = UDim2.new(0, 14, 0, 10), Size = UDim2.new(1, -28, 0, 18), BackgroundTransparency = 1,
        Text = "EZRAGOX HUB'a hoş geldin!", Font = Enum.Font.GothamBold, TextSize = 14,
        TextColor3 = Color3.new(1, 1, 1), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4,
    }, info)
    new("TextLabel", {
        Position = UDim2.new(0, 14, 0, 32), Size = UDim2.new(1, -28, 0, 38), BackgroundTransparency = 1,
        Text = "Menüyü G tuşuyla açıp kapatabilirsin. Yapımcı: Hasan Usta",
        Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = Color3.fromRGB(150, 163, 195),
        TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true, ZIndex = 4,
    }, info)
end

-- Ana sayfa Premium CTA: Discord logosu metnin sonunda; tıklanınca davet bağlantısı panoya kopyalanır.
do
    local premiumCta = new("TextButton", {
        LayoutOrder = nextOrder(HomePage),
        Size = UDim2.new(1, 0, 0, 70),
        BackgroundColor3 = Color3.fromRGB(29, 13, 22),
        BackgroundTransparency = 0.04,
        BorderSizePixel = 0,
        AutoButtonColor = true,
        Text = "",
        ZIndex = 4,
    }, HomePage)
    corner(premiumCta, 13)
    stroke(premiumCta, 1.2, Color3.fromRGB(190, 35, 55), 0.12)
    new("TextLabel", {
        Position = UDim2.new(0, 18, 0, 0),
        Size = UDim2.new(1, -88, 1, 0),
        BackgroundTransparency = 1,
        Text = "PREMIUM ALMAK İÇİN TIKLA  ›",
        Font = Enum.Font.GothamBlack,
        TextSize = 14,
        TextColor3 = Color3.fromRGB(255, 105, 115),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        ZIndex = 5,
    }, premiumCta)
    new("ImageLabel", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.new(0, 48, 0, 48),
        BackgroundTransparency = 1,
        Image = "rbxassetid://124899140068285",
        ScaleType = Enum.ScaleType.Fit,
        ZIndex = 5,
    }, premiumCta)
    premiumCta.MouseButton1Click:Connect(function()
        local copied = false
        if setclipboard then
            copied = pcall(function() setclipboard(DISCORD_URL) end)
        end
        if not copied and toclipboard then
            copied = pcall(function() toclipboard(DISCORD_URL) end)
        end
        if copied then
            notify("Discord", "Davet bağlantısı panoya kopyalandı.", 4)
        else
            notify("Discord", "Bağlantı: " .. DISCORD_URL, 6)
        end
    end)
end

-- ÖZELLİKLER SEKMESİ
createSection(FeaturesPage, "KARAKTER ÖZELLİKLERİ")

local ghostActive = false
createToggle(FeaturesPage, "👻  Hayalet Modu (Görünmezlik)", false, function(v)
    ghostActive = v
    pcall(function()
        local char = LocalPlayer.Character
        if char then
            for _, d in ipairs(char:GetDescendants()) do
                if d:IsA("BasePart") or d:IsA("Decal") then
                    if d.Name ~= "HumanoidRootPart" then
                        d.Transparency = ghostActive and 1 or 0
                    end
                end
            end
        end
    end)
    notify("Hayalet Modu", ghostActive and "Görünmez oldun!" or "Görünür hale geldin.", 2)
end)

createToggle(FeaturesPage, "🏃‍♂️  Süper Hız Aktif Et", false, function(v)
    pcall(function()
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = v and Settings.SpeedVal or 16
        end
    end)
    notify("Süper Hız", v and "Hızın artırıldı!" or "Normale döndü.", 2)
end)

createSlider(FeaturesPage, "⚡  Süper Hız Değeri", 16, 200, Settings.SpeedVal, function(v)
    Settings.SpeedVal = v
    pcall(function()
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum and hum.WalkSpeed > 16 then
            hum.WalkSpeed = v
        end
    end)
end, "")

createToggle(FeaturesPage, "🚀  Süper Zıplama Gücü", false, function(v)
    pcall(function()
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.UseJumpPower = true
            hum.JumpPower = v and 120 or 50
        end
    end)
    notify("Süper Zıplama", v and "Zıplama gücü artırıldı!" or "Normale döndü.", 2)
end)

local infJumpActive = false
createToggle(FeaturesPage, "🦘  Sınırsız Zıplama (Infinite Jump)", false, function(v)
    infJumpActive = v
    notify("Sınırsız Zıplama", v and "Aktif edildi!" or "Kapatıldı.", 2)
end)

bind(UserInputService.JumpRequest, function()
    if infJumpActive then
        pcall(function()
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    end
end)

createSection(FeaturesPage, "UÇUŞ MODU (FLY)")

do
local flyActive = false
local flyConnection = nil
local flyBv, flyBg = nil, nil
local flyHumanoid = nil
local flyOldAutoRotate = nil
local flyOldJumpingEnabled = nil
local flyOldFreefallEnabled = nil
local flyAnimateScript = nil
local flyOldAnimateEnabled = nil

local function toggleFly(v)
    flyActive = v
    pcall(function()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if flyActive and hrp and hum then
            flyHumanoid = hum
            flyOldAutoRotate = hum.AutoRotate
            flyOldJumpingEnabled = hum:GetStateEnabled(Enum.HumanoidStateType.Jumping)
            flyOldFreefallEnabled = hum:GetStateEnabled(Enum.HumanoidStateType.Freefall)
            flyAnimateScript = char:FindFirstChild("Animate")
            if flyAnimateScript and flyAnimateScript:IsA("LocalScript") then
                flyOldAnimateEnabled = flyAnimateScript.Enabled
                flyAnimateScript.Enabled = false
            end

            -- Uçuş sırasında varsayılan yürüme/koşma/zıplama animasyonlarını durdur.
            local animator = hum:FindFirstChildOfClass("Animator")
            if animator then
                for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                    track:Stop(0)
                end
            end
            hum:Move(Vector3.zero, false)
            hum.AutoRotate = false
            hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
            hum:ChangeState(Enum.HumanoidStateType.Physics)

            flyBv = Instance.new("BodyVelocity")
            flyBv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            flyBv.Velocity = Vector3.zero
            flyBv.Parent = hrp

            flyBg = Instance.new("BodyGyro")
            flyBg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
            flyBg.P = 90000
            flyBg.D = 1000
            flyBg.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + Vector3.new(hrp.CFrame.LookVector.X, 0, hrp.CFrame.LookVector.Z))
            flyBg.Parent = hrp

            flyConnection = RunService.RenderStepped:Connect(function()
                if not flyActive or not hrp.Parent then return end
                local cam = workspace.CurrentCamera
                local moveDir = Vector3.zero
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                    moveDir = moveDir + cam.CFrame.LookVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                    moveDir = moveDir - cam.CFrame.LookVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                    moveDir = moveDir - cam.CFrame.RightVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                    moveDir = moveDir + cam.CFrame.RightVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                    moveDir = moveDir + Vector3.new(0, 1, 0)
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                    moveDir = moveDir - Vector3.new(0, 1, 0)
                end
                flyBv.Velocity = moveDir * Settings.FlySpeed
                -- Klavye ile hareket ederken Humanoid'in koşu/yürüme animasyonu tetiklenmesin.
                if flyHumanoid and flyHumanoid.Parent then
                    flyHumanoid:Move(Vector3.zero, false)
                    local animator = flyHumanoid:FindFirstChildOfClass("Animator")
                    if animator then
                        for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                            track:Stop(0)
                        end
                    end
                end

                -- Kamera hareket etse bile karakterin gövdesi dik ve sabit kalır.
                local look = cam.CFrame.LookVector
                local flatLook = Vector3.new(look.X, 0, look.Z)
                if flatLook.Magnitude > 0.001 then
                    flyBg.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + flatLook.Unit)
                end
                if flyHumanoid and flyHumanoid.Parent and flyHumanoid:GetState() ~= Enum.HumanoidStateType.Physics then
                    flyHumanoid:ChangeState(Enum.HumanoidStateType.Physics)
                end
            end)
            notify("Fly Aktif", "Uçuş modu açıldı! Tuş: " .. Settings.FlyKey.Name, 2)
        else
            if flyConnection then flyConnection:Disconnect(); flyConnection = nil end
            if flyBv then flyBv:Destroy(); flyBv = nil end
            if flyBg then flyBg:Destroy(); flyBg = nil end
            if flyHumanoid and flyHumanoid.Parent then
                if flyOldAutoRotate ~= nil then flyHumanoid.AutoRotate = flyOldAutoRotate end
                if flyOldJumpingEnabled ~= nil then flyHumanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, flyOldJumpingEnabled) end
                if flyOldFreefallEnabled ~= nil then flyHumanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, flyOldFreefallEnabled) end
                if flyAnimateScript and flyAnimateScript.Parent and flyOldAnimateEnabled ~= nil then
                    flyAnimateScript.Enabled = flyOldAnimateEnabled
                end
                flyHumanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
            flyHumanoid = nil
            flyAnimateScript, flyOldAnimateEnabled = nil, nil
            flyOldAutoRotate, flyOldJumpingEnabled, flyOldFreefallEnabled = nil, nil, nil
            notify("Fly Kapandı", "Uçuş modu kapatıldı.", 2)
        end
    end)
end

local flyToggleObj = createToggle(FeaturesPage, "🛸  Fly (Uçma) Modu", false, function(v)
    toggleFly(v)
end)

do
    local row, st = baseRow(FeaturesPage, "TextButton", 42)
    rowLabel(row, "Fly Açma/Kapatma Tuşu")
    local keyText = new("TextLabel", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.new(0, 100, 0, 26),
        BackgroundTransparency = 1, Text = Settings.FlyKey.Name, Font = Enum.Font.GothamBold, TextSize = 13,
        TextColor3 = Color3.fromRGB(255, 65, 75), TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 4,
    }, row)
    hoverFx(row, st)

    updateFlyKeyTextCallback = function(name)
        setText(keyText, name)
    end

    bind(row.MouseButton1Click, function()
        playClickSound()
        listeningFlyKey = true
        setText(keyText, "Tuşa basın...")
        notify("Tuş Bekleniyor", "Fly için yeni bir klavye tuşuna basın...", 3)
    end)
end

createSlider(FeaturesPage, "🚀  Fly Hızı", 10, 300, Settings.FlySpeed, function(v)
    Settings.FlySpeed = v
end, "")

bind(UserInputService.InputBegan, function(input, gpe)
    if gpe or not ready or listeningFlyKey or listeningForKey then return end
    if input.KeyCode == Settings.FlyKey then
        flyActive = not flyActive
        toggleFly(flyActive)
        flyToggleObj.Set(flyActive, true)
    end
end)

end

-- FPS BOOST VE ULTRA FPS MODLARI
createSection(FeaturesPage, "PERFORMANS VE FPS MODLARI")

createToggle(FeaturesPage, "📈  FPS Modu (Optimizasyon)", false, function(v)
    pcall(function()
        Lighting.GlobalShadows = not v
        for _, child in ipairs(Lighting:GetChildren()) do
            if child:IsA("PostEffect") and child ~= blurEffect and child ~= cc then
                child.Enabled = not v
            end
        end
        local localCharacter = LocalPlayer.Character
        for _, obj in ipairs(workspace:GetDescendants()) do
            -- Oyuncunun kendi karakterini atla; görünüm ve kıyafetleri korunur.
            if not (localCharacter and obj:IsDescendantOf(localCharacter)) then
                if obj:IsA("BasePart") then
                    obj.CastShadow = not v
                end
            end
        end
    end)
    notify("FPS Modu", v and "FPS Optimizasyonu aktif! Gölgeler ve efektler kapatıldı." or "Normal ayarlara dönüldü.", 3)
end)

createToggle(FeaturesPage, "⚡  Ultra FPS Modu (Maksimum Performans)", false, function(v)
    ultraFpsDisplayBoost = v
    pcall(function()
        Lighting.GlobalShadows = not v
        Lighting.Brightness = v and 1 or 2
        for _, child in ipairs(Lighting:GetChildren()) do
            if child:IsA("PostEffect") and child ~= blurEffect and child ~= cc then
                child.Enabled = not v
            end
        end
        local localCharacter = LocalPlayer.Character
        for _, obj in ipairs(workspace:GetDescendants()) do
            -- Ultra FPS yalnızca çevreye uygulanır; yerel karaktere dokunulmaz.
            if not (localCharacter and obj:IsDescendantOf(localCharacter)) then
                if obj:IsA("BasePart") then
                    obj.CastShadow = not v
                    if v and obj.Material ~= Enum.Material.SmoothPlastic and obj.Material ~= Enum.Material.Neon then
                        obj.Material = Enum.Material.SmoothPlastic
                    end
                elseif v and (obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles")) then
                    obj.Enabled = false
                elseif v and (obj:IsA("Decal") or obj:IsA("Texture")) then
                    obj.Transparency = 1
                end
            end
        end
    end)
    notify("Ultra FPS", v and "Ultra FPS Modu aktif! Donanım yükü minimuma indirildi." or "Ultra mod kapatıldı.", 3)
end)

-- ESP (DUVAR ARKASI GÖRÜŞ)
createSection(FeaturesPage, "ESP (DUVAR ARKASI GÖRÜŞ)")
do
    local espOn = false
    local espData = {}      -- [Player] = {hl, gui, name, dist, hue}
    local espFolder = nil
    local ESP_GREEN = Color3.fromRGB(0, 255, 70)

    local function getEspFolder()
        if espFolder and espFolder.Parent then return espFolder end
        espFolder = Instance.new("Folder")
        espFolder.Name = "EZRAGOX_ESP"
        espFolder.Parent = ScreenGui.Parent or CoreGui
        return espFolder
    end

    local function removeEsp(plr)
        local d = espData[plr]
        if not d then return end
        espData[plr] = nil
        pcall(function() d.hl:Destroy() end)
        pcall(function() d.gui:Destroy() end)
    end

    local function buildEsp(plr)
        removeEsp(plr)
        if plr == LocalPlayer then return end
        local char = plr.Character
        if not char then return end
        local head = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
        if not head then return end
        local folder = getEspFolder()

        -- Yeşil dolgu + parlak yeşil kenar; AlwaysOnTop sayesinde duvar arkasından da görünür
        local hl = new("Highlight", {
            Name = "ESP_" .. plr.Name,
            Adornee = char,
            FillColor = ESP_GREEN,
            OutlineColor = Color3.fromRGB(150, 255, 170),
            FillTransparency = 0.45,
            OutlineTransparency = 0,
            DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
        }, folder)

        -- Karakterin üstünde renkli isim + mesafe
        local gui = new("BillboardGui", {
            Name = "ESPName_" .. plr.Name,
            Adornee = head,
            AlwaysOnTop = true,
            Size = UDim2.new(0, 220, 0, 44),
            StudsOffset = Vector3.new(0, 2.6, 0),
            ResetOnSpawn = false,
        }, folder)
        local nameLbl = new("TextLabel", {
            Size = UDim2.new(1, 0, 0.6, 0),
            BackgroundTransparency = 1,
            Text = plr.DisplayName,
            Font = Enum.Font.GothamBold,
            TextSize = 18,
            TextColor3 = Color3.new(1, 1, 1),
            TextStrokeTransparency = 0,
            TextStrokeColor3 = Color3.new(0, 0, 0),
        }, gui)
        local distLbl = new("TextLabel", {
            Position = UDim2.new(0, 0, 0.6, 0),
            Size = UDim2.new(1, 0, 0.4, 0),
            BackgroundTransparency = 1,
            Text = "",
            Font = Enum.Font.GothamMedium,
            TextSize = 13,
            TextColor3 = Color3.fromRGB(235, 255, 240),
            TextStrokeTransparency = 0.2,
            TextStrokeColor3 = Color3.new(0, 0, 0),
        }, gui)

        espData[plr] = {hl = hl, gui = gui, name = nameLbl, dist = distLbl, hue = (plr.UserId % 100) / 100}
    end

    local function hookEspPlayer(plr)
        if plr == LocalPlayer then return end
        bind(plr.CharacterAdded, function(char)
            if not espOn then return end
            char:WaitForChild("Head", 5)
            if espOn and plr.Character == char then
                pcall(buildEsp, plr)
            end
        end)
        bind(plr.CharacterRemoving, function() removeEsp(plr) end)
    end

    for _, p in ipairs(Players:GetPlayers()) do hookEspPlayer(p) end
    bind(Players.PlayerAdded, function(p)
        hookEspPlayer(p)
        if espOn and p.Character then pcall(buildEsp, p) end
    end)
    bind(Players.PlayerRemoving, function(p) removeEsp(p) end)

    -- Her karede: isim renkleri akar, mesafe güncellenir
    bind(RunService.RenderStepped, function()
        if not espOn then return end
        local t = os.clock() * 0.25
        local cam = workspace.CurrentCamera
        for plr, d in pairs(espData) do
            d.name.TextColor3 = Color3.fromHSV((t + d.hue) % 1, 0.85, 1)
            local head = d.gui.Adornee
            if cam and head and head.Parent then
                setText(d.dist, math.floor((cam.CFrame.Position - head.Position).Magnitude + 0.5) .. " m")
            end
        end
    end)

    createToggle(FeaturesPage, "👁️  ESP (Yeşil Çerçeve + Renkli İsim)", false, function(v)
        espOn = v
        if v then
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Character then pcall(buildEsp, p) end
            end
            notify("ESP Aktif", "Oyuncular duvar arkasından yeşil renkte görünüyor!", 3)
        else
            local list = {}
            for p in pairs(espData) do list[#list + 1] = p end
            for _, p in ipairs(list) do removeEsp(p) end
            notify("ESP Kapandı", "Oyuncu işaretleri kaldırıldı.", 2)
        end
    end)
end

-- TROLL
createSection(TrollPage, "HEDEF OYUNCU SEÇİMİ VE ARAMA")

do
local selectedTargetPlayer = nil

local dropdownRow, dropdownSt = baseRow(TrollPage, "Frame", 48)
rowLabel(dropdownRow, "Oyuncu Ara / Seç")

local selectBtn = new("TextBox", {
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -12, 0.5, 0),
    Size = UDim2.new(0, 180, 0, 32),
    BackgroundColor3 = Color3.fromRGB(28, 34, 54),
    Text = "",
    PlaceholderText = "İsim yaz (örn: hasan)",
    PlaceholderColor3 = Color3.fromRGB(120, 134, 170),
    TextColor3 = Color3.fromRGB(220, 230, 245),
    TextSize = 12,
    Font = Enum.Font.GothamBold,
    ClearTextOnFocus = false,
    ZIndex = 4,
}, dropdownRow)
corner(selectBtn, 8)
stroke(selectBtn, 1, Color3.fromRGB(55, 65, 95), 0.3)

local DropdownListFrame = new("ScrollingFrame", {
    LayoutOrder = nextOrder(TrollPage),
    Size = UDim2.new(1, 0, 0, 0),
    BackgroundColor3 = Color3.fromRGB(15, 18, 28),
    BackgroundTransparency = 0.05,
    BorderSizePixel = 0,
    ScrollBarThickness = 3,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    Visible = false,
    ZIndex = 20,
}, TrollPage)
corner(DropdownListFrame, 10)
stroke(DropdownListFrame, 1, Color3.fromRGB(60, 75, 110), 0.2)
new("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4)}, DropdownListFrame)
new("UIPadding", {PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6), PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6)}, DropdownListFrame)

-- Listede fareyle üzerine gelinen oyuncunun karakteri sağdaki önizlemede gösterilir;
-- hiçbir oyuncunun üzerinde değilken kendi karakterim görünür.
local hoverToken = 0
local shownPlayer = nil   -- nil = kendi karakterim
local function previewPlayer(plr)
    hoverToken = hoverToken + 1
    local my = hoverToken
    task.delay(0.12, function()
        if not alive or my ~= hoverToken or not refreshMenuAvatar then return end
        -- Zaten kendi karakterim gösteriliyorsa gereksiz yeniden kurma
        if plr == nil and shownPlayer == nil then return end
        shownPlayer = plr
        pcall(refreshMenuAvatar, plr or LocalPlayer)
    end)
end

bind(DropdownListFrame:GetPropertyChangedSignal("Visible"), function()
    if not DropdownListFrame.Visible then previewPlayer(nil) end
end)
bind(TrollPage:GetPropertyChangedSignal("Visible"), function()
    if not TrollPage.Visible then previewPlayer(nil) end
end)

local function updatePlayerDropdown(filterText)
    previewPlayer(nil)
    for _, ch in ipairs(DropdownListFrame:GetChildren()) do
        if ch:IsA("TextButton") then ch:Destroy() end
    end

    local matchCount = 0
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local displayName = string.lower(plr.DisplayName)
            local name = string.lower(plr.Name)
            local filter = string.lower(filterText or "")

            if filter == "" or string.sub(name, 1, #filter) == filter or string.sub(displayName, 1, #filter) == filter or string.find(name, filter, 1, true) then
                matchCount = matchCount + 1
                local pBtn = new("TextButton", {
                    Size = UDim2.new(1, 0, 0, 36),
                    BackgroundColor3 = Color3.fromRGB(22, 27, 42),
                    BackgroundTransparency = 0.2,
                    AutoButtonColor = false,
                    Text = "",
                    ZIndex = 21,
                }, DropdownListFrame)
                corner(pBtn, 8)

                -- Üzerine gelince: satırı parlat + oyuncunun karakterini sağda göster
                pBtn.MouseEnter:Connect(function()
                    tween(pBtn, 0.12, {BackgroundTransparency = 0})
                    previewPlayer(plr)
                end)
                pBtn.MouseLeave:Connect(function()
                    tween(pBtn, 0.18, {BackgroundTransparency = 0.2})
                    previewPlayer(nil)
                end)

                local avImg = new("ImageLabel", {
                    Position = UDim2.new(0, 4, 0, 2),
                    Size = UDim2.new(0, 32, 0, 32),
                    BackgroundTransparency = 1,
                    ZIndex = 22,
                }, pBtn)
                pill(avImg)

                task.spawn(function()
                    pcall(function()
                        local thumb = Players:GetUserThumbnailAsync(plr.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
                        avImg.Image = thumb
                    end)
                end)

                new("TextLabel", {
                    Position = UDim2.new(0, 42, 0, 0),
                    Size = UDim2.new(1, -45, 1, 0),
                    BackgroundTransparency = 1,
                    Text = plr.DisplayName .. " (@" .. plr.Name .. ")",
                    TextColor3 = Color3.new(1, 1, 1),
                    TextSize = 12,
                    Font = Enum.Font.GothamMedium,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 22,
                }, pBtn)

                pBtn.MouseButton1Click:Connect(function()
                    playClickSound()
                    previewPlayer(nil)
                    selectedTargetPlayer = plr
                    setText(selectBtn, plr.Name)
                    DropdownListFrame.Visible = false
                    DropdownListFrame.Size = UDim2.new(1, 0, 0, 0)
                    notify("Hedef Seçildi", plr.Name .. " hedef olarak belirlendi.", 2)
                end)
            end
        end
    end

    if matchCount > 0 then
        DropdownListFrame.Visible = true
        tween(DropdownListFrame, 0.2, {Size = UDim2.new(1, 0, 0, math.min(matchCount * 40 + 12, 160))})
    else
        DropdownListFrame.Visible = false
        DropdownListFrame.Size = UDim2.new(1, 0, 0, 0)
    end
end

bind(selectBtn.Focused, function()
    updatePlayerDropdown(selectBtn.Text)
end)

bind(selectBtn:GetPropertyChangedSignal("Text"), function()
    if selectBtn:IsFocused() then
        updatePlayerDropdown(selectBtn.Text)
    end
end)

createSection(TrollPage, "AKTİF TROLL ÖZELLİKLERİ (14 ADET)")

local attachedActive = false
local attachConnection = nil
local attachToggleObj
attachToggleObj = createToggle(TrollPage, "🔗  1. Seçilen Kişiye Yapış", false, function(v)
    attachedActive = v
    if attachedActive then
        if not selectedTargetPlayer or not selectedTargetPlayer.Parent then
            notify("Hata", "Lütfen önce yukarıdan hedef oyuncu seçin!", 3)
            attachedActive = false
            task.defer(function() attachToggleObj.Set(false, true) end)
            return
        end
        notify("Yapışma Aktif", selectedTargetPlayer.Name .. " adlı oyuncuya yapışılıyor!", 3)
        attachConnection = RunService.Heartbeat:Connect(function()
            if not attachedActive then return end
            pcall(function()
                local myChar = LocalPlayer.Character
                local targetChar = selectedTargetPlayer.Character
                if myChar and targetChar then
                    local myHrp = myChar:FindFirstChild("HumanoidRootPart")
                    local targetHrp = targetChar:FindFirstChild("HumanoidRootPart")
                    if myHrp and targetHrp then
                        myHrp.CFrame = targetHrp.CFrame * CFrame.new(0, 0, 0)
                        myHrp.Velocity = Vector3.new(0, 0, 0)
                    end
                end
            end)
        end)
    else
        if attachConnection then attachConnection:Disconnect(); attachConnection = nil end
        notify("Yapışma Kapandı", "Oyuncudan ayrıldınız.", 2)
    end
end)

local stickActive = false
local stickConnection = nil
local stickToggleObj
local function tryNetworkOwner(part)
    -- Çoğu executor/oyunda bu çalışmaz (ağ sahipliği sunucuya aittir),
    -- bazılarında çalışabileceği için zararsızca deneniyor.
    pcall(function() part:SetNetworkOwner(LocalPlayer) end)
end
stickToggleObj = createToggle(TrollPage, "📎  1b. Oyuncuyu Kendine Yapıştır", false, function(v)
    stickActive = v
    if stickActive then
        if not selectedTargetPlayer or not selectedTargetPlayer.Parent then
            notify("Hata", "Lütfen önce yukarıdan hedef oyuncu seçin!", 3)
            stickActive = false
            task.defer(function() stickToggleObj.Set(false, true) end)
            return
        end
        if attachedActive then attachToggleObj.Set(false) end
        notify("Yapıştırma Aktif", selectedTargetPlayer.Name .. " sana yapıştırılıyor!", 3)
        local triedOwner = false
        stickConnection = RunService.Heartbeat:Connect(function()
            if not stickActive then return end
            pcall(function()
                local target = selectedTargetPlayer
                local myChar = LocalPlayer.Character
                local targetChar = target and target.Character
                if myChar and targetChar then
                    local myHrp = myChar:FindFirstChild("HumanoidRootPart")
                    local tHrp = targetChar:FindFirstChild("HumanoidRootPart")
                    if myHrp and tHrp then
                        if not triedOwner then
                            triedOwner = true
                            tryNetworkOwner(tHrp)
                        end
                        local goal = myHrp.CFrame * CFrame.new(0, 0, -3)
                        tHrp.CFrame = goal
                        tHrp.AssemblyLinearVelocity = myHrp.AssemblyLinearVelocity
                        tHrp.AssemblyAngularVelocity = Vector3.zero
                    end
                end
            end)
        end)
    else
        if stickConnection then stickConnection:Disconnect() stickConnection = nil end
        notify("Yapıştırma Kapandı", "Oyuncu serbest bırakıldı.", 2)
    end
end)
bind(Players.PlayerRemoving, function(plr)
    if plr == selectedTargetPlayer and stickActive then stickToggleObj.Set(false, true) end
end)

---------------------------------------------------------
-- TROLL ÇEKİRDEĞİ
-- Not: Başka oyuncunun karakterinde doğrudan yapılan değişiklikler
-- (CFrame, Anchored, Jump, BodyVelocity...) sunucuya yansımaz, sadece
-- senin ekranında görünür. Diğer oyunculara gerçekten etki eden tek
-- yol fizik çarpışmasıdır: kendi karakterini hedefin içine ışınlayıp
-- yüksek hızla çarptırmak. Fling / Sky / Sallantı bu yöntemi kullanır.
---------------------------------------------------------
local Troll = {busy = false, fovBusy = false}

function Troll.parts(plr)
    local char = plr and plr.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    return char, hrp, hum
end

function Troll.require()
    if not selectedTargetPlayer or not selectedTargetPlayer.Parent then
        notify("Hata", "Lütfen önce bir hedef oyuncu seçin!", 3)
        return false
    end
    local _, hrp, hum = Troll.parts(selectedTargetPlayer)
    if not hrp or not hum or hum.Health <= 0 then
        notify("Hata", "Hedefin karakteri şu an yok veya ölü.", 3)
        return false
    end
    return true
end

function Troll.flat(a, b)
    return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

-- mode: "fling" | "sky" | "shake" | "pull"
function Troll.attack(mode)
    if Troll.busy then
        notify("Bekle", "Önceki işlem hâlâ sürüyor.", 2)
        return
    end
    if not Troll.require() then return end

    local target = selectedTargetPlayer
    local myChar, myHrp, myHum = Troll.parts(LocalPlayer)
    if not myHrp or not myHum or myHum.Health <= 0 then
        notify("Hata", "Kendi karakterin hazır değil.", 3)
        return
    end

    if mode == "pull" then
        local _, th = Troll.parts(target)
        if th and (th.Position - myHrp.Position).Magnitude < 8 then
            notify("Zaten Yakın", target.Name .. " zaten yanında.", 2)
            return
        end
    end

    Troll.busy = true
    -- "Yapış" açıksa saldırıyla çakışmasın
    if attachedActive then attachToggleObj.Set(false) end

    task.spawn(function()
        local cam = workspace.CurrentCamera
        local oldCF = myHrp.CFrame
        local oldFallen = workspace.FallenPartsDestroyHeight
        local duration = (mode == "fling") and 3 or ((mode == "sky") and 2.5 or ((mode == "space") and 6 or ((mode == "pull") and 4 or 2)))
        local hit = false
        local home = oldCF.Position
        local startDist = 0
        do
            local _, th0 = Troll.parts(target)
            if th0 then startDist = Troll.flat(th0.Position, home) end
        end

        -- Fırlayınca boşluğa düşüp ölmemek için
        pcall(function() workspace.FallenPartsDestroyHeight = -math.huge end)
        pcall(function()
            myHrp.Anchored = false
            local _, _, tHum0 = Troll.parts(target)
            if cam and tHum0 then cam.CameraSubject = tHum0 end
        end)

        pcall(function()
            local startT = os.clock()
            local angle = 0
            while alive and os.clock() - startT < duration do
                local _, tHrp, tHum = Troll.parts(target)
                if not tHrp or not tHum or tHum.Health <= 0 then break end
                if not myHrp.Parent or myHum.Health <= 0 then break end

                angle = angle + 100
                -- Hedef yürüyorsa gideceği yöne doğru önden git
                local lead = tHum.MoveDirection * math.min(tHrp.AssemblyLinearVelocity.Magnitude, 40) / 1.25

                local offset, lin, rot, spin
                if mode == "fling" then
                    local y = (math.floor(angle / 100) % 2 == 0) and 1.5 or -1.5
                    offset = CFrame.new(0, y, 0) + lead
                    lin = Vector3.new(9e7, 9e8, 9e7)
                    rot = Vector3.new(9e8, 9e8, 9e8)
                    spin = CFrame.Angles(math.rad(angle), 0, 0)
                elseif mode == "sky" then
                    offset = CFrame.new(0, -2, 0) + lead
                    lin = Vector3.new(0, 9e5, 0)
                    rot = Vector3.zero
                    spin = CFrame.new()
                elseif mode == "space" then
                    -- Sürekli artan, çok güçlü dikey itiş: hedefi haritanın çok üstüne,
                    -- adeta uzaya kadar fırlatmayı hedefler.
                    local t = os.clock() - startT
                    offset = CFrame.new(0, -2 - t * 4, 0) + lead
                    lin = Vector3.new(0, 1.2e6 + t * 4e5, 0)
                    rot = Vector3.zero
                    spin = CFrame.new()
                elseif mode == "pull" then
                    -- Hedefin arkasından, benim durduğum yere doğru itelerek çek
                    local toHome = Vector3.new(home.X - tHrp.Position.X, 0, home.Z - tHrp.Position.Z)
                    if toHome.Magnitude < 8 then
                        hit = true
                        break
                    end
                    local dir = toHome.Unit
                    offset = CFrame.new(-dir * 1.2 + Vector3.new(0, 0.2, 0))
                    lin = dir * 150 + Vector3.new(0, 12, 0)
                    rot = Vector3.zero
                    spin = CFrame.new()
                else -- shake
                    local a = math.rad(angle * 4)
                    offset = CFrame.new(math.sin(a) * 0.8, 0, math.cos(a) * 0.8)
                    lin = Vector3.new(math.sin(a) * 60, 0, math.cos(a) * 60)
                    rot = Vector3.new(0, 400, 0)
                    spin = CFrame.new()
                end

                myChar:PivotTo(CFrame.new(tHrp.Position) * offset * spin)
                myHrp.AssemblyLinearVelocity = lin
                myHrp.AssemblyAngularVelocity = rot
                task.wait()

                -- Hedef çok hızlandıysa fırlamış demektir
                if (mode == "fling" or mode == "sky" or mode == "space") and tHrp.AssemblyLinearVelocity.Magnitude > 500 then
                    hit = true
                    break
                end
            end
        end)

        -- Kendi karakterini eski yerine güvenle geri götür
        for _ = 1, 20 do
            if not myHrp.Parent then break end
            pcall(function()
                myChar:PivotTo(oldCF)
                myHrp.AssemblyLinearVelocity = Vector3.zero
                myHrp.AssemblyAngularVelocity = Vector3.zero
            end)
            task.wait()
        end
        pcall(function() workspace.FallenPartsDestroyHeight = oldFallen end)
        pcall(function()
            if cam and myHum.Parent then cam.CameraSubject = myHum end
        end)
        Troll.busy = false

        local name = target.Name
        if mode == "fling" then
            if hit then
                notify("Fling Başarılı", name .. " fırlatıldı!", 3)
            else
                notify("Fling Etkisiz", name .. " fırlamadı; oyun fling'e karşı korumalı olabilir.", 4)
            end
        elseif mode == "sky" then
            if hit then
                notify("Havaya Uçuruldu", name .. " havaya fırlatıldı!", 3)
            else
                notify("Sky Etkisiz", name .. " yükselmedi; oyun çarpışmaya karşı korumalı olabilir.", 4)
            end
        elseif mode == "space" then
            if hit then
                notify("Uzaya Fırlatıldı 🚀", name .. " maksimum güçle fırlatıldı!", 3)
            else
                notify("Etkisiz", name .. " yerinden oynamadı; bu oyun çarpışma fiziğine karşı korumalı (ör. anchored/ragdoll kilidi).", 5)
            end
        elseif mode == "pull" then
            local _, thEnd = Troll.parts(target)
            local endDist = thEnd and Troll.flat(thEnd.Position, home) or startDist
            local moved = math.floor(startDist - endDist + 0.5)
            if endDist < 12 then
                notify("Yanına Çekildi", name .. " yanına çekildi!", 3)
            elseif moved >= 10 then
                notify("Kısmen Çekildi", name .. " " .. tostring(moved) .. " stud yaklaştı.", 3)
            else
                notify("Çekilemedi", name .. " yerinden oynamadı; oyun buna karşı korumalı olabilir.", 4)
            end
        else
            notify("Sallantı Bitti", name .. " sallandı (etki oyuna göre değişir).", 3)
        end
    end)
end

createButton(TrollPage, "🌀  2. Oyuncuyu Döndür (Gerçek Fling)", function()
    Troll.attack("fling")
end)

createButton(TrollPage, "💥  3. Oyuncuya Patlama Efekti", function()
    if not Troll.require() then return end
    pcall(function()
        local _, hrp = Troll.parts(selectedTargetPlayer)
        local ex = Instance.new("Explosion")
        ex.Position = hrp.Position
        ex.BlastRadius = 12
        ex.BlastPressure = 0
        ex.DestroyJointRadiusPercent = 0
        ex.ExplosionType = Enum.ExplosionType.NoCraters
        ex.Parent = workspace
    end)
    notify("Patlama", "Efekt yalnızca senin ekranında görünür.", 3)
end)

createButton(TrollPage, "🎈  4. Oyuncuyu Havaya Uçur (Sky Teleport)", function()
    Troll.attack("sky")
end)

createButton(TrollPage, "☄️  5. Kafasına Taş/Blok Düşür", function()
    if not Troll.require() then return end
    pcall(function()
        local char, hrp = Troll.parts(selectedTargetPlayer)
        local head = char:FindFirstChild("Head") or hrp
        local part = Instance.new("Part")
        part.Size = Vector3.new(3, 3, 3)
        part.Material = Enum.Material.Slate
        part.BrickColor = BrickColor.new("Dark stone grey")
        part.Anchored = false
        part.CanCollide = true
        part.CFrame = CFrame.new(head.Position + Vector3.new(0, 25, 0))
        part.AssemblyLinearVelocity = Vector3.new(0, -80, 0)
        part.Parent = workspace
        task.delay(5, function() part:Destroy() end)
    end)
    notify("Blok Düştü", "Blok yalnızca senin ekranında görünür.", 3)
end)

createButton(TrollPage, "📌  6. Oyuncuyu Olduğu Yere Sabitle", function()
    if not Troll.require() then return end
    local plr = selectedTargetPlayer
    local _, hrp0 = Troll.parts(plr)
    local frozenCF = hrp0.CFrame
    local startT = os.clock()
    local conn
    conn = RunService.Heartbeat:Connect(function()
        local _, h = Troll.parts(plr)
        if not alive or os.clock() - startT >= 3 or not h then
            conn:Disconnect()
            if h then h.Anchored = false end
            return
        end
        h.CFrame = frozenCF
        h.AssemblyLinearVelocity = Vector3.zero
        h.Anchored = true
    end)
    notify("Sabitlendi", plr.Name .. " 3 sn donduruldu (yalnızca senin ekranında).", 3)
end)

createButton(TrollPage, "💃  7. Oyuncuyu Sars / Sallantı Ver", function()
    Troll.attack("shake")
end)

createButton(TrollPage, "🕶️  8. Hedefin Bilgilerini Al", function()
    if not selectedTargetPlayer or not selectedTargetPlayer.Parent then
        notify("Hata", "Lütfen önce bir hedef oyuncu seçin!", 3)
        return
    end
    local plr = selectedTargetPlayer
    local _, hrp, hum = Troll.parts(plr)

    local line1 = plr.DisplayName .. " (@" .. plr.Name .. ")  •  ID: " .. tostring(plr.UserId)
    local line2 = "Hesap yaşı: " .. tostring(plr.AccountAge) .. " gün  •  Takım: " .. (plr.Team and plr.Team.Name or "Yok")
    local line3 = "Karakter şu an yüklü değil."
    if hum and hrp then
        local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local dist = myHrp and tostring(math.floor((myHrp.Position - hrp.Position).Magnitude + 0.5)) or "?"
        line3 = "Can: " .. tostring(math.floor(hum.Health)) .. "/" .. tostring(math.floor(hum.MaxHealth))
            .. "  •  Hız: " .. tostring(math.floor(hum.WalkSpeed))
            .. "  •  Mesafe: " .. dist .. " m"
    end

    notify("Hedef Bilgisi", line1, 5)
    task.delay(0.15, function() notify("Hesap", line2, 5) end)
    task.delay(0.3, function() notify("Durum", line3, 5) end)
end)

createButton(TrollPage, "🔄  9. Kamera Efekti (FOV Trolling)", function()
    if Troll.fovBusy then return end
    local cam = workspace.CurrentCamera
    if not cam then return end
    Troll.fovBusy = true
    local origFov = cam.FieldOfView
    local startT = os.clock()
    RunService:BindToRenderStep("EZRAGOX_FOV", Enum.RenderPriority.Camera.Value + 1, function()
        local t = os.clock() - startT
        if t >= 2 or not alive then
            RunService:UnbindFromRenderStep("EZRAGOX_FOV")
            cam.FieldOfView = origFov
            Troll.fovBusy = false
            return
        end
        cam.FieldOfView = math.clamp(75 + math.sin(t * 31) * 40, 20, 120)
    end)
    notify("Kamera Troll", "Kamera efektleri uygulandı!", 2)
end)

createButton(TrollPage, "💨  10. Sunucudaki Herkesi Zıplat", function()
    for _, p in ipairs(Players:GetPlayers()) do
        pcall(function()
            local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.Jump = true
            end
        end)
    end
    notify("Toplu Zıplama", "Sunucudaki herkes zıplatıldı!", 2)
end)

-- 11. SEÇİLEN OYUNCUYU İZLE (Spectate)
local Spectate = {on = false, conn = nil}
local spectateToggleObj

local function restoreOwnCamera()
    pcall(function()
        local cam = workspace.CurrentCamera
        local myChar = LocalPlayer.Character
        local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
        if cam and myHum then
            cam.CameraSubject = myHum
        end
    end)
end

local function stopSpectate()
    Spectate.on = false
    if Spectate.conn then
        Spectate.conn:Disconnect()
        Spectate.conn = nil
    end
    restoreOwnCamera()
end

spectateToggleObj = createToggle(TrollPage, "👁️  11. Seçilen Oyuncuyu İzle", false, function(v)
    if v then
        if not selectedTargetPlayer or not selectedTargetPlayer.Parent then
            notify("Hata", "Lütfen önce yukarıdan hedef oyuncu seçin!", 3)
            task.defer(function() spectateToggleObj.Set(false, true) end)
            return
        end
        Spectate.on = true
        notify("İzleme Aktif", selectedTargetPlayer.Name .. " adlı oyuncu izleniyor!", 3)
        if Spectate.conn then Spectate.conn:Disconnect() end
        Spectate.conn = bind(RunService.RenderStepped, function()
            if not Spectate.on then return end

            -- Hedef oyundan çıktıysa izlemeyi otomatik kapat
            local target = selectedTargetPlayer
            if not target or not target.Parent then
                stopSpectate()
                notify("İzleme Kapandı", "Hedef oyuncu oyundan ayrıldı.", 3)
                task.defer(function() spectateToggleObj.Set(false, true) end)
                return
            end

            -- Hedef ölüp yeniden doğunca (veya hedef değiştirilince) kamerayı yeni Humanoid'e bağla
            pcall(function()
                local cam = workspace.CurrentCamera
                local hum = target.Character and target.Character:FindFirstChildOfClass("Humanoid")
                if cam and hum and cam.CameraSubject ~= hum then
                    cam.CameraSubject = hum
                end
            end)
        end)
    else
        stopSpectate()
        notify("İzleme Kapandı", "Kamera kendi karakterine döndü.", 2)
    end
end)

-- 12. SEÇİLEN OYUNCUNUN YANINA IŞINLAN
createButton(TrollPage, "🚀  12. Seçilen Oyuncunun Yanına Işınlan", function()
    if Troll.busy then
        notify("Bekle", "Önceki işlem hâlâ sürüyor.", 2)
        return
    end
    if not Troll.require() then return end
    local myChar, myHrp = Troll.parts(LocalPlayer)
    local _, tHrp = Troll.parts(selectedTargetPlayer)
    if not myChar or not myHrp then
        notify("Hata", "Kendi karakterin hazır değil.", 3)
        return
    end
    -- Hedefin hemen arkasına, aynı yöne bakarak
    myChar:PivotTo(tHrp.CFrame * CFrame.new(0, 0, 4))
    myHrp.AssemblyLinearVelocity = Vector3.zero
    notify("Işınlandın", selectedTargetPlayer.Name .. " adlı oyuncunun yanındasın!", 2)
end)

-- 13. SEÇİLEN OYUNCUYU YANIMA ÇEK (fizik ile iterek)
createButton(TrollPage, "🎣  13. Seçilen Oyuncuyu Yanıma Çek", function()
    Troll.attack("pull")
end)

-- 14. UZAYA FIRLAT (maksimum güç, uzun süreli fling)
createButton(TrollPage, "🚀  14. Uzaya Fırlat (Maksimum Güç)", function()
    Troll.attack("space")
end)

end

---------------------------------------------------------
-- PREMİUM (ANAHTAR SİSTEMİ) + YÖNETİM (SADECE SAHİBİ İÇİN)
---------------------------------------------------------
do
local PX = {
    unlocked = false,   -- premium açık mı
    admin = false,      -- yönetim girişi yapıldı mı
    lockRows = {},      -- kilitliyken görünen satırlar
    premiumRows = {},   -- açılınca görünen satırlar
    toggles = {},       -- premium anahtarları (kilitlenince kapatılır)
    onLock = {},        -- kilitlenince çalışacak temizlik fonksiyonları
    wrong = 0,
    cooldownUntil = 0,
    adminWrong = 0,
    adminCooldownUntil = 0,
    real = "",
    rows = {},
    adminTab = AdminTab,
}

local ADMIN_HASH = 945129088          -- yönetim şifresinin özeti (düz şifre kodda yazmaz)
local ADMIN_HOTKEY = Enum.KeyCode.Y         -- Ctrl + Shift + Y  => yönetim girişi

-- PREMİUM HESAPLAR (Roblox kullanıcı adı). Veritabanı kullanmıyorsan premium vereceklerini buraya yaz.
local PREMIUM_NAMES = { }

-- Premium hesapları herkesin cihazında görmek için ortak veritabanı (Firebase Realtime Database - ücretsiz).
-- Örnek: "https://proje-adin-default-rtdb.firebaseio.com"   (boş bırakırsan sadece PREMIUM_NAMES listesi kullanılır)
local KEY_DB_URL = "https://veri-aa690-default-rtdb.europe-west1.firebasedatabase.app"
local SECRET_FILE = "ezragox_admin_secret.txt"   -- veritabanı gizli anahtarı SADECE senin cihazında bu dosyada durur

---------------------------------------------------------
-- YARDIMCI FONKSİYONLAR
---------------------------------------------------------
function PX.hash32(str, seed)
    local h = seed or 5381
    for i = 1, #str do
        h = (h * 33 + string.byte(str, i) * ((i % 7) + 1) + 17) % 4294967296
    end
    return h
end

function PX.checkAdmin(pw)
    local s = tostring(pw or "")
    s = s:gsub("%s", "")
    return PX.hash32("EZRX_ADMIN|" .. s, 9871) == ADMIN_HASH
end

function PX.copy(text)
    local ok = false
    pcall(function()
        if setclipboard then
            setclipboard(text)
            ok = true
        end
    end)
    return ok
end

function PX.openDiscord()
    task.spawn(function()
        -- 1) Tarayıcıda (Chrome vb.) aç
        pcall(function() GuiService:OpenBrowserWindow(DISCORD_URL) end)
        pcall(function() if openurl then openurl(DISCORD_URL) end end)
        -- 2) Bağlantıyı panoya kopyala (açılmazsa yapıştırıp girebilsin)
        pcall(function() if setclipboard then setclipboard(DISCORD_URL) end end)
        -- 3) Discord uygulaması açıksa davet penceresini doğrudan uygulamada aç
        pcall(function()
            local req = request or http_request or (syn and syn.request)
            local code = string.match(DISCORD_URL, "discord%.gg/(%w+)")
            if req and code then
                req({
                    Url = "http://127.0.0.1:6463/rpc?v=1",
                    Method = "POST",
                    Headers = {["Content-Type"] = "application/json", ["Origin"] = "https://discord.com"},
                    Body = HttpService:JSONEncode({
                        cmd = "INVITE_BROWSER",
                        args = {code = code},
                        nonce = HttpService:GenerateGUID(false),
                    }),
                })
            end
        end)
    end)
    notify("Discord Sunucusu", "Açılıyor... Açılmazsa bağlantı panoya kopyalandı.", 4)
end

---------------------------------------------------------
-- ORTAK ARAYÜZ PARÇALARI
---------------------------------------------------------
function PX.infoCard(page, title, body, height)
    local row = baseRow(page, "Frame", height)
    local t = new("TextLabel", {
        Position = UDim2.new(0, 14, 0, 10), Size = UDim2.new(1, -28, 0, 18), BackgroundTransparency = 1,
        Text = title, Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = Color3.new(1, 1, 1),
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4,
    }, row)
    local b = new("TextLabel", {
        Position = UDim2.new(0, 14, 0, 32), Size = UDim2.new(1, -28, 1, -40), BackgroundTransparency = 1,
        Text = body, Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = Color3.fromRGB(150, 163, 195),
        TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true, ZIndex = 4,
    }, row)
    return row, t, b
end

function PX.inputRow(page, label, placeholder)
    local row = baseRow(page, "Frame", 48)
    local lbl = rowLabel(row, label)
    lbl.Size = UDim2.new(0, 80, 0, 20)
    lbl.Position = UDim2.new(0, 14, 0.5, -10)
    local box = new("TextBox", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.new(1, -108, 0, 32),
        BackgroundColor3 = Color3.fromRGB(28, 14, 20), Text = "", PlaceholderText = placeholder,
        PlaceholderColor3 = Color3.fromRGB(130, 100, 108), TextColor3 = Color3.fromRGB(255, 214, 102),
        TextSize = 13, Font = Enum.Font.Code, ClearTextOnFocus = false, ZIndex = 4,
    }, row)
    corner(box, 8)
    stroke(box, 1, Color3.fromRGB(135, 40, 55), 0.3)
    return row, box, lbl
end

local function snapshot(page)
    local s = {}
    for _, c in ipairs(page:GetChildren()) do s[c] = true end
    return s
end
local function collectNew(page, before, list)
    for _, c in ipairs(page:GetChildren()) do
        if not before[c] and c:IsA("GuiObject") then list[#list + 1] = c end
    end
end

-- Premium bileşenleri: kilitliyken çalışmaz
function PX.toggle(text, cb)
    local obj
    obj = createToggle(PremiumPage, text, false, function(v)
        if v and not PX.unlocked then
            obj.Set(false, true)
            notify("Premium Gerekli", "Önce geçerli bir anahtar gir.", 3)
            return
        end
        cb(v)
    end, false)
    PX.toggles[#PX.toggles + 1] = obj
    return obj
end
function PX.button(text, cb)
    return createButton(PremiumPage, text, function()
        if not PX.unlocked then return end
        cb()
    end)
end
function PX.slider(text, min, max, default, cb, suffix)
    return createSlider(PremiumPage, text, min, max, default, function(v)
        if PX.unlocked then cb(v) end
    end, suffix)
end

---------------------------------------------------------
-- PREMİUM SEKMESİ
---------------------------------------------------------
do
    local badge = new("TextLabel", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -6, 0.5, 0), Size = UDim2.new(0, 26, 0, 15),
        BackgroundColor3 = Color3.fromRGB(255, 190, 60), Text = "PRO", Font = Enum.Font.GothamBlack,
        TextSize = 9, TextColor3 = Color3.fromRGB(45, 22, 0), ZIndex = 6,
    }, PremiumTab.btn)
    corner(badge, 6)
end

-- 1) Kilitli ekran
do
    local before = snapshot(PremiumPage)
    createSection(PremiumPage, "PREMİUM KİLİDİ")
    PX.infoCard(PremiumPage, trText("👑  EZRAGOX PREMİUM"), "Noclip • Tıkla-Işınlan • Fullbright • Gökkuşağı Aura • Dönen Karakter • Yerçekimi • FOV • Zoom Kilidi • Gün Saati • Anti-AFK • Rejoin ve daha fazlası. Premium, Roblox hesabına özel tanımlanır.", 92)
    PX.infoCard(PremiumPage, trText("👤  Hesabın: ") .. LocalPlayer.Name, trText("Bu hesapta premium tanımlı değil. Premium istemek için Discord sunucusuna gel."), 62)
    createButton(PremiumPage, "🔄  Premium Durumunu Yenile", function()
        PX.checkPremium(false)
    end)
    createButton(PremiumPage, "🔑  Premium İste  (Discord Sunucusu)", function()
        PX.openDiscord()
    end)
    collectNew(PremiumPage, before, PX.lockRows)
end

-- 2) Açık ekran (özellikler)
do
    local before = snapshot(PremiumPage)

    createSection(PremiumPage, "PREMİUM DURUMU")
    local _, _, statusBody = PX.infoCard(PremiumPage, trText("✅  PREMİUM AKTİF"), "", 58)
    PX.statusBody = statusBody

    createSection(PremiumPage, "👑  PREMİUM HAREKET")

    -- Noclip
    do
        local noclipOn, touched = false, {}
        bind(RunService.Stepped, function()
            if not noclipOn then return end
            local char = LocalPlayer.Character
            if not char then return end
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") and p.CanCollide then
                    touched[p] = true
                    p.CanCollide = false
                end
            end
        end)
        PX.toggle("👻  Noclip (Duvarlardan Geç)", function(v)
            noclipOn = v
            if v then
                notify("Noclip", "Aktif! Duvarların içinden geçebilirsin.", 2)
            else
                for p in pairs(touched) do
                    if p and p.Parent then p.CanCollide = true end
                end
                touched = {}
            end
        end)
    end

    -- Tıkla-Işınlan
    do
        local clickTp = false
        local mouse = LocalPlayer:GetMouse()
        bind(UserInputService.InputBegan, function(input, gpe)
            if gpe or not clickTp or not PX.unlocked then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1
                and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp and mouse.Hit then
                    hrp.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0))
                end
            end
        end)
        PX.toggle("🖱️  Tıkla-Işınlan  (Ctrl + Sol Tık)", function(v)
            clickTp = v
            if v then notify("Tıkla-Işınlan", "Ctrl basılıyken bir yere sol tıkla.", 3) end
        end)
    end

    -- Dönen karakter
    do
        local spinOn, spinSpeed = false, 10
        bind(RunService.RenderStepped, function(dt)
            if not spinOn then return end
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(spinSpeed * 36 * dt), 0)
            end
        end)
        PX.toggle("🌀  Dönen Karakter (Spin)", function(v)
            spinOn = v
            if v then notify("Spin", "Karakterin dönmeye başladı!", 2) end
        end)
        PX.slider("🌪️  Dönme Hızı", 1, 20, 10, function(v) spinSpeed = v end)
    end

    -- Yerçekimi
    do
        local origGravity = workspace.Gravity
        PX.slider("🪐  Yerçekimi", 10, 400, math.clamp(math.floor(origGravity + 0.5), 10, 400), function(v)
            workspace.Gravity = v
        end)
        PX.onLock[#PX.onLock + 1] = function() workspace.Gravity = origGravity end
        PX.button("♻️  Yerçekimini Normale Döndür", function()
            workspace.Gravity = origGravity
            notify("Yerçekimi", "Normal değere döndü.", 2)
        end)
    end

    createSection(PremiumPage, "👑  PREMİUM GÖRÜNÜM")

    -- Fullbright
    do
        local saved = nil
        PX.toggle("💡  Fullbright (Her Yer Aydınlık)", function(v)
            pcall(function()
                if v then
                    saved = {
                        Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime,
                        FogEnd = Lighting.FogEnd, GlobalShadows = Lighting.GlobalShadows,
                        Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient,
                    }
                    Lighting.Brightness = 2
                    Lighting.ClockTime = 14
                    Lighting.FogEnd = 100000
                    Lighting.GlobalShadows = false
                    Lighting.Ambient = Color3.fromRGB(178, 178, 178)
                    Lighting.OutdoorAmbient = Color3.fromRGB(178, 178, 178)
                    notify("Fullbright", "Her yer aydınlandı!", 2)
                elseif saved then
                    for k, val in pairs(saved) do Lighting[k] = val end
                    saved = nil
                end
            end)
        end)
    end

    -- Gökkuşağı aura
    do
        local rainbowOn, hl = false, nil
        bind(RunService.Heartbeat, function()
            if not rainbowOn then return end
            local char = LocalPlayer.Character
            if not char then return end
            if not hl or hl.Parent ~= char then
                if hl then hl:Destroy() end
                hl = new("Highlight", {
                    Name = "EZRAGOX_Rainbow", FillTransparency = 0.35, OutlineTransparency = 0,
                    OutlineColor = Color3.new(1, 1, 1),
                }, char)
            end
            hl.FillColor = Color3.fromHSV((os.clock() * 0.35) % 1, 1, 1)
        end)
        PX.toggle("🌈  Gökkuşağı Aura", function(v)
            rainbowOn = v
            if not v and hl then
                hl:Destroy()
                hl = nil
            elseif v then
                notify("Gökkuşağı Aura", "Karakterin renk değiştiriyor!", 2)
            end
        end)
    end

    -- FOV
    do
        local cam0 = workspace.CurrentCamera
        local fov0 = cam0 and cam0.FieldOfView or 70
        PX.slider("🔭  Görüş Açısı (FOV)", 40, 120, math.clamp(math.floor(fov0 + 0.5), 40, 120), function(v)
            local cam = workspace.CurrentCamera
            if cam then cam.FieldOfView = v end
        end, "°")
    end

    -- Zoom kilidi
    do
        local origMax, origMin = LocalPlayer.CameraMaxZoomDistance, LocalPlayer.CameraMinZoomDistance
        PX.toggle("🔍  Kamera Zoom Sınırını Kaldır", function(v)
            pcall(function()
                if v then
                    LocalPlayer.CameraMaxZoomDistance = 1000
                    LocalPlayer.CameraMinZoomDistance = 0.5
                    notify("Zoom", "Uzaklaşma sınırı kaldırıldı.", 2)
                else
                    LocalPlayer.CameraMaxZoomDistance = origMax
                    LocalPlayer.CameraMinZoomDistance = origMin
                end
            end)
        end)
    end

    -- Gün saati
    PX.slider("🌙  Gün Saati", 0, 24, math.clamp(math.floor(Lighting.ClockTime), 0, 24), function(v)
        pcall(function() Lighting.ClockTime = v end)
    end, " sa")

    createSection(PremiumPage, "👑  PREMİUM KIYAFET DEĞİŞTİRİCİ")

    -- Başka bir kullanıcının görünümünü kuşan
    do
        -- Sağdaki dönen karakter önizlemesi (fareyle üzerine gelinen oyuncuyu gösterir)
        local hoverTok, shownP = 0, nil
        local function viewportOk()
            local cam = MenuCharViewport.CurrentCamera
            return MenuCharViewport:FindFirstChildOfClass("Model") ~= nil
                and cam ~= nil and cam.Parent == MenuCharViewport
        end
        local function previewPlayer(plr)
            hoverTok = hoverTok + 1
            local my = hoverTok
            task.delay(0.12, function()
                if not alive or my ~= hoverTok or not refreshMenuAvatar then return end
                if plr ~= nil then
                    shownP = plr
                    pcall(refreshMenuAvatar, plr)
                    return
                end
                -- Kendi karakterime dön (boş kalırsa 3 kereye kadar tekrar dene)
                if shownP == nil and viewportOk() then return end
                shownP = nil
                for _ = 1, 3 do
                    pcall(refreshMenuAvatar, LocalPlayer)
                    if my ~= hoverTok or viewportOk() then break end
                    task.wait(0.3)
                end
            end)
        end

        -- Mod: "global" = Roblox'taki herhangi biri, "server" = bu sunucudaki oyuncular
        local mode = "global"
        local modeRow = baseRow(PremiumPage, "Frame", 46)
        local modeBtns = {}
        local function makeModeBtn(key, text, xScale, xOff)
            local b = new("TextButton", {
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(xScale, xOff, 0.5, 0),
                Size = UDim2.new(0.5, -14, 0, 32),
                BackgroundColor3 = Color3.fromRGB(28, 14, 20),
                AutoButtonColor = false, Text = text,
                Font = Enum.Font.GothamBold, TextSize = 12,
                TextColor3 = Color3.fromRGB(228, 233, 245), ZIndex = 4,
            }, modeRow)
            corner(b, 8)
            modeBtns[key] = {btn = b, st = stroke(b, 1, Color3.fromRGB(135, 40, 55), 0.3)}
            return b
        end
        makeModeBtn("global", "🌍  Genel Kullanıcı", 0, 10)
        makeModeBtn("server", "🖥️  Server İçinde", 0.5, 4)

        local _, nameBox, nameLbl = PX.inputRow(PremiumPage, "Genel Kullanıcı", "Roblox kullanıcı adı yaz")
        nameLbl.TextSize = 12
        nameLbl.TextWrapped = true
        nameLbl.Size = UDim2.new(0, 80, 0, 36)
        nameLbl.Position = UDim2.new(0, 14, 0.5, -18)

        local listFrame = new("ScrollingFrame", {
            LayoutOrder = nextOrder(PremiumPage),
            Size = UDim2.new(1, 0, 0, 0),
            BackgroundColor3 = ROW_BG, BackgroundTransparency = 0.05,
            BorderSizePixel = 0, ScrollBarThickness = 3,
            ScrollBarImageColor3 = Color3.fromRGB(255, 42, 58),
            CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible = false, ZIndex = 3,
        }, PremiumPage)
        corner(listFrame, 12)
        stroke(listFrame, 1, ROW_STROKE, 0.32)
        new("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4)}, listFrame)
        new("UIPadding", {PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6),
            PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6)}, listFrame)

        local busy = false

        -- Varlığı (asset) yükle: önce InsertService, olmazsa game:GetObjects
        local function loadAsset(id)
            local model
            local ok = pcall(function()
                model = game:GetService("InsertService"):LoadAsset(id)
            end)
            if ok and model then return model end
            local ok2, objs = pcall(function() return game:GetObjects("rbxassetid://" .. id) end)
            if ok2 and objs and objs[1] then return objs[1] end
            return nil
        end

        -- Yedek yöntem: ApplyDescription çalışmazsa parçaları elle uygula
        local function manualApply(char, hum, desc)
            -- Vücut renkleri
            local bc = char:FindFirstChildOfClass("BodyColors")
            if not bc then bc = Instance.new("BodyColors") bc.Parent = char end
            bc.HeadColor3, bc.TorsoColor3 = desc.HeadColor, desc.TorsoColor
            bc.LeftArmColor3, bc.RightArmColor3 = desc.LeftArmColor, desc.RightArmColor
            bc.LeftLegColor3, bc.RightLegColor3 = desc.LeftLegColor, desc.RightLegColor

            -- Eski aksesuar ve kıyafetleri temizle
            for _, v in ipairs(char:GetChildren()) do
                if v:IsA("Accessory") or v:IsA("Shirt") or v:IsA("Pants") or v:IsA("ShirtGraphic") then
                    v:Destroy()
                end
            end

            local function addClothing(id, className)
                if not id or id == 0 then return end
                local m = loadAsset(id)
                local item = m and m:FindFirstChildWhichIsA(className, true)
                if item then item:Clone().Parent = char end
            end
            addClothing(desc.Shirt, "Shirt")
            addClothing(desc.Pants, "Pants")
            addClothing(desc.GraphicTShirt, "ShirtGraphic")

            local added = 0
            for _, info in ipairs(desc:GetAccessories(true)) do
                local m = loadAsset(info.AssetId)
                local acc = m and m:FindFirstChildWhichIsA("Accessory", true)
                if acc then
                    local okAdd = pcall(function() hum:AddAccessory(acc:Clone()) end)
                    if okAdd then added += 1 end
                end
            end

            -- Yüz
            if desc.Face and desc.Face ~= 0 then
                local head = char:FindFirstChild("Head")
                local m = loadAsset(desc.Face)
                local decal = m and m:FindFirstChildWhichIsA("Decal", true)
                if head and decal then
                    local old = head:FindFirstChildOfClass("Decal")
                    if old then old:Destroy() end
                    decal:Clone().Parent = head
                end
            end
            return added
        end

        local function countAcc(char)
            local n = 0
            for _, v in ipairs(char:GetChildren()) do
                if v:IsA("Accessory") then n += 1 end
            end
            return n
        end

        -- Kaynak modelden (aksesuar / kıyafet / renk) parçaları karakterine kopyala
        local function applyFromModel(char, hum, desc, src)
            local accs, cloths = {}, {}
            for _, v in ipairs(src:GetChildren()) do
                if v:IsA("Accessory") then
                    accs[#accs + 1] = v
                elseif v:IsA("Shirt") or v:IsA("Pants") or v:IsA("ShirtGraphic") or v:IsA("BodyColors") then
                    cloths[#cloths + 1] = v
                end
            end
            if #accs + #cloths == 0 then error("kaynakta aksesuar/kıyafet yok") end

            -- Yeni görünüm hazır: eskisini temizle
            for _, v in ipairs(char:GetChildren()) do
                if v:IsA("Accessory") or v:IsA("Shirt") or v:IsA("Pants")
                    or v:IsA("ShirtGraphic") or v:IsA("BodyColors") then
                    pcall(function() v:Destroy() end)
                end
            end

            for _, v in ipairs(cloths) do pcall(function() v:Clone().Parent = char end) end
            for _, v in ipairs(accs) do pcall(function() hum:AddAccessory(v:Clone()) end) end

            -- Yüz ve kafa şekli
            pcall(function()
                local rh, ch = src:FindFirstChild("Head"), char:FindFirstChild("Head")
                if rh and ch then
                    local rf = rh:FindFirstChildOfClass("Decal")
                    if rf then
                        local old = ch:FindFirstChildOfClass("Decal")
                        if old then old:Destroy() end
                        rf:Clone().Parent = ch
                    end
                    local rm = rh:FindFirstChildOfClass("SpecialMesh")
                    if rm then
                        local om = ch:FindFirstChildOfClass("SpecialMesh")
                        if om then om:Destroy() end
                        rm:Clone().Parent = ch
                    end
                end
            end)

            -- Vücut parçaları (renk, mesh, doku)
            for _, rp in ipairs(src:GetChildren()) do
                local cp = char:FindFirstChild(rp.Name)
                if cp and rp:IsA("BasePart") and cp:IsA("BasePart") then
                    pcall(function()
                        cp.Color = rp.Color
                        if rp:IsA("MeshPart") and cp:IsA("MeshPart") then
                            cp.MeshId = rp.MeshId
                            cp.TextureID = rp.TextureID
                        end
                    end)
                end
            end

            -- Boy / genişlik
            if desc then
                pcall(function()
                    local rs = {
                        BodyHeightScale = desc.HeightScale, BodyWidthScale = desc.WidthScale,
                        BodyDepthScale = desc.DepthScale, HeadScale = desc.HeadScale,
                    }
                    for name, val in pairs(rs) do
                        local nv = hum:FindFirstChild(name)
                        if nv then nv.Value = val end
                    end
                end)
            end
        end

        local function applyLook(userId, label, srcPlr)
            if busy then return end
            busy = true
            task.spawn(function()
                local errs, usedMethod = {}, nil
                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")

                if not hum then
                    errs[#errs + 1] = "karakter/Humanoid yok"
                else
                    local desc
                    for i = 1, 3 do
                        local s, r = pcall(function()
                            return Players:GetHumanoidDescriptionFromUserId(userId)
                        end)
                        if s and r then desc = r break end
                        errs[#errs + 1] = "desc: " .. tostring(r)
                        task.wait(1)
                    end

                    local expected = 0
                    if desc then pcall(function() expected = #desc:GetAccessories(true) end) end
                    local function verified() return expected == 0 or countAcc(char) > 0 end

                    local steps = {
                        {"ApplyDescription", function()
                            assert(desc, "desc yok")
                            local s, e = pcall(function() hum:ApplyDescriptionReset(desc) end)
                            if not s then hum:ApplyDescription(desc) end
                        end},
                        {"CharacterAppearance", function()
                            local m = Players:GetCharacterAppearanceAsync(userId)
                            applyFromModel(char, hum, desc, m)
                            pcall(function() m:Destroy() end)
                        end},
                        {"CanlıKarakter", function()
                            assert(srcPlr and srcPlr.Character, "oyuncunun karakteri yüklü değil")
                            applyFromModel(char, hum, desc, srcPlr.Character)
                        end},
                        {"Model", function()
                            assert(desc, "desc yok")
                            local rig
                            pcall(function() rig = Players:CreateHumanoidModelFromDescription(desc, hum.RigType) end)
                            if not rig then rig = Players:CreateHumanoidModelFromUserId(userId) end
                            applyFromModel(char, hum, desc, rig)
                            pcall(function() rig:Destroy() end)
                        end},
                        {"LoadAsset", function()
                            assert(desc, "desc yok")
                            manualApply(char, hum, desc)
                        end},
                    }

                    for _, step in ipairs(steps) do
                        local s, e = pcall(step[2])
                        if s and verified() then
                            usedMethod = step[1]
                            break
                        end
                        errs[#errs + 1] = step[1] .. ": " .. (s and "aksesuar eklenmedi" or tostring(e))
                    end

                    -- Oyun aksesuarları geri siliyor mu?
                    if usedMethod and expected > 0 then
                        task.wait(1.5)
                        if countAcc(char) == 0 then
                            errs[#errs + 1] = "oyun aksesuarları siliyor"
                            usedMethod = nil
                        end
                    end
                end

                busy = false
                if usedMethod then
                    print("[EZRAGOX] Yöntem: " .. usedMethod .. " | Aksesuar: " .. countAcc(char))
                    notify("Görünüm Kuşanıldı 👕", label .. " görünümü uygulandı.", 4)
                else
                    warn("[EZRAGOX] Görünüm hataları:\n" .. table.concat(errs, "\n"))
                    notify("Kuşanılamadı", tostring(errs[#errs] or "bilinmiyor"):sub(1, 110), 6)
                end
            end)
        end
        local selectedPlr = nil
        local thumbCache = {}
        local rowRefs = {}
        local applyBtn

        local function shownMatches()
            local f = string.lower((nameBox.Text or ""):gsub("%s", "") )
            local out = {}
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer then
                    local n, d = string.lower(plr.Name), string.lower(plr.DisplayName)
                    if f == "" or n:sub(1, #f) == f or d:sub(1, #f) == f
                        or n:find(f, 1, true) or d:find(f, 1, true) then
                        out[#out + 1] = plr
                    end
                end
            end
            return out
        end

        local function updateApplyLabel()
            local l = applyBtn and applyBtn:FindFirstChildOfClass("TextLabel")
            if not l then return end
            l.TextTruncate = Enum.TextTruncate.AtEnd
            if mode == "server" and selectedPlr then
                setText(l, "👕  Uygula  →  " .. selectedPlr.DisplayName .. " (@" .. selectedPlr.Name .. ")")
            elseif mode == "server" then
                setText(l, "👕  Seçilen Oyuncuyu Kopyala")
            else
                setText(l, "👕  Karakteri Komple Kopyala  (Saç • Üst • Alt • Aksesuar)")
            end
        end

        local function applySelectionStyles()
            for plr, r in pairs(rowRefs) do
                local sel = (plr == selectedPlr)
                if r.btn.Parent then
                    r.btn.BackgroundColor3 = sel and Color3.fromRGB(70, 14, 28) or Color3.fromRGB(28, 14, 20)
                    r.st.Color = sel and Color3.fromRGB(255, 42, 58) or Color3.fromRGB(135, 40, 55)
                    r.st.Transparency = sel and 0.05 or 0.55
                    r.mark.Visible = sel
                end
            end
        end

        local function wantListVisible() return mode == "server" and PX.unlocked end
        bind(listFrame:GetPropertyChangedSignal("Visible"), function()
            local want = wantListVisible()
            if listFrame.Visible ~= want then listFrame.Visible = want end
        end)

        local function refreshList()
            previewPlayer(nil)
            table.clear(rowRefs)
            for _, ch in ipairs(listFrame:GetChildren()) do
                if ch:IsA("TextButton") or ch:IsA("TextLabel") then ch:Destroy() end
            end
            if mode ~= "server" then
                listFrame.Visible = false
                listFrame.Size = UDim2.new(1, 0, 0, 0)
                previewPlayer(nil)
                return
            end

            local matches = shownMatches()
            if selectedPlr and not selectedPlr.Parent then selectedPlr = nil end

            if #matches == 0 then
                new("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1,
                    Text = "Eşleşen oyuncu yok", Font = Enum.Font.GothamMedium, TextSize = 12,
                    TextColor3 = Color3.fromRGB(150, 163, 195), ZIndex = 4,
                }, listFrame)
            end

            for _, plr in ipairs(matches) do
                local isSel = (plr == selectedPlr)
                local pBtn = new("TextButton", {
                    Size = UDim2.new(1, 0, 0, 36),
                    BackgroundColor3 = isSel and Color3.fromRGB(70, 14, 28) or Color3.fromRGB(28, 14, 20),
                    BackgroundTransparency = 0.1, AutoButtonColor = false, Text = "", ZIndex = 4,
                }, listFrame)
                corner(pBtn, 8)
                local pst = stroke(pBtn, 1, isSel and Color3.fromRGB(255, 42, 58) or Color3.fromRGB(135, 40, 55),
                    isSel and 0.05 or 0.55)

                local avImg = new("ImageLabel", {
                    Position = UDim2.new(0, 4, 0, 2), Size = UDim2.new(0, 32, 0, 32),
                    BackgroundTransparency = 1, Image = thumbCache[plr.UserId] or "", ZIndex = 5,
                }, pBtn)
                pill(avImg)
                if not thumbCache[plr.UserId] then
                    task.spawn(function()
                        local ok, thumb = pcall(function()
                            return Players:GetUserThumbnailAsync(plr.UserId,
                                Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
                        end)
                        if ok and thumb then
                            thumbCache[plr.UserId] = thumb
                            if avImg.Parent then avImg.Image = thumb end
                        end
                    end)
                end

                new("TextLabel", {
                    Position = UDim2.new(0, 44, 0, 0), Size = UDim2.new(1, -70, 1, 0),
                    BackgroundTransparency = 1, Text = plr.DisplayName .. " (@" .. plr.Name .. ")",
                    TextColor3 = Color3.new(1, 1, 1), TextSize = 12, Font = Enum.Font.GothamMedium,
                    TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
                    ZIndex = 5,
                }, pBtn)
                local mark = new("TextLabel", {
                    AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0),
                    Size = UDim2.new(0, 18, 0, 18), BackgroundTransparency = 1, Text = "✓",
                    Font = Enum.Font.GothamBold, TextSize = 14,
                    TextColor3 = Color3.fromRGB(255, 112, 122), ZIndex = 5, Visible = isSel,
                }, pBtn)
                rowRefs[plr] = {btn = pBtn, st = pst, mark = mark}

                -- Üzerine gelince sağdaki dönen karakter bu oyuncu olur
                pBtn.MouseEnter:Connect(function()
                    tween(pBtn, 0.12, {BackgroundColor3 = Color3.fromRGB(48, 12, 22), BackgroundTransparency = 0})
                    tween(pst, 0.12, {Color = Color3.fromRGB(255, 42, 58), Transparency = 0.1})
                    previewPlayer(plr)
                end)
                pBtn.MouseLeave:Connect(function()
                    local sel = (plr == selectedPlr)
                    tween(pBtn, 0.18, {
                        BackgroundColor3 = sel and Color3.fromRGB(70, 14, 28) or Color3.fromRGB(28, 14, 20),
                        BackgroundTransparency = 0.1,
                    })
                    tween(pst, 0.18, {
                        Color = sel and Color3.fromRGB(255, 42, 58) or Color3.fromRGB(135, 40, 55),
                        Transparency = sel and 0.05 or 0.55,
                    })
                    previewPlayer(nil)
                end)
                pBtn.MouseButton1Click:Connect(function()
                    playClickSound()
                    selectedPlr = plr
                    updateApplyLabel()
                    applySelectionStyles()
                    previewPlayer(nil)   -- seçince sağdaki karakter tekrar benim karakterime döner
                end)
            end

            listFrame.Visible = wantListVisible()
            listFrame.Size = UDim2.new(1, 0, 0, math.min(math.max(#matches, 1) * 40 + 12, 176))
        end

        local function setMode(m)
            mode = m
            for key, d in pairs(modeBtns) do
                local on = (key == m)
                tween(d.btn, 0.16, {BackgroundColor3 = on and Color3.fromRGB(140, 20, 36) or Color3.fromRGB(28, 14, 20)})
                tween(d.st, 0.16, {
                    Color = on and Color3.fromRGB(255, 42, 58) or Color3.fromRGB(135, 40, 55),
                    Transparency = on and 0.05 or 0.3,
                })
            end
            if m == "server" then
                setText(nameLbl, "Server İçinde")
                setPlaceholder(nameBox, "İsmin başını yaz, liste süzülür")
            else
                setText(nameLbl, "Genel Kullanıcı")
                setPlaceholder(nameBox, "Roblox kullanıcı adı yaz")
            end
            updateApplyLabel()
            refreshList()
        end

        bind(modeBtns.global.btn.MouseButton1Click, function() playClickSound() setMode("global") end)
        bind(modeBtns.server.btn.MouseButton1Click, function() playClickSound() setMode("server") end)
        bind(nameBox:GetPropertyChangedSignal("Text"), function()
            if mode == "server" then refreshList() end
        end)
        bind(Players.PlayerAdded, function() if mode == "server" then refreshList() end end)
        bind(Players.PlayerRemoving, function(plr)
            if plr == selectedPlr then selectedPlr = nil updateApplyLabel() end
            task.defer(function() if mode == "server" then refreshList() end end)
        end)
        bind(PremiumPage:GetPropertyChangedSignal("Visible"), function()
            if not PremiumPage.Visible then previewPlayer(nil) end
        end)

        applyBtn = PX.button("👕  Karakteri Komple Kopyala  (Saç • Üst • Alt • Aksesuar)", function()
            if mode == "server" then
                local target = selectedPlr
                if not (target and target.Parent) then
                    local m = shownMatches()
                    if #m == 1 then
                        target = m[1]
                    else
                        notify("Oyuncu Seçilmedi", "Listeden bir oyuncu seç (ya da adını yaz).", 3)
                        return
                    end
                end
                applyLook(target.UserId, target.Name, target)
            else
                local name = nameBox.Text:gsub("%s", "")
                if name == "" then
                    notify("Kullanıcı Adı Boş", "Önce bir Roblox kullanıcı adı yaz.", 3)
                    return
                end
                task.spawn(function()
                    local id = PX.resolveUserId(name)
                    if id then
                        applyLook(id, name)
                    else
                        notify("Kullanıcı Bulunamadı", name, 3)
                    end
                end)
            end
        end)
        PX.button("♻️  Kendi Görünümüme Dön", function()
            applyLook(LocalPlayer.UserId, "Kendi")
        end)

        setMode("global")
    end

    createSection(PremiumPage, "👑  PREMİUM OTO TOPLAYICI")

    -- Haritada spawn olan para / altın / gem gibi şeyleri otomatik toplar
    do
        local enabled, runId = false, 0
        local cands = {}          -- [part] = {tries, nextAt, touched}
        local pending = {}        -- yeni eklenen ve henüz incelenmemiş nesneler
        local collected = 0
        local speedLevel = 3      -- 1 = en yavaş/temkinli, 10 = en hızlı

        local BASE_WORDS = {
            "coin", "gold", "cash", "money", "gem", "para", "altin", "altın", "diamond",
            "crystal", "orb", "token", "loot", "collect", "pickup", "dollar", "reward",
            "currency", "treasure", "bill", "nugget",
        }
        local DENY_WORDS = {
            "shop", "store", "sell", "buy", "upgrade", "rebirth", "gate", "door",
            "teleport", "button", "portal",
        }

        local _, customBox = PX.inputRow(PremiumPage, "Özel İsim", "örn: Coin, Gold  (boş = otomatik bul)")

        local function hasWord(name, words)
            for _, w in ipairs(words) do
                if string.find(name, w, 1, true) then return true end
            end
            return false
        end

        local function customWords()
            local t = {}
            for w in string.gmatch(string.lower(customBox.Text or ""), "[^,%s]+") do
                t[#t + 1] = w
            end
            return #t > 0 and t or nil
        end

        local function isCharPart(part)
            local m = part:FindFirstAncestorOfClass("Model")
            while m do
                if Players:GetPlayerFromCharacter(m) then return true end
                local par = m.Parent
                m = par and par:FindFirstAncestorOfClass("Model") or nil
            end
            return false
        end

        local function nameMatches(part, custom)
            if not custom then
                local own = string.lower(part.Name)
                local par = part.Parent and string.lower(part.Parent.Name) or ""
                if hasWord(own, DENY_WORDS) or hasWord(par, DENY_WORDS) then return false end
            end
            local words = custom or BASE_WORDS
            local node, depth = part, 0
            while node and node ~= workspace and depth < 4 do
                if hasWord(string.lower(node.Name), words) then return true end
                node = node.Parent
                depth = depth + 1
            end
            return false
        end

        local function considerPart(part, custom, target)
            if target[part] or not part:IsA("BasePart") or part:IsA("Terrain") then return end
            if isCharPart(part) then return end
            if not nameMatches(part, custom) then return end
            local interactive = part:FindFirstChildWhichIsA("TouchTransmitter")
                or part:FindFirstChildWhichIsA("ProximityPrompt", true)
                or part:FindFirstChildWhichIsA("ClickDetector", true)
            -- Otomatik modda sadece etkileşimli (dokunulabilir/prompt'lu) parçalar alınır
            if not custom and not interactive then return end
            target[part] = {tries = 0, nextAt = 0, touched = false}
        end

        local function enqueue(inst)
            if #pending > 5000 then return end
            if inst:IsA("BasePart") then
                pending[#pending + 1] = inst
            elseif inst:IsA("TouchTransmitter") or inst:IsA("ProximityPrompt") or inst:IsA("ClickDetector") then
                local part = inst:FindFirstAncestorWhichIsA("BasePart")
                if part then pending[#pending + 1] = part end
            end
        end

        local function processPending(custom)
            local n = 0
            while #pending > 0 and n < 300 do
                local inst = table.remove(pending)
                if inst and inst.Parent then pcall(considerPart, inst, custom, cands) end
                n = n + 1
            end
        end

        -- Tüm haritayı tara (donmasın diye parça parça)
        local function scanInto(target, custom)
            local count = 0
            local list = workspace:GetDescendants()
            for i, inst in ipairs(list) do
                if inst:IsA("BasePart") then
                    local before = target[inst]
                    pcall(considerPart, inst, custom, target)
                    if not before and target[inst] then count = count + 1 end
                end
                if i % 1500 == 0 then task.wait() end
            end
            return count
        end

        bind(workspace.DescendantAdded, function(inst)
            if enabled then enqueue(inst) end
        end)

        local function interact(part, hrp)
            local used = false
            local prompt = part:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt and type(fireproximityprompt) == "function" then
                pcall(fireproximityprompt, prompt)
                used = true
            end
            local cd = part:FindFirstChildWhichIsA("ClickDetector", true)
            if cd and type(fireclickdetector) == "function" then
                pcall(fireclickdetector, cd)
                used = true
            end
            if type(firetouchinterest) == "function" and part:FindFirstChildWhichIsA("TouchTransmitter") then
                pcall(function()
                    firetouchinterest(hrp, part, 0)
                    firetouchinterest(hrp, part, 1)
                end)
                used = true
            end
            return used
        end

        -- En yakın hazır parçayı seç (hepsini birden değil, tek tek gidilecek)
        local function pickNearest(hrp, now)
            local best, bestInfo, bestD
            local pos = hrp.Position
            for part, info in pairs(cands) do
                if not part.Parent then
                    if info.touched then collected = collected + 1 end
                    cands[part] = nil
                elseif now >= info.nextAt and part.CanTouch ~= false then
                    local d = (part.Position - pos).Magnitude
                    if not bestD or d < bestD then best, bestInfo, bestD = part, info, d end
                end
            end
            return best, bestInfo
        end

        -- Tek parça: doğrudan paranın üstüne ışınlan (süzülme yok), kısa bekle
        local function pickupOne(part, info, hrp)
            info.tries = info.tries + 1
            info.touched = true
            pcall(function()
                hrp.CFrame = CFrame.new(part.Position)
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
            end)
            -- Önce fiziksel temasın gerçekleşmesine izin ver
            RunService.Heartbeat:Wait()
            RunService.Heartbeat:Wait()
            -- Yetmediyse yedek etkileşim (artık paranın tam üstündeyken)
            if part.Parent then interact(part, hrp) end
            task.wait(0.2 + math.random() * 0.15)
            if info.tries >= 3 and part.Parent then
                info.tries = 0
                info.nextAt = os.clock() + 20   -- toplanamayanı 20 sn beklet
            else
                info.nextAt = os.clock() + 1
            end
        end

        local function collectLoop(myRun)
            local homeCF, idleSince = nil, nil
            while enabled and alive and myRun == runId do
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if hrp and hum and hum.Health > 0 then
                    processPending(customWords())
                    local part, info = pickNearest(hrp, os.clock())
                    if part then
                        idleSince = nil
                        if not homeCF then homeCF = hrp.CFrame end
                        pickupOne(part, info, hrp)
                        -- Hız ayarına göre bekle (hafif rastgele sapmayla)
                        local delay = 2.5 - (speedLevel - 1) * (2.2 / 9)
                        task.wait(delay * (0.8 + math.random() * 0.4))
                    else
                        -- Toplanacak kalmadıysa başladığım yere bir kez dön
                        if homeCF then
                            idleSince = idleSince or os.clock()
                            if os.clock() - idleSince > 1.2 then
                                pcall(function()
                                    hrp.CFrame = homeCF
                                    hrp.AssemblyLinearVelocity = Vector3.zero
                                end)
                                homeCF, idleSince = nil, nil
                            end
                        end
                        task.wait(0.25)
                    end
                else
                    homeCF, idleSince = nil, nil
                    task.wait(0.5)
                end
            end
            -- Kapatıldıysa başladığım yere dön
            if homeCF and not enabled then
                local c = LocalPlayer.Character
                local h = c and c:FindFirstChild("HumanoidRootPart")
                if h then pcall(function() h.CFrame = homeCF end) end
            end
        end

        PX.toggle("💰  Otomatik Para / Altın Topla  (Tüm Harita)", function(v)
            enabled = v
            runId = runId + 1
            local myRun = runId
            if v then
                collected = 0
                table.clear(cands)
                table.clear(pending)
                local hasFns = type(firetouchinterest) == "function"
                notify("Oto Toplayıcı", hasFns and "En yakın paradan başlayıp tek tek toplanacak."
                    or "Executor dokunma fonksiyonu yok: paranın üstüne ışınlanarak toplanacak.", 3)
                task.spawn(function()
                    local n = scanInto(cands, customWords())
                    if enabled and myRun == runId and n == 0 then
                        notify("Para Bulunamadı", "Şu an eşleşen yok. Yeni spawn olanlar otomatik alınır. İstersen 'Özel İsim' yaz.", 5)
                    end
                end)
                task.spawn(collectLoop, myRun)
            else
                table.clear(cands)
                table.clear(pending)
                notify("Oto Toplayıcı Kapandı", collected .. " parça toplandı.", 3)
            end
        end)

        PX.slider("⚡  Toplama Hızı  (düşük = daha temkinli)", 1, 10, 3, function(v)
            speedLevel = v
        end)

        bind(customBox.FocusLost, function()
            if not enabled then return end
            runId = runId + 1
            local myRun = runId
            table.clear(cands)
            table.clear(pending)
            task.spawn(function() scanInto(cands, customWords()) end)
            task.spawn(collectLoop, myRun)
        end)

        PX.button("🔍  Haritadaki Paraları Tara  (Kaç Tane Var?)", function()
            task.spawn(function()
                local tmp = {}
                local total = scanInto(tmp, customWords())
                if total == 0 then
                    notify("Tarama Bitti", "Hiç bulunamadı. 'Özel İsim' kutusuna paranın adını yaz (örn: Coin).", 5)
                    return
                end
                local groups = {}
                for part in pairs(tmp) do groups[part.Name] = (groups[part.Name] or 0) + 1 end
                local arr = {}
                for name, c in pairs(groups) do arr[#arr + 1] = {name, c} end
                table.sort(arr, function(a, b) return a[2] > b[2] end)
                local out = {}
                for i = 1, math.min(#arr, 4) do out[#out + 1] = arr[i][1] .. " ×" .. arr[i][2] end
                print("[EZRAGOX] Tarama sonucu:")
                for _, a in ipairs(arr) do print("  " .. a[1] .. " ×" .. a[2]) end
                notify("Tarama: " .. total .. " parça", table.concat(out, "  •  "), 6)
            end)
        end)
    end

    createSection(PremiumPage, "👑  PREMİUM ARAÇLAR")

    -- Anti-AFK
    do
        local afkConn = nil
        PX.toggle("🛡️  Anti-AFK (Atılmayı Engelle)", function(v)
            if afkConn then
                afkConn:Disconnect()
                afkConn = nil
            end
            if v then
                afkConn = LocalPlayer.Idled:Connect(function()
                    pcall(function()
                        local vu = game:GetService("VirtualUser")
                        vu:CaptureController()
                        vu:ClickButton2(Vector2.new())
                    end)
                end)
                conns[#conns + 1] = afkConn
                notify("Anti-AFK", "Aktif! Boşta kalsan da atılmazsın.", 2)
            end
        end)
    end

    PX.button("🔄  Sunucuya Yeniden Gir (Rejoin)", function()
        notify("Rejoin", "Aynı sunucuya yeniden bağlanılıyor...", 3)
        pcall(function()
            local ts = game:GetService("TeleportService")
            if #Players:GetPlayers() <= 1 then
                ts:Teleport(game.PlaceId, LocalPlayer)
            else
                ts:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
            end
        end)
    end)

    PX.button("📋  Sunucu ID'sini Kopyala (JobId)", function()
        if PX.copy(game.JobId) then
            notify("Kopyalandı", "Sunucu ID panoya kopyalandı.", 2)
        else
            notify("Kopyalanamadı", "Executor panoya yazmayı desteklemiyor.", 3)
        end
    end)

    PX.button("🎮  Oyun ID'sini Kopyala (PlaceId)", function()
        if PX.copy(tostring(game.PlaceId)) then
            notify("Kopyalandı", "Oyun ID panoya kopyalandı.", 2)
        else
            notify("Kopyalanamadı", "Executor panoya yazmayı desteklemiyor.", 3)
        end
    end)

    collectNew(PremiumPage, before, PX.premiumRows)
end

function PX.setPremium(v, viaAdmin)
    PX.unlocked = v and true or false
    for _, r in ipairs(PX.lockRows) do r.Visible = not PX.unlocked end
    for _, r in ipairs(PX.premiumRows) do r.Visible = PX.unlocked end
    if not PX.unlocked then
        for _, o in ipairs(PX.toggles) do pcall(o.Set, false, true, true) end
        for _, f in ipairs(PX.onLock) do pcall(f) end
    else
        for _, o in ipairs(PX.toggles) do
            if Settings.ToggleStates[o.Key] == true then pcall(o.Set, true) end
        end
    end
    if PX.statusBody then
        if viaAdmin then
            setText(PX.statusBody, "Yönetici erişimi ile açık.")
        else
            setText(PX.statusBody, "Hesap: " .. LocalPlayer.Name .. "  •  premium tanımlı.")
        end
    end
end

function PX.dbRequest(method, path, body, auth)
    local req = request or http_request or (syn and syn.request)
    if not req or KEY_DB_URL == "" then return nil end
    local base = KEY_DB_URL:gsub("/+$", "")
    local url = base .. "/" .. path .. ".json"
    if auth and auth ~= "" then url = url .. "?auth=" .. auth end
    local ok, res = pcall(req, {
        Url = url, Method = method, Headers = {["Content-Type"] = "application/json"},
        Body = (body ~= nil) and HttpService:JSONEncode(body) or nil,
    })
    if not ok or type(res) ~= "table" then return nil end
    return res
end

function PX.isListed()
    local lname = LocalPlayer.Name:lower()
    for _, n in ipairs(PREMIUM_NAMES) do
        if tostring(n):lower() == lname then return true end
    end
    return false
end

-- Bu hesapta premium var mı? (koddaki liste + veritabanı)
function PX.checkPremium(silent)
    if PX.admin then return end
    local has, offline = PX.isListed(), false
    if not has and KEY_DB_URL ~= "" then
        local res = PX.dbRequest("GET", "ezragox_premium/" .. LocalPlayer.UserId)
        if res and res.StatusCode == 200 then
            has = (res.Body ~= nil and res.Body ~= "null" and res.Body ~= "")
        else
            offline = true
        end
    end
    if has then
        local was = PX.unlocked
        PX.setPremium(true, false)
        if not silent or not was then notify("Premium Aktif 👑", "Hesabın için premium tanımlı, hoş geldin!", 4) end
    elseif not offline then
        PX.setPremium(false)
        if not silent then notify("Premium Yok", LocalPlayer.Name .. " hesabında premium tanımlı değil.", 4) end
    elseif not silent then
        notify("Bağlantı Hatası", "Premium sunucusuna ulaşılamadı. Tekrar dene.", 4)
    end
end

PX.setPremium(false)
task.spawn(function() PX.checkPremium(true) end)
-- Premium durumunu 20 saniyede bir yeniden kontrol et (kaldırılınca kısa sürede kapanır)
task.spawn(function()
    while alive do
        task.wait(20)
        if KEY_DB_URL ~= "" then pcall(PX.checkPremium, true) end
    end
end)

---------------------------------------------------------
-- YÖNETİM SEKMESİ (GİZLİ — SADECE ŞİFREYLE AÇILIR)
---------------------------------------------------------
function PX.secret()
    local s = ""
    pcall(function()
        if isfile and readfile and isfile(SECRET_FILE) then s = readfile(SECRET_FILE) end
    end)
    s = s:gsub("%s", "")
    return s
end

function PX.resolveUserId(name)
    local id
    local ok = pcall(function() id = Players:GetUserIdFromNameAsync(name) end)
    if ok and id then return id end
    return nil
end

function PX.addUserRow(name, userId)
    if PX.rows[userId] and PX.rows[userId].Parent then return end
    local btn
    btn = createButton(AdminPage, "👤  " .. name .. "   •   tıkla = premiumu kaldır", function()
        PX.revoke(userId, name)
    end)
    local l = btn:FindFirstChildOfClass("TextLabel")
    if l then l.TextColor3 = Color3.fromRGB(255, 214, 102) end
    PX.rows[userId] = btn
end

function PX.grant(rawName)
    local name = tostring(rawName or "")
    name = name:gsub("%s", "")
    if name == "" then
        notify("Kullanıcı Adı Boş", "Önce bir Roblox kullanıcı adı yaz.", 3)
        return
    end
    task.spawn(function()
        local id = PX.resolveUserId(name)
        if not id then
            notify("Kullanıcı Bulunamadı", "Bu adda bir Roblox hesabı yok: " .. name, 4)
            return
        end
        if KEY_DB_URL == "" then
            PX.copy('"' .. name:lower() .. '",')
            notify("Veritabanı Yok", "Satır panoya kopyalandı: dosyadaki PREMIUM_NAMES listesine ekle.", 6)
            return
        end
        local secret = PX.secret()
        if secret == "" then
            notify("Gizli Anahtar Yok", "Önce veritabanı gizli anahtarını kaydet.", 4)
            return
        end
        local res = PX.dbRequest("PUT", "ezragox_premium/" .. id, {name = name, grantedAt = os.time()}, secret)
        if res and res.StatusCode == 200 then
            notify("Premium Verildi 👑", name .. "  (" .. id .. ")", 4)
            PX.addUserRow(name, id)
        else
            notify("Hata", "Veritabanına yazılamadı. Adres ve gizli anahtarı kontrol et.", 5)
        end
    end)
end

function PX.revoke(userId, name)
    task.spawn(function()
        if KEY_DB_URL == "" then
            notify("Veritabanı Yok", "Listeden elle sil: PREMIUM_NAMES.", 4)
            return
        end
        local secret = PX.secret()
        if secret == "" then
            notify("Gizli Anahtar Yok", "Önce veritabanı gizli anahtarını kaydet.", 4)
            return
        end
        local res = PX.dbRequest("DELETE", "ezragox_premium/" .. userId, nil, secret)
        if res and res.StatusCode == 200 then
            notify("Premium Kaldırıldı", tostring(name or userId), 3)
            PX.checkPremium(true)
            local row = PX.rows[userId]
            if row then row:Destroy() end
            PX.rows[userId] = nil
        else
            notify("Hata", "Veritabanından silinemedi.", 4)
        end
    end)
end

function PX.loadList()
    task.spawn(function()
        local res = PX.dbRequest("GET", "ezragox_premium")
        if not res or res.StatusCode ~= 200 then
            notify("Liste Alınamadı", "Veritabanı adresini kontrol et.", 4)
            return
        end
        if res.Body == "null" then
            notify("Liste Boş", "Henüz premium verilen hesap yok.", 3)
            return
        end
        local ok, data = pcall(function() return HttpService:JSONDecode(res.Body) end)
        if not ok or type(data) ~= "table" then return end
        local n = 0
        for id, v in pairs(data) do
            local uid = tonumber(id)
            if uid then
                PX.addUserRow((type(v) == "table" and v.name) or tostring(uid), uid)
                n = n + 1
            end
        end
        notify("Liste Yüklendi", n .. " hesap bulundu.", 3)
    end)
end

createSection(AdminPage, "PREMİUM YÖNETİMİ")
PX.infoCard(AdminPage, trText("🛡️  Sadece sana özel"), trText("Premium vermek istediğin kişinin Roblox kullanıcı adını yaz. Premium o hesaba tanımlanır; kişi menüyü açınca kendi hesabıyla otomatik premium olur."), 84)
local _, userBox = PX.inputRow(AdminPage, "Kullanıcı", "Roblox kullanıcı adı (örn: hasanusta_03)")
createButton(AdminPage, "✅  Premium Ver", function() PX.grant(userBox.Text) end)
createButton(AdminPage, "❌  Premium Kaldır", function()
    local name = userBox.Text:gsub("%s", "")
    if name == "" then
        notify("Kullanıcı Adı Boş", "Önce bir Roblox kullanıcı adı yaz.", 3)
        return
    end
    task.spawn(function()
        local id = PX.resolveUserId(name)
        if id then
            PX.revoke(id, name)
        else
            notify("Kullanıcı Bulunamadı", name, 3)
        end
    end)
end)
createButton(AdminPage, "📜  Premium Listesini Yükle", function() PX.loadList() end)

createSection(AdminPage, "VERİTABANI GİZLİ ANAHTARI  (sadece bu cihazda saklanır)")
local _, secretBox = PX.inputRow(AdminPage, "Gizli Anahtar", "Firebase veritabanı gizli anahtarı")
createButton(AdminPage, "💾  Gizli Anahtarı Kaydet", function()
    local v = secretBox.Text:gsub("%s", "")
    if v == "" then
        notify("Boş", "Gizli anahtarı yapıştır.", 3)
        return
    end
    local ok = pcall(function() writefile(SECRET_FILE, v) end)
    setText(secretBox, "")
    notify(ok and "Kaydedildi" or "Kaydedilemedi", ok and "Gizli anahtar bu cihaza kaydedildi." or "Executor dosya yazmayı desteklemiyor.", 3)
end)
createButton(AdminPage, "🔒  Yönetimi Kilitle ve Gizle", function() PX.lockAdmin() end)
createSection(AdminPage, "PREMİUM OLAN HESAPLAR  (tıkla = kaldır)")

function PX.lockAdmin()
    PX.admin = false
    PX.adminTab.btn.Visible = false
    PX.setPremium(false)
    task.spawn(function() PX.checkPremium(true) end)
    selectTab(Tabs[1])
    notify("Yönetim Kilitlendi", "Sekme gizlendi.", 3)
end

---------------------------------------------------------
-- YÖNETİM ŞİFRE PENCERESİ + GİZLİ AÇMA YÖNTEMLERİ
---------------------------------------------------------
do
    local dim = new("TextButton", {
        Name = "EZRAGOX_AdminPrompt", Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.35, AutoButtonColor = false, Text = "", Visible = false, ZIndex = 60,
    }, MainFrame)
    corner(dim, 22)
    local card = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, 320, 0, 186),
        BackgroundColor3 = Color3.fromRGB(18, 9, 14), BorderSizePixel = 0, ZIndex = 61,
    }, dim)
    corner(card, 16)
    stroke(card, 1.5, Color3.fromRGB(255, 50, 68), 0.2)
    new("TextLabel", {
        Position = UDim2.new(0, 16, 0, 14), Size = UDim2.new(1, -32, 0, 22), BackgroundTransparency = 1,
        Text = "🛡️  YÖNETİM GİRİŞİ", Font = Enum.Font.GothamBlack, TextSize = 16, TextColor3 = Color3.new(1, 1, 1),
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 62,
    }, card)
    new("TextLabel", {
        Position = UDim2.new(0, 16, 0, 40), Size = UDim2.new(1, -32, 0, 16), BackgroundTransparency = 1,
        Text = "Devam etmek için yönetim şifresini gir.", Font = Enum.Font.GothamMedium, TextSize = 12,
        TextColor3 = Color3.fromRGB(150, 163, 195), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 62,
    }, card)
    local box = new("TextBox", {
        Position = UDim2.new(0, 16, 0, 68), Size = UDim2.new(1, -32, 0, 38), BackgroundColor3 = Color3.fromRGB(28, 14, 20),
        Text = "", PlaceholderText = "Şifre", PlaceholderColor3 = Color3.fromRGB(130, 100, 108),
        TextColor3 = Color3.fromRGB(255, 214, 102), TextSize = 18, Font = Enum.Font.Code,
        ClearTextOnFocus = true, ZIndex = 62,
    }, card)
    corner(box, 10)
    stroke(box, 1, Color3.fromRGB(135, 40, 55), 0.3)
    local enter = new("TextButton", {
        Position = UDim2.new(0, 16, 1, -56), Size = UDim2.new(0.5, -22, 0, 38), BackgroundColor3 = Color3.fromRGB(190, 18, 42),
        Text = "Giriş", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = Color3.new(1, 1, 1),
        AutoButtonColor = true, ZIndex = 62,
    }, card)
    corner(enter, 10)
    local cancel = new("TextButton", {
        AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 1, -56), Size = UDim2.new(0.5, -22, 0, 38),
        BackgroundColor3 = Color3.fromRGB(45, 24, 30), Text = "İptal", Font = Enum.Font.GothamBold, TextSize = 14,
        TextColor3 = Color3.fromRGB(220, 200, 205), AutoButtonColor = true, ZIndex = 62,
    }, card)
    corner(cancel, 10)

    -- Yazılanı yıldızla gizle (omuz üstünden / kayıttan görünmesin)
    local busy = false
    bind(box:GetPropertyChangedSignal("Text"), function()
        if busy then return end
        local t = box.Text
        if #t > #PX.real then
            PX.real = PX.real .. t:sub(#PX.real + 1)
        else
            PX.real = PX.real:sub(1, #t)
        end
        busy = true
        setText(box, string.rep("*", #PX.real))
        busy = false
    end)

    function PX.hidePrompt()
        dim.Visible = false
        PX.real = ""
        busy = true
        setText(box, "")
        busy = false
    end

    function PX.showPrompt()
        if not menuOpen then return end
        PX.real = ""
        busy = true
        setText(box, "")
        busy = false
        dim.Visible = true
        task.defer(function() pcall(function() box:CaptureFocus() end) end)
    end

    function PX.submitAdmin()
        if os.clock() < PX.adminCooldownUntil then
            notify("Biraz Bekle", "Çok fazla hatalı deneme. Bir süre sonra tekrar dene.", 3)
            return
        end
        if PX.checkAdmin(PX.real) then
            PX.adminWrong = 0
            PX.admin = true
            PX.hidePrompt()
            PX.adminTab.btn.Visible = true
            PX.setPremium(true, true)
            selectTab(PX.adminTab)
            notify("Yönetim Açıldı 🛡️", "Hoş geldin! Premium da senin için açıldı.", 4)
        else
            PX.adminWrong = PX.adminWrong + 1
            PX.real = ""
            busy = true
            setText(box, "")
            busy = false
            if PX.adminWrong >= 3 then
                PX.adminWrong = 0
                PX.adminCooldownUntil = os.clock() + 30
                PX.hidePrompt()
                notify("Erişim Engellendi", "3 hatalı deneme. 30 saniye bekle.", 4)
            else
                notify("Şifre Hatalı", "Tekrar dene.", 2)
            end
        end
    end

    bind(enter.MouseButton1Click, function()
        playClickSound()
        PX.submitAdmin()
    end)
    bind(cancel.MouseButton1Click, function()
        playClickSound()
        PX.hidePrompt()
    end)
    bind(box.FocusLost, function(enterPressed)
        if enterPressed then PX.submitAdmin() end
    end)
end

-- Gizli açma yöntemi 1: Ctrl + Shift + Y
bind(UserInputService.InputBegan, function(input, gpe)
    if gpe or not ready or not menuOpen then return end
    if input.KeyCode == ADMIN_HOTKEY
        and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
        and UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
        if PX.admin then
            selectTab(PX.adminTab)
        else
            PX.showPrompt()
        end
    end
end)

-- Gizli açma yöntemi 2 (mobil/klavyesiz): sol paneldeki küçük "menüyü aç/kapat" yazısına hızlıca 7 kez dokun
do
    local taps, lastTap = 0, 0
    SidebarKeyHint.Active = true
    bind(SidebarKeyHint.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local now = os.clock()
            if now - lastTap > 1.2 then taps = 0 end
            lastTap = now
            taps = taps + 1
            if taps >= 7 then
                taps = 0
                if PX.admin then
                    selectTab(PX.adminTab)
                else
                    PX.showPrompt()
                end
            end
        end
    end)
end

-- Yönetim sekmesi başlangıçta tamamen gizli
PX.adminTab.btn.Visible = false
end

-- AYARLAR
createSection(SettingsPage, "KONTROL")
do
    local row, st = baseRow(SettingsPage, "TextButton", 42)
    rowLabel(row, "Menü Tuşu")
    local keyText = new("TextLabel", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.new(0, 100, 0, 26),
        BackgroundTransparency = 1, Text = Settings.ToggleKey.Name, Font = Enum.Font.GothamBold, TextSize = 13,
        TextColor3 = Color3.fromRGB(255, 65, 75), TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 4,
    }, row)
    hoverFx(row, st)

    updateKeyTextCallback = function(name)
        setText(keyText, name)
    end

    bind(row.MouseButton1Click, function()
        playClickSound()
        listeningForKey = true
        setText(keyText, "Tuşa basın...")
        notify("Tuş Bekleniyor", "Menü için yeni bir klavye tuşuna basın...", 3)
    end)
end

createSection(SettingsPage, "GÖRÜNÜM")
createToggle(SettingsPage, "Bulanık arka plan", Settings.Blur, function(v)
    Settings.Blur = v
    if menuOpen then
        if v then
            blurEffect.Enabled = true
            tween(blurEffect, 0.3, {Size = 12})
        else
            tween(blurEffect, 0.3, {Size = 0})
            task.delay(0.3, function() if not Settings.Blur then blurEffect.Enabled = false end end)
        end
    end
end)
createSlider(SettingsPage, "Menü boyutu", 60, 120, math.floor(Settings.Scale * 100 + 0.5), function(v)
    Settings.Scale = v / 100
    if menuOpen then tween(MainScale, 0.15, {Scale = menuScale()}) end
end, "%")
createSection(SettingsPage, "SES")
createToggle(SettingsPage, "Ses efektleri", Settings.Sound, function(v) Settings.Sound = v end)
createSection(SettingsPage, "DİĞER")
createButton(SettingsPage, "Menüyü küçült", function() setMenu(false) end)
createButton(SettingsPage, "Arayüzü tamamen kapat", function() closeAll() end)

-- DİL SEÇİMİ
createSection(SettingsPage, "DİL / LANGUAGE")
do
    local row, st = baseRow(SettingsPage, "Frame", 48)
    rowLabel(row, "Dil / Language")
    -- Background layers carry the animated color effect; button text stays plain white.
    local trBg = new("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -106, 0.5, 0),
        Size = UDim2.new(0, 82, 0, 30),
        BackgroundColor3 = Color3.fromRGB(120, 22, 38),
        BorderSizePixel = 0,
        ZIndex = 5,
    }, row)
    corner(trBg, 8)
    local trGradient = new("UIGradient", {
        Color = flowSeq(0.1, 0.55),
        Rotation = 0,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.22),
            NumberSequenceKeypoint.new(0.5, 0.02),
            NumberSequenceKeypoint.new(1, 0.22),
        }),
    }, trBg)
    regFlow(UIFlows, trGradient, 0.1, 0.55, 36)
    local trStroke = stroke(trBg, 1.2, Color3.fromRGB(190, 65, 80), 0.25)

    local trButton = new("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -106, 0.5, 0),
        Size = UDim2.new(0, 82, 0, 30),
        BackgroundTransparency = 1,
        Text = "Türkçe",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        AutoButtonColor = false,
        ZIndex = 6,
    }, row)

    local enBg = new("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.new(0, 82, 0, 30),
        BackgroundColor3 = Color3.fromRGB(35, 42, 58),
        BorderSizePixel = 0,
        ZIndex = 5,
    }, row)
    corner(enBg, 8)
    local enGradient = new("UIGradient", {
        Color = flowSeq(1.7, 0.55),
        Rotation = 0,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.22),
            NumberSequenceKeypoint.new(0.5, 0.02),
            NumberSequenceKeypoint.new(1, 0.22),
        }),
    }, enBg)
    regFlow(UIFlows, enGradient, 1.7, 0.55, 36)
    local enStroke = stroke(enBg, 1.2, Color3.fromRGB(90, 105, 130), 0.25)

    local enButton = new("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.new(0, 82, 0, 30),
        BackgroundTransparency = 1,
        Text = "English",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        AutoButtonColor = false,
        ZIndex = 6,
    }, row)

    local function refreshLanguageButtons(code)
        local trSelected = code == "TR"
        local enSelected = code == "EN"

        trBg.BackgroundTransparency = 0
        enBg.BackgroundTransparency = 0
        trBg.BackgroundColor3 = trSelected and Color3.fromRGB(120, 22, 38) or Color3.fromRGB(35, 42, 58)
        enBg.BackgroundColor3 = enSelected and Color3.fromRGB(120, 22, 38) or Color3.fromRGB(35, 42, 58)

        -- The animated gradient remains behind both labels, regardless of selection.
        trGradient.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, trSelected and 0.12 or 0.48),
            NumberSequenceKeypoint.new(0.5, trSelected and 0.02 or 0.22),
            NumberSequenceKeypoint.new(1, trSelected and 0.12 or 0.48),
        })
        enGradient.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, enSelected and 0.12 or 0.48),
            NumberSequenceKeypoint.new(0.5, enSelected and 0.02 or 0.22),
            NumberSequenceKeypoint.new(1, enSelected and 0.12 or 0.48),
        })

        trStroke.Transparency = trSelected and 0.05 or 0.35
        enStroke.Transparency = enSelected and 0.05 or 0.35
        trStroke.Color = trSelected and Color3.fromRGB(255, 95, 110) or Color3.fromRGB(115, 125, 145)
        enStroke.Color = enSelected and Color3.fromRGB(255, 95, 110) or Color3.fromRGB(115, 125, 145)

        -- Both labels are always simple, solid white.
        trButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        enButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    end

    local function chooseLanguage(code)
        Settings.Language = code
        saveConfig()
        applyLanguage()
        refreshLanguageButtons(code)
        notify("EZRAGOX HUB", code == "EN" and "Language changed to English." or "Dil Türkçe olarak değiştirildi.", 2)
    end
    bind(trButton.MouseButton1Click, function() chooseLanguage("TR") end)
    bind(enButton.MouseButton1Click, function() chooseLanguage("EN") end)
    refreshLanguageButtons(Settings.Language)
end

selectTab(Tabs[1])

---------------------------------------------------------
-- 10. HER KARE GÜNCELLEMELER
---------------------------------------------------------
local fps, fpsAcc, fpsN = 60, 0, 0

bind(RunService.RenderStepped, function(dt)
    local t = os.clock()
    fpsAcc = fpsAcc + dt
    fpsN = fpsN + 1
    if fpsAcc >= 0.5 then
        fps = math.floor(fpsN / fpsAcc + 0.5)
        fpsAcc, fpsN = 0, 0
    end

    for _, a in ipairs(UIAccents) do a.obj[a.prop] = accentAt(a.off) end
    for _, f in ipairs(UIFlows) do
        f.grad.Color = flowSeq(f.phase, f.step)
        if f.spin then f.grad.Rotation = (f.grad.Rotation + f.spin * dt) % 360 end
    end
    for _, p in ipairs(Pulsers) do p.obj[p.prop] = p.base + math.sin(t * p.speed) * p.amp end

end)

local function getPing()
    local ok, v = pcall(function()
        return math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue() + 0.5)
    end)
    return ok and v or nil
end
task.spawn(function()
    while alive do
        if menuOpen then
            -- Ultra FPS açıkken ana sayfa göstergesine +100 eklenir.
            -- Gerçek FPS ölçümü ve oyun performansı değiştirilmez.
            local displayedFps = math.max(0, math.floor(fps)) + (ultraFpsDisplayBoost and 100 or 0)
            setText(FpsValue, tostring(displayedFps))
            local ping = getPing()
            setText(PingValue, ping and (tostring(ping) .. " ms") or "—")
            setText(PlayersValue, tostring(#Players:GetPlayers()))
        end
        task.wait(0.5)
    end
end)

task.spawn(function()
    while alive do
        task.wait(2.8)
        for _, s in ipairs(Shines) do
            if s.Parent then playShine(s) end
        end
    end
end)

---------------------------------------------------------
-- 11. SİNEMATİK GİRİŞ SENARYOSU
---------------------------------------------------------
task.spawn(function()
    Intro.play(function()
        -- Flaşın tepe noktasında ana menü açılır
        ready = true
        menuOpen = true
        MainScale.Scale = menuScale() * 0.6
        MainFrame.Visible = true
        MenuCharViewport.Visible = true
        playMenuIntroSoundOnce()
        tween(MainScale, 0.6, {Scale = menuScale()}, Enum.EasingStyle.Back)
        if Settings.Blur then
            tween(blurEffect, 0.6, {Size = 12})
        else
            tween(blurEffect, 0.6, {Size = 0})
            task.delay(0.6, function() if not menuOpen or not Settings.Blur then blurEffect.Enabled = false end end)
        end
        playClickSound()
        task.delay(0.8, function()
            notify("EZRAGOX HUB", "Hoş geldin! Menüyü " .. Settings.ToggleKey.Name .. " tuşu ile açıp kapatabilirsin.", 4)
        end)
    end)
end)
