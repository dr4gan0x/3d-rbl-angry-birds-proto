# Flockfall — 3D Sapan Fizik Oyunu Tasarım Dokümanı (Spec)

**Durum:** Taslak — uygulama öncesi onay bekliyor
**Tarih:** 2026-11-12
**Proje kodu:** `flockfall`
**Depo:** `dr4gan0x/3d-rbl-angry-birds-proto`
**Hedef platform:** Roblox (PC / mobil / konsol)

---

## 0. Tek Cümlelik Hedef

Roblox üzerinde, oyuncunun 3D bir sapanla kuş fırlatıp düşman hedefleri ve yıkılabilir yapıları devirdiği, tek oyunculu, 3 seviyeli, çalışan bir **oynanabilir prototip** teslim etmek — tamamı özgün IP ve ücretsiz/kendi üretimimiz varlıklarla.

---

## 1. IP ve Lisans Politikası (Bağlayıcı — en yüksek öncelik)

Kullanıcı şartı: **"Lisans olmadığı için lisanslı şeyler kullanılmayacaktır."** Bu, spec'in en katı kısıtıdır ve tüm tasarım kararlarını şekillendirir.

### 1.1 Neden bu kadar kritik

Roblox, DMCA "safe harbor" modeliyle çalışır: hak sahibi şikâyet edene kadar Roblox genelde harekete geçmez, ancak şikâyet geldiğinde içerik kaldırılır ve tekrarlayan ihlalde **hesap kalıcı olarak kapatılır** ([Roblox IP duyurusu](https://devforum.roblox.com/t/protecting-creativity-by-understanding-intellectual-property/2559638)). Yani "şimdiye kadar kaldırılmadı" güvenli olduğu anlamına gelmez; risk, yayınlandığı anda başlar.

Telif **fikri** değil, **ifadeyi** korur. "Sapanla kuş fırlatıp domuz devirme" mekaniği bir fikirdir ve tek başına korunmaz; ama şu ifadeler korunur: karakter tasarımları, isimler, ses efektleri, müzik, seviye düzenlerinin birebir kopyası, görsel stil.

### 1.2 Kesinlikle yasak (kara liste)

| Kategori | Yasak örnekler |
|---|---|
| Marka / oyun adı | "Angry Birds", "Rovio", "Bad Piggies" ve bunların çeviri/türevleri |
| Karakter isimleri | Red, Chuck, Bomb, Matilda, Hal, Terence, Bubbles, Stella, Silver, Leonard, King Pig, Minion Pig |
| Karakter tasarımları | Yuvarlak kırmızı kuş + kaş; yeşil domuz + burun; herhangi bir AB silueti veya renk kombinasyonu |
| Ses | AB müziği, sapan/çarpma/domuz sesleri, Rovio ses varlıkları |
| Görseller | Ekran görüntüleri, logolar, ikonlar, arayüz kopyası (örn. seviye sonu yıldız ekranının birebir taklidi) |
| Seviye düzeni | Orijinal oyunun seviyelerinin birebir 3D'ye taşınması |

> **Not:** "Angry Birds" adı depo adında (`3d-rbl-angry-birds-proto`) yalnızca **tür tanımı** olarak geçer. Yayınlanan deneyimin adı, açıklaması, ikonu ve vitrin görselinde bu ad **kullanılmayacaktır**.

### 1.3 İzin verilen varlık kaynakları

1. **Kendi üretimimiz (birincil yol):** Roblox `Part` / `WedgePart` / `CylinderPart` primitiflerinden kodla üretilen geometri. Sıfır lisans riski, sıfır dış bağımlılık, sıfır yükleme.
2. **Roblox'un sağladığı resmî kütüphane:** Roblox'un lisanslı ses kütüphanesi (100.000+ parça, platform içi kullanım için temizlenmiş) ve Roblox'a ait varsayılan materyal/doku. Kimlik doğrulaması: yalnızca `creator = Roblox` olan sesler.
3. **Kendi bestelediğimiz/ürettiğimiz ses:** gerekirse `Sound` için prosedürel/elle üretilmiş kısa efektler.

### 1.4 Yasak varlık kaynakları

- Creator Store'daki üçüncü taraf modeller/mesh'ler (lisans kaydı tutmadan **hayır**)
- Toolbox'tan rastgele "free model"
- İnternetten indirilen herhangi bir mesh, doku, müzik
- Başka bir Roblox oyunundan alınmış herhangi bir şey

### 1.5 Varlık kayıt defteri (zorunlu süreç)

Her dış varlık için `docs/ASSETS.md` dosyasına şu satır eklenir; eklenmeyen varlık oyuna girmez:

```
| id | tür | kaynak | lisans | doğrulama tarihi | ekleyen |
```

Prototipte bu dosya **boş tablodur** ve spec gereği öyle kalması beklenir — tüm varlıklar prosedüreldir.

### 1.6 Özgün kimlik: Flockfall

- **Tema:** Endüstriyel bir hurdalıkta geçen, kuş sürüsünün "Tinhead" denen tek gözlü robot nöbetçilerin kalelerini devirdiği bir isyan.
- **Görsel dil:** Kuşlar organik/yuvarlak, sıcak renkler; Tinhead'ler köşeli, soğuk gri-metal, tek Neon göz. Bu karşıtlık, domuz/kuş karşıtlığından **kasıtlı olarak farklıdır**.
- **İsimlendirme:** Kuş türleri gerçek kuş cinslerinden (Wren, Swallow, Puffin) — tür adları marka olarak tescil edilemez, tasarımlar bizimdir.
- **Çalışma adı doğrulaması:** Yayından önce "Flockfall" için Roblox arama + marka (TÜRKPATENT/USPTO) kontrolü yapılacak. Çakışma varsa isim değişir; kod içi kimlik `flockfall` olarak kalır.

---

## 2. Kapsam

### 2.1 Prototip kapsamında (yapılacak)

- Tek oyunculu, sunucu yetkili (server-authoritative) sapan atışı
- 3D nişan alma: tek sürükleme ile **yaw + pitch + güç**
- Yörünge önizlemesi (analitik parabol, sunucu fiziğiyle uyumlu)
- 3 kuş tipi: Wren (temel), Swallow (hız hamlesi), Puffin (patlama)
- 4 malzeme: Wood, Glass, Stone, Metal (Metal kırılmaz — seviye tasarımı aracı)
- Yıkılabilir yapılar: parça bazlı sağlık, kırılma, enkaz temizliği
- 3 Tinhead hedefi tipi davranışı: statik, sağlıklı, patlayıcı varil yanında
- 3 el yapımı seviye
- Skor + yıldız (1–3), seviye sonu ekranı, yeniden deneme, sonraki seviye
- Mobil + klavye/fare + gamepad girişi
- Otomatik testler (saf mantık) + Studio oynanış kontrol listesi

### 2.2 Kapsam dışı (prototipte yapılmayacak)

- Çok oyunculu / PvP / eşli mod
- Kalıcı veri (DataStore), ilerleme kaydı, liderlik tablosu
- Monetizasyon (Robux, oyun içi satın alma), reklam
- Ses kaydı/voice chat
- Yapay zekâlı düşman hareketi (Tinhead'ler statik nöbetçidir)
- Seviye editörü, prosedürel seviye üretimi
- Özelleştirme/kilit açma sistemi

> **Gerekçe:** Prototipin amacı "eğlenceli mi?" sorusunu yanıtlamak. Bunlar eğlenceyi kanıtlamadan eklenirse maliyeti artırır, öğrenmeyi geciktirir (YAGNI).

---

## 3. Oyun Tasarımı

### 3.1 Çekirdek döngü (≈ 20–45 sn/seviye)

```
NİŞAN AL → BIRAK → UÇUŞ (kamera takip) → ÇARPIŞMA → YIKIM & ZİNCİRLEME
   ↑                                                          │
   └──────────── sıradaki kuş (kuş kaldıysa) ←────────────────┘
                             │ (hedef kalmadı / kuş bitti)
                             ↓
                    SKOR + YILDIZ + DEVAM
```

### 3.2 3D nişan alma modeli — tasarımın kalbi

2D oyunda 2 serbestlik derecesi vardır (açı + güç). 3D'de 3 gerekir. Çözüm:

**Tek sürükleme, üç kontrol.** Oyuncu sapan lastiğine dokunup kuşu **çeker**; bırakınca kuş çekme vektörünün **tersi** yönünde fırlar.

```
v_launch = -normalize(pullVector) * clamp(|pullVector| / maxPull, 0, 1) * maxSpeed
```

- **Yatay çekme** → yaw (soldan çekersem sağa uçar)
- **Dikey çekme** → pitch (aşağı çekersem yukarı uçar)
- **Çekme mesafesi** → güç

Bu, gerçek bir sapanın sezgisel davranışıdır ve ekstra mod/buton gerektirmez. Mobilde tek parmakla çalışır.

**Kısıtlar:**
- `maxPull = 8 stud` (çekme yarıçapı), `maxSpeed = 260 stud/s`
- Ölü bölge: `|pull| < 0.75 stud` → atış yok (yanlış dokunma koruması)
- Minimum ateş gücü: `power >= 0.12`, aksi halde kuş sapanın dibine düşer (kötü deneyim) → atış iptal edilir
- Çekme vektörü, sapan çatalından geçen dünya dikey düzlemine **projeksiyonlanmaz**; serbest 3D kalır (yandan atış yapılabilir)

### 3.3 Kamera

- **Hazırlık:** Sapan çevresinde yörünge kamerası. Boş alana sürükle = kamera döner; kuş üzerine sürükle = nişan alınır. Bu ayrım, hedefleme ile kamera çakışmasını çözer.
- **Uçuş:** Kamera kuşa yumuşak takip (lerp). Çarpışmadan sonra hedef bölgesine döner.
- **Çözünürlük:** FOV 70, kamera `Scriptable` moda alınır; `BindToRenderStep` ile güncellenir.

### 3.4 Kuşlar

| Kuş | Tür | Kütle | Yetenek (uçuşta dokun) | Rol |
|---|---|---|---|---|
| **Wren** | Temel | 2.0 | Yok | Güvenilir hasar, temel araç |
| **Swallow** | Hız | 1.2 | İleri doğru hız patlaması (v *= 1.9, tek kullanım) | Derin nüfuz, uzun menzil |
| **Puffin** | Patlayıcı | 3.5 | 0.4 sn sonra 140 stud/s impuls + 14 stud yarıçap patlama | Kalabalık yapı sökme |

Yetenek, fırlatmadan sonra **bir kez** ekrana dokunarak tetiklenir; kaçırılırsa kuş temel davranışta kalır. (Öğrenme eğrisi düşük, ustalık alanı var.)

### 3.5 Malzemeler ve yıkım

| Malzeme | HP | Yoğunluk | Not |
|---|---|---|---|
| Wood | 55 | 0.6 | Standart yapı |
| Glass | 24 | 0.4 | Kolay kırılır, enkazı hafif |
| Stone | 140 | 1.8 | Ağır, devirmek kırmaktan kolay |
| Metal | ∞ | 2.4 | **Kırılmaz** — tasarımcının "çözümü zorlaştırma" aracı |

Hasar modeli (saf fonksiyon, test edilebilir):

```
damage = impactSpeedFactor * impactMassFactor * materialMultiplier
impactSpeedFactor = clamp((relativeSpeed - minSpeed) / (maxSpeed - minSpeed), 0, 1)
```

`minSpeed = 18 stud/s` altındaki temaslar hasar vermez (yapıların kendi kendine çökmesini engeller → seviye kararlılığı).

### 3.6 Hedefler

**Tinhead** — tek gözlü, küp gövdeli robot nöbetçi.
- `health = 100`, kuş çarpması ve patlama ile hasar alır
- Yüksekten düşme hasarı: `fallDamage = max(0, impactSpeed - 40) * 1.2`
- Öldüğünde skor + görsel/ses geri bildirimi + skorbord güncellemesi

### 3.7 Skor ve yıldız

```
score = 500 * (öldürülen Tinhead) + 40 * (kırılan Wood/Glass)
      + 90 * (kırılan Stone) + 1000 * (kalan kuş)
```

- 3 yıldız: `score >= level.par.three`
- 2 yıldız: `score >= level.par.two`
- 1 yıldız: seviye tamamlandı

### 3.8 Seviye akışı (durum makinesi)

`Idle → Aiming → Flying → Settling → (Win | Lose) → Idle`

- **Settling:** tüm parçaların hızı < 1.5 stud/s olana kadar bekle, en fazla 4 sn (sonsuz beklemeyi engeller)
- **Win:** tüm Tinhead'ler öldü
- **Lose:** kuş bitti ve Tinhead kaldı
- Durum makinesi **saf Luau** — Roblox'a bağımsız, test edilebilir

### 3.9 Arayüz (mobil öncelikli)

- `ScreenGui` (`ResetOnSpawn = false`), tüm ölçüler **Scale** tabanlı (Offset yalnızca küçük padding)
- Dokunma hedefi ≥ ekran yüksekliğinin %8'i
- HUD: kalan kuşlar (sol üst), skor (sağ üst), duraklat (sağ üst köşe)
- Seviye sonu paneli: yıldızlar, skor, "Yeniden Dene" / "Sonraki Seviye"

---

## 4. Teknik Mimari

### 4.1 Yetki modeli

**Sunucu tek doğruluk kaynağıdır.** İstemci yalnızca *niyet* bildirir.

```
İstemci                                   Sunucu
───────                                   ───────
drag → AimModel: (power,yaw,pitch)   →    FireRequest(power, yaw, pitch)
                                          ├─ rate limit (≥0.35 sn)
                                          ├─ aralık doğrulaması (0..1, ±π)
                                          ├─ sıra doğrulaması (bu oyuncunun sırası mı?)
                                          ├─ kuş kaldı mı?
                                          ├─ Kinematics.launchVelocity → spawn
                                          └─ SetNetworkOwner(nil)
← TrajectoryPreview (aynı Kinematics)     (yalnızca görsel, yetkisiz)
←------------ hasar/yıkım olayları ------ (sunucudan yayınlanır)
```

**Neden istemci fiziği değil:** İstemci sahipliğinde hile ile her atış maksimum güçte olur. Bu bir yarışma oyunu değil ama "prototip, üretime evrilebilir mimari" hedefinde yetki modeli en pahalı sonradan düzeltilen karardır. Ayrıca tek oyunculu olduğu için gecikme cezası yok — güvenli taraf bedava.

### 4.2 Katmanlar

```
┌──────────────────────────────────────────────────────────────┐
│  src/shared/core/*  — SAF LUA (Roblox API yok, test edilir)  │
│  Kinematics · AimModel · DamageModel · ScoreModel            │
│  LevelSchema · LevelState · BuildMath                        │
└──────────────────────────────────────────────────────────────┘
            ↑ require                    ↑ require
┌───────────────────────────┐  ┌───────────────────────────────┐
│  src/client/*             │  │  src/server/*                │
│  SlingshotController      │  │  FireService                 │
│  CameraRig                │  │  DamageService               │
│  TrajectoryPreview        │  │  RoundService                │
│  Hud                      │  │  BuildService                │
└───────────────────────────┘  └───────────────────────────────┘
                    ↕ RemoteEvents (ReplicatedStorage/Remotes)
```

**Kural:** `src/shared/core/*` içindeki hiçbir dosya `game`, `workspace`, `Vector3`, `Instance`, `task` referansı **içermez**. Bu dosyalar Luau VM'inde Roblox olmadan çalışır. Bu kural, test edilebilirliğin tek dayanağıdır.

### 4.3 Neden `Vector3` yerine `{x, y, z}`

Saf modüller düz tablo vektörleri kullanır; Roblox katmanı sınırda dönüştürür (`BuildMath.toVector3`). Böylece core, Roblox VM'i olmadan çalışır. Maliyet: sınır geçişinde tek dönüşüm. Kazanç: tüm nişan/hasar/skor mantığı CI'da test edilebilir.

### 4.4 Dosya yapısı

```
3d-rbl-angry-birds-proto/
├── README.md
├── package.json                  # yalnızca araç zinciri (devDependency)
├── default.project.json          # Rojo eşlemesi
├── .luaurc                       # languageMode = strict
├── stylua.toml
├── src/
│   ├── shared/
│   │   ├── core/
│   │   │   ├── Kinematics.luau
│   │   │   ├── AimModel.luau
│   │   │   ├── DamageModel.luau
│   │   │   ├── ScoreModel.luau
│   │   │   ├── LevelSchema.luau
│   │   │   ├── LevelState.luau
│   │   │   └── BuildMath.luau
│   │   ├── config/
│   │   │   ├── GameConfig.luau       # sabitler: maxSpeed, maxPull, hp tablosu...
│   │   │   └── Materials.luau
│   │   ├── levels/
│   │   │   ├── Level01.luau
│   │   │   ├── Level02.luau
│   │   │   ├── Level03.luau
│   │   │   └── init.luau             # liste + id ile getir
│   │   ├── testkit/
│   │   │   └── TestKit.luau
│   │   └── Remotes.luau              # RemoteEvent tanımları
│   ├── client/
│   │   ├── init.client.luau
│   │   ├── SlingshotController.luau
│   │   ├── CameraRig.luau
│   │   ├── TrajectoryPreview.luau
│   │   └── Hud.luau
│   └── server/
│       ├── init.server.luau
│       ├── FireService.luau
│       ├── DamageService.luau
│       ├── RoundService.luau
│       └── BuildService.luau
├── tests/
│   ├── Kinematics.spec.luau
│   ├── AimModel.spec.luau
│   ├── DamageModel.spec.luau
│   ├── ScoreModel.spec.luau
│   ├── LevelSchema.spec.luau
│   ├── LevelState.spec.luau
│   ├── BuildMath.spec.luau
│   └── Levels.spec.luau
├── tools/
│   └── test.mjs                  # Luau WASM test koşucusu
└── docs/
    ├── ASSETS.md
    └── superpowers/
        ├── specs/2026-11-12-flockfall-3d-slingshot-design.md
        └── plans/2026-11-12-flockfall-mvp.md
```

### 4.5 Veri modeli — `LevelDefinition`

Saf Luau tablosu; `Vector3` yok. `LevelSchema.validate` bunu doğrular.

```lua
{
  id = "level-02",
  name = "Vincin Altında",
  par = { two = 3200, three = 5400 },
  loadout = { "Wren", "Wren", "Swallow", "Puffin" },
  slingshot = { position = {x=0,y=6,z=0}, facing = {x=0,y=0,z=-1} },
  pieces = {
    { id="w1", material="Wood",  size={x=2,y=8,z=2},
      position={x=0,y=4,z=-40}, rotation={x=0,y=90,z=0} },
    { id="m1", material="Metal", size={x=1,y=30,z=1},
      position={x=0,y=15,z=-52}, rotation={x=0,y=0,z=0} },
  },
  targets = {
    { id="t1", position={x=0,y=2,z=-40}, health=100 },
  },
  props = {
    { id="barrel1", kind="ExplosiveBarrel",
      position={x=2,y=3,z=-42}, radius=8, damage=60, impulse=90 },
  },
}
```

### 4.6 Ağ olayları

| Remote | Yön | Argümanlar | Doğrulama |
|---|---|---|---|
| `FireRequest` | C→S | `power:number, yaw:number, pitch:number` | tip + aralık + sıra + rate limit |
| `AbilityRequest` | C→S | — | uçuşta mı, kullanılmış mı |
| `ShotFired` | S→C | `birdType, origin, velocity` | — |
| `DamageEvent` | S→C | `pieceId, healthAfter, destroyed` | — |
| `LevelStateChanged` | S→C | `state, payload` | — |

`UnreliableRemoteEvent` kullanılmaz — prototip için kayıp paket karmaşıklığı gereksiz.

---

## 5. Doğrulama Stratejisi

### 5.1 Araç zinciri (bu ortamda **doğrulandı**)

| Araç | Sürüm | Durum | Kanıt |
|---|---|---|---|
| Node.js | 22.22.3 | ✅ mevcut | `node --version` |
| `@luau-rs/luau` | 0.739.0 | ✅ çalışıyor | Luau 0.739 VM'de modül + matematik testi koştu |
| `@johnnymorganz/stylua-bin-linux-x64` | 2.6.0 | ✅ çalışıyor | `stylua --check` ve `--write` doğrulandı |
| Rojo / Lune binary | — | ❌ indirilemiyor | `release-assets.githubusercontent.com` erişim engelli |

**Sonuç:** Saf mantık TDD gerçekten yapılabilir. Roblox'a bağlı katman bu ortamda **otomatik test edilemez** — bu spec'te açıkça kabul edilir ve Studio kontrol listesi ile telafi edilir. Yanlış güven vermektense sınırı net çizmek doğrudur.

**Doğrulama kanıtı (2026-11-12):** Plan'ın 1–8. görevleri bu ortamda gerçekten kuruldu; koşucu `PASS 88 FAIL 1` (kasıtlı hata) → `PASS 88 FAIL 0` verdi. Bu sırada bulunan ve spec'e işlenen üç gerçek tasarım düzeltmesi:

1. **`script` yasağı ile `require` çelişkisi:** Core modüller `require(script.Parent.X)` kullanamaz (VM'de `attempt to index nil with 'Parent'`). Çözüm: **dependency injection** — config/materials parametre olarak geçer.
2. **`{ number, number, number }` geçersiz Luau tipi:** Sabit boyutlu demet tipi yoktur; `{ number }` kullanılır.
3. **Spec dosyası sarmalaması:** Her spec `end` ile bitmeli, `end)` ile değil; koşucu dosyayı `(function() ... end)()` içine sarar.

### 5.2 Test piramidi

1. **Birim (otomatik, CI):** `src/shared/core/*` — her fonksiyon. Hedef: ≥ 60 assertion, 0 hata.
2. **Veri (otomatik, CI):** 3 seviyenin `LevelSchema.validate` ile geçmesi + erişilebilirlik kontrolü.
3. **Özellik (otomatik, CI):** analitik yörünge ≈ ayrık adımlı simülasyon (tolerans testi).
4. **Oynanış (elle, Studio):** `docs/PLAYTEST.md` kontrol listesi.

**Bilinen sınır:** `rojo build` / `lune` bu ortamda çalışmaz. Bu yüzden `.rbxl` üretimi ve Studio içi testler kullanıcı tarafında yapılır; kod tarafında yalnızca `default.project.json` doğruluğu garanti edilir.

### 5.3 Test koşucusu sözleşmesi

Her spec şu biçimde **bir fonksiyon döndürür** (ne global ne `script` bağımlılığı):

```lua
-- tests/Kinematics.spec.luau
return function(T)
	local Kinematics = T.require("Kinematics")
	T.describe("Kinematics", function()
		T.it("...", function()
			T.expect(actual):toBeCloseTo(expected, 1e-6)
		end)
	end)
end
```

`TestKit` API: `require(name)`, `describe(name, fn)`, `it(name, fn)`, `expect(v)` → `:toBe` `:toBeCloseTo` `:toBeTrue` `:toBeFalse` `:toThrow` `:toEqual`, `run()` → `pass, fail, failures`.

> **Tuzak (doğrulandı):** `expect(x):toBe(y)` kolon sözdizimidir; metot `function(self, expected)` almalıdır. `function(expected)` yazılırsa "attempt to perform arithmetic on number and table" hatası alınır. Bu, planın 2. görevinde testle sabitlenir.

---

## 6. Global Kısıtlar (tüm görevler için bağlayıcı)

1. Luau `--!strict`; kök `.luaurc` içinde `"languageMode": "strict"`.
2. `src/shared/core/*` dosyalarında Roblox globali **yasak** (`game`, `workspace`, `Instance`, `Vector3`, `task`, `wait`, `tick`, `warn` hariç).
3. Dış Luau paketi yok (Wally yok). Sıfır bağımlılık.
4. Yerçekimi: `196.2` stud/s² (Roblox varsayılanı). Testlerde bu değer sabit.
5. Dokümantasyon ve yorumlar Türkçe; tanımlayıcılar İngilizce.
6. Dosya adları `PascalCase.luau`; `.spec.luau` soneki test dosyaları.
7. Biçimlendirme: `stylua --check` temiz olmalı (sekme, 100 kolon).
8. Sihirli sayı yok: tüm ayar sabitleri `src/shared/config/GameConfig.luau` içinde.
9. Her görev kendi commit'i ile biter.
10. IP kuralı: bölüm 1.2'deki hiçbir isim/tasarım kodda geçmez.

---

## 7. Riskler

| Risk | Etki | Azaltma |
|---|---|---|
| 3D nişan alma sezgisel değil | Oyun eğlenceli olmaz | Yörünge önizlemesi + ölü bölge + `maxPull` ayarı tek yerden |
| Roblox fiziği önizlemeden sapar | Oyuncu "hile" hisseder | Önizleme analitik; testte ayrık simülasyonla tolerans doğrulanır (±2 stud/80 stud) |
| Yapılar kendi kendine çöker | Seviye kararsız | `minSpeed = 18` hasar eşiği + Metal taşıyıcılar |
| Yıkım parçacıkları FPS düşürür | Mobilde oynanmaz | Parça bütçesi ≤ 500, enkaz 2.5 sn ömür + `CanCollide=false` |
| Studio'da test edilemezlik | Hatalar geç bulunur | Saf mantığı olabildiğince geniş tutmak + ayrıntılı elle kontrol listesi |
| IP ihlali | Hesap kapanması | Bölüm 1 politikası + varlık kayıt defteri |

---

## 8. Kabul Kriterleri (prototip "bitti" sayılır eğer)

- [ ] `npm test` → 0 hata, ≥ 60 assertion; `stylua --check` temiz
- [ ] Studio'da: sapan çekilip bırakılabiliyor, kuş 3D yay çiziyor, yapıya çarpıyor
- [ ] Yapı parçaları hasar alıp kırılıyor, enkaz temizleniyor
- [ ] Tinhead'ler ölüyor, seviye kazanılıyor
- [ ] Kuş biterse "kaybettin" ekranı, yeniden dene çalışıyor
- [ ] 3 seviye sırayla oynanabiliyor, skor/yıldız doğru
- [ ] Telefonda tek parmakla oynanabiliyor, HUD okunabiliyor
- [ ] Kodda yasaklı IP ismi/tasarımı **yok** (elle + `grep` taraması)
- [ ] `docs/ASSETS.md` tüm varlıkları listeliyor (prototipte: hepsi prosedürel)
- [ ] `README.md` kurulum + oynama adımlarını içeriyor

---

## 9. Araştırma Kaynakları

| Konu | Bulgu | Kaynak |
|---|---|---|
| Fizik performansı | Fizik 60/120/240 Hz uyarlamalı; sabit 240 Hz'e zorlamak maliyeti 4× artırır | [Roblox creator-docs](https://github.com/Roblox/creator-docs/blob/main/content/en-us/performance-optimization/improve.md) |
| | Karmaşık constraint ağları ve yüksek `CollisionFidelity` ana maliyet | [DevForum](https://devforum.roblox.com/t/physics-calculation-performance-on-client/3419566) |
| Fırlatma | `AssemblyLinearVelocity` tek atışta kesin hız verir; `ApplyImpulse` kütleye bağlı ve sapabilir | [DevForum](https://devforum.roblox.com/t/using-a-beam-to-model-projectile-motion/1302237) |
| | Ağ sahipliği sunucuda kalmalı: `SetNetworkOwner(nil)` | [DevForum](https://devforum.roblox.com/t/force-calculation-to-get-from-point-a-to-point-b/3149049) |
| Ağ güvenliği | Sunucu otoriter; istemci yalnızca niyet gönderir; rate limit zorunlu | [Roblox güvenlik rehberi](https://create.roblox.com/docs/scripting/security) |
| Girdi | `ContextActionService:BindAction` tek çağrıda fare+ dokunma + gamepad bağlar | [DevForum](https://devforum.roblox.com/t/userinputservice/3643586) |
| Yıkım | Parça bazlı sağlık + ön-kırılmış enkaz; enkaz istemci tarafı görsel olmalı | [SO](https://stackoverflow.com/questions/78699786/looking-for-techniques-to-optimize-a-voxel-destruction-system-roblox) |
| Arayüz | Scale tabanlı ölçü, ≥%8 dokunma hedefi, mobil öncelikli | [Roblox dökümanı](https://create.roblox.com/docs/ui) |
| IP | DMCA + tekrarlayan ihlalde hesap kapatma; "yaygın" olmak izin değildir | [DevForum IP](https://devforum.roblox.com/t/protecting-creativity-by-understanding-intellectual-property/2559638) |
| Varlık lisansı | Creator Store üçüncü taraf varlıkları lisans kaydı ister; Roblox resmî sesleri platform içi temizlenmiş | [Creator Store](https://create.roblox.com/docs/production/creator-store) |
| Araç zinciri | Rojo dosya↔instance eşlemesi; `.luaurc` strict; CI'da headless Luau testi | [Rojo/Lune örneği](https://github.com/atdasu/rojo) |

---

## 10. Onay Gerektiren Kararlar

Aşağıdakiler spec'in varsayımlarıdır; **biri yanlışsa plan değişir**:

1. **Tek oyunculu prototip** — çok oyunculu ertelendi.
2. **Tek sürükleme = yaw + pitch + güç** — alternatif: iki aşamalı nişan.
3. **Kuş türleri Wren/Swallow/Puffin**, hedefler **Tinhead** — isimler/tasarımlar değişebilir, politika değişmez.
4. **3 seviye** yeterli — 10 seviye MVP değildir.
5. **Sıfır dış varlık, sıfır dış paket** — her şey kodla üretilir.
